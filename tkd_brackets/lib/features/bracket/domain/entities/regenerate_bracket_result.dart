import 'package:flutter/foundation.dart' show immutable;

/// Result of bracket regeneration operation.
///
/// Contains cleanup counts and the new generation result.
@immutable
class RegenerateBracketResult {
  const RegenerateBracketResult({
    required this.deletedBracketCount,
    required this.deletedMatchCount,
    required this.generationResult,
  });

  /// Number of old brackets that were soft-deleted.
  final int deletedBracketCount;

  /// Number of old matches that were soft-deleted.
  final int deletedMatchCount;

  /// Result from the appropriate bracket generator use case.
  /// Type is `BracketGenerationResult` (for single-elimination and round-robin)
  /// or `DoubleEliminationBracketGenerationResult` (for double-elimination).
  /// There is NO separate `RoundRobinBracketGenerationResult` — round robin
  /// reuses `BracketGenerationResult`.
  final Object generationResult;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegenerateBracketResult &&
          runtimeType == other.runtimeType &&
          deletedBracketCount == other.deletedBracketCount &&
          deletedMatchCount == other.deletedMatchCount &&
          generationResult == other.generationResult;

  @override
  int get hashCode =>
      Object.hash(deletedBracketCount, deletedMatchCount, generationResult);

  @override
  String toString() =>
      'RegenerateBracketResult(deletedBrackets: $deletedBracketCount, '
      'deletedMatches: $deletedMatchCount, '
      'generationResult: ${generationResult.runtimeType})';
}
