import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/regenerate_bracket_result.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_round_robin_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_round_robin_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_single_elimination_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_single_elimination_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_pool_play_elimination_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_pool_play_elimination_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/regenerate_bracket_params.dart';

/// Use case that orchestrates bracket regeneration.
///
/// Soft-deletes existing brackets and matches for a division,
/// then delegates to the appropriate generator use case to
/// create fresh brackets from the current participant list.
@injectable
class RegenerateBracketUseCase
    extends UseCase<RegenerateBracketResult, RegenerateBracketParams> {
  RegenerateBracketUseCase(
    this._bracketRepository,
    this._matchRepository,
    this._singleEliminationUseCase,
    this._doubleEliminationUseCase,
    this._roundRobinUseCase,
    this._poolPlayUseCase,
  );

  final BracketRepository _bracketRepository;
  final MatchRepository _matchRepository;
  final GenerateSingleEliminationBracketUseCase _singleEliminationUseCase;
  final GenerateDoubleEliminationBracketUseCase _doubleEliminationUseCase;
  final GenerateRoundRobinBracketUseCase _roundRobinUseCase;
  final GeneratePoolPlayEliminationBracketUseCase _poolPlayUseCase;

  @override
  Future<Either<Failure, RegenerateBracketResult>> call(
    RegenerateBracketParams params,
  ) async {
    // 1. Validate divisionId
    if (params.divisionId.trim().isEmpty) {
      return const Left(
        ValidationFailure(userFriendlyMessage: 'Division ID is required.'),
      );
    }

    // 2. Validate minimum participants
    if (params.participantIds.length < 2) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage:
              'At least 2 participants are required to generate a bracket.',
        ),
      );
    }

    // 3. Validate no empty participant IDs
    if (params.participantIds.any((id) => id.trim().isEmpty)) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Participant list contains empty IDs.',
        ),
      );
    }

    // 4. Validate no duplicate participant IDs
    final ids = params.participantIds.toSet();
    if (ids.length != params.participantIds.length) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Duplicate participant IDs detected.',
        ),
      );
    }

    // 5. Fetch existing brackets for this division
    final bracketsResult = await _bracketRepository.getBracketsForDivision(
      params.divisionId,
    );

    return bracketsResult.fold(Left.new, (existingBrackets) async {
      // 6. Check if any bracket is finalized
      if (existingBrackets.any((b) => b.isFinalized)) {
        return const Left(
          ValidationFailure(
            userFriendlyMessage:
                'Cannot regenerate: bracket is finalized. '
                'Unlock the bracket before regenerating.',
          ),
        );
      }

      // 7. Soft-delete old matches and brackets
      var deletedMatchCount = 0;
      for (final bracket in existingBrackets) {
        // Get all matches for this bracket
        final matchesResult = await _matchRepository.getMatchesForBracket(
          bracket.id,
        );

        // If fetching matches fails, propagate the failure
        final matchFailure = matchesResult.fold((f) => f, (_) => null);
        if (matchFailure != null) return Left(matchFailure);

        final matches = matchesResult.getOrElse((_) => []);

        // Soft-delete each match
        for (final match in matches) {
          final deleteResult = await _matchRepository.deleteMatch(match.id);
          final deleteFailure = deleteResult.fold((f) => f, (_) => null);
          if (deleteFailure != null) return Left(deleteFailure);
        }
        deletedMatchCount += matches.length;

        // Soft-delete the bracket itself
        final bracketDeleteResult = await _bracketRepository.deleteBracket(
          bracket.id,
        );
        final bracketFailure = bracketDeleteResult.fold((f) => f, (_) => null);
        if (bracketFailure != null) return Left(bracketFailure);
      }

      final deletedBracketCount = existingBrackets.length;

      // 8. Delegate to appropriate generator
      final Either<Failure, Object> generationResult;

      switch (params.bracketFormat) {
        case BracketFormat.singleElimination:
          generationResult = await _singleEliminationUseCase(
            GenerateSingleEliminationBracketParams(
              divisionId: params.divisionId,
              participantIds: params.participantIds,
              includeThirdPlaceMatch: params.includeThirdPlaceMatch,
            ),
          );
        case BracketFormat.doubleElimination:
          generationResult = await _doubleEliminationUseCase(
            GenerateDoubleEliminationBracketParams(
              divisionId: params.divisionId,
              participantIds: params.participantIds,
              includeResetMatch: params.includeResetMatch,
            ),
          );
        case BracketFormat.roundRobin:
          generationResult = await _roundRobinUseCase(
            GenerateRoundRobinBracketParams(
              divisionId: params.divisionId,
              participantIds: params.participantIds,
              // poolIdentifier defaults to 'A' in the params
            ),
          );
        case BracketFormat.poolPlay:
          generationResult = await _poolPlayUseCase(
            GeneratePoolPlayEliminationBracketParams(
              divisionId: params.divisionId,
              participantIds: params.participantIds,
            ),
          );
      }

      return generationResult.fold(Left.new, (genResult) {
        return Right(
          RegenerateBracketResult(
            deletedBracketCount: deletedBracketCount,
            deletedMatchCount: deletedMatchCount,
            generationResult: genResult,
          ),
        );
      });
    });
  }
}
