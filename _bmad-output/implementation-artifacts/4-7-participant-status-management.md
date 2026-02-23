# Story 4.7: Participant Status Management

Status: done

**Created:** 2026-02-23

**Epic:** 4 - Participant Management

**FRs Covered:** FR18 (remove participant - no-show handling), FR19 (DQ participant)

**Dependencies:** Story 4.6 (Bulk Import) - COMPLETE | Story 4.2 (Participant Entity & Repository) - COMPLETE | Epic 3 (Tournament & Division) - COMPLETE

---

## TL;DR — Critical Facts

**CURRENT STATE:**
- ✅ `lib/features/participant/domain/entities/participant_entity.dart` — ParticipantEntity with `ParticipantStatus` enum (pending, checkedIn, noShow, withdrawn)
- ✅ `lib/features/participant/domain/repositories/participant_repository.dart` — ParticipantRepository with `updateParticipant()` method
- ✅ `lib/features/participant/data/models/participant_model.dart` — ParticipantModel with JSON mapping
- ✅ `lib/core/database/tables/participants_table.dart` — Drift table definition
- ✅ `lib/core/error/failures.dart` — NotFoundFailure, InputValidationFailure exist
- ✅ `lib/core/usecases/use_case.dart` — Base UseCase class with `call(Params)` signature
- ❌ `ParticipantStatus.disqualified` — **DOES NOT EXIST** — Must ADD to enum
- ❌ `dqReason` field on ParticipantEntity — **DOES NOT EXIST** — Must ADD to entity
- ❌ `MarkNoShowUseCase` — **DOES NOT EXIST** — Create in this story
- ❌ `DisqualifyParticipantUseCase` — **DOES NOT EXIST** — Create in this story
- ❌ `UpdateParticipantStatusUseCase` — **DOES NOT EXIST** — Create in this story (general status update)
- ❌ `dq_reason` column in Drift table — **DOES NOT EXIST** — Must ADD to participants_table.dart

**TARGET STATE:** Add `disqualified` status to enum, add `dqReason` field, create use cases for marking no-show and disqualification with proper validation and bracket impact handling.

**FILES TO CREATE:**
| File | Type | Description |
|------|------|-------------|
| `lib/features/participant/domain/usecases/mark_no_show_usecase.dart` | Use case | Mark participant as no-show |
| `lib/features/participant/domain/usecases/disqualify_participant_usecase.dart` | Use case | Disqualify participant with reason |
| `lib/features/participant/domain/usecases/update_participant_status_usecase.dart` | Use case | General status updates with transition validation |

**FILES TO MODIFY:**
| File | Change |
|------|--------|
| `lib/features/participant/domain/entities/participant_entity.dart` | Add `disqualified` to enum, add `dqReason` field |
| `lib/features/participant/data/models/participant_model.dart` | Add `dqReason` field with `@JsonKey(name: 'dq_reason')`, update conversions |
| `lib/core/database/tables/participants_table.dart` | Add `dqReason` column to Drift table |
| `lib/features/participant/domain/usecases/usecases.dart` | Export new use cases |

**KEY PREVIOUS STORY LESSONS — APPLY ALL:**
1. Use `@injectable` for use cases (not `@lazySingleton`) — see `create_participant_usecase.dart` line 13
2. Inject existing repository — don't re-implement persistence
3. Use `Either<Failure, T>` pattern for all return types
4. Run `dart run build_runner build --delete-conflicting-outputs` after ANY generated file changes
5. Keep domain layer pure — no Drift, Supabase, or Flutter dependencies
6. Use `copyWith()` for entity updates — entities are immutable via freezed
7. Always increment `syncVersion` on updates
8. Always set `updatedAtTimestamp: DateTime.now()` on updates

---

## Story

**As an** organizer,
**I want** to mark participants as no-show or disqualified,
**So that** brackets adjust correctly for absent or rule-violating athletes (FR18, FR19).

---

## Acceptance Criteria

- [x] **AC1:** `ParticipantStatus` enum updated to include `disqualified`:
  ```dart
  enum ParticipantStatus {
    pending('pending'),
    checkedIn('checked_in'),
    noShow('no_show'),
    withdrawn('withdrawn'),
    disqualified('disqualified');  // NEW - MUST ADD
  
    const ParticipantStatus(this.value);
    final String value;
    
    static ParticipantStatus fromString(String value) {
      return ParticipantStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => ParticipantStatus.pending,
      );
    }
  }
  ```

- [x] **AC2:** `ParticipantEntity` updated with `dqReason` field (placed AFTER `checkInAtTimestamp`):
  ```dart
  @freezed
  class ParticipantEntity with _$ParticipantEntity {
    const factory ParticipantEntity({
      // ... existing fields up to checkInAtTimestamp
      DateTime? checkInAtTimestamp,
      String? dqReason,  // NEW — reason for disqualification, nullable
      String? photoUrl,
      // ... rest of fields
    }) = _ParticipantEntity;
  }
  ```

- [x] **AC3:** Drift table `participants_table.dart` updated with `dqReason` column:
  ```dart
  /// Disqualification reason (nullable, only set when status is 'disqualified').
  TextColumn get dqReason => text().named('dq_reason').nullable()();
  ```

- [x] **AC4:** `ParticipantModel` updated with `dqReason` field:
  - Add `@JsonKey(name: 'dq_reason') String? dqReason` to factory constructor
  - Update `convertFromEntity()` to map `entity.dqReason`
  - Update `convertToEntity()` to map `dqReason`
  - Update `fromDriftEntry()` to map `entry.dqReason`
  - Update `toDriftCompanion()` to include `dqReason: Value(dqReason)`

- [x] **AC5:** `MarkNoShowUseCase` created with `@injectable`:
  - Extends `UseCase<ParticipantEntity, String>` (params is just participantId string)
  - Method: `Future<Either<Failure, ParticipantEntity>> call(String participantId)`
  - Validates participant exists via `getParticipantById()`
  - Sets `checkInStatus = ParticipantStatus.noShow`
  - Sets `checkInAtTimestamp = null` (clear any previous check-in)
  - Clears `dqReason = null` (not a DQ, so clear any previous DQ reason)
  - Increments `syncVersion`
  - Sets `updatedAtTimestamp = DateTime.now()`
  - Returns updated participant via `updateParticipant()`

- [x] **AC6:** `DisqualifyParticipantUseCase` created with `@injectable`:
  - Does NOT extend UseCase (uses named parameters pattern like existing use cases)
  - Method: `Future<Either<Failure, ParticipantEntity>> call({required String participantId, required String dqReason})`
  - **VALIDATES FIRST (before repository call):** `dqReason.trim().isEmpty` → return `Left(InputValidationFailure)`
  - Validates participant exists via `getParticipantById()`
  - Sets `checkInStatus = ParticipantStatus.disqualified`
  - Sets `dqReason = dqReason.trim()`
  - Sets `checkInAtTimestamp = null` (DQ overrides any check-in)
  - Increments `syncVersion`
  - Sets `updatedAtTimestamp = DateTime.now()`
  - Returns updated participant via `updateParticipant()`

- [x] **AC7:** `UpdateParticipantStatusUseCase` created for general status updates:
  - Does NOT extend UseCase (uses named parameters pattern)
  - Method: `Future<Either<Failure, ParticipantEntity>> call({required String participantId, required ParticipantStatus newStatus, String? dqReason})`
  - Validates participant exists via `getParticipantById()`
  - **VALIDATES STATUS TRANSITION** using transition matrix (see AC8)
  - If `newStatus == disqualified`, validates `dqReason` is not empty
  - If transitioning TO `disqualified`, sets `dqReason`
  - If transitioning FROM `disqualified` (undo), clears `dqReason = null`
  - Updates entity with new status
  - Increments `syncVersion`
  - Sets `updatedAtTimestamp = DateTime.now()`
  - Returns updated participant via `updateParticipant()`

- [x] **AC8:** Status transition validation matrix:
  | From | To | Allowed? | Notes |
  |------|-----|----------|-------|
  | pending | checked_in | ✅ | Normal check-in |
  | pending | no_show | ✅ | Mark absent before event |
  | pending | withdrawn | ✅ | Participant withdrew |
  | pending | disqualified | ✅ | DQ before event |
  | checked_in | withdrawn | ✅ | Checked-in but withdrew |
  | checked_in | disqualified | ✅ | DQ during event |
  | no_show | pending | ✅ | Undo no-show |
  | withdrawn | pending | ✅ | Undo withdrawal |
  | disqualified | pending | ✅ | Undo DQ (clears dqReason) |
  | checked_in | no_show | ❌ | Invalid - use withdrawn instead |
  | no_show | disqualified | ❌ | Invalid - reinstate first |
  | any other | any other | ❌ | Invalid transition |
  
  **Invalid transitions return:** `Left(InputValidationFailure)` with message "Invalid status transition from '{from}' to '{to}'"

- [x] **AC9:** Error handling:
  - **Participant not found** → return `Left(NotFoundFailure(userFriendlyMessage: 'Participant not found'))`
  - **Empty DQ reason** → return `Left(InputValidationFailure(userFriendlyMessage: 'Disqualification reason is required', fieldErrors: {'dqReason': 'Cannot be empty'}))`
  - **Invalid status transition** → return `Left(InputValidationFailure(userFriendlyMessage: 'Invalid status transition from ... to ...', fieldErrors: {'status': 'Invalid transition'}))`
  - **Repository failure** → propagate the failure from repository (already typed)

- [x] **AC10:** Unit tests verify:
  - Mark no-show success flow (participant exists, status updated, checkInAtTimestamp cleared)
  - Disqualify success flow with reason (participant exists, status + dqReason set)
  - Disqualify without reason fails validation (returns InputValidationFailure)
  - Disqualify with whitespace-only reason fails validation
  - Invalid status transitions rejected with proper error
  - Participant not found returns NotFoundFailure
  - Status transitions clear/restore appropriate fields (dqReason cleared on non-DQ status)
  - syncVersion increments on every update
  - updatedAtTimestamp is updated on every change
  - Undo DQ clears dqReason field

- [x] **AC11:** `flutter analyze` passes with zero new errors

- [x] **AC12:** `dart run build_runner build --delete-conflicting-outputs` succeeds

- [x] **AC13:** All participant tests pass: `flutter test test/features/participant/`

---

## Tasks / Subtasks

### Task 1: Update ParticipantStatus Enum (AC: #1)

- [x] 1.1: Open `lib/features/participant/domain/entities/participant_entity.dart`
- [x] 1.2: Add `disqualified('disqualified')` to `ParticipantStatus` enum (after `withdrawn`)
- [x] 1.3: Verify `fromString()` method handles new value correctly (no change needed - uses firstWhere)

### Task 2: Add dqReason Column to Drift Table (AC: #3)

- [x] 2.1: Open `lib/core/database/tables/participants_table.dart`
- [x] 2.2: Add `dqReason` column AFTER `checkInAtTimestamp` column:
  ```dart
  /// Disqualification reason (nullable, only set when status is 'disqualified').
  TextColumn get dqReason => text().named('dq_reason').nullable()();
  ```

### Task 3: Add dqReason Field to Entity (AC: #2)

- [x] 3.1: Open `lib/features/participant/domain/entities/participant_entity.dart`
- [x] 3.2: Add `String? dqReason` field to `ParticipantEntity` factory constructor (after `checkInAtTimestamp`)

### Task 4: Add dqReason Field to Model (AC: #4)

- [x] 4.1: Open `lib/features/participant/data/models/participant_model.dart`
- [x] 4.2: Add `@JsonKey(name: 'dq_reason') String? dqReason` to factory constructor (after `checkInAtTimestamp`)
- [x] 4.3: Update `fromDriftEntry()` factory to include `dqReason: entry.dqReason`
- [x] 4.4: Update `convertFromEntity()` factory to include `dqReason: entity.dqReason`
- [x] 4.5: Update `toDriftCompanion()` to include `dqReason: Value(dqReason)`
- [x] 4.6: Update `convertToEntity()` to include `dqReason: dqReason`

### Task 5: Run Build Runner (AC: #12)

- [x] 5.1: Run `dart run build_runner build --delete-conflicting-outputs` from `tkd_brackets/`
- [x] 5.2: Verify no errors in generated files

### Task 6: Create MarkNoShowUseCase (AC: #5)

- [x] 6.1: Create `lib/features/participant/domain/usecases/mark_no_show_usecase.dart`
- [x] 6.2: Add imports:
  ```dart
  import 'package:fpdart/fpdart.dart';
  import 'package:injectable/injectable.dart';
  import 'package:tkd_brackets/core/error/failures.dart';
  import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
  import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
  ```
- [x] 6.3: Add `@injectable` annotation
- [x] 6.4: Create class with `ParticipantRepository` injection
- [x] 6.5: Implement `call(String participantId)` method:
  - Call `_participantRepository.getParticipantById(participantId)`
  - Use `fold()` to handle Either
  - On success, create updated entity with `copyWith()`
  - Call `_participantRepository.updateParticipant(updatedParticipant)`
- [x] 6.6: Ensure `checkInAtTimestamp` is set to `null`
- [x] 6.7: Ensure `dqReason` is set to `null` (clear any previous DQ)

### Task 7: Create DisqualifyParticipantUseCase (AC: #6)

- [x] 7.1: Create `lib/features/participant/domain/usecases/disqualify_participant_usecase.dart`
- [x] 7.2: Add imports (same as Task 6.2)
- [x] 7.3: Add `@injectable` annotation
- [x] 7.4: Create class with `ParticipantRepository` injection
- [x] 7.5: **VALIDATE FIRST:** Check `dqReason.trim().isEmpty` before any repository calls
- [x] 7.6: Implement `call({required String participantId, required String dqReason})` method
- [x] 7.7: Ensure `checkInAtTimestamp` is set to `null`
- [x] 7.8: Ensure `dqReason` is trimmed before storage

### Task 8: Create UpdateParticipantStatusUseCase (AC: #7, #8)

- [x] 8.1: Create `lib/features/participant/domain/usecases/update_participant_status_usecase.dart`
- [x] 8.2: Add imports (same as Task 6.2)
- [x] 8.3: Add `@injectable` annotation
- [x] 8.4: Create class with `ParticipantRepository` injection
- [x] 8.5: Define static `_validTransitions` map (see Dev Notes)
- [x] 8.6: Implement `_isValidTransition(ParticipantStatus from, ParticipantStatus to)` helper
- [x] 8.7: Implement `call({required String participantId, required ParticipantStatus newStatus, String? dqReason})` method
- [x] 8.8: Validate transition before proceeding
- [x] 8.9: Handle disqualified status (requires dqReason)
- [x] 8.10: Handle undo DQ (transition from disqualified to pending clears dqReason)

### Task 9: Update Barrel File (AC: #11)

- [x] 9.1: Open `lib/features/participant/domain/usecases/usecases.dart`
- [x] 9.2: Add exports:
  ```dart
  export 'mark_no_show_usecase.dart';
  export 'disqualify_participant_usecase.dart';
  export 'update_participant_status_usecase.dart';
  ```

### Task 10: Create Unit Tests (AC: #10)

- [x] 10.1: Create `test/features/participant/domain/usecases/mark_no_show_usecase_test.dart`
- [x] 10.2: Create `test/features/participant/domain/usecases/disqualify_participant_usecase_test.dart`
- [x] 10.3: Create `test/features/participant/domain/usecases/update_participant_status_usecase_test.dart`
- [x] 10.4: Mock `ParticipantRepository` using `Mocktail`
- [x] 10.5: Test all success scenarios
- [x] 10.6: Test all failure scenarios (not found, validation errors, invalid transitions)

### Task 11: Verify Project Integrity (AC: #11, #13)

- [x] 11.1: Run `dart run build_runner build --delete-conflicting-outputs` — succeeds
- [x] 11.2: Run `flutter analyze` from `tkd_brackets/` — zero new issues
- [x] 11.3: Run all participant tests: `flutter test test/features/participant/` — all pass

---

## Dev Notes

### ⚠️ CRITICAL: Files That DO NOT Need Changes

| File | Why No Change |
|------|---------------|
| `participant_repository.dart` | Already has `getParticipantById()` and `updateParticipant()` — use these |
| `participant_repository_implementation.dart` | Implementation already complete, no changes needed |
| `participant_local_datasource.dart` | Will auto-work after Drift table update + build_runner |
| `participant_remote_datasource.dart` | Will auto-work after Supabase migration |

### Architecture Patterns — MANDATORY

**Use Case Pattern (follow existing `create_participant_usecase.dart`):**
```dart
@injectable  // ← REQUIRED, NOT @lazySingleton
class MarkNoShowUseCase {
  MarkNoShowUseCase(this._participantRepository);

  final ParticipantRepository _participantRepository;

  Future<Either<Failure, ParticipantEntity>> call(String participantId) async {
    // Implementation
  }
}
```

**Existing Repository Methods to Use:**
| Method | Purpose | Returns |
|--------|---------|---------|
| `getParticipantById(String id)` | Fetch participant for validation | `Either<Failure, ParticipantEntity>` |
| `updateParticipant(ParticipantEntity)` | Persist status change | `Either<Failure, ParticipantEntity>` |

**⚠️ CRITICAL: Entity Update Pattern with freezed:**
```dart
// ✅ CORRECT: Use copyWith() - entities are immutable
final updatedParticipant = participant.copyWith(
  checkInStatus: ParticipantStatus.noShow,
  checkInAtTimestamp: null,  // Clear previous check-in
  dqReason: null,            // Clear any previous DQ reason
  syncVersion: participant.syncVersion + 1,  // ALWAYS increment
  updatedAtTimestamp: DateTime.now(),        // ALWAYS update
);

// ❌ WRONG: Trying to mutate fields directly
participant.checkInStatus = ParticipantStatus.noShow;  // COMPILE ERROR
```

### Status Transition Matrix Implementation

```dart
// In update_participant_status_usecase.dart
static const Map<ParticipantStatus, Set<ParticipantStatus>> _validTransitions = {
  ParticipantStatus.pending: {
    ParticipantStatus.checkedIn,
    ParticipantStatus.noShow,
    ParticipantStatus.withdrawn,
    ParticipantStatus.disqualified,
  },
  ParticipantStatus.checkedIn: {
    ParticipantStatus.withdrawn,
    ParticipantStatus.disqualified,
  },
  ParticipantStatus.noShow: {
    ParticipantStatus.pending, // Undo
  },
  ParticipantStatus.withdrawn: {
    ParticipantStatus.pending, // Undo
  },
  ParticipantStatus.disqualified: {
    ParticipantStatus.pending, // Undo DQ
  },
};

bool _isValidTransition(ParticipantStatus from, ParticipantStatus to) {
  // Same status is always valid (idempotent)
  if (from == to) return true;
  return _validTransitions[from]?.contains(to) ?? false;
}
```

### Import Statements for All Use Cases

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
```

### Failure Types to Use (from `core/error/failures.dart`)

| Failure | When to Use | Constructor |
|---------|-------------|-------------|
| `NotFoundFailure` | Participant not found | `NotFoundFailure(userFriendlyMessage: 'Participant not found')` |
| `InputValidationFailure` | Validation fails | `InputValidationFailure(userFriendlyMessage: '...', fieldErrors: {'field': 'error'})` |

### Field Clearing Rules by Status

| New Status | checkInAtTimestamp | dqReason |
|------------|-------------------|----------|
| `pending` | `null` | `null` |
| `checkedIn` | `DateTime.now()` | `null` |
| `noShow` | `null` | `null` |
| `withdrawn` | keep existing | `null` |
| `disqualified` | `null` | **required** |

### Testing Patterns (using Mocktail)

```dart
// test/features/participant/domain/usecases/mark_no_show_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/mark_no_show_usecase.dart';

class MockParticipantRepository extends Mock implements ParticipantRepository {}

void main() {
  late MarkNoShowUseCase useCase;
  late MockParticipantRepository mockRepository;

  setUp(() {
    mockRepository = MockParticipantRepository();
    useCase = MarkNoShowUseCase(mockRepository);
  });

  group('MarkNoShowUseCase', () {
    final tParticipant = ParticipantEntity(
      id: 'test-id',
      divisionId: 'division-id',
      firstName: 'John',
      lastName: 'Doe',
      checkInStatus: ParticipantStatus.pending,
      syncVersion: 1,
      createdAtTimestamp: DateTime(2024, 1, 1),
      updatedAtTimestamp: DateTime(2024, 1, 1),
    );

    test('should return updated participant with noShow status', () async {
      // Arrange
      when(() => mockRepository.getParticipantById('test-id'))
          .thenAnswer((_) async => Right(tParticipant));
      when(() => mockRepository.updateParticipant(any()))
          .thenAnswer((_) async => Right(tParticipant.copyWith(
            checkInStatus: ParticipantStatus.noShow,
            syncVersion: 2,
          )));

      // Act
      final result = await useCase('test-id');

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.updateParticipant(any())).called(1);
    });

    test('should return NotFoundFailure when participant not found', () async {
      // Arrange
      when(() => mockRepository.getParticipantById('nonexistent'))
          .thenAnswer((_) async => const Left(NotFoundFailure(
            userFriendlyMessage: 'Participant not found',
          )));

      // Act
      final result = await useCase('nonexistent');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('Should return failure'),
      );
      verifyNever(() => mockRepository.updateParticipant(any()));
    });
  });
}
```

---

## Anti-Patterns — WHAT NOT TO DO

| ❌ Don't Do This | ✅ Do This Instead | Why |
|-----------------|---------------------|-----|
| Create new repository methods like `markNoShow()` | Use existing `updateParticipant()` | Avoid repository bloat, single update path |
| Use `@lazySingleton` for use case | Use `@injectable` | Use cases are transient, not singletons |
| Skip validation for DQ reason | Always validate `dqReason.trim().isNotEmpty` | Data integrity, user feedback |
| Allow any status transition | Validate against `_validTransitions` map | Business rule enforcement |
| Forget to increment syncVersion | Always do `syncVersion: participant.syncVersion + 1` | Offline sync requires version tracking |
| Forget to update updatedAtTimestamp | Always set `updatedAtTimestamp: DateTime.now()` | Audit trail requirement |
| Directly mutate entity fields | Use `copyWith()` for all updates | Freezed entities are immutable |
| Clear `dqReason` when setting `noShow` | Clear `dqReason: null` on all non-DQ statuses | Data consistency |
| Validate after repository call | Validate inputs BEFORE any repository calls | Fail fast, avoid unnecessary I/O |
| Return `Exception` or throw | Return `Either<Failure, T>` | Functional error handling pattern |
| Import Drift/Supabase in use case | Only import `fpdart`, `injectable`, domain types | Clean Architecture layer isolation |

---

## File Structure After This Story

```
lib/features/participant/
├── participant.dart
├── domain/
│   ├── entities/
│   │   ├── participant_entity.dart              ← MODIFIED (add disqualified, dqReason)
│   │   └── participant_entity.freezed.dart      ← REGENERATED by build_runner
│   ├── repositories/
│   │   └── participant_repository.dart          ← USE ONLY (no changes)
│   └── usecases/
│       ├── usecases.dart                        ← MODIFIED (add 3 new exports)
│       ├── create_participant_usecase.dart      ← EXISTING (reference pattern)
│       ├── create_participant_params.dart       ← EXISTING
│       ├── bulk_import_usecase.dart             ← EXISTING
│       ├── mark_no_show_usecase.dart            ← NEW
│       ├── disqualify_participant_usecase.dart  ← NEW
│       └── update_participant_status_usecase.dart ← NEW
├── data/
│   ├── models/
│   │   ├── participant_model.dart               ← MODIFIED (add dqReason)
│   │   ├── participant_model.freezed.dart       ← REGENERATED by build_runner
│   │   └── participant_model.g.dart             ← REGENERATED by build_runner
│   ├── datasources/
│   │   ├── participant_local_datasource.dart    ← USE ONLY (auto-works after table update)
│   │   └── participant_remote_datasource.dart   ← USE ONLY
│   └── repositories/
│       └── participant_repository_implementation.dart  ← USE ONLY (no changes)
└── presentation/                                ← Empty (Story 4.12)

lib/core/database/tables/
└── participants_table.dart                      ← MODIFIED (add dqReason column)
```

---

## Implementation Reference - Complete Code

### MarkNoShowUseCase

```dart
// lib/features/participant/domain/usecases/mark_no_show_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';

@injectable
class MarkNoShowUseCase {
  MarkNoShowUseCase(this._participantRepository);

  final ParticipantRepository _participantRepository;

  Future<Either<Failure, ParticipantEntity>> call(String participantId) async {
    final result = await _participantRepository.getParticipantById(participantId);

    return result.fold(
      (failure) => Left(failure),
      (participant) async {
        final updatedParticipant = participant.copyWith(
          checkInStatus: ParticipantStatus.noShow,
          checkInAtTimestamp: null,
          dqReason: null,
          syncVersion: participant.syncVersion + 1,
          updatedAtTimestamp: DateTime.now(),
        );

        return _participantRepository.updateParticipant(updatedParticipant);
      },
    );
  }
}
```

### DisqualifyParticipantUseCase

```dart
// lib/features/participant/domain/usecases/disqualify_participant_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';

@injectable
class DisqualifyParticipantUseCase {
  DisqualifyParticipantUseCase(this._participantRepository);

  final ParticipantRepository _participantRepository;

  Future<Either<Failure, ParticipantEntity>> call({
    required String participantId,
    required String dqReason,
  }) async {
    // VALIDATE FIRST - before any repository calls
    final trimmedReason = dqReason.trim();
    if (trimmedReason.isEmpty) {
      return const Left(InputValidationFailure(
        userFriendlyMessage: 'Disqualification reason is required',
        fieldErrors: {'dqReason': 'Cannot be empty'},
      ));
    }

    final result = await _participantRepository.getParticipantById(participantId);

    return result.fold(
      (failure) => Left(failure),
      (participant) async {
        final updatedParticipant = participant.copyWith(
          checkInStatus: ParticipantStatus.disqualified,
          checkInAtTimestamp: null,
          dqReason: trimmedReason,
          syncVersion: participant.syncVersion + 1,
          updatedAtTimestamp: DateTime.now(),
        );

        return _participantRepository.updateParticipant(updatedParticipant);
      },
    );
  }
}
```

### UpdateParticipantStatusUseCase

```dart
// lib/features/participant/domain/usecases/update_participant_status_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';

@injectable
class UpdateParticipantStatusUseCase {
  UpdateParticipantStatusUseCase(this._participantRepository);

  final ParticipantRepository _participantRepository;

  static const Map<ParticipantStatus, Set<ParticipantStatus>> _validTransitions = {
    ParticipantStatus.pending: {
      ParticipantStatus.checkedIn,
      ParticipantStatus.noShow,
      ParticipantStatus.withdrawn,
      ParticipantStatus.disqualified,
    },
    ParticipantStatus.checkedIn: {
      ParticipantStatus.withdrawn,
      ParticipantStatus.disqualified,
    },
    ParticipantStatus.noShow: {
      ParticipantStatus.pending,
    },
    ParticipantStatus.withdrawn: {
      ParticipantStatus.pending,
    },
    ParticipantStatus.disqualified: {
      ParticipantStatus.pending,
    },
  };

  Future<Either<Failure, ParticipantEntity>> call({
    required String participantId,
    required ParticipantStatus newStatus,
    String? dqReason,
  }) async {
    // Validate DQ reason if transitioning to disqualified
    if (newStatus == ParticipantStatus.disqualified) {
      final trimmedReason = dqReason?.trim() ?? '';
      if (trimmedReason.isEmpty) {
        return const Left(InputValidationFailure(
          userFriendlyMessage: 'Disqualification reason is required',
          fieldErrors: {'dqReason': 'Cannot be empty'},
        ));
      }
    }

    final result = await _participantRepository.getParticipantById(participantId);

    return result.fold(
      (failure) => Left(failure),
      (participant) async {
        // Validate status transition
        if (!_isValidTransition(participant.checkInStatus, newStatus)) {
          return Left(InputValidationFailure(
            userFriendlyMessage: 'Invalid status transition',
            fieldErrors: {
              'status': 'Cannot transition from ${participant.checkInStatus.value} to ${newStatus.value}',
            },
          ));
        }

        // Build updated participant based on new status
        final updatedParticipant = _buildUpdatedParticipant(
          participant,
          newStatus,
          dqReason?.trim(),
        );

        return _participantRepository.updateParticipant(updatedParticipant);
      },
    );
  }

  bool _isValidTransition(ParticipantStatus from, ParticipantStatus to) {
    if (from == to) return true; // Idempotent
    return _validTransitions[from]?.contains(to) ?? false;
  }

  ParticipantEntity _buildUpdatedParticipant(
    ParticipantEntity participant,
    ParticipantStatus newStatus,
    String? trimmedDqReason,
  ) {
    DateTime? newCheckInAtTimestamp;
    String? newDqReason;

    switch (newStatus) {
      case ParticipantStatus.pending:
        newCheckInAtTimestamp = null;
        newDqReason = null;
      case ParticipantStatus.checkedIn:
        newCheckInAtTimestamp = DateTime.now();
        newDqReason = null;
      case ParticipantStatus.noShow:
        newCheckInAtTimestamp = null;
        newDqReason = null;
      case ParticipantStatus.withdrawn:
        // Keep existing checkInAtTimestamp
        newCheckInAtTimestamp = participant.checkInAtTimestamp;
        newDqReason = null;
      case ParticipantStatus.disqualified:
        newCheckInAtTimestamp = null;
        newDqReason = trimmedDqReason;
    }

    return participant.copyWith(
      checkInStatus: newStatus,
      checkInAtTimestamp: newCheckInAtTimestamp,
      dqReason: newDqReason,
      syncVersion: participant.syncVersion + 1,
      updatedAtTimestamp: DateTime.now(),
    );
  }
}
```

---

## Database Migration Notes

### Drift Table Update (Local SQLite)

Add to `lib/core/database/tables/participants_table.dart`:

```dart
/// Disqualification reason (nullable, only set when status is 'disqualified').
TextColumn get dqReason => text().named('dq_reason').nullable()();
```

After adding, run: `dart run build_runner build --delete-conflicting-outputs`

### Supabase Migration (Remote PostgreSQL)

Create migration file `supabase/migrations/YYYYMMDDHHMMSS_add_dq_reason_to_participants.sql`:

```sql
-- Add dq_reason column to participants table
ALTER TABLE participants ADD COLUMN dq_reason TEXT;

-- Update check_in_status constraint to include 'disqualified'
ALTER TABLE participants DROP CONSTRAINT IF EXISTS participants_check_in_status_check;
ALTER TABLE participants ADD CONSTRAINT participants_check_in_status_check 
  CHECK (check_in_status IN ('pending', 'checked_in', 'no_show', 'withdrawn', 'disqualified'));

-- Add comment for documentation
COMMENT ON COLUMN participants.dq_reason IS 'Reason for disqualification, only set when check_in_status is disqualified';
```

---

## Bracket Impact Notes

**Future Consideration (Epic 5 - Bracket Generation):**
- No-show participants: opponents should receive bye advancement
- Disqualified participants: current match forfeited, opponent advances
- These bracket adjustments will be handled by Bracket Service in Epic 5

**This story creates the foundation by:**
1. Setting participant status correctly with proper validation
2. Storing DQ reason for audit trail
3. Providing clean use case APIs for status changes

---

## Dev Agent Record

### Agent Model Used
opencode/glm-5-free

### Debug Log References
N/A

### Completion Notes List
- Added `disqualified` status to `ParticipantStatus` enum
- Added `dqReason` field to `ParticipantEntity`, `ParticipantModel`, and Drift table
- Created `MarkNoShowUseCase` for marking participants as no-show
- Created `DisqualifyParticipantUseCase` for disqualifying participants with validation
- Created `UpdateParticipantStatusUseCase` with status transition validation matrix
- All 13 acceptance criteria verified and passing
- All participant tests pass (42 tests in new use cases)
- Flutter analyze shows zero new errors
- **Code Review Fixes Applied:**
  - Fixed line length violations in participants_table.dart and update_participant_status_usecase.dart
  - Converted closures to tearoffs in all three use cases for cleaner code
  - Added test for noShow → withdrawn invalid transition

### File List
**Modified:**
- tkd_brackets/lib/features/participant/domain/entities/participant_entity.dart
- tkd_brackets/lib/features/participant/data/models/participant_model.dart
- tkd_brackets/lib/core/database/tables/participants_table.dart
- tkd_brackets/lib/features/participant/domain/usecases/usecases.dart

**Created:**
- tkd_brackets/lib/features/participant/domain/usecases/mark_no_show_usecase.dart
- tkd_brackets/lib/features/participant/domain/usecases/disqualify_participant_usecase.dart
- tkd_brackets/lib/features/participant/domain/usecases/update_participant_status_usecase.dart
- tkd_brackets/test/features/participant/domain/usecases/mark_no_show_usecase_test.dart
- tkd_brackets/test/features/participant/domain/usecases/disqualify_participant_usecase_test.dart
- tkd_brackets/test/features/participant/domain/usecases/update_participant_status_usecase_test.dart

**Regenerated by build_runner:**
- tkd_brackets/lib/features/participant/domain/entities/participant_entity.freezed.dart
- tkd_brackets/lib/features/participant/data/models/participant_model.freezed.dart
- tkd_brackets/lib/features/participant/data/models/participant_model.g.dart
- tkd_brackets/lib/core/database/app_database.g.dart

### Change Log
- 2026-02-23: Story implementation completed - added disqualified status, dqReason field, and three use cases with comprehensive tests

