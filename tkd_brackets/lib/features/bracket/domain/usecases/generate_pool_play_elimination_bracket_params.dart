import 'package:flutter/foundation.dart' show immutable;

/// Parameters for generating a pool play → elimination hybrid bracket.
@immutable
class GeneratePoolPlayEliminationBracketParams {
  const GeneratePoolPlayEliminationBracketParams({
    required this.divisionId,
    required this.participantIds,
    this.numberOfPools = 2,
    this.qualifiersPerPool = 2,
  });

  final String divisionId;
  final List<String> participantIds;
  final int numberOfPools;
  final int qualifiersPerPool;
}
