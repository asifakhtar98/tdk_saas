import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/usecases.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/participant_list_event.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/participant_list_state.dart';

@injectable
class ParticipantListBloc
    extends Bloc<ParticipantListEvent, ParticipantListState> {
  ParticipantListBloc(
    this._getDivisionParticipantsUseCase,
    this._createParticipantUseCase,
    this._updateParticipantUseCase,
    this._transferParticipantUseCase,
    this._updateParticipantStatusUseCase,
    this._deleteParticipantUseCase,
  ) : super(const ParticipantListInitial()) {
    on<ParticipantListLoadRequested>(_onLoadRequested);
    on<ParticipantListRefreshRequested>(_onRefreshRequested);
    on<ParticipantListSearchQueryChanged>(_onSearchQueryChanged);
    on<ParticipantListFilterChanged>(_onFilterChanged);
    on<ParticipantListSortChanged>(_onSortChanged);
    on<ParticipantListCreateRequested>(_onCreateRequested);
    on<ParticipantListEditRequested>(_onEditRequested);
    on<ParticipantListStatusChangeRequested>(_onStatusChangeRequested);
    on<ParticipantListTransferRequested>(_onTransferRequested);
    on<ParticipantListRemoveRequested>(_onRemoveRequested);
  }

  final GetDivisionParticipantsUseCase _getDivisionParticipantsUseCase;
  final CreateParticipantUseCase _createParticipantUseCase;
  final UpdateParticipantUseCase _updateParticipantUseCase;
  final TransferParticipantUseCase _transferParticipantUseCase;
  final UpdateParticipantStatusUseCase _updateParticipantStatusUseCase;
  final DeleteParticipantUseCase _deleteParticipantUseCase;

  String? _currentDivisionId;

  Future<void> _onLoadRequested(
    ParticipantListLoadRequested event,
    Emitter<ParticipantListState> emit,
  ) async {
    emit(const ParticipantListLoadInProgress());
    _currentDivisionId = event.divisionId;
    await _loadParticipants(emit);
  }

  Future<void> _onRefreshRequested(
    ParticipantListRefreshRequested event,
    Emitter<ParticipantListState> emit,
  ) async {
    if (_currentDivisionId == null) return;
    await _loadParticipants(emit);
  }

  Future<void> _loadParticipants(Emitter<ParticipantListState> emit) async {
    if (_currentDivisionId == null) return;

    final result = await _getDivisionParticipantsUseCase(_currentDivisionId!);

    result.fold(
      (failure) => emit(
        ParticipantListLoadFailure(
          userFriendlyMessage: failure.userFriendlyMessage,
          technicalDetails: failure.technicalDetails,
        ),
      ),
      (view) {
        final query = state is ParticipantListLoadSuccess
            ? (state as ParticipantListLoadSuccess).searchQuery
            : '';
        final filter = state is ParticipantListLoadSuccess
            ? (state as ParticipantListLoadSuccess).currentFilter
            : ParticipantFilter.all;
        final sort = state is ParticipantListLoadSuccess
            ? (state as ParticipantListLoadSuccess).currentSort
            : ParticipantSort.nameAsc;

        emit(
          ParticipantListLoadSuccess(
            view: view,
            searchQuery: query,
            currentFilter: filter,
            currentSort: sort,
            filteredParticipants: _processParticipants(
              view.participants,
              query,
              filter,
              sort,
            ),
          ),
        );
      },
    );
  }

  void _onSearchQueryChanged(
    ParticipantListSearchQueryChanged event,
    Emitter<ParticipantListState> emit,
  ) {
    final currentState = state;
    if (currentState is! ParticipantListLoadSuccess) return;

    emit(
      currentState.copyWith(
        searchQuery: event.query,
        filteredParticipants: _processParticipants(
          currentState.view.participants,
          event.query,
          currentState.currentFilter,
          currentState.currentSort,
        ),
      ),
    );
  }

  void _onFilterChanged(
    ParticipantListFilterChanged event,
    Emitter<ParticipantListState> emit,
  ) {
    final currentState = state;
    if (currentState is! ParticipantListLoadSuccess) return;

    emit(
      currentState.copyWith(
        currentFilter: event.filter,
        filteredParticipants: _processParticipants(
          currentState.view.participants,
          currentState.searchQuery,
          event.filter,
          currentState.currentSort,
        ),
      ),
    );
  }

  void _onSortChanged(
    ParticipantListSortChanged event,
    Emitter<ParticipantListState> emit,
  ) {
    final currentState = state;
    if (currentState is! ParticipantListLoadSuccess) return;

    emit(
      currentState.copyWith(
        currentSort: event.sort,
        filteredParticipants: _processParticipants(
          currentState.view.participants,
          currentState.searchQuery,
          currentState.currentFilter,
          event.sort,
        ),
      ),
    );
  }

  Future<void> _onCreateRequested(
    ParticipantListCreateRequested event,
    Emitter<ParticipantListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ParticipantListLoadSuccess) return;

    emit(currentState.copyWith(actionStatus: ActionStatus.inProgress));

    final result = await _createParticipantUseCase(event.params);

    result.fold(
      (failure) => emit(
        currentState.copyWith(
          actionStatus: ActionStatus.failure,
          actionMessage: failure.userFriendlyMessage,
        ),
      ),
      (_) {
        emit(
          currentState.copyWith(
            actionStatus: ActionStatus.success,
            actionMessage: 'Participant added successfully',
          ),
        );
        add(const ParticipantListRefreshRequested());
      },
    );
  }

  Future<void> _onEditRequested(
    ParticipantListEditRequested event,
    Emitter<ParticipantListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ParticipantListLoadSuccess) return;

    emit(currentState.copyWith(actionStatus: ActionStatus.inProgress));

    final result = await _updateParticipantUseCase(event.params);

    result.fold(
      (failure) => emit(
        currentState.copyWith(
          actionStatus: ActionStatus.failure,
          actionMessage: failure.userFriendlyMessage,
        ),
      ),
      (_) {
        emit(
          currentState.copyWith(
            actionStatus: ActionStatus.success,
            actionMessage: 'Participant updated successfully',
          ),
        );
        add(const ParticipantListRefreshRequested());
      },
    );
  }

  Future<void> _onStatusChangeRequested(
    ParticipantListStatusChangeRequested event,
    Emitter<ParticipantListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ParticipantListLoadSuccess) return;

    emit(currentState.copyWith(actionStatus: ActionStatus.inProgress));

    final result = await _updateParticipantStatusUseCase(
      participantId: event.participantId,
      newStatus: event.newStatus,
      dqReason: event.dqReason,
    );

    result.fold(
      (failure) => emit(
        currentState.copyWith(
          actionStatus: ActionStatus.failure,
          actionMessage: failure.userFriendlyMessage,
        ),
      ),
      (_) {
        emit(
          currentState.copyWith(
            actionStatus: ActionStatus.success,
            actionMessage: 'Status updated',
          ),
        );
        add(const ParticipantListRefreshRequested());
      },
    );
  }

  Future<void> _onTransferRequested(
    ParticipantListTransferRequested event,
    Emitter<ParticipantListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ParticipantListLoadSuccess) return;

    emit(currentState.copyWith(actionStatus: ActionStatus.inProgress));

    final result = await _transferParticipantUseCase(event.params);

    result.fold(
      (failure) => emit(
        currentState.copyWith(
          actionStatus: ActionStatus.failure,
          actionMessage: failure.userFriendlyMessage,
        ),
      ),
      (_) {
        emit(
          currentState.copyWith(
            actionStatus: ActionStatus.success,
            actionMessage: 'Participant transferred successfully',
          ),
        );
        add(const ParticipantListRefreshRequested());
      },
    );
  }

  Future<void> _onRemoveRequested(
    ParticipantListRemoveRequested event,
    Emitter<ParticipantListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ParticipantListLoadSuccess) return;

    emit(currentState.copyWith(actionStatus: ActionStatus.inProgress));

    final result = await _deleteParticipantUseCase(event.participantId);

    result.fold(
      (failure) => emit(
        currentState.copyWith(
          actionStatus: ActionStatus.failure,
          actionMessage: failure.userFriendlyMessage,
        ),
      ),
      (_) {
        emit(
          currentState.copyWith(
            actionStatus: ActionStatus.success,
            actionMessage: 'Participant removed',
          ),
        );
        add(const ParticipantListRefreshRequested());
      },
    );
  }

  List<ParticipantEntity> _processParticipants(
    List<ParticipantEntity> participants,
    String query,
    ParticipantFilter filter,
    ParticipantSort sort,
  ) {
    var filtered = participants.where((p) => !p.isDeleted).toList();

    // 1. Filter
    filtered = filtered.where((p) {
      return switch (filter) {
        ParticipantFilter.all => true,
        ParticipantFilter.active =>
          p.checkInStatus == ParticipantStatus.pending ||
              p.checkInStatus == ParticipantStatus.checkedIn,
        ParticipantFilter.noShow => p.checkInStatus == ParticipantStatus.noShow,
        ParticipantFilter.disqualified =>
          p.checkInStatus == ParticipantStatus.disqualified,
        ParticipantFilter.checkedIn =>
          p.checkInStatus == ParticipantStatus.checkedIn,
      };
    }).toList();

    // 2. Search
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered.where((p) {
        return p.firstName.toLowerCase().contains(q) ||
            p.lastName.toLowerCase().contains(q) ||
            (p.schoolOrDojangName?.toLowerCase().contains(q) ?? false) ||
            (p.beltRank?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // 3. Sort
    filtered.sort((a, b) {
      return switch (sort) {
        ParticipantSort.nameAsc => '${a.lastName} ${a.firstName}'.compareTo(
          '${b.lastName} ${b.firstName}',
        ),
        ParticipantSort.nameDesc => '${b.lastName} ${b.firstName}'.compareTo(
          '${a.lastName} ${a.firstName}',
        ),
        ParticipantSort.dojangAsc => (a.schoolOrDojangName ?? '').compareTo(
          b.schoolOrDojangName ?? '',
        ),
        ParticipantSort.beltAsc => (a.beltRank ?? '').compareTo(
          b.beltRank ?? '',
        ),
        ParticipantSort.seedAsc => (a.seedNumber ?? 999).compareTo(
          b.seedNumber ?? 999,
        ),
      };
    });

    return filtered;
  }
}
