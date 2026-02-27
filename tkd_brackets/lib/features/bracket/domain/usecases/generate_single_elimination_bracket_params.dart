import 'package:flutter/foundation.dart' show immutable;

/// Parameters for generating a single elimination bracket.
@immutable
class GenerateSingleEliminationBracketParams {
  const GenerateSingleEliminationBracketParams({
    required this.divisionId,
    required this.participantIds,
    this.includeThirdPlaceMatch = false,
  });

  final String divisionId;
  final List<String> participantIds;
  final bool includeThirdPlaceMatch;
}
