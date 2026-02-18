import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/archive_tournament_params.dart';

/// Use case for archiving a tournament.
///
/// ARCHIVE vs DELETE:
/// - Archive: Sets status to 'archived', keeps all data, reversible (unarchive)
/// - Delete: Marks as soft-deleted, removes from lists, reversible within grace period
///
/// Authorization: Owner or Admin only
///
/// Failure Cases:
/// - NotFoundFailure: Tournament doesn't exist
/// - AuthenticationFailure: User not logged in
/// - AuthorizationPermissionDeniedFailure: User role not Owner/Admin
/// - TournamentActiveFailure: Tournament has active matches in progress
@injectable
class ArchiveTournamentUseCase
    extends UseCase<TournamentEntity, ArchiveTournamentParams> {
  ArchiveTournamentUseCase(this._repository, this._authRepository);

  final TournamentRepository _repository;
  final AuthRepository _authRepository;

  @override
  Future<Either<Failure, TournamentEntity>> call(
    ArchiveTournamentParams params,
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
          userFriendlyMessage: 'Cannot archive tournament with active matches',
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
          userFriendlyMessage: 'You must be logged in to archive a tournament',
        ),
      );
    }

    final canArchive =
        user.role == UserRole.owner || user.role == UserRole.admin;
    if (!canArchive) {
      return Left(
        AuthorizationPermissionDeniedFailure(
          userFriendlyMessage: 'Only Owners and Admins can archive tournaments',
        ),
      );
    }

    final archivedTournament = tournament.copyWith(
      status: TournamentStatus.archived,
      syncVersion: tournament.syncVersion + 1,
    );

    final updateResult = await _repository.updateTournament(archivedTournament);

    return updateResult.fold(
      (failure) => Left(failure),
      (savedTournament) => Right(savedTournament),
    );
  }
}
