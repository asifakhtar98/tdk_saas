# Story 5.12: Bracket Lock & Unlock

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an organizer,
I want to lock a bracket to prevent accidental changes during live competition, and unlock it when adjustments are needed,
so that live competition isn't disrupted by accidental bracket modifications (FR31, FR32).

## Acceptance Criteria

1. **AC1:** `LockBracketUseCase` accepts `LockBracketParams` containing `bracketId` (String) and returns `Either<Failure, BracketEntity>` with the updated bracket where `isFinalized == true` and `finalizedAtTimestamp` is set to current time.
2. **AC2:** Locking is blocked if the bracket is already finalized (`isFinalized == true`) — returns `Left(ValidationFailure(...))` with message containing "already locked" or "already finalized".
3. **AC3:** Locking validates that `bracketId` is non-empty (trimmed) — returns `Left(ValidationFailure(...))` if empty/whitespace-only.
4. **AC4:** Locking fetches the bracket via `BracketRepository.getBracketById(bracketId)` — propagates any repository failures (including `NotFoundFailure` when bracket ID doesn't exist and `LocalCacheAccessFailure` when database read fails).
5. **AC5:** Locking updates the bracket via `BracketRepository.updateBracket(bracket.copyWith(isFinalized: true, finalizedAtTimestamp: <now>))` — propagates any repository failures.
6. **AC6:** `UnlockBracketUseCase` accepts `UnlockBracketParams` containing `bracketId` (String) and returns `Either<Failure, BracketEntity>` with the updated bracket where `isFinalized == false` and `finalizedAtTimestamp` is set to `null`.
7. **AC7:** Unlocking is blocked if the bracket is NOT finalized (`isFinalized == false`) — returns `Left(ValidationFailure(...))` with message containing "not locked" or "not finalized".
8. **AC8:** Unlocking validates that `bracketId` is non-empty (trimmed) — returns `Left(ValidationFailure(...))` if empty/whitespace-only.
9. **AC9:** Unlocking fetches the bracket via `BracketRepository.getBracketById(bracketId)` — propagates any repository failures (including `NotFoundFailure` when bracket ID doesn't exist and `LocalCacheAccessFailure` when database read fails).
10. **AC10:** Unlocking updates the bracket via `BracketRepository.updateBracket(bracket.copyWith(isFinalized: false, finalizedAtTimestamp: null))` — propagates any repository failures.
11. **AC11:** Unit tests verify: lock validation (empty, whitespace), lock success with timestamp verification, lock-when-already-locked, lock error propagation (get-not-found, get-cache-fails, update fails), unlock validation (empty, whitespace), unlock success with null-timestamp verification, unlock-when-not-locked, unlock error propagation (get-not-found, get-cache-fails, update fails).

## Tasks / Subtasks

- [x] Task 1: Create `LockBracketParams` (AC: #1, #3)
  - [x] 1.1 Create `lib/features/bracket/domain/usecases/lock_bracket_params.dart`
  - [x] 1.2 Fields: `bracketId` (String)
  - [x] 1.3 Use `@immutable` from `package:flutter/foundation.dart`
- [x] Task 2: Create `LockBracketUseCase` (AC: #1-#5)
  - [x] 2.1 Create `lib/features/bracket/domain/usecases/lock_bracket_use_case.dart`
  - [x] 2.2 `@injectable`, extends `UseCase<BracketEntity, LockBracketParams>`
  - [x] 2.3 Constructor injection: `BracketRepository`
  - [x] 2.4 Implement validation (bracketId non-empty), fetch bracket, check not already finalized, update with `isFinalized: true` and `finalizedAtTimestamp: DateTime.now()`
- [x] Task 3: Create `UnlockBracketParams` (AC: #6, #8)
  - [x] 3.1 Create `lib/features/bracket/domain/usecases/unlock_bracket_params.dart`
  - [x] 3.2 Fields: `bracketId` (String)
  - [x] 3.3 Use `@immutable` from `package:flutter/foundation.dart`
- [x] Task 4: Create `UnlockBracketUseCase` (AC: #6-#10)
  - [x] 4.1 Create `lib/features/bracket/domain/usecases/unlock_bracket_use_case.dart`
  - [x] 4.2 `@injectable`, extends `UseCase<BracketEntity, UnlockBracketParams>`
  - [x] 4.3 Constructor injection: `BracketRepository`
  - [x] 4.4 Implement validation (bracketId non-empty), fetch bracket, check IS finalized, update with `isFinalized: false` and `finalizedAtTimestamp: null`
- [x] Task 5: Write LockBracketUseCase tests (AC: #11)
  - [x] 5.1 Create `test/features/bracket/domain/usecases/lock_bracket_use_case_test.dart`
  - [x] 5.2 Mock: `BracketRepository`
  - [x] 5.3 `registerFallbackValue` for `LockBracketParams` AND `BracketEntity` in `setUpAll`
  - [x] 5.4 Minimum 8 test cases: 2 validation (empty, whitespace bracketId) + 1 already-finalized + 1 success (isFinalized=true, timestamp set) + 1 success-verifies-captured-entity + 3 error propagation (getBracketById returns NotFoundFailure, getBracketById returns LocalCacheAccessFailure, updateBracket returns LocalCacheWriteFailure)
- [x] Task 6: Write UnlockBracketUseCase tests (AC: #11)
  - [x] 6.1 Create `test/features/bracket/domain/usecases/unlock_bracket_use_case_test.dart`
  - [x] 6.2 Mock: `BracketRepository`
  - [x] 6.3 `registerFallbackValue` for `UnlockBracketParams` AND `BracketEntity` in `setUpAll`
  - [x] 6.4 Minimum 8 test cases: 2 validation (empty, whitespace bracketId) + 1 not-finalized + 1 success (isFinalized=false, timestamp null) + 1 success-verifies-captured-entity + 3 error propagation (getBracketById returns NotFoundFailure, getBracketById returns LocalCacheAccessFailure, updateBracket returns LocalCacheWriteFailure)
- [x] Task 7: Run analysis and verify all tests pass
  - [x] 7.1 Run `dart analyze` — zero errors, zero warnings
  - [x] 7.2 Run all new tests — all pass
  - [x] 7.3 Run full test suite — all pass (regression check)

## Dev Notes

### ⚠️ Scope Boundary: Two Simple Use Cases Only

This story implements **two independent use cases** — `LockBracketUseCase` and `UnlockBracketUseCase`. Each one fetches a bracket, validates its current state, and updates the `isFinalized` field. **No new repository methods, services, or datasource changes are needed.**

**This story is purely additive — 4 new source files + 2 test files, 0 modified files.**

### ⚠️ What This Story Does NOT Do

- **Does NOT add lock-checking guards to other use cases.** Other use cases (like `RegenerateBracketUseCase`) already check `isFinalized` independently. This story only provides the mechanism to toggle the flag.
- **Does NOT add UI** — the bracket visualization UI (Story 5.13) will consume these use cases.
- **Does NOT modify participant, seeding, or scoring use cases** — those epics (6+) will add their own `isFinalized` checks as needed.
- **Does NOT handle multi-bracket operations** (e.g., locking all brackets for a division at once) — each bracket is locked/unlocked individually by ID.

### Business Rule Enforcement: What Lock/Unlock Controls

When a bracket is **locked** (`isFinalized == true`):
- ✅ Scoring and match progression **ARE allowed** (Epic 6 use cases will permit this)
- ❌ Participant additions/removals to the division **ARE blocked** (future stories enforce this)
- ❌ Seeding changes **ARE blocked** (future stories enforce this)
- ❌ Bracket regeneration **IS blocked** (Story 5.11 `RegenerateBracketUseCase` already enforces this)

When a bracket is **unlocked** (`isFinalized == false`):
- ✅ All bracket modifications are allowed
- ⚠️ Unlocking during live competition should show a warning to the user (presentation concern, not domain)

### Lock/Unlock Flow

```
LockBracketUseCase.call(params)
  │
  ├── 1. Validate bracketId (non-empty after trim)
  │
  ├── 2. Fetch bracket: BracketRepository.getBracketById(bracketId)
  │
  ├── 3. Check NOT finalized: if bracket.isFinalized → Left(ValidationFailure)
  │
  └── 4. Update bracket: BracketRepository.updateBracket(
  │       bracket.copyWith(isFinalized: true, finalizedAtTimestamp: DateTime.now())
  │     )
  │
  └── 5. Return updated BracketEntity

UnlockBracketUseCase.call(params)
  │
  ├── 1. Validate bracketId (non-empty after trim)
  │
  ├── 2. Fetch bracket: BracketRepository.getBracketById(bracketId)
  │
  ├── 3. Check IS finalized: if !bracket.isFinalized → Left(ValidationFailure)
  │
  └── 4. Update bracket: BracketRepository.updateBracket(
  │       bracket.copyWith(isFinalized: false, finalizedAtTimestamp: null)
  │     )
  │
  └── 5. Return updated BracketEntity
```

### Implementation — Exact Pattern

Follow existing use case patterns from `RegenerateBracketUseCase` (Story 5.11).

**⚠️ `fold` with async callback pattern:** The use cases use `bracketResult.fold(Left.new, (bracket) async { ... })`. This works because `fpdart`'s `Either.fold` accepts `FutureOr` return types. The `Left.new` tear-off constructor wraps the failure into a new `Left`. The `RegenerateBracketUseCase` uses this exact same pattern (line 84 of `regenerate_bracket_use_case.dart`). Do NOT rewrite this as a `switch` or `if/else` — the `fold` pattern is the project standard.

#### LockBracketParams

```dart
// lib/features/bracket/domain/usecases/lock_bracket_params.dart
import 'package:flutter/foundation.dart' show immutable;

/// Parameters for [LockBracketUseCase].
@immutable
class LockBracketParams {
  /// Creates [LockBracketParams].
  const LockBracketParams({required this.bracketId});

  /// The bracket ID to lock (finalize).
  final String bracketId;
}
```

#### LockBracketUseCase

```dart
// lib/features/bracket/domain/usecases/lock_bracket_use_case.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/lock_bracket_params.dart';

/// Use case that locks (finalizes) a bracket to prevent accidental changes
/// during live competition.
///
/// Sets `isFinalized = true` and records `finalizedAtTimestamp`.
/// Blocks participant additions/removals, seeding changes, and regeneration
/// while locked. Scoring and match progression remain allowed.
@injectable
class LockBracketUseCase
    extends UseCase<BracketEntity, LockBracketParams> {
  LockBracketUseCase(this._bracketRepository);

  final BracketRepository _bracketRepository;

  @override
  Future<Either<Failure, BracketEntity>> call(
    LockBracketParams params,
  ) async {
    // 1. Validate bracketId
    if (params.bracketId.trim().isEmpty) {
      return const Left(
        ValidationFailure(userFriendlyMessage: 'Bracket ID is required.'),
      );
    }

    // 2. Fetch the bracket
    final bracketResult = await _bracketRepository.getBracketById(
      params.bracketId,
    );

    return bracketResult.fold(Left.new, (bracket) async {
      // 3. Check not already finalized
      if (bracket.isFinalized) {
        return const Left(
          ValidationFailure(
            userFriendlyMessage:
                'Bracket is already locked (finalized). '
                'No action needed.',
          ),
        );
      }

      // 4. Update with isFinalized = true
      final updatedBracket = bracket.copyWith(
        isFinalized: true,
        finalizedAtTimestamp: DateTime.now(),
      );

      return _bracketRepository.updateBracket(updatedBracket);
    });
  }
}
```

#### UnlockBracketParams

```dart
// lib/features/bracket/domain/usecases/unlock_bracket_params.dart
import 'package:flutter/foundation.dart' show immutable;

/// Parameters for [UnlockBracketUseCase].
@immutable
class UnlockBracketParams {
  /// Creates [UnlockBracketParams].
  const UnlockBracketParams({required this.bracketId});

  /// The bracket ID to unlock (un-finalize).
  final String bracketId;
}
```

#### UnlockBracketUseCase

```dart
// lib/features/bracket/domain/usecases/unlock_bracket_use_case.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/unlock_bracket_params.dart';

/// Use case that unlocks (un-finalizes) a bracket to allow modifications.
///
/// Sets `isFinalized = false` and clears `finalizedAtTimestamp`.
/// After unlocking, participant additions/removals, seeding changes,
/// and regeneration are allowed again.
@injectable
class UnlockBracketUseCase
    extends UseCase<BracketEntity, UnlockBracketParams> {
  UnlockBracketUseCase(this._bracketRepository);

  final BracketRepository _bracketRepository;

  @override
  Future<Either<Failure, BracketEntity>> call(
    UnlockBracketParams params,
  ) async {
    // 1. Validate bracketId
    if (params.bracketId.trim().isEmpty) {
      return const Left(
        ValidationFailure(userFriendlyMessage: 'Bracket ID is required.'),
      );
    }

    // 2. Fetch the bracket
    final bracketResult = await _bracketRepository.getBracketById(
      params.bracketId,
    );

    return bracketResult.fold(Left.new, (bracket) async {
      // 3. Check IS finalized (can't unlock what isn't locked)
      if (!bracket.isFinalized) {
        return const Left(
          ValidationFailure(
            userFriendlyMessage:
                'Bracket is not locked (not finalized). '
                'Cannot unlock a bracket that is not locked.',
          ),
        );
      }

      // 4. Update with isFinalized = false, clear timestamp
      final updatedBracket = bracket.copyWith(
        isFinalized: false,
        finalizedAtTimestamp: null,
      );

      return _bracketRepository.updateBracket(updatedBracket);
    });
  }
}
```

### Existing Code Intelligence

#### BracketEntity — The Lock Mechanism

The `BracketEntity` uses `isFinalized` (bool) as the lock mechanism with `finalizedAtTimestamp` recording when:
- `isFinalized == false` → bracket is unlocked (draft/generated state) — changes allowed
- `isFinalized == true` → bracket is locked for live scoring — changes blocked

**⚠️ There is NO `status` enum on `BracketEntity`.** The entity uses a `isFinalized` boolean field. The use cases MUST use `copyWith(isFinalized: ...)`, NOT set a status string.

From `bracket_entity.dart`:
```dart
@freezed
class BracketEntity with _$BracketEntity {
  const factory BracketEntity({
    required String id,
    required String divisionId,
    required BracketType bracketType,
    required int totalRounds,
    required DateTime createdAtTimestamp,
    required DateTime updatedAtTimestamp,
    String? poolIdentifier,
    @Default(false) bool isFinalized,       // ← THE LOCK FIELD
    DateTime? generatedAtTimestamp,
    DateTime? finalizedAtTimestamp,          // ← LOCK TIMESTAMP
    Map<String, dynamic>? bracketDataJson,
    @Default(1) int syncVersion,
    @Default(false) bool isDeleted,
    DateTime? deletedAtTimestamp,
    @Default(false) bool isDemoData,
  }) = _BracketEntity;

  const BracketEntity._();  // ← PRIVATE CONSTRUCTOR (enables custom methods)
}

/// Bracket type — winners/losers for elimination, pool for round robin.
enum BracketType {
  winners('winners'),
  losers('losers'),
  pool('pool');

  const BracketType(this.value);
  final String value;

  static BracketType fromString(String value) {
    return BracketType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => BracketType.winners,
    );
  }
}
```

**⚠️ IMPORTANT:** `BracketType` is defined in the SAME file as `BracketEntity` (`bracket_entity.dart`). Tests only need `import '...bracket_entity.dart'` to access both `BracketEntity` and `BracketType`. Do NOT create a separate import for `BracketType`.

#### BracketRepository Interface

The repository already has `getBracketById` and `updateBracket` — the **complete** interface:
```dart
/// Repository interface for bracket operations.
abstract class BracketRepository {
  Future<Either<Failure, List<BracketEntity>>> getBracketsForDivision(
    String divisionId,
  );
  Future<Either<Failure, BracketEntity>> getBracketById(String id);       // ← USED BY THIS STORY
  Future<Either<Failure, BracketEntity>> createBracket(BracketEntity bracket);
  Future<Either<Failure, BracketEntity>> updateBracket(BracketEntity bracket);  // ← USED BY THIS STORY
  Future<Either<Failure, Unit>> deleteBracket(String id);
}
```

**⚠️ CRITICAL:** This is the COMPLETE interface — all 5 methods. Do NOT add any new methods. This story only uses `getBracketById` and `updateBracket`.

**The `updateBracket` method in `BracketRepositoryImplementation`:**
- Reads current `syncVersion`, increments it
- Creates `BracketModel` from the updated entity
- Updates local datasource
- Attempts remote update if connected (non-blocking)
- Returns `Either<Failure, BracketEntity>`

**⚠️ CRITICAL:** The `updateBracket` method handles `syncVersion` incrementing automatically. The use case does NOT need to manually increment it — just call `updateBracket` with the `copyWith` result.

**⚠️ CRITICAL:** The use case does NOT need to set `updatedAtTimestamp` manually. The `updateBracket` flow in the repository creates a `BracketModel` from the entity, and the datasource layer handles updating the timestamp in the database. The `updatedAtTimestamp` on the entity passed to `updateBracket` is the OLD timestamp — the database/datasource will overwrite it with `NOW()` on write.

#### getBracketById Failure Paths

`BracketRepositoryImplementation.getBracketById(id)` can return three different failure types:
1.  **`NotFoundFailure`** — When the bracket ID doesn't exist locally AND remotely (or offline). This is the **most common real-world error path** (e.g., invalid UUID passed by UI).
2.  **`LocalCacheAccessFailure`** — When the local database read throws an exception.
3.  **Success** — `Right(BracketEntity)` when found.

Tests MUST cover both `NotFoundFailure` and `LocalCacheAccessFailure` propagation.

#### How Lock/Unlock Affects Other Use Cases

Story 5.11 (`RegenerateBracketUseCase`) already checks `isFinalized`:
```dart
if (existingBrackets.any((b) => b.isFinalized)) {
  return const Left(ValidationFailure(
    userFriendlyMessage: 'Cannot regenerate: bracket is finalized. '
        'Unlock the bracket before regenerating.',
  ));
}
```

This means **locking a bracket automatically prevents regeneration** — no additional code changes needed in other use cases.

#### freezed `copyWith` Behavior

`BracketEntity` is a `@freezed` class, so `copyWith` correctly handles nullable fields:
- `bracket.copyWith(isFinalized: true, finalizedAtTimestamp: DateTime.now())` → sets both
- `bracket.copyWith(isFinalized: false, finalizedAtTimestamp: null)` → sets `isFinalized` to false AND clears the timestamp to null

**⚠️ IMPORTANT:** With `freezed`, to set a nullable field to `null`, you pass `null` directly. `copyWith(finalizedAtTimestamp: null)` correctly sets the field to `null`.

### Testing Patterns

**⚠️ CRITICAL rules from Stories 5.7-5.11:**
- Use case tests: **MOCK** `BracketRepository` using `mocktail`
- `registerFallbackValue` required in `setUpAll` for params types used with `any()`
- Use `fail('Should have failed')` in the wrong-branch handler of `fold()`, NOT `throw Exception('unexpected')`
- Use `result.fold((l) => fail('Should be right'), (r) { ... })` to extract right value
- Use `verifyNever()` to assert methods that should NOT be called (e.g., `updateBracket` NOT called after get fails)
- Check `isFinalized` and `finalizedAtTimestamp` on the returned entity for success cases
- Test BOTH `NotFoundFailure` AND `LocalCacheAccessFailure` for `getBracketById` error propagation
- Test `LocalCacheWriteFailure` for `updateBracket` error propagation

#### Lock Use Case Test Skeleton

```dart
// test/features/bracket/domain/usecases/lock_bracket_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/lock_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/lock_bracket_use_case.dart';

class MockBracketRepository extends Mock implements BracketRepository {}

void main() {
  late MockBracketRepository mockBracketRepo;
  late LockBracketUseCase useCase;

  setUpAll(() {
    registerFallbackValue(const LockBracketParams(bracketId: 'b1'));
    // Must also register fallback for BracketEntity since updateBracket takes it
    registerFallbackValue(
      BracketEntity(
        id: 'b1',
        divisionId: 'div1',
        bracketType: BracketType.winners,
        totalRounds: 3,
        createdAtTimestamp: DateTime(2026),
        updatedAtTimestamp: DateTime(2026),
      ),
    );
  });

  setUp(() {
    mockBracketRepo = MockBracketRepository();
    useCase = LockBracketUseCase(mockBracketRepo);
  });

  BracketEntity makeBracket({
    String id = 'bracket-1',
    bool isFinalized = false,
    DateTime? finalizedAtTimestamp,
  }) =>
      BracketEntity(
        id: id,
        divisionId: 'div1',
        bracketType: BracketType.winners,
        totalRounds: 3,
        createdAtTimestamp: DateTime(2026),
        updatedAtTimestamp: DateTime(2026),
        isFinalized: isFinalized,
        finalizedAtTimestamp: finalizedAtTimestamp,
      );

  const validParams = LockBracketParams(bracketId: 'bracket-1');

  // ═════════════════════════════════════════════════════════════════════
  // 1. Validation
  // ═════════════════════════════════════════════════════════════════════

  group('Validation', () {
    test('empty bracketId → ValidationFailure', () async {
      final result = await useCase(
        const LockBracketParams(bracketId: ''),
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.getBracketById(any()));
    });

    test('whitespace-only bracketId → ValidationFailure', () async {
      final result = await useCase(
        const LockBracketParams(bracketId: '   '),
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.getBracketById(any()));
    });
  });

  // ═════════════════════════════════════════════════════════════════════
  // 2. Already finalized
  // ═════════════════════════════════════════════════════════════════════

  group('Already finalized', () {
    test('already finalized bracket → ValidationFailure with "already locked"', () async {
      when(() => mockBracketRepo.getBracketById('bracket-1'))
          .thenAnswer((_) async => Right(makeBracket(isFinalized: true)));

      final result = await useCase(validParams);
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) {
          expect(f, isA<ValidationFailure>());
          expect(f.userFriendlyMessage, contains('already'));
        },
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.updateBracket(any()));
    });
  });

  // ═════════════════════════════════════════════════════════════════════
  // 3. Success
  // ═════════════════════════════════════════════════════════════════════

  group('Success', () {
    test('locks bracket → returns entity with isFinalized=true', () async {
      final bracket = makeBracket();
      when(() => mockBracketRepo.getBracketById('bracket-1'))
          .thenAnswer((_) async => Right(bracket));
      when(() => mockBracketRepo.updateBracket(any()))
          .thenAnswer((invocation) async {
        final updated = invocation.positionalArguments.first as BracketEntity;
        return Right(updated);
      });

      final result = await useCase(validParams);
      expect(result.isRight(), isTrue);

      result.fold(
        (_) => fail('Should be right'),
        (r) {
          expect(r.isFinalized, isTrue);
          expect(r.finalizedAtTimestamp, isNotNull);
        },
      );
    });

    test('locks bracket → verifies update called with correct entity', () async {
      final bracket = makeBracket();
      when(() => mockBracketRepo.getBracketById('bracket-1'))
          .thenAnswer((_) async => Right(bracket));
      when(() => mockBracketRepo.updateBracket(any()))
          .thenAnswer((inv) async =>
              Right(inv.positionalArguments.first as BracketEntity));

      await useCase(validParams);

      final captured = verify(
        () => mockBracketRepo.updateBracket(captureAny()),
      ).captured.single as BracketEntity;

      expect(captured.isFinalized, isTrue);
      expect(captured.finalizedAtTimestamp, isNotNull);
      expect(captured.id, equals('bracket-1'));
    });
  });

  // ═════════════════════════════════════════════════════════════════════
  // 4. Error propagation
  // ═════════════════════════════════════════════════════════════════════

  group('Error propagation', () {
    test('getBracketById returns NotFoundFailure → propagates failure', () async {
      when(() => mockBracketRepo.getBracketById('bracket-1'))
          .thenAnswer((_) async => const Left(
                NotFoundFailure(userFriendlyMessage: 'Bracket not found'),
              ));

      final result = await useCase(validParams);
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.updateBracket(any()));
    });

    test('getBracketById returns LocalCacheAccessFailure → propagates failure', () async {
      when(() => mockBracketRepo.getBracketById('bracket-1'))
          .thenAnswer((_) async => const Left(LocalCacheAccessFailure()));

      final result = await useCase(validParams);
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<LocalCacheAccessFailure>()),
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.updateBracket(any()));
    });

    test('updateBracket fails → propagates failure', () async {
      when(() => mockBracketRepo.getBracketById('bracket-1'))
          .thenAnswer((_) async => Right(makeBracket()));
      when(() => mockBracketRepo.updateBracket(any()))
          .thenAnswer((_) async => const Left(LocalCacheWriteFailure()));

      final result = await useCase(validParams);
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<LocalCacheWriteFailure>()),
        (_) => fail('Should have failed'),
      );
    });
  });
}
```

#### Unlock Use Case Test Skeleton

```dart
// test/features/bracket/domain/usecases/unlock_bracket_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/unlock_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/unlock_bracket_use_case.dart';

class MockBracketRepository extends Mock implements BracketRepository {}

void main() {
  late MockBracketRepository mockBracketRepo;
  late UnlockBracketUseCase useCase;

  setUpAll(() {
    registerFallbackValue(const UnlockBracketParams(bracketId: 'b1'));
    registerFallbackValue(
      BracketEntity(
        id: 'b1',
        divisionId: 'div1',
        bracketType: BracketType.winners,
        totalRounds: 3,
        createdAtTimestamp: DateTime(2026),
        updatedAtTimestamp: DateTime(2026),
      ),
    );
  });

  setUp(() {
    mockBracketRepo = MockBracketRepository();
    useCase = UnlockBracketUseCase(mockBracketRepo);
  });

  BracketEntity makeBracket({
    String id = 'bracket-1',
    bool isFinalized = false,
    DateTime? finalizedAtTimestamp,
  }) =>
      BracketEntity(
        id: id,
        divisionId: 'div1',
        bracketType: BracketType.winners,
        totalRounds: 3,
        createdAtTimestamp: DateTime(2026),
        updatedAtTimestamp: DateTime(2026),
        isFinalized: isFinalized,
        finalizedAtTimestamp: finalizedAtTimestamp,
      );

  const validParams = UnlockBracketParams(bracketId: 'bracket-1');

  // ═════════════════════════════════════════════════════════════════════
  // 1. Validation
  // ═════════════════════════════════════════════════════════════════════

  group('Validation', () {
    test('empty bracketId → ValidationFailure', () async {
      final result = await useCase(
        const UnlockBracketParams(bracketId: ''),
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.getBracketById(any()));
    });

    test('whitespace-only bracketId → ValidationFailure', () async {
      final result = await useCase(
        const UnlockBracketParams(bracketId: '   '),
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.getBracketById(any()));
    });
  });

  // ═════════════════════════════════════════════════════════════════════
  // 2. Not finalized
  // ═════════════════════════════════════════════════════════════════════

  group('Not finalized', () {
    test('not-finalized bracket → ValidationFailure with "not locked"', () async {
      when(() => mockBracketRepo.getBracketById('bracket-1'))
          .thenAnswer((_) async => Right(makeBracket(isFinalized: false)));

      final result = await useCase(validParams);
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) {
          expect(f, isA<ValidationFailure>());
          expect(f.userFriendlyMessage, contains('not'));
        },
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.updateBracket(any()));
    });
  });

  // ═════════════════════════════════════════════════════════════════════
  // 3. Success
  // ═════════════════════════════════════════════════════════════════════

  group('Success', () {
    test('unlocks bracket → returns entity with isFinalized=false', () async {
      final bracket = makeBracket(
        isFinalized: true,
        finalizedAtTimestamp: DateTime(2026),
      );
      when(() => mockBracketRepo.getBracketById('bracket-1'))
          .thenAnswer((_) async => Right(bracket));
      when(() => mockBracketRepo.updateBracket(any()))
          .thenAnswer((inv) async =>
              Right(inv.positionalArguments.first as BracketEntity));

      final result = await useCase(validParams);
      expect(result.isRight(), isTrue);

      result.fold(
        (_) => fail('Should be right'),
        (r) {
          expect(r.isFinalized, isFalse);
          expect(r.finalizedAtTimestamp, isNull);
        },
      );
    });

    test('unlocks bracket → verifies update called with correct entity', () async {
      final bracket = makeBracket(
        isFinalized: true,
        finalizedAtTimestamp: DateTime(2026),
      );
      when(() => mockBracketRepo.getBracketById('bracket-1'))
          .thenAnswer((_) async => Right(bracket));
      when(() => mockBracketRepo.updateBracket(any()))
          .thenAnswer((inv) async =>
              Right(inv.positionalArguments.first as BracketEntity));

      await useCase(validParams);

      final captured = verify(
        () => mockBracketRepo.updateBracket(captureAny()),
      ).captured.single as BracketEntity;

      expect(captured.isFinalized, isFalse);
      expect(captured.finalizedAtTimestamp, isNull);
      expect(captured.id, equals('bracket-1'));
    });
  });

  // ═════════════════════════════════════════════════════════════════════
  // 4. Error propagation
  // ═════════════════════════════════════════════════════════════════════

  group('Error propagation', () {
    test('getBracketById returns NotFoundFailure → propagates failure', () async {
      when(() => mockBracketRepo.getBracketById('bracket-1'))
          .thenAnswer((_) async => const Left(
                NotFoundFailure(userFriendlyMessage: 'Bracket not found'),
              ));

      final result = await useCase(validParams);
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.updateBracket(any()));
    });

    test('getBracketById returns LocalCacheAccessFailure → propagates failure', () async {
      when(() => mockBracketRepo.getBracketById('bracket-1'))
          .thenAnswer((_) async => const Left(LocalCacheAccessFailure()));

      final result = await useCase(validParams);
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<LocalCacheAccessFailure>()),
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.updateBracket(any()));
    });

    test('updateBracket fails → propagates failure', () async {
      when(() => mockBracketRepo.getBracketById('bracket-1'))
          .thenAnswer((_) async => Right(
                makeBracket(isFinalized: true, finalizedAtTimestamp: DateTime(2026)),
              ));
      when(() => mockBracketRepo.updateBracket(any()))
          .thenAnswer((_) async => const Left(LocalCacheWriteFailure()));

      final result = await useCase(validParams);
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<LocalCacheWriteFailure>()),
        (_) => fail('Should have failed'),
      );
    });
  });
}
```

### ⚠️ Common LLM Mistakes — Prevention Rules

| #   | Mistake                                                           | Correct Approach                                                                                                                                                |
| --- | ----------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Checking a `bracket.status` string field                          | `BracketEntity` has `isFinalized` (bool), **NOT** a status enum — use `bracket.isFinalized`                                                                     |
| 2   | Setting bracket status to `'in_progress'` or `'generated'` string | The epics mention "status = 'in_progress'" but the actual entity uses `isFinalized = true/false`. Use `copyWith(isFinalized: true/false)`                       |
| 3   | Creating a new `BracketStatus` enum                               | NO new enums needed — `isFinalized` boolean is the complete lock mechanism                                                                                      |
| 4   | Modifying any existing files                                      | NO modifications — this story creates 4 source files + 2 test files only                                                                                        |
| 5   | Adding new repository methods                                     | NO new repository methods — `getBracketById` and `updateBracket` already exist and are sufficient                                                               |
| 6   | Manually incrementing `syncVersion`                               | `BracketRepositoryImplementation.updateBracket` handles `syncVersion` incrementing automatically                                                                |
| 7   | Forgetting to set `finalizedAtTimestamp` when locking             | MUST set `finalizedAtTimestamp: DateTime.now()` on lock AND `finalizedAtTimestamp: null` on unlock                                                              |
| 8   | Using `Equatable` or `freezed` on params                          | Params use `@immutable` annotation only — follow `LockBracketParams` pattern from `RegenerateBracketParams`                                                     |
| 9   | Importing infrastructure packages in domain layer                 | UseCase can ONLY import domain and core packages — no `drift`, `supabase`, etc.                                                                                 |
| 10  | Forgetting `registerFallbackValue` for `BracketEntity` in tests   | `updateBracket(any())` requires a fallback for `BracketEntity` — register it in `setUpAll`                                                                      |
| 11  | Using `throw Exception('unexpected')` in test fold assertions     | Use `fail('Should have failed')` — matches existing test pattern                                                                                                |
| 12  | Creating a combined `LockUnlockBracketUseCase`                    | These are TWO SEPARATE use cases — `LockBracketUseCase` and `UnlockBracketUseCase` — following Clean Architecture single responsibility principle               |
| 13  | Manually setting `updatedAtTimestamp` in `copyWith`               | Do NOT set `updatedAtTimestamp` — the datasource layer handles timestamp updates on write. Only set `isFinalized` and `finalizedAtTimestamp`                    |
| 14  | Forgetting to import `NotFoundFailure` in test files              | Tests MUST import `failures.dart` which exports `NotFoundFailure`, `ValidationFailure`, `LocalCacheAccessFailure`, `LocalCacheWriteFailure` — all used in tests |
| 15  | Importing `bracket_entity.freezed.dart` directly                  | NEVER import `.freezed.dart` or `.g.dart` files — only import `bracket_entity.dart` which has the `part` directive                                              |

### Key Differences from Previous Stories

| Aspect         | Story 5.11 (Regeneration)       | **Story 5.12 (Lock/Unlock)**                    |
| -------------- | ------------------------------- | ----------------------------------------------- |
| Purpose        | Cleanup + re-create brackets    | **Toggle isFinalized flag on existing bracket** |
| Complexity     | High (multi-step orchestration) | **Low (get → validate → update)**               |
| Dependencies   | Repos + 3 generator use cases   | **BracketRepository only**                      |
| New files      | 3 source + 1 test               | **4 source + 2 test = 6 total**                 |
| Modified files | None                            | **None**                                        |
| Return type    | `RegenerateBracketResult`       | **`BracketEntity` (updated)**                   |
| Pattern        | Complex orchestration UC        | **Simple CRUD use case**                        |

### Performance Notes

- Lock/unlock is trivial: 1 read + 1 update per operation
- No performance concerns beyond existing repository latency
- Both operations are O(1) database operations

### Previous Story Intelligence

Learnings from Story 5.11 (`RegenerateBracketUseCase`) that impact this story:

1.  **`isFinalized` is the lock**: Story 5.11 already checks `isFinalized` to block regeneration on locked brackets. This story implements the mechanism that sets/clears this field.
2.  **Repository pattern**: `BracketRepository.updateBracket(BracketEntity)` returns `Either<Failure, BracketEntity>` — the use case returns this result directly.
3.  **Test pattern**: Mock `BracketRepository`, use `registerFallbackValue` in `setUpAll`, use `fail('Should have failed')` in fold handlers.
4.  **Params pattern**: Use `@immutable` annotation, `const` constructor, final fields — same as `RegenerateBracketParams`.
5.  **`copyWith` works correctly** with freezed for nullable fields — `copyWith(finalizedAtTimestamp: null)` correctly sets to null.
6.  **`fold(Left.new, ...)` pattern**: The `Left.new` tear-off is the project standard for error propagation in `.fold()`. Do NOT use `(failure) => Left(failure)` — use `Left.new`.
7.  **`BracketType` enum import**: Tests use `BracketType.winners` when constructing `BracketEntity` test fixtures. `BracketType` is exported from `bracket_entity.dart` (it's defined in the same file or re-exported). No separate import needed.
8.  **Test file counts**: Story 5.11 had 23 test cases across 1 file. Story 5.12 expects ~8 test cases per file = ~16 total across 2 files.

### Git Intelligence

Recent commits:
- `e1ee165` — Story 5.11 (Bracket regeneration) — checks `isFinalized` for blocking
- `4bfff31` — Story 5.10 (Bye assignment algorithm)
- `b578d00` — Story 5.9 (Manual seed override)

All follow Clean Architecture pattern. Use cases are in `lib/features/bracket/domain/usecases/`.

### Project Structure Notes

**New Files (4 source + 2 test = 6 total):**
```
lib/features/bracket/domain/usecases/
├── lock_bracket_params.dart              ← NEW
├── lock_bracket_use_case.dart            ← NEW
├── unlock_bracket_params.dart            ← NEW
└── unlock_bracket_use_case.dart          ← NEW

test/features/bracket/domain/usecases/
├── lock_bracket_use_case_test.dart       ← NEW
└── unlock_bracket_use_case_test.dart     ← NEW
```

**Existing directories (all exist — no need to create):**
- `lib/features/bracket/domain/usecases/` — has all generator and regeneration use cases + params
- `test/features/bracket/domain/usecases/` — has existing test files

**No modified files** — this story is purely additive.

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Story 5.12 section, lines 1887-1906]
- [Source: `_bmad-output/planning-artifacts/epics.md` — FR31: Regenerate bracket (locked state blocks), line 270]
- [Source: `_bmad-output/planning-artifacts/epics.md` — FR32: Enter match results (allowed on locked), line 271]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — brackets table schema with is_finalized, lines 1463-1486]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Clean Architecture dependency rules, lines 235-270]
- [Source: `lib/features/bracket/domain/entities/bracket_entity.dart` — BracketEntity with isFinalized field]
- [Source: `lib/features/bracket/domain/repositories/bracket_repository.dart` — getBracketById, updateBracket]
- [Source: `lib/features/bracket/data/repositories/bracket_repository_implementation.dart` — updateBracket auto-increments syncVersion]
- [Source: `lib/core/usecases/use_case.dart` — UseCase base class]
- [Source: `lib/core/error/failures.dart` — ValidationFailure, LocalCacheAccessFailure, LocalCacheWriteFailure, NotFoundFailure]
- [Source: `_bmad-output/implementation-artifacts/5-11-bracket-regeneration.md` — Previous story with isFinalized check pattern]
- [Source: `lib/features/bracket/data/repositories/bracket_repository_implementation.dart` — getBracketById returns NotFoundFailure when bracket doesn't exist]

## Dev Agent Record
 
 ### Agent Model Used
 
 Antigravity (Google Deepmind)
 
 ### Debug Log References
 
 - None.
 
 ### Completion Notes List
 
 - Created `LockBracketParams` and `UnlockBracketParams` with `@immutable`.
 - Implemented `LockBracketUseCase` and `UnlockBracketUseCase` with field validation and `BracketRepository` integration.
 - Added 16 unit tests across two files covering success, validation, and error propagation paths.
 - Verified all tests pass (1517 total) and analysis is clean.
 
 ### File List
 
 - `lib/features/bracket/domain/usecases/lock_bracket_params.dart`
 - `lib/features/bracket/domain/usecases/lock_bracket_use_case.dart`
 - `lib/features/bracket/domain/usecases/unlock_bracket_params.dart`
 - `lib/features/bracket/domain/usecases/unlock_bracket_use_case.dart`
 - `test/features/bracket/domain/usecases/lock_bracket_use_case_test.dart`
 - `test/features/bracket/domain/usecases/unlock_bracket_use_case_test.dart`
 
 ## Change Log
 
 - 2026-03-02: Initial implementation of bracket lock/unlock feature.
 - 2026-03-02: Code review — fixed circular imports in params files, tightened test assertions. All issues resolved. Status → done.
 
 Status: done
