import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/delete_tournament_usecase.dart'
    show DeleteTournamentUseCase;
import 'package:tkd_brackets/features/tournament/tournament.dart'
    show DeleteTournamentUseCase;

part 'delete_tournament_params.freezed.dart';

/// Parameters for [DeleteTournamentUseCase].
///
/// This use case handles both SOFT delete and HARD delete:
///
/// - SOFT DELETE (default, hardDelete: false):
///   - Marks tournament as deleted (isDeleted = true)
///   - Sets deletedAtTimestamp timestamp
///   - Increments syncVersion
///   - Cascade soft-deletes ALL related data (divisions, brackets, matches, participants)
///   - Reversible (can be restored via un-delete)
///   - Data remains in database but hidden from queries
///
/// - HARD DELETE (hardDelete: true):
///   - Permanently removes from local Drift DB
///   - Marks for permanent deletion from Supabase
///   - IRREVERSIBLE - use with extreme caution
///   - Only for GDPR compliance or data cleanup scenarios
///
/// [tournamentId] — Required ID of tournament to delete
/// [hardDelete] — Optional: if true, permanently removes from DB (default: false = soft delete)
@freezed
class DeleteTournamentParams with _$DeleteTournamentParams {
  const factory DeleteTournamentParams({
    /// The unique identifier of the tournament to delete
    required String tournamentId,

    /// If true, permanently removes from database (IRREVERSIBLE)
    /// Default: false (soft delete)
    @Default(false) bool hardDelete,
  }) = _DeleteTournamentParams;

  const DeleteTournamentParams._();
}
