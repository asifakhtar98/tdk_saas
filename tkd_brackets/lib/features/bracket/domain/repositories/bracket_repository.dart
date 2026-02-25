import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';

/// Repository interface for bracket operations.
abstract class BracketRepository {
  Future<Either<Failure, List<BracketEntity>>> getBracketsForDivision(
    String divisionId,
  );
  Future<Either<Failure, BracketEntity>> getBracketById(String id);
  Future<Either<Failure, BracketEntity>> createBracket(BracketEntity bracket);
  Future<Either<Failure, BracketEntity>> updateBracket(BracketEntity bracket);
  Future<Either<Failure, Unit>> deleteBracket(String id);
}
