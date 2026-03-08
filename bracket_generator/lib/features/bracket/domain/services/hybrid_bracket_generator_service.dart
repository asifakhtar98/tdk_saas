import 'package:bracket_generator/features/bracket/domain/entities/hybrid_bracket_generation_result.dart';

/// Domain service for generating pool play → elimination hybrid brackets.
/// This service contains the pure algorithm — NO database access.
abstract interface class HybridBracketGeneratorService {
  /// Generates a pool play → elimination hybrid bracket.
  ///
  /// [divisionId] is the division this bracket belongs to.
  /// [participantIds] is the list of participant IDs.
  /// [numberOfPools] defaults to 2 (Pool A, Pool B).
  /// [qualifiersPerPool] defaults to 2 (top 2 advance).
  /// [eliminationBracketId] is the pre-generated ID for the elimination bracket.
  /// [poolBracketIds] is the pre-generated list of IDs for pool brackets (one per pool).
  HybridBracketGenerationResult generate({
    required String divisionId,
    required List<String> participantIds,
    required String eliminationBracketId,
    required List<String> poolBracketIds,
    int numberOfPools = 2,
    int qualifiersPerPool = 2,
  });
}
