import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/dojang_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/regional_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_regional_separation_seeding_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_regional_separation_seeding_use_case.dart';
import 'package:tkd_brackets/core/error/failures.dart';

class MockSeedingEngine extends Mock implements SeedingEngine {}

void main() {
  late MockSeedingEngine mockEngine;
  late ApplyRegionalSeparationSeedingUseCase useCase;

  setUpAll(() {
    registerFallbackValue(SeedingStrategy.random);
    registerFallbackValue(BracketFormat.singleElimination);
  });

  setUp(() {
    mockEngine = MockSeedingEngine();
    useCase = ApplyRegionalSeparationSeedingUseCase(mockEngine);
  });

  group('ApplyRegionalSeparationSeedingUseCase', () {
    const divisionId = 'div1';
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

    test('should return ValidationFailure when divisionId is empty', () async {
      final params = ApplyRegionalSeparationSeedingParams(
        divisionId: '',
        participants: participants,
      );

      final result = await useCase(params);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => throw Exception('unexpected'),
      );
    });

    test(
      'should return ValidationFailure when less than 2 participants',
      () async {
        final params = ApplyRegionalSeparationSeedingParams(
          divisionId: divisionId,
          participants: [participants[0]],
        );

        final result = await useCase(params);

        expect(result.isLeft(), isTrue);
      },
    );

    test(
      'should return ValidationFailure when participant ID is empty',
      () async {
        const params = ApplyRegionalSeparationSeedingParams(
          divisionId: divisionId,
          participants: [
            SeedingParticipant(id: '', dojangName: 'Tiger'),
            SeedingParticipant(id: 'p2', dojangName: 'Dragon'),
          ],
        );

        final result = await useCase(params);

        expect(result.isLeft(), isTrue);
      },
    );

    test('should return ValidationFailure when dojang name is empty', () async {
      const params = ApplyRegionalSeparationSeedingParams(
        divisionId: divisionId,
        participants: [
          SeedingParticipant(id: 'p1', dojangName: '  '),
          SeedingParticipant(id: 'p2', dojangName: 'Dragon'),
        ],
      );

      final result = await useCase(params);

      expect(result.isLeft(), isTrue);
    });

    test(
      'should return ValidationFailure when duplicate IDs present',
      () async {
        const params = ApplyRegionalSeparationSeedingParams(
          divisionId: divisionId,
          participants: [
            SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
            SeedingParticipant(id: 'p1', dojangName: 'Dragon'),
          ],
        );

        final result = await useCase(params);

        expect(result.isLeft(), isTrue);
      },
    );

    test(
      'should call engine with correct params and both constraints by default',
      () async {
        final params = ApplyRegionalSeparationSeedingParams(
          divisionId: divisionId,
          participants: participants,
          randomSeed: 42,
        );

        const seedingResult = SeedingResult(
          placements: [],
          appliedConstraints: ['dojang_separation', 'regional_separation'],
          isFullySatisfied: true,
          randomSeed: 42,
        );

        when(
          () => mockEngine.generateSeeding(
            participants: any(named: 'participants'),
            strategy: any(named: 'strategy'),
            constraints: any(named: 'constraints'),
            bracketFormat: any(named: 'bracketFormat'),
            randomSeed: 42,
          ),
        ).thenReturn(const Right(seedingResult));

        final result = await useCase(params);

        expect(result.isRight(), isTrue);
        final captured =
            verify(
                  () => mockEngine.generateSeeding(
                    participants: participants,
                    strategy: SeedingStrategy.random,
                    constraints: captureAny(named: 'constraints'),
                    bracketFormat: BracketFormat.singleElimination,
                    randomSeed: 42,
                  ),
                ).captured.single
                as List<dynamic>;

        expect(captured, hasLength(2));
        expect(captured[0], isA<DojangSeparationConstraint>());
        expect(captured[1], isA<RegionalSeparationConstraint>());
      },
    );

    test(
      'should call engine only with regional constraint when dojang disabled',
      () async {
        final params = ApplyRegionalSeparationSeedingParams(
          divisionId: divisionId,
          participants: participants,
          enableDojangSeparation: false,
        );

        when(
          () => mockEngine.generateSeeding(
            participants: any(named: 'participants'),
            strategy: any(named: 'strategy'),
            constraints: any(named: 'constraints'),
            bracketFormat: any(named: 'bracketFormat'),
            randomSeed: any(named: 'randomSeed'),
          ),
        ).thenReturn(
          const Right(
            SeedingResult(
              placements: [],
              appliedConstraints: [],
              isFullySatisfied: true,
              randomSeed: 0,
            ),
          ),
        );

        await useCase(params);

        final captured =
            verify(
                  () => mockEngine.generateSeeding(
                    participants: participants,
                    strategy: SeedingStrategy.random,
                    constraints: captureAny(named: 'constraints'),
                    bracketFormat: BracketFormat.singleElimination,
                    randomSeed: null,
                  ),
                ).captured.single
                as List<dynamic>;

        expect(captured, hasLength(1));
        expect(captured[0], isA<RegionalSeparationConstraint>());
      },
    );

    test('should return SeedingFailure when engine fails', () async {
      final params = ApplyRegionalSeparationSeedingParams(
        divisionId: divisionId,
        participants: participants,
      );

      when(
        () => mockEngine.generateSeeding(
          participants: any(named: 'participants'),
          strategy: any(named: 'strategy'),
          constraints: any(named: 'constraints'),
          bracketFormat: any(named: 'bracketFormat'),
          randomSeed: any(named: 'randomSeed'),
        ),
      ).thenReturn(
        const Left(SeedingFailure(userFriendlyMessage: 'Engine failed')),
      );

      final result = await useCase(params);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<SeedingFailure>()),
        (_) => throw Exception('unexpected'),
      );
    });
  });
}
