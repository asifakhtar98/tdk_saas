import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/double_elimination_bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/services/double_elimination_bracket_generator_service.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_params.dart';
import 'package:uuid/uuid.dart';

/// Use case for generating a double elimination bracket.
/// Orchestrates validation, generation, and persistence.
@injectable
class GenerateDoubleEliminationBracketUseCase
    extends UseCase<DoubleEliminationBracketGenerationResult,
        GenerateDoubleEliminationBracketParams> {
  GenerateDoubleEliminationBracketUseCase(
    this._generatorService,
    this._bracketRepository,
    this._matchRepository,
    this._uuid,
  );

  final DoubleEliminationBracketGeneratorService _generatorService;
  final BracketRepository _bracketRepository;
  final MatchRepository _matchRepository;
  final Uuid _uuid;

  @override
  Future<Either<Failure, DoubleEliminationBracketGenerationResult>> call(
    GenerateDoubleEliminationBracketParams params,
  ) async {
    // 1. Validation
    if (params.participantIds.length < 2) {
      return const Left(ValidationFailure(
        userFriendlyMessage: 'At least 2 participants are required '
            'to generate a bracket.',
      ));
    }

    if (params.participantIds.any((id) => id.trim().isEmpty)) {
      return const Left(ValidationFailure(
        userFriendlyMessage: 'Participant list contains empty IDs.',
      ));
    }

    // 2. Generate bracket IDs
    final winnersBracketId = _uuid.v4();
    final losersBracketId = _uuid.v4();

    // 3. Generate bracket structure (pure algorithm, no DB)
    final generationResult = _generatorService.generate(
      divisionId: params.divisionId,
      participantIds: params.participantIds,
      winnersBracketId: winnersBracketId,
      losersBracketId: losersBracketId,
      includeResetMatch: params.includeResetMatch,
    );

    // 4. Persist winners bracket — CHECK Either result!
    final winnersResult = await _bracketRepository.createBracket(
      generationResult.winnersBracket,
    );

    return winnersResult.fold(
      Left.new,
      (_) async {
        // 5. Persist losers bracket — CHECK Either result!
        final losersResult = await _bracketRepository.createBracket(
          generationResult.losersBracket,
        );

        return losersResult.fold(
          Left.new,
          (_) async {
            // 6. Persist all matches (batch) — CHECK Either result!
            final matchesResult = await _matchRepository.createMatches(
              generationResult.allMatches,
            );

            return matchesResult.fold(
              Left.new,
              (_) => Right(generationResult),
            );
          },
        );
      },
    );
  }
}
