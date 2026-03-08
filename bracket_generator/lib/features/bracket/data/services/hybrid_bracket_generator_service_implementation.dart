import 'package:injectable/injectable.dart';
import 'package:bracket_generator/features/bracket/domain/entities/bracket_generation_result.dart';
import 'package:bracket_generator/features/bracket/domain/entities/hybrid_bracket_generation_result.dart';
import 'package:bracket_generator/features/bracket/domain/entities/match_entity.dart';
import 'package:bracket_generator/features/bracket/domain/services/hybrid_bracket_generator_service.dart';
import 'package:bracket_generator/features/bracket/domain/services/round_robin_bracket_generator_service.dart';
import 'package:bracket_generator/features/bracket/domain/services/single_elimination_bracket_generator_service.dart';

/// Implementation of [HybridBracketGeneratorService].
@LazySingleton(as: HybridBracketGeneratorService)
class HybridBracketGeneratorServiceImplementation
    implements HybridBracketGeneratorService {
  HybridBracketGeneratorServiceImplementation(
    this._roundRobinGenerator,
    this._singleEliminationGenerator,
  );

  final RoundRobinBracketGeneratorService _roundRobinGenerator;
  final SingleEliminationBracketGeneratorService _singleEliminationGenerator;

  @override
  HybridBracketGenerationResult generate({
    required String divisionId,
    required List<String> participantIds,
    required String eliminationBracketId,
    required List<String> poolBracketIds,
    int numberOfPools = 2,
    int qualifiersPerPool = 2,
  }) {
    final pools = List.generate(numberOfPools, (_) => <String>[]);

    // 1. Split participants into pools (round-robin/interleaved distribution)
    // This provides better competitive balance than sequential chunks.
    for (var i = 0; i < participantIds.length; i++) {
      pools[i % numberOfPools].add(participantIds[i]);
    }

    // 2. Generate round robin per pool
    final poolResults = <BracketGenerationResult>[];
    for (var i = 0; i < numberOfPools; i++) {
      final result = _roundRobinGenerator.generate(
        divisionId: divisionId,
        participantIds: pools[i],
        bracketId: poolBracketIds[i],
        poolIdentifier: String.fromCharCode(65 + i), // A, B, C...
      );
      poolResults.add(result);
    }

    // 3. Build qualifier placeholders (cross-seeded for 2 pools)
    // These are placeholders like 'pool_a_q1' that will be replaced by
    // real participants once pool matches are completed (Epic 6).
    final qualifierIds = <String>[];
    if (numberOfPools == 2) {
      // Standard cross-seeding pattern for 2 pools.
      // Pairs top seeds from one pool against bottom seeds from the other:
      //   A#1 vs B#N, B#1 vs A#N, A#2 vs B#(N-1), B#2 vs A#(N-1), ...
      // This avoids same-pool rematches in early elimination rounds.
      for (var i = 0; i < qualifiersPerPool; i++) {
        final aRank = i + 1; // 1-based qualifier rank from Pool A
        final bRank = qualifiersPerPool - i; // opposite end from Pool B
        qualifierIds.add('pool_a_q$aRank');
        qualifierIds.add('pool_b_q$bRank');
      }
    } else {
      // Simple sequential placeholders for N pools
      for (var i = 0; i < numberOfPools; i++) {
        final poolLetter = String.fromCharCode(97 + i); // a, b, c...
        for (var q = 1; q <= qualifiersPerPool; q++) {
          qualifierIds.add('pool_${poolLetter}_q$q');
        }
      }
    }

    // 4. Generate elimination bracket from qualifiers
    final eliminationResult = _singleEliminationGenerator.generate(
      divisionId: divisionId,
      participantIds: qualifierIds,
      bracketId: eliminationBracketId,
    );

    // 5. Store hybrid configuration metadata in the elimination bracket
    // This allows the advancement system to know which pools feed into it.
    final updatedEliminationBracket = eliminationResult.bracket.copyWith(
      bracketDataJson: {
        'hybrid': true,
        'numberOfPools': numberOfPools,
        'qualifiersPerPool': qualifiersPerPool,
        'poolBracketIds': poolBracketIds,
      },
    );

    final finalEliminationResult = BracketGenerationResult(
      bracket: updatedEliminationBracket,
      matches: eliminationResult.matches,
    );

    // 6. Collect all matches across all pools + elimination
    final allMatches = <MatchEntity>[];
    for (final poolResult in poolResults) {
      allMatches.addAll(poolResult.matches);
    }
    allMatches.addAll(eliminationResult.matches);

    return HybridBracketGenerationResult(
      poolBrackets: poolResults,
      eliminationBracket: finalEliminationResult,
      allMatches: allMatches,
    );
  }
}
