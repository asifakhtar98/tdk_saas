import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/core/router/app_router.dart';
import 'package:tkd_brackets/core/theme/app_theme.dart';
import 'package:tkd_brackets/core/web/web_notification.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_event.dart';

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
    // Dispatch initial auth check once, not on every build
    getIt<AuthenticationBloc>().add(
      const AuthenticationEvent.checkRequested(),
    );
    // Notify the web landing page that Flutter is ready
    // after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WebNotificationService.notifyFlutterReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appRouter = getIt<AppRouter>();

    return BlocProvider<AuthenticationBloc>.value(
      value: getIt<AuthenticationBloc>(),
      child: MaterialApp.router(
        title: 'TKD Brackets',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter.router,
      ),
    );
  }
}
