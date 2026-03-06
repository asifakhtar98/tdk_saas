import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/double_elimination_bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/hybrid_bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';

import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_round_robin_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_round_robin_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_single_elimination_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_single_elimination_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_pool_play_elimination_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_pool_play_elimination_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/regenerate_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/regenerate_bracket_use_case.dart';

class MockBracketRepository extends Mock implements BracketRepository {}

class MockMatchRepository extends Mock implements MatchRepository {}

class MockGenerateSingleEliminationBracketUseCase extends Mock
    implements GenerateSingleEliminationBracketUseCase {}

class MockGenerateDoubleEliminationBracketUseCase extends Mock
    implements GenerateDoubleEliminationBracketUseCase {}

class MockGenerateRoundRobinBracketUseCase extends Mock
    implements GenerateRoundRobinBracketUseCase {}

class MockGeneratePoolPlayEliminationBracketUseCase extends Mock
    implements GeneratePoolPlayEliminationBracketUseCase {}

void main() {
  late MockBracketRepository mockBracketRepo;
  late MockMatchRepository mockMatchRepo;
  late MockGenerateSingleEliminationBracketUseCase mockSingleElimUC;
  late MockGenerateDoubleEliminationBracketUseCase mockDoubleElimUC;
  late MockGenerateRoundRobinBracketUseCase mockRoundRobinUC;
  late MockGeneratePoolPlayEliminationBracketUseCase mockPoolPlayUC;
  late RegenerateBracketUseCase useCase;

  setUpAll(() {
    // ⚠️ MUST register fallback values for ALL params types used with any()
    registerFallbackValue(
      const RegenerateBracketParams(
        divisionId: 'div1',
        participantIds: ['p1', 'p2'],
      ),
    );
    registerFallbackValue(
      const GenerateSingleEliminationBracketParams(
        divisionId: 'div1',
        participantIds: ['p1', 'p2'],
      ),
    );
    registerFallbackValue(
      const GenerateDoubleEliminationBracketParams(
        divisionId: 'div1',
        participantIds: ['p1', 'p2'],
      ),
    );
    registerFallbackValue(
      const GenerateRoundRobinBracketParams(
        divisionId: 'div1',
        participantIds: ['p1', 'p2'],
      ),
    );
    registerFallbackValue(
      const GeneratePoolPlayEliminationBracketParams(
        divisionId: 'div1',
        participantIds: ['p1', 'p2'],
      ),
    );
  });

  setUp(() {
    mockBracketRepo = MockBracketRepository();
    mockMatchRepo = MockMatchRepository();
    mockSingleElimUC = MockGenerateSingleEliminationBracketUseCase();
    mockDoubleElimUC = MockGenerateDoubleEliminationBracketUseCase();
    mockRoundRobinUC = MockGenerateRoundRobinBracketUseCase();
    mockPoolPlayUC = MockGeneratePoolPlayEliminationBracketUseCase();
    useCase = RegenerateBracketUseCase(
      mockBracketRepo,
      mockMatchRepo,
      mockSingleElimUC,
      mockDoubleElimUC,
      mockRoundRobinUC,
      mockPoolPlayUC,
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers — match existing entity constructors exactly
  // ─────────────────────────────────────────────────────────────────────────

  BracketEntity makeBracket({
    String id = 'bracket-1',
    bool isFinalized = false,
  }) => BracketEntity(
    id: id,
    divisionId: 'div1',
    bracketType: BracketType.winners,
    totalRounds: 3,
    createdAtTimestamp: DateTime(2026),
    updatedAtTimestamp: DateTime(2026),
    isFinalized: isFinalized,
  );

  MatchEntity makeMatch({
    String id = 'match-1',
    String bracketId = 'bracket-1',
  }) => MatchEntity(
    id: id,
    bracketId: bracketId,
    roundNumber: 1,
    matchNumberInRound: 1,
    createdAtTimestamp: DateTime(2026),
    updatedAtTimestamp: DateTime(2026),
  );

  const validParams = RegenerateBracketParams(
    divisionId: 'div1',
    participantIds: ['p1', 'p2', 'p3'],
  );

  // ═══════════════════════════════════════════════════════════════════════
  // 1. Validation (no repository or generator calls)
  // ═══════════════════════════════════════════════════════════════════════

  group('Validation (no repository or generator calls)', () {
    test('empty divisionId → ValidationFailure', () async {
      final result = await useCase(
        const RegenerateBracketParams(
          divisionId: '',
          participantIds: ['p1', 'p2'],
        ),
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.getBracketsForDivision(any()));
    });

    test('whitespace-only divisionId → ValidationFailure', () async {
      final result = await useCase(
        const RegenerateBracketParams(
          divisionId: '   ',
          participantIds: ['p1', 'p2'],
        ),
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.getBracketsForDivision(any()));
    });

    test('< 2 participants → ValidationFailure', () async {
      final result = await useCase(
        const RegenerateBracketParams(
          divisionId: 'div1',
          participantIds: ['p1'],
        ),
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.getBracketsForDivision(any()));
    });

    test('zero participants → ValidationFailure', () async {
      final result = await useCase(
        const RegenerateBracketParams(divisionId: 'div1', participantIds: []),
      );
      expect(result.isLeft(), isTrue);
      verifyNever(() => mockBracketRepo.getBracketsForDivision(any()));
    });

    test('empty participant ID → ValidationFailure', () async {
      final result = await useCase(
        const RegenerateBracketParams(
          divisionId: 'div1',
          participantIds: ['p1', ''],
        ),
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.getBracketsForDivision(any()));
    });

    test('whitespace-only participant ID → ValidationFailure', () async {
      final result = await useCase(
        const RegenerateBracketParams(
          divisionId: 'div1',
          participantIds: ['p1', '   ', 'p3'],
        ),
      );
      expect(result.isLeft(), isTrue);
      verifyNever(() => mockBracketRepo.getBracketsForDivision(any()));
    });

    test('duplicate participant IDs → ValidationFailure', () async {
      final result = await useCase(
        const RegenerateBracketParams(
          divisionId: 'div1',
          participantIds: ['p1', 'p1'],
        ),
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.getBracketsForDivision(any()));
    });

    test(
      'validation order: empty divisionId checked before participants',
      () async {
        // Both divisionId and participantIds are invalid
        final result = await useCase(
          const RegenerateBracketParams(divisionId: '', participantIds: ['p1']),
        );
        expect(result.isLeft(), isTrue);
        result.fold((f) {
          expect(f, isA<ValidationFailure>());
          expect(f.userFriendlyMessage, contains('Division ID'));
        }, (_) => fail('Should have failed'));
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 2. Finalized bracket blocking
  // ═══════════════════════════════════════════════════════════════════════

  group('Finalized bracket blocking', () {
    test(
      'single finalized bracket → ValidationFailure with "finalized"',
      () async {
        when(
          () => mockBracketRepo.getBracketsForDivision('div1'),
        ).thenAnswer((_) async => Right([makeBracket(isFinalized: true)]));

        final result = await useCase(validParams);
        expect(result.isLeft(), isTrue);
        result.fold((f) {
          expect(f, isA<ValidationFailure>());
          expect(f.userFriendlyMessage, contains('finalized'));
        }, (_) => fail('Should have failed'));
        // Should NOT attempt to delete anything
        verifyNever(() => mockMatchRepo.getMatchesForBracket(any()));
        verifyNever(() => mockMatchRepo.deleteMatch(any()));
        verifyNever(() => mockBracketRepo.deleteBracket(any()));
      },
    );

    test('one finalized among multiple → blocks ALL regeneration', () async {
      when(() => mockBracketRepo.getBracketsForDivision('div1')).thenAnswer(
        (_) async => Right([
          makeBracket(id: 'b1', isFinalized: false),
          makeBracket(id: 'b2', isFinalized: true),
        ]),
      );

      final result = await useCase(validParams);
      expect(result.isLeft(), isTrue);
      verifyNever(() => mockMatchRepo.deleteMatch(any()));
    });

    test(
      'non-finalized bracket → proceeds to cleanup and regeneration',
      () async {
        final bracket = makeBracket();
        final match = makeMatch();

        when(
          () => mockBracketRepo.getBracketsForDivision('div1'),
        ).thenAnswer((_) async => Right([bracket]));
        when(
          () => mockMatchRepo.getMatchesForBracket('bracket-1'),
        ).thenAnswer((_) async => Right([match]));
        when(
          () => mockMatchRepo.deleteMatch('match-1'),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => mockBracketRepo.deleteBracket('bracket-1'),
        ).thenAnswer((_) async => const Right(unit));
        when(() => mockSingleElimUC(any())).thenAnswer(
          (_) async => Right(
            BracketGenerationResult(bracket: bracket, matches: [match]),
          ),
        );

        final result = await useCase(validParams);
        expect(result.isRight(), isTrue);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 3. Soft-delete and regeneration
  // ═══════════════════════════════════════════════════════════════════════

  group('Soft-delete and regeneration', () {
    test('deletes all matches and brackets, returns correct counts', () async {
      final bracket = makeBracket();
      final match1 = makeMatch(id: 'm1');
      final match2 = makeMatch(id: 'm2');

      when(
        () => mockBracketRepo.getBracketsForDivision('div1'),
      ).thenAnswer((_) async => Right([bracket]));
      when(
        () => mockMatchRepo.getMatchesForBracket('bracket-1'),
      ).thenAnswer((_) async => Right([match1, match2]));
      when(
        () => mockMatchRepo.deleteMatch(any()),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => mockBracketRepo.deleteBracket('bracket-1'),
      ).thenAnswer((_) async => const Right(unit));
      when(() => mockSingleElimUC(any())).thenAnswer(
        (_) async =>
            Right(BracketGenerationResult(bracket: bracket, matches: [match1])),
      );

      final result = await useCase(validParams);
      expect(result.isRight(), isTrue);

      result.fold((_) => fail('Should be right'), (r) {
        expect(r.deletedBracketCount, equals(1));
        expect(r.deletedMatchCount, equals(2));
        expect(r.generationResult, isA<BracketGenerationResult>());
      });

      // Verify all individual delete calls were made
      verify(() => mockMatchRepo.deleteMatch('m1')).called(1);
      verify(() => mockMatchRepo.deleteMatch('m2')).called(1);
      verify(() => mockBracketRepo.deleteBracket('bracket-1')).called(1);
    });

    test(
      'multiple brackets (e.g., double elim winners+losers) → deletes all',
      () async {
        final b1 = makeBracket(id: 'winners-bracket');
        final b2 = makeBracket(id: 'losers-bracket');
        final m1 = makeMatch(id: 'w-m1', bracketId: 'winners-bracket');
        final m2 = makeMatch(id: 'l-m1', bracketId: 'losers-bracket');
        final m3 = makeMatch(id: 'l-m2', bracketId: 'losers-bracket');

        when(
          () => mockBracketRepo.getBracketsForDivision('div1'),
        ).thenAnswer((_) async => Right([b1, b2]));
        when(
          () => mockMatchRepo.getMatchesForBracket('winners-bracket'),
        ).thenAnswer((_) async => Right([m1]));
        when(
          () => mockMatchRepo.getMatchesForBracket('losers-bracket'),
        ).thenAnswer((_) async => Right([m2, m3]));
        when(
          () => mockMatchRepo.deleteMatch(any()),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => mockBracketRepo.deleteBracket(any()),
        ).thenAnswer((_) async => const Right(unit));
        when(() => mockSingleElimUC(any())).thenAnswer(
          (_) async =>
              Right(BracketGenerationResult(bracket: b1, matches: const [])),
        );

        final result = await useCase(validParams);
        expect(result.isRight(), isTrue);

        result.fold((_) => fail('Should be right'), (r) {
          expect(r.deletedBracketCount, equals(2));
          expect(r.deletedMatchCount, equals(3));
        });

        verify(
          () => mockBracketRepo.deleteBracket('winners-bracket'),
        ).called(1);
        verify(() => mockBracketRepo.deleteBracket('losers-bracket')).called(1);
      },
    );

    test('no existing brackets → generates fresh (count 0)', () async {
      final bracket = makeBracket();

      when(
        () => mockBracketRepo.getBracketsForDivision('div1'),
      ).thenAnswer((_) async => const Right([]));
      when(() => mockSingleElimUC(any())).thenAnswer(
        (_) async =>
            Right(BracketGenerationResult(bracket: bracket, matches: const [])),
      );

      final result = await useCase(validParams);
      expect(result.isRight(), isTrue);

      result.fold((_) => fail('Should be right'), (r) {
        expect(r.deletedBracketCount, equals(0));
        expect(r.deletedMatchCount, equals(0));
      });

      // Should never call delete methods
      verifyNever(() => mockMatchRepo.getMatchesForBracket(any()));
      verifyNever(() => mockMatchRepo.deleteMatch(any()));
      verifyNever(() => mockBracketRepo.deleteBracket(any()));
    });

    test('bracket with zero matches → deletes bracket only', () async {
      final bracket = makeBracket();

      when(
        () => mockBracketRepo.getBracketsForDivision('div1'),
      ).thenAnswer((_) async => Right([bracket]));
      when(
        () => mockMatchRepo.getMatchesForBracket('bracket-1'),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockBracketRepo.deleteBracket('bracket-1'),
      ).thenAnswer((_) async => const Right(unit));
      when(() => mockSingleElimUC(any())).thenAnswer(
        (_) async =>
            Right(BracketGenerationResult(bracket: bracket, matches: const [])),
      );

      final result = await useCase(validParams);
      expect(result.isRight(), isTrue);

      result.fold((_) => fail('Should be right'), (r) {
        expect(r.deletedBracketCount, equals(1));
        expect(r.deletedMatchCount, equals(0));
      });

      verifyNever(() => mockMatchRepo.deleteMatch(any()));
      verify(() => mockBracketRepo.deleteBracket('bracket-1')).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 4. Generator delegation
  // ═══════════════════════════════════════════════════════════════════════

  group('Generator delegation', () {
    void setupEmptyDivision() {
      when(
        () => mockBracketRepo.getBracketsForDivision(any()),
      ).thenAnswer((_) async => const Right([]));
    }

    test(
      'singleElimination → calls GenerateSingleEliminationBracketUseCase',
      () async {
        setupEmptyDivision();
        final bracket = makeBracket();
        when(() => mockSingleElimUC(any())).thenAnswer(
          (_) async => Right(
            BracketGenerationResult(bracket: bracket, matches: const []),
          ),
        );

        final result = await useCase(validParams);
        expect(result.isRight(), isTrue);

        final captured =
            verify(() => mockSingleElimUC(captureAny())).captured.single
                as GenerateSingleEliminationBracketParams;
        expect(captured.divisionId, equals('div1'));
        expect(captured.participantIds, equals(['p1', 'p2', 'p3']));
        expect(captured.includeThirdPlaceMatch, isFalse);
        verifyNever(() => mockDoubleElimUC(any()));
        verifyNever(() => mockRoundRobinUC(any()));
      },
    );

    test(
      'doubleElimination → calls GenerateDoubleEliminationBracketUseCase',
      () async {
        setupEmptyDivision();
        final bracket = makeBracket();
        final match = makeMatch();
        when(() => mockDoubleElimUC(any())).thenAnswer(
          (_) async => Right(
            DoubleEliminationBracketGenerationResult(
              winnersBracket: bracket,
              losersBracket: bracket,
              grandFinalsMatch: match,
              allMatches: [match],
            ),
          ),
        );

        final result = await useCase(
          const RegenerateBracketParams(
            divisionId: 'div1',
            participantIds: ['p1', 'p2', 'p3'],
            bracketFormat: BracketFormat.doubleElimination,
          ),
        );
        expect(result.isRight(), isTrue);

        final captured =
            verify(() => mockDoubleElimUC(captureAny())).captured.single
                as GenerateDoubleEliminationBracketParams;
        expect(captured.divisionId, equals('div1'));
        expect(captured.participantIds, equals(['p1', 'p2', 'p3']));
        expect(captured.includeResetMatch, isTrue);
        verifyNever(() => mockSingleElimUC(any()));
        verifyNever(() => mockRoundRobinUC(any()));
      },
    );

    test('roundRobin → calls GenerateRoundRobinBracketUseCase', () async {
      setupEmptyDivision();
      final bracket = makeBracket();
      when(() => mockRoundRobinUC(any())).thenAnswer(
        (_) async =>
            Right(BracketGenerationResult(bracket: bracket, matches: const [])),
      );

      final result = await useCase(
        const RegenerateBracketParams(
          divisionId: 'div1',
          participantIds: ['p1', 'p2', 'p3'],
          bracketFormat: BracketFormat.roundRobin,
        ),
      );
      expect(result.isRight(), isTrue);

      final captured =
          verify(() => mockRoundRobinUC(captureAny())).captured.single
              as GenerateRoundRobinBracketParams;
      expect(captured.divisionId, equals('div1'));
      expect(captured.participantIds, equals(['p1', 'p2', 'p3']));
      verifyNever(() => mockSingleElimUC(any()));
      verifyNever(() => mockDoubleElimUC(any()));
    });

    test('poolPlay → calls GeneratePoolPlayEliminationBracketUseCase', () async {
      setupEmptyDivision();
      final bracket = makeBracket();
      when(() => mockPoolPlayUC(any())).thenAnswer(
        (_) async => Right(HybridBracketGenerationResult(
          poolBrackets: const [],
          eliminationBracket:
              BracketGenerationResult(bracket: bracket, matches: const []),
          allMatches: const [],
        )),
      );

      final result = await useCase(
        const RegenerateBracketParams(
          divisionId: 'div1',
          participantIds: ['p1', 'p2', 'p3'],
          bracketFormat: BracketFormat.poolPlay,
        ),
      );
      expect(result.isRight(), isTrue);

      final captured =
          verify(() => mockPoolPlayUC(captureAny())).captured.single
              as GeneratePoolPlayEliminationBracketParams;
      expect(captured.divisionId, equals('div1'));
      expect(captured.participantIds, equals(['p1', 'p2', 'p3']));
      verifyNever(() => mockSingleElimUC(any()));
      verifyNever(() => mockDoubleElimUC(any()));
      verifyNever(() => mockRoundRobinUC(any()));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 5. Error propagation — repository/generator failures
  // ═══════════════════════════════════════════════════════════════════════

  group('Error propagation', () {
    test('getBracketsForDivision fails → propagates failure', () async {
      when(
        () => mockBracketRepo.getBracketsForDivision('div1'),
      ).thenAnswer((_) async => const Left(LocalCacheAccessFailure()));

      final result = await useCase(validParams);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<LocalCacheAccessFailure>()),
        (_) => fail('Should have failed'),
      );
    });

    test('getMatchesForBracket fails → propagates failure', () async {
      when(
        () => mockBracketRepo.getBracketsForDivision('div1'),
      ).thenAnswer((_) async => Right([makeBracket()]));
      when(
        () => mockMatchRepo.getMatchesForBracket('bracket-1'),
      ).thenAnswer((_) async => const Left(LocalCacheAccessFailure()));

      final result = await useCase(validParams);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<LocalCacheAccessFailure>()),
        (_) => fail('Should have failed'),
      );
      // Should NOT proceed to delete bracket
      verifyNever(() => mockBracketRepo.deleteBracket(any()));
    });

    test('deleteMatch fails → propagates failure, stops iteration', () async {
      final m1 = makeMatch(id: 'm1');
      final m2 = makeMatch(id: 'm2');

      when(
        () => mockBracketRepo.getBracketsForDivision('div1'),
      ).thenAnswer((_) async => Right([makeBracket()]));
      when(
        () => mockMatchRepo.getMatchesForBracket('bracket-1'),
      ).thenAnswer((_) async => Right([m1, m2]));
      when(
        () => mockMatchRepo.deleteMatch('m1'),
      ).thenAnswer((_) async => const Left(LocalCacheWriteFailure()));

      final result = await useCase(validParams);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<LocalCacheWriteFailure>()),
        (_) => fail('Should have failed'),
      );
      // m2 delete should NOT be attempted after m1 fails
      verifyNever(() => mockMatchRepo.deleteMatch('m2'));
      verifyNever(() => mockBracketRepo.deleteBracket(any()));
    });

    test('deleteBracket fails → propagates failure', () async {
      when(
        () => mockBracketRepo.getBracketsForDivision('div1'),
      ).thenAnswer((_) async => Right([makeBracket()]));
      when(
        () => mockMatchRepo.getMatchesForBracket('bracket-1'),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockBracketRepo.deleteBracket('bracket-1'),
      ).thenAnswer((_) async => const Left(LocalCacheWriteFailure()));

      final result = await useCase(validParams);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<LocalCacheWriteFailure>()),
        (_) => fail('Should have failed'),
      );
      // Generator should NOT be called after delete failure
      verifyNever(() => mockSingleElimUC(any()));
    });

    test('generator use case fails → propagates failure', () async {
      when(
        () => mockBracketRepo.getBracketsForDivision('div1'),
      ).thenAnswer((_) async => const Right([]));
      when(() => mockSingleElimUC(any())).thenAnswer(
        (_) async => const Left(
          BracketGenerationFailure(userFriendlyMessage: 'Generation failed'),
        ),
      );

      final result = await useCase(validParams);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<BracketGenerationFailure>()),
        (_) => fail('Should have failed'),
      );
    });
  });
}
