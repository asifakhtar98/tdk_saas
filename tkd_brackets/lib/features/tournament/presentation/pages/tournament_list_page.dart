import 'package:flutter/material.dart';

/// Tournament list placeholder page - Full implementation in Epic 3.
///
/// Displays a simple placeholder UI indicating tournament list is coming.
/// Uses theme colors for consistent styling.
class TournamentListPage extends StatelessWidget {
  /// Creates a tournament list page.
  const TournamentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: colorScheme.primary,
            semanticLabel: 'Tournaments icon',
          ),
          const SizedBox(height: 16),
          Text('Tournaments', style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Tournament management coming in Epic 3',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
