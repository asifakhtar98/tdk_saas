import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/hybrid_bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/services/hybrid_bracket_generator_service.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_pool_play_elimination_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_pool_play_elimination_bracket_use_case.dart';
import 'package:uuid/uuid.dart';

class MockBracketRepository extends Mock implements BracketRepository {}
class MockMatchRepository extends Mock implements MatchRepository {}
class MockHybridGeneratorService extends Mock implements HybridBracketGeneratorService {}
class MockUuid extends Mock implements Uuid {}

void main() {
  late GeneratePoolPlayEliminationBracketUseCase useCase;
  late MockBracketRepository mockBracketRepository;
  late MockMatchRepository mockMatchRepository;
  late MockHybridGeneratorService mockGeneratorService;
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
    mockGeneratorService = MockHybridGeneratorService();
    mockUuid = MockUuid();

    useCase = GeneratePoolPlayEliminationBracketUseCase(
      mockGeneratorService,
      mockBracketRepository,
      mockMatchRepository,
      mockUuid,
    );

    var uuidCounter = 0;
    when(() => mockUuid.v4()).thenAnswer((_) => 'uuid-${uuidCounter++}');
  });

  const divisionId = 'div-1';
  const participantIds = ['p1', 'p2', 'p3', 'p4'];

  HybridBracketGenerationResult makeTestResult() {
    final now = DateTime.now();
    final poolA = BracketGenerationResult(
      bracket: BracketEntity(
        id: 'pool-a',
        divisionId: divisionId,
        bracketType: BracketType.pool,
        totalRounds: 1,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
      ),
      matches: const [],
    );
    final poolB = BracketGenerationResult(
      bracket: BracketEntity(
        id: 'pool-b',
        divisionId: divisionId,
        bracketType: BracketType.pool,
        totalRounds: 1,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
      ),
      matches: const [],
    );
    final elim = BracketGenerationResult(
      bracket: BracketEntity(
        id: 'elim',
        divisionId: divisionId,
        bracketType: BracketType.winners,
        totalRounds: 1,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
      ),
      matches: const [],
    );
    return HybridBracketGenerationResult(
      poolBrackets: [poolA, poolB],
      eliminationBracket: elim,
      allMatches: const [],
    );
  }

  void stubSuccessful(HybridBracketGenerationResult result) {
    when(() => mockGeneratorService.generate(
      divisionId: any(named: 'divisionId'),
      participantIds: any(named: 'participantIds'),
      eliminationBracketId: any(named: 'eliminationBracketId'),
      poolBracketIds: any(named: 'poolBracketIds'),
      numberOfPools: any(named: 'numberOfPools'),
      qualifiersPerPool: any(named: 'qualifiersPerPool'),
    )).thenReturn(result);

    when(() => mockBracketRepository.createBracket(any()))
      .thenAnswer((invocation) async => Right<Failure, BracketEntity>(
        invocation.positionalArguments.first as BracketEntity,
      ));

    when(() => mockMatchRepository.createMatches(any()))
      .thenAnswer((_) async => const Right<Failure, List<MatchEntity>>([]));
  }

  test('should return ValidationFailure when less than 3 participants', () async {
    final result = await useCase(const GeneratePoolPlayEliminationBracketParams(
      divisionId: divisionId,
      participantIds: ['p1', 'p2'],
    ));

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<ValidationFailure>()),
      (_) => fail('Should have failed'),
    );
  });

  test('should return ValidationFailure when empty participant ID', () async {
    final result = await useCase(const GeneratePoolPlayEliminationBracketParams(
      divisionId: divisionId,
      participantIds: ['p1', '', 'p3'],
    ));

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<ValidationFailure>()),
      (_) => fail('Should have failed'),
    );
  });

  test('should return ValidationFailure when duplicate participant IDs detected', () async {
    final result = await useCase(const GeneratePoolPlayEliminationBracketParams(
      divisionId: divisionId,
      participantIds: ['p1', 'p2', 'p1'],
    ));

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<ValidationFailure>()),
      (_) => fail('Should have failed'),
    );
  });

  test('should return ValidationFailure when qualifiers exceed participants', () async {
      final result = await useCase(const GeneratePoolPlayEliminationBracketParams(
          divisionId: divisionId,
          participantIds: ['p1', 'p2', 'p3', 'p4'],
          numberOfPools: 2,
          qualifiersPerPool: 3, // Total 6 > 4 participants
      ));

      expect(result.isLeft(), isTrue);
      result.fold(
              (failure) => expect(failure, isA<ValidationFailure>()),
              (_) => fail('Should have failed'),
      );
  });

  test('should generate and persist all brackets and matches on success', () async {
    final testResult = makeTestResult();
    stubSuccessful(testResult);

    final result = await useCase(const GeneratePoolPlayEliminationBracketParams(
      divisionId: divisionId,
      participantIds: participantIds,
      numberOfPools: 2,
      qualifiersPerPool: 2,
    ));

    expect(result.isRight(), isTrue);
    verify(() => mockBracketRepository.createBracket(any())).called(3); // 2 pools + 1 elim
    verify(() => mockMatchRepository.createMatches(any())).called(1);
  });

  test('should return failure if pool bracket persistence fails', () async {
    final testResult = makeTestResult();
    stubSuccessful(testResult);
    when(() => mockBracketRepository.createBracket(any()))
      .thenAnswer((_) async => const Left(LocalCacheWriteFailure()));

    final result = await useCase(const GeneratePoolPlayEliminationBracketParams(
      divisionId: divisionId,
      participantIds: participantIds,
    ));

    expect(result.isLeft(), isTrue);
    verifyZeroInteractions(mockMatchRepository);
  });

  test('should return failure if elimination bracket persistence fails', () async {
    final testResult = makeTestResult();
    stubSuccessful(testResult);

    var callCount = 0;
    when(() => mockBracketRepository.createBracket(any()))
      .thenAnswer((invocation) async {
        callCount++;
        // First 2 calls (pool brackets) succeed, 3rd (elimination) fails
        if (callCount <= 2) {
          return Right<Failure, BracketEntity>(
            invocation.positionalArguments.first as BracketEntity,
          );
        }
        return const Left(LocalCacheWriteFailure());
      });

    final result = await useCase(const GeneratePoolPlayEliminationBracketParams(
      divisionId: divisionId,
      participantIds: participantIds,
    ));

    expect(result.isLeft(), isTrue);
    verifyNever(() => mockMatchRepository.createMatches(any()));
  });

  test('should return failure if match persistence fails', () async {
    final testResult = makeTestResult();
    stubSuccessful(testResult);
    when(() => mockMatchRepository.createMatches(any()))
      .thenAnswer((_) async => const Left(LocalCacheWriteFailure()));

    final result = await useCase(const GeneratePoolPlayEliminationBracketParams(
      divisionId: divisionId,
      participantIds: participantIds,
    ));

    expect(result.isLeft(), isTrue);
  });
}
