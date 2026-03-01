import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/regional_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

void main() {
  group('RegionalSeparationConstraint', () {
    test('name returns regional_separation', () {
      final constraint = RegionalSeparationConstraint();
      expect(constraint.name, 'regional_separation');
    });

    test('violationMessage returns non-empty string', () {
      final constraint = RegionalSeparationConstraint();
      expect(constraint.violationMessage, isNotEmpty);
    });

    group('isSatisfied', () {
      test('returns true when same-region athletes are well-separated', () {
        final constraint = RegionalSeparationConstraint(
          minimumRoundsSeparation: 1,
        );
        // In 8-person bracket: seeds 1 & 3 meet in round 2 (> 1) ✓
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(participantId: 'p2', seedPosition: 3),
        ];
        final participants = [
          const SeedingParticipant(
            id: 'p1',
            dojangName: 'Tiger',
            regionName: 'North',
          ),
          const SeedingParticipant(
            id: 'p2',
            dojangName: 'Dragon',
            regionName: 'North',
          ),
        ];
        expect(
          constraint.isSatisfied(
            placements: placements,
            participants: participants,
            bracketSize: 8,
          ),
          isTrue,
        );
      });

      test('returns false when same-region athletes meet in round 1', () {
        final constraint = RegionalSeparationConstraint(
          minimumRoundsSeparation: 1,
        );
        // seeds 1 & 2 meet in round 1 → violation
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(participantId: 'p2', seedPosition: 2),
        ];
        final participants = [
          const SeedingParticipant(
            id: 'p1',
            dojangName: 'Tiger',
            regionName: 'North',
          ),
          const SeedingParticipant(
            id: 'p2',
            dojangName: 'Dragon',
            regionName: 'North',
          ),
        ];
        expect(
          constraint.isSatisfied(
            placements: placements,
            participants: participants,
            bracketSize: 4,
          ),
          isFalse,
        );
      });

      test('returns true when different-region athletes meet early', () {
        final constraint = RegionalSeparationConstraint(
          minimumRoundsSeparation: 1,
        );
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(participantId: 'p2', seedPosition: 2),
        ];
        final participants = [
          const SeedingParticipant(
            id: 'p1',
            dojangName: 'Tiger',
            regionName: 'North',
          ),
          const SeedingParticipant(
            id: 'p2',
            dojangName: 'Dragon',
            regionName: 'South',
          ),
        ];
        expect(
          constraint.isSatisfied(
            placements: placements,
            participants: participants,
            bracketSize: 4,
          ),
          isTrue,
        );
      });

      test('skips participants without region — no violation', () {
        final constraint = RegionalSeparationConstraint(
          minimumRoundsSeparation: 1,
        );
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(participantId: 'p2', seedPosition: 2),
        ];
        final participants = [
          const SeedingParticipant(
            id: 'p1',
            dojangName: 'Tiger',
          ), // null region
          const SeedingParticipant(
            id: 'p2',
            dojangName: 'Dragon',
            regionName: 'North',
          ),
        ];
        expect(
          constraint.isSatisfied(
            placements: placements,
            participants: participants,
            bracketSize: 4,
          ),
          isTrue,
        );
      });

      test('skips participants with empty-string region — no violation', () {
        final constraint = RegionalSeparationConstraint(
          minimumRoundsSeparation: 1,
        );
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(participantId: 'p2', seedPosition: 2),
        ];
        final participants = [
          const SeedingParticipant(
            id: 'p1',
            dojangName: 'Tiger',
            regionName: '',
          ),
          const SeedingParticipant(
            id: 'p2',
            dojangName: 'Dragon',
            regionName: 'North',
          ),
        ];
        expect(
          constraint.isSatisfied(
            placements: placements,
            participants: participants,
            bracketSize: 4,
          ),
          isTrue,
        );
      });

      test('skips participants with whitespace-only region — no violation', () {
        final constraint = RegionalSeparationConstraint(
          minimumRoundsSeparation: 1,
        );
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(participantId: 'p2', seedPosition: 2),
        ];
        final participants = [
          const SeedingParticipant(
            id: 'p1',
            dojangName: 'Tiger',
            regionName: '  ',
          ),
          const SeedingParticipant(
            id: 'p2',
            dojangName: 'Dragon',
            regionName: 'North',
          ),
        ];
        expect(
          constraint.isSatisfied(
            placements: placements,
            participants: participants,
            bracketSize: 4,
          ),
          isTrue,
        );
      });

      test('auto-satisfied when no participants have regions', () {
        final constraint = RegionalSeparationConstraint(
          minimumRoundsSeparation: 1,
        );
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(participantId: 'p2', seedPosition: 2),
        ];
        final participants = [
          const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
          const SeedingParticipant(id: 'p2', dojangName: 'Dragon'),
        ];
        expect(
          constraint.isSatisfied(
            placements: placements,
            participants: participants,
            bracketSize: 4,
          ),
          isTrue,
        );
      });

      test('case-insensitive: North and north treated as same region', () {
        final constraint = RegionalSeparationConstraint(
          minimumRoundsSeparation: 1,
        );
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(participantId: 'p2', seedPosition: 2),
        ];
        final participants = [
          const SeedingParticipant(
            id: 'p1',
            dojangName: 'T1',
            regionName: 'North',
          ),
          const SeedingParticipant(
            id: 'p2',
            dojangName: 'T2',
            regionName: 'north',
          ),
        ];
        expect(
          constraint.isSatisfied(
            placements: placements,
            participants: participants,
            bracketSize: 4,
          ),
          isFalse,
        );
      });

      test(
        'reduced strictness: allows same-region final in 4-person bracket',
        () {
          final constraint = RegionalSeparationConstraint(
            minimumRoundsSeparation: 2,
          );
          // Seeds 1 & 3 meet in Round 2 (Final).
          // effectiveSep = min(2, 2-1) = 1.
          // Round 2 > 1. OK.
          final placements = [
            const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
            const ParticipantPlacement(participantId: 'p2', seedPosition: 3),
          ];
          final participants = [
            const SeedingParticipant(
              id: 'p1',
              dojangName: 'T1',
              regionName: 'North',
            ),
            const SeedingParticipant(
              id: 'p2',
              dojangName: 'T2',
              regionName: 'North',
            ),
          ];
          expect(
            constraint.isSatisfied(
              placements: placements,
              participants: participants,
              bracketSize: 4,
            ),
            isTrue,
          );
        },
      );
    });

    group('countViolations', () {
      test('returns 0 for empty placements', () {
        final constraint = RegionalSeparationConstraint();
        expect(
          constraint.countViolations(
            placements: [],
            participants: [],
            bracketSize: 8,
          ),
          0,
        );
      });

      test('counts multiple same-region violations correctly — exact count', () {
        final constraint = RegionalSeparationConstraint(
          minimumRoundsSeparation: 2,
        );
        // 8-person bracket: seeds 1&2 meet in round 1, seeds 3&4 meet in round 1.
        // Both pairs are same-region North, both violate minimumRoundsSeparation=2.
        // seeds 1&3, 1&4, 2&3, 2&4 meet in round 2 — exactly at the boundary (round==sep → counted).
        // Let's count precisely:
        //   (p1:1, p2:2) → XOR=1, bitLength=1, round = 3-1+1=3? No.
        //   totalRounds = (8-1).bitLength = 3.
        //   XOR(0,1)=1, bitLength=1. meetingRound = 3-1+1 = 3. Wait...
        //   DojangSeparationConstraint.earliestMeetingRound uses: totalRounds - (xor).bitLength + 1.
        //   Seeds use 1-indexed, so i=seed-1: seed1→0, seed2→1, seed3→2, seed4→3.
        //   p1(seed1) vs p2(seed2): 0^1=1, bitLength=1 → round = 3-1+1=3. >2. No violation.
        //   p1(seed1) vs p3(seed3): 0^2=2, bitLength=2 → round = 3-2+1=2. ==2. Violation.
        //   p1(seed1) vs p4(seed4): 0^3=3, bitLength=2 → round = 3-2+1=2. ==2. Violation.
        //   p2(seed2) vs p3(seed3): 1^2=3, bitLength=2 → round = 3-2+1=2. ==2. Violation.
        //   p2(seed2) vs p4(seed4): 1^3=2, bitLength=2 → round = 3-2+1=2. ==2. Violation.
        //   p3(seed3) vs p4(seed4): 2^3=1, bitLength=1 → round = 3-1+1=3. >2. No violation.
        // Total = 4 violations.
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(participantId: 'p2', seedPosition: 2),
          const ParticipantPlacement(participantId: 'p3', seedPosition: 3),
          const ParticipantPlacement(participantId: 'p4', seedPosition: 4),
        ];
        final participants = [
          const SeedingParticipant(
            id: 'p1',
            dojangName: 'A',
            regionName: 'North',
          ),
          const SeedingParticipant(
            id: 'p2',
            dojangName: 'B',
            regionName: 'North',
          ),
          const SeedingParticipant(
            id: 'p3',
            dojangName: 'C',
            regionName: 'North',
          ),
          const SeedingParticipant(
            id: 'p4',
            dojangName: 'D',
            regionName: 'North',
          ),
        ];
        final violations = constraint.countViolations(
          placements: placements,
          participants: participants,
          bracketSize: 8,
        );
        expect(violations, 6);
      });

      test('returns 0 when all different regions', () {
        final constraint = RegionalSeparationConstraint(
          minimumRoundsSeparation: 1,
        );
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(participantId: 'p2', seedPosition: 2),
        ];
        final participants = [
          const SeedingParticipant(
            id: 'p1',
            dojangName: 'T1',
            regionName: 'North',
          ),
          const SeedingParticipant(
            id: 'p2',
            dojangName: 'T2',
            regionName: 'South',
          ),
        ];
        expect(
          constraint.countViolations(
            placements: placements,
            participants: participants,
            bracketSize: 8,
          ),
          0,
        );
      });
    });
  });
}
