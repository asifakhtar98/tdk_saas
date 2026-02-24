import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/archive_tournament_params.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/archive_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/create_tournament_params.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/create_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/delete_tournament_params.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/delete_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/get_tournaments_usecase.dart';
import 'package:tkd_brackets/features/tournament/presentation/bloc/tournament_event.dart';
import 'package:tkd_brackets/features/tournament/presentation/bloc/tournament_state.dart';

@injectable
class TournamentBloc extends Bloc<TournamentEvent, TournamentState> {
  TournamentBloc(
    this._getTournamentsUseCase,
    this._archiveTournamentUseCase,
    this._deleteTournamentUseCase,
    this._createTournamentUseCase,
  ) : super(const TournamentInitial()) {
    on<TournamentLoadRequested>(_onLoadRequested);
    on<TournamentRefreshRequested>(_onRefreshRequested);
    on<TournamentFilterChanged>(_onFilterChanged);
    on<TournamentDeleted>(_onTournamentDeleted);
    on<TournamentArchived>(_onTournamentArchived);
    on<TournamentCreateRequested>(_onCreateRequested);
  }

  final GetTournamentsUseCase _getTournamentsUseCase;
  final ArchiveTournamentUseCase _archiveTournamentUseCase;
  final DeleteTournamentUseCase _deleteTournamentUseCase;
  final CreateTournamentUseCase _createTournamentUseCase;

  String _currentOrganizationId = '';

  Future<void> _onLoadRequested(
    TournamentLoadRequested event,
    Emitter<TournamentState> emit,
  ) async {
    emit(const TournamentLoadInProgress());

    final orgId = event.organizationId ?? 'default-org';
    _currentOrganizationId = orgId;

    final result = await _getTournamentsUseCase(orgId);

    result.fold(
      (failure) => emit(
        TournamentLoadFailure(
          userFriendlyMessage: failure.userFriendlyMessage,
          technicalDetails: failure.technicalDetails,
        ),
      ),
      (tournaments) => emit(
        TournamentLoadSuccess(
          tournaments: _filterTournaments(tournaments, TournamentFilter.all),
          currentFilter: TournamentFilter.all,
        ),
      ),
    );
  }

  Future<void> _onRefreshRequested(
    TournamentRefreshRequested event,
    Emitter<TournamentState> emit,
  ) async {
    final orgId = event.organizationId ?? _currentOrganizationId;
    if (orgId.isEmpty) {
      emit(
        const TournamentLoadFailure(
          userFriendlyMessage: 'No organization selected',
        ),
      );
      return;
    }

    emit(const TournamentLoadInProgress());

    final result = await _getTournamentsUseCase(orgId);

    final currentFilter = state is TournamentLoadSuccess
        ? (state as TournamentLoadSuccess).currentFilter
        : TournamentFilter.all;

    result.fold(
      (failure) => emit(
        TournamentLoadFailure(
          userFriendlyMessage: failure.userFriendlyMessage,
          technicalDetails: failure.technicalDetails,
        ),
      ),
      (tournaments) => emit(
        TournamentLoadSuccess(
          tournaments: _filterTournaments(tournaments, currentFilter),
          currentFilter: currentFilter,
        ),
      ),
    );
  }

  void _onFilterChanged(
    TournamentFilterChanged event,
    Emitter<TournamentState> emit,
  ) {
    if (state is TournamentLoadSuccess) {
      final currentState = state as TournamentLoadSuccess;
      emit(
        TournamentLoadSuccess(
          tournaments: _filterTournaments(
            currentState.tournaments,
            event.filter,
          ),
          currentFilter: event.filter,
        ),
      );
    }
  }

  Future<void> _onTournamentDeleted(
    TournamentDeleted event,
    Emitter<TournamentState> emit,
  ) async {
    final result = await _deleteTournamentUseCase(
      DeleteTournamentParams(tournamentId: event.tournamentId),
    );

    await result.fold(
      (failure) async => emit(
        TournamentLoadFailure(
          userFriendlyMessage: failure.userFriendlyMessage,
          technicalDetails: failure.technicalDetails,
        ),
      ),
      (_) async => add(
        TournamentRefreshRequested(organizationId: _currentOrganizationId),
      ),
    );
  }

  Future<void> _onTournamentArchived(
    TournamentArchived event,
    Emitter<TournamentState> emit,
  ) async {
    final result = await _archiveTournamentUseCase(
      ArchiveTournamentParams(tournamentId: event.tournamentId),
    );

    await result.fold(
      (failure) async => emit(
        TournamentLoadFailure(
          userFriendlyMessage: failure.userFriendlyMessage,
          technicalDetails: failure.technicalDetails,
        ),
      ),
      (_) async => add(
        TournamentRefreshRequested(organizationId: _currentOrganizationId),
      ),
    );
  }

  Future<void> _onCreateRequested(
    TournamentCreateRequested event,
    Emitter<TournamentState> emit,
  ) async {
    emit(const TournamentCreateInProgress());

    final result = await _createTournamentUseCase(
      CreateTournamentParams(
        name: event.name,
        scheduledDate: event.scheduledDate,
        description: event.description,
      ),
    );

    await result.fold(
      (failure) async => emit(
        TournamentCreateFailure(
          userFriendlyMessage: failure.userFriendlyMessage,
          technicalDetails: failure.technicalDetails,
        ),
      ),
      (tournament) async {
        emit(const TournamentCreateSuccess());
        add(TournamentRefreshRequested(organizationId: _currentOrganizationId));
      },
    );
  }

  List<TournamentEntity> _filterTournaments(
    List<TournamentEntity> tournaments,
    TournamentFilter filter,
  ) {
    switch (filter) {
      case TournamentFilter.all:
        return tournaments.where((t) => !t.isDeleted).toList();
      case TournamentFilter.draft:
        return tournaments
            .where((t) => !t.isDeleted && t.status == TournamentStatus.draft)
            .toList();
      case TournamentFilter.active:
        return tournaments
            .where((t) => !t.isDeleted && t.status == TournamentStatus.active)
            .toList();
      case TournamentFilter.archived:
        return tournaments
            .where((t) => !t.isDeleted && t.status == TournamentStatus.archived)
            .toList();
    }
  }
}
