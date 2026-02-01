import 'package:flutter/material.dart';
import 'package:tkd_brackets/app/app.dart';

/// Shared initialization for all flavors.
/// This function configures services before launching the app.
Future<void> bootstrap({
  required String environment,
  required String supabaseUrl,
  required String supabaseAnonKey,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO(story-1.2): Initialize DI container.
  // await configureDependencies(environment);
  
  // TODO(story-1.6): Initialize Supabase.
  // await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  
  // TODO(story-1.7): Initialize Sentry.
  // await SentryFlutter.init((options) => ...);
  
  runApp(const App());
}
