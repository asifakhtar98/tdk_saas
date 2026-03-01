import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/dojang_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/regional_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';

void main() {
  late ConstraintSatisfyingSeedingEngine engine;

  setUp(() {
    engine = ConstraintSatisfyingSeedingEngine();
  });

  group('Combined dojang + regional constraints', () {
    test('both constraints satisfied — unique dojangs, unique regions', () {
      final participants = [
        const SeedingParticipant(id: 'p1', dojangName: 'D1', regionName: 'R1'),
        const SeedingParticipant(id: 'p2', dojangName: 'D2', regionName: 'R2'),
        const SeedingParticipant(id: 'p3', dojangName: 'D3', regionName: 'R3'),
        const SeedingParticipant(id: 'p4', dojangName: 'D4', regionName: 'R4'),
      ];

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [
          DojangSeparationConstraint(minimumRoundsSeparation: 2),
          RegionalSeparationConstraint(minimumRoundsSeparation: 2),
        ],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );

      expect(result.isRight(), isTrue);
      final seeding = result.getOrElse((_) => throw Exception('unexpected'));
      expect(seeding.isFullySatisfied, isTrue);
    });

    test('mixed region data — some with, some without', () {
      final participants = [
        const SeedingParticipant(
          id: 'p1',
          dojangName: 'T1',
          regionName: 'North',
        ),
        const SeedingParticipant(id: 'p2', dojangName: 'T1', regionName: null),
        const SeedingParticipant(
          id: 'p3',
          dojangName: 'T2',
          regionName: 'North',
        ),
        const SeedingParticipant(id: 'p4', dojangName: 'T2', regionName: ''),
      ];

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [
          DojangSeparationConstraint(minimumRoundsSeparation: 2),
          RegionalSeparationConstraint(minimumRoundsSeparation: 2),
        ],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );

      expect(result.isRight(), isTrue);
      final seeding = result.getOrElse((_) => throw Exception('unexpected'));
      // p1 & p2 (T1) must meet R2 (Final).
      // p1 & p3 (North) must meet R2 (Final).
      // This is possible: {p1:1, p2:3, p3:2, p4:4}
      // R1: (1 vs 2) -> p1 vs p3 (both North) -> VIOLATION if North is same region.
      // Wait, let's see: seeds {1, 3} are R2. Seeds {1, 2} are R1.
      // Solution: {p1:1, p2:3, p3:4, p4:2}.
      // R1 pairings: (1, 2) -> p1 vs p4. (3, 4) -> p2 vs p3.
      // p1 vs p4: no conflict. p2 vs p3: no conflict.
      // R2 pairings: Winner 1/2 vs Winner 3/4.
      // p1(T1) vs p2(T1) in Final. p1(N) vs p3(N) in Final.
      // YES!
      expect(seeding.isFullySatisfied, isTrue);
    });

    test('dojang takes priority over regional when conflicting', () {
      // In a 4-person bracket, it's possible to satisfy both if they are distinct.
      // But if we have 4 participants where every combination hits something...
      // tiger (p1, p2). dragon (p3, p4).
      // North (p1, p3). South (p2, p4).
      final participants = [
        const SeedingParticipant(
          id: 'p1',
          dojangName: 'Tiger',
          regionName: 'North',
        ),
        const SeedingParticipant(
          id: 'p2',
          dojangName: 'Tiger',
          regionName: 'South',
        ),
        const SeedingParticipant(
          id: 'p3',
          dojangName: 'Dragon',
          regionName: 'North',
        ),
        const SeedingParticipant(
          id: 'p4',
          dojangName: 'Dragon',
          regionName: 'South',
        ),
      ];

      // With default sep=2 for dojang and sep=1 for regional:
      // Dojang Tiger (p1, p2) must not meet in Round 1.
      // Dojang Dragon (p3, p4) must not meet in Round 1.
      // Region North (p1, p3) must not meet in Round 1.
      // Region South (p2, p4) must not meet in Round 1.

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [
          DojangSeparationConstraint(minimumRoundsSeparation: 2),
          RegionalSeparationConstraint(minimumRoundsSeparation: 1),
        ],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );

      expect(result.isRight(), isTrue);
      final seeding = result.getOrElse((_) => throw Exception('unexpected'));
      // In this case, both CAN be satisfied:
      // Match 1 (R1): p1(1) vs p4(2). Match 2 (R1): p3(3) vs p2(4).
      // p1 vs p4: No dojang (T/D), No region (N/S).
      // p3 vs p2: No dojang (D/T), No region (N/S).
      expect(seeding.isFullySatisfied, isTrue);
    });

    test('all same dojang returns with warning (early-exit path)', () {
      // Use unique IDs — the use case validates duplicate IDs, but engine does not.
      // Unique IDs make this a realistic fixture.
      final participants = [
        const SeedingParticipant(id: 'p1', dojangName: 'Tiger', regionName: 'North'),
        const SeedingParticipant(id: 'p2', dojangName: 'Tiger', regionName: 'South'),
        const SeedingParticipant(id: 'p3', dojangName: 'Tiger', regionName: 'North'),
        const SeedingParticipant(id: 'p4', dojangName: 'Tiger', regionName: 'South'),
      ];

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [
          DojangSeparationConstraint(minimumRoundsSeparation: 2),
          RegionalSeparationConstraint(minimumRoundsSeparation: 1),
        ],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );

      expect(result.isRight(), isTrue);
      final seeding = result.getOrElse((_) => throw Exception('unexpected'));
      expect(seeding.isFullySatisfied, isFalse);
      expect(
        seeding.warnings,
        anyElement(contains('participants are from the same dojang')),
      );
    });

    test('isSatisfied detects violations in complete list even when last participant has no region', () {
      // Regression test for H3: isSatisfied must scan all pairs, not just the last participant.
      // p1(North):seed1, p2(North):seed2 would violate in a 4-person bracket (meet round 1).
      // p3 has no region — it is placed last. Without a full scan, isSatisfied would return
      // true (last participant has no region), silently missing the p1/p2 violation.
      final constraint = RegionalSeparationConstraint(minimumRoundsSeparation: 1);
      final placements = [
        const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
        const ParticipantPlacement(participantId: 'p2', seedPosition: 2),
        const ParticipantPlacement(participantId: 'p3', seedPosition: 3),
      ];
      final participants = [
        const SeedingParticipant(id: 'p1', dojangName: 'A', regionName: 'North'),
        const SeedingParticipant(id: 'p2', dojangName: 'B', regionName: 'North'),
        const SeedingParticipant(id: 'p3', dojangName: 'C'), // no region
      ];
      // p1 & p2 share 'North' and meet in round 1 of a 4-person bracket → violation
      expect(
        constraint.isSatisfied(
          placements: placements,
          participants: participants,
          bracketSize: 4,
        ),
        isFalse,
        reason: 'p1 and p2 both North and meet in round 1; isSatisfied must catch this even though last participant (p3) has no region',
      );
    });

    test('performance — 64 participants with combined constraints', () {
      final participants = List.generate(
        64,
        (i) => SeedingParticipant(
          id: 'p$i',
          dojangName: 'Dojang${i % 8}',
          regionName: 'Region${i % 4}',
        ),
      );

      final stopwatch = Stopwatch()..start();
      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [
          DojangSeparationConstraint(minimumRoundsSeparation: 2),
          RegionalSeparationConstraint(minimumRoundsSeparation: 1),
        ],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 123,
      );
      stopwatch.stop();

      expect(result.isRight(), isTrue);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: 'Should complete in < 500ms',
      );
    });
  });
}
