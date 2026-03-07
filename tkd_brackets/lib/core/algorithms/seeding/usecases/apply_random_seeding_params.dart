import 'package:flutter/foundation.dart' show immutable;
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

/// Parameters for applying cryptographically fair random seeding.
@immutable
class ApplyRandomSeedingParams {
  const ApplyRandomSeedingParams({
    required this.divisionId,
    required this.participants,
    this.bracketFormat = BracketFormat.singleElimination,
    this.randomSeed,
  });

  /// The division ID for context.
  final String divisionId;

  /// Participants to seed. Only `id` is used; dojang/region are irrelevant
  /// for pure random seeding (no separation constraints).
  final List<SeedingParticipant> participants;

  /// Bracket format affects meeting-round calculations inside the engine.
  /// Default: singleElimination (most common for TKD tournaments).
  final BracketFormat bracketFormat;

  /// Optional random seed for reproducibility.
  /// If null, a cryptographically secure seed is generated via
  /// `Random.secure().nextInt(1 << 31)`.
  final int? randomSeed;
}
