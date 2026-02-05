import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_showroom/services/customer_service.dart';
import 'package:wedding_showroom/core/constants.dart';

/// Unit tests for CustomerService
/// 
/// Run with: flutter test test/services/customer_service_test.dart
void main() {
  group('CustomerService', () {
    late CustomerService service;

    setUp(() {
      service = CustomerService();
    });

    group('validateCustomerInput', () {
      test('returns error when both name and phone are empty', () {
        final error = service.validateCustomerInput(name: '', phone: '');
        
        expect(error, isNotNull);
        expect(error, contains('يجب إدخال'));
      });

      test('returns error when name is too short', () {
        final error = service.validateCustomerInput(name: 'A', phone: '');
        
        expect(error, isNotNull);
        expect(error, contains('${AppConstants.minNameLength} أحرف'));
      });

      test('returns error when phone is too short', () {
        final error = service.validateCustomerInput(name: '', phone: '12345');
        
        expect(error, isNotNull);
        expect(error, contains('${AppConstants.minPhoneLength} أرقام'));
      });

      test('returns null for valid name only', () {
        final error = service.validateCustomerInput(
          name: 'John Doe',
          phone: '',
        );
        
        expect(error, isNull);
      });

      test('returns null for valid phone only', () {
        final error = service.validateCustomerInput(
          name: '',
          phone: '1234567890',
        );
        
        expect(error, isNull);
      });

      test('returns null for valid name and phone', () {
        final error = service.validateCustomerInput(
          name: 'John Doe',
          phone: '1234567890',
        );
        
        expect(error, isNull);
      });

      test('handles phone numbers with formatting characters', () {
        final error = service.validateCustomerInput(
          name: 'John',
          phone: '+1 (555) 123-4567',
        );
        
        expect(error, isNull);
      });

      test('trims whitespace from inputs', () {
        final error = service.validateCustomerInput(
          name: '  John Doe  ',
          phone: '  1234567890  ',
        );
        
        expect(error, isNull);
      });
    });
  });
}
