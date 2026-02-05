import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import 'error_logging_service.dart';

/// Payment model
class PaymentModel {
  final String? id;
  final num amount;
  final PaymentMethod method;
  final PaymentType type;
  final String customerId;
  final DateTime paidAt;
  final String? notes;
  final String? agreementLabel;
  final String? dressText;
  final SalesSource source;
  final num? expectedTotal;
  final String? groupKey;
  final String? receivedByStaffId;

  PaymentModel({
    this.id,
    required this.amount,
    required this.method,
    required this.type,
    required this.customerId,
    required this.paidAt,
    this.notes,
    this.agreementLabel,
    this.dressText,
    required this.source,
    this.expectedTotal,
    this.groupKey,
    this.receivedByStaffId,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'method': method.value,
      'type': type.value,
      'customer_id': customerId,
      'paid_at': paidAt.toUtc().toIso8601String(),
      if (notes != null) 'notes': notes,
      if (agreementLabel != null) 'agreement_label': agreementLabel,
      if (dressText != null) 'dress_text': dressText,
      'source': source.value,
      if (expectedTotal != null) 'expected_total': expectedTotal,
      if (groupKey != null) 'group_key': groupKey,
      if (receivedByStaffId != null) 'received_by_staff_id': receivedByStaffId,
    };
  }
}

/// Service for managing payment operations
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final _errorLogger = ErrorLoggingService();

  /// Create a new payment
  Future<Map<String, dynamic>> createPayment(PaymentModel payment) async {
    // Validate payment
    final validationError = validatePayment(payment);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    try {
      final payload = payment.toJson();

      final res = await Supabase.instance.client
          .from('payments')
          .insert(payload)
          .select('id, group_key')
          .single();

      return Map<String, dynamic>.from(res as Map);
    } catch (e, stack) {
      await _errorLogger.logError(
        e,
        stack,
        context: 'PaymentService.createPayment',
        extras: {'customerId': payment.customerId, 'amount': payment.amount},
      );
      rethrow;
    }
  }

  /// Validate payment data
  String? validatePayment(PaymentModel payment) {
    if (payment.amount <= 0) {
      return 'يجب أن يكون المبلغ أكبر من الصفر';
    }

    if (payment.type == PaymentType.deposit && payment.expectedTotal == null) {
      return 'يجب إدخال المبلغ المتوقع للفاتورة الكاملة عند العربون';
    }

    if (payment.type == PaymentType.deposit && 
        payment.expectedTotal != null && 
        payment.amount > payment.expectedTotal!) {
      return 'مبلغ العربون يجب أن يكون أقل من المبلغ المتوقع';
    }

    if (payment.type == PaymentType.final_ && payment.groupKey == null) {
      return 'يجب اختيار العربون المرتبط للدفعة النهائية';
    }

    return null;
  }

  /// Fetch balance for a customer's open group
  Future<num?> fetchGroupBalance({
    required String customerId,
    required String groupKey,
  }) async {
    try {
      final rows = await Supabase.instance.client
          .from('v_customer_balances')
          .select('balance')
          .eq('customer_id', customerId)
          .eq('group_key', groupKey)
          .limit(1);

      if (rows.isNotEmpty) {
        final balance = rows.first['balance'];
        return balance is num ? balance : num.tryParse('$balance');
      }
      return null;
    } catch (e, stack) {
      await _errorLogger.logError(
        e,
        stack,
        context: 'PaymentService.fetchGroupBalance',
        extras: {'customerId': customerId, 'groupKey': groupKey},
      );
      rethrow;
    }
  }

  /// Fetch open groups for a customer
  Future<List<Map<String, dynamic>>> fetchOpenGroups(String customerId) async {
    try {
      final data = await Supabase.instance.client
          .from('v_customer_balances')
          .select('group_key,agreement_label,expected_total,paid,balance,status,opened_at')
          .eq('customer_id', customerId)
          .eq('status', PaymentStatus.open.value)
          .order('opened_at', ascending: false);

      return (data as List)
          .map((json) => Map<String, dynamic>.from(json as Map))
          .toList();
    } catch (e, stack) {
      await _errorLogger.logError(
        e,
        stack,
        context: 'PaymentService.fetchOpenGroups',
        extras: {'customerId': customerId},
      );
      rethrow;
    }
  }

  /// Fetch staff members
  Future<List<Map<String, dynamic>>> fetchStaffMembers() async {
    try {
      final data = await Supabase.instance.client
          .from('staff')
          .select('id,name,is_active')
          .eq('is_active', true)
          .order('name');

      return (data as List)
          .map((json) => Map<String, dynamic>.from(json as Map))
          .toList();
    } catch (e, stack) {
      await _errorLogger.logError(e, stack, context: 'PaymentService.fetchStaffMembers');
      rethrow;
    }
  }
}
