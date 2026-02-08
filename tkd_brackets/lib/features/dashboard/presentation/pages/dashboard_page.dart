import 'package:flutter/material.dart';

/// Dashboard placeholder page - Full implementation in Epic 3.
///
/// Displays a simple placeholder UI indicating the dashboard is coming.
/// Uses theme colors for consistent styling.
class DashboardPage extends StatelessWidget {
  /// Creates a dashboard page.
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard_outlined,
            size: 64,
            color: colorScheme.primary,
            semanticLabel: 'Dashboard icon',
          ),
          const SizedBox(height: 16),
          Text('Dashboard', style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Tournament overview coming in Epic 3',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
