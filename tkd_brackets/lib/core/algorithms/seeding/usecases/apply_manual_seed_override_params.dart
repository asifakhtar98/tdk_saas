import 'package:flutter/foundation.dart' show immutable;
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

/// Parameters for the manual seed override use case.
@immutable
class ApplyManualSeedOverrideParams {
  const ApplyManualSeedOverrideParams({
    required this.divisionId,
    required this.participants,
    this.pinnedSeeds = const {},
    this.enableDojangSeparation = true,
    this.dojangMinimumRoundsSeparation = 2,
    this.enableRegionalSeparation = true,
    this.regionalMinimumRoundsSeparation = 1,
    this.bracketFormat = BracketFormat.singleElimination,
    this.randomSeed,
  });

  /// The division ID for context.
  final String divisionId;

  /// All participants with dojang names and optional region names.
  final List<SeedingParticipant> participants;

  /// Map of participantId → fixed seed position.
  final Map<String, int> pinnedSeeds;

  /// Whether to apply dojang separation constraint.
  final bool enableDojangSeparation;

  /// Minimum rounds of separation for same-dojang athletes.
  final int dojangMinimumRoundsSeparation;

  /// Whether to apply regional separation constraint.
  final bool enableRegionalSeparation;

  /// Minimum rounds of separation for same-region athletes.
  final int regionalMinimumRoundsSeparation;

  /// Bracket format affects meeting-round calculations.
  final BracketFormat bracketFormat;

  /// Optional random seed for reproducibility.
  final int? randomSeed;
}
