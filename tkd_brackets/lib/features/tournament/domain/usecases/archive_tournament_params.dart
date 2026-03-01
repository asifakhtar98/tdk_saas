import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/archive_tournament_usecase.dart'
    show ArchiveTournamentUseCase;
import 'package:tkd_brackets/features/tournament/tournament.dart'
    show ArchiveTournamentUseCase;

part 'archive_tournament_params.freezed.dart';

/// Parameters for [ArchiveTournamentUseCase].
///
/// This use case allows organizers to archive completed tournaments
/// without permanently deleting them. Archived tournaments are hidden
/// from the main list but can be restored later.
///
/// [tournamentId] — Required ID of tournament to archive
@freezed
class ArchiveTournamentParams with _$ArchiveTournamentParams {
  const factory ArchiveTournamentParams({
    /// The unique identifier of the tournament to archive
    required String tournamentId,
  }) = _ArchiveTournamentParams;

  const ArchiveTournamentParams._();
}
