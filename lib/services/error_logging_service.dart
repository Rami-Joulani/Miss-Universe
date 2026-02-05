import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Service for logging errors and exceptions
class ErrorLoggingService {
  static final ErrorLoggingService _instance = ErrorLoggingService._internal();
  factory ErrorLoggingService() => _instance;
  ErrorLoggingService._internal();

  bool _initialized = false;

  /// Initialize Sentry for error logging
  /// Set [dsn] from environment or leave null to disable in development
  Future<void> initialize({String? dsn}) async {
    if (_initialized) return;

    // Only initialize if DSN is provided (typically in production)
    if (dsn != null && dsn.isNotEmpty) {
      await SentryFlutter.init(
        (options) {
          options.dsn = dsn;
          options.tracesSampleRate = 0.1;
          options.debug = kDebugMode;
          options.environment = kDebugMode ? 'development' : 'production';
        },
      );
      _initialized = true;
    }
  }

  /// Log an error with context
  Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? extras,
  }) async {
    // Always log to console in development
    if (kDebugMode) {
      debugPrint('❌ Error in $context: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
      if (extras != null) {
        debugPrint('Extras: $extras');
      }
    }

    // Send to Sentry if initialized
    if (_initialized) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          if (context != null) 'context': context,
          if (extras != null) ...extras,
        }),
      );
    }
  }

  /// Log a message (non-error)
  Future<void> logMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extras,
  }) async {
    if (kDebugMode) {
      debugPrint('ℹ️ $message');
    }

    if (_initialized) {
      await Sentry.captureMessage(
        message,
        level: level,
        hint: Hint.withMap(extras ?? {}),
      );
    }
  }

  /// Set user context for error tracking
  Future<void> setUser({String? id, String? email, String? name}) async {
    if (_initialized) {
      await Sentry.configureScope(
        (scope) => scope.setUser(
          SentryUser(id: id, email: email, name: name),
        ),
      );
    }
  }

  /// Clear user context (on logout)
  Future<void> clearUser() async {
    if (_initialized) {
      await Sentry.configureScope((scope) => scope.setUser(null));
    }
  }
}
