import 'package:freezed_annotation/freezed_annotation.dart';

part 'tournament_event.freezed.dart';

enum TournamentFilter { all, draft, active, archived }

@freezed
class TournamentEvent with _$TournamentEvent {
  const factory TournamentEvent.loadRequested({String? organizationId}) =
      TournamentLoadRequested;
  const factory TournamentEvent.refreshRequested({String? organizationId}) =
      TournamentRefreshRequested;
  const factory TournamentEvent.filterChanged(TournamentFilter filter) =
      TournamentFilterChanged;
  const factory TournamentEvent.tournamentDeleted(String tournamentId) =
      TournamentDeleted;
  const factory TournamentEvent.tournamentArchived(String tournamentId) =
      TournamentArchived;
  const factory TournamentEvent.createRequested({
    required String name,
    required DateTime scheduledDate,
    String? description,
  }) = TournamentCreateRequested;
}
