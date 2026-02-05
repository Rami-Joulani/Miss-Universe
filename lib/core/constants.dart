/// Application-wide constants and enums
library;

/// Payment method types
enum PaymentMethod {
  cash('cash', 'نقدي'),
  card('card', 'بطاقة');

  const PaymentMethod(this.value, this.label);
  final String value;
  final String label;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// Payment type (deposit or final)
enum PaymentType {
  deposit('deposit', 'عربون'),
  final_('final', 'دفعة نهائية/كاملة');

  const PaymentType(this.value, this.label);
  final String value;
  final String label;

  static PaymentType fromString(String value) {
    return PaymentType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentType.deposit,
    );
  }
}

/// Sales source/channel
enum SalesSource {
  inStore('in_store', 'في المتجر'),
  whatsapp('whatsapp', 'WhatsApp'),
  instagram('instagram', 'Instagram'),
  messenger('messenger', 'Messenger');

  const SalesSource(this.value, this.label);
  final String value;
  final String label;

  static SalesSource fromString(String value) {
    return SalesSource.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SalesSource.inStore,
    );
  }
}

/// Payment/agreement status
enum PaymentStatus {
  open('open', 'مفتوح'),
  closed('closed', 'مغلق'),
  cancelled('cancelled', 'ملغي');

  const PaymentStatus(this.value, this.label);
  final String value;
  final String label;

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentStatus.open,
    );
  }
}

/// Application constants
class AppConstants {
  AppConstants._();

  // Search debounce duration
  static const searchDebounceDuration = Duration(milliseconds: 300);

  // Pagination
  static const defaultPageSize = 20;
  static const dressGridPageSize = 20;

  // Image placeholder
  static const placeholderImageUrl = 'https://placehold.co/900x1200?text=Dress';

  // Supabase storage buckets
  static const dressStorageBucket = 'dresses';

  // Validation
  static const minPasswordLength = 6;
  static const minPhoneLength = 6;
  static const minNameLength = 2;

  // Cache durations
  static const customerCacheDuration = Duration(minutes: 5);
  static const dressCacheDuration = Duration(minutes: 10);
}
