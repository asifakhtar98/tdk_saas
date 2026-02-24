import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Provides Sentry error tracking initialization and access.
///
/// Must be called in bootstrap.dart BEFORE DI container initialization.
/// Sentry is disabled when DSN is empty (development mode).
///
/// Usage:
/// ```dart
/// await SentryService.initialize(
///   dsn: 'https://...@sentry.io/...',
///   environment: 'production',
/// );
/// ```
class SentryService {
  SentryService._();

  static bool _initialized = false;
  static bool _enabled = false;

  /// Whether Sentry has been initialized.
  static bool get isInitialized => _initialized;

  /// Whether Sentry is enabled (DSN was provided).
  /// Use this to guard Sentry calls throughout the app.
  static bool get isEnabled => _enabled;

  /// Initializes Sentry error tracking.
  ///
  /// If [dsn] is empty, Sentry is disabled (no events sent).
  /// This allows development builds to run without Sentry configuration.
  ///
  /// [environment] should be 'development', 'staging', or 'production'.
  /// [tracesSampleRate] controls performance monitoring (0.0 to 1.0).
  /// [appRunner] is the callback to run the app after Sentry init.
  ///
  /// Throws [StateError] if called more than once.
  static Future<void> initialize({
    required String dsn,
    required String environment,
    required Future<void> Function() appRunner,
    double tracesSampleRate = 0.2,
  }) async {
    if (_initialized) {
      throw StateError('SentryService.initialize() called more than once.');
    }

    _initialized = true;

    // If DSN is empty, skip Sentry init (development mode)
    if (dsn.isEmpty) {
      _enabled = false;
      if (kDebugMode) {
        // Print is used here intentionally for development-time logging
        // since logging services are not yet initialized.
        // ignore: avoid_print
        print('[SentryService] Disabled - no DSN provided (development mode)');
      }
      await appRunner();
      return;
    }

    _enabled = true;

    await SentryFlutter.init((options) {
      options
        ..dsn = dsn
        ..environment = environment
        ..tracesSampleRate = tracesSampleRate
        // Disable in debug builds even if DSN provided
        ..debug = kDebugMode
        // Attach screenshots on crash (default is true)
        ..attachScreenshot = true
        // Track app lifecycle events as breadcrumbs
        ..enableAutoSessionTracking = true;
    }, appRunner: appRunner);
  }

  /// Captures an exception to Sentry.
  /// No-op if Sentry is disabled.
  static Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? context,
  }) async {
    if (!_enabled) return;

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      hint: context != null ? Hint.withMap({'context': context}) : null,
    );
  }

  /// Captures a message to Sentry.
  /// No-op if Sentry is disabled.
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? params,
  }) async {
    if (!_enabled) return;

    await Sentry.captureMessage(
      message,
      level: level,
      params: params?.values.toList(),
    );
  }

  /// Adds a breadcrumb for debugging context.
  /// No-op if Sentry is disabled.
  static void addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
  }) {
    if (!_enabled) return;

    Sentry.addBreadcrumb(
      Breadcrumb(message: message, category: category, data: data),
    );
  }

  /// Sets user context for all future events.
  /// No-op if Sentry is disabled.
  static void setUserContext({
    required String userId,
    String? email,
    String? organizationId,
  }) {
    if (!_enabled) return;

    Sentry.configureScope((scope) {
      scope.setUser(
        SentryUser(
          id: userId,
          email: email,
          data: organizationId != null
              ? {'organization_id': organizationId}
              : null,
        ),
      );
    });
  }

  /// Clears user context (e.g., on logout).
  /// No-op if Sentry is disabled.
  static void clearUserContext() {
    if (!_enabled) return;

    Sentry.configureScope((scope) => scope.setUser(null));
  }

  /// Resets initialization state for testing.
  /// WARNING: Only use in tests.
  @visibleForTesting
  static void resetForTesting() {
    _initialized = false;
    _enabled = false;
  }
}
