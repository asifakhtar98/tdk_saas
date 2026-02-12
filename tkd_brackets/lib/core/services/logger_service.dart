import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Logging service interface for centralized logging.
///
/// This is registered as a lazy singleton - instantiated on first use.
@lazySingleton
class LoggerService {
  final _logger = Logger();

  /// Logs an informational message.
  void info(String message) {
    // TODO(story-1.7): Replace with proper logging in Story 1.7 (Sentry)
    // Using print temporarily until Sentry is integrated.
    
    _logger.i(message);
  }

  /// Logs a warning message.
  void warning(String message) {
    // Using print temporarily until Sentry is integrated.
    
    _logger.w(message);
  }

  /// Logs an error message.
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    // Using print temporarily until Sentry is integrated.
    
    // Error details for debugging.
    // Stack trace for debugging.
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
