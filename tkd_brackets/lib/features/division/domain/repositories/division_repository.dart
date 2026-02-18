import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';

abstract class DivisionRepository {
  Future<Either<Failure, List<DivisionEntity>>> getDivisionsForTournament(
    String tournamentId,
  );

  Future<Either<Failure, DivisionEntity>> getDivisionById(String id);

  Future<Either<Failure, DivisionEntity>> getDivision(String id) =>
      getDivisionById(id);

  Future<Either<Failure, DivisionEntity>> createDivision(
    DivisionEntity division,
  );

  Future<Either<Failure, DivisionEntity>> updateDivision(
    DivisionEntity division,
  );

  Future<Either<Failure, Unit>> deleteDivision(String id);

  Future<Either<Failure, bool>> isDivisionNameUnique(
    String name,
    String tournamentId, {
    String? excludeDivisionId,
  });

  Future<Either<Failure, List<ParticipantEntry>>> getParticipantsForDivision(
    String divisionId,
  );

  Future<Either<Failure, List<ParticipantEntry>>> getParticipantsForDivisions(
    List<String> divisionIds,
  );

  Future<Either<Failure, List<DivisionEntity>>> mergeDivisions({
    required DivisionEntity mergedDivision,
    required List<DivisionEntity> sourceDivisions,
    required List<ParticipantEntry> participants,
  });

  Future<Either<Failure, List<DivisionEntity>>> getDivisionsForRing(
    String tournamentId,
    int ringNumber,
  );

  Future<Either<Failure, List<DivisionEntity>>> splitDivision({
    required DivisionEntity poolADivision,
    required DivisionEntity poolBDivision,
    required DivisionEntity sourceDivision,
    required List<ParticipantEntry> poolAParticipants,
    required List<ParticipantEntry> poolBParticipants,
  });
}
