import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/services/single_elimination_bracket_generator_service.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_single_elimination_bracket_params.dart';
import 'package:uuid/uuid.dart';

/// Use case to generate a single elimination bracket for a division.
///
/// This use case orchestrates validation, bracket generation via
/// service, and persistence of the resulting bracket and matches.
@injectable
class GenerateSingleEliminationBracketUseCase
    extends
        UseCase<
          BracketGenerationResult,
          GenerateSingleEliminationBracketParams
        > {
  GenerateSingleEliminationBracketUseCase(
    this._generatorService,
    this._bracketRepository,
    this._matchRepository,
    this._uuid,
  );

  final SingleEliminationBracketGeneratorService _generatorService;
  final BracketRepository _bracketRepository;
  final MatchRepository _matchRepository;
  final Uuid _uuid;

  @override
  Future<Either<Failure, BracketGenerationResult>> call(
    GenerateSingleEliminationBracketParams params,
  ) async {
    // 1. Validation
    if (params.participantIds.length < 2) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage:
              'At least 2 participants are required '
              'to generate a bracket.',
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

    // 2. Generate bracket ID
    final bracketId = _uuid.v4();

    // 3. Generate match structure (pure algorithm, no DB)
    final generationResult = _generatorService.generate(
      divisionId: params.divisionId,
      participantIds: params.participantIds,
      bracketId: bracketId,
      includeThirdPlaceMatch: params.includeThirdPlaceMatch,
    );

    // 4. Persist bracket — CHECK Either result!
    final bracketResult = await _bracketRepository.createBracket(
      generationResult.bracket,
    );

    return bracketResult.fold(Left.new, (_) async {
      // 5. Persist matches (batch) — CHECK Either result!
      final matchesResult = await _matchRepository.createMatches(
        generationResult.matches,
      );
      return matchesResult.fold(Left.new, (_) => Right(generationResult));
    });
  }
}
