import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides Supabase initialization and access.
///
/// Must be called in bootstrap.dart BEFORE DI container initialization.
/// This ensures the Supabase.instance is available for injection.
///
/// Debug Mode: When `debug: true`, Supabase logs all network requests
/// to the console. This is helpful for troubleshooting but should never
/// be enabled in production builds.
///
/// Thread Safety: Uses a Completer pattern to handle concurrent initialization
/// attempts safely. If initialization is already in progress, concurrent
/// callers await the same result rather than double-initializing.
///
/// Usage:
/// ```dart
/// await SupabaseConfig.initialize(
///   url: 'https://project.supabase.co',
///   anonKey: 'your-anon-key',
/// );
/// final client = SupabaseConfig.client;
/// ```
class SupabaseConfig {
  SupabaseConfig._();

  static bool _initialized = false;
  static Completer<void>? _initCompleter;

  /// Whether Supabase has been initialized.
  static bool get isInitialized => _initialized;

  /// Initializes the Supabase client.
  ///
  /// Call this once at app startup, before DI container setup.
  /// If initialization is already in progress (concurrent call), awaits
  /// that initialization instead of double-initializing.
  ///
  /// Throws [ArgumentError] if [url] or [anonKey] is empty.
  /// Throws [StateError] if already initialized (not in progress).
  static Future<void> initialize({
    required String url,
    required String anonKey,
    bool debug = false,
  }) async {
    // Validate credentials before attempting initialization
    if (url.isEmpty) {
      throw ArgumentError.value(
        url,
        'url',
        'Supabase URL cannot be empty. '
            'Ensure .env has SUPABASE_URL defined.',
      );
    }
    if (anonKey.isEmpty) {
      throw ArgumentError.value(
        anonKey,
        'anonKey',
        'Supabase anon key cannot be empty. '
            'Ensure .env has SUPABASE_ANON_KEY is provided.',
      );
    }

    // Already fully initialized - throw
    if (_initialized) {
      throw StateError('SupabaseConfig.initialize() called more than once.');
    }

    // Initialization in progress - await existing completer.
    // This is the race condition fix.
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    // Start initialization
    _initCompleter = Completer<void>();

    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: debug,
        // Note: authOptions will be configured in Story 2.1 (Authentication)
        // to include PKCE flow and secure storage per architecture.
      );

      _initialized = true;
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null; // Allow retry on failure
      rethrow;
    }
  }

  /// Returns the Supabase client.
  ///
  /// Throws [StateError] if not initialized.
  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'SupabaseConfig.client accessed before initialization. '
        'Call SupabaseConfig.initialize() first.',
      );
    }
    return Supabase.instance.client;
  }

  /// Convenience getter for GoTrueClient (auth).
  static GoTrueClient get auth => client.auth;

  /// Resets initialization state for testing.
  ///
  /// WARNING: Only use in tests. Do not call in production code.
  static void resetForTesting() {
    _initialized = false;
    _initCompleter = null;
  }
}
