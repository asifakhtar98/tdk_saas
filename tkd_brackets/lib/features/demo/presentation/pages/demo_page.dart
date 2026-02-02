import 'package:flutter/material.dart';
import 'package:tkd_brackets/core/router/routes.dart';

/// Demo mode page - explore app without account.
/// Full implementation in Story 1.11 (Demo Mode Data Seeding).
class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Mode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => const HomeRoute().go(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.science_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text('Demo Mode', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Explore TKD Brackets without creating an account.\n'
                'Your data is stored locally until you sign up.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => const TournamentListRoute().go(context),
                icon: const Icon(Icons.emoji_events),
                label: const Text('View Tournaments'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
