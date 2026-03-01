import 'package:flutter/foundation.dart' show immutable;
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

/// Parameters for applying regional (and optionally dojang) separation seeding.
@immutable
class ApplyRegionalSeparationSeedingParams {
  const ApplyRegionalSeparationSeedingParams({
    required this.divisionId,
    required this.participants,
    this.enableDojangSeparation = true,
    this.dojangMinimumRoundsSeparation = 2,
    this.regionalMinimumRoundsSeparation = 1,
    this.bracketFormat = BracketFormat.singleElimination,
    this.randomSeed,
  });

  /// The division ID for context.
  final String divisionId;

  /// Participants with dojang names and optional region names.
  final List<SeedingParticipant> participants;

  /// Whether to also apply dojang separation (default: true).
  /// When true, dojang separation is included as a higher-priority constraint.
  final bool enableDojangSeparation;

  /// Minimum rounds of separation for same-dojang athletes.
  /// Only used when [enableDojangSeparation] is true.
  /// Default: 2.
  final int dojangMinimumRoundsSeparation;

  /// Minimum rounds of separation for same-region athletes.
  /// Default: 1.
  final int regionalMinimumRoundsSeparation;

  /// Bracket format affects meeting-round calculations.
  final BracketFormat bracketFormat;

  /// Optional random seed for reproducibility in testing.
  final int? randomSeed;
}
