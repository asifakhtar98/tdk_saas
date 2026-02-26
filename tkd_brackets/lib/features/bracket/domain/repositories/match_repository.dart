import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';

/// Repository interface for match operations.
abstract class MatchRepository {
  Future<Either<Failure, List<MatchEntity>>> getMatchesForBracket(
    String bracketId,
  );
  Future<Either<Failure, List<MatchEntity>>> getMatchesForRound(
    String bracketId,
    int roundNumber,
  );
  Future<Either<Failure, MatchEntity>> getMatchById(String id);
  Future<Either<Failure, MatchEntity>> createMatch(MatchEntity match);
  Future<Either<Failure, MatchEntity>> updateMatch(MatchEntity match);
  Future<Either<Failure, Unit>> deleteMatch(String id);
}
