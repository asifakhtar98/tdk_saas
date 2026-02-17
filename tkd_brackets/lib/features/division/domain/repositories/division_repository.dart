import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';

abstract class DivisionRepository {
  Future<Either<Failure, List<DivisionEntity>>> getDivisionsForTournament(
    String tournamentId,
  );

  Future<Either<Failure, DivisionEntity>> getDivisionById(String id);

  Future<Either<Failure, DivisionEntity>> createDivision(
    DivisionEntity division,
  );

  Future<Either<Failure, DivisionEntity>> updateDivision(
    DivisionEntity division,
  );

  Future<Either<Failure, Unit>> deleteDivision(String id);
}
