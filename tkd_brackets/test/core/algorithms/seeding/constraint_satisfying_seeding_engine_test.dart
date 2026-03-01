import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/dojang_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';

void main() {
  late ConstraintSatisfyingSeedingEngine engine;

  setUp(() {
    engine = ConstraintSatisfyingSeedingEngine();
  });

  group('ConstraintSatisfyingSeedingEngine', () {
    test('4 participants, 2 dojangs (evenly split) — perfect separation', () {
      final participants = [
        const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
        const SeedingParticipant(id: 'p3', dojangName: 'Dragon'),
        const SeedingParticipant(id: 'p2', dojangName: 'Tiger'),
        const SeedingParticipant(id: 'p4', dojangName: 'Dragon'),
      ];

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [
          DojangSeparationConstraint(minimumRoundsSeparation: 1),
        ], // Separate Round 1
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );

      expect(result.isRight(), isTrue);
      final seeding = result.getOrElse((_) => throw Exception('unexpected'));
      expect(seeding.isFullySatisfied, isTrue);
      expect(seeding.constraintViolationCount, 0);
    });

    test(
      '8 participants, 2 dojangs (evenly split) — perfect separation (R1)',
      () {
        final participants = List.generate(
          8,
          (i) => SeedingParticipant(
            id: 'p$i',
            dojangName: i < 4 ? 'Tiger' : 'Dragon',
          ),
        );

        final result = engine.generateSeeding(
          participants: participants,
          strategy: SeedingStrategy.random,
          constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 1)],
          bracketFormat: BracketFormat.singleElimination,
          randomSeed: 42,
        );

        expect(result.isRight(), isTrue);
        final seeding = result.getOrElse((_) => throw Exception('unexpected'));
        expect(seeding.isFullySatisfied, isTrue);
      },
    );

    test(
      '8 participants, 3 dojangs (varied sizes: 4, 2, 2) — perfect separation (R1)',
      () {
        final participants = [
          ...List.generate(
            4,
            (i) => SeedingParticipant(id: 't$i', dojangName: 'Tiger'),
          ),
          ...List.generate(
            2,
            (i) => SeedingParticipant(id: 'd$i', dojangName: 'Dragon'),
          ),
          ...List.generate(
            2,
            (i) => SeedingParticipant(id: 'e$i', dojangName: 'Eagle'),
          ),
        ];

        final result = engine.generateSeeding(
          participants: participants,
          strategy: SeedingStrategy.random,
          constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 1)],
          bracketFormat: BracketFormat.singleElimination,
          randomSeed: 42,
        );

        expect(result.isRight(), isTrue);
        final seeding = result.getOrElse((_) => throw Exception('unexpected'));
        expect(seeding.isFullySatisfied, isTrue);
      },
    );

    test(
      '16 participants, 4 dojangs — no same-dojang meetings before round 2',
      () {
        final participants = List.generate(
          16,
          (i) => SeedingParticipant(id: 'p$i', dojangName: 'Dojang${i % 4}'),
        );

        final result = engine.generateSeeding(
          participants: participants,
          strategy: SeedingStrategy.random,
          constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 1)],
          bracketFormat: BracketFormat.singleElimination,
          randomSeed: 123,
        );

        expect(result.isRight(), isTrue);
        final seeding = result.getOrElse((_) => throw Exception('unexpected'));
        expect(seeding.isFullySatisfied, isTrue);
      },
    );

    test('32 participants performance — completes in < 500ms', () {
      final participants = List.generate(
        32,
        (i) => SeedingParticipant(id: 'p$i', dojangName: 'Dojang${i % 8}'),
      );

      final stopwatch = Stopwatch()..start();
      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 1)],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );
      stopwatch.stop();

      expect(result.isRight(), isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('single dojang — fallback with warning', () {
      final participants = List.generate(
        4,
        (i) => const SeedingParticipant(id: 'p', dojangName: 'Tiger'),
      );

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 2)],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );

      expect(result.isRight(), isTrue);
      final seeding = result.getOrElse((_) => throw Exception('unexpected'));
      expect(seeding.isFullySatisfied, isFalse);
      expect(seeding.warnings, anyElement(contains('same dojang')));
    });

    test('impossible constraint (6 from one dojang in 8-person bracket)', () {
      final participants = [
        ...List.generate(
          6,
          (i) => SeedingParticipant(id: 't$i', dojangName: 'Tiger'),
        ),
        const SeedingParticipant(id: 'd1', dojangName: 'Dragon'),
        const SeedingParticipant(id: 'd2', dojangName: 'Dragon'),
      ];

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 2)],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );

      expect(result.isRight(), isTrue);
      final seeding = result.getOrElse((_) => throw Exception('unexpected'));
      expect(seeding.isFullySatisfied, isFalse);
    });

    test('2 participants, same dojang — placed with warning', () {
      final participants = [
        const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
        const SeedingParticipant(id: 'p2', dojangName: 'Tiger'),
      ];

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 1)],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );

      expect(result.isRight(), isTrue);
      final seeding = result.getOrElse((_) => throw Exception('unexpected'));
      expect(seeding.isFullySatisfied, isFalse);
      expect(seeding.warnings, anyElement(contains('same dojang')));
    });

    test('all unique dojangs — fully satisfied', () {
      final participants = List.generate(
        8,
        (i) => SeedingParticipant(id: 'p$i', dojangName: 'Dojang$i'),
      );

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 2)],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );

      expect(result.isRight(), isTrue);
      final seeding = result.getOrElse((_) => throw Exception('unexpected'));
      expect(seeding.isFullySatisfied, isTrue);
    });

    test('deterministic output — same randomSeed produces same result', () {
      final participants = List.generate(
        16,
        (i) => SeedingParticipant(id: 'p$i', dojangName: 'Dojang${i % 4}'),
      );

      final result1 = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 1)],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );

      final result2 = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 1)],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );

      expect(result1, equals(result2));
    });

    test('0 participants — returns SeedingFailure', () {
      final result = engine.generateSeeding(
        participants: [],
        strategy: SeedingStrategy.random,
        constraints: [],
        bracketFormat: BracketFormat.singleElimination,
      );

      expect(result.isLeft(), isTrue);
    });

    group('validateSeeding', () {
      test('returns Right(unit) when all constraints satisfied', () {
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(
            participantId: 'p2',
            seedPosition: 5,
          ), // Final in size 8
        ];
        final participants = [
          const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
          const SeedingParticipant(id: 'p2', dojangName: 'Tiger'),
        ];

        final result = engine.validateSeeding(
          placements: placements,
          participants: participants,
          constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 2)],
          bracketFormat: BracketFormat.singleElimination,
          bracketSize: 8,
        );

        expect(result.isRight(), isTrue);
      });

      test('returns Left(SeedingFailure) when constraint violated', () {
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(
            participantId: 'p2',
            seedPosition: 2,
          ), // Round 1
        ];
        final participants = [
          const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
          const SeedingParticipant(id: 'p2', dojangName: 'Tiger'),
        ];

        final result = engine.validateSeeding(
          placements: placements,
          participants: participants,
          constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 2)],
          bracketFormat: BracketFormat.singleElimination,
          bracketSize: 8,
        );

        expect(result.isLeft(), isTrue);
      });
    });
  });
}
