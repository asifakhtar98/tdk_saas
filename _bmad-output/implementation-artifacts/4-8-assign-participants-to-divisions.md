# Story 4.8: Assign Participants to Divisions

Status: done

**Created:** 2026-02-23

**Epic:** 4 - Participant Management

**FRs Covered:** FR18 (manually assign participants to divisions)

**Dependencies:** Story 4.7 (Participant Status Management) - COMPLETE | Story 4.2 (Participant Entity & Repository) - COMPLETE | Story 3.7 (Division Entity & Repository) - COMPLETE

---

## TL;DR — Critical Facts

**CURRENT STATE:**
- ✅ `lib/features/participant/domain/entities/participant_entity.dart` — ParticipantEntity with `divisionId` field
- ✅ `lib/features/participant/domain/repositories/participant_repository.dart` — has `getParticipantById()` and `updateParticipant()` methods
- ✅ `lib/features/division/domain/repositories/division_repository.dart` — has `getDivisionById()` and `getParticipantsForDivision()`
- ✅ `lib/features/participant/domain/usecases/auto_assign_participants_usecase.dart` — auto-assignment EXISTS (Story 4.9 already done!)
- ✅ `lib/core/database/tables/participants_table.dart` — `divisionId` column with FK to divisions
- ✅ `lib/core/error/failures.dart` — has `NotFoundFailure`, `InputValidationFailure`, `AuthorizationPermissionDeniedFailure`
- ❌ `AssignToDivisionUseCase` — **DOES NOT EXIST** — Create in this story

**TARGET STATE:** Create `AssignToDivisionUseCase` for manual participant-to-division assignment with proper validation, authorization, duplicate prevention, and audit trail.

**FILES TO CREATE:**
| File | Type | Description |
|------|------|-------------|
| `lib/features/participant/domain/usecases/assign_to_division_usecase.dart` | Use case | Assign participant to a division |

**FILES TO MODIFY:**
| File | Change |
|------|--------|
| `lib/features/participant/domain/usecases/usecases.dart` | Export new use case |

**⚠️ SCOPE NOTE:**
- `TransferParticipantUseCase` and `RemoveFromDivisionUseCase` are deferred to **Story 4.11** (Participant Edit & Transfer)
- `GetUnassignedParticipantsUseCase` is deferred to **Story 4.10** (Division Participant View)
- This story focuses ONLY on the core `AssignToDivisionUseCase`

**KEY PREVIOUS STORY LESSONS — APPLY ALL:**
1. Use `@injectable` for use cases (not `@lazySingleton`)
2. Inject existing repositories — don't re-implement persistence
3. Use `Either<Failure, T>` pattern for all return types
4. Run `dart run build_runner build --delete-conflicting-outputs` after ANY generated file changes
5. Keep domain layer pure — no Drift, Supabase, or Flutter dependencies
6. Use `copyWith()` for entity updates — entities are immutable via freezed
7. Always increment `syncVersion` on updates
8. Always set `updatedAtTimestamp: DateTime.now()` on updates
9. Validate BEFORE repository calls (fail fast)

---

## Story

**As an** organizer,
**I want** to manually assign participants to specific divisions,
**So that** I have full control over placement (FR18).

**Note:** Per epics AC, a participant can be in multiple divisions (forms + sparring). The same participant cannot be added to the same division twice.

---

## Acceptance Criteria

- [x] **AC1:** `AssignToDivisionUseCase` created with `@injectable`:
  - Method: `Future<Either<Failure, ParticipantEntity>> call({required String participantId, required String divisionId})`
  - **AUTHORIZATION:** Validates current user belongs to organization that owns the tournament (follow `CreateParticipantUseCase` pattern)
  - Validates participant exists via `getParticipantById()`
  - Validates division exists via `getDivisionById()`
  - **DIVISION STATUS:** Validates division status is `DivisionStatus.setup` OR `DivisionStatus.ready` (NOT `inProgress` or `completed`)
  - **DUPLICATE PREVENTION:** Check if participant is already assigned to this specific division (`participant.divisionId == divisionId`)
  - Updates participant's `divisionId` to new division
  - Increments `syncVersion`
  - Sets `updatedAtTimestamp = DateTime.now()`
  - Returns updated participant

- [x] **AC2:** Division status validation (CRITICAL — no `isAssignable` getter exists):
  - **DO NOT USE:** `division.status.isAssignable` — this getter does NOT exist
  - **USE INSTEAD:** Direct comparison:
    ```dart
    if (division.status != DivisionStatus.setup && 
        division.status != DivisionStatus.ready) {
      return const Left(InputValidationFailure(
        userFriendlyMessage: 'Cannot assign to division that is in progress or completed',
        fieldErrors: {'divisionId': 'Division is not accepting new participants'},
      ));
    }
    ```

- [x] **AC3:** Authorization check (follow `CreateParticipantUseCase` pattern exactly):
  - Get current user via `_userRepository.getCurrentUser()`
  - Get tournament via `_tournamentRepository.getTournamentById(division.tournamentId)`
  - Verify `tournament.organizationId == user.organizationId`
  - Return `AuthorizationPermissionDeniedFailure` if mismatch
  - **Required repositories to inject:** `ParticipantRepository`, `DivisionRepository`, `TournamentRepository`, `UserRepository`

- [x] **AC4:** Duplicate assignment prevention:
  - Same participant record cannot be assigned to same division twice
  - Check: `participant.divisionId == divisionId` → return error
  - Error message: "Participant is already assigned to this division"
  - **Note:** This check is per participant RECORD, not per person (multi-division uses multiple records)

- [x] **AC5:** Error handling:
  - **User not logged in** → `Left(AuthorizationPermissionDeniedFailure(userFriendlyMessage: 'You must be logged in with an organization to assign participants'))`
  - **Participant not found** → `Left(NotFoundFailure(userFriendlyMessage: 'Participant not found'))`
  - **Division not found** → `Left(NotFoundFailure(userFriendlyMessage: 'Division not found'))`
  - **Tournament not found** → `Left(NotFoundFailure(userFriendlyMessage: 'Tournament not found'))`
  - **Wrong organization** → `Left(AuthorizationPermissionDeniedFailure(userFriendlyMessage: 'You do not have permission to assign participants to this division'))`
  - **Division not assignable** → `Left(InputValidationFailure(userFriendlyMessage: 'Cannot assign to division that is in progress or completed'))`
  - **Duplicate assignment** → `Left(InputValidationFailure(userFriendlyMessage: 'Participant is already assigned to this division'))`

- [x] **AC6:** Unit tests verify:
  - Assign to division success flow (all validations pass)
  - User not logged in returns AuthorizationPermissionDeniedFailure
  - Wrong organization returns AuthorizationPermissionDeniedFailure
  - Division status `inProgress` blocks assignment
  - Division status `completed` blocks assignment
  - Division status `setup` allows assignment
  - Division status `ready` allows assignment
  - Duplicate assignment rejected
  - Participant not found returns NotFoundFailure
  - Division not found returns NotFoundFailure
  - syncVersion increments on update
  - updatedAtTimestamp is updated on change

- [x] **AC7:** `flutter analyze` passes with zero new errors

- [x] **AC8:** All participant tests pass: `flutter test test/features/participant/`

---

## Tasks / Subtasks

### Task 1: Create AssignToDivisionUseCase (AC: #1, #2, #3, #4, #5)

- [x] 1.1: Create `lib/features/participant/domain/usecases/assign_to_division_usecase.dart`
- [x] 1.2: Add imports:
  ```dart
  import 'package:fpdart/fpdart.dart';
  import 'package:injectable/injectable.dart';
  import 'package:tkd_brackets/core/error/failures.dart';
  import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
  import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
  import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
  import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
  import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
  import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
  ```
- [x] 1.3: Add `@injectable` annotation
- [x] 1.4: Create class with FOUR repository injections:
  - `ParticipantRepository _participantRepository`
  - `DivisionRepository _divisionRepository`
  - `TournamentRepository _tournamentRepository`
  - `UserRepository _userRepository`
- [x] 1.5: Implement `call({required String participantId, required String divisionId})` method
- [x] 1.6: **AUTHORIZATION FIRST:** Get current user, return `AuthorizationPermissionDeniedFailure` if not logged in or no organization
- [x] 1.7: Validate participant exists via `getParticipantById()`, return `NotFoundFailure` if not found
- [x] 1.8: Validate division exists via `getDivisionById()`, return `NotFoundFailure` if not found
- [x] 1.9: **AUTHORIZATION:** Get tournament via `getTournamentById(division.tournamentId)`, verify organization ownership
- [x] 1.10: Validate division status using DIRECT COMPARISON (NOT `isAssignable` getter):
  ```dart
  if (division.status != DivisionStatus.setup && 
      division.status != DivisionStatus.ready) {
    // return InputValidationFailure
  }
  ```
- [x] 1.11: Check duplicate assignment (`participant.divisionId == divisionId`)
- [x] 1.12: Create updated participant with `copyWith()`, increment `syncVersion`, set `updatedAtTimestamp`
- [x] 1.13: Return result from `updateParticipant()`

### Task 2: Update Barrel File (AC: #7)

- [x] 2.1: Open `lib/features/participant/domain/usecases/usecases.dart`
- [x] 2.2: Add export: `export 'assign_to_division_usecase.dart';`
- [x] 2.3: **Current exports for reference:**
  ```dart
  export 'auto_assignment_match.dart';
  export 'auto_assignment_result.dart';
  export 'auto_assign_participants_usecase.dart';
  export 'bulk_import_preview.dart';
  export 'bulk_import_preview_row.dart';
  export 'bulk_import_result.dart';
  export 'bulk_import_row_status.dart';
  export 'bulk_import_usecase.dart';
  export 'create_participant_params.dart';
  export 'create_participant_usecase.dart';
  export 'disqualify_participant_usecase.dart';
  export 'mark_no_show_usecase.dart';
  export 'update_participant_status_usecase.dart';
  // ADD: export 'assign_to_division_usecase.dart';
  ```

### Task 3: Create Unit Tests (AC: #6)

- [x] 3.1: Create `test/features/participant/domain/usecases/assign_to_division_usecase_test.dart`
- [x] 3.2: Mock all four repositories: `MockParticipantRepository`, `MockDivisionRepository`, `MockTournamentRepository`, `MockUserRepository`
- [x] 3.3: Test: success flow with all validations passing
- [x] 3.4: Test: user not logged in returns `AuthorizationPermissionDeniedFailure`
- [x] 3.5: Test: wrong organization returns `AuthorizationPermissionDeniedFailure`
- [x] 3.6: Test: division status `inProgress` blocks assignment
- [x] 3.7: Test: division status `completed` blocks assignment
- [x] 3.8: Test: division status `setup` allows assignment
- [x] 3.9: Test: division status `ready` allows assignment
- [x] 3.10: Test: duplicate assignment rejected
- [x] 3.11: Test: participant not found returns `NotFoundFailure`
- [x] 3.12: Test: division not found returns `NotFoundFailure`
- [x] 3.13: Test: `syncVersion` increments
- [x] 3.14: Test: `updatedAtTimestamp` is updated

### Task 4: Verify Project Integrity (AC: #7, #8)

- [x] 4.1: Run `flutter analyze` from `tkd_brackets/` — zero new issues
- [x] 4.2: Run all participant tests: `flutter test test/features/participant/` — all pass

---

## Dev Notes

### ⚠️ CRITICAL: Files That DO NOT Need Changes

| File | Why No Change |
|------|---------------|
| `participant_repository.dart` | Already has `getParticipantById()` and `updateParticipant()` |
| `division_repository.dart` | Already has `getDivisionById()` and `getParticipantsForDivision()` |
| `tournament_repository.dart` | Already has `getTournamentById()` |
| `user_repository.dart` | Already has `getCurrentUser()` |
| `participant_entity.dart` | Already has `divisionId` field |
| `participants_table.dart` | Already has `division_id` column with FK |
| `auto_assign_participants_usecase.dart` | **ALREADY EXISTS** from Story 4.9 — don't recreate! |

### ⚠️ CRITICAL: DivisionStatus Enum Has NO `isAssignable` Getter

**The `DivisionStatus` enum in `division_entity.dart` does NOT have an `isAssignable` getter.**

```dart
// ❌ WRONG - This will cause a compile error:
if (!division.status.isAssignable) { ... }

// ✅ CORRECT - Use direct comparison:
if (division.status != DivisionStatus.setup && 
    division.status != DivisionStatus.ready) {
  return const Left(InputValidationFailure(...));
}
```

**DivisionStatus values from `division_entity.dart`:**
- `DivisionStatus.setup` — assignable
- `DivisionStatus.ready` — assignable
- `DivisionStatus.inProgress` — NOT assignable
- `DivisionStatus.completed` — NOT assignable

### ⚠️ ARCHITECTURAL DECISION: Junction Table vs Direct FK

**Per epics.md:** Story 4.8 mentions "creates a `division_participant` record" (junction table).

**Actual implementation:** Uses direct FK `participants.division_id`.

**What this means for this story:**
- Each participant record belongs to ONE division (via `divisionId` FK)
- Multi-division participation = create MULTIPLE participant records with same person's data but different `divisionId`
- Example: John Doe competes in both Sparring and Forms:
  - Record 1: `{id: 'p1', firstName: 'John', lastName: 'Doe', divisionId: 'sparring-div'}`
  - Record 2: `{id: 'p2', firstName: 'John', lastName: 'Doe', divisionId: 'forms-div'}`
- Duplicate check is per-record: `participant.divisionId == targetDivisionId`
- **This use case assigns ONE participant record to ONE division**

### ⚠️ CRITICAL: Authorization Pattern — Follow CreateParticipantUseCase

**This use case MUST inject FOUR repositories:**
```dart
@injectable
class AssignToDivisionUseCase {
  AssignToDivisionUseCase(
    this._participantRepository,
    this._divisionRepository,
    this._tournamentRepository,
    this._userRepository,
  );

  final ParticipantRepository _participantRepository;
  final DivisionRepository _divisionRepository;
  final TournamentRepository _tournamentRepository;
  final UserRepository _userRepository;
```

**Authorization flow (from `create_participant_usecase.dart` lines 48-95):**
```dart
// 1. Get current user
final userResult = await _userRepository.getCurrentUser();
final user = userResult.fold((failure) => null, (user) => user);

// 2. Check user is logged in with organization
if (user == null || user.organizationId.isEmpty) {
  return const Left(AuthorizationPermissionDeniedFailure(
    userFriendlyMessage: 'You must be logged in with an organization to assign participants',
  ));
}

// 3. Get tournament from division
final tournamentResult = await _tournamentRepository.getTournamentById(division.tournamentId);
final tournament = tournamentResult.fold((failure) => null, (t) => t);

if (tournament == null) {
  return const Left(NotFoundFailure(
    userFriendlyMessage: 'Tournament not found',
  ));
}

// 4. Verify organization ownership
if (tournament.organizationId != user.organizationId) {
  return const Left(AuthorizationPermissionDeniedFailure(
    userFriendlyMessage: 'You do not have permission to assign participants to this division',
  ));
}
```

### Existing Repository Methods to Use

| Repository | Method | Purpose | Returns |
|------------|--------|---------|---------|
| `UserRepository` | `getCurrentUser()` | Get logged-in user | `Either<Failure, UserEntity>` |
| `ParticipantRepository` | `getParticipantById(String id)` | Fetch participant | `Either<Failure, ParticipantEntity>` |
| `ParticipantRepository` | `updateParticipant(ParticipantEntity)` | Persist changes | `Either<Failure, ParticipantEntity>` |
| `DivisionRepository` | `getDivisionById(String id)` | Fetch division | `Either<Failure, DivisionEntity>` |
| `TournamentRepository` | `getTournamentById(String id)` | Fetch tournament | `Either<Failure, TournamentEntity>` |

### ⚠️ CRITICAL: Entity Update Pattern with freezed

```dart
// ✅ CORRECT: Use copyWith() - entities are immutable
final updatedParticipant = participant.copyWith(
  divisionId: divisionId,
  syncVersion: participant.syncVersion + 1,  // ALWAYS increment
  updatedAtTimestamp: DateTime.now(),        // ALWAYS update
);

// ❌ WRONG: Trying to mutate fields directly
participant.divisionId = newDivisionId;  // COMPILE ERROR
```

### Duplicate Assignment Check Logic

```dart
// Check if participant record is ALREADY in this specific division
if (participant.divisionId == divisionId) {
  return const Left(InputValidationFailure(
    userFriendlyMessage: 'Participant is already assigned to this division',
    fieldErrors: {'divisionId': 'Duplicate assignment'},
  ));
}
```

**Note:** This check is per participant RECORD. If John Doe has Record A in Division X and Record B in Division Y, assigning Record A to Division Y would pass this check (different record ID, different current divisionId). This is correct behavior for multi-division participation.

### Failure Types to Use (from `core/error/failures.dart`)

| Failure | When to Use | Constructor |
|---------|-------------|-------------|
| `AuthorizationPermissionDeniedFailure` | User not logged in or wrong org | `AuthorizationPermissionDeniedFailure(userFriendlyMessage: '...')` |
| `NotFoundFailure` | Participant/Division/Tournament not found | `NotFoundFailure(userFriendlyMessage: '...')` |
| `InputValidationFailure` | Division status or duplicate | `InputValidationFailure(userFriendlyMessage: '...', fieldErrors: {'field': 'error'})` |

### Import Statements

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
```

---

## Anti-Patterns — WHAT NOT TO DO

| ❌ Don't Do This | ✅ Do This Instead | Why |
|-----------------|---------------------|-----|
| Use `division.status.isAssignable` | Use direct comparison: `status == setup \|\| status == ready` | `isAssignable` getter does NOT exist |
| Skip authorization check | Always validate user.organizationId == tournament.organizationId | Security vulnerability |
| Inject only 2 repositories | Inject all 4: Participant, Division, Tournament, User | Authorization requires User and Tournament |
| Use `@lazySingleton` for use case | Use `@injectable` | Use cases are transient |
| Check all divisions for duplicate | Check only `participant.divisionId == targetDivisionId` | Simpler, correct for single-record assignment |
| Forget to validate division status | Always check `status == setup \|\| status == ready` | Business rule enforcement |
| Forget to increment syncVersion | Always do `syncVersion: participant.syncVersion + 1` | Offline sync requires version tracking |
| Forget to update updatedAtTimestamp | Always set `updatedAtTimestamp: DateTime.now()` | Audit trail requirement |
| Directly mutate entity fields | Use `copyWith()` for all updates | Freezed entities are immutable |
| Validate after repository call | Validate inputs BEFORE any repository calls | Fail fast, avoid unnecessary I/O |
| Return `Exception` or throw | Return `Either<Failure, T>` | Functional error handling pattern |
| Import Drift/Supabase in use case | Only import domain types and fpdart/injectable | Clean Architecture layer isolation |
| Recreate `AutoAssignParticipantsUseCase` | It already exists from Story 4.9 | Don't reinvent the wheel |
| Create TransferParticipantUseCase here | Defer to Story 4.11 | Correct per epics.md |

---

## File Structure After This Story

```
lib/features/participant/
├── participant.dart
├── domain/
│   ├── entities/
│   │   ├── participant_entity.dart              ← USE ONLY (no changes)
│   │   └── participant_entity.freezed.dart
│   ├── repositories/
│   │   └── participant_repository.dart          ← USE ONLY (no changes)
│   └── usecases/
│       ├── usecases.dart                        ← MODIFIED (add 1 export)
│       ├── create_participant_usecase.dart      ← REFERENCE (authorization pattern)
│       ├── create_participant_params.dart       ← EXISTING
│       ├── bulk_import_usecase.dart             ← EXISTING
│       ├── mark_no_show_usecase.dart            ← EXISTING (Story 4.7)
│       ├── disqualify_participant_usecase.dart  ← EXISTING (Story 4.7)
│       ├── update_participant_status_usecase.dart ← EXISTING (Story 4.7)
│       ├── auto_assign_participants_usecase.dart  ← EXISTING (Story 4.9)
│       └── assign_to_division_usecase.dart      ← NEW (this story)
├── data/
│   ├── models/
│   │   ├── participant_model.dart               ← USE ONLY (no changes)
│   │   ├── participant_model.freezed.dart
│   │   └── participant_model.g.dart
│   ├── datasources/
│   │   ├── participant_local_datasource.dart    ← USE ONLY
│   │   └── participant_remote_datasource.dart  ← USE ONLY
│   └── repositories/
│       └── participant_repository_implementation.dart  ← USE ONLY (no changes)
└── presentation/                                ← Empty (Story 4.12)

test/features/participant/domain/usecases/
├── assign_to_division_usecase_test.dart         ← NEW (this story)
└── ... (existing test files)
```

---

## Implementation Reference - Complete Code

### AssignToDivisionUseCase

```dart
// lib/features/participant/domain/usecases/assign_to_division_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

@injectable
class AssignToDivisionUseCase {
  AssignToDivisionUseCase(
    this._participantRepository,
    this._divisionRepository,
    this._tournamentRepository,
    this._userRepository,
  );

  final ParticipantRepository _participantRepository;
  final DivisionRepository _divisionRepository;
  final TournamentRepository _tournamentRepository;
  final UserRepository _userRepository;

  Future<Either<Failure, ParticipantEntity>> call({
    required String participantId,
    required String divisionId,
  }) async {
    // ========== AUTHORIZATION ==========
    final userResult = await _userRepository.getCurrentUser();
    final user = userResult.fold((failure) => null, (user) => user);

    if (user == null || user.organizationId.isEmpty) {
      return const Left(AuthorizationPermissionDeniedFailure(
        userFriendlyMessage:
            'You must be logged in with an organization to assign participants',
      ));
    }

    // ========== VALIDATE PARTICIPANT ==========
    final participantResult = await _participantRepository.getParticipantById(
      participantId,
    );

    final participant = participantResult.fold(
      (failure) => null,
      (p) => p,
    );

    if (participant == null) {
      return const Left(NotFoundFailure(
        userFriendlyMessage: 'Participant not found',
      ));
    }

    // ========== VALIDATE DIVISION ==========
    final divisionResult = await _divisionRepository.getDivisionById(divisionId);

    final division = divisionResult.fold(
      (failure) => null,
      (d) => d,
    );

    if (division == null) {
      return const Left(NotFoundFailure(
        userFriendlyMessage: 'Division not found',
      ));
    }

    // ========== AUTHORIZATION: CHECK TOURNAMENT OWNERSHIP ==========
    final tournamentResult = await _tournamentRepository.getTournamentById(
      division.tournamentId,
    );

    final tournament = tournamentResult.fold(
      (failure) => null,
      (t) => t,
    );

    if (tournament == null) {
      return const Left(NotFoundFailure(
        userFriendlyMessage: 'Tournament not found',
      ));
    }

    if (tournament.organizationId != user.organizationId) {
      return const Left(AuthorizationPermissionDeniedFailure(
        userFriendlyMessage:
            'You do not have permission to assign participants to this division',
      ));
    }

    // ========== VALIDATE DIVISION STATUS ==========
    // NOTE: DivisionStatus does NOT have isAssignable getter
    // Use direct comparison instead
    if (division.status != DivisionStatus.setup &&
        division.status != DivisionStatus.ready) {
      return const Left(InputValidationFailure(
        userFriendlyMessage:
            'Cannot assign to division that is in progress or completed',
        fieldErrors: {'divisionId': 'Division is not accepting new participants'},
      ));
    }

    // ========== CHECK DUPLICATE ASSIGNMENT ==========
    if (participant.divisionId == divisionId) {
      return const Left(InputValidationFailure(
        userFriendlyMessage: 'Participant is already assigned to this division',
        fieldErrors: {'divisionId': 'Duplicate assignment'},
      ));
    }

    // ========== UPDATE PARTICIPANT ==========
    final updatedParticipant = participant.copyWith(
      divisionId: divisionId,
      syncVersion: participant.syncVersion + 1,
      updatedAtTimestamp: DateTime.now(),
    );

    return _participantRepository.updateParticipant(updatedParticipant);
  }
}
```

---

## Testing Reference

### Test File: assign_to_division_usecase_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/assign_to_division_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

class MockParticipantRepository extends Mock implements ParticipantRepository {}
class MockDivisionRepository extends Mock implements DivisionRepository {}
class MockTournamentRepository extends Mock implements TournamentRepository {}
class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late AssignToDivisionUseCase useCase;
  late MockParticipantRepository mockParticipantRepo;
  late MockDivisionRepository mockDivisionRepo;
  late MockTournamentRepository mockTournamentRepo;
  late MockUserRepository mockUserRepo;

  setUp(() {
    mockParticipantRepo = MockParticipantRepository();
    mockDivisionRepo = MockDivisionRepository();
    mockTournamentRepo = MockTournamentRepository();
    mockUserRepo = MockUserRepository();
    useCase = AssignToDivisionUseCase(
      mockParticipantRepo,
      mockDivisionRepo,
      mockTournamentRepo,
      mockUserRepo,
    );
  });

  final tUser = UserEntity(
    id: 'user-id',
    email: 'test@example.com',
    displayName: 'Test User',
    organizationId: 'org-id',
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  final tTournament = TournamentEntity(
    id: 'tournament-id',
    organizationId: 'org-id',
    name: 'Test Tournament',
    scheduledDate: DateTime(2024, 6, 1),
    syncVersion: 1,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  final tDivision = DivisionEntity(
    id: 'division-id',
    tournamentId: 'tournament-id',
    name: 'Test Division',
    category: DivisionCategory.sparring,
    gender: DivisionGender.male,
    bracketFormat: BracketFormat.singleElimination,
    status: DivisionStatus.ready,
    syncVersion: 1,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  final tParticipant = ParticipantEntity(
    id: 'participant-id',
    divisionId: 'old-division-id',
    firstName: 'John',
    lastName: 'Doe',
    syncVersion: 1,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  group('AssignToDivisionUseCase', () {
    test('should assign participant to division successfully', () async {
      // Arrange
      when(() => mockUserRepo.getCurrentUser())
          .thenAnswer((_) async => Right(tUser));
      when(() => mockParticipantRepo.getParticipantById('participant-id'))
          .thenAnswer((_) async => Right(tParticipant));
      when(() => mockDivisionRepo.getDivisionById('division-id'))
          .thenAnswer((_) async => Right(tDivision));
      when(() => mockTournamentRepo.getTournamentById('tournament-id'))
          .thenAnswer((_) async => Right(tTournament));
      when(() => mockParticipantRepo.updateParticipant(any()))
          .thenAnswer((_) async => Right(tParticipant.copyWith(
            divisionId: 'division-id',
            syncVersion: 2,
          )));

      // Act
      final result = await useCase(
        participantId: 'participant-id',
        divisionId: 'division-id',
      );

      // Assert
      expect(result.isRight(), true);
      verify(() => mockParticipantRepo.updateParticipant(any())).called(1);
    });

    test('should return AuthorizationPermissionDeniedFailure when user not logged in', () async {
      // Arrange
      when(() => mockUserRepo.getCurrentUser())
          .thenAnswer((_) async => const Left(AuthenticationFailure(
            userFriendlyMessage: 'Not logged in',
          )));

      // Act
      final result = await useCase(
        participantId: 'participant-id',
        divisionId: 'division-id',
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
        (_) => fail('Should return failure'),
      );
      verifyNever(() => mockParticipantRepo.getParticipantById(any()));
    });

    test('should return AuthorizationPermissionDeniedFailure for wrong organization', () async {
      // Arrange
      final wrongOrgTournament = tTournament.copyWith(organizationId: 'other-org');
      when(() => mockUserRepo.getCurrentUser())
          .thenAnswer((_) async => Right(tUser));
      when(() => mockParticipantRepo.getParticipantById('participant-id'))
          .thenAnswer((_) async => Right(tParticipant));
      when(() => mockDivisionRepo.getDivisionById('division-id'))
          .thenAnswer((_) async => Right(tDivision));
      when(() => mockTournamentRepo.getTournamentById('tournament-id'))
          .thenAnswer((_) async => Right(wrongOrgTournament));

      // Act
      final result = await useCase(
        participantId: 'participant-id',
        divisionId: 'division-id',
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
        (_) => fail('Should return failure'),
      );
      verifyNever(() => mockParticipantRepo.updateParticipant(any()));
    });

    test('should return InputValidationFailure when division is inProgress', () async {
      // Arrange
      final inProgressDivision = tDivision.copyWith(
        status: DivisionStatus.inProgress,
      );
      when(() => mockUserRepo.getCurrentUser())
          .thenAnswer((_) async => Right(tUser));
      when(() => mockParticipantRepo.getParticipantById('participant-id'))
          .thenAnswer((_) async => Right(tParticipant));
      when(() => mockDivisionRepo.getDivisionById('division-id'))
          .thenAnswer((_) async => Right(inProgressDivision));
      when(() => mockTournamentRepo.getTournamentById('tournament-id'))
          .thenAnswer((_) async => Right(tTournament));

      // Act
      final result = await useCase(
        participantId: 'participant-id',
        divisionId: 'division-id',
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<InputValidationFailure>()),
        (_) => fail('Should return failure'),
      );
      verifyNever(() => mockParticipantRepo.updateParticipant(any()));
    });

    test('should return InputValidationFailure for duplicate assignment', () async {
      // Arrange
      final sameDivisionParticipant = tParticipant.copyWith(
        divisionId: 'division-id',
      );
      when(() => mockUserRepo.getCurrentUser())
          .thenAnswer((_) async => Right(tUser));
      when(() => mockParticipantRepo.getParticipantById('participant-id'))
          .thenAnswer((_) async => Right(sameDivisionParticipant));
      when(() => mockDivisionRepo.getDivisionById('division-id'))
          .thenAnswer((_) async => Right(tDivision));
      when(() => mockTournamentRepo.getTournamentById('tournament-id'))
          .thenAnswer((_) async => Right(tTournament));

      // Act
      final result = await useCase(
        participantId: 'participant-id',
        divisionId: 'division-id',
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<InputValidationFailure>());
          expect(
            (failure as InputValidationFailure).userFriendlyMessage,
            contains('already assigned'),
          );
        },
        (_) => fail('Should return failure'),
      );
      verifyNever(() => mockParticipantRepo.updateParticipant(any()));
    });

    test('should allow assignment when division status is setup', () async {
      // Arrange
      final setupDivision = tDivision.copyWith(status: DivisionStatus.setup);
      when(() => mockUserRepo.getCurrentUser())
          .thenAnswer((_) async => Right(tUser));
      when(() => mockParticipantRepo.getParticipantById('participant-id'))
          .thenAnswer((_) async => Right(tParticipant));
      when(() => mockDivisionRepo.getDivisionById('division-id'))
          .thenAnswer((_) async => Right(setupDivision));
      when(() => mockTournamentRepo.getTournamentById('tournament-id'))
          .thenAnswer((_) async => Right(tTournament));
      when(() => mockParticipantRepo.updateParticipant(any()))
          .thenAnswer((_) async => Right(tParticipant.copyWith(
            divisionId: 'division-id',
            syncVersion: 2,
          )));

      // Act
      final result = await useCase(
        participantId: 'participant-id',
        divisionId: 'division-id',
      );

      // Assert
      expect(result.isRight(), true);
    });
  });
}
```

---

## Dev Agent Record

### Agent Model Used

glm-5-free

### Debug Log References

N/A - No issues encountered during implementation.

### Completion Notes List

 - 2026-02-23: Implemented AssignToDivisionUseCase with full authorization, validation, and error handling
 - 2026-02-23: Created 14 comprehensive unit tests covering all acceptance criteria
 - 2026-02-23: All tests pass (14/14) and flutter analyze returns zero new issues
 - 2026-02-23: Followed CreateParticipantUseCase authorization pattern exactly
 - 2026-02-23: Used direct DivisionStatus comparison (no isAssignable getter exists)
 - 2026-02-23: Code review fixes - added input validation for empty IDs (fail fast)
 - 2026-02-23: Code review fixes - added test for updateParticipant failure
 - 2026-02-23: Code review fixes - fixed duplicate import in test file
 - 2026-02-23: Final test count: 17 tests all passing

### File List

**Modified:**
- tkd_brackets/lib/features/participant/domain/usecases/usecases.dart

**Created:**
- tkd_brackets/lib/features/participant/domain/usecases/assign_to_division_usecase.dart
- tkd_brackets/test/features/participant/domain/usecases/assign_to_division_usecase_test.dart

### Change Log

- 2026-02-23: Story created
- 2026-02-23: Story validated and improved — added authorization, fixed DivisionStatus check, scoped to single use case
- 2026-02-23: Implementation complete — AssignToDivisionUseCase created with full test coverage

