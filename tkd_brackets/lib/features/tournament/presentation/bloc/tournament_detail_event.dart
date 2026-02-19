import 'package:freezed_annotation/freezed_annotation.dart';

part 'tournament_detail_event.freezed.dart';

@freezed
class TournamentDetailEvent with _$TournamentDetailEvent {
  const factory TournamentDetailEvent.loadRequested(String tournamentId) =
      TournamentDetailLoadRequested;
  const factory TournamentDetailEvent.updateRequested(
    String tournamentId,
    String? venueName,
    String? venueAddress,
    int? ringCount,
  ) = TournamentDetailUpdateRequested;
  const factory TournamentDetailEvent.deleteRequested(String tournamentId) =
      TournamentDetailDeleteRequested;
  const factory TournamentDetailEvent.archiveRequested(String tournamentId) =
      TournamentDetailArchiveRequested;
  const factory TournamentDetailEvent.conflictDismissed(String conflictId) =
      ConflictDismissed;
}
