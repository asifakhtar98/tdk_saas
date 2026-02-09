import 'package:flutter/material.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/core/router/app_router.dart';
import 'package:tkd_brackets/core/theme/app_theme.dart';
import 'package:tkd_brackets/core/web/web_notification.dart';

/// Root application widget.
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    // Notify the web landing page that Flutter is ready after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WebNotificationService.notifyFlutterReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appRouter = getIt<AppRouter>();

    return MaterialApp.router(
      title: 'TKD Brackets',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter.router,
    );
  }
}
