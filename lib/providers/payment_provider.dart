import 'package:flutter/foundation.dart';
import '../services/payment_service.dart';

/// Provider for payment-related state management
class PaymentProvider with ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  bool _isSubmitting = false;
  String? _error;
  List<Map<String, dynamic>> _openGroups = [];
  List<Map<String, dynamic>> _staffMembers = [];
  num? _currentBalance;

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  List<Map<String, dynamic>> get openGroups => _openGroups;
  List<Map<String, dynamic>> get staffMembers => _staffMembers;
  num? get currentBalance => _currentBalance;

  /// Create a new payment
  Future<Map<String, dynamic>?> createPayment(PaymentModel payment) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _paymentService.createPayment(payment);
      _error = null;
      return result;
    } catch (e) {
      if (e is ArgumentError) {
        _error = e.message;
      } else {
        _error = 'فشل حفظ الدفعة: ${e.toString()}';
      }
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Load open groups for a customer
  Future<void> loadOpenGroups(String customerId) async {
    _error = null;
    
    try {
      _openGroups = await _paymentService.fetchOpenGroups(customerId);
    } catch (e) {
      _error = 'فشل تحميل العرابين: ${e.toString()}';
      _openGroups = [];
    }
    notifyListeners();
  }

  /// Load balance for a specific group
  Future<void> loadGroupBalance({
    required String customerId,
    required String groupKey,
  }) async {
    _error = null;
    
    try {
      _currentBalance = await _paymentService.fetchGroupBalance(
        customerId: customerId,
        groupKey: groupKey,
      );
    } catch (e) {
      _error = 'فشل تحميل الرصيد: ${e.toString()}';
      _currentBalance = null;
    }
    notifyListeners();
  }

  /// Load staff members
  Future<void> loadStaffMembers() async {
    _error = null;
    
    try {
      _staffMembers = await _paymentService.fetchStaffMembers();
    } catch (e) {
      _error = 'فشل تحميل الموظفين: ${e.toString()}';
      _staffMembers = [];
    }
    notifyListeners();
  }

  /// Clear state
  void clear() {
    _error = null;
    _openGroups = [];
    _currentBalance = null;
    notifyListeners();
  }
}
