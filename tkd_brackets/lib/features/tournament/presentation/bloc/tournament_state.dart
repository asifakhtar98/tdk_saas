import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'tournament_event.dart';

part 'tournament_state.freezed.dart';

@freezed
class TournamentState with _$TournamentState {
  const factory TournamentState.initial() = TournamentInitial;
  const factory TournamentState.loadInProgress() = TournamentLoadInProgress;
  const factory TournamentState.loadSuccess({
    required List<TournamentEntity> tournaments,
    required TournamentFilter currentFilter,
  }) = TournamentLoadSuccess;
  const factory TournamentState.loadFailure({
    required String userFriendlyMessage,
    String? technicalDetails,
  }) = TournamentLoadFailure;
  const factory TournamentState.createInProgress() = TournamentCreateInProgress;
  const factory TournamentState.createSuccess() = TournamentCreateSuccess;
  const factory TournamentState.createFailure({
    required String userFriendlyMessage,
    String? technicalDetails,
  }) = TournamentCreateFailure;
}
