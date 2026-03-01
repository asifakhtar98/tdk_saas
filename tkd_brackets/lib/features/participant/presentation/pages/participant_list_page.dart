import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/core/router/routes.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/usecases/get_divisions_usecase.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/usecases.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/participant_list_bloc.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/participant_list_event.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/participant_list_state.dart';
import 'package:tkd_brackets/features/participant/presentation/widgets/participant_card.dart';
import 'package:tkd_brackets/features/participant/presentation/widgets/participant_form_dialog.dart';
import 'package:tkd_brackets/features/participant/presentation/widgets/participant_search_bar.dart';

class ParticipantListPage extends StatelessWidget {
  const ParticipantListPage({
    required this.tournamentId,
    required this.divisionId,
    super.key,
  });

  final String tournamentId;
  final String divisionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ParticipantListBloc(
        getIt<GetDivisionParticipantsUseCase>(),
        getIt<CreateParticipantUseCase>(),
        getIt<UpdateParticipantUseCase>(),
        getIt<TransferParticipantUseCase>(),
        getIt<UpdateParticipantStatusUseCase>(),
        getIt<DeleteParticipantUseCase>(),
      )..add(ParticipantListEvent.loadRequested(divisionId: divisionId)),
      child: _ParticipantListView(
        tournamentId: tournamentId,
        divisionId: divisionId,
      ),
    );
  }
}

class _ParticipantListView extends StatelessWidget {
  const _ParticipantListView({
    required this.tournamentId,
    required this.divisionId,
  });

  final String tournamentId;
  final String divisionId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ParticipantListBloc, ParticipantListState>(
      listenWhen: (prev, curr) {
        if (prev is ParticipantListLoadSuccess &&
            curr is ParticipantListLoadSuccess) {
          return prev.actionStatus != curr.actionStatus;
        }
        return false;
      },
      listener: (context, state) {
        if (state is ParticipantListLoadSuccess) {
          if (state.actionStatus == ActionStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.actionMessage ?? 'Success')),
            );
          } else if (state.actionStatus == ActionStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionMessage ?? 'Error occurred'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      },
      builder: (context, state) {
        return state.when(
          initial: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          loadInProgress: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          loadFailure: (msg, details) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(msg),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      context.read<ParticipantListBloc>().add(
                        ParticipantListEvent.loadRequested(
                          divisionId: divisionId,
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          loadSuccess: (view, query, filter, sort, filtered, status, msg) =>
              _buildLoadedScaffold(
                context,
                view,
                query,
                filter,
                sort,
                filtered,
                status,
              ),
        );
      },
    );
  }

  Widget _buildLoadedScaffold(
    BuildContext context,
    DivisionParticipantView view,
    String query,
    ParticipantFilter filter,
    ParticipantSort sort,
    List<ParticipantEntity> filtered,
    ActionStatus status,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(view.division.name),
            Text(
              '${view.participantCount} participants',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: () => CsvImportRoute(
              tournamentId: tournamentId,
              divisionId: divisionId,
            ).go(context),
            tooltip: 'Import CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ParticipantListBloc>().add(
              const ParticipantListEvent.refreshRequested(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              ParticipantSearchBar(
                initialQuery: query,
                onSearch: (q) => context.read<ParticipantListBloc>().add(
                  ParticipantListEvent.searchQueryChanged(q),
                ),
              ),
              _buildFilterChips(context, filter),
              const Divider(),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          return ParticipantCard(
                            participant: p,
                            onStatusChange: (newStatus) {
                              if (newStatus == ParticipantStatus.disqualified) {
                                _showDisqualifyDialog(context, p.id);
                              } else {
                                context.read<ParticipantListBloc>().add(
                                  ParticipantListStatusChangeRequested(
                                    participantId: p.id,
                                    newStatus: newStatus,
                                  ),
                                );
                              }
                            },
                            onEdit: () =>
                                _showFormDialog(context, divisionId, p),
                            onDelete: () => _showDeleteConfirmation(context, p),
                            onTransfer: () => _showTransferDialog(context, p),
                          );
                        },
                      ),
              ),
            ],
          ),
          if (status == ActionStatus.inProgress)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black12,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(context, divisionId, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No participants found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Add participants manually or import'
            ' from CSV',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    ParticipantFilter activeFilter,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ParticipantFilter.values.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter == ParticipantFilter.all
                    ? 'ALL'
                    : filter.name.toUpperCase(),
              ),
              selected: activeFilter == filter,
              onSelected: (_) => context.read<ParticipantListBloc>().add(
                ParticipantListEvent.filterChanged(filter),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showFormDialog(
    BuildContext context,
    String divId,
    ParticipantEntity? participant,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => ParticipantFormDialog(
        divisionId: divId,
        participant: participant,
        onSave: (params) {
          if (params is CreateParticipantParams) {
            context.read<ParticipantListBloc>().add(
              ParticipantListEvent.createRequested(params: params),
            );
          } else if (params is UpdateParticipantParams) {
            context.read<ParticipantListBloc>().add(
              ParticipantListEvent.editRequested(params: params),
            );
          }
        },
      ),
    );
  }

  void _showDisqualifyDialog(BuildContext context, String participantId) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Disqualify Participant'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason for DQ'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isNotEmpty) {
                context.read<ParticipantListBloc>().add(
                  ParticipantListStatusChangeRequested(
                    participantId: participantId,
                    newStatus: ParticipantStatus.disqualified,
                    dqReason: reason,
                  ),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Disqualify'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ParticipantEntity participant,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Participant'),
        content: Text(
          'Are you sure you want to remove '
          '${participant.firstName} '
          '${participant.lastName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ParticipantListBloc>().add(
                ParticipantListEvent.removeRequested(
                  participantId: participant.id,
                ),
              );
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog(
    BuildContext context,
    ParticipantEntity participant,
  ) {
    final getDivisionsUseCase = getIt<GetDivisionsUseCase>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder(
          future: getDivisionsUseCase(tournamentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AlertDialog(
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final result = snapshot.data;
            if (result == null) {
              return AlertDialog(
                title: const Text('Error'),
                content: const Text('Failed to load divisions'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            return result.fold(
              (failure) => AlertDialog(
                title: const Text('Error'),
                content: Text(failure.userFriendlyMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                ],
              ),
              (divisions) {
                final otherDivisions = divisions
                    .where((d) => d.id != divisionId)
                    .toList();

                return _TransferDivisionPicker(
                  participant: participant,
                  divisions: otherDivisions,
                  onTransfer: (targetDivisionId) {
                    context.read<ParticipantListBloc>().add(
                      ParticipantListEvent.transferRequested(
                        params: TransferParticipantParams(
                          participantId: participant.id,
                          targetDivisionId: targetDivisionId,
                        ),
                      ),
                    );
                    Navigator.pop(dialogContext);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _TransferDivisionPicker extends StatefulWidget {
  const _TransferDivisionPicker({
    required this.participant,
    required this.divisions,
    required this.onTransfer,
  });

  final ParticipantEntity participant;
  final List<DivisionEntity> divisions;
  final ValueChanged<String> onTransfer;

  @override
  State<_TransferDivisionPicker> createState() =>
      _TransferDivisionPickerState();
}

class _TransferDivisionPickerState extends State<_TransferDivisionPicker> {
  String? _selectedDivisionId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Transfer ${widget.participant.firstName} '
        '${widget.participant.lastName}',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.divisions.isEmpty
            ? const Text('No other divisions available')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.divisions.length,
                itemBuilder: (context, index) {
                  final division = widget.divisions[index];
                  return RadioListTile<String>(
                    title: Text(division.name),
                    subtitle: Text(
                      '${division.category.value} • '
                      '${division.gender.value}',
                    ),
                    value: division.id,
                    // Legacy flutter feature, skipping refactor for now
                    // ignore: deprecated_member_use
                    groupValue: _selectedDivisionId,
                    // Legacy flutter feature, skipping refactor for now
                    // ignore: deprecated_member_use
                    onChanged: (v) => setState(() => _selectedDivisionId = v),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedDivisionId == null
              ? null
              : () => widget.onTransfer(_selectedDivisionId!),
          child: const Text('Transfer'),
        ),
      ],
    );
  }
}
