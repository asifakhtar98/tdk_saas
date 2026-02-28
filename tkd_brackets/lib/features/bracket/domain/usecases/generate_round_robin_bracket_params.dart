import 'package:flutter/foundation.dart' show immutable;

/// Parameters for generating a round robin bracket.
@immutable
class GenerateRoundRobinBracketParams {
  const GenerateRoundRobinBracketParams({
    required this.divisionId,
    required this.participantIds,
    this.poolIdentifier = 'A',
  });

  final String divisionId;
  final List<String> participantIds;
  final String poolIdentifier;
}
