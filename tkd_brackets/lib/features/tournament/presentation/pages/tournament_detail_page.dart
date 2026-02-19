import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/core/widgets/sync_status_indicator_widget.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/get_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/update_tournament_settings_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/delete_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/archive_tournament_usecase.dart';
import 'package:tkd_brackets/features/division/domain/usecases/get_divisions_usecase.dart';
import 'package:tkd_brackets/features/division/domain/services/conflict_detection_service.dart';
import 'package:tkd_brackets/features/tournament/presentation/bloc/tournament_detail_bloc.dart';
import 'package:tkd_brackets/features/tournament/presentation/bloc/tournament_detail_event.dart';
import 'package:tkd_brackets/features/tournament/presentation/bloc/tournament_detail_state.dart';
import 'package:tkd_brackets/features/tournament/presentation/widgets/conflict_warning_banner.dart';

class TournamentDetailPage extends StatelessWidget {
  const TournamentDetailPage({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TournamentDetailBloc(
        getIt<GetTournamentUseCase>(),
        getIt<UpdateTournamentSettingsUseCase>(),
        getIt<DeleteTournamentUseCase>(),
        getIt<ArchiveTournamentUseCase>(),
        getIt<GetDivisionsUseCase>(),
        getIt<ConflictDetectionService>(),
      )..add(TournamentDetailLoadRequested(tournamentId)),
      child: _TournamentDetailView(tournamentId: tournamentId),
    );
  }
}

class _TournamentDetailView extends StatefulWidget {
  const _TournamentDetailView({required this.tournamentId});

  final String tournamentId;

  @override
  State<_TournamentDetailView> createState() => _TournamentDetailViewState();
}

class _TournamentDetailViewState extends State<_TournamentDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<TournamentDetailBloc, TournamentDetailState>(
      listener: (context, state) {
        if (state is TournamentDetailDeleteSuccess) {
          context.go('/tournaments');
        }
        if (state is TournamentDetailLoadFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.userFriendlyMessage),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is TournamentDetailLoadInProgress) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is TournamentDetailLoadFailure) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(state.userFriendlyMessage),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/tournaments'),
                    child: const Text('Back to Tournaments'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is TournamentDetailLoadSuccess) {
          return _buildLoadedContent(context, state);
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Tournament')),
          body: const Center(child: Text('Unknown state')),
        );
      },
    );
  }

  Widget _buildLoadedContent(
    BuildContext context,
    TournamentDetailLoadSuccess state,
  ) {
    final tournament = state.tournament;
    final conflicts = state.conflicts;
    final dismissedIds = state.dismissedConflictIds;

    final visibleConflicts = conflicts
        .where((c) => !dismissedIds.contains(c.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(tournament.name),
        actions: const [SyncStatusIndicatorWidget(), SizedBox(width: 8)],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Divisions'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (visibleConflicts.isNotEmpty)
            ConflictWarningBanner(
              conflicts: visibleConflicts,
              onDismiss: (conflictId) {
                context.read<TournamentDetailBloc>().add(
                  ConflictDismissed(conflictId),
                );
              },
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, tournament, state),
                _buildDivisionsTab(context, state),
                _buildSettingsTab(context, tournament),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    TournamentEntity tournament,
    TournamentDetailLoadSuccess state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tournament.name,
                              style: textTheme.headlineSmall,
                            ),
                            _buildStatusChip(context, tournament.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  if (tournament.description != null &&
                      tournament.description!.isNotEmpty) ...[
                    Text(tournament.description!, style: textTheme.bodyLarge),
                    const SizedBox(height: 16),
                  ],
                  _buildInfoRow(
                    context,
                    Icons.calendar_today,
                    'Date',
                    tournament.scheduledDate != null
                        ? '${tournament.scheduledDate!.month}/${tournament.scheduledDate!.day}/${tournament.scheduledDate!.year}'
                        : 'Not scheduled',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.location_on,
                    'Venue',
                    tournament.venueName ?? 'Not set',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.sports_martial_arts,
                    'Federation',
                    tournament.federationType.value.toUpperCase(),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.timer,
                    'Rings',
                    '${tournament.numberOfRings}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Stats', style: textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context,
                        '${state.divisions.length}',
                        'Divisions',
                        Icons.view_column,
                      ),
                      _buildStatItem(
                        context,
                        '0',
                        'Participants',
                        Icons.people,
                      ),
                      _buildStatItem(
                        context,
                        '${tournament.numberOfRings}',
                        'Rings',
                        Icons.timer,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    context.go('/tournaments/${tournament.id}/divisions');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Divisions'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivisionsTab(
    BuildContext context,
    TournamentDetailLoadSuccess state,
  ) {
    final divisions = state.divisions;

    if (divisions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_column_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text('No divisions yet'),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                context.go('/tournaments/${widget.tournamentId}/divisions');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Divisions'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: divisions.length,
      itemBuilder: (context, index) {
        final division = divisions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(division.name),
            subtitle: Text(
              '${division.category.value} • ${division.gender.value} • Ring ${division.assignedRingNumber ?? "Unassigned"}',
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab(BuildContext context, TournamentEntity tournament) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tournament Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.sports_martial_arts),
                    title: const Text('Federation Type'),
                    subtitle: Text(
                      tournament.federationType.value.toUpperCase(),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: const Text('Number of Rings'),
                    subtitle: Text('${tournament.numberOfRings}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('Venue'),
                    subtitle: Text(tournament.venueName ?? 'Not set'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.archive),
                  title: const Text('Archive Tournament'),
                  onTap: () {
                    context.read<TournamentDetailBloc>().add(
                      TournamentDetailArchiveRequested(tournament.id),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Delete Tournament',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () => _showDeleteConfirmation(context, tournament),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, TournamentStatus status) {
    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color foregroundColor;

    switch (status) {
      case TournamentStatus.draft:
        backgroundColor = colorScheme.surfaceContainerHighest;
        foregroundColor = colorScheme.onSurfaceVariant;
        break;
      case TournamentStatus.active:
        backgroundColor = colorScheme.primaryContainer;
        foregroundColor = colorScheme.onPrimaryContainer;
        break;
      case TournamentStatus.completed:
        backgroundColor = colorScheme.tertiaryContainer;
        foregroundColor = colorScheme.onTertiaryContainer;
        break;
      case TournamentStatus.archived:
        backgroundColor = colorScheme.surfaceContainerHighest;
        foregroundColor = colorScheme.onSurfaceVariant;
        break;
      case TournamentStatus.cancelled:
        backgroundColor = colorScheme.errorContainer;
        foregroundColor = colorScheme.onErrorContainer;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.value.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: foregroundColor,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
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
              context.read<TournamentDetailBloc>().add(
                TournamentDetailDeleteRequested(tournament.id),
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
}
