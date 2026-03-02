import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_bloc.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_event.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_state.dart';
import 'package:tkd_brackets/features/bracket/presentation/widgets/bracket_viewer_widget.dart';
import 'package:tkd_brackets/features/bracket/presentation/widgets/round_robin_table_widget.dart';

class BracketPage extends StatelessWidget {
  final String bracketId;

  const BracketPage({required this.bracketId, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BracketBloc>(
      create: (context) =>
          getIt<BracketBloc>()..add(BracketLoadRequested(bracketId: bracketId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bracket Viewer'),
          actions: [
            BlocBuilder<BracketBloc, BracketState>(
              builder: (context, state) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state is BracketLoadSuccess)
                      IconButton(
                        icon: Icon(
                          state.bracket.isFinalized
                              ? Icons.lock
                              : Icons.lock_open,
                        ),
                        onPressed: () => context.read<BracketBloc>().add(
                          state.bracket.isFinalized
                              ? const BracketUnlockRequested()
                              : const BracketLockRequested(),
                        ),
                        tooltip: state.bracket.isFinalized
                            ? 'Unlock Bracket'
                            : 'Lock Bracket',
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => context.read<BracketBloc>().add(
                        const BracketRefreshRequested(),
                      ),
                      tooltip: 'Refresh',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<BracketBloc, BracketState>(
          builder: (context, state) {
            return switch (state) {
              BracketInitial() ||
              BracketLoadInProgress() ||
              BracketLockInProgress() ||
              BracketUnlockInProgress() => const Center(
                child: CircularProgressIndicator(),
              ),
              BracketLoadFailure(:final userFriendlyMessage) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(userFriendlyMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<BracketBloc>().add(
                        const BracketRefreshRequested(),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              BracketLoadSuccess(
                :final bracket,
                :final matches,
                :final layout,
                :final selectedMatchId,
              ) =>
                bracket.bracketType == BracketType.pool
                    ? RoundRobinTableWidget(matches: matches)
                    : BracketViewerWidget(
                        layout: layout,
                        matches: matches,
                        selectedMatchId: selectedMatchId,
                        onMatchTap: (id) => context.read<BracketBloc>().add(
                          BracketMatchSelected(id),
                        ),
                      ),
              _ => const Center(child: CircularProgressIndicator()),
            };
          },
        ),
      ),
    );
  }
}
