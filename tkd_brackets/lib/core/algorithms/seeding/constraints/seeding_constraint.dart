import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

/// Base class for seeding constraints that the seeding engine must
/// attempt to satisfy.
abstract class SeedingConstraint {
  /// Human-readable name of this constraint.
  String get name;

  /// Checks whether the given placements satisfy this constraint.
  ///
  /// [placements] is the current (possibly partial) list of assignments.
  /// [participants] provides the full participant data (for dojang lookup).
  /// [bracketSize] is the total number of slots in the bracket (power of 2).
  bool isSatisfied({
    required List<ParticipantPlacement> placements,
    required List<SeedingParticipant> participants,
    required int bracketSize,
  });

  /// Returns a human-readable message explaining why the constraint
  /// is violated (used in warnings).
  String get violationMessage;

  /// Counts the number of violations in the given placement.
  /// Used for best-effort fallback scoring.
  int countViolations({
    required List<ParticipantPlacement> placements,
    required List<SeedingParticipant> participants,
    required int bracketSize,
  });
}
