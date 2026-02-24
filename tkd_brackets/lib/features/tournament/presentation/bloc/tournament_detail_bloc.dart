import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/division/domain/entities/conflict_warning.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/services/conflict_detection_service.dart';
import 'package:tkd_brackets/features/division/domain/usecases/get_divisions_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/archive_tournament_params.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/archive_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/delete_tournament_params.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/delete_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/get_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/update_tournament_settings_params.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/update_tournament_settings_usecase.dart';
import 'package:tkd_brackets/features/tournament/presentation/bloc/tournament_detail_event.dart';
import 'package:tkd_brackets/features/tournament/presentation/bloc/tournament_detail_state.dart';

@injectable
class TournamentDetailBloc
    extends Bloc<TournamentDetailEvent, TournamentDetailState> {
  TournamentDetailBloc(
    this._getTournamentUseCase,
    this._updateTournamentUseCase,
    this._deleteTournamentUseCase,
    this._archiveTournamentUseCase,
    this._getDivisionsUseCase,
    this._conflictDetectionService,
  ) : super(const TournamentDetailInitial()) {
    on<TournamentDetailLoadRequested>(_onLoadRequested);
    on<TournamentDetailUpdateRequested>(_onUpdateRequested);
    on<TournamentDetailDeleteRequested>(_onDeleteRequested);
    on<TournamentDetailArchiveRequested>(_onArchiveRequested);
    on<ConflictDismissed>(_onConflictDismissed);
  }

  final GetTournamentUseCase _getTournamentUseCase;
  final UpdateTournamentSettingsUseCase _updateTournamentUseCase;
  final DeleteTournamentUseCase _deleteTournamentUseCase;
  final ArchiveTournamentUseCase _archiveTournamentUseCase;
  final GetDivisionsUseCase _getDivisionsUseCase;
  final ConflictDetectionService _conflictDetectionService;

  Future<void> _onLoadRequested(
    TournamentDetailLoadRequested event,
    Emitter<TournamentDetailState> emit,
  ) async {
    emit(const TournamentDetailLoadInProgress());

    final tournamentResult = await _getTournamentUseCase(event.tournamentId);

    await tournamentResult.fold(
      (failure) async => emit(
        TournamentDetailLoadFailure(
          userFriendlyMessage: failure.userFriendlyMessage,
          technicalDetails: failure.technicalDetails,
        ),
      ),
      (tournament) async {
        final divisionsResult = await _getDivisionsUseCase(event.tournamentId);
        final conflictsResult = await _conflictDetectionService.detectConflicts(
          event.tournamentId,
        );

        final divisions = divisionsResult.fold<List<DivisionEntity>>(
          (_) => [],
          (divs) => divs,
        );
        final conflicts = conflictsResult.fold<List<ConflictWarning>>(
          (_) => [],
          (c) => c,
        );

        emit(
          TournamentDetailLoadSuccess(
            tournament: tournament,
            divisions: divisions,
            conflicts: conflicts,
          ),
        );
      },
    );
  }

  Future<void> _onUpdateRequested(
    TournamentDetailUpdateRequested event,
    Emitter<TournamentDetailState> emit,
  ) async {
    emit(const TournamentDetailUpdateInProgress());

    final result = await _updateTournamentUseCase(
      UpdateTournamentSettingsParams(
        tournamentId: event.tournamentId,
        venueName: event.venueName,
        venueAddress: event.venueAddress,
        ringCount: event.ringCount,
      ),
    );

    result.fold(
      (failure) => emit(
        TournamentDetailUpdateFailure(
          userFriendlyMessage: failure.userFriendlyMessage,
          technicalDetails: failure.technicalDetails,
        ),
      ),
      (tournament) => emit(TournamentDetailUpdateSuccess(tournament)),
    );
  }

  Future<void> _onDeleteRequested(
    TournamentDetailDeleteRequested event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final result = await _deleteTournamentUseCase(
      DeleteTournamentParams(tournamentId: event.tournamentId),
    );

    result.fold(
      (failure) => emit(
        TournamentDetailDeleteFailure(
          userFriendlyMessage: failure.userFriendlyMessage,
          technicalDetails: failure.technicalDetails,
        ),
      ),
      (_) => emit(const TournamentDetailDeleteSuccess()),
    );
  }

  Future<void> _onArchiveRequested(
    TournamentDetailArchiveRequested event,
    Emitter<TournamentDetailState> emit,
  ) async {
    final result = await _archiveTournamentUseCase(
      ArchiveTournamentParams(tournamentId: event.tournamentId),
    );

    result.fold(
      (failure) => emit(
        TournamentDetailArchiveFailure(
          userFriendlyMessage: failure.userFriendlyMessage,
          technicalDetails: failure.technicalDetails,
        ),
      ),
      (tournament) => emit(TournamentDetailArchiveSuccess(tournament)),
    );
  }

  void _onConflictDismissed(
    ConflictDismissed event,
    Emitter<TournamentDetailState> emit,
  ) {
    if (state is TournamentDetailLoadSuccess) {
      final currentState = state as TournamentDetailLoadSuccess;
      emit(
        currentState.copyWith(
          dismissedConflictIds: [
            ...currentState.dismissedConflictIds,
            event.conflictId,
          ],
        ),
      );
    }
  }
}
