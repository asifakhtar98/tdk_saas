import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/services/logger_service.dart';

/// Centralized error reporting service for handling and logging errors.
///
/// This service provides a unified interface for reporting errors throughout
/// the application. It integrates with the logging infrastructure and is
/// designed for future Sentry integration (Story 1.7).
///
/// All use cases and repositories should use this service to report errors
/// rather than logging directly.
@lazySingleton
class ErrorReportingService {
  ErrorReportingService(this._loggerService);

  final LoggerService _loggerService;

  /// Reports a domain-layer Failure.
  ///
  /// Use this method when a use case or repository encounters a Failure.
  /// The userFriendlyMessage is logged at warning level, and technicalDetails
  /// (if available) are logged at error level.
  void reportFailure(Failure failure) {
    _loggerService.warning(
      'Failure: ${failure.runtimeType} - ${failure.userFriendlyMessage}',
    );

    if (failure.technicalDetails != null) {
      _loggerService.error(
        'Technical details: ${failure.technicalDetails}',
      );
    }

    // TODO(story-1.7): Send to Sentry when integrated
    // await Sentry.captureMessage(
    //   failure.userFriendlyMessage,
    //   level: SentryLevel.warning,
    //   params: {'type': failure.runtimeType.toString()},
    // );
  }

  /// Reports a data-layer Exception with stack trace.
  ///
  /// Use this method when catching exceptions in data sources or repositories.
  /// The exception message and stack trace are logged.
  void reportException(
    Object exception,
    StackTrace stackTrace, {
    String? context,
  }) {
    final contextPrefix = context != null ? '[$context] ' : '';
    _loggerService.error(
      '${contextPrefix}Exception: ${exception.runtimeType}',
      exception,
      stackTrace,
    );

    // TODO(story-1.7): Send to Sentry when integrated
    // await Sentry.captureException(
    //   exception,
    //   stackTrace: stackTrace,
    //   hint: Hint.withMap({'context': context}),
    // );
  }

  /// Reports a generic error message.
  ///
  /// Use this method for general error reporting when you don't have a
  /// structured Failure or Exception.
  void reportError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _loggerService.error(message, error, stackTrace);

    // TODO(story-1.7): Send to Sentry when integrated
    // await Sentry.captureMessage(message, level: SentryLevel.error);
  }

  /// Adds a breadcrumb for tracking user actions.
  ///
  /// Breadcrumbs provide context for debugging by tracking the sequence
  /// of events leading up to an error. Full implementation in Story 1.7.
  void addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
  }) {
    // Log breadcrumb locally for now
    final categoryPrefix = category != null ? '[$category] ' : '';
    _loggerService.info('Breadcrumb: $categoryPrefix$message');

    // TODO(story-1.7): Add Sentry breadcrumb when integrated
    // Sentry.addBreadcrumb(Breadcrumb(
    //   message: message,
    //   category: category,
    //   data: data,
    // ));
  }

  /// Sets user context for error tracking.
  ///
  /// Call this after successful authentication to associate errors with users.
  void setUserContext({
    required String userId,
    String? email,
    String? organizationId,
  }) {
    _loggerService.info(
      'User context set: userId=$userId, orgId=$organizationId',
    );

    // TODO(story-1.7): Set Sentry user when integrated
    // Sentry.configureScope((scope) {
    //   scope.setUser(SentryUser(
    //     id: userId,
    //     email: email,
    //     data: {'organization_id': organizationId},
    //   ));
    // });
  }

  /// Clears user context (e.g., on logout).
  void clearUserContext() {
    _loggerService.info('User context cleared');

    // TODO(story-1.7): Clear Sentry user when integrated
    // Sentry.configureScope((scope) => scope.setUser(null));
  }
}
