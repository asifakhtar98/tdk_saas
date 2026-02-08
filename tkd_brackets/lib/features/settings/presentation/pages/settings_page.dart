import 'package:flutter/material.dart';

/// Settings placeholder page - Full implementation in Epic 2+.
///
/// Displays a simple placeholder UI indicating settings are coming.
/// Uses theme colors for consistent styling.
class SettingsPage extends StatelessWidget {
  /// Creates a settings page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings_outlined,
            size: 64,
            color: colorScheme.primary,
            semanticLabel: 'Settings icon',
          ),
          const SizedBox(height: 16),
          Text('Settings', style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'App settings coming in Epic 2',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
