import 'package:injectable/injectable.dart';

/// Logging service interface for centralized logging.
///
/// This is registered as a lazy singleton - instantiated on first use.
@lazySingleton
class LoggerService {
  /// Logs an informational message.
  void info(String message) {
    // TODO(story-1.7): Replace with proper logging in Story 1.7 (Sentry)
    // Using print temporarily until Sentry is integrated.
    // ignore: avoid_print
    print('[INFO] $message');
  }

  /// Logs a warning message.
  void warning(String message) {
    // Using print temporarily until Sentry is integrated.
    // ignore: avoid_print
    print('[WARNING] $message');
  }

  /// Logs an error message.
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    // Using print temporarily until Sentry is integrated.
    // ignore: avoid_print
    print('[ERROR] $message');
    if (error != null) {
      // Error details for debugging.
      // ignore: avoid_print
      print(error);
    }
    if (stackTrace != null) {
      // Stack trace for debugging.
      // ignore: avoid_print
      print(stackTrace);
    }
  }
}
