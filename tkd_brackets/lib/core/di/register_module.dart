import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/core/config/supabase_config.dart';
import 'package:uuid/uuid.dart';

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

  /// Provides a [Connectivity] instance for network interface monitoring.
  @lazySingleton
  Connectivity get connectivity => Connectivity();

  /// Provides an [InternetConnection] instance for internet reachability
  /// checks.
  @lazySingleton
  InternetConnection get internetConnection => InternetConnection();

  @lazySingleton
  Uuid get uuid => const Uuid();
}
