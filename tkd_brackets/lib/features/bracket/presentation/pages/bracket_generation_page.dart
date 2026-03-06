import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_generation_bloc.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_generation_event.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_generation_state.dart';
import 'package:tkd_brackets/features/bracket/presentation/widgets/bracket_format_selection_dialog.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';


class BracketGenerationPage extends StatelessWidget {
  const BracketGenerationPage({
    required this.tournamentId,
    required this.divisionId,
    super.key,
  });

  final String tournamentId;
  final String divisionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BracketGenerationBloc>(
      create: (context) => getIt<BracketGenerationBloc>()
        ..add(BracketGenerationLoadRequested(divisionId: divisionId)),
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<BracketGenerationBloc, BracketGenerationState>(
            builder: (context, state) {
              if (state is BracketGenerationLoadSuccess) {
                return Text('${state.division.name} Brackets');
              }
              return const Text('Bracket Generation');
            },
          ),
          actions: [
            BlocBuilder<BracketGenerationBloc, BracketGenerationState>(
              builder: (context, state) {
                if (state is BracketGenerationLoadSuccess) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.existingBrackets.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => _showRegenerateConfirmation(context),
                          tooltip: 'Regenerate Bracket',
                        ),
                      IconButton(
                        icon: const Icon(Icons.sync),
                        onPressed: () => context
                            .read<BracketGenerationBloc>()
                            .add(BracketGenerationLoadRequested(
                                divisionId: divisionId)),
                        tooltip: 'Refresh',
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocListener<BracketGenerationBloc, BracketGenerationState>(
          listener: (context, state) {
            if (state is BracketGenerationSuccess) {
              context.go(
                '/tournaments/$tournamentId/divisions/$divisionId/brackets/${state.generatedBracketId}',
              );
            }
          },
          child: BlocBuilder<BracketGenerationBloc, BracketGenerationState>(
            builder: (context, state) {
              return switch (state) {
                BracketGenerationInitial() ||
                BracketGenerationLoadInProgress() ||
                BracketGenerationInProgress() =>
                  const Center(child: CircularProgressIndicator()),
                BracketGenerationLoadFailure(
                  :final userFriendlyMessage,
                  :final technicalDetails
                ) =>
                  _buildErrorState(context, userFriendlyMessage, technicalDetails),
                BracketGenerationLoadSuccess(
                  :final division,
                  :final participants,
                  :final existingBrackets
                ) =>
                  _buildContent(context, division, participants, existingBrackets),
                BracketGenerationSuccess() =>
                  const Center(child: CircularProgressIndicator()),
                _ => const Center(child: CircularProgressIndicator()),
              };
            },
          ),
        ),
        floatingActionButton:
            BlocBuilder<BracketGenerationBloc, BracketGenerationState>(
          builder: (context, state) {
            if (state is BracketGenerationLoadSuccess &&
                state.existingBrackets.isEmpty) {
              return FloatingActionButton.extended(
                onPressed: () => _handleFormatSelection(context),
                label: const Text('Generate Bracket'),
                icon: const Icon(Icons.add),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String message,
    String? details,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<BracketGenerationBloc>().add(
                    BracketGenerationLoadRequested(divisionId: divisionId),
                  ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DivisionEntity division,
    List<ParticipantEntity> participants,
    List<BracketEntity> existingBrackets,
  ) {
    if (existingBrackets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '${participants.length} participants available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('No brackets generated yet for this division.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: existingBrackets.length,
      itemBuilder: (context, index) {
        final bracket = existingBrackets[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.account_tree),
            title: Text(_getBracketLabel(bracket.bracketType)),
            subtitle: Text(
                'Created: ${bracket.createdAtTimestamp.toLocal().toString().split('.')[0]}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(
              '/tournaments/$tournamentId/divisions/$divisionId/brackets/${bracket.id}',
            ),
          ),
        );
      },
    );
  }

  String _getBracketLabel(BracketType type) {
    return switch (type) {
      BracketType.winners => 'Winners Bracket',
      BracketType.losers => 'Losers Bracket',
      BracketType.pool => 'Pool Play',
    };

  }

  Future<void> _handleFormatSelection(BuildContext context) async {
    final bloc = context.read<BracketGenerationBloc>();
    final format = await BracketFormatSelectionDialog.show(context);
    if (format != null) {
      bloc.add(BracketGenerationFormatSelected(format));
      bloc.add(const BracketGenerationGenerateRequested());
    }
  }

  Future<void> _showRegenerateConfirmation(BuildContext context) async {
    final bloc = context.read<BracketGenerationBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Bracket?'),
        content: const Text(
          'This will delete the existing bracket and its matches. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Regenerate', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      bloc.add(const BracketGenerationRegenerateRequested());
    }
  }
}
