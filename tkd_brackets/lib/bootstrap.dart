import 'package:flutter/material.dart';
import 'package:tkd_brackets/app/app.dart';
import 'package:tkd_brackets/core/config/supabase_config.dart';
import 'package:tkd_brackets/core/di/injection.dart';

/// Shared initialization for all flavors.
/// This function configures services before launching the app.
Future<void> bootstrap({
  required String environment,
  required String supabaseUrl,
  required String supabaseAnonKey,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase FIRST (before DI so client is available for injection)
  // Debug mode enabled only in development for network request logging.
  await SupabaseConfig.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: environment == 'development',
  );

  // Initialize DI container (can now inject SupabaseClient)
  configureDependencies(environment);

  // TODO(story-1.7): Initialize Sentry.
  // await SentryFlutter.init((options) => ...);

  runApp(const App());
}
