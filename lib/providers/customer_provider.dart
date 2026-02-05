import 'package:flutter/foundation.dart';
import '../services/customer_service.dart';

/// Provider for customer-related state management
class CustomerProvider with ChangeNotifier {
  final CustomerService _customerService = CustomerService();

  List<CustomerModel> _searchResults = [];
  bool _isSearching = false;
  String? _error;

  List<CustomerModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get error => _error;

  /// Search customers with debouncing handled at UI level
  Future<void> searchCustomers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _error = null;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _customerService.searchCustomers(query);
      _error = null;
    } catch (e) {
      _error = 'فشل البحث: ${e.toString()}';
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Create a new customer
  Future<CustomerModel?> createCustomer({
    required String name,
    required String phone,
  }) async {
    _error = null;

    try {
      final customer = await _customerService.createCustomer(
        name: name,
        phone: phone,
      );
      
      // Clear search results to force a refresh
      _searchResults = [];
      notifyListeners();
      
      return customer;
    } catch (e) {
      if (e is ArgumentError) {
        _error = e.message;
      } else {
        _error = 'فشل إضافة الزبون: ${e.toString()}';
      }
      notifyListeners();
      return null;
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    _error = null;
    notifyListeners();
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _customerService.clearCache();
    _searchResults = [];
    notifyListeners();
  }
}
