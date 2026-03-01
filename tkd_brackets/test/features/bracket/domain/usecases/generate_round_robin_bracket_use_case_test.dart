import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/services/round_robin_bracket_generator_service.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_round_robin_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_round_robin_bracket_use_case.dart';
import 'package:uuid/uuid.dart';

class MockBracketRepository extends Mock implements BracketRepository {}

class MockMatchRepository extends Mock implements MatchRepository {}

class MockGeneratorService extends Mock
    implements RoundRobinBracketGeneratorService {}

class MockUuid extends Mock implements Uuid {}

void main() {
  late GenerateRoundRobinBracketUseCase useCase;
  late MockBracketRepository mockBracketRepository;
  late MockMatchRepository mockMatchRepository;
  late MockGeneratorService mockGeneratorService;
  late MockUuid mockUuid;

  setUpAll(() {
    registerFallbackValue(
      BracketEntity(
        id: '',
        divisionId: '',
        bracketType: BracketType.pool,
        totalRounds: 0,
        createdAtTimestamp: DateTime.now(),
        updatedAtTimestamp: DateTime.now(),
      ),
    );
    registerFallbackValue(<MatchEntity>[]);
  });

  setUp(() {
    mockBracketRepository = MockBracketRepository();
    mockMatchRepository = MockMatchRepository();
    mockGeneratorService = MockGeneratorService();
    mockUuid = MockUuid();

    useCase = GenerateRoundRobinBracketUseCase(
      mockGeneratorService,
      mockBracketRepository,
      mockMatchRepository,
      mockUuid,
    );

    when(() => mockUuid.v4()).thenReturn('test-uuid');
  });

  group('GenerateRoundRobinBracketUseCase', () {
    const tParams = GenerateRoundRobinBracketParams(
      divisionId: 'div-1',
      participantIds: ['p1', 'p2', 'p3', 'p4'],
    );

    final tNow = DateTime.now();

    final tBracket = BracketEntity(
      id: 'test-uuid',
      divisionId: 'div-1',
      bracketType: BracketType.pool,
      totalRounds: 3,
      poolIdentifier: 'A',
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
          poolIdentifier: any(named: 'poolIdentifier'),
        ),
      ).thenReturn(tResult);

      when(
        () => mockBracketRepository.createBracket(any()),
      ).thenAnswer((_) async => Right<Failure, BracketEntity>(tBracket));

      when(
        () => mockMatchRepository.createMatches(any()),
      ).thenAnswer((_) async => Right<Failure, List<MatchEntity>>(tMatches));
    }

    test(
      'should return ValidationFailure when participant count < 2',
      () async {
        const params = GenerateRoundRobinBracketParams(
          divisionId: 'div-1',
          participantIds: ['p1'],
        );

        final result = await useCase(params);

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          final vf = failure as ValidationFailure;
          expect(vf.userFriendlyMessage, contains('At least 2 participants'));
        }, (_) => fail('Should have returned Left'));
      },
    );

    test('should return ValidationFailure for empty participant IDs', () async {
      const params = GenerateRoundRobinBracketParams(
        divisionId: 'div-1',
        participantIds: ['p1', '', 'p3'],
      );

      final result = await useCase(params);

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        final vf = failure as ValidationFailure;
        expect(vf.userFriendlyMessage, contains('contains empty IDs'));
      }, (_) => fail('Should have returned Left'));
    });

    test(
      'should return ValidationFailure for whitespace-only participant IDs',
      () async {
        const params = GenerateRoundRobinBracketParams(
          divisionId: 'div-1',
          participantIds: ['p1', '   ', 'p3'],
        );

        final result = await useCase(params);

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          final vf = failure as ValidationFailure;
          expect(vf.userFriendlyMessage, contains('contains empty IDs'));
        }, (_) => fail('Should have returned Left'));
      },
    );

    test(
      'should call service, repository, and return result on success',
      () async {
        stubSuccessful();

        final result = await useCase(tParams);

        expect(result, Right<Failure, BracketGenerationResult>(tResult));

        verify(
          () => mockGeneratorService.generate(
            divisionId: tParams.divisionId,
            participantIds: tParams.participantIds,
            bracketId: 'test-uuid',
            poolIdentifier: tParams.poolIdentifier,
          ),
        ).called(1);

        verify(() => mockBracketRepository.createBracket(tBracket)).called(1);
        verify(() => mockMatchRepository.createMatches(tMatches)).called(1);
      },
    );

    test('should propagate failure and stop if createBracket fails', () async {
      when(
        () => mockGeneratorService.generate(
          divisionId: any(named: 'divisionId'),
          participantIds: any(named: 'participantIds'),
          bracketId: any(named: 'bracketId'),
          poolIdentifier: any(named: 'poolIdentifier'),
        ),
      ).thenReturn(tResult);

      const tFailure = LocalCacheWriteFailure();
      when(
        () => mockBracketRepository.createBracket(any()),
      ).thenAnswer((_) async => const Left<Failure, BracketEntity>(tFailure));

      final result = await useCase(tParams);

      expect(result, const Left<Failure, BracketGenerationResult>(tFailure));
      verify(() => mockBracketRepository.createBracket(any())).called(1);
      verifyZeroInteractions(mockMatchRepository);
    });

    test('should propagate failure if createMatches fails', () async {
      when(
        () => mockGeneratorService.generate(
          divisionId: any(named: 'divisionId'),
          participantIds: any(named: 'participantIds'),
          bracketId: any(named: 'bracketId'),
          poolIdentifier: any(named: 'poolIdentifier'),
        ),
      ).thenReturn(tResult);

      when(
        () => mockBracketRepository.createBracket(any()),
      ).thenAnswer((_) async => Right<Failure, BracketEntity>(tBracket));

      const tFailure = LocalCacheWriteFailure();
      when(() => mockMatchRepository.createMatches(any())).thenAnswer(
        (_) async => const Left<Failure, List<MatchEntity>>(tFailure),
      );

      final result = await useCase(tParams);

      expect(result, const Left<Failure, BracketGenerationResult>(tFailure));
      verify(() => mockBracketRepository.createBracket(any())).called(1);
      verify(() => mockMatchRepository.createMatches(any())).called(1);
    });
  });
}
