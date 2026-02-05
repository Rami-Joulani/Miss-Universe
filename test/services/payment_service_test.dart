import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_showroom/services/payment_service.dart';
import 'package:wedding_showroom/core/constants.dart';

/// Unit tests for PaymentService
/// 
/// Run with: flutter test test/services/payment_service_test.dart
void main() {
  group('PaymentService', () {
    late PaymentService service;

    setUp(() {
      service = PaymentService();
    });

    group('validatePayment', () {
      test('returns error when amount is zero', () {
        final payment = PaymentModel(
          amount: 0,
          method: PaymentMethod.cash,
          type: PaymentType.deposit,
          customerId: 'test-id',
          paidAt: DateTime.now(),
          source: SalesSource.inStore,
          expectedTotal: 1000,
        );

        final error = service.validatePayment(payment);
        
        expect(error, isNotNull);
        expect(error, contains('أكبر من الصفر'));
      });

      test('returns error when amount is negative', () {
        final payment = PaymentModel(
          amount: -100,
          method: PaymentMethod.cash,
          type: PaymentType.deposit,
          customerId: 'test-id',
          paidAt: DateTime.now(),
          source: SalesSource.inStore,
          expectedTotal: 1000,
        );

        final error = service.validatePayment(payment);
        
        expect(error, isNotNull);
      });

      test('returns error for deposit without expected total', () {
        final payment = PaymentModel(
          amount: 500,
          method: PaymentMethod.cash,
          type: PaymentType.deposit,
          customerId: 'test-id',
          paidAt: DateTime.now(),
          source: SalesSource.inStore,
          // expectedTotal is null
        );

        final error = service.validatePayment(payment);
        
        expect(error, isNotNull);
        expect(error, contains('المبلغ المتوقع'));
      });

      test('returns error when deposit exceeds expected total', () {
        final payment = PaymentModel(
          amount: 1500,
          method: PaymentMethod.cash,
          type: PaymentType.deposit,
          customerId: 'test-id',
          paidAt: DateTime.now(),
          source: SalesSource.inStore,
          expectedTotal: 1000,
        );

        final error = service.validatePayment(payment);
        
        expect(error, isNotNull);
        expect(error, contains('أقل من المبلغ المتوقع'));
      });

      test('returns error for final payment without group key', () {
        final payment = PaymentModel(
          amount: 500,
          method: PaymentMethod.cash,
          type: PaymentType.final_,
          customerId: 'test-id',
          paidAt: DateTime.now(),
          source: SalesSource.inStore,
          // groupKey is null
        );

        final error = service.validatePayment(payment);
        
        expect(error, isNotNull);
        expect(error, contains('العربون المرتبط'));
      });

      test('returns null for valid deposit payment', () {
        final payment = PaymentModel(
          amount: 500,
          method: PaymentMethod.cash,
          type: PaymentType.deposit,
          customerId: 'test-id',
          paidAt: DateTime.now(),
          source: SalesSource.inStore,
          expectedTotal: 1000,
        );

        final error = service.validatePayment(payment);
        
        expect(error, isNull);
      });

      test('returns null for valid final payment', () {
        final payment = PaymentModel(
          amount: 500,
          method: PaymentMethod.card,
          type: PaymentType.final_,
          customerId: 'test-id',
          paidAt: DateTime.now(),
          source: SalesSource.whatsapp,
          groupKey: 'existing-group-key',
        );

        final error = service.validatePayment(payment);
        
        expect(error, isNull);
      });

      test('accepts deposit equal to expected total', () {
        final payment = PaymentModel(
          amount: 1000,
          method: PaymentMethod.cash,
          type: PaymentType.deposit,
          customerId: 'test-id',
          paidAt: DateTime.now(),
          source: SalesSource.inStore,
          expectedTotal: 1000,
        );

        final error = service.validatePayment(payment);
        
        expect(error, isNull);
      });
    });
  });
}
