import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/duplicate_tournament_usecase.dart'
    show DuplicateTournamentUseCase;
import 'package:tkd_brackets/features/tournament/tournament.dart'
    show DuplicateTournamentUseCase;

part 'duplicate_tournament_params.freezed.dart';

/// Parameters for [DuplicateTournamentUseCase].
///
/// This use case allows organizers to duplicate an existing tournament
/// as a template for creating similar events quickly.
///
/// **CRITICAL BEHAVIOR:**
/// - Creates new tournament with "(Copy)" suffix in name
/// - Copies ALL divisions with new UUIDs (participants are NOT copied)
/// - New tournament starts as "draft" status
/// - New tournament marked as template (isTemplate: true)
///
/// **Authorization:** Owner or Admin only
///
/// **Failure Cases:**
/// - NotFoundFailure: Source tournament doesn't exist
/// - NotFoundFailure: Source tournament is soft-deleted
/// - AuthenticationFailure: User not logged in
/// - AuthorizationPermissionDeniedFailure: User role not Owner/Admin
///
/// **Example Usage:**
/// ```dart
/// final result = await duplicateTournamentUseCase(
///   DuplicateTournamentParams(sourceTournamentId: 'abc-123'),
/// );
/// ```
///
/// [sourceTournamentId] — Required ID of tournament to duplicate
@freezed
class DuplicateTournamentParams with _$DuplicateTournamentParams {
  const factory DuplicateTournamentParams({
    /// The unique identifier of the tournament to duplicate
    ///
    /// This ID is used to fetch the source tournament that will be duplicated.
    /// The source tournament can be in any status (draft, active, completed, archived).
    /// Soft-deleted tournaments will result in NotFoundFailure.
    required String sourceTournamentId,
  }) = _DuplicateTournamentParams;

  const DuplicateTournamentParams._();
}
