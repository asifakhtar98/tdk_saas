import 'package:flutter/foundation.dart' show immutable;

/// Parameters for generating a double elimination bracket.
@immutable
class GenerateDoubleEliminationBracketParams {
  const GenerateDoubleEliminationBracketParams({
    required this.divisionId,
    required this.participantIds,
    this.includeResetMatch = true,
  });

  final String divisionId;
  final List<String> participantIds;
  final bool includeResetMatch;
}
