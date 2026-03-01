import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/double_elimination_bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/services/double_elimination_bracket_generator_service.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_use_case.dart';
import 'package:uuid/uuid.dart';

class MockBracketRepository extends Mock implements BracketRepository {}

class MockMatchRepository extends Mock implements MatchRepository {}

class MockGeneratorService extends Mock
    implements DoubleEliminationBracketGeneratorService {}

class MockUuid extends Mock implements Uuid {}

void main() {
  late GenerateDoubleEliminationBracketUseCase useCase;
  late MockBracketRepository mockBracketRepository;
  late MockMatchRepository mockMatchRepository;
  late MockGeneratorService mockGeneratorService;
  late MockUuid mockUuid;

  setUp(() {
    mockBracketRepository = MockBracketRepository();
    mockMatchRepository = MockMatchRepository();
    mockGeneratorService = MockGeneratorService();
    mockUuid = MockUuid();

    useCase = GenerateDoubleEliminationBracketUseCase(
      mockGeneratorService,
      mockBracketRepository,
      mockMatchRepository,
      mockUuid,
    );

    when(() => mockUuid.v4()).thenReturn('test-uuid');

    registerFallbackValue(
      BracketEntity(
        id: '',
        divisionId: '',
        bracketType: BracketType.winners,
        totalRounds: 0,
        createdAtTimestamp: DateTime.now(),
        updatedAtTimestamp: DateTime.now(),
      ),
    );

    registerFallbackValue(<MatchEntity>[]);
  });

  group('GenerateDoubleEliminationBracketUseCase', () {
    const tParams = GenerateDoubleEliminationBracketParams(
      divisionId: 'div-1',
      participantIds: ['p1', 'p2', 'p3', 'p4'],
    );

    final tNow = DateTime.now();

    final tWinnersBracket = BracketEntity(
      id: 'test-uuid-w',
      divisionId: 'div-1',
      bracketType: BracketType.winners,
      totalRounds: 2,
      createdAtTimestamp: tNow,
      updatedAtTimestamp: tNow,
    );

    final tLosersBracket = BracketEntity(
      id: 'test-uuid-l',
      divisionId: 'div-1',
      bracketType: BracketType.losers,
      totalRounds: 2,
      createdAtTimestamp: tNow,
      updatedAtTimestamp: tNow,
    );

    final tGrandFinals = MatchEntity(
      id: 'gf',
      bracketId: 'test-uuid-w',
      roundNumber: 3,
      matchNumberInRound: 1,
      createdAtTimestamp: tNow,
      updatedAtTimestamp: tNow,
    );

    final tMatches = [
      MatchEntity(
        id: 'm1',
        bracketId: 'test-uuid-w',
        roundNumber: 1,
        matchNumberInRound: 1,
        createdAtTimestamp: tNow,
        updatedAtTimestamp: tNow,
      ),
    ];

    final tResult = DoubleEliminationBracketGenerationResult(
      winnersBracket: tWinnersBracket,
      losersBracket: tLosersBracket,
      grandFinalsMatch: tGrandFinals,
      allMatches: tMatches,
    );

    void stubSuccessful() {
      when(
        () => mockGeneratorService.generate(
          divisionId: any(named: 'divisionId'),
          participantIds: any(named: 'participantIds'),
          winnersBracketId: any(named: 'winnersBracketId'),
          losersBracketId: any(named: 'losersBracketId'),
          includeResetMatch: any(named: 'includeResetMatch'),
        ),
      ).thenReturn(tResult);

      when(
        () => mockBracketRepository.createBracket(any()),
      ).thenAnswer((_) async => Right(tWinnersBracket));

      when(
        () => mockMatchRepository.createMatches(any()),
      ).thenAnswer((_) async => Right(tMatches));
    }

    test(
      'should return ValidationFailure for less than 2 participants',
      () async {
        const invalidParams = GenerateDoubleEliminationBracketParams(
          divisionId: 'div-1',
          participantIds: ['p1'],
        );

        final result = await useCase(invalidParams);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Should have failed'),
        );
        verifyZeroInteractions(mockGeneratorService);
      },
    );

    test('should return ValidationFailure for empty participant IDs', () async {
      const invalidParams = GenerateDoubleEliminationBracketParams(
        divisionId: 'div-1',
        participantIds: ['p1', '', 'p3'],
      );

      final result = await useCase(invalidParams);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should have failed'),
      );
      verifyZeroInteractions(mockGeneratorService);
    });

    test(
      'should generate and persist brackets and matches successfully',
      () async {
        stubSuccessful();

        final result = await useCase(tParams);

        expect(result.isRight(), isTrue);
        result.fold((l) => fail('Should be right'), (r) {
          expect(r, tResult);
        });
        verify(
          () => mockGeneratorService.generate(
            divisionId: 'div-1',
            participantIds: tParams.participantIds,
            winnersBracketId: any(named: 'winnersBracketId'),
            losersBracketId: any(named: 'losersBracketId'),
            includeResetMatch: true,
          ),
        ).called(1);
        verify(() => mockBracketRepository.createBracket(any())).called(2);
        verify(() => mockMatchRepository.createMatches(tMatches)).called(1);
      },
    );

    test('should return failure when first bracket creation fails', () async {
      stubSuccessful();
      when(
        () => mockBracketRepository.createBracket(any()),
      ).thenAnswer((_) async => const Left(LocalCacheWriteFailure()));

      final result = await useCase(tParams);

      expect(
        result,
        const Left<Failure, DoubleEliminationBracketGenerationResult>(
          LocalCacheWriteFailure(),
        ),
      );
      verify(() => mockBracketRepository.createBracket(any())).called(1);
      verifyNever(() => mockMatchRepository.createMatches(any()));
    });

    test('should return failure when second bracket creation fails', () async {
      stubSuccessful();
      // Succeed first call, fail second
      var callCount = 0;
      when(() => mockBracketRepository.createBracket(any())).thenAnswer((
        _,
      ) async {
        callCount++;
        if (callCount == 1) return Right(tWinnersBracket);
        return const Left(LocalCacheWriteFailure());
      });

      final result = await useCase(tParams);

      expect(
        result,
        const Left<Failure, DoubleEliminationBracketGenerationResult>(
          LocalCacheWriteFailure(),
        ),
      );
      verify(() => mockBracketRepository.createBracket(any())).called(2);
      verifyNever(() => mockMatchRepository.createMatches(any()));
    });

    test('should return failure when match creation fails', () async {
      stubSuccessful();
      when(
        () => mockMatchRepository.createMatches(any()),
      ).thenAnswer((_) async => const Left(LocalCacheWriteFailure()));

      final result = await useCase(tParams);

      expect(
        result,
        const Left<Failure, DoubleEliminationBracketGenerationResult>(
          LocalCacheWriteFailure(),
        ),
      );
      verify(() => mockBracketRepository.createBracket(any())).called(2);
      verify(() => mockMatchRepository.createMatches(any())).called(1);
    });
  });
}
