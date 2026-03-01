# Story 5.11: Bracket Regeneration

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an organizer,
I want to regenerate a bracket if participants change,
so that late additions or withdrawals are accommodated (FR31).

## Acceptance Criteria

1. **AC1:** `RegenerateBracketUseCase` accepts `RegenerateBracketParams` containing `divisionId` (String), `participantIds` (List<String>), `bracketFormat` (BracketFormat, default singleElimination), `includeThirdPlaceMatch` (bool, default false), `includeResetMatch` (bool, default **true** — matching `GenerateDoubleEliminationBracketParams` default)
2. **AC2:** Regeneration is blocked if bracket `isFinalized == true` — returns `Left(ValidationFailure(...))`
3. **AC3:** All existing brackets for the division are soft-deleted via `BracketRepository.deleteBracket(id)` before regeneration
4. **AC4:** All matches belonging to each deleted bracket are soft-deleted via `MatchRepository.deleteMatch(id)` for every match returned by `MatchRepository.getMatchesForBracket(bracketId)`
5. **AC5:** After cleanup, the appropriate generator use case is called to create a fresh bracket from current participants:
   - `BracketFormat.singleElimination` → delegates to `GenerateSingleEliminationBracketUseCase`
   - `BracketFormat.doubleElimination` → delegates to `GenerateDoubleEliminationBracketUseCase`
   - `BracketFormat.roundRobin` → delegates to `GenerateRoundRobinBracketUseCase`
6. **AC6:** `RegenerateBracketResult` contains `deletedBracketCount` (int), `deletedMatchCount` (int), and the `generationResult` (the output of the generation use case — `BracketGenerationResult` for single-elim/round-robin or `DoubleEliminationBracketGenerationResult` for double-elim)
7. **AC7:** If no existing brackets are found for the division, regeneration still succeeds (effectively a first-time generation)
8. **AC8:** Validation: `divisionId` must be non-empty, `participantIds` must have ≥ 2 entries, no empty IDs, no duplicate IDs
9. **AC9:** Unit tests verify: finalized bracket blocking, soft-delete of brackets and matches, delegation to correct generator, zero-bracket scenario, all validation checks, **error propagation for every repository/generator failure path**

## Tasks / Subtasks

- [x] Task 1: Create `RegenerateBracketParams` (AC: #1, #8)
  - [x] 1.1 Create `lib/features/bracket/domain/usecases/regenerate_bracket_params.dart`
  - [x] 1.2 Fields: `divisionId` (String), `participantIds` (List\<String\>), `bracketFormat` (BracketFormat, default singleElimination), `includeThirdPlaceMatch` (bool, default false), `includeResetMatch` (bool, default **true** — must match `GenerateDoubleEliminationBracketParams` default)
  - [x] 1.3 Use `@immutable` from `package:flutter/foundation.dart`
- [x] Task 2: Create `RegenerateBracketResult` model (AC: #6)
  - [x] 2.1 Create `lib/features/bracket/domain/entities/regenerate_bracket_result.dart`
  - [x] 2.2 Fields: `deletedBracketCount` (int), `deletedMatchCount` (int), `generationResult` (Object — the appropriate generation result type)
  - [x] 2.3 Manual `==`, `hashCode`, `toString` overrides (no Equatable — this is a simple value class like `BracketGenerationResult`)
- [x] Task 3: Create `RegenerateBracketUseCase` (AC: #1-#8)
  - [x] 3.1 Create `lib/features/bracket/domain/usecases/regenerate_bracket_use_case.dart`
  - [x] 3.2 `@injectable`, extends `UseCase<RegenerateBracketResult, RegenerateBracketParams>`
  - [x] 3.3 Constructor injection: `BracketRepository`, `MatchRepository`, `GenerateSingleEliminationBracketUseCase`, `GenerateDoubleEliminationBracketUseCase`, `GenerateRoundRobinBracketUseCase`
  - [x] 3.4 Implement validation checks (4 checks — see implementation section)
  - [x] 3.5 Implement bracket lookup, finalized check, soft-delete, and re-generation flow
- [x] Task 4: Write use case tests (AC: #9)
  - [x] 4.1 Create `test/features/bracket/domain/usecases/regenerate_bracket_use_case_test.dart`
  - [x] 4.2 Mock: `BracketRepository`, `MatchRepository`, `GenerateSingleEliminationBracketUseCase`, `GenerateDoubleEliminationBracketUseCase`, `GenerateRoundRobinBracketUseCase`
  - [x] 4.3 `registerFallbackValue` for all params types in `setUpAll`
  - [x] 4.4 Minimum 23 test cases (8 validation + 3 finalized + 4 soft-delete + 3 delegation + 5 error propagation)
- [x] Task 5: Run analysis and verify all tests pass
  - [x] 5.1 Run `dart analyze` — zero errors, zero warnings
  - [x] 5.2 Run all tests in `test/features/bracket/domain/usecases/regenerate_bracket_use_case_test.dart` — all pass

## Dev Notes

### ⚠️ Scope Boundary: Use Case Orchestration Only

This story implements the **regeneration orchestration use case** — it coordinates soft-deleting old data and calling existing generators. It does **NOT** modify any existing generator services, repositories, or datasources.

**This story is purely additive — 3 new source files + 1 test file, 0 modified files.**

### Regeneration Flow

```
RegenerateBracketUseCase.call(params)
  │
  ├── 1. Validate inputs (divisionId, participantIds, empty IDs, duplicates)
  │
  ├── 2. Fetch existing brackets: BracketRepository.getBracketsForDivision(divisionId)
  │
  ├── 3. Check finalized: if ANY bracket.isFinalized == true → Left(ValidationFailure)
  │
  ├── 4. Soft-delete old matches (for each bracket):
  │       MatchRepository.getMatchesForBracket(bracketId)
  │       MatchRepository.deleteMatch(matchId) × N   ← calls softDeleteMatch under the hood
  │
  ├── 5. Soft-delete old brackets:
  │       BracketRepository.deleteBracket(bracketId) × N  ← calls softDeleteBracket under the hood
  │
  └── 6. Delegate to generator:
          ├── singleElimination → GenerateSingleEliminationBracketUseCase(params)
          ├── doubleElimination → GenerateDoubleEliminationBracketUseCase(params)
          └── roundRobin → GenerateRoundRobinBracketUseCase(params)
```

### Implementation — Exact Pattern

Follow existing use case patterns from `GenerateSingleEliminationBracketUseCase`.

#### RegenerateBracketParams

```dart
// lib/features/bracket/domain/usecases/regenerate_bracket_params.dart
import 'package:flutter/foundation.dart' show immutable;
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';

/// Parameters for [RegenerateBracketUseCase].
@immutable
class RegenerateBracketParams {
  /// Creates [RegenerateBracketParams].
  const RegenerateBracketParams({
    required this.divisionId,
    required this.participantIds,
    this.bracketFormat = BracketFormat.singleElimination,
    this.includeThirdPlaceMatch = false,
    this.includeResetMatch = true,
  });

  /// Division ID to regenerate brackets for.
  final String divisionId;

  /// Current participant IDs in seed order.
  final List<String> participantIds;

  /// Bracket format to generate.
  final BracketFormat bracketFormat;

  /// Include 3rd place match (single elimination only).
  final bool includeThirdPlaceMatch;

  /// Include reset match (double elimination grand finals only).
  final bool includeResetMatch;
}
```

#### RegenerateBracketResult

```dart
// lib/features/bracket/domain/entities/regenerate_bracket_result.dart
import 'package:flutter/foundation.dart' show immutable;

/// Result of bracket regeneration operation.
///
/// Contains cleanup counts and the new generation result.
@immutable
class RegenerateBracketResult {
  const RegenerateBracketResult({
    required this.deletedBracketCount,
    required this.deletedMatchCount,
    required this.generationResult,
  });

  /// Number of old brackets that were soft-deleted.
  final int deletedBracketCount;

  /// Number of old matches that were soft-deleted.
  final int deletedMatchCount;

  /// Result from the appropriate bracket generator use case.
  /// Type is `BracketGenerationResult` (for single-elimination and round-robin)
  /// or `DoubleEliminationBracketGenerationResult` (for double-elimination).
  /// There is NO separate `RoundRobinBracketGenerationResult` — round robin
  /// reuses `BracketGenerationResult`.
  final Object generationResult;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegenerateBracketResult &&
          runtimeType == other.runtimeType &&
          deletedBracketCount == other.deletedBracketCount &&
          deletedMatchCount == other.deletedMatchCount &&
          generationResult == other.generationResult;

  @override
  int get hashCode =>
      Object.hash(deletedBracketCount, deletedMatchCount, generationResult);

  @override
  String toString() =>
      'RegenerateBracketResult(deletedBrackets: $deletedBracketCount, '
      'deletedMatches: $deletedMatchCount)';
}
```

#### RegenerateBracketUseCase

```dart
// lib/features/bracket/domain/usecases/regenerate_bracket_use_case.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/regenerate_bracket_result.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_round_robin_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_round_robin_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_single_elimination_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_single_elimination_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/regenerate_bracket_params.dart';

/// Use case that orchestrates bracket regeneration.
///
/// Soft-deletes existing brackets and matches for a division,
/// then delegates to the appropriate generator use case to
/// create fresh brackets from the current participant list.
@injectable
class RegenerateBracketUseCase
    extends UseCase<RegenerateBracketResult, RegenerateBracketParams> {
  RegenerateBracketUseCase(
    this._bracketRepository,
    this._matchRepository,
    this._singleEliminationUseCase,
    this._doubleEliminationUseCase,
    this._roundRobinUseCase,
  );

  final BracketRepository _bracketRepository;
  final MatchRepository _matchRepository;
  final GenerateSingleEliminationBracketUseCase _singleEliminationUseCase;
  final GenerateDoubleEliminationBracketUseCase _doubleEliminationUseCase;
  final GenerateRoundRobinBracketUseCase _roundRobinUseCase;

  @override
  Future<Either<Failure, RegenerateBracketResult>> call(
    RegenerateBracketParams params,
  ) async {
    // 1. Validate divisionId
    if (params.divisionId.trim().isEmpty) {
      return const Left(
        ValidationFailure(userFriendlyMessage: 'Division ID is required.'),
      );
    }

    // 2. Validate minimum participants
    if (params.participantIds.length < 2) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage:
              'At least 2 participants are required to generate a bracket.',
        ),
      );
    }

    // 3. Validate no empty participant IDs
    if (params.participantIds.any((id) => id.trim().isEmpty)) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Participant list contains empty IDs.',
        ),
      );
    }

    // 4. Validate no duplicate participant IDs
    final ids = params.participantIds.toSet();
    if (ids.length != params.participantIds.length) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Duplicate participant IDs detected.',
        ),
      );
    }

    // 5. Fetch existing brackets for this division
    final bracketsResult = await _bracketRepository.getBracketsForDivision(
      params.divisionId,
    );

    return bracketsResult.fold(Left.new, (existingBrackets) async {
      // 6. Check if any bracket is finalized
      if (existingBrackets.any((b) => b.isFinalized)) {
        return const Left(
          ValidationFailure(
            userFriendlyMessage:
                'Cannot regenerate: bracket is finalized. '
                'Unlock the bracket before regenerating.',
          ),
        );
      }

      // 7. Soft-delete old matches and brackets
      var deletedMatchCount = 0;
      for (final bracket in existingBrackets) {
        // Get all matches for this bracket
        final matchesResult = await _matchRepository.getMatchesForBracket(
          bracket.id,
        );

        // If fetching matches fails, propagate the failure
        final matchesOrFailure = matchesResult.fold(
          (failure) => failure,
          (matches) => null,
        );
        if (matchesOrFailure != null) {
          return Left(matchesOrFailure);
        }

        final matches = matchesResult.getOrElse((_) => []);

        // Soft-delete each match
        for (final match in matches) {
          final deleteResult = await _matchRepository.deleteMatch(match.id);
          if (deleteResult.isLeft()) {
            return deleteResult.fold(
              Left.new,
              (_) => throw StateError('unreachable'),
            );
          }
        }
        deletedMatchCount += matches.length;

        // Soft-delete the bracket itself
        final bracketDeleteResult = await _bracketRepository.deleteBracket(
          bracket.id,
        );
        if (bracketDeleteResult.isLeft()) {
          return bracketDeleteResult.fold(
            Left.new,
            (_) => throw StateError('unreachable'),
          );
        }
      }

      final deletedBracketCount = existingBrackets.length;

      // 8. Delegate to appropriate generator
      final Either<Failure, Object> generationResult;

      switch (params.bracketFormat) {
        case BracketFormat.singleElimination:
          generationResult = await _singleEliminationUseCase(
            GenerateSingleEliminationBracketParams(
              divisionId: params.divisionId,
              participantIds: params.participantIds,
              includeThirdPlaceMatch: params.includeThirdPlaceMatch,
            ),
          );
        case BracketFormat.doubleElimination:
          generationResult = await _doubleEliminationUseCase(
            GenerateDoubleEliminationBracketParams(
              divisionId: params.divisionId,
              participantIds: params.participantIds,
              includeResetMatch: params.includeResetMatch,
            ),
          );
        case BracketFormat.roundRobin:
          generationResult = await _roundRobinUseCase(
            GenerateRoundRobinBracketParams(
              divisionId: params.divisionId,
              participantIds: params.participantIds,
              // poolIdentifier defaults to 'A' in the params
            ),
          );
      }

      return generationResult.fold(Left.new, (genResult) {
        return Right(
          RegenerateBracketResult(
            deletedBracketCount: deletedBracketCount,
            deletedMatchCount: deletedMatchCount,
            generationResult: genResult,
          ),
        );
      });
    });
  }
}
```

### Existing Code Intelligence

#### BracketEntity Status Model

The `BracketEntity` uses `isFinalized` (bool) as the lock mechanism:
- `isFinalized == false` → bracket can be regenerated (draft/generated state)
- `isFinalized == true` → bracket is locked for live scoring (in-progress/completed state)

**⚠️ There is NO `status` enum on `BracketEntity`.** The epics file mentions "draft" and "generated" status values, but the actual entity uses a simple `isFinalized` boolean. The use case MUST check `isFinalized`, not a status string.

#### Soft-Delete Pattern

Both datasources use soft-delete under the hood:
- `BracketLocalDatasource.deleteBracket(id)` → calls `_database.softDeleteBracket(id)`
- `MatchLocalDatasource.deleteMatch(id)` → calls `_database.softDeleteMatch(id)`

The repository `deleteBracket(String id)` returns `Either<Failure, Unit>`. The use case calls the existing repository APIs — no new datasource or repository methods are needed.

#### No Batch Delete for Matches

The `MatchRepository` has `deleteMatch(String id)` for single match deletion but NO batch delete method. The use case must iterate and delete each match individually. This is safe because match counts per bracket are small (≤ 128 for standard tournaments).

#### Generator Use Case Delegation

The three generator use cases already handle:
- Validation (≥ 2 participants, no empty IDs)
- UUID generation for new bracket IDs
- Bracket + match persistence
- Return of generation result

The `RegenerateBracketUseCase` cleanup logic runs BEFORE delegating, so there's no risk of orphaned data. The generator use cases are completely self-contained.

#### Soft-Delete Filtering Safety

Both `getBracketsForDivision(divisionId)` and `getMatchesForBracket(bracketId)` in the database layer already filter `isDeleted == false`. This means:
- After soft-deleting brackets, calling `getBracketsForDivision` again would NOT return the just-deleted brackets
- After soft-deleting matches, calling `getMatchesForBracket` again would NOT return the just-deleted matches
- The use case does NOT need to add any `isDeleted` filtering — it’s handled at the database layer
- The regeneration flow is safe against double-deletion: even if called twice, the first call soft-deletes, and the second call would find zero brackets

#### BracketFormat Enum

Located at `lib/core/algorithms/seeding/bracket_format.dart`:
```dart
enum BracketFormat {
  singleElimination('single_elimination'),
  doubleElimination('double_elimination'),
  roundRobin('round_robin');

  const BracketFormat(this.value);
  final String value;
}
```

### Existing Params Patterns

Check the existing generator params to ensure exact compatibility:

- `GenerateSingleEliminationBracketParams`: `divisionId`, `participantIds`, `includeThirdPlaceMatch` (default **false**)
- `GenerateDoubleEliminationBracketParams`: `divisionId`, `participantIds`, `includeResetMatch` (default **true** — NOT false)
- `GenerateRoundRobinBracketParams`: `divisionId`, `participantIds`, `poolIdentifier` (default `'A'`)

**⚠️ CRITICAL: `includeResetMatch` defaults to `true`**, not `false`. The `RegenerateBracketParams` must match this default to preserve consistent behavior.

The `RegenerateBracketParams` aggregates all these fields so the correct subset is passed to each generator.

### Testing Patterns

**⚠️ CRITICAL rules from Stories 5.7-5.10:**
- Use case tests: **MOCK** all repositories and delegated use cases using `mocktail`
- `registerFallbackValue` required in `setUpAll` for all params types used with `any()`/`captureAny()`
- Extract result with `result.getOrElse((_) => throw Exception('unexpected'))`
- Check failure with `result.fold((f) => expect(f, isA<ValidationFailure>()), ...)`

#### Use Case Test Skeleton

```dart
// test/features/bracket/domain/usecases/regenerate_bracket_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/double_elimination_bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/regenerate_bracket_result.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_round_robin_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_round_robin_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_single_elimination_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_single_elimination_bracket_use_case.dart';
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

void main() {
  late MockBracketRepository mockBracketRepo;
  late MockMatchRepository mockMatchRepo;
  late MockGenerateSingleEliminationBracketUseCase mockSingleElimUC;
  late MockGenerateDoubleEliminationBracketUseCase mockDoubleElimUC;
  late MockGenerateRoundRobinBracketUseCase mockRoundRobinUC;
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
  });

  setUp(() {
    mockBracketRepo = MockBracketRepository();
    mockMatchRepo = MockMatchRepository();
    mockSingleElimUC = MockGenerateSingleEliminationBracketUseCase();
    mockDoubleElimUC = MockGenerateDoubleEliminationBracketUseCase();
    mockRoundRobinUC = MockGenerateRoundRobinBracketUseCase();
    useCase = RegenerateBracketUseCase(
      mockBracketRepo,
      mockMatchRepo,
      mockSingleElimUC,
      mockDoubleElimUC,
      mockRoundRobinUC,
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers — match existing entity constructors exactly
  // ─────────────────────────────────────────────────────────────────────────

  BracketEntity makeBracket({
    String id = 'bracket-1',
    bool isFinalized = false,
  }) =>
      BracketEntity(
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
  }) =>
      MatchEntity(
        id: id,
        bracketId: bracketId,
        roundNumber: 1,
        matchNumberInRound: 1,
        createdAtTimestamp: DateTime(2026),
        updatedAtTimestamp: DateTime(2026),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Stub helper: set up successful cleanup + single-elim regeneration
  // ─────────────────────────────────────────────────────────────────────────

  void stubSuccessfulRegeneration({
    List<BracketEntity>? existingBrackets,
    Map<String, List<MatchEntity>>? bracketMatches,
  }) {
    final brackets = existingBrackets ?? [];
    when(() => mockBracketRepo.getBracketsForDivision('div1'))
        .thenAnswer((_) async => Right(brackets));

    for (final bracket in brackets) {
      final matches = bracketMatches?[bracket.id] ?? [];
      when(() => mockMatchRepo.getMatchesForBracket(bracket.id))
          .thenAnswer((_) async => Right(matches));
      for (final match in matches) {
        when(() => mockMatchRepo.deleteMatch(match.id))
            .thenAnswer((_) async => const Right(unit));
      }
      when(() => mockBracketRepo.deleteBracket(bracket.id))
          .thenAnswer((_) async => const Right(unit));
    }

    final newBracket = makeBracket(id: 'new-bracket');
    when(() => mockSingleElimUC(any())).thenAnswer(
      (_) async => Right(
        BracketGenerationResult(bracket: newBracket, matches: []),
      ),
    );
  }

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
        const RegenerateBracketParams(
          divisionId: 'div1',
          participantIds: [],
        ),
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
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 2. Finalized bracket blocking
  // ═══════════════════════════════════════════════════════════════════════

  group('Finalized bracket blocking', () {
    test('single finalized bracket → ValidationFailure with "finalized"', () async {
      when(() => mockBracketRepo.getBracketsForDivision('div1'))
          .thenAnswer((_) async => Right([makeBracket(isFinalized: true)]));

      final result = await useCase(validParams);
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) {
          expect(f, isA<ValidationFailure>());
          expect(f.userFriendlyMessage, contains('finalized'));
        },
        (_) => fail('Should have failed'),
      );
      // Should NOT attempt to delete anything
      verifyNever(() => mockMatchRepo.getMatchesForBracket(any()));
      verifyNever(() => mockMatchRepo.deleteMatch(any()));
      verifyNever(() => mockBracketRepo.deleteBracket(any()));
    });

    test('one finalized among multiple → blocks ALL regeneration', () async {
      when(() => mockBracketRepo.getBracketsForDivision('div1'))
          .thenAnswer((_) async => Right([
                makeBracket(id: 'b1', isFinalized: false),
                makeBracket(id: 'b2', isFinalized: true),
              ]));

      final result = await useCase(validParams);
      expect(result.isLeft(), isTrue);
      verifyNever(() => mockMatchRepo.deleteMatch(any()));
    });

    test('non-finalized bracket → proceeds to cleanup and regeneration', () async {
      final bracket = makeBracket();
      final match = makeMatch();

      when(() => mockBracketRepo.getBracketsForDivision('div1'))
          .thenAnswer((_) async => Right([bracket]));
      when(() => mockMatchRepo.getMatchesForBracket('bracket-1'))
          .thenAnswer((_) async => Right([match]));
      when(() => mockMatchRepo.deleteMatch('match-1'))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockBracketRepo.deleteBracket('bracket-1'))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockSingleElimUC(any())).thenAnswer(
        (_) async => Right(
          BracketGenerationResult(bracket: bracket, matches: [match]),
        ),
      );

      final result = await useCase(validParams);
      expect(result.isRight(), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 3. Soft-delete and regeneration
  // ═══════════════════════════════════════════════════════════════════════

  group('Soft-delete and regeneration', () {
    test('deletes all matches and brackets, returns correct counts', () async {
      final bracket = makeBracket();
      final match1 = makeMatch(id: 'm1');
      final match2 = makeMatch(id: 'm2');

      when(() => mockBracketRepo.getBracketsForDivision('div1'))
          .thenAnswer((_) async => Right([bracket]));
      when(() => mockMatchRepo.getMatchesForBracket('bracket-1'))
          .thenAnswer((_) async => Right([match1, match2]));
      when(() => mockMatchRepo.deleteMatch(any()))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockBracketRepo.deleteBracket('bracket-1'))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockSingleElimUC(any())).thenAnswer(
        (_) async => Right(
          BracketGenerationResult(bracket: bracket, matches: [match1]),
        ),
      );

      final result = await useCase(validParams);
      expect(result.isRight(), isTrue);

      result.fold(
        (_) => fail('Should be right'),
        (r) {
          expect(r.deletedBracketCount, equals(1));
          expect(r.deletedMatchCount, equals(2));
          expect(r.generationResult, isA<BracketGenerationResult>());
        },
      );

      // Verify all individual delete calls were made
      verify(() => mockMatchRepo.deleteMatch('m1')).called(1);
      verify(() => mockMatchRepo.deleteMatch('m2')).called(1);
      verify(() => mockBracketRepo.deleteBracket('bracket-1')).called(1);
    });

    test('multiple brackets (e.g., double elim winners+losers) → deletes all', () async {
      final b1 = makeBracket(id: 'winners-bracket');
      final b2 = makeBracket(id: 'losers-bracket');
      final m1 = makeMatch(id: 'w-m1', bracketId: 'winners-bracket');
      final m2 = makeMatch(id: 'l-m1', bracketId: 'losers-bracket');
      final m3 = makeMatch(id: 'l-m2', bracketId: 'losers-bracket');

      when(() => mockBracketRepo.getBracketsForDivision('div1'))
          .thenAnswer((_) async => Right([b1, b2]));
      when(() => mockMatchRepo.getMatchesForBracket('winners-bracket'))
          .thenAnswer((_) async => Right([m1]));
      when(() => mockMatchRepo.getMatchesForBracket('losers-bracket'))
          .thenAnswer((_) async => Right([m2, m3]));
      when(() => mockMatchRepo.deleteMatch(any()))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockBracketRepo.deleteBracket(any()))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockSingleElimUC(any())).thenAnswer(
        (_) async => Right(
          BracketGenerationResult(bracket: b1, matches: []),
        ),
      );

      final result = await useCase(validParams);
      expect(result.isRight(), isTrue);

      result.fold(
        (_) => fail('Should be right'),
        (r) {
          expect(r.deletedBracketCount, equals(2));
          expect(r.deletedMatchCount, equals(3));
        },
      );

      verify(() => mockBracketRepo.deleteBracket('winners-bracket')).called(1);
      verify(() => mockBracketRepo.deleteBracket('losers-bracket')).called(1);
    });

    test('no existing brackets → generates fresh (count 0)', () async {
      final bracket = makeBracket();

      when(() => mockBracketRepo.getBracketsForDivision('div1'))
          .thenAnswer((_) async => const Right([]));
      when(() => mockSingleElimUC(any())).thenAnswer(
        (_) async => Right(
          BracketGenerationResult(bracket: bracket, matches: []),
        ),
      );

      final result = await useCase(validParams);
      expect(result.isRight(), isTrue);

      result.fold(
        (_) => fail('Should be right'),
        (r) {
          expect(r.deletedBracketCount, equals(0));
          expect(r.deletedMatchCount, equals(0));
        },
      );

      // Should never call delete methods
      verifyNever(() => mockMatchRepo.getMatchesForBracket(any()));
      verifyNever(() => mockMatchRepo.deleteMatch(any()));
      verifyNever(() => mockBracketRepo.deleteBracket(any()));
    });

    test('bracket with zero matches → deletes bracket only', () async {
      final bracket = makeBracket();

      when(() => mockBracketRepo.getBracketsForDivision('div1'))
          .thenAnswer((_) async => Right([bracket]));
      when(() => mockMatchRepo.getMatchesForBracket('bracket-1'))
          .thenAnswer((_) async => const Right([]));
      when(() => mockBracketRepo.deleteBracket('bracket-1'))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockSingleElimUC(any())).thenAnswer(
        (_) async => Right(
          BracketGenerationResult(bracket: bracket, matches: []),
        ),
      );

      final result = await useCase(validParams);
      expect(result.isRight(), isTrue);

      result.fold(
        (_) => fail('Should be right'),
        (r) {
          expect(r.deletedBracketCount, equals(1));
          expect(r.deletedMatchCount, equals(0));
        },
      );

      verifyNever(() => mockMatchRepo.deleteMatch(any()));
      verify(() => mockBracketRepo.deleteBracket('bracket-1')).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 4. Generator delegation
  // ═══════════════════════════════════════════════════════════════════════

  group('Generator delegation', () {
    void setupEmptyDivision() {
      when(() => mockBracketRepo.getBracketsForDivision(any()))
          .thenAnswer((_) async => const Right([]));
    }

    test('singleElimination → calls GenerateSingleEliminationBracketUseCase', () async {
      setupEmptyDivision();
      final bracket = makeBracket();
      when(() => mockSingleElimUC(any())).thenAnswer(
        (_) async => Right(
          BracketGenerationResult(bracket: bracket, matches: []),
        ),
      );

      final result = await useCase(validParams);
      expect(result.isRight(), isTrue);

      verify(() => mockSingleElimUC(any())).called(1);
      verifyNever(() => mockDoubleElimUC(any()));
      verifyNever(() => mockRoundRobinUC(any()));
    });

    test('doubleElimination → calls GenerateDoubleEliminationBracketUseCase', () async {
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

      verify(() => mockDoubleElimUC(any())).called(1);
      verifyNever(() => mockSingleElimUC(any()));
      verifyNever(() => mockRoundRobinUC(any()));
    });

    test('roundRobin → calls GenerateRoundRobinBracketUseCase', () async {
      setupEmptyDivision();
      final bracket = makeBracket();
      when(() => mockRoundRobinUC(any())).thenAnswer(
        (_) async => Right(
          BracketGenerationResult(bracket: bracket, matches: []),
        ),
      );

      final result = await useCase(
        const RegenerateBracketParams(
          divisionId: 'div1',
          participantIds: ['p1', 'p2', 'p3'],
          bracketFormat: BracketFormat.roundRobin,
        ),
      );
      expect(result.isRight(), isTrue);

      verify(() => mockRoundRobinUC(any())).called(1);
      verifyNever(() => mockSingleElimUC(any()));
      verifyNever(() => mockDoubleElimUC(any()));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 5. Error propagation — repository/generator failures
  // ═══════════════════════════════════════════════════════════════════════

  group('Error propagation', () {
    test('getBracketsForDivision fails → propagates failure', () async {
      when(() => mockBracketRepo.getBracketsForDivision('div1'))
          .thenAnswer((_) async => const Left(LocalCacheAccessFailure()));

      final result = await useCase(validParams);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<LocalCacheAccessFailure>()),
        (_) => fail('Should have failed'),
      );
    });

    test('getMatchesForBracket fails → propagates failure', () async {
      when(() => mockBracketRepo.getBracketsForDivision('div1'))
          .thenAnswer((_) async => Right([makeBracket()]));
      when(() => mockMatchRepo.getMatchesForBracket('bracket-1'))
          .thenAnswer((_) async => const Left(LocalCacheAccessFailure()));

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

      when(() => mockBracketRepo.getBracketsForDivision('div1'))
          .thenAnswer((_) async => Right([makeBracket()]));
      when(() => mockMatchRepo.getMatchesForBracket('bracket-1'))
          .thenAnswer((_) async => Right([m1, m2]));
      when(() => mockMatchRepo.deleteMatch('m1'))
          .thenAnswer((_) async => const Left(LocalCacheWriteFailure()));

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
      when(() => mockBracketRepo.getBracketsForDivision('div1'))
          .thenAnswer((_) async => Right([makeBracket()]));
      when(() => mockMatchRepo.getMatchesForBracket('bracket-1'))
          .thenAnswer((_) async => const Right([]));
      when(() => mockBracketRepo.deleteBracket('bracket-1'))
          .thenAnswer((_) async => const Left(LocalCacheWriteFailure()));

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
      when(() => mockBracketRepo.getBracketsForDivision('div1'))
          .thenAnswer((_) async => const Right([]));
      when(() => mockSingleElimUC(any())).thenAnswer(
        (_) async => const Left(
          BracketGenerationFailure(
            userFriendlyMessage: 'Generation failed',
          ),
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
```

**⚠️ CRITICAL TEST PATTERN NOTES (from existing tests in this codebase):**
- Use `fail('Should have failed')` as the wrong-branch handler in `fold()`, NOT `throw Exception('unexpected')` — matches `generate_single_elimination_bracket_use_case_test.dart` pattern
- Use `result.fold((l) => fail('Should be right'), (r) { ... })` to extract right value for assertions
- Use `verifyNever()` to assert methods that should NOT be called (e.g., generator after delete failure)
- Use `verifyZeroInteractions(mock)` when appropriate — e.g., validation failures should never touch repos
- `DoubleEliminationBracketGenerationResult` requires: `winnersBracket`, `losersBracket`, `grandFinalsMatch` (MatchEntity), `allMatches` (List<MatchEntity>), optional `resetMatch` (MatchEntity?)
- `BracketGenerationResult` requires: `bracket` (BracketEntity), `matches` (List<MatchEntity>) — used for BOTH single-elim AND round-robin

### ⚠️ Common LLM Mistakes — Prevention Rules

| #   | Mistake                                                             | Correct Approach                                                                                                                        |
| --- | ------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Checking a `bracket.status` string field                            | `BracketEntity` has `isFinalized` (bool), **NOT** a status enum — check `isFinalized == true`                                           |
| 2   | Adding a `deleteMatchesForBracket` method to MatchRepository        | NO new repository methods — iterate with existing `getMatchesForBracket` + `deleteMatch` per ID                                         |
| 3   | Hard-deleting brackets/matches                                      | Both use **soft-delete** under the hood (`softDeleteBracket`, `softDeleteMatch`) via existing repository methods                        |
| 4   | Modifying any existing files                                        | NO modifications — this story creates 3 source files + 1 test file only                                                                 |
| 5   | Creating a new service (e.g., RegenerateBracketService)             | This is a **use case** only — orchestration logic lives in the use case, no service needed                                              |
| 6   | Importing infrastructure packages in domain layer                   | UseCase can ONLY import domain and core packages — no `drift`, `supabase`, etc.                                                         |
| 7   | Making `generationResult` strongly typed in RegenerateBracketResult | Use `Object` — the result type varies by bracket format. The caller knows which format was requested                                    |
| 8   | Forgetting `registerFallbackValue` for ALL params types in tests    | Need fallback values for: `RegenerateBracketParams`, all 3 generator params types                                                       |
| 9   | Using `Equatable` on new result class                               | Existing `BracketGenerationResult` uses manual `==`/`hashCode` — follow same pattern                                                    |
| 10  | Not checking `getBracketsForDivision` Either result                 | Repository returns `Either<Failure, List<BracketEntity>>` — must fold, not assume success                                               |
| 11  | Setting `includeResetMatch` default to `false`                      | Must be `true` — matches `GenerateDoubleEliminationBracketParams` default. Otherwise double-elim regeneration silently changes behavior |
| 12  | Using `RoundRobinBracketGenerationResult` as a type                 | This class does NOT exist — round robin uses `BracketGenerationResult`, same as single-elimination                                      |
| 13  | Using `throw Exception('unexpected')` in test fold assertions       | Use `fail('Should have failed')` — matches existing test pattern in `generate_single_elimination_bracket_use_case_test.dart`            |
| 14  | Adding `isDeleted` filtering logic in the use case                  | The database layer ALREADY filters `isDeleted == false` in `getBracketsForDivision` and `getMatchesForBracket`                          |
| 15  | Skipping error propagation tests for repo/generator failures        | MUST test: getBracketsForDivision fails, getMatchesForBracket fails, deleteMatch fails, deleteBracket fails, generator fails            |

### Key Differences from Previous Stories

| Aspect         | Stories 5.4-5.6 (Generators) | Stories 5.7-5.10 (Seeding/Bye) | **Story 5.11 (Regeneration)**            |
| -------------- | ---------------------------- | ------------------------------ | ---------------------------------------- |
| Purpose        | Create brackets              | Seed/optimize participants     | **Cleanup + re-create brackets**         |
| Layer          | Domain use case              | Core algorithms                | **Domain use case**                      |
| Dependencies   | Service + Repos + Uuid       | Service (or none)              | **Repos + 3 existing use cases**         |
| New files      | Service + UseCase + Params   | Models + Service + UC + Params | **UseCase + Params + Result (3 files)**  |
| Modified files | None                         | None                           | **None**                                 |
| Feature path   | `features/bracket/domain/`   | `core/algorithms/seeding/`     | **`features/bracket/domain/`**           |
| Uses Uuid      | Yes                          | No                             | **No (generators handle UUID creation)** |

### Performance Notes

- Bracket regeneration involves:
  - 1 read: `getBracketsForDivision` (typically 1-2 brackets)
  - N reads + N deletes for matches (N = match count per bracket, ≤ 127 for 128 participants)
  - 1-2 deletes for brackets
  - 1 generator call (existing, already performance-tested)
- Total: dominated by the generator call which is already < 500ms (NFR2)
- No new performance constraints beyond existing NFR2

### Previous Story Intelligence

Learnings from Stories 5.4-5.10 that impact this story:

1. **Use case pattern**: `RegenerateBracketUseCase` follows `GenerateSingleEliminationBracketUseCase` pattern — `@injectable`, async `call`, `Either<Failure, T>` return
2. **Repository patterns**: Both `BracketRepository` and `MatchRepository` interfaces are in `domain/repositories/` — use case depends on interfaces only (Clean Architecture)
3. **Test pattern**: Mock all dependencies including other use cases. Use `registerFallbackValue` for every params type touched by `any()`
4. **`isFinalized` is the lock**: There's no `status` field or enum on `BracketEntity` — the lock/unlock from story 5.12 will set `isFinalized` to true/false
5. **Soft delete is the standard**: `deleteBracket` and `deleteMatch` both perform soft-delete internally

### Git Intelligence

Recent commits on bracket generation:
- `4bfff31` — Story 5.10 (Bye assignment algorithm)
- `b578d00` — Story 5.9 (Manual seed override)
- `eed1a0a` — Story 5.8 (Regional separation seeding)
- `08a798c` — Story 5.7 (Dojang separation seeding algorithm)
- `eb1f705` — Story 5.6 (Round robin bracket generator)

All follow Clean Architecture pattern. Generator use cases are in `lib/features/bracket/domain/usecases/`.

### Project Structure Notes

**New Files (3 source + 1 test = 4 total):**
```
lib/features/bracket/domain/
├── entities/
│   └── regenerate_bracket_result.dart       ← NEW
└── usecases/
    ├── regenerate_bracket_params.dart        ← NEW
    └── regenerate_bracket_use_case.dart      ← NEW

test/features/bracket/domain/usecases/
└── regenerate_bracket_use_case_test.dart     ← NEW (1 test file)
```

**Existing directories (all exist — no need to create):**
- `lib/features/bracket/domain/entities/` — has `bracket_entity.dart`, `bracket_generation_result.dart`, `double_elimination_bracket_generation_result.dart`, `match_entity.dart`
- `lib/features/bracket/domain/usecases/` — has all 3 generator use cases + params
- `test/features/bracket/domain/usecases/` — has existing test files

**No modified files** — this story is purely additive.

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Story 5.11 section, lines 1868-1884]
- [Source: `_bmad-output/planning-artifacts/epics.md` — FR31: Regenerate bracket, line 270]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Clean Architecture dependency rules, lines 235-270]
- [Source: `lib/features/bracket/domain/entities/bracket_entity.dart` — BracketEntity with isFinalized field, line 15]
- [Source: `lib/features/bracket/domain/repositories/bracket_repository.dart` — BracketRepository interface]
- [Source: `lib/features/bracket/domain/repositories/match_repository.dart` — MatchRepository interface]
- [Source: `lib/features/bracket/domain/usecases/generate_single_elimination_bracket_use_case.dart` — Generator UC pattern]
- [Source: `lib/features/bracket/domain/usecases/generate_double_elimination_bracket_use_case.dart` — Double elim generator pattern]
- [Source: `lib/features/bracket/data/datasources/bracket_local_datasource.dart` — softDeleteBracket call, line 43]
- [Source: `lib/features/bracket/data/datasources/match_local_datasource.dart` — softDeleteMatch call, line 64]
- [Source: `lib/core/algorithms/seeding/bracket_format.dart` — BracketFormat enum]
- [Source: `lib/core/usecases/use_case.dart` — UseCase base class]
- [Source: `lib/core/error/failures.dart` — ValidationFailure class]
- [Source: `_bmad-output/implementation-artifacts/5-10-bye-assignment-algorithm.md` — Previous story template reference]

## Dev Agent Record

### Agent Model Used

Antigravity (Google Deepmind)

### Debug Log References

None — clean implementation with zero analysis errors and all tests passing on first run.

### Completion Notes List

- ✅ Task 1: Created `RegenerateBracketParams` with all fields matching story spec. `includeResetMatch` correctly defaults to `true` matching `GenerateDoubleEliminationBracketParams`.
- ✅ Task 2: Created `RegenerateBracketResult` with manual `==`, `hashCode`, `toString` overrides (no Equatable). `generationResult` typed as `Object` to support both `BracketGenerationResult` and `DoubleEliminationBracketGenerationResult`.
- ✅ Task 3: Created `RegenerateBracketUseCase` with `@injectable` annotation. Implements full flow: validation → fetch brackets → finalized check → soft-delete matches → soft-delete brackets → delegate to correct generator. All error paths propagate failures correctly.
- ✅ Task 4: 23 test cases covering: 8 validation (empty/whitespace divisionId, <2 participants, zero participants, empty/whitespace participant IDs, duplicates, validation order), 3 finalized blocking (single finalized, mixed finalized, non-finalized proceeds), 4 soft-delete (correct counts, multiple brackets, zero brackets fresh gen, zero matches), 3 delegation (single/double/round-robin), 5 error propagation (getBracketsForDivision, getMatchesForBracket, deleteMatch, deleteBracket, generator failure).
- ✅ Task 5: `dart analyze` — 0 errors, 0 warnings. All 23 new tests pass. Full regression suite: 1501 tests all pass.

### Change Log

- 2026-03-01: Story 5.11 implementation complete — 3 new source files + 1 test file, 0 modified files.

### File List

- `lib/features/bracket/domain/usecases/regenerate_bracket_params.dart` — NEW
- `lib/features/bracket/domain/entities/regenerate_bracket_result.dart` — NEW
- `lib/features/bracket/domain/usecases/regenerate_bracket_use_case.dart` — NEW
- `test/features/bracket/domain/usecases/regenerate_bracket_use_case_test.dart` — NEW
