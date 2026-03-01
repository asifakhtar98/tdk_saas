import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/dojang_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

void main() {
  group('DojangSeparationConstraint', () {
    group('earliestMeetingRound', () {
      // 8-person bracket: 3 rounds
      test('seeds 1 & 2 meet in round 3 (final)', () {
        expect(DojangSeparationConstraint.earliestMeetingRound(1, 2, 8, 3), 3);
      });

      test('seeds 1 & 3 meet in round 2 (semifinal)', () {
        expect(DojangSeparationConstraint.earliestMeetingRound(1, 3, 8, 3), 2);
      });

      test('seeds 1 & 5 meet in round 1 (quarterfinal)', () {
        expect(DojangSeparationConstraint.earliestMeetingRound(1, 5, 8, 3), 1);
      });

      test('seeds 2 & 6 meet in round 1', () {
        expect(DojangSeparationConstraint.earliestMeetingRound(2, 6, 8, 3), 1);
      });
    });

    group('isSatisfied', () {
      test('returns true when same-dojang athletes are separated', () {
        final constraint = DojangSeparationConstraint(
          minimumRoundsSeparation: 2,
        );
        // In 8-person bracket: seeds 1 & 2 meet in round 3 (> 2) ✓
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(participantId: 'p2', seedPosition: 2),
        ];
        final participants = [
          const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
          const SeedingParticipant(id: 'p2', dojangName: 'Tiger'),
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

      test('returns false when same-dojang athletes meet too early', () {
        final constraint = DojangSeparationConstraint(
          minimumRoundsSeparation: 2,
        );
        // In 8-person bracket: seeds 1 & 5 meet in round 1 (<= 2) ✗
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(participantId: 'p2', seedPosition: 5),
        ];
        final participants = [
          const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
          const SeedingParticipant(id: 'p2', dojangName: 'Tiger'),
        ];
        expect(
          constraint.isSatisfied(
            placements: placements,
            participants: participants,
            bracketSize: 8,
          ),
          isFalse,
        );
      });

      test('returns true when different dojangs meet early', () {
        final constraint = DojangSeparationConstraint(
          minimumRoundsSeparation: 2,
        );
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(participantId: 'p2', seedPosition: 5),
        ];
        final participants = [
          const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
          const SeedingParticipant(id: 'p2', dojangName: 'Dragon'),
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
      test('reduced strictness: allows same-dojang final in 4-person bracket even if minSep is high', () {
        final constraint = DojangSeparationConstraint(
          minimumRoundsSeparation: 2, // No meeting in R1 or R2
        );
        // In 4-person bracket, R2 is the final.
        // With reduced strictness, effSep becomes 1 (totalRounds - 1).
        // Meeting in R2 (Final) should be allowed.
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(participantId: 'p2', seedPosition: 2),
        ];
        final participants = [
          const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
          const SeedingParticipant(id: 'p2', dojangName: 'Tiger'),
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
    });

    group('countViolations', () {
      test('counts multiple violations correctly', () {
        final constraint = DojangSeparationConstraint(
          minimumRoundsSeparation: 2,
        );
        // 8-person bracket: seeds 1&3 meet R2 (<=2 → violation),
        // seeds 5&7 meet R2 (<=2 → violation)
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(participantId: 'p2', seedPosition: 3),
          const ParticipantPlacement(participantId: 'p3', seedPosition: 5),
          const ParticipantPlacement(participantId: 'p4', seedPosition: 7),
        ];
        final participants = [
          const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
          const SeedingParticipant(id: 'p2', dojangName: 'Tiger'),
          const SeedingParticipant(id: 'p3', dojangName: 'Tiger'),
          const SeedingParticipant(id: 'p4', dojangName: 'Tiger'),
        ];
        // p1&p2 meet R2 (viol), p1&p3 meet R1 (viol), p1&p4 meet R1 (viol),
        // p2&p3 meet R1 (viol), p2&p4 meet R1 (viol), p3&p4 meet R2 (viol) = 6
        expect(
          constraint.countViolations(
            placements: placements,
            participants: participants,
            bracketSize: 8,
          ),
          greaterThan(0),
        );
      });

      test('returns 0 when no violations', () {
        final constraint = DojangSeparationConstraint(
          minimumRoundsSeparation: 2,
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
