import 'package:flutter/material.dart';
import 'package:tkd_brackets/core/theme/app_theme.dart';

/// Root application widget.
/// Configures MaterialApp with theming and routing.
class App extends StatelessWidget {
  /// Creates the root App widget.
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TKD Brackets',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // TODO(story-1.3): Replace with GoRouter.
      home: const Scaffold(
        body: Center(
          child: Text('TKD Brackets - Foundation Setup Complete'),
        ),
      ),
    );
  }
}
