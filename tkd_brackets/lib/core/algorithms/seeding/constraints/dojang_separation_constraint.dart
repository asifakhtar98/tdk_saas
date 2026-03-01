import 'package:tkd_brackets/core/algorithms/seeding/constraints/seeding_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

/// Constraint ensuring same-dojang athletes do not meet
/// before a specified round in the bracket.
///
/// [minimumRoundsSeparation] = 2 means same-dojang athletes
/// should not meet in Round 1 or Round 2 (i.e., earliest meeting
/// should be semifinals or later in an 8-person bracket).
class DojangSeparationConstraint extends SeedingConstraint {
  DojangSeparationConstraint({this.minimumRoundsSeparation = 2});

  /// Minimum number of rounds before same-dojang athletes can meet.
  /// Default: 2 (cannot meet in Round 1 or Round 2).
  final int minimumRoundsSeparation;

  @override
  String get name => 'dojang_separation';

  @override
  String get violationMessage =>
      'Same-dojang athletes are meeting before round $minimumRoundsSeparation';

  @override
  bool isSatisfied({
    required List<ParticipantPlacement> placements,
    required List<SeedingParticipant> participants,
    required int bracketSize,
  }) {
    return countViolations(
          placements: placements,
          participants: participants,
          bracketSize: bracketSize,
        ) ==
        0;
  }

  @override
  int countViolations({
    required List<ParticipantPlacement> placements,
    required List<SeedingParticipant> participants,
    required int bracketSize,
  }) {
    if (placements.isEmpty) return 0;

    // Build a map from participantId to dojang name for fast lookup
    final dojangMap = <String, String>{};
    for (final p in participants) {
      dojangMap[p.id] = p.dojangName.toLowerCase().trim();
    }

    var violations = 0;
    // Use bitLength for integer-precise totalRounds calculation.
    // bracketSize is always power of 2, so (bracketSize-1).bitLength == log2(bracketSize).
    // Example: bracketSize=8 → (7).bitLength = 3 → totalRounds = 3 ✓
    final totalRounds = bracketSize <= 1 ? 0 : (bracketSize - 1).bitLength;

    // Check all pairs of placed participants
    for (var i = 0; i < placements.length; i++) {
      for (var j = i + 1; j < placements.length; j++) {
        final a = placements[i];
        final b = placements[j];

        final dojangA = dojangMap[a.participantId];
        final dojangB = dojangMap[b.participantId];

        // Skip if different dojangs
        if (dojangA != dojangB) continue;

        // Calculate earliest meeting round
        final meetingRound = earliestMeetingRound(
          a.seedPosition,
          b.seedPosition,
          bracketSize,
          totalRounds,
        );

        // Violation if they meet before the minimum round
        // Reduced strictness: if bracket is too small, reduce separation
        // to allow them to meet in the final round at least.
        var effectiveSeparation = minimumRoundsSeparation;
        if (totalRounds > 0 && effectiveSeparation >= totalRounds) {
          effectiveSeparation = totalRounds - 1;
        }

        if (meetingRound <= effectiveSeparation && meetingRound > 0) {
          violations++;
        }
      }
    }

    return violations;
  }

  /// Calculates the earliest round two seeds can meet in a
  /// single elimination bracket.
  ///
  /// Seeds are 1-indexed. bracketSize must be a power of 2.
  /// Returns 1 for Round 1 (first round), totalRounds for the Final.
  ///
  /// Uses XOR + bitLength for O(1) integer-precise calculation.
  static int earliestMeetingRound(
    int seedA,
    int seedB,
    int bracketSize,
    int totalRounds,
  ) {
    if (seedA == seedB) return 0; // Same position

    // Convert to 0-indexed
    final a = seedA - 1;
    final b = seedB - 1;

    final xor = a ^ b;
    // int.bitLength gives position of the highest set bit
    final msb = xor.bitLength;
    return totalRounds - msb + 1;
  }
}
