import 'package:tkd_brackets/features/bracket/domain/entities/bracket_generation_result.dart';

/// Domain service for generating single elimination brackets.
/// This service contains the pure algorithm for bracket generation.
abstract interface class SingleEliminationBracketGeneratorService {
  /// Generates a single elimination bracket structure.
  ///
  /// [divisionId] is the ID of the division this bracket belongs to.
  /// [participantIds] is the list of participant IDs to be
  /// seeded in the bracket.
  /// [bracketId] is the pre-generated ID for the new bracket.
  /// [includeThirdPlaceMatch] whether to generate a 3rd place match.
  BracketGenerationResult generate({
    required String divisionId,
    required List<String> participantIds,
    required String bracketId,
    bool includeThirdPlaceMatch = false,
  });
}
