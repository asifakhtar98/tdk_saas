import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/delete_tournament_params.dart';

/// Use case for deleting a tournament.
///
/// DELETION TYPES:
///
/// 1. SOFT DELETE (default):
///    - Sets isDeleted = true, deletedAtTimestamp = now, syncVersion++
///    - Cascade soft-deletes all related data
///    - Hidden from normal queries
///    - Can be restored (future "un-delete" story)
///
/// 2. HARD DELETE:
///    - Permanently removes from local Drift DB
///    - Marks for deletion in Supabase
///    - IRREVERSIBLE - only for GDPR/compliance
///
/// AUTHORIZATION: Owner ONLY (stricter than archive)
///
/// Failure Cases:
/// - NotFoundFailure: Tournament doesn't exist
/// - AuthenticationFailure: User not logged in
/// - AuthorizationPermissionDeniedFailure: User role not Owner
/// - TournamentActiveFailure: Tournament has active matches
@injectable
class DeleteTournamentUseCase
    extends UseCase<TournamentEntity, DeleteTournamentParams> {
  DeleteTournamentUseCase(this._repository, this._authRepository);

  final TournamentRepository _repository;
  final AuthRepository _authRepository;

  @override
  Future<Either<Failure, TournamentEntity>> call(
    DeleteTournamentParams params,
  ) async {
    final tournamentResult = await _repository.getTournamentById(
      params.tournamentId,
    );
    final tournament = tournamentResult.fold((failure) => null, (t) => t);

    if (tournament == null) {
      return Left(
        NotFoundFailure(
          userFriendlyMessage: 'Tournament not found',
          technicalDetails:
              'No tournament exists with ID: ${params.tournamentId}',
        ),
      );
    }

    if (tournament.status == TournamentStatus.active) {
      return Left(
        TournamentActiveFailure(
          userFriendlyMessage: 'Cannot delete tournament with active matches',
          technicalDetails: 'Tournament has active status',
          activeMatchCount: 0,
        ),
      );
    }

    final authResult = await _authRepository.getCurrentAuthenticatedUser();
    final user = authResult.fold((failure) => null, (u) => u);

    if (user == null) {
      return const Left(
        AuthenticationFailure(
          userFriendlyMessage: 'You must be logged in to delete a tournament',
        ),
      );
    }

    if (user.role != UserRole.owner) {
      return Left(
        AuthorizationPermissionDeniedFailure(
          userFriendlyMessage: 'Only Owners can delete tournaments',
        ),
      );
    }

    if (params.hardDelete) {
      final hardDeleteResult = await _repository.hardDeleteTournament(
        params.tournamentId,
      );
      return hardDeleteResult.fold(
        (failure) => Left(failure),
        (_) => Right(tournament),
      );
    } else {
      await _cascadeSoftDelete(tournament.id);

      final deletedTournament = tournament.copyWith(
        isDeleted: true,
        deletedAtTimestamp: DateTime.now(),
        syncVersion: tournament.syncVersion + 1,
      );

      final updateResult = await _repository.updateTournament(
        deletedTournament,
      );

      return updateResult.fold(
        (failure) => Left(failure),
        (savedTournament) => Right(savedTournament),
      );
    }
  }

  Future<void> _cascadeSoftDelete(String tournamentId) async {
    final divisionsResult = await _repository.getDivisionsByTournamentId(
      tournamentId,
    );

    await divisionsResult.fold((failure) async {}, (divisions) async {
      for (final division in divisions) {
        await _repository.updateDivision(
          division.copyWith(
            isDeleted: true,
            deletedAtTimestamp: DateTime.now(),
            syncVersion: division.syncVersion + 1,
          ),
        );
      }
    });
  }
}
