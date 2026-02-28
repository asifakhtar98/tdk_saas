import 'package:tkd_brackets/features/bracket/domain/entities/bracket_generation_result.dart';

/// Domain service for generating round robin brackets.
/// This service contains the pure scheduling algorithm — NO database access.
abstract interface class RoundRobinBracketGeneratorService {
  /// Generates a round robin bracket schedule.
  ///
  /// [divisionId] is the ID of the division this bracket belongs to.
  /// [participantIds] is the list of participant IDs to schedule.
  /// [bracketId] is the pre-generated ID for the bracket.
  /// [poolIdentifier] is the pool label (e.g., 'A', 'B').
  BracketGenerationResult generate({
    required String divisionId,
    required List<String> participantIds,
    required String bracketId,
    String poolIdentifier = 'A',
  });
}
