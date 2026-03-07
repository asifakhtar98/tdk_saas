import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/seeding_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_random_seeding_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_random_seeding_use_case.dart';
import 'package:tkd_brackets/core/error/failures.dart';

class MockSeedingEngine extends Mock implements SeedingEngine {}

void main() {
  late MockSeedingEngine mockEngine;
  late ApplyRandomSeedingUseCase useCase;

  setUpAll(() {
    registerFallbackValue(BracketFormat.singleElimination);
    registerFallbackValue(SeedingStrategy.random);
    // CRITICAL: Must register List<SeedingConstraint> fallback
    // because the constraints param uses any(named: 'constraints')
    registerFallbackValue(<SeedingConstraint>[]);
  });

  setUp(() {
    mockEngine = MockSeedingEngine();
    useCase = ApplyRandomSeedingUseCase(mockEngine);
  });

  final tParticipants = [
    const SeedingParticipant(id: 'p1', dojangName: 'A'),
    const SeedingParticipant(id: 'p2', dojangName: 'B'),
    const SeedingParticipant(id: 'p3', dojangName: 'C'),
    const SeedingParticipant(id: 'p4', dojangName: 'D'),
  ];

  final tParams = ApplyRandomSeedingParams(
    divisionId: 'div1',
    participants: tParticipants,
    randomSeed: 42,
  );

  const tSeedingResult = SeedingResult(
    placements: [],
    appliedConstraints: [],
    randomSeed: 42,
  );

  group('ApplyRandomSeedingUseCase', () {
    test(
      'should call engine with empty constraints and SeedingStrategy.random',
      () async {
        // arrange
        when(
          () => mockEngine.generateSeeding(
            participants: any(named: 'participants'),
            strategy: any(named: 'strategy'),
            constraints: any(named: 'constraints'),
            bracketFormat: any(named: 'bracketFormat'),
            randomSeed: any(named: 'randomSeed'),
          ),
        ).thenReturn(const Right<Failure, SeedingResult>(tSeedingResult));

        // act
        final result = await useCase(tParams);

        // assert
        expect(result, const Right<Failure, SeedingResult>(tSeedingResult));
        verify(
          () => mockEngine.generateSeeding(
            participants: tParticipants,
            strategy: SeedingStrategy.random,
            constraints: [],
            bracketFormat: BracketFormat.singleElimination,
            randomSeed: 42,
          ),
        ).called(1);
      },
    );

    test(
      'should return ValidationFailure when divisionId is empty',
      () async {
        // act
        final result = await useCase(
          ApplyRandomSeedingParams(
            divisionId: '',
            participants: tParticipants,
          ),
        );

        // assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('should fail'),
        );
        verifyNever(
          () => mockEngine.generateSeeding(
            participants: any(named: 'participants'),
            strategy: any(named: 'strategy'),
            constraints: any(named: 'constraints'),
            bracketFormat: any(named: 'bracketFormat'),
          ),
        );
      },
    );

    test(
      'should return ValidationFailure when less than 2 participants',
      () async {
        // act
        final result = await useCase(
          ApplyRandomSeedingParams(
            divisionId: 'div1',
            participants: [tParticipants.first],
          ),
        );

        // assert
        expect(result.isLeft(), isTrue);
      },
    );

    test(
      'should return ValidationFailure when participant ID is empty',
      () async {
        // act
        final result = await useCase(
          const ApplyRandomSeedingParams(
            divisionId: 'div1',
            participants: [
              SeedingParticipant(id: '', dojangName: 'A'),
              SeedingParticipant(id: 'p2', dojangName: 'B'),
            ],
          ),
        );

        // assert
        expect(result.isLeft(), isTrue);
      },
    );

    test(
      'should return ValidationFailure when duplicate IDs present',
      () async {
        // act
        final result = await useCase(
          const ApplyRandomSeedingParams(
            divisionId: 'div1',
            participants: [
              SeedingParticipant(id: 'p1', dojangName: 'A'),
              SeedingParticipant(id: 'p1', dojangName: 'B'),
            ],
          ),
        );

        // assert
        expect(result.isLeft(), isTrue);
      },
    );

    test('should return SeedingFailure when engine fails', () async {
      // arrange
      const failure = SeedingFailure(userFriendlyMessage: 'Engine error');
      when(
        () => mockEngine.generateSeeding(
          participants: any(named: 'participants'),
          strategy: any(named: 'strategy'),
          constraints: any(named: 'constraints'),
          bracketFormat: any(named: 'bracketFormat'),
          randomSeed: any(named: 'randomSeed'),
        ),
      ).thenReturn(const Left(failure));

      // act
      final result = await useCase(tParams);

      // assert
      expect(result, const Left<Failure, SeedingResult>(failure));
    });

    test(
      'should generate a secure seed when randomSeed is null',
      () async {
        // arrange
        when(
          () => mockEngine.generateSeeding(
            participants: any(named: 'participants'),
            strategy: any(named: 'strategy'),
            constraints: any(named: 'constraints'),
            bracketFormat: any(named: 'bracketFormat'),
            randomSeed: any(named: 'randomSeed'),
          ),
        ).thenReturn(const Right<Failure, SeedingResult>(tSeedingResult));

        // act — pass null randomSeed to trigger Random.secure()
        await useCase(
          ApplyRandomSeedingParams(
            divisionId: 'div1',
            participants: tParticipants,
            // randomSeed: null — intentionally omitted
          ),
        );

        // assert — engine MUST have been called with a non-null seed
        final captured = verify(
          () => mockEngine.generateSeeding(
            participants: any(named: 'participants'),
            strategy: any(named: 'strategy'),
            constraints: any(named: 'constraints'),
            bracketFormat: any(named: 'bracketFormat'),
            randomSeed: captureAny(named: 'randomSeed'),
          ),
        ).captured;

        expect(captured.single, isNotNull);
        expect(captured.single, isA<int>());
      },
    );

    test(
      'should NOT validate dojang names (differs from dojang use case)',
      () async {
        // arrange — participants with EMPTY dojangName
        final emptyDojangParticipants = [
          const SeedingParticipant(id: 'p1', dojangName: ''),
          const SeedingParticipant(id: 'p2', dojangName: ''),
        ];

        when(
          () => mockEngine.generateSeeding(
            participants: any(named: 'participants'),
            strategy: any(named: 'strategy'),
            constraints: any(named: 'constraints'),
            bracketFormat: any(named: 'bracketFormat'),
            randomSeed: any(named: 'randomSeed'),
          ),
        ).thenReturn(const Right<Failure, SeedingResult>(tSeedingResult));

        // act — empty dojangName should NOT cause validation failure
        final result = await useCase(
          ApplyRandomSeedingParams(
            divisionId: 'div1',
            participants: emptyDojangParticipants,
            randomSeed: 42,
          ),
        );

        // assert — engine IS called (no validation failure)
        expect(result.isRight(), isTrue);
        verify(
          () => mockEngine.generateSeeding(
            participants: any(named: 'participants'),
            strategy: any(named: 'strategy'),
            constraints: any(named: 'constraints'),
            bracketFormat: any(named: 'bracketFormat'),
            randomSeed: any(named: 'randomSeed'),
          ),
        ).called(1);
      },
    );
  });

  group('Reproducibility (integration)', () {
    test('same seed produces identical placements', () async {
      // Use REAL engine — not mock
      final realEngine = ConstraintSatisfyingSeedingEngine();
      final realUseCase = ApplyRandomSeedingUseCase(realEngine);

      final params = ApplyRandomSeedingParams(
        divisionId: 'div1',
        participants: tParticipants,
        randomSeed: 12345,
      );

      final result1 = await realUseCase(params);
      final result2 = await realUseCase(params);

      // fpdart ^1.1.1 getOrElse signature: (L) => R
      final placements1 =
          result1.getOrElse((_) => throw Exception('Expected Right')).placements;
      final placements2 =
          result2.getOrElse((_) => throw Exception('Expected Right')).placements;

      expect(placements1, equals(placements2));
    });

    test('different seeds produce different placements', () async {
      final realEngine = ConstraintSatisfyingSeedingEngine();
      final realUseCase = ApplyRandomSeedingUseCase(realEngine);

      // Use 8 participants to make collision near-impossible
      final manyParticipants = List.generate(
        8,
        (i) => SeedingParticipant(
          id: 'p$i',
          dojangName: 'School$i',
        ),
      );

      final result1 = await realUseCase(
        ApplyRandomSeedingParams(
          divisionId: 'div1',
          participants: manyParticipants,
          randomSeed: 111,
        ),
      );
      final result2 = await realUseCase(
        ApplyRandomSeedingParams(
          divisionId: 'div1',
          participants: manyParticipants,
          randomSeed: 222,
        ),
      );

      final p1 = result1.getOrElse((_) => throw Exception('fail'));
      final p2 = result2.getOrElse((_) => throw Exception('fail'));

      // At least one placement should differ
      final ids1 = p1.placements.map((p) => p.participantId).toList();
      final ids2 = p2.placements.map((p) => p.participantId).toList();
      expect(ids1, isNot(equals(ids2)));
    });
  });
}
