import 'package:flutter/foundation.dart' show immutable;
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

/// Parameters for applying dojang separation seeding.
@immutable
class ApplyDojangSeparationSeedingParams {
  const ApplyDojangSeparationSeedingParams({
    required this.divisionId,
    required this.participants,
    this.minimumRoundsSeparation = 2,
    this.bracketFormat = BracketFormat.singleElimination,
    this.randomSeed,
  });

  /// The division ID for context.
  final String divisionId;

  /// Participants with their dojang names.
  final List<SeedingParticipant> participants;

  /// Minimum rounds of separation for same-dojang athletes.
  /// Default: 2 (cannot meet in Round 1 or 2).
  final int minimumRoundsSeparation;

  /// Bracket format affects meeting-round calculations.
  /// Default: singleElimination (most common for TKD tournaments).
  final BracketFormat bracketFormat;

  /// Optional random seed for reproducibility in testing.
  final int? randomSeed;
}
