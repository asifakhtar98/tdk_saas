import 'package:tkd_brackets/core/algorithms/seeding/constraints/dojang_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/seeding_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

/// Constraint ensuring same-region athletes do not meet
/// before a specified round in the bracket.
///
/// Unlike [DojangSeparationConstraint], this constraint:
/// - Uses [SeedingParticipant.regionName] (nullable) instead of dojangName
/// - Skips participants with null/empty regionName (no violation)
/// - Has a lower default separation (1 round) since regional is weaker
///
/// [minimumRoundsSeparation] = 1 means same-region athletes
/// should not meet in Round 1 (i.e., earliest meeting should be
/// Round 2 or later).
class RegionalSeparationConstraint extends SeedingConstraint {
  RegionalSeparationConstraint({this.minimumRoundsSeparation = 1});

  /// Minimum number of rounds before same-region athletes can meet.
  /// Default: 1 (cannot meet in Round 1).
  final int minimumRoundsSeparation;

  @override
  String get name => 'regional_separation';

  @override
  String get violationMessage =>
      'Same-region athletes are meeting before round $minimumRoundsSeparation';

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

    // Build map from participantId to normalized region name.
    // Participants with null/empty regionName are excluded from checks.
    final regionMap = <String, String>{};
    for (final p in participants) {
      final region = p.regionName?.toLowerCase().trim();
      if (region != null && region.isNotEmpty) {
        regionMap[p.id] = region;
      }
    }

    // If fewer than 2 participants have regions, constraint is auto-satisfied
    if (regionMap.length < 2) return 0;

    var violations = 0;
    final totalRounds = bracketSize <= 1 ? 0 : (bracketSize - 1).bitLength;

    for (var i = 0; i < placements.length; i++) {
      for (var j = i + 1; j < placements.length; j++) {
        final a = placements[i];
        final b = placements[j];

        final regionA = regionMap[a.participantId];
        final regionB = regionMap[b.participantId];

        // Skip if either participant has no region
        if (regionA == null || regionB == null) continue;

        // Skip if different regions
        if (regionA != regionB) continue;

        // Calculate earliest meeting round — reuse static method from
        // DojangSeparationConstraint (same math, single elimination tree).
        final meetingRound = DojangSeparationConstraint.earliestMeetingRound(
          a.seedPosition,
          b.seedPosition,
          bracketSize,
          totalRounds,
        );

        // Reduced strictness: if bracket is too small, reduce separation
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
}
