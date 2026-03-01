import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_dojang_separation_seeding_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_dojang_separation_seeding_use_case.dart';
import 'package:tkd_brackets/core/error/failures.dart';

class MockSeedingEngine extends Mock implements SeedingEngine {}

void main() {
  late MockSeedingEngine mockEngine;
  late ApplyDojangSeparationSeedingUseCase useCase;

  setUpAll(() {
    registerFallbackValue(BracketFormat.singleElimination);
    registerFallbackValue(SeedingStrategy.random);
  });

  setUp(() {
    mockEngine = MockSeedingEngine();
    useCase = ApplyDojangSeparationSeedingUseCase(mockEngine);
  });

  final tParticipants = [
    const SeedingParticipant(id: 'p1', dojangName: 'A'),
    const SeedingParticipant(id: 'p2', dojangName: 'B'),
  ];

  final tParams = ApplyDojangSeparationSeedingParams(
    divisionId: 'div1',
    participants: tParticipants,
    randomSeed: 42,
  );

  const tSeedingResult = SeedingResult(
    placements: [],
    appliedConstraints: ['dojang_separation'],
    randomSeed: 42,
  );

  group('ApplyDojangSeparationSeedingUseCase', () {
    test(
      'should call engine with correct params when validation passes',
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
            strategy: any(named: 'strategy'),
            constraints: any(named: 'constraints'),
            bracketFormat: BracketFormat.singleElimination,
            randomSeed: 42,
          ),
        ).called(1);
      },
    );

    test('should return ValidationFailure when divisionId is empty', () async {
      // act
      final result = await useCase(
        ApplyDojangSeparationSeedingParams(
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
    });

    test(
      'should return ValidationFailure when less than 2 participants',
      () async {
        // act
        final result = await useCase(
          ApplyDojangSeparationSeedingParams(
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
          const ApplyDojangSeparationSeedingParams(
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

    test('should return ValidationFailure when dojang name is empty', () async {
      // act
      final result = await useCase(
        const ApplyDojangSeparationSeedingParams(
          divisionId: 'div1',
          participants: [
            SeedingParticipant(id: 'p1', dojangName: ''),
            SeedingParticipant(id: 'p2', dojangName: 'B'),
          ],
        ),
      );

      // assert
      expect(result.isLeft(), isTrue);
      verifyNever(
        () => mockEngine.generateSeeding(
          participants: any(named: 'participants'),
          strategy: any(named: 'strategy'),
          constraints: any(named: 'constraints'),
          bracketFormat: any(named: 'bracketFormat'),
        ),
      );
    });

    test(
      'should return ValidationFailure when duplicate IDs present',
      () async {
        // act
        final result = await useCase(
          const ApplyDojangSeparationSeedingParams(
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
  });
}
