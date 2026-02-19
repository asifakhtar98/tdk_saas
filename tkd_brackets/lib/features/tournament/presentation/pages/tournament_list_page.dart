import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/core/widgets/sync_status_indicator_widget.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/get_tournaments_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/archive_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/delete_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/create_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/presentation/bloc/tournament_bloc.dart';
import 'package:tkd_brackets/features/tournament/presentation/bloc/tournament_event.dart';
import 'package:tkd_brackets/features/tournament/presentation/bloc/tournament_state.dart';
import 'package:tkd_brackets/features/tournament/presentation/widgets/tournament_card.dart';
import 'package:tkd_brackets/features/tournament/presentation/widgets/tournament_form_dialog.dart';

class TournamentListPage extends StatelessWidget {
  const TournamentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TournamentBloc(
        getIt<GetTournamentsUseCase>(),
        getIt<ArchiveTournamentUseCase>(),
        getIt<DeleteTournamentUseCase>(),
        getIt<CreateTournamentUseCase>(),
      )..add(const TournamentLoadRequested()),
      child: const _TournamentListView(),
    );
  }
}

class _TournamentListView extends StatelessWidget {
  const _TournamentListView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
        actions: const [SyncStatusIndicatorWidget(), SizedBox(width: 8)],
      ),
      body: BlocConsumer<TournamentBloc, TournamentState>(
        listener: (context, state) {
          if (state is TournamentLoadFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.userFriendlyMessage),
                backgroundColor: colorScheme.error,
              ),
            );
          }
          if (state is TournamentCreateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tournament created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
          if (state is TournamentCreateFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.userFriendlyMessage),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TournamentLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TournamentLoadFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load tournaments',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(state.userFriendlyMessage),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      context.read<TournamentBloc>().add(
                        const TournamentRefreshRequested(),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is TournamentLoadSuccess) {
            return Column(
              children: [
                _buildFilterChips(context, state.currentFilter),
                Expanded(
                  child: state.tournaments.isEmpty
                      ? _buildEmptyState(context)
                      : _buildTournamentList(context, state.tournaments),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Tournament'),
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    TournamentFilter currentFilter,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: currentFilter == TournamentFilter.all,
            onSelected: (_) {
              context.read<TournamentBloc>().add(
                const TournamentFilterChanged(TournamentFilter.all),
              );
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Draft'),
            selected: currentFilter == TournamentFilter.draft,
            onSelected: (_) {
              context.read<TournamentBloc>().add(
                const TournamentFilterChanged(TournamentFilter.draft),
              );
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Active'),
            selected: currentFilter == TournamentFilter.active,
            onSelected: (_) {
              context.read<TournamentBloc>().add(
                const TournamentFilterChanged(TournamentFilter.active),
              );
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Archived'),
            selected: currentFilter == TournamentFilter.archived,
            onSelected: (_) {
              context.read<TournamentBloc>().add(
                const TournamentFilterChanged(TournamentFilter.archived),
              );
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TournamentBloc>().add(
                const TournamentRefreshRequested(),
              );
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No tournaments yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first tournament to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Tournament'),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentList(
    BuildContext context,
    List<TournamentEntity> tournaments,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<TournamentBloc>().add(const TournamentRefreshRequested());
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tournaments.length,
        itemBuilder: (context, index) {
          final tournament = tournaments[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TournamentCard(
              tournament: tournament,
              onTap: () {
                context.go('/tournaments/${tournament.id}');
              },
              onDelete: () => _showDeleteConfirmation(context, tournament),
              onArchive: tournament.status != TournamentStatus.archived
                  ? () => _archiveTournament(context, tournament)
                  : null,
            ),
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => TournamentFormDialog(
        onSave: (name, description, scheduledDate) {
          if (scheduledDate != null) {
            context.read<TournamentBloc>().add(
              TournamentCreateRequested(
                name: name,
                description: description,
                scheduledDate: scheduledDate,
              ),
            );
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    TournamentEntity tournament,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Tournament'),
        content: Text(
          'Are you sure you want to delete "${tournament.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<TournamentBloc>().add(
                TournamentDeleted(tournament.id),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _archiveTournament(BuildContext context, TournamentEntity tournament) {
    context.read<TournamentBloc>().add(TournamentArchived(tournament.id));
  }
}
