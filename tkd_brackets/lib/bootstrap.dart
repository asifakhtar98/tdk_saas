import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:tkd_brackets/app/app.dart';
import 'package:tkd_brackets/core/config/supabase_config.dart';
import 'package:tkd_brackets/core/demo/demo_data_service.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/core/monitoring/sentry_service.dart';

/// Shared initialization for all flavors.
/// This function configures services before launching the app.
Future<void> bootstrap({
  required String environment,
  required String supabaseUrl,
  required String supabaseAnonKey,
  required String sentryDsn,
}) async {
  usePathUrlStrategy();
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // On web, always enable the semantics tree so that screen readers
  // and E2E testing tools (Playwright, Selenium) can interact with
  // Flutter-rendered content. Without this, CanvasKit renders into
  // an opaque <canvas> with no accessible DOM elements.
  if (kIsWeb) {
    binding.ensureSemantics();
  }

  // Initialize Supabase FIRST (before DI so client is available for injection)
  // Debug mode enabled only in development for network request logging.
  await SupabaseConfig.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: environment == 'development',
  );

  // Initialize Sentry with appRunner pattern
  // Empty DSN disables Sentry (development mode)
  await SentryService.initialize(
    dsn: sentryDsn,
    environment: environment,
    appRunner: () async {
      // Initialize DI container (can now inject SupabaseClient)
      configureDependencies(environment);

      // Seed demo data on first launch (after DI, before UI)
      final demoService = getIt<DemoDataService>();
      if (await demoService.shouldSeedDemoData()) {
        await demoService.seedDemoData();
      }

      runApp(const App());
    },
  );
}
