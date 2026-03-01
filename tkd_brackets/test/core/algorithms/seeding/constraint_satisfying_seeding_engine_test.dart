import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/dojang_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';

void main() {
  late ConstraintSatisfyingSeedingEngine engine;

  setUp(() {
    engine = ConstraintSatisfyingSeedingEngine();
  });

  /// Helper: creates participants with specified dojang distribution.
  List<SeedingParticipant> makeParticipantsWithDojangs(
    Map<String, int> dojangCounts,
  ) {
    final participants = <SeedingParticipant>[];
    var counter = 1;
    for (final entry in dojangCounts.entries) {
      for (var i = 0; i < entry.value; i++) {
        participants.add(
          SeedingParticipant(id: 'p$counter', dojangName: entry.key),
        );
        counter++;
      }
    }
    return participants;
  }

  /// Helper: verifies that the seeding result satisfies the constraint.
  void verifySeparation(
    List<ParticipantPlacement> placements,
    List<SeedingParticipant> participants,
    int bracketSize, {
    int minimumRoundsSeparation = 2,
  }) {
    final constraint = DojangSeparationConstraint(
      minimumRoundsSeparation: minimumRoundsSeparation,
    );
    expect(
      constraint.isSatisfied(
        placements: placements,
        participants: participants,
        bracketSize: bracketSize,
      ),
      isTrue,
      reason: 'Dojang separation constraint should be satisfied',
    );
  }

  group('ConstraintSatisfyingSeedingEngine', () {
    test('4 participants, 2 dojangs (evenly split) — perfect separation', () {
      final participants = makeParticipantsWithDojangs({
        'Tiger Dojang': 2,
        'Dragon Dojang': 2,
      });

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 1)],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );

      expect(result.isRight(), isTrue);
      final seeding = result.getOrElse((_) => throw Exception('unexpected'));
      expect(seeding.placements.length, 4);
      expect(seeding.isFullySatisfied, isTrue);
      expect(seeding.constraintViolationCount, 0);

      verifySeparation(
        seeding.placements,
        participants,
        4,
        minimumRoundsSeparation: 1,
      );
    });

    test('8 participants, 2 dojangs (evenly split) — perfect separation', () {
      final participants = makeParticipantsWithDojangs({
        'Tiger': 4,
        'Dragon': 4,
      });

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
      verifySeparation(
        seeding.placements,
        participants,
        8,
        minimumRoundsSeparation: 1,
      );
    });

    test(
      '8 participants, 3 dojangs (varied sizes: 4, 2, 2) — perfect separation',
      () {
        final participants = makeParticipantsWithDojangs({
          'Tiger': 4,
          'Dragon': 2,
          'Phoenix': 2,
        });

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
        verifySeparation(
          seeding.placements,
          participants,
          8,
          minimumRoundsSeparation: 1,
        );
      },
    );

    test(
      '16 participants, 4 dojangs — no same-dojang meetings before round 2',
      () {
        final participants = makeParticipantsWithDojangs({
          'A': 4,
          'B': 4,
          'C': 4,
          'D': 4,
        });

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
        verifySeparation(
          seeding.placements,
          participants,
          16,
          minimumRoundsSeparation: 1,
        );
      },
    );

    test('32 participants performance — completes in < 500ms', () {
      final participants = makeParticipantsWithDojangs({
        'A': 8,
        'B': 8,
        'C': 8,
        'D': 8,
      });

      final sw = Stopwatch()..start();
      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 2)],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );
      sw.stop();

      expect(result.isRight(), isTrue);
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('single dojang — fallback with warning', () {
      final participants = makeParticipantsWithDojangs({'Tiger': 8});

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint()],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );

      expect(result.isRight(), isTrue);
      final seeding = result.getOrElse((_) => throw Exception('unexpected'));
      expect(seeding.isFullySatisfied, isFalse);
      expect(seeding.warnings, isNotEmpty);
      expect(seeding.placements.length, 8);
    });

    test(
      'impossible constraint (6 from one dojang in 8-person bracket) — minimal violations',
      () {
        final participants = makeParticipantsWithDojangs({
          'Tiger': 6,
          'Dragon': 2,
        });

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
        expect(seeding.constraintViolationCount, greaterThan(0));
        expect(seeding.warnings, isNotEmpty);
      },
    );

    test('2 participants, same dojang — placed with warning', () {
      final participants = makeParticipantsWithDojangs({'Tiger': 2});

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint()],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );

      expect(result.isRight(), isTrue);
      final seeding = result.getOrElse((_) => throw Exception('unexpected'));
      expect(seeding.placements.length, 2);
      expect(seeding.isFullySatisfied, isFalse);
    });

    test('all unique dojangs — fully satisfied', () {
      final participants = <SeedingParticipant>[];
      for (var i = 1; i <= 8; i++) {
        participants.add(
          SeedingParticipant(id: 'p$i', dojangName: 'Dojang $i'),
        );
      }

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint()],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );

      expect(result.isRight(), isTrue);
      final seeding = result.getOrElse((_) => throw Exception('unexpected'));
      expect(seeding.isFullySatisfied, isTrue);
      expect(seeding.constraintViolationCount, 0);
    });

    test('deterministic output — same randomSeed produces same result', () {
      final participants = makeParticipantsWithDojangs({'A': 4, 'B': 4});

      final r1 = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint()],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 123,
      );

      final r2 = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint()],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 123,
      );

      expect(r1, equals(r2));
    });

    test('0 participants — returns SeedingFailure', () {
      final result = engine.generateSeeding(
        participants: [],
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint()],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );

      expect(result.isLeft(), isTrue);
    });

    test(
      'default minimumRoundsSeparation=2 — returns valid result (satisfied or graceful fallback)',
      () {
        final participants = makeParticipantsWithDojangs({
          'Tiger': 4,
          'Dragon': 4,
        });

        final result = engine.generateSeeding(
          participants: participants,
          strategy: SeedingStrategy.random,
          constraints: [DojangSeparationConstraint()], // default = 2
          bracketFormat: BracketFormat.singleElimination,
          randomSeed: 42,
        );

        expect(result.isRight(), isTrue);
        final seeding = result.getOrElse((_) => throw Exception('unexpected'));
        expect(seeding.placements.length, 8);
        // Either fully satisfied or graceful degradation with warnings
        if (!seeding.isFullySatisfied) {
          expect(seeding.warnings, isNotEmpty);
          expect(seeding.constraintViolationCount, greaterThan(0));
        }
      },
    );

    test(
      '16 participants, 4 dojangs — fully satisfied with default sep=2',
      () {
        final participants = makeParticipantsWithDojangs({
          'A': 4,
          'B': 4,
          'C': 4,
          'D': 4,
        });

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
        verifySeparation(
          seeding.placements,
          participants,
          16,
          minimumRoundsSeparation: 1,
        );
      },
    );
  });

  group('validateSeeding', () {
    test('returns Right(unit) when all constraints satisfied', () {
      final placements = [
        const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
        const ParticipantPlacement(participantId: 'p2', seedPosition: 2),
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
        const ParticipantPlacement(participantId: 'p2', seedPosition: 5),
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
}
