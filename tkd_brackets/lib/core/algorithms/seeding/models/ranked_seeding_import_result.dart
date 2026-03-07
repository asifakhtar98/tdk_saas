import 'package:flutter/foundation.dart' show immutable;
import 'package:tkd_brackets/core/algorithms/seeding/models/ranked_seeding_match_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';

/// Combined result of ranked seeding import.
///
/// Wraps the [SeedingResult] from the seeding engine with the
/// [RankedSeedingMatchResult] diagnostics from the matching process.
@immutable
class RankedSeedingImportResult {
  const RankedSeedingImportResult({
    required this.seedingResult,
    required this.matchResult,
  });

  /// The seeding result from the engine (participant placements).
  final SeedingResult seedingResult;

  /// Diagnostics about the fuzzy matching process.
  final RankedSeedingMatchResult matchResult;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankedSeedingImportResult &&
          runtimeType == other.runtimeType &&
          seedingResult == other.seedingResult &&
          matchResult == other.matchResult;

  @override
  int get hashCode => Object.hash(seedingResult, matchResult);

  @override
  String toString() =>
      'RankedSeedingImportResult(seeding: $seedingResult, match: $matchResult)';
}
