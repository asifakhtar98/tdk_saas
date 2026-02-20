import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';

/// Repository interface for participant operations.
///
/// Implementations handle data source coordination
/// (local Drift, remote Supabase).
abstract class ParticipantRepository {
  /// Get all active participants for a division.
  Future<Either<Failure, List<ParticipantEntity>>> getParticipantsForDivision(
    String divisionId,
  );

  /// Get participant by ID.
  /// Returns [Left(Failure)] if not found or error occurs.
  Future<Either<Failure, ParticipantEntity>> getParticipantById(String id);

  /// Create a new participant.
  /// Returns created participant on success.
  Future<Either<Failure, ParticipantEntity>> createParticipant(
    ParticipantEntity participant,
  );

  /// Update an existing participant.
  /// Returns updated participant on success.
  Future<Either<Failure, ParticipantEntity>> updateParticipant(
    ParticipantEntity participant,
  );

  /// Delete a participant (soft delete).
  Future<Either<Failure, Unit>> deleteParticipant(String id);
}
