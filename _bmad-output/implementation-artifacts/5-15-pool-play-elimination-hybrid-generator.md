# Story 5.15: Pool Play → Elimination Hybrid Generator

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an organizer,
I want the system to generate a pool play followed by elimination bracket,
so that I can run group-stage competition before knockout rounds (FR23).

## Acceptance Criteria

1. **AC1:** A `HybridBracketGeneratorService` abstract interface exists at `lib/features/bracket/domain/services/hybrid_bracket_generator_service.dart`, following the exact same pattern as `RoundRobinBracketGeneratorService` and `SingleEliminationBracketGeneratorService`.
2. **AC2:** A `HybridBracketGenerationResult` entity exists at `lib/features/bracket/domain/entities/hybrid_bracket_generation_result.dart`. It holds: `List<BracketGenerationResult> poolBrackets` (one per pool), `BracketGenerationResult eliminationBracket`, and `List<MatchEntity> allMatches`.
3. **AC3:** `HybridBracketGeneratorServiceImplementation` at `lib/features/bracket/data/services/hybrid_bracket_generator_service_implementation.dart` implements the pool play → elimination hybrid algorithm: splits participants into pools, generates round robin per pool using the existing `RoundRobinBracketGeneratorService`, then generates a single elimination bracket from qualifiers using `SingleEliminationBracketGeneratorService`.
4. **AC4:** Pool count defaults to 2 (Pool A, Pool B). Participants are distributed evenly across pools — if odd, the last pool gets the extra participant.
5. **AC5:** The number of qualifiers per pool (`qualifiersPerPool`) is configurable. Defaults to 2 (top 2 from each pool advance).
6. **AC6:** Pool standings determine seeding for the elimination bracket: Pool A #1 vs Pool B #2, Pool B #1 vs Pool A #2 (cross-seeded to avoid same-pool rematches in first elimination round).
7. **AC7:** `GeneratePoolPlayEliminationBracketParams` exists at `lib/features/bracket/domain/usecases/generate_pool_play_elimination_bracket_params.dart` with fields: `divisionId`, `participantIds`, `numberOfPools` (default 2), `qualifiersPerPool` (default 2).
8. **AC8:** `GeneratePoolPlayEliminationBracketUseCase` exists at `lib/features/bracket/domain/usecases/generate_pool_play_elimination_bracket_use_case.dart`. It extends `UseCase<HybridBracketGenerationResult, GeneratePoolPlayEliminationBracketParams>`, validates inputs, delegates to `HybridBracketGeneratorService`, and persists all brackets and matches via repositories.
9. **AC9:** The `seeding.BracketFormat` enum in `lib/core/algorithms/seeding/bracket_format.dart` is updated to add a `poolPlay('pool_play')` value.
10. **AC10:** `RegenerateBracketUseCase` is updated to handle `BracketFormat.poolPlay` by delegating to `GeneratePoolPlayEliminationBracketUseCase`.
11. **AC11:** `BracketGenerationBloc._onGenerateRequested` is updated so that `BracketFormat.poolPlay` dispatches `GeneratePoolPlayEliminationBracketUseCase` instead of emitting the "not yet available" error.
12. **AC12:** The barrel file `bracket.dart` is updated with exports for all new files.
13. **AC13:** Unit tests for `HybridBracketGeneratorServiceImplementation` verify: correct pool splitting for 4/6/8/10 participants; correct round robin schedule generated per pool; correct elimination bracket from qualifiers; cross-seeding of pool qualifiers; configurable qualifiers per pool; edge case — 3 participants (minimum viable: 1 pool of 3 with top 2 qualifying).
14. **AC14:** Unit tests for `GeneratePoolPlayEliminationBracketUseCase` verify: successful end-to-end generation; validation failures (< 3 participants, empty IDs); repository persistence of all brackets and matches.
15. **AC15:** Existing `BracketGenerationBloc` tests are updated or extended to cover the pool play format selection → generation flow.

## Tasks / Subtasks

- [x] Task 1: Create `HybridBracketGenerationResult` entity (AC: #2)
  - [x] 1.1 Create `lib/features/bracket/domain/entities/hybrid_bracket_generation_result.dart`
  - [x] 1.2 Define `@immutable class HybridBracketGenerationResult` (PODO with equality, same pattern as `DoubleEliminationBracketGenerationResult`):
    ```dart
    import 'package:flutter/foundation.dart';
    import 'package:tkd_brackets/features/bracket/domain/entities/bracket_generation_result.dart';
    import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';

    @immutable
    class HybridBracketGenerationResult {
      const HybridBracketGenerationResult({
        required this.poolBrackets,
        required this.eliminationBracket,
        required this.allMatches,
      });

      /// One BracketGenerationResult per pool (Pool A, Pool B, ...).
      final List<BracketGenerationResult> poolBrackets;

      /// The single elimination bracket built from pool qualifiers.
      final BracketGenerationResult eliminationBracket;

      /// All matches across all pools + elimination.
      final List<MatchEntity> allMatches;

      @override
      bool operator ==(Object other) =>
          identical(this, other) ||
          other is HybridBracketGenerationResult &&
              runtimeType == other.runtimeType &&
              listEquals(poolBrackets, other.poolBrackets) &&
              eliminationBracket == other.eliminationBracket &&
              listEquals(allMatches, other.allMatches);

      @override
      int get hashCode =>
          poolBrackets.hashCode ^
          eliminationBracket.hashCode ^
          allMatches.hashCode;
    }
    ```

- [x] Task 2: Create `HybridBracketGeneratorService` interface (AC: #1)
  - [x] 2.1 Create `lib/features/bracket/domain/services/hybrid_bracket_generator_service.dart`
  - [x] 2.2 Define:
    ```dart
    import 'package:tkd_brackets/features/bracket/domain/entities/hybrid_bracket_generation_result.dart';

    /// Domain service for generating pool play → elimination hybrid brackets.
    /// This service contains the pure algorithm — NO database access.
    abstract interface class HybridBracketGeneratorService {
      /// Generates a pool play → elimination hybrid bracket.
      ///
      /// [divisionId] is the division this bracket belongs to.
      /// [participantIds] is the list of participant IDs.
      /// [numberOfPools] defaults to 2 (Pool A, Pool B).
      /// [qualifiersPerPool] defaults to 2 (top 2 advance).
      /// [eliminationBracketId] is the pre-generated ID for the elimination bracket.
      /// [poolBracketIds] is the pre-generated list of IDs for pool brackets (one per pool).
      HybridBracketGenerationResult generate({
        required String divisionId,
        required List<String> participantIds,
        required String eliminationBracketId,
        required List<String> poolBracketIds,
        int numberOfPools = 2,
        int qualifiersPerPool = 2,
      });
    }
    ```

- [x] Task 3: Implement `HybridBracketGeneratorServiceImplementation` (AC: #3, #4, #5, #6)
  - [x] 3.1 Create `lib/features/bracket/data/services/hybrid_bracket_generator_service_implementation.dart`
  - [x] 3.2 `@LazySingleton(as: HybridBracketGeneratorService)` — same DI pattern as other generator services
  - [x] 3.3 Constructor injects `RoundRobinBracketGeneratorService` and `SingleEliminationBracketGeneratorService` (compose, don't duplicate)
  - [x] 3.4 Algorithm in `generate()`:
    1. **Split participants into pools**: Distribute `participantIds` evenly. Pool A gets indices `0, numberOfPools, 2*numberOfPools, ...`, Pool B gets `1, numberOfPools+1, ...` etc. (round-robin distribution, NOT sequential chunks — this gives better competitive balance).
    2. **Generate round robin per pool**: For each pool `i`, call `_roundRobinGenerator.generate(divisionId: divisionId, participantIds: poolParticipants[i], bracketId: poolBracketIds[i], poolIdentifier: String.fromCharCode(65 + i))` — returns `BracketGenerationResult`.
    3. **Build qualifier placeholder list**: Since pool standings aren't known at generation time (matches haven't been played yet), the elimination bracket is generated with placeholder participant slots. Create `qualifierIds` as: `['pool_a_q1', 'pool_b_q2', 'pool_b_q1', 'pool_a_q2']` (cross-seeded). These placeholders will be replaced at runtime when pool results are finalized.
    4. **Generate elimination bracket**: Call `_singleEliminationGenerator.generate(divisionId: divisionId, participantIds: qualifierIds, bracketId: eliminationBracketId)`.
    5. **Collect all matches**: Combine matches from all pools + elimination.
    6. Return `HybridBracketGenerationResult(poolBrackets: poolResults, eliminationBracket: elimResult, allMatches: allMatches)`.
  - [x] 3.5 Store the pool configuration in the elimination bracket's `bracketDataJson`: `{'hybrid': true, 'numberOfPools': numberOfPools, 'qualifiersPerPool': qualifiersPerPool, 'poolBracketIds': poolBracketIds}`

- [x] Task 4: Create `GeneratePoolPlayEliminationBracketParams` (AC: #7)
  - [x] 4.1 Create `lib/features/bracket/domain/usecases/generate_pool_play_elimination_bracket_params.dart`
  - [x] 4.2 Define:
    ```dart
    import 'package:flutter/foundation.dart' show immutable;

    /// Parameters for generating a pool play → elimination hybrid bracket.
    @immutable
    class GeneratePoolPlayEliminationBracketParams {
      const GeneratePoolPlayEliminationBracketParams({
        required this.divisionId,
        required this.participantIds,
        this.numberOfPools = 2,
        this.qualifiersPerPool = 2,
      });

      final String divisionId;
      final List<String> participantIds;
      final int numberOfPools;
      final int qualifiersPerPool;
    }
    ```

- [x] Task 5: Create `GeneratePoolPlayEliminationBracketUseCase` (AC: #8)
  - [x] 5.1 Create `lib/features/bracket/domain/usecases/generate_pool_play_elimination_bracket_use_case.dart`
  - [x] 5.2 `@injectable`, extends `UseCase<HybridBracketGenerationResult, GeneratePoolPlayEliminationBracketParams>`
  - [x] 5.3 Constructor injects: `HybridBracketGeneratorService _generatorService`, `BracketRepository _bracketRepository`, `MatchRepository _matchRepository`, `Uuid _uuid`
  - [x] 5.4 Implement `call()`:
    1. **Validate**: minimum `numberOfPools * qualifiersPerPool` participants needed for meaningful pool play (at minimum 3 participants total — 1 pool with 3 always works). Also validate: `participantIds.length >= 3`, no empty IDs, no duplicates, `numberOfPools >= 1`, `qualifiersPerPool >= 1`.
    2. **If total qualifiers (`numberOfPools * qualifiersPerPool`) > `participantIds.length`**, return `ValidationFailure` — not enough participants to fill qualifier slots.
    3. **Generate bracket IDs**: `eliminationBracketId = _uuid.v4()`, `poolBracketIds = List.generate(params.numberOfPools, (_) => _uuid.v4())`
    4. **Call `_generatorService.generate(...)`**
    5. **Persist each pool bracket**: Loop `poolBrackets`, call `_bracketRepository.createBracket(poolBracket.bracket)`. On failure → `Left.new`.
    6. **Persist elimination bracket**: `_bracketRepository.createBracket(eliminationBracket.bracket)`. On failure → `Left.new`.
    7. **Persist all matches (batch)**: `_matchRepository.createMatches(result.allMatches)`. On failure → `Left.new`.
    8. **Return `Right(result)`**.

- [x] Task 6: Update `seeding.BracketFormat` enum (AC: #9)
  - [x] 6.1 In `lib/core/algorithms/seeding/bracket_format.dart`, add `poolPlay('pool_play')` value:
    ```dart
    enum BracketFormat {
      singleElimination('single_elimination'),
      doubleElimination('double_elimination'),
      roundRobin('round_robin'),
      poolPlay('pool_play');

      const BracketFormat(this.value);
      final String value;
    }
    ```

- [x] Task 7: Update `RegenerateBracketUseCase` (AC: #10)
  - [x] 7.1 Add `GeneratePoolPlayEliminationBracketUseCase _poolPlayUseCase` as a constructor dependency
  - [x] 7.2 Add `case BracketFormat.poolPlay:` to the switch statement, delegating to `_poolPlayUseCase(GeneratePoolPlayEliminationBracketParams(divisionId: params.divisionId, participantIds: params.participantIds))`
  - [x] 7.3 Import the new use case and params files
  - [x] 7.4 **CRITICAL**: The `RegenerateBracketUseCase` constructor currently takes 5 positional params. Adding a 6th will require updating `injection.config.dart` via `build_runner`.

- [x] Task 8: Update `BracketGenerationBloc` (AC: #11)
  - [x] 8.1 Add `GeneratePoolPlayEliminationBracketUseCase _generatePoolPlayEliminationUseCase` as a constructor dependency (8th positional parameter, after `_regenerateBracketUseCase`)
  - [x] 8.2 Add new field declaration:
    ```dart
    final GeneratePoolPlayEliminationBracketUseCase
        _generatePoolPlayEliminationUseCase;
    ```
  - [x] 8.3 In `_onGenerateRequested`, replace the ENTIRE `case BracketFormat.poolPlay:` block (lines 187-190 in current file). The current code:
    ```dart
    // CURRENT (DELETE THIS):
    case BracketFormat.poolPlay:
      emit(const BracketGenerationState.loadFailure(
        userFriendlyMessage: 'Pool play format is not yet available.',
      ));
    ```
    Replace with the EXACT same pattern used by the other formats (await + fold). **DO NOT use `.then()` chaining** — the existing BLoC uses `await` + `result.fold()`:
    ```dart
    // REPLACEMENT:
    case BracketFormat.poolPlay:
      final result = await _generatePoolPlayEliminationUseCase(
        GeneratePoolPlayEliminationBracketParams(
          divisionId: divisionId,
          participantIds: activeParticipantIds,
        ),
      );
      result.fold(
        (failure) => emit(BracketGenerationState.loadFailure(
          userFriendlyMessage: failure.userFriendlyMessage,
          technicalDetails: failure.technicalDetails,
        )),
        (res) => emit(BracketGenerationState.generationSuccess(
          generatedBracketId: res.eliminationBracket.bracket.id,
        )),
      );
    ```
    **CRITICAL**: Note `res.eliminationBracket.bracket.id` — the `HybridBracketGenerationResult` has `.eliminationBracket` (a `BracketGenerationResult`) whose `.bracket.id` is used for navigation. This is DIFFERENT from single elimination which uses `res.bracket.id` and double elimination which uses `res.winnersBracket.id`.
  - [x] 8.4 In `_onRegenerateRequested`, the `genResult` type-check chain (lines 236-245) currently handles `BracketGenerationResult` and `DoubleEliminationBracketGenerationResult`. Add `HybridBracketGenerationResult` BEFORE the `else` fallback:
    ```dart
    // CURRENT CODE (lines 234-245):
    final genResult = res.generationResult;
    String bracketId;
    if (genResult is BracketGenerationResult) {
      bracketId = genResult.bracket.id;
    } else if (genResult is DoubleEliminationBracketGenerationResult) {
      bracketId = genResult.winnersBracket.id;
    } else {
      // ...error...
    }

    // UPDATED CODE:
    final genResult = res.generationResult;
    String bracketId;
    if (genResult is BracketGenerationResult) {
      bracketId = genResult.bracket.id;
    } else if (genResult is DoubleEliminationBracketGenerationResult) {
      bracketId = genResult.winnersBracket.id;
    } else if (genResult is HybridBracketGenerationResult) {
      bracketId = genResult.eliminationBracket.bracket.id;
    } else {
      emit(const BracketGenerationState.loadFailure(
        userFriendlyMessage: 'Unexpected generation result type.',
      ));
      return;
    }
    ```
  - [x] 8.5 Update `_mapToSeedingFormat` (line 258). Current code:
    ```dart
    // CURRENT:
    BracketFormat.poolPlay => seeding.BracketFormat.singleElimination,
    // UPDATED:
    BracketFormat.poolPlay => seeding.BracketFormat.poolPlay,
    ```
  - [x] 8.6 Add these imports to `bracket_generation_bloc.dart`:
    ```dart
    import 'package:tkd_brackets/features/bracket/domain/entities/hybrid_bracket_generation_result.dart';
    import 'package:tkd_brackets/features/bracket/domain/usecases/generate_pool_play_elimination_bracket_params.dart';
    import 'package:tkd_brackets/features/bracket/domain/usecases/generate_pool_play_elimination_bracket_use_case.dart';
    ```

- [x] Task 9: Update barrel file (AC: #12)
  - [x] 9.1 Add to `lib/features/bracket/bracket.dart`:
    ```dart
    // Domain entity
    export 'domain/entities/hybrid_bracket_generation_result.dart';
    // Domain service
    export 'domain/services/hybrid_bracket_generator_service.dart';
    // Data service implementation
    export 'data/services/hybrid_bracket_generator_service_implementation.dart';
    // Use case + params
    export 'domain/usecases/generate_pool_play_elimination_bracket_params.dart';
    export 'domain/usecases/generate_pool_play_elimination_bracket_use_case.dart';
    ```

- [x] Task 10: Write `HybridBracketGeneratorServiceImplementation` tests (AC: #13)
  - [x] 10.1 Create `test/features/bracket/data/services/hybrid_bracket_generator_service_implementation_test.dart`
  - [x] 10.2 This test does NOT mock the sub-generators. Instead, it mocks the sub-generators since the implementation composes them. Pattern:
    ```dart
    import 'package:flutter_test/flutter_test.dart';
    import 'package:mocktail/mocktail.dart';
    import 'package:tkd_brackets/features/bracket/data/services/hybrid_bracket_generator_service_implementation.dart';
    import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
    import 'package:tkd_brackets/features/bracket/domain/entities/bracket_generation_result.dart';
    import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
    import 'package:tkd_brackets/features/bracket/domain/services/round_robin_bracket_generator_service.dart';
    import 'package:tkd_brackets/features/bracket/domain/services/single_elimination_bracket_generator_service.dart';

    class MockRoundRobinGeneratorService extends Mock
        implements RoundRobinBracketGeneratorService {}

    class MockSingleEliminationGeneratorService extends Mock
        implements SingleEliminationBracketGeneratorService {}
    ```
  - [x] 10.3 In `setUp`, create service with mocked sub-generators:
    ```dart
    late HybridBracketGeneratorServiceImplementation service;
    late MockRoundRobinGeneratorService mockRRGenerator;
    late MockSingleEliminationGeneratorService mockSEGenerator;

    setUp(() {
      mockRRGenerator = MockRoundRobinGeneratorService();
      mockSEGenerator = MockSingleEliminationGeneratorService();
      service = HybridBracketGeneratorServiceImplementation(
        mockRRGenerator,
        mockSEGenerator,
      );
    });
    ```
  - [x] 10.4 Helper to create stub `BracketGenerationResult`:
    ```dart
    BracketGenerationResult makePoolResult(String bracketId, String poolId) {
      final now = DateTime.now();
      return BracketGenerationResult(
        bracket: BracketEntity(
          id: bracketId,
          divisionId: 'div-1',
          bracketType: BracketType.pool,
          totalRounds: 1,
          poolIdentifier: poolId,
          createdAtTimestamp: now,
          updatedAtTimestamp: now,
          ),
        matches: [
          MatchEntity(
            id: 'm-$bracketId',
            bracketId: bracketId,
            roundNumber: 1,
            matchNumberInRound: 1,
            createdAtTimestamp: now,
            updatedAtTimestamp: now,
          ),
        ],
      );
    }
    ```
  - [x] 10.5 Stub the sub-generators using `when(() => mockRRGenerator.generate(...)).thenReturn(...)` with `any(named: 'divisionId')` etc.
  - [x] 10.6 Test cases:
    - [x] **4 participants, 2 pools**: Verify `mockRRGenerator.generate` called 2x with participant lists of 2 each (round-robin distribution: [p1,p3], [p2,p4]). Verify `mockSEGenerator.generate` called 1x with qualifier placeholders.
    - [x] **6 participants, 2 pools**: Verify pools of 3 each ([p1,p3,p5], [p2,p4,p6]).
    - [x] **8 participants, 2 pools**: Verify pools of 4 each.
    - [x] **10 participants, 2 pools**: Verify pools of 5 each.
    - [x] **Cross-seeding verification**: For 2 pools, 2 qualifiers → verify qualifier IDs passed to SE generator are in cross-seed order: `['pool_a_q1', 'pool_b_q2', 'pool_b_q1', 'pool_a_q2']`.
    - [x] **Configurable qualifiers**: 3 per pool → 6 total qualifiers passed to SE generator.
    - [x] **Pool bracket metadata**: Each pool bracket's `poolIdentifier` is correct ('A', 'B', etc.).
    - [x] **Elimination bracket metadata**: `bracketDataJson` contains `{'hybrid': true, 'numberOfPools': 2, 'qualifiersPerPool': 2, ...}`.
    - [x] **allMatches**: Total count = sum of all pool matches + elimination matches.
    - [x] **Result structure**: `poolBrackets.length == numberOfPools`, `eliminationBracket` is not null.
    - [x] **Pool bracket IDs**: Passed `poolBracketIds` are used correctly.
    - [x] **Elimination bracket ID**: Passed `eliminationBracketId` is used.

- [x] Task 11: Write `GeneratePoolPlayEliminationBracketUseCase` tests (AC: #14)
  - [x] 11.1 Create `test/features/bracket/domain/usecases/generate_pool_play_elimination_bracket_use_case_test.dart`
  - [x] 11.2 Define mocks (follow same pattern as `generate_round_robin_bracket_use_case_test.dart`):
    ```dart
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
    ```
  - [x] 11.3 **`setUpAll` with `registerFallbackValue`** — **CRITICAL** (same pattern as RR use case test):
    ```dart
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
    ```
  - [x] 11.4 `setUp` creates mocks and use case:
    ```dart
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

      // UUID returns incrementing values for predictability
      var uuidCounter = 0;
      when(() => mockUuid.v4()).thenAnswer((_) => 'uuid-${uuidCounter++}');
    });
    ```
  - [x] 11.5 Stub helper:
    ```dart
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
        .thenAnswer((_) async => Right<Failure, BracketEntity>(
          _.positionalArguments.first as BracketEntity,
        ));

      when(() => mockMatchRepository.createMatches(any()))
        .thenAnswer((_) async => Right<Failure, List<MatchEntity>>(
          _.positionalArguments.first as List<MatchEntity>,
        ));
    }
    ```
  - [x] 11.6 Test cases (each with `() async {}`):
    - [x] **`< 3 participants → ValidationFailure`**: Pass `['p1', 'p2']`, expect `Left(ValidationFailure(...))`.
    - [x] **`empty participant ID → ValidationFailure`**: Pass `['p1', '', 'p3']`.
    - [x] **`duplicate participant IDs → ValidationFailure`**: Pass `['p1', 'p2', 'p1']`.
    - [x] **`qualifiers exceed participants → ValidationFailure`**: 4 participants, 2 pools, 3 qualifiers each = 6 > 4.
    - [x] **`success: generates and persists all brackets + matches`**: Verify `mockBracketRepository.createBracket` called N+1 times (N pools + 1 elimination), `mockMatchRepository.createMatches` called 1x.
    - [x] **`pool bracket persist failure → propagates`**: First `createBracket` returns `Left(LocalCacheWriteFailure())`, verify `createMatches` is NOT called (`verifyZeroInteractions(mockMatchRepository)`).
    - [x] **`elimination bracket persist failure → propagates`**: Pool brackets succeed, elimination fails.
    - [x] **`match persist failure → propagates`**: All brackets succeed, matches fail.

- [x] Task 12: Update `BracketGenerationBloc` tests (AC: #15)
  - [x] 12.1 In `test/features/bracket/presentation/bloc/bracket_generation_bloc_test.dart`:
  - [x] 12.2 Add mock class OUTSIDE `main()` (follow existing pattern at lines 34-44):
    ```dart
    class MockGeneratePoolPlayEliminationBracketUseCase extends Mock
        implements GeneratePoolPlayEliminationBracketUseCase {}
    ```
  - [x] 12.3 Add fake class OUTSIDE `main()` (follow pattern at lines 46-56):
    ```dart
    class FakeGeneratePoolPlayEliminationBracketParams extends Fake
        implements GeneratePoolPlayEliminationBracketParams {}
    ```
  - [x] 12.4 Add import:
    ```dart
    import 'package:tkd_brackets/features/bracket/domain/entities/hybrid_bracket_generation_result.dart';
    import 'package:tkd_brackets/features/bracket/domain/usecases/generate_pool_play_elimination_bracket_params.dart';
    import 'package:tkd_brackets/features/bracket/domain/usecases/generate_pool_play_elimination_bracket_use_case.dart';
    ```
  - [x] 12.5 Add `late MockGeneratePoolPlayEliminationBracketUseCase generatePoolPlayUseCase;` to the `main()` variable declarations (after line 65)
  - [x] 12.6 Add `registerFallbackValue(FakeGeneratePoolPlayEliminationBracketParams());` in `setUpAll` (after line 125)
  - [x] 12.7 Add `generatePoolPlayUseCase = MockGeneratePoolPlayEliminationBracketUseCase();` in `setUp` (after line 135)
  - [x] 12.8 Update `buildBloc()` to pass the 8th positional parameter:
    ```dart
    BracketGenerationBloc buildBloc() => BracketGenerationBloc(
          divisionRepository,
          participantRepository,
          bracketRepository,
          generateSingleUseCase,
          generateDoubleUseCase,
          generateRoundRobinUseCase,
          regenerateUseCase,
          generatePoolPlayUseCase,  // NEW: 8th positional param
        );
    ```
  - [x] 12.9 Add success test (follow pattern at lines 210-228):
    ```dart
    blocTest<BracketGenerationBloc, BracketGenerationState>(
      'generateRequested emits [InProgress, Success] for Pool Play',
      setUp: () {
        when(() => generatePoolPlayUseCase(any())).thenAnswer(
          (_) async => Right(HybridBracketGenerationResult(
            poolBrackets: [
              BracketGenerationResult(bracket: testBracket.copyWith(id: 'pool-a', bracketType: BracketType.pool), matches: const []),
              BracketGenerationResult(bracket: testBracket.copyWith(id: 'pool-b', bracketType: BracketType.pool), matches: const []),
            ],
            eliminationBracket: BracketGenerationResult(bracket: testBracket, matches: const []),
            allMatches: const [],
          )),
        );
      },
      build: buildBloc,
      seed: () => BracketGenerationLoadSuccess(
        division: testDivision.copyWith(bracketFormat: BracketFormat.poolPlay),
        participants: testParticipants,
        existingBrackets: const [],
      ),
      act: (bloc) => bloc.add(const BracketGenerationGenerateRequested()),
      expect: () => [
        const BracketGenerationInProgress(),
        BracketGenerationSuccess(generatedBracketId: testBracket.id),
      ],
    );
    ```
  - [x] 12.10 Add failure test:
    ```dart
    blocTest<BracketGenerationBloc, BracketGenerationState>(
      'generateRequested emits [InProgress, LoadFailure] for Pool Play failure',
      setUp: () {
        when(() => generatePoolPlayUseCase(any())).thenAnswer(
          (_) async => const Left(
              ServerResponseFailure(userFriendlyMessage: 'Pool Error')),
        );
      },
      build: buildBloc,
      seed: () => BracketGenerationLoadSuccess(
        division: testDivision.copyWith(bracketFormat: BracketFormat.poolPlay),
        participants: testParticipants,
        existingBrackets: const [],
      ),
      act: (bloc) => bloc.add(const BracketGenerationGenerateRequested()),
      expect: () => [
        const BracketGenerationInProgress(),
        const BracketGenerationLoadFailure(userFriendlyMessage: 'Pool Error'),
      ],
    );
    ```

- [x] Task 13: Run `build_runner` and verify (AC: all)
  - [x] 13.1 Run `dart run build_runner build --delete-conflicting-outputs` — regenerates DI config
  - [x] 13.2 Run `dart analyze` — zero errors, zero warnings
  - [x] 13.3 Run all new tests — all pass
  - [x] 13.4 Run existing bracket tests — no regressions

## Dev Notes

### ⚠️ Scope Boundary: Pool Play → Elimination Hybrid Algorithm

This story creates the fourth bracket format generator. It builds entirely on existing infrastructure:
- **Reuses** `RoundRobinBracketGeneratorService` for pool stages
- **Reuses** `SingleEliminationBracketGeneratorService` for elimination stage
- **Follows** exact same patterns as Stories 5.4, 5.5, 5.6

**This story does NOT:**
- Add any new UI pages or widgets (pool play was already a selectable option in `BracketFormatSelectionDialog` from Story 5.14)
- Add pool standings calculation (that's a scoring concern — Epic 6)
- Add pool-to-elimination advancement logic at runtime (that requires match results — Epic 6)
- Modify the bracket visualization renderer (pool display is future work)

### ⚠️ THREE BracketFormat Enums — UPDATED with Pool Play

After this story, the enum landscape is:

1. **`division_entity.BracketFormat`** — already has `poolPlay` value ✅
2. **`seeding.BracketFormat`** — needs `poolPlay` added (Task 6)
3. **`bracket_layout.BracketFormat`** — DO NOT touch (visualization is separate concern)

### ⚠️ Composition Over Duplication

The `HybridBracketGeneratorServiceImplementation` MUST compose existing generator services:
```dart
@LazySingleton(as: HybridBracketGeneratorService)
class HybridBracketGeneratorServiceImplementation
    implements HybridBracketGeneratorService {
  HybridBracketGeneratorServiceImplementation(
    this._roundRobinGenerator,
    this._singleEliminationGenerator,
  );

  final RoundRobinBracketGeneratorService _roundRobinGenerator;
  final SingleEliminationBracketGeneratorService _singleEliminationGenerator;
  ...
}
```
**DO NOT** copy-paste round robin or single elimination logic. Call the existing service methods directly.

### ⚠️ Qualifier Placeholder Strategy

Since pool play generates brackets BEFORE any matches are played, the elimination bracket's participant slots will contain **placeholder IDs** like `pool_a_q1`, `pool_b_q2`. These are intentional — they'll be replaced by the scoring/advancement system (Epic 6) when pool results are finalized. The `BracketEntity.bracketDataJson` stores the hybrid configuration so the advancement system knows how to interpret these placeholders.

### ⚠️ Pool Splitting Strategy — Round-Robin Distribution

Distribute participants via interleaving (NOT sequential chunks):
```dart
// For 8 participants [P1, P2, P3, P4, P5, P6, P7, P8] with 2 pools:
// Pool A: P1, P3, P5, P7 (indices 0, 2, 4, 6)
// Pool B: P2, P4, P6, P8 (indices 1, 3, 5, 7)
for (var i = 0; i < participantIds.length; i++) {
  pools[i % numberOfPools].add(participantIds[i]);
}
```
This gives better competitive balance than sequential splitting ([P1-P4] vs [P5-P8]).

### ⚠️ Cross-Seeding for Elimination

Pool qualifiers are cross-seeded to avoid same-pool rematches in the first elimination round:
```
For 2 pools, 2 qualifiers each:
  Slot 1: Pool A #1 (best of Pool A)
  Slot 2: Pool B #2 (2nd of Pool B)
  Slot 3: Pool B #1 (best of Pool B)
  Slot 4: Pool A #2 (2nd of Pool A)

Match 1: A#1 vs B#2
Match 2: B#1 vs A#2
```
This is the standard tournament cross-seeding pattern.

### ⚠️ Use Case Pattern — Multiple Bracket Persistence

Unlike single/double elimination which persist 1-2 brackets, pool play persists N+1 brackets (N pools + 1 elimination). The persistence loop pattern:
```dart
// Persist pool brackets
for (final poolResult in result.poolBrackets) {
  final bracketResult = await _bracketRepository.createBracket(
    poolResult.bracket,
  );
  // On failure → fold with Left.new and return early
  final failure = bracketResult.fold((f) => f, (_) => null);
  if (failure != null) return Left(failure);
}

// Persist elimination bracket
final elimResult = await _bracketRepository.createBracket(
  result.eliminationBracket.bracket,
);
return elimResult.fold(Left.new, (_) async {
  final matchesResult = await _matchRepository.createMatches(
    result.allMatches,
  );
  return matchesResult.fold(Left.new, (_) => Right(result));
});
```

### ⚠️ RegenerateBracketUseCase — Injectable Constructor Change

Adding `GeneratePoolPlayEliminationBracketUseCase` as a 6th parameter to `RegenerateBracketUseCase` constructor is a **breaking DI change**. After editing, you MUST run `dart run build_runner build --delete-conflicting-outputs` to regenerate `injection.config.dart`. The DI system will auto-resolve the new dependency because the use case is already `@injectable`.

**Current constructor (5 params):**
```dart
RegenerateBracketUseCase(
  this._bracketRepository,
  this._matchRepository,
  this._singleEliminationUseCase,
  this._doubleEliminationUseCase,
  this._roundRobinUseCase,
)
```

**Updated constructor (6 params):**
```dart
RegenerateBracketUseCase(
  this._bracketRepository,
  this._matchRepository,
  this._singleEliminationUseCase,
  this._doubleEliminationUseCase,
  this._roundRobinUseCase,
  this._poolPlayUseCase,
)
```

### ⚠️ BracketGenerationBloc — 8th Constructor Dependency

Adding the pool play use case makes this BLoC's constructor have 8 positional dependencies. This is acceptable for a facade BLoC that dispatches to multiple generators. The `@injectable` annotation handles DI resolution automatically.

**Current constructor (7 positional params, from `bracket_generation_bloc.dart` lines 27-35):**
```dart
BracketGenerationBloc(
  this._divisionRepository,          // 1
  this._participantRepository,       // 2
  this._bracketRepository,           // 3
  this._generateSingleEliminationUseCase,  // 4
  this._generateDoubleEliminationUseCase,  // 5
  this._generateRoundRobinUseCase,         // 6
  this._regenerateBracketUseCase,           // 7
) : super(const BracketGenerationState.initial()) {
```

**Updated constructor (8 positional params):**
```dart
BracketGenerationBloc(
  this._divisionRepository,                       // 1
  this._participantRepository,                     // 2
  this._bracketRepository,                         // 3
  this._generateSingleEliminationUseCase,          // 4
  this._generateDoubleEliminationUseCase,          // 5
  this._generateRoundRobinUseCase,                 // 6
  this._regenerateBracketUseCase,                   // 7
  this._generatePoolPlayEliminationUseCase,         // 8 ← NEW
) : super(const BracketGenerationState.initial()) {
```

### ⚠️ BLoC Variable Names in `_onGenerateRequested`

The existing BLoC code (lines 112-128) extracts values into local variables BEFORE the switch. The pool play case MUST use the same variable names:
- `divisionId` (NOT `division.id`) — already extracted at line 115
- `activeParticipantIds` (NOT `participantIds` or `participants`) — already filtered at line 121
- `selectedFormat` — already resolved at line 116

DO NOT re-extract these values inside the `case BracketFormat.poolPlay:` block.

### Existing Repository Interfaces (DO NOT MODIFY)

#### BracketRepository
```dart
abstract class BracketRepository {
  Future<Either<Failure, List<BracketEntity>>> getBracketsForDivision(String divisionId);
  Future<Either<Failure, BracketEntity>> getBracketById(String id);
  Future<Either<Failure, BracketEntity>> createBracket(BracketEntity bracket);
  Future<Either<Failure, BracketEntity>> updateBracket(BracketEntity bracket);
  Future<Either<Failure, Unit>> deleteBracket(String id);
}
```

#### MatchRepository
```dart
abstract class MatchRepository {
  Future<Either<Failure, List<MatchEntity>>> getMatchesForBracket(String bracketId);
  Future<Either<Failure, MatchEntity>> createMatch(MatchEntity match);
  Future<Either<Failure, List<MatchEntity>>> createMatches(List<MatchEntity> matches);
  Future<Either<Failure, MatchEntity>> updateMatch(MatchEntity match);
  Future<Either<Failure, Unit>> deleteMatch(String id);
}
```

### BLoC Pattern — Follow Existing Conventions

- `@injectable` (NOT `@lazySingleton`) for BLoCs
- Positional constructor params for DI injection
- Guard state before processing events
- Nested fold for sequential repo calls
- `Left.new` tear-off for error propagation

### Test Pattern — Follow Existing Conventions

- `bloc_test` package with `blocTest<BlocType, StateType>`
- `Fake` classes + `registerFallbackValue` in `setUpAll`
- `isA<T>().having(...)` for complex matchers
- `seed:` parameter for tests needing pre-loaded state
- Mock use cases with `Mock implements UseCaseType`

### Project Structure Notes

New files created by this story:
```
lib/features/bracket/
├── data/
│   └── services/
│       └── hybrid_bracket_generator_service_implementation.dart    # NEW
└── domain/
    ├── entities/
    │   └── hybrid_bracket_generation_result.dart                   # NEW
    ├── services/
    │   └── hybrid_bracket_generator_service.dart                   # NEW
    └── usecases/
        ├── generate_pool_play_elimination_bracket_params.dart      # NEW
        └── generate_pool_play_elimination_bracket_use_case.dart    # NEW

test/features/bracket/
├── data/
│   └── services/
│       └── hybrid_bracket_generator_service_implementation_test.dart  # NEW
└── domain/
    └── usecases/
        └── generate_pool_play_elimination_bracket_use_case_test.dart  # NEW
```

Modified files:
```
lib/core/algorithms/seeding/bracket_format.dart                       # MODIFIED — add poolPlay
lib/features/bracket/domain/usecases/regenerate_bracket_use_case.dart # MODIFIED — add poolPlay case
lib/features/bracket/domain/usecases/regenerate_bracket_params.dart   # NO CHANGE (uses seeding.BracketFormat which gets new value)
lib/features/bracket/presentation/bloc/bracket_generation_bloc.dart   # MODIFIED — wire pool play use case
lib/features/bracket/bracket.dart                                     # MODIFIED — add new exports
lib/core/di/injection.config.dart                                     # REGENERATED by build_runner
test/features/bracket/presentation/bloc/bracket_generation_bloc_test.dart  # MODIFIED — add pool play tests
```

### ⚠️ Common LLM Mistakes — Prevention Rules

| #   | Mistake                                                                                             | Correct Approach                                                                                                                                                  |
| --- | --------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Duplicating round robin algorithm logic in hybrid generator                                         | COMPOSE existing `RoundRobinBracketGeneratorService` — call its `.generate()` method directly                                                                     |
| 2   | Duplicating single elimination logic                                                                | COMPOSE existing `SingleEliminationBracketGeneratorService` — call its `.generate()` method                                                                       |
| 3   | Sequential pool splitting `[P1-P4], [P5-P8]`                                                        | Use round-robin distribution `[P1,P3,P5,P7], [P2,P4,P6,P8]` via `i % numberOfPools` for competitive balance                                                       |
| 4   | Trying to implement pool standings/advancement at generation time                                   | Pool play generates PLACEHOLDER qualifier IDs. Runtime advancement is Epic 6 scope                                                                                |
| 5   | Forgetting to update `seeding.BracketFormat` enum                                                   | Must add `poolPlay` to `lib/core/algorithms/seeding/bracket_format.dart` — this enum currently has only 3 values                                                  |
| 6   | Not updating `RegenerateBracketUseCase` for pool play                                               | Must add `BracketFormat.poolPlay` case to the switch statement AND add 6th constructor param                                                                      |
| 7   | Using `@lazySingleton` for the use case                                                             | Use cases are `@injectable` (NOT `@lazySingleton`). Only generator *services* use `@LazySingleton(as: ...)`                                                       |
| 8   | Forgetting to run `build_runner` after adding new DI dependency to `RegenerateBracketUseCase`       | Constructor change requires DI regeneration: `dart run build_runner build --delete-conflicting-outputs`                                                           |
| 9   | Importing `bracket_layout.BracketFormat` in new files                                               | NEVER import the layout-level `BracketFormat`. Only `division_entity.BracketFormat` (UI/presentation) and `seeding.BracketFormat` (algorithms/domain)             |
| 10  | Not persisting ALL pool brackets in the use case                                                    | Must loop over `poolBrackets` and persist each one individually via `_bracketRepository.createBracket()` — the repository does NOT support batch bracket creation |
| 11  | Using wrong BracketType for pool brackets                                                           | Pool brackets use `BracketType.pool`, elimination uses `BracketType.winners`                                                                                      |
| 12  | Not storing hybrid config in `bracketDataJson`                                                      | The elimination bracket's `bracketDataJson` MUST contain `{'hybrid': true, ...}` for future advancement logic                                                     |
| 13  | Wrong return type accessor in `BracketGenerationBloc` for pool play                                 | Navigation uses `res.eliminationBracket.bracket.id`, NOT `res.bracket.id` (single elim) or `res.winnersBracket.id` (double elim)                                  |
| 14  | Forgetting `registerFallbackValue` for `FakeGeneratePoolPlayEliminationBracketParams` in BLoC tests | Must register in `setUpAll` alongside existing Fake classes                                                                                                       |
| 15  | Using `.then()` chaining in BLoC event handler                                                      | The codebase uses `await` + `result.fold()` pattern. DO NOT use `.then()` — see existing `_onGenerateRequested` cases                                             |
| 16  | Forgetting `registerFallbackValue` for `BracketEntity` and `List<MatchEntity>` in use case tests    | Must register in `setUpAll` — same pattern as `generate_round_robin_bracket_use_case_test.dart` lines 31-43                                                       |
| 17  | Using wrong variable names in `_onGenerateRequested` pool play case                                 | Must use `divisionId` (already extracted line 115) and `activeParticipantIds` (already filtered line 121), NOT `division.id` or `participants`                    |
| 18  | Not updating `buildBloc()` in test file with 8th positional param                                   | Test constructor MUST pass all 8 params positionally — adding pool play use case mock as last param                                                               |
| 19  | Creating a `FakeGeneratePoolPlayEliminationBracketParams` inside `main()`                           | Fake classes MUST be defined OUTSIDE `main()` at top level, following the pattern at lines 46-56 of the test file                                                 |
| 20  | Not adding `HybridBracketGenerationResult` to the regenerate result type-check                      | The `_onRegenerateRequested` handler (lines 233-250) checks `genResult` type — must add `is HybridBracketGenerationResult` BEFORE the `else` fallback             |

### Previous Story Intelligence

Learnings from Story 5.14 (Bracket Generation UI Integration):

1. **`Left.new` tear-off**: Project standard for error propagation in `.fold()`.
2. **`registerFallbackValue` pattern**: Must register in `setUpAll`, not `setUp`.
3. **`BracketType.pool`**: Used for round robin / pool brackets. `BracketType.winners` for elimination.
4. **Generator services use `@LazySingleton`**: Not `@injectable`. Use cases use `@injectable`.
5. **`RegenerateBracketResult.generationResult` is `Object`**: Must type-check with `is` before accessing fields. After this story, `HybridBracketGenerationResult` becomes a third possible type.
6. **Pool play was already a selectable format** in `BracketFormatSelectionDialog` (it just emitted an error). This story removes that error.
7. **`_mapToSeedingFormat` fallback**: Currently maps `poolPlay → singleElimination` as fallback. After this story, it maps to `seeding.BracketFormat.poolPlay` properly.

### References

- [Source: epics.md#Story 5.15] — User story, acceptance criteria (FR23)
- [Source: architecture.md#Implementation Patterns] — Naming conventions, file structure
- [Source: bracket_entity.dart] — `BracketType` enum with `pool` value
- [Source: bracket_generation_result.dart] — Result pattern for single/RR generators
- [Source: double_elimination_bracket_generation_result.dart] — Multi-bracket result pattern
- [Source: round_robin_bracket_generator_service.dart] — Service interface pattern
- [Source: round_robin_bracket_generator_service_implementation.dart] — Implementation pattern, pool identifier
- [Source: single_elimination_bracket_generator_service.dart] — Service interface pattern
- [Source: generate_round_robin_bracket_use_case.dart] — Use case pattern, persistence
- [Source: regenerate_bracket_use_case.dart] — Format switch, delegation pattern
- [Source: bracket_generation_bloc.dart] — BLoC integration, format dispatch
- [Source: seeding/bracket_format.dart] — Algorithm-level format enum (needs poolPlay)
- [Source: division_entity.dart] — UI-level format enum (already has poolPlay)
- [Source: 5-14-bracket-generation-ui-integration.md] — Previous story learnings, BLoC pattern

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
