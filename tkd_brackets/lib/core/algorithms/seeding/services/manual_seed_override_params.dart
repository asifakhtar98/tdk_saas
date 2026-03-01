import 'package:flutter/foundation.dart' show immutable;
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/seeding_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

/// Parameters for the re-seed-around-pins operation.
@immutable
class ManualSeedOverrideParams {
  const ManualSeedOverrideParams({
    required this.participants,
    required this.constraints,
    this.pinnedSeeds = const {},
    this.bracketFormat = BracketFormat.singleElimination,
    this.randomSeed,
  });

  /// All participants in the division.
  final List<SeedingParticipant> participants;

  /// Map of participantId → fixed seed position.
  /// These participants will NOT be moved during re-seeding.
  final Map<String, int> pinnedSeeds;

  /// Constraints to apply during re-seeding.
  final List<SeedingConstraint> constraints;

  /// Bracket format affects meeting-round calculations.
  final BracketFormat bracketFormat;

  /// Optional random seed for reproducibility.
  final int? randomSeed;
}
