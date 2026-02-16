import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';

/// Repository interface for tournament operations.
///
/// Implementations handle data source coordination
/// (local Drift, remote Supabase).
abstract class TournamentRepository {
  /// Get all tournaments for an organization.
  Future<Either<Failure, List<TournamentEntity>>> getTournamentsForOrganization(
    String organizationId,
  );

  /// Get tournament by ID.
  /// Returns [Left(Failure)] if not found or error occurs.
  Future<Either<Failure, TournamentEntity>> getTournamentById(String id);

  /// Create a new tournament (local + remote sync).
  /// Returns created tournament on success.
  Future<Either<Failure, TournamentEntity>> createTournament(
    TournamentEntity tournament,
    String organizationId,
  );

  /// Update an existing tournament.
  /// Returns updated tournament on success.
  Future<Either<Failure, TournamentEntity>> updateTournament(
    TournamentEntity tournament,
  );

  /// Delete a tournament (soft delete).
  Future<Either<Failure, Unit>> deleteTournament(String id);
}
