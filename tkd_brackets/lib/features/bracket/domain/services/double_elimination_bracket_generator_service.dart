import 'package:tkd_brackets/features/bracket/domain/entities/double_elimination_bracket_generation_result.dart';

/// Domain service for generating double elimination brackets.
/// This service contains the pure algorithm — NO database access.
abstract interface class DoubleEliminationBracketGeneratorService {
  /// Generates a double elimination bracket structure.
  ///
  /// [divisionId] is the ID of the division this bracket belongs to.
  /// [participantIds] is the list of participant IDs to seed.
  /// [winnersBracketId] is the pre-generated ID for the winners bracket.
  /// [losersBracketId] is the pre-generated ID for the losers bracket.
  /// [includeResetMatch] whether to generate a reset match.
  DoubleEliminationBracketGenerationResult generate({
    required String divisionId,
    required List<String> participantIds,
    required String winnersBracketId,
    required String losersBracketId,
    bool includeResetMatch = true,
  });
}
