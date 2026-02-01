import 'package:flutter/material.dart';
import 'package:tkd_brackets/app/app.dart';
import 'package:tkd_brackets/core/di/injection.dart';

/// Shared initialization for all flavors.
/// This function configures services before launching the app.
Future<void> bootstrap({
  required String environment,
  required String supabaseUrl,
  required String supabaseAnonKey,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize DI container FIRST (sync call per injectable pattern)
  configureDependencies(environment);

  // TODO(story-1.6): Initialize Supabase.
  // await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // TODO(story-1.7): Initialize Sentry.
  // await SentryFlutter.init((options) => ...);

  runApp(const App());
}
