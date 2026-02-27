import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/services/single_elimination_bracket_generator_service.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_single_elimination_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_single_elimination_bracket_use_case.dart';
import 'package:uuid/uuid.dart';

class MockBracketRepository extends Mock
    implements BracketRepository {}

class MockMatchRepository extends Mock
    implements MatchRepository {}

class MockGeneratorService extends Mock
    implements SingleEliminationBracketGeneratorService {}

class MockUuid extends Mock implements Uuid {}

void main() {
  late GenerateSingleEliminationBracketUseCase useCase;
  late MockBracketRepository mockBracketRepository;
  late MockMatchRepository mockMatchRepository;
  late MockGeneratorService mockGeneratorService;
  late MockUuid mockUuid;

  setUp(() {
    mockBracketRepository = MockBracketRepository();
    mockMatchRepository = MockMatchRepository();
    mockGeneratorService = MockGeneratorService();
    mockUuid = MockUuid();

    useCase = GenerateSingleEliminationBracketUseCase(
      mockGeneratorService,
      mockBracketRepository,
      mockMatchRepository,
      mockUuid,
    );

    when(() => mockUuid.v4()).thenReturn('test-uuid');

    registerFallbackValue(BracketEntity(
      id: '',
      divisionId: '',
      bracketType: BracketType.winners,
      totalRounds: 0,
      createdAtTimestamp: DateTime.now(),
      updatedAtTimestamp: DateTime.now(),
    ));

    registerFallbackValue(<MatchEntity>[]);
  });

  group('GenerateSingleEliminationBracketUseCase', () {
    const tParams = GenerateSingleEliminationBracketParams(
      divisionId: 'div-1',
      participantIds: ['p1', 'p2', 'p3', 'p4'],
    );

    final tNow = DateTime.now();

    final tBracket = BracketEntity(
      id: 'test-uuid',
      divisionId: 'div-1',
      bracketType: BracketType.winners,
      totalRounds: 2,
      createdAtTimestamp: tNow,
      updatedAtTimestamp: tNow,
    );

    final tMatches = [
      MatchEntity(
        id: 'm1',
        bracketId: 'test-uuid',
        roundNumber: 1,
        matchNumberInRound: 1,
        createdAtTimestamp: tNow,
        updatedAtTimestamp: tNow,
      ),
    ];

    final tResult = BracketGenerationResult(
      bracket: tBracket,
      matches: tMatches,
    );

    void stubSuccessful() {
      when(
        () => mockGeneratorService.generate(
          divisionId: any(named: 'divisionId'),
          participantIds: any(named: 'participantIds'),
          bracketId: any(named: 'bracketId'),
          includeThirdPlaceMatch:
              any(named: 'includeThirdPlaceMatch'),
        ),
      ).thenReturn(tResult);

      when(() => mockBracketRepository.createBracket(any()))
          .thenAnswer((_) async => Right(tBracket));

      when(() => mockMatchRepository.createMatches(any()))
          .thenAnswer((_) async => Right(tMatches));
    }

    test(
      'should return ValidationFailure for less than '
      '2 participants',
      () async {
        const invalidParams =
            GenerateSingleEliminationBracketParams(
          divisionId: 'div-1',
          participantIds: ['p1'],
        );

        final result = await useCase(invalidParams);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) =>
              expect(failure, isA<ValidationFailure>()),
          (_) => fail('Should have failed'),
        );
        verifyZeroInteractions(mockGeneratorService);
      },
    );

    test(
      'should return ValidationFailure for empty '
      'participant IDs',
      () async {
        const invalidParams =
            GenerateSingleEliminationBracketParams(
          divisionId: 'div-1',
          participantIds: ['p1', '', 'p3'],
        );

        final result = await useCase(invalidParams);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) =>
              expect(failure, isA<ValidationFailure>()),
          (_) => fail('Should have failed'),
        );
        verifyZeroInteractions(mockGeneratorService);
      },
    );

    test(
      'should return ValidationFailure for whitespace-only '
      'participant IDs',
      () async {
        const invalidParams =
            GenerateSingleEliminationBracketParams(
          divisionId: 'div-1',
          participantIds: ['p1', '   ', 'p3'],
        );

        final result = await useCase(invalidParams);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) =>
              expect(failure, isA<ValidationFailure>()),
          (_) => fail('Should have failed'),
        );
      },
    );

    test(
      'should generate and persist bracket and matches '
      'successfully',
      () async {
        stubSuccessful();

        final result = await useCase(tParams);

        expect(result.isRight(), isTrue);
        result.fold(
          (l) => fail('Should be right'),
          (r) {
            expect(r.bracket, tBracket);
            expect(r.matches, tMatches);
          },
        );
        verify(
          () => mockGeneratorService.generate(
            divisionId: 'div-1',
            participantIds: tParams.participantIds,
            bracketId: 'test-uuid',
            includeThirdPlaceMatch: false,
          ),
        ).called(1);
        verify(
          () => mockBracketRepository.createBracket(any()),
        ).called(1);
        verify(
          () => mockMatchRepository.createMatches(tMatches),
        ).called(1);
      },
    );

    test(
      'should return failure when bracket creation fails',
      () async {
        stubSuccessful();
        when(
          () => mockBracketRepository.createBracket(any()),
        ).thenAnswer(
          (_) async =>
              const Left(LocalCacheWriteFailure()),
        );

        final result = await useCase(tParams);

        expect(
          result,
          const Left<Failure, BracketGenerationResult>(LocalCacheWriteFailure()),
        );
        verifyNever(
          () => mockMatchRepository.createMatches(any()),
        );
      },
    );

    test(
      'should return failure when match creation fails',
      () async {
        stubSuccessful();
        when(
          () => mockMatchRepository.createMatches(any()),
        ).thenAnswer(
          (_) async =>
              const Left(LocalCacheWriteFailure()),
        );

        final result = await useCase(tParams);

        expect(
          result,
          const Left<Failure, BracketGenerationResult>(LocalCacheWriteFailure()),
        );
        verify(
          () => mockBracketRepository.createBracket(any()),
        ).called(1);
      },
    );
  });
}
