import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/hybrid_bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/services/hybrid_bracket_generator_service.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_pool_play_elimination_bracket_params.dart';
import 'package:uuid/uuid.dart';

/// Use case to generate a pool play → elimination hybrid bracket.
@injectable
class GeneratePoolPlayEliminationBracketUseCase
    extends UseCase<HybridBracketGenerationResult, GeneratePoolPlayEliminationBracketParams> {
  GeneratePoolPlayEliminationBracketUseCase(
    this._generatorService,
    this._bracketRepository,
    this._matchRepository,
    this._uuid,
  );

  final HybridBracketGeneratorService _generatorService;
  final BracketRepository _bracketRepository;
  final MatchRepository _matchRepository;
  final Uuid _uuid;

  @override
  Future<Either<Failure, HybridBracketGenerationResult>> call(
    GeneratePoolPlayEliminationBracketParams params,
  ) async {
    // 1. Validate
    if (params.participantIds.length < 3) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'At least 3 participants are required for pool play.',
        ),
      );
    }

    if (params.participantIds.any((id) => id.trim().isEmpty)) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Participant list contains empty IDs.',
        ),
      );
    }

    if (params.participantIds.toSet().length != params.participantIds.length) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Participant list contains duplicate IDs.',
        ),
      );
    }

    if (params.numberOfPools < 1 || params.qualifiersPerPool < 1) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Number of pools and qualifiers per pool must be at least 1.',
        ),
      );
    }

    final totalQualifiers = params.numberOfPools * params.qualifiersPerPool;
    if (totalQualifiers > params.participantIds.length) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Not enough participants to fill all qualifier slots.',
        ),
      );
    }

    // 2. Generate IDs
    final eliminationBracketId = _uuid.v4();
    final poolBracketIds = List.generate(params.numberOfPools, (_) => _uuid.v4());

    // 3. Generate hybrid bracket (pure algorithm)
    final result = _generatorService.generate(
      divisionId: params.divisionId,
      participantIds: params.participantIds,
      eliminationBracketId: eliminationBracketId,
      poolBracketIds: poolBracketIds,
      numberOfPools: params.numberOfPools,
      qualifiersPerPool: params.qualifiersPerPool,
    );

    // 4. Persist each pool bracket
    // Note: createBracket is called sequentially as repository doesn't support batch bracket creation.
    for (final poolResult in result.poolBrackets) {
      final bracketResult = await _bracketRepository.createBracket(poolResult.bracket);
      final failure = bracketResult.fold((f) => f, (_) => null);
      if (failure != null) return Left(failure);
    }

    // 5. Persist elimination bracket
    final elimResult = await _bracketRepository.createBracket(result.eliminationBracket.bracket);
    return elimResult.fold(Left.new, (_) async {
      // 6. Persist all matches across all pools + elimination (batch)
      final matchesResult = await _matchRepository.createMatches(result.allMatches);
      return matchesResult.fold(Left.new, (_) => Right(result));
    });
  }
}
