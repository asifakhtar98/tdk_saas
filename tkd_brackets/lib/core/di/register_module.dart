import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/core/config/supabase_config.dart';

/// Module for registering third-party libraries and external dependencies.
///
/// These are dependencies that cannot use @injectable annotations directly.
@module
abstract class RegisterModule {
  /// Provides the SupabaseClient as a lazySingleton.
  ///
  /// Requires SupabaseConfig.initialize() to be called before DI setup.
  @lazySingleton
  SupabaseClient get supabaseClient => SupabaseConfig.client;

  // Placeholder for future third-party registrations:
  // - Sentry service (Story 1.7)
  // - Other external services as needed
}
