# Story 4.3: Manual Participant Entry

Status: review

**Created:** 2026-02-20

**Epic:** 4 - Participant Management

**FRs Covered:** FR13 (Add participants manually)

**Dependencies:** Story 4.2 (Participant Entity & Repository) - COMPLETE | Story 4.1 (Participant Feature Structure) - COMPLETE | Epic 3 (Tournament & Division) - COMPLETE | Epic 2 (Auth) - COMPLETE | Epic 1 (Foundation) - COMPLETE

---

## TL;DR — Critical Facts

**CURRENT STATE:**
- ✅ `lib/features/participant/domain/entities/participant_entity.dart` — ParticipantEntity exists from Story 4.2
- ✅ `lib/features/participant/domain/repositories/participant_repository.dart` — Repository interface exists from Story 4.2
- ✅ `lib/features/participant/data/repositories/participant_repository_implementation.dart` — Repository impl exists from Story 4.2
- ✅ `lib/features/participant/data/models/participant_model.dart` — ParticipantModel exists from Story 4.2
- ✅ `lib/features/participant/data/datasources/participant_local_datasource.dart` — Local datasource exists from Story 4.2
- ✅ `lib/features/participant/data/datasources/participant_remote_datasource.dart` — Remote datasource stub exists from Story 4.2
- ✅ `lib/core/database/tables/participants_table.dart` — Drift table exists (Epic 1) — **DO NOT TOUCH**
- ✅ `ParticipantStatus` enum exists in entity with values: `pending`, `checkedIn`, `noShow`, `withdrawn`
- ✅ `Gender` enum exists in entity with values: `male`, `female`
- ❌ `CreateParticipantUseCase` — **DOES NOT EXIST** — Create in this story
- ❌ `CreateParticipantParams` — **DOES NOT EXIST** — Create in this story
- ❌ Participant feature usecases barrel file — **MAY NOT EXIST** — Create if needed
- ❌ Unit tests for use case — **DOES NOT EXIST** — Create in this story

**TARGET STATE:** Create participant use case with validation for manual participant entry, following the exact pattern from `CreateTournamentUseCase` (Story 3.3).

**KEY PREVIOUS STORY (4.2) LESSONS — APPLY ALL:**
1. Use cases = `@injectable` (transient), Repos/Services = `@lazySingleton` (singleton) — mixing causes state leakage
2. Freezed params class with `part` directive for code generation
3. All methods return `Either<Failure, T>` — use `InputValidationFailure` for validation errors with `fieldErrors` map
4. Always verify organization ID in use cases (prevent cross-org attacks)
5. Run `build_runner build --delete-conflicting-outputs` after ANY generated file changes
6. Entity already has all required fields — use `ParticipantEntity` as return type
7. Repository `createParticipant` method handles local + remote sync — call it from use case
8. **No `field_rename: snake` in `build.yaml`** — json_serializable uses camelCase by default
9. **Failure types from `core/error/failures.dart`:** Use `InputValidationFailure` for validation, `LocalCacheWriteFailure` for write errors, `AuthorizationPermissionDeniedFailure` for org verification failures, `NotFoundFailure` for not found
10. UUID generated using `uuid` package with `static const _uuid = Uuid()` pattern
11. **DI Dependencies Required:** Inject `ParticipantRepository`, `DivisionRepository`, `TournamentRepository`, `UserRepository` — all 4 needed for proper org verification

---

## Story

**As an** organizer,
**I want** to manually add individual participants,
**So that** I can register athletes for my tournament (FR13).

---

## Acceptance Criteria

- [x] **AC1:** `CreateParticipantParams` freezed class in `domain/usecases/` with required fields: `divisionId`, `firstName`, `lastName`, `schoolOrDojangName`, `beltRank` and optional fields: `dateOfBirth`, `gender`, `weightKg`, `registrationNumber`, `notes`

- [x] **AC2:** `CreateParticipantUseCase` extends `UseCase<ParticipantEntity, CreateParticipantParams>` in domain layer with `@injectable` annotation

- [x] **AC3:** Input validation rejects:
  - Empty/whitespace-only firstName → `InputValidationFailure` with field error
  - Empty/whitespace-only lastName → `InputValidationFailure` with field error
  - Empty/whitespace-only schoolOrDojangName → `InputValidationFailure` with field error
  - Empty/whitespace-only beltRank → `InputValidationFailure` with field error
  - Invalid beltRank (not a valid TKD belt from BeltRank enum) → `InputValidationFailure` with field error
  - weightKg < 0 → `InputValidationFailure` with field error
  - weightKg > 150 (unrealistic for TKD) → `InputValidationFailure` with field error
  - Invalid dateOfBirth (future date) → `InputValidationFailure` with field error
  - dateOfBirth results in age < 4 or > 80 → `InputValidationFailure` with field error

- [x] **AC4:** UUID generated using `uuid` package for participant ID

- [x] **AC5:** Participant created with defaults: `checkInStatus: ParticipantStatus.pending`, `isBye: false`, `seedNumber: null`, `syncVersion: 1`, `isDeleted: false`, `isDemoData: false`

- [x] **AC6:** Use case verifies division exists and belongs to user's organization via the following EXACT flow:
  1. Get current user via `UserRepository.getCurrentUser()` → extract `organizationId`
  2. Get division via `DivisionRepository.getDivisionById(divisionId)`
  3. Get tournament via `TournamentRepository.getTournamentById(division.tournamentId)`
  4. Compare `tournament.organizationId` with user's `organizationId`
  5. If mismatch, return `Left(AuthorizationPermissionDeniedFailure(...))` — NOT `AuthFailure`
  6. If division not found, return `NotFoundFailure`

- [x] **AC7:** Delegates to `ParticipantRepository.createParticipant()` to persist (local + remote sync handled by repo)

- [x] **AC8:** Error cases propagated as `Either<Failure, ParticipantEntity>`

- [x] **AC9:** Unit tests verify: validation rules, successful creation, error paths

- [x] **AC10:** Exports added to usecases barrel file (create if doesn't exist) and main `participant.dart` barrel

- [x] **AC11:** `flutter analyze` passes with zero new errors

- [x] **AC12:** `dart run build_runner build --delete-conflicting-outputs` succeeds

- [x] **AC13:** Existing infrastructure UNTOUCHED — `participants_table.dart`, `app_database.dart`, `ParticipantEntity`, `ParticipantModel`, `ParticipantRepository` unmodified

---

## Tasks / Subtasks

### Task 1: Verify Current State (AC: #13)

> **⚠️ CRITICAL: Do this FIRST before creating anything.**

- [x] 1.1: Verify `ParticipantEntity` exists in `lib/features/participant/domain/entities/participant_entity.dart` — read it to understand all fields
- [x] 1.2: Verify `ParticipantRepository` interface exists in `lib/features/participant/domain/repositories/participant_repository.dart` — read it to see available methods
- [x] 1.3: Verify `ParticipantRepositoryImplementation` exists in `lib/features/participant/data/repositories/participant_repository_implementation.dart` — read it to see create method signature
- [x] 1.4: Read `lib/features/tournament/domain/usecases/create_tournament_usecase.dart` for use case pattern reference
- [x] 1.5: Read `lib/features/tournament/domain/usecases/create_tournament_params.dart` for params pattern reference
- [x] 1.6: Read `lib/core/error/failures.dart` to verify `InputValidationFailure` is available

### Task 2: Create CreateParticipantParams (AC: #1)

- [x] 2.1: Create `lib/features/participant/domain/usecases/create_participant_params.dart`

### Task 3: Create CreateParticipantUseCase (AC: #2, #3, #4, #5, #6, #7, #8)

- [x] 3.1: Create `lib/features/participant/domain/usecases/create_participant_usecase.dart`

### Task 4: Update Barrel Files (AC: #10)

- [x] 4.1: Create or update `lib/features/participant/domain/usecases/usecases.dart` barrel file
- [x] 4.2: Update `lib/features/participant/participant.dart` to export new usecases

### Task 5: Run Code Generation (AC: #12)

- [x] 5.1: Run `dart run build_runner build --delete-conflicting-outputs` from `tkd_brackets/`
- [x] 5.2: Verify these generated files are created:
  - `create_participant_params.freezed.dart`
- [x] 5.3: Verify NO orphaned generated files exist

### Task 6: Create Use Case Tests (AC: #9)

- [x] 6.1: Create `test/features/participant/domain/usecases/create_participant_usecase_test.dart`

### Task 7: Verify Project Integrity (AC: #11, #13)

- [x] 7.1: Run `flutter analyze` from `tkd_brackets/` — zero new issues
- [x] 7.2: Run `dart run build_runner build --delete-conflicting-outputs` — succeeds
- [x] 7.3: Run ALL participant tests: `flutter test test/features/participant/` — all pass
- [x] 7.4: Verify existing tests to verify no regressions: `flutter test` (full suite)
- [x] 7.5: Verify `git diff lib/core/database/tables/participants_table.dart` — NO changes
- [x] 7.6: Verify `git diff lib/features/participant/domain/entities/participant_entity.dart` — NO changes
- [x] 7.7: Verify `git diff lib/features/participant/data/models/participant_model.dart` — NO changes
- [x] 7.8: Verify `git diff lib/features/participant/domain/repositories/participant_repository.dart` — NO changes
- [x] 7.9: Verify `git diff lib/features/participant/data/repositories/participant_repository_implementation.dart` — NO changes

---

## Dev Notes

### Architecture Patterns — MANDATORY

**Use Case Pattern (from CreateTournamentUseCase):**
- Use `@injectable` annotation (NOT `@LazySingleton`)
- Extend `UseCase<Entity, Params>` base class
- Return `Future<Either<Failure, Entity>>`
- First validate inputs, then call repository

**Params Pattern (freezed):**
- Use `@freezed` annotation with `_$Params` mixin
- Use `const factory` constructor with named parameters
- Use `part` directive for `.freezed.dart` generated file only
- NO `.g.dart` part needed (params don't need JSON serialization)

**Validation Pattern:**
- Collect errors in `Map<String, String>` called `fieldErrors`
- Return `Left(InputValidationFailure(userFriendlyMessage: '...', fieldErrors: fieldErrors))` when validation fails
- Field keys match form field names for UI error display

**UUID Generation Pattern:**
```dart
import 'package:uuid/uuid.dart';

class CreateParticipantUseCase ... {
  static const _uuid = Uuid();
  
  Future<Either<Failure, ParticipantEntity>> call(...) async {
    final participantId = _uuid.v4();
    // ... rest of implementation
  }
}
```

### Complete Use Case Skeleton

```dart
// lib/features/participant/domain/usecases/create_participant_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/create_participant_params.dart';
import 'package:uuid/uuid.dart';

@injectable
class CreateParticipantUseCase
    extends UseCase<ParticipantEntity, CreateParticipantParams> {
  CreateParticipantUseCase(
    this._participantRepository,
    this._divisionRepository,
    this._tournamentRepository,
    this._userRepository,
  );

  final ParticipantRepository _participantRepository;
  final DivisionRepository _divisionRepository;
  final TournamentRepository _tournamentRepository;
  final UserRepository _userRepository;
  
  static const _uuid = Uuid();

  @override
  Future<Either<Failure, ParticipantEntity>> call(
    CreateParticipantParams params,
  ) async {
    // Step 1: Validate inputs (AC3)
    final validationErrors = _validateInputs(params);
    if (validationErrors.isNotEmpty) {
      return Left(InputValidationFailure(
        userFriendlyMessage: 'Please fix the validation errors',
        fieldErrors: validationErrors,
      ));
    }

    // Step 2: Get current user and verify organization (AC6)
    final userResult = await _userRepository.getCurrentUser();
    final user = userResult.fold(
      (failure) => null,
      (user) => user,
    );
    
    if (user == null || user.organizationId.isEmpty) {
      return const Left(AuthorizationPermissionDeniedFailure(
        userFriendlyMessage: 'You must be logged in with an organization to add participants',
      ));
    }

    // Step 3: Verify division belongs to user's organization
    final divisionResult = await _divisionRepository.getDivisionById(params.divisionId);
    final division = divisionResult.fold(
      (failure) => null,
      (division) => division,
    );
    
    if (division == null) {
      return const Left(NotFoundFailure(
        userFriendlyMessage: 'Division not found',
      ));
    }

    // Step 4: Get tournament to verify organization ownership
    final tournamentResult = await _tournamentRepository.getTournamentById(division.tournamentId);
    final tournament = tournamentResult.fold(
      (failure) => null,
      (tournament) => tournament,
    );
    
    if (tournament == null) {
      return const Left(NotFoundFailure(
        userFriendlyMessage: 'Tournament not found',
      ));
    }
    
    if (tournament.organizationId != user.organizationId) {
      return const Left(AuthorizationPermissionDeniedFailure(
        userFriendlyMessage: 'You do not have permission to add participants to this division',
      ));
    }

    // Step 5: Create participant entity with defaults (AC4, AC5)
    final now = DateTime.now();
    final participant = ParticipantEntity(
      id: _uuid.v4(),
      divisionId: params.divisionId,
      firstName: params.firstName.trim(),
      lastName: params.lastName.trim(),
      dateOfBirth: params.dateOfBirth,
      gender: params.gender,
      weightKg: params.weightKg,
      schoolOrDojangName: params.schoolOrDojangName.trim(),
      beltRank: params.beltRank.trim(),
      seedNumber: null,
      registrationNumber: params.registrationNumber?.trim(),
      isBye: false,
      checkInStatus: ParticipantStatus.pending,
      checkInAtTimestamp: null,
      photoUrl: null,
      notes: params.notes?.trim(),
      syncVersion: 1,
      isDeleted: false,
      deletedAtTimestamp: null,
      isDemoData: false,
      createdAtTimestamp: now,
      updatedAtTimestamp: now,
    );

    // Step 6: Persist via repository (AC7, AC8)
    return _participantRepository.createParticipant(participant);
  }

  Map<String, String> _validateInputs(CreateParticipantParams params) {
    final errors = <String, String>{};
    
    if (params.firstName.trim().isEmpty) {
      errors['firstName'] = 'First name is required';
    }
    
    if (params.lastName.trim().isEmpty) {
      errors['lastName'] = 'Last name is required';
    }
    
    if (params.schoolOrDojangName.trim().isEmpty) {
      errors['schoolOrDojangName'] = 'Dojang name is required';
    }
    
    if (params.beltRank.trim().isEmpty) {
      errors['beltRank'] = 'Belt rank is required';
    }
    // TODO: Add BeltRank enum validation
    
    if (params.weightKg != null && params.weightKg! < 0) {
      errors['weightKg'] = 'Weight cannot be negative';
    }
    if (params.weightKg != null && params.weightKg! > 150) {
      errors['weightKg'] = 'Weight exceeds maximum allowed (150kg)';
    }
    
    if (params.dateOfBirth != null) {
      final now = DateTime.now();
      if (params.dateOfBirth.isAfter(now)) {
        errors['dateOfBirth'] = 'Date of birth cannot be in the future';
      }
      final age = _calculateAge(params.dateOfBirth!);
      if (age < 4 || age > 80) {
        errors['dateOfBirth'] = 'Participant age must be between 4 and 80 years';
      }
    }
    
    return errors;
  }

  int _calculateAge(DateTime dateOfBirth) {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
}
```

### ParticipantEntity Fields (from Story 4.2)

| Field | Type | Required | Default |
|-------|------|----------|---------|
| `id` | String | Yes | Generated (UUID) |
| `divisionId` | String | Yes | From params |
| `firstName` | String | Yes | From params |
| `lastName` | String | Yes | From params |
| `dateOfBirth` | DateTime? | No | null |
| `gender` | Gender? | No | null |
| `weightKg` | double? | No | null |
| `schoolOrDojangName` | String | Yes | From params |
| `beltRank` | String | Yes | From params |
| `seedNumber` | int? | No | null |
| `registrationNumber` | String? | No | null |
| `isBye` | bool | Yes | false |
| `checkInStatus` | ParticipantStatus | Yes | ParticipantStatus.pending |
| `checkInAtTimestamp` | DateTime? | No | null |
| `photoUrl` | String? | No | null |
| `notes` | String? | No | null |
| `syncVersion` | int | Yes | 1 |
| `isDeleted` | bool | Yes | false |
| `deletedAtTimestamp` | DateTime? | No | null |
| `isDemoData` | bool | Yes | false |
| `createdAtTimestamp` | DateTime | Yes | Now |
| `updatedAtTimestamp` | DateTime | Yes | Now |

### Enums (already defined in ParticipantEntity)

**ParticipantStatus:**
- `pending` — Default, participant registered but not checked in
- `checkedIn` — Participant has checked in at venue
- `noShow` — Participant did not show up
- `withdrawn` — Participant withdrew from tournament

**Gender:**
- `male`
- `female`

### BeltRank Validation — CRITICAL FOR SEEDING

**⚠️ MUST VALIDATE against valid TKD belt ranks!**

The `BeltRank` enum exists in `lib/features/division/domain/entities/belt_rank.dart`. This is CRITICAL because:
1. Invalid belt ranks will break the seeding algorithm (Story 5.7)
2. Belt rank determines division eligibility
3. Used for dojang separation logic

**Valid TKD Belts (from BeltRank enum):**
- White (beginner)
- Yellow (9th kup)
- Orange (8th kup)
- Green (7th kup)
- Blue (5th-6th kup)
- Red (3rd-4th kup)
- Black 1st Dan through Black 9th Dan

**Validation Required:**
```dart
import 'package:tkd_brackets/features/division/domain/entities/belt_rank.dart';

// In _validateInputs method:
final beltRank = BeltRank.fromString(params.beltRank.trim());
if (beltRank == null) {
  errors['beltRank'] = 'Invalid belt rank. Use standard TKD belt names (e.g., White, Yellow, Green, Blue, Red, Black 1st Dan)';
}
```

### Clean Architecture Layer Rules — ENFORCED

| Layer            | Can Depend On            | CANNOT Depend On                  |
| ---------------- | ------------------------ | --------------------------------- |
| **Presentation** | Domain                   | Data                              |
| **Domain**       | Nothing (core only)      | Data, Presentation, External SDKs |
| **Data**         | Domain (interfaces only) | Presentation                      |

### File Structure After This Story

```
lib/features/participant/
├── participant.dart                                    ← Updated barrel
├── data/
│   ├── datasources/                                   ← Unchanged from 4.2
│   ├── models/                                        ← Unchanged from 4.2
│   └── repositories/                                 ← Unchanged from 4.2
├── domain/
│   ├── entities/                                     ← Unchanged from 4.2
│   │   └── participant_entity.dart
│   ├── repositories/                                 ← Unchanged from 4.2
│   │   └── participant_repository.dart
│   └── usecases/
│       ├── usecases.dart                             ← NEW (or updated)
│       ├── create_participant_params.dart             ← NEW
│       ├── create_participant_params.freezed.dart    ← GENERATED
│       └── create_participant_usecase.dart           ← NEW
└── presentation/                                     ← Empty (Story 4.12)
```

### Project Structure Notes

- All new files are within `lib/features/participant/domain/usecases/`
- No modifications to `lib/core/` — existing database and infrastructure are reused as-is
- No modifications to `lib/features/tournament/` or `lib/features/division/`
- Barrel file follows existing export organization pattern
- Generated files (`.freezed.dart`) created by `build_runner`

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 4, Story 4.3]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Clean Architecture, Use Case Pattern]
- [Source: `_bmad-output/implementation-artifacts/4-2-participant-entity-and-repository.md` — Previous story, entity/repository patterns]
- [Source: `_bmad-output/implementation-artifacts/3-3-create-tournament-use-case.md` — Use case pattern reference]
- [Source: `_bmad-output/implementation-artifacts/3-10-custom-division-creation.md` — BeltRank enum usage reference]
- [Source: `tkd_brackets/lib/features/participant/domain/entities/participant_entity.dart` — Entity definition]
- [Source: `tkd_brackets/lib/features/participant/domain/repositories/participant_repository.dart` — Repository interface]
- [Source: `tkd_brackets/lib/features/participant/data/repositories/participant_repository_implementation.dart` — Repository impl]
- [Source: `tkd_brackets/lib/features/division/domain/entities/belt_rank.dart` — **BeltRank enum for validation**]
- [Source: `tkd_brackets/lib/features/division/domain/entities/division_entity.dart` — DivisionEntity for org verification]
- [Source: `tkd_brackets/lib/features/division/domain/repositories/division_repository.dart` — DivisionRepository]
- [Source: `tkd_brackets/lib/features/tournament/domain/repositories/tournament_repository.dart` — TournamentRepository]
- [Source: `tkd_brackets/lib/features/auth/domain/repositories/user_repository.dart` — UserRepository]
- [Source: `tkd_brackets/lib/core/error/failures.dart` — Failure types including InputValidationFailure, AuthorizationPermissionDeniedFailure, NotFoundFailure]
- [Source: `tkd_brackets/lib/core/usecases/use_case.dart` — UseCase base class]

---

## Anti-Patterns — WHAT NOT TO DO

| ❌ Don't Do This                                            | ✅ Do This Instead                                                                                                                 | Source                   |
| ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ------------------------ |
| Import `drift` or `supabase_flutter` in domain layer       | Domain only uses `fpdart`, `freezed`, core Dart                                                                                   | Architecture doc         |
| Use `@LazySingleton` on use case                            | Use `@injectable` on use cases (transient), `@LazySingleton` on repositories (singleton)                                            | Epic 2/3 lessons         |
| Use `CacheFailure` for validation errors                    | Use `InputValidationFailure` with `fieldErrors` map for validation                                                               | CreateTournament pattern |
| Use `AuthFailure` for organization permission denial         | Use `AuthorizationPermissionDeniedFailure` for org verification failures                                                        | This story               |
| Return raw types from use case                              | Return `Either<Failure, Entity>`                                                                                                 | Architecture pattern     |
| Skip validation                                             | Validate all required fields: firstName, lastName, schoolOrDojangName, beltRank                                                    | AC3                      |
| Skip organization/division verification                     | Verify division belongs to user's organization: get user → get division → get tournament → compare org IDs                          | AC6                      |
| Skip BeltRank enum validation                               | Validate beltRank against `BeltRank.fromString()` — invalid belts break seeding algorithm                                       | Critical for Epic 5      |
| Use wrong repository for verification                       | Use all 4: ParticipantRepository, DivisionRepository, TournamentRepository, UserRepository                                        | AC6                      |
| Hardcode UUID without using uuid package                    | Use `static const _uuid = Uuid()` then `_uuid.v4()`                                                                              | UUID pattern             |
| Use `@JsonKey` on params class                              | Params classes don't need JSON serialization — only use `@freezed`                                                               | Use case pattern         |
| Create participant with wrong default values               | Use: `checkInStatus: ParticipantStatus.pending`, `isBye: false`, `syncVersion: 1`, `isDeleted: false`, `isDemoData: false`     | AC5                      |
| Return `void` or throw exceptions from use case             | Return `Either<Failure, ParticipantEntity>` — exceptions handled by repository                                                   | Architecture pattern     |
| Modify existing entity, model, or repository files           | Only add new use case files — existing infrastructure is complete from Story 4.2                                                  | AC13                     |
| Skip age/weight range validation                           | Validate: age 4-80 years, weight 0-150kg — prevents unrealistic data                                                            | AC3                      |

---

## Previous Story Intelligence

### From Story 4.2: Participant Entity & Repository

**Key Learnings:**
1. **DI Registration:** Use `@injectable` for use cases (transient), `@LazySingleton` for repositories/datasources (singleton)
2. **Freezed + JsonKey:** Model uses selective `@JsonKey(name: 'snake_case')` only where camelCase ≠ snake_case — NO `field_rename` in build.yaml
3. **Model conversions:** Entity ↔ Model ↔ Drift Entry conversion methods needed
4. **Repository manages sync:** Use cases call repository methods, repository handles local + remote sync
5. **Failure types:** Use `LocalCacheAccessFailure` for read errors, `LocalCacheWriteFailure` for write errors, `InputValidationFailure` for validation
6. **4 dependencies in repo constructor:** Local datasource, remote datasource, connectivity service, app database
7. **Code generation required:** Run `build_runner` after any generated file changes
8. **Tests mirror source structure:** `test/features/participant/domain/usecases/` for use case tests

---

## Dev Agent Record

### Agent Model Used

opencode/glm-5-free

### Debug Log References

### Completion Notes List

- ✅ Task 1 complete: Verified all existing infrastructure (ParticipantEntity, ParticipantRepository, CreateTournamentUseCase pattern, failures)
- ✅ Task 2 complete: Created CreateParticipantParams with freezed pattern (required: divisionId, firstName, lastName, schoolOrDojangName, beltRank; optional: dateOfBirth, gender, weightKg, registrationNumber, notes)
- ✅ Task 3 complete: Created CreateParticipantUseCase with @injectable, full validation (including belt rank validation), org verification flow, UUID generation, and proper defaults
- ✅ Task 4 complete: Created usecases.dart barrel file, updated participant.dart barrel
- ✅ Task 5 complete: build_runner generated create_participant_params.freezed.dart successfully
- ✅ Task 6 complete: Created 23 comprehensive unit tests covering validation, org verification, and successful creation
- ✅ Task 7 complete: flutter analyze passes with zero new issues, all 76 participant tests pass, existing infrastructure verified unchanged

### File List

## New Files Created
- `lib/features/participant/domain/usecases/create_participant_params.dart`
- `lib/features/participant/domain/usecases/create_participant_params.freezed.dart` (generated)
- `lib/features/participant/domain/usecases/create_participant_usecase.dart`
- `lib/features/participant/domain/usecases/usecases.dart`
- `test/features/participant/domain/usecases/create_participant_usecase_test.dart`

## Modified Files
- `lib/features/participant/participant.dart` (barrel file - added usecases exports)

## Files Verified Unchanged (as required)
- `lib/core/database/tables/participants_table.dart` - NO CHANGES
- `lib/core/database/app_database.dart` - NO CHANGES
- `lib/features/participant/domain/entities/participant_entity.dart` - NO CHANGES
- `lib/features/participant/data/models/participant_model.dart` - NO CHANGES
- `lib/features/participant/domain/repositories/participant_repository.dart` - NO CHANGES
- `lib/features/participant/data/repositories/participant_repository_implementation.dart` - NO CHANGES

---

## Completion Status

**Status:** review

**Completion Note:** Story implementation complete. All 13 acceptance criteria satisfied. 23 unit tests passing. Zero new analysis issues. Infrastructure untouched.

**Next Steps:**
1. Run `code-review` workflow for peer review (recommend using a different LLM)
2. Verify DI registration works by running the app
