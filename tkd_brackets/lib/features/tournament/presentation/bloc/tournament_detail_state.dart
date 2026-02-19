import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/entities/conflict_warning.dart';

part 'tournament_detail_state.freezed.dart';

@freezed
class TournamentDetailState with _$TournamentDetailState {
  const factory TournamentDetailState.initial() = TournamentDetailInitial;
  const factory TournamentDetailState.loadInProgress() =
      TournamentDetailLoadInProgress;
  const factory TournamentDetailState.loadSuccess({
    required TournamentEntity tournament,
    required List<DivisionEntity> divisions,
    required List<ConflictWarning> conflicts,
    @Default([]) List<String> dismissedConflictIds,
  }) = TournamentDetailLoadSuccess;
  const factory TournamentDetailState.loadFailure({
    required String userFriendlyMessage,
    String? technicalDetails,
  }) = TournamentDetailLoadFailure;
  const factory TournamentDetailState.updateInProgress() =
      TournamentDetailUpdateInProgress;
  const factory TournamentDetailState.updateSuccess(
    TournamentEntity tournament,
  ) = TournamentDetailUpdateSuccess;
  const factory TournamentDetailState.updateFailure({
    required String userFriendlyMessage,
    String? technicalDetails,
  }) = TournamentDetailUpdateFailure;
  const factory TournamentDetailState.deleteSuccess() =
      TournamentDetailDeleteSuccess;
  const factory TournamentDetailState.deleteFailure({
    required String userFriendlyMessage,
    String? technicalDetails,
  }) = TournamentDetailDeleteFailure;
  const factory TournamentDetailState.archiveSuccess(
    TournamentEntity tournament,
  ) = TournamentDetailArchiveSuccess;
  const factory TournamentDetailState.archiveFailure({
    required String userFriendlyMessage,
    String? technicalDetails,
  }) = TournamentDetailArchiveFailure;
}
