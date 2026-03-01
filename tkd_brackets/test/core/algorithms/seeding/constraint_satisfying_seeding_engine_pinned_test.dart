import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/dojang_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';

void main() {
  late ConstraintSatisfyingSeedingEngine engine;

  setUp(() {
    engine = ConstraintSatisfyingSeedingEngine();
  });

  group('ConstraintSatisfyingSeedingEngine with Pinned Seeds', () {
    test('pinned participants stay at their fixed positions', () {
      final participants = [
        const SeedingParticipant(id: '1', dojangName: 'Dojang A'),
        const SeedingParticipant(id: '2', dojangName: 'Dojang B'),
        const SeedingParticipant(id: '3', dojangName: 'Dojang C'),
        const SeedingParticipant(id: '4', dojangName: 'Dojang D'),
      ];

      final pinnedSeeds = {'1': 4, '2': 1};

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.manual,
        constraints: [],
        bracketFormat: BracketFormat.singleElimination,
        pinnedSeeds: pinnedSeeds,
      );

      final seeding = result.getOrElse((_) => throw Exception('Failed'));
      
      final p1 = seeding.placements.firstWhere((p) => p.participantId == '1');
      final p2 = seeding.placements.firstWhere((p) => p.participantId == '2');
      
      expect(p1.seedPosition, 4);
      expect(p2.seedPosition, 1);
    });

    test('unpinned participants are assigned via backtracking', () {
      final participants = [
        const SeedingParticipant(id: '1', dojangName: 'Dojang A'),
        const SeedingParticipant(id: '2', dojangName: 'Dojang B'),
        const SeedingParticipant(id: '3', dojangName: 'Dojang A'), // Conflict with 1
        const SeedingParticipant(id: '4', dojangName: 'Dojang B'),
      ];

      // Pin 1 and 2 far apart
      final pinnedSeeds = {'1': 1, '2': 3};

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.manual,
        constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 1)],
        bracketFormat: BracketFormat.singleElimination,
        pinnedSeeds: pinnedSeeds,
      );

      final seeding = result.getOrElse((_) => throw Exception('Failed'));

      // Check pins
      expect(seeding.placements.firstWhere((p) => p.participantId == '1').seedPosition, 1);
      expect(seeding.placements.firstWhere((p) => p.participantId == '2').seedPosition, 3);

      // 1 (A) is at 1. Neighbor is 2 (B) at 2?
      // Pairings: (1, 2) and (3, 4)
      // If 1 is at 1, 2 must be at 2.
      // 3 (A) must NOT be at 2.
      // So 4 (B) must be at 2.
      // 3 (A) must be at 3 or 4.
      // If 2 is pinned to 3, then 3 must be at 4.
      
      final p3 = seeding.placements.firstWhere((p) => p.participantId == '3');
      final p4 = seeding.placements.firstWhere((p) => p.participantId == '4');
      
      // Slot 1: P1(A). Slot 2 must be P4(B).
      // Slot 3: P2(B). Slot 4 must be P3(A).
      expect(p3.seedPosition, 4);
      expect(p4.seedPosition, 2);
      expect(seeding.isFullySatisfied, true);
    });

    test('constraint checking includes pinned participants', () {
      final participants = [
        const SeedingParticipant(id: 'A1', dojangName: 'Dojang A'),
        const SeedingParticipant(id: 'A2', dojangName: 'Dojang A'),
        const SeedingParticipant(id: 'B1', dojangName: 'Dojang B'),
        const SeedingParticipant(id: 'B2', dojangName: 'Dojang B'),
      ];

      // Pin A1 at 1, A2 at 2 (R1 meeting)
      // Pin B1 at 3, B2 at 4 (R1 meeting)
      final pinnedSeeds = {'A1': 1, 'A2': 2, 'B1': 3, 'B2': 4};

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.manual,
        constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 1)],
        bracketFormat: BracketFormat.singleElimination,
        pinnedSeeds: pinnedSeeds,
      );

      final seeding = result.getOrElse((_) => throw Exception('Failed'));
      
      expect(seeding.constraintViolationCount, 2);
    });

    test('all participants pinned returns exact placement', () {
      final participants = [
        const SeedingParticipant(id: '1', dojangName: 'Dojang A'),
        const SeedingParticipant(id: '2', dojangName: 'Dojang B'),
      ];
      final pinnedSeeds = {'1': 2, '2': 1};

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.manual,
        constraints: [],
        bracketFormat: BracketFormat.singleElimination,
        pinnedSeeds: pinnedSeeds,
      );

      final seeding = result.getOrElse((_) => throw Exception('Failed'));
      expect(seeding.placements.length, 2);
      expect(seeding.placements[0].participantId, '2');
      expect(seeding.placements[0].seedPosition, 1);
      expect(seeding.placements[1].participantId, '1');
      expect(seeding.placements[1].seedPosition, 2);
    });

    test('no pins same as regular seeding', () {
      final participants = [
        const SeedingParticipant(id: '1', dojangName: 'Dojang A'),
        const SeedingParticipant(id: '2', dojangName: 'Dojang B'),
      ];

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [],
        bracketFormat: BracketFormat.singleElimination,
        pinnedSeeds: null,
      );

      expect(result.isRight(), true);
      expect(result.getOrElse((_) => throw Exception()).placements.length, 2);
    });

    test('pinned seed excluded from available pool for unpinned', () {
      final participants = [
        const SeedingParticipant(id: 'PINNED', dojangName: 'X'),
        const SeedingParticipant(id: 'FREE', dojangName: 'Y'),
      ];
      final pinnedSeeds = {'PINNED': 1};

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.manual,
        constraints: [],
        bracketFormat: BracketFormat.singleElimination,
        pinnedSeeds: pinnedSeeds,
      );

      final seeding = result.getOrElse((_) => throw Exception('Failed'));
      
      final free = seeding.placements.firstWhere((p) => p.participantId == 'FREE');
      expect(free.seedPosition, 2);
    });
    test('all same dojang with pins respects pins in random result', () {
      final participants = [
        const SeedingParticipant(id: '1', dojangName: 'Dojang A'),
        const SeedingParticipant(id: '2', dojangName: 'Dojang A'),
        const SeedingParticipant(id: '3', dojangName: 'Dojang A'),
      ];
      final pinnedSeeds = {'1': 3};

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.manual,
        constraints: [],
        bracketFormat: BracketFormat.singleElimination,
        pinnedSeeds: pinnedSeeds,
      );

      final seeding = result.getOrElse((_) => throw Exception('Failed'));
      expect(seeding.warnings.any((w) => w.contains('All participants are from the same dojang')), true);
      
      final p1 = seeding.placements.firstWhere((p) => p.participantId == '1');
      expect(p1.seedPosition, 3);
    });
  });
}
