import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import 'error_logging_service.dart';

/// Customer model for local caching
class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final DateTime lastUpdated;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.lastUpdated,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Service for managing customer operations
class CustomerService {
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  final _errorLogger = ErrorLoggingService();
  Box<Map>? _cacheBox;

  /// Initialize the service with Hive box
  Future<void> initialize() async {
    try {
      _cacheBox = await Hive.openBox<Map>('customers_cache');
    } catch (e, stack) {
      await _errorLogger.logError(e, stack, context: 'CustomerService.initialize');
    }
  }

  /// Search customers by name or phone
  Future<List<CustomerModel>> searchCustomers(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      // Try to get from cache first if query is the same
      final cacheKey = 'search_$query';
      final cachedData = _cacheBox?.get(cacheKey);
      
      if (cachedData != null) {
        final lastUpdated = DateTime.parse(
          cachedData['lastUpdated'] as String? ?? DateTime.now().toIso8601String(),
        );
        
        if (DateTime.now().difference(lastUpdated) < AppConstants.customerCacheDuration) {
          final customers = (cachedData['customers'] as List)
              .map((c) => CustomerModel.fromJson(Map<String, dynamic>.from(c as Map)))
              .toList();
          return customers;
        }
      }

      // Fetch from database
      final data = await Supabase.instance.client
          .from('customers')
          .select('id,name,phone')
          .or('name.ilike.%${_sanitizeInput(query)}%,phone.ilike.%${_sanitizeInput(query)}%')
          .limit(50);

      final customers = (data as List)
          .map((json) => CustomerModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();

      // Cache the results
      await _cacheBox?.put(cacheKey, {
        'customers': customers.map((c) => c.toJson()).toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      return customers;
    } catch (e, stack) {
      await _errorLogger.logError(
        e,
        stack,
        context: 'CustomerService.searchCustomers',
        extras: {'query': query},
      );
      rethrow;
    }
  }

  /// Create a new customer
  Future<CustomerModel> createCustomer({
    required String name,
    required String phone,
  }) async {
    // Validate input
    final validationError = validateCustomerInput(name: name, phone: phone);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    try {
      final row = await Supabase.instance.client
          .from('customers')
          .insert({
            'name': name.trim(),
            'phone': phone.trim(),
          })
          .select('id,name,phone')
          .single();

      final customer = CustomerModel.fromJson(Map<String, dynamic>.from(row as Map));

      // Clear search cache since we added a new customer
      await _clearSearchCache();

      return customer;
    } catch (e, stack) {
      await _errorLogger.logError(
        e,
        stack,
        context: 'CustomerService.createCustomer',
        extras: {'name': name, 'phone': phone},
      );
      rethrow;
    }
  }

  /// Validate customer input
  String? validateCustomerInput({required String name, required String phone}) {
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();

    if (trimmedName.isEmpty && trimmedPhone.isEmpty) {
      return 'يجب إدخال الاسم أو رقم الهاتف على الأقل';
    }

    if (trimmedName.isNotEmpty && trimmedName.length < AppConstants.minNameLength) {
      return 'يجب أن يتكون الاسم من ${AppConstants.minNameLength} أحرف على الأقل';
    }

    if (trimmedPhone.isNotEmpty) {
      final digitsOnly = trimmedPhone.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.length < AppConstants.minPhoneLength) {
        return 'رقم الهاتف يجب أن يحتوي على ${AppConstants.minPhoneLength} أرقام على الأقل';
      }
    }

    return null;
  }

  /// Sanitize input to prevent SQL injection
  String _sanitizeInput(String input) {
    // Remove potentially dangerous characters
    return input.replaceAll(RegExp(r"[%;'\\]"), '');
  }

  /// Clear search cache
  Future<void> _clearSearchCache() async {
    try {
      final keys = _cacheBox?.keys.where((key) => key.toString().startsWith('search_')).toList();
      if (keys != null) {
        for (final key in keys) {
          await _cacheBox?.delete(key);
        }
      }
    } catch (e, stack) {
      await _errorLogger.logError(e, stack, context: 'CustomerService._clearSearchCache');
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      await _cacheBox?.clear();
    } catch (e, stack) {
      await _errorLogger.logError(e, stack, context: 'CustomerService.clearCache');
    }
  }
}
