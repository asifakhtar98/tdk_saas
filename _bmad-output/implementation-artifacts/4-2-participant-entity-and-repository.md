# Story 4.2: Participant Entity & Repository

Status: review

**Created:** 2026-02-19

**Epic:** 4 - Participant Management

**FRs Covered:** FR13-FR19 (foundational entity & repository for all participant operations)

**Dependencies:** Story 4.1 (Participant Feature Structure) - COMPLETE | Epic 3 (Tournament & Division) - COMPLETE | Epic 2 (Auth) - COMPLETE | Epic 1 (Foundation) - COMPLETE

---

## TL;DR — Critical Facts

**CURRENT STATE:**
- ✅ `lib/features/participant/` — Feature structure exists (empty dirs + barrel + README) from Story 4.1
- ✅ `lib/core/database/tables/participants_table.dart` — Drift table exists (Epic 1) — **DO NOT TOUCH**
- ✅ `AppDatabase` has CRUD methods: `getParticipantsForDivision`, `getParticipantById`, `insertParticipant`, `updateParticipant`, `softDeleteParticipant`, `getActiveParticipants` — **DO NOT TOUCH**
- ✅ `DivisionRepository.getParticipantsForDivision()` — returns `ParticipantEntry` (Drift type), NOT domain entities — **DO NOT TOUCH**
- ❌ `ParticipantEntity` — **DOES NOT EXIST** — Create in this story
- ❌ `ParticipantModel` — **DOES NOT EXIST** — Create in this story  
- ❌ `ParticipantRepository` (interface) — **DOES NOT EXIST** — Create in this story
- ❌ `ParticipantRepositoryImplementation` — **DOES NOT EXIST** — Create in this story
- ❌ `ParticipantLocalDatasource` — **DOES NOT EXIST** — Create in this story
- ❌ `ParticipantRemoteDatasource` — **DOES NOT EXIST** — Create in this story

**TARGET STATE:** Complete domain entity, data model, datasource layer (local + remote stubs), repository interface, and repository implementation — following EXACT patterns from `tournament` and `division` features.

**EPICS AC vs DB SCHEMA RECONCILIATION:**
> The epics AC says entity should contain: `firstName`, `lastName`, `dateOfBirth`, `age`, `gender`, `dojangName`, `dojangRegion`, `beltRank`, `weight`, `status`.
> **Differences from Drift table (source of truth):**
> - `age` → NOT a stored column. Implement as computed getter from `dateOfBirth` on the entity.
> - `dojangName` → Maps to Drift column `school_or_dojang_name` (entity field: `schoolOrDojangName`).
> - `dojangRegion` → **NOT in Drift table**. Excluded from this story. Will be added if/when schema migrates.
> - `weight` → Maps to Drift column `weight_kg` (entity field: `weightKg`).
> - `status` → Maps to Drift column `check_in_status` (entity field: `checkInStatus` with `ParticipantStatus` enum).
> - Additional Drift columns included: `seedNumber`, `registrationNumber`, `isBye`, `checkInAtTimestamp`, `photoUrl`, `notes`, `syncVersion`, `isDeleted`, `deletedAtTimestamp`, `isDemoData`, `createdAtTimestamp`, `updatedAtTimestamp`.

**KEY EPIC 2 & 3 LESSONS — APPLY ALL:**
1. Use cases = `@injectable` (transient), Repos/Services = `@lazySingleton` — mixing causes state leakage
2. `@JsonKey(name: 'snake_case')` only needed on model fields where camelCase ≠ snake_case (e.g., `divisionId` → `@JsonKey(name: 'division_id')`). Fields like `id`, `gender`, `notes` DON'T need `@JsonKey` because they're the same in both cases. **Follow TournamentModel's selective pattern.**
3. Clean up orphaned `.freezed.dart`/`.g.dart` files when renaming
4. Repository manages `sync_version`, NOT use cases — Database transaction handles increment
5. Always verify organization ID in use cases (prevent cross-org attacks)
6. Run `build_runner build --delete-conflicting-outputs` after ANY generated file changes
7. Model needs `fromDriftEntry`, `fromJson`, `convertToEntity`, `toDriftCompanion`, `convertFromEntity`
8. Entity uses `freezed` for immutability; Model uses `freezed` + `json_serializable`
9. Datasource abstract + implementation in SAME file (e.g., `tournament_local_datasource.dart`)
10. `// ignore_for_file: invalid_annotation_target` at top of Model file for freezed `@JsonKey`
11. **No `field_rename: snake` in `build.yaml`** — json_serializable uses camelCase by default. You MUST add `@JsonKey` on every field that differs from camelCase.
12. **Failure types from `core/error/failures.dart`:** Use `LocalCacheAccessFailure` for read errors, `LocalCacheWriteFailure` for write errors, `NotFoundFailure` for not-found. There is NO `CacheFailure` class.
13. Repository constructor MUST inject ALL 4 dependencies (local datasource, remote datasource, connectivity service, app database) for forward compatibility with tournament pattern — even though remote calls are wrapped in try/catch that silently fail for now.

---

## Story

**As a** developer,
**I want** the Participant entity and repository implemented,
**So that** athlete data can be managed with TKD-specific attributes.

---

## Acceptance Criteria

- [x] **AC1**: `ParticipantEntity` freezed class in `domain/entities/participant_entity.dart` with fields: `id`, `divisionId`, `firstName`, `lastName`, `dateOfBirth`, `gender`, `weightKg`, `schoolOrDojangName`, `beltRank`, `seedNumber`, `registrationNumber`, `isBye`, `checkInStatus`, `checkInAtTimestamp`, `photoUrl`, `notes`, `syncVersion`, `isDeleted`, `deletedAtTimestamp`, `isDemoData`, `createdAtTimestamp`, `updatedAtTimestamp` PLUS computed `age` getter derived from `dateOfBirth`

- [x] **AC2**: `ParticipantStatus` enum in same entity file with values: `pending`, `checkedIn`, `noShow`, `withdrawn` (mapping to DB `check_in_status` column values: `'pending'`, `'checked_in'`, `'no_show'`, `'withdrawn'`)

- [x] **AC3**: `Gender` enum in same entity file with values: `male`, `female` (mapping to DB string values)

- [x] **AC4**: `ParticipantModel` freezed class in `data/models/participant_model.dart` with SELECTIVE `@JsonKey(name: 'snake_case')` on fields where camelCase ≠ snake_case (following TournamentModel pattern; NO build.yaml `field_rename`), plus conversion methods: `fromJson`, `fromDriftEntry`, `convertToEntity`, `toDriftCompanion`, `convertFromEntity`

- [x] **AC5**: `ParticipantRepository` abstract class in `domain/repositories/participant_repository.dart` with CRUD methods returning `Either<Failure, T>`

- [x] **AC6**: `ParticipantRepositoryImplementation` in `data/repositories/participant_repository_implementation.dart` implementing `ParticipantRepository` with `@LazySingleton(as: ParticipantRepository)` annotation

- [x] **AC7**: `ParticipantLocalDatasource` (abstract + implementation) in `data/datasources/participant_local_datasource.dart` with `@LazySingleton` annotation, wrapping `AppDatabase` participant methods

- [x] **AC8**: `ParticipantRemoteDatasource` (abstract + implementation stub) in `data/datasources/participant_remote_datasource.dart` — stub implementation that throws `UnimplementedError` for all methods (Supabase integration deferred)

- [x] **AC9**: Barrel file `participant.dart` updated with exports for all new files

- [x] **AC10**: Unit tests for entity creation and enum parsing in `test/features/participant/domain/entities/participant_entity_test.dart`

- [x] **AC11**: Unit tests for model conversion methods in `test/features/participant/data/models/participant_model_test.dart`

- [x] **AC12**: Unit tests for repository CRUD operations in `test/features/participant/data/repositories/participant_repository_implementation_test.dart`

- [x] **AC13**: Unit tests for local datasource in `test/features/participant/data/datasources/participant_local_datasource_test.dart`

- [x] **AC14**: `flutter analyze` passes with zero new errors

- [x] **AC15**: `dart run build_runner build --delete-conflicting-outputs` succeeds

- [x] **AC16**: Existing infrastructure UNTOUCHED — `participants_table.dart`, `app_database.dart`, `DivisionRepository` participant methods unmodified

---

## Tasks / Subtasks

### Task 1: Verify Current State (AC: #16)

> **⚠️ CRITICAL: Do this FIRST before creating anything.**

- [x] 1.1: Verify `lib/features/participant/` structure exists with empty subdirs from Story 4.1
- [x] 1.2: Verify `lib/core/database/tables/participants_table.dart` EXISTS — read it to understand all columns
- [x] 1.3: Read `lib/core/database/app_database.dart` participant CRUD methods to understand DB API
- [x] 1.4: Read `lib/features/tournament/domain/entities/tournament_entity.dart` for entity pattern
- [x] 1.5: Read `lib/features/tournament/data/models/tournament_model.dart` for model pattern (freezed + JsonKey + Drift conversion)
- [x] 1.6: Read `lib/features/tournament/data/datasources/tournament_local_datasource.dart` for datasource pattern
- [x] 1.7: Read `lib/features/tournament/domain/repositories/tournament_repository.dart` for repository interface pattern
- [x] 1.8: Read `lib/features/tournament/data/repositories/tournament_repository_implementation.dart` for repository impl pattern

### Task 2: Create ParticipantEntity (AC: #1, #2, #3)

- [x] 2.1: Create `lib/features/participant/domain/entities/participant_entity.dart`

### Task 3: Create ParticipantModel (AC: #4)

- [x] 3.1: Create `lib/features/participant/data/models/participant_model.dart`

### Task 4: Create ParticipantLocalDatasource (AC: #7)

- [x] 4.1: Create `lib/features/participant/data/datasources/participant_local_datasource.dart`

### Task 5: Create ParticipantRemoteDatasource Stub (AC: #8)

- [x] 5.1: Create `lib/features/participant/data/datasources/participant_remote_datasource.dart`

### Task 6: Create ParticipantRepository Interface (AC: #5)

- [x] 6.1: Create `lib/features/participant/domain/repositories/participant_repository.dart`

### Task 7: Create ParticipantRepositoryImplementation (AC: #6)

- [x] 7.1: Create `lib/features/participant/data/repositories/participant_repository_implementation.dart`

### Task 8: Update Barrel File (AC: #9)

- [x] 8.1: Update `lib/features/participant/participant.dart` to export all new files

### Task 9: Run Code Generation (AC: #15)

- [x] 9.1: Run `dart run build_runner build --delete-conflicting-outputs` from `tkd_brackets/`
- [x] 9.2: Verify these generated files are created:
  - `participant_entity.freezed.dart`
  - `participant_model.freezed.dart`
  - `participant_model.g.dart`
  - `injection.config.dart` (should auto-discover new `@LazySingleton` and `@injectable` annotations)
- [x] 9.3: Verify NO orphaned generated files exist

### Task 10: Create Entity Tests (AC: #10)

- [x] 10.1: Create `test/features/participant/domain/entities/participant_entity_test.dart`

### Task 11: Create Model Tests (AC: #11)

- [x] 11.1: Create `test/features/participant/data/models/participant_model_test.dart`

### Task 12: Create Local Datasource Tests (AC: #13)

- [x] 12.1: Create `test/features/participant/data/datasources/participant_local_datasource_test.dart`

### Task 13: Create Repository Tests (AC: #12)

- [x] 13.1: Create `test/features/participant/data/repositories/participant_repository_implementation_test.dart`

### Task 14: Verify Project Integrity (AC: #14, #15, #16)

- [x] 14.1: Run `flutter analyze` from `tkd_brackets/` — zero new issues
- [x] 14.2: Run `dart run build_runner build --delete-conflicting-outputs` — succeeds
- [x] 14.3: Run ALL participant tests: `flutter test test/features/participant/` — all pass
- [x] 14.4: Run existing tests to verify no regressions: `flutter test` (full suite)
- [x] 14.5: Verify `git diff lib/core/database/tables/participants_table.dart` — NO changes
- [x] 14.6: Verify `git diff lib/core/database/app_database.dart` — NO changes
- [x] 14.7: Verify structure test still passes: `flutter test test/features/participant/structure_test.dart`

---

## Dev Notes

### Architecture Patterns — MANDATORY

**Entity Pattern (freezed):**
- Use `@freezed` annotation with `_$ParticipantEntity` mixin
- Use `const factory` constructor with named parameters
- Domain enums in same file with `fromString` static factory
- `part` directive for `.freezed.dart` generated file only
- NO `.g.dart` part needed (entities don't need JSON serialization)

**Model Pattern (freezed + json_serializable):**
- `// ignore_for_file: invalid_annotation_target` at top of file
- `import 'package:drift/drift.dart' hide JsonKey;` — MUST hide `JsonKey` to avoid conflict
- `@freezed` + SELECTIVE `@JsonKey(name: 'snake_case')` only where camelCase ≠ snake_case
- `part` directives for BOTH `.freezed.dart` AND `.g.dart`
- Private constructor `const ParticipantModel._();` required for adding methods
- Conversion methods: `fromJson`, `fromDriftEntry`, `convertToEntity`, `toDriftCompanion`, `convertFromEntity`
- **No `field_rename: snake` config exists in `build.yaml`** — json_serializable uses camelCase by default

**Repository Pattern:**
- Interface in `domain/repositories/` — abstract class, no framework imports
- Implementation in `data/repositories/` — `@LazySingleton(as: ParticipantRepository)`, injects ALL 4 deps (local, remote, connectivity, database)
- All methods return `Future<Either<Failure, T>>`
- Catch all exceptions → `LocalCacheAccessFailure` for reads, `LocalCacheWriteFailure` for writes (NO `CacheFailure` exists)

**Datasource Pattern:**
- Abstract + implementation in SAME file
- `@LazySingleton(as: ParticipantLocalDatasource)` on implementation
- Methods return raw models (not `Either<Failure, T>` — that's the repository's job)
- Wraps `AppDatabase` calls with model conversion

### Existing AppDatabase Participant Methods (DO NOT MODIFY)

```dart
// Already implemented in core/database/app_database.dart:
getParticipantsForDivision(String divisionId) → Future<List<ParticipantEntry>>
getParticipantById(String id) → Future<ParticipantEntry?>
insertParticipant(ParticipantsCompanion participant) → Future<int>
updateParticipant(String id, ParticipantsCompanion participant) → Future<bool>  // Increments sync_version in transaction
softDeleteParticipant(String id) → Future<bool>
getActiveParticipants() → Future<List<ParticipantEntry>>  // For testing
```

### Drift ParticipantEntry Columns (from participants_table.dart)

| Column               | Dart Type        | DB Name                 | Nullable | Notes                                                  |
| -------------------- | ---------------- | ----------------------- | -------- | ------------------------------------------------------ |
| `id`                 | `TextColumn`     | `id`                    | No       | PK, UUID as TEXT                                       |
| `divisionId`         | `TextColumn`     | `division_id`           | No       | FK → divisions                                         |
| `firstName`          | `TextColumn`     | `first_name`            | No       | Required                                               |
| `lastName`           | `TextColumn`     | `last_name`             | No       | Required                                               |
| `dateOfBirth`        | `DateTimeColumn` | `date_of_birth`         | Yes      | Age verification                                       |
| `gender`             | `TextColumn`     | `gender`                | Yes      | 'male', 'female'                                       |
| `weightKg`           | `RealColumn`     | `weight_kg`             | Yes      | Kilograms                                              |
| `schoolOrDojangName` | `TextColumn`     | `school_or_dojang_name` | Yes      | **CRITICAL for seeding**                               |
| `beltRank`           | `TextColumn`     | `belt_rank`             | Yes      | e.g., "black 1dan"                                     |
| `seedNumber`         | `IntColumn`      | `seed_number`           | Yes      | >= 1                                                   |
| `registrationNumber` | `TextColumn`     | `registration_number`   | Yes      | External ref                                           |
| `isBye`              | `BoolColumn`     | `is_bye`                | No       | Default: false                                         |
| `checkInStatus`      | `TextColumn`     | `check_in_status`       | No       | Default: 'pending'                                     |
| `checkInAtTimestamp` | `DateTimeColumn` | `check_in_at_timestamp` | Yes      |                                                        |
| `photoUrl`           | `TextColumn`     | `photo_url`             | Yes      |                                                        |
| `notes`              | `TextColumn`     | `notes`                 | Yes      |                                                        |
| + `BaseSyncMixin`    |                  |                         |          | syncVersion, isDeleted, deletedAtTimestamp, isDemoData |
| + `BaseAuditMixin`   |                  |                         |          | createdAtTimestamp, updatedAtTimestamp                 |

### Clean Architecture Layer Rules — ENFORCED

| Layer            | Can Depend On            | CANNOT Depend On                  |
| ---------------- | ------------------------ | --------------------------------- |
| **Presentation** | Domain                   | Data                              |
| **Domain**       | Nothing (core only)      | Data, Presentation, External SDKs |
| **Data**         | Domain (interfaces only) | Presentation                      |

### DI Registration Requirements

```dart
// Datasources — SINGLETON
@LazySingleton(as: ParticipantLocalDatasource)
class ParticipantLocalDatasourceImplementation { ... }

@LazySingleton(as: ParticipantRemoteDatasource)
class ParticipantRemoteDatasourceImplementation { ... }

// Repository — SINGLETON
@LazySingleton(as: ParticipantRepository)
class ParticipantRepositoryImplementation { ... }

// Use Cases — TRANSIENT (created in Story 4.3+)
// @injectable
// class CreateParticipantUseCase extends UseCase<...> { ... }
```

### File Structure After This Story

```
lib/features/participant/
├── participant.dart                                    ← Updated barrel
├── README.md                                           ← Unchanged
├── data/
│   ├── datasources/
│   │   ├── participant_local_datasource.dart            ← NEW
│   │   └── participant_remote_datasource.dart           ← NEW (stub)
│   ├── models/
│   │   ├── participant_model.dart                       ← NEW
│   │   ├── participant_model.freezed.dart               ← GENERATED
│   │   └── participant_model.g.dart                     ← GENERATED
│   └── repositories/
│       └── participant_repository_implementation.dart    ← NEW
├── domain/
│   ├── entities/
│   │   ├── participant_entity.dart                      ← NEW
│   │   └── participant_entity.freezed.dart              ← GENERATED
│   ├── repositories/
│   │   └── participant_repository.dart                  ← NEW
│   └── usecases/                                       ← Empty (Story 4.3+)
└── presentation/                                       ← Empty (Story 4.12)
```

### Project Structure Notes

- All new files are within `lib/features/participant/` following Clean Architecture
- No modifications to `lib/core/` — existing `AppDatabase` and `participants_table.dart` are reused as-is
- No modifications to `lib/features/division/` or `lib/features/tournament/`
- Barrel file follows `tournament.dart` export organization pattern
- Generated files (`.freezed.dart`, `.g.dart`) created by `build_runner`

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 4, Story 4.2]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Clean Architecture, Naming Conventions, Database Schema, Drift patterns]
- [Source: `_bmad-output/implementation-artifacts/4-1-participant-feature-structure.md` — Previous story learnings, anti-patterns, existing infrastructure]
- [Source: `tkd_brackets/lib/core/database/tables/participants_table.dart` — Drift table definition (DO NOT MODIFY)]
- [Source: `tkd_brackets/lib/core/database/app_database.dart` — Existing participant CRUD methods (DO NOT MODIFY)]
- [Source: `tkd_brackets/lib/features/tournament/domain/entities/tournament_entity.dart` — Entity pattern reference]
- [Source: `tkd_brackets/lib/features/tournament/data/models/tournament_model.dart` — Model pattern reference]
- [Source: `tkd_brackets/lib/features/tournament/data/datasources/tournament_local_datasource.dart` — Datasource pattern reference]
- [Source: `tkd_brackets/lib/features/tournament/domain/repositories/tournament_repository.dart` — Repository interface pattern]
- [Source: `tkd_brackets/lib/features/tournament/data/repositories/tournament_repository_implementation.dart` — Repository impl pattern]
- [Source: `tkd_brackets/lib/core/usecases/use_case.dart` — UseCase base class]

---

## Anti-Patterns — WHAT NOT TO DO

| ❌ Don't Do This                                            | ✅ Do This Instead                                                                                                                 | Source                   |
| ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ------------------------ |
| Import `drift` or `supabase_flutter` in domain layer       | Domain only uses `fpdart`, `freezed`, core Dart                                                                                   | Architecture doc         |
| Create new DB tables in feature dir                        | Drift tables stay in `core/database/tables/` — ALREADY EXISTS                                                                     | Architecture boundary    |
| Modify `participants_table.dart`                           | Use existing table definition unchanged                                                                                           | Story 4.1                |
| Modify `app_database.dart`                                 | Use existing CRUD methods unchanged                                                                                               | Story 4.1                |
| Return raw `ParticipantEntry` from repository              | Return `ParticipantEntity` domain type                                                                                            | Clean Architecture       |
| Use `@injectable` on repository (transient)                | Use `@LazySingleton(as: ParticipantRepository)` (singleton)                                                                       | Epic 2 lessons           |
| Use `@JsonKey` on ALL model fields                         | Use `@JsonKey` SELECTIVELY only where camelCase ≠ snake_case (match `TournamentModel` pattern; no `field_rename` in `build.yaml`) | TournamentModel pattern  |
| Use `CacheFailure` in repository catch blocks              | Use `LocalCacheAccessFailure` (reads) / `LocalCacheWriteFailure` (writes) — check `core/error/failures.dart`                      | Actual failures.dart     |
| Inject only local datasource in repository constructor     | Inject ALL 4 deps: local + remote + connectivity + database (match `TournamentRepositoryImplementation` constructor exactly)      | Tournament repo pattern  |
| Skip `// ignore_for_file: invalid_annotation_target`       | Add at top of model file for freezed `@JsonKey` lint                                                                              | Tournament model pattern |
| Import `package:drift/drift.dart` without hiding `JsonKey` | Use `import 'package:drift/drift.dart' hide JsonKey;`                                                                             | Tournament model pattern |
| Make datasource return `Either<Failure, T>`                | Datasource returns raw types; repository wraps in `Either`                                                                        | Architecture pattern     |
| Force-unwrap nullable gender/DOB from DB                   | Check for null, pass null when DB column is null                                                                                  | Data integrity           |
| Create `services/` directory                               | Not needed in this story — services added in 4.4+                                                                                 | Story 4.1 notes          |

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

- Comprehensive context engine analysis completed — exhaustive developer guide created
- Cross-referenced with tournament, division, and auth feature patterns for implementation fidelity
- All DB column mappings documented with Drift → Model → Entity conversion paths
- DI registration patterns verified against existing injectable patterns
- Previous story (4.1) learnings incorporated: gitkeep, barrel file, structure patterns

### File List

## New Files Created
- `lib/features/participant/domain/entities/participant_entity.dart`
- `lib/features/participant/domain/entities/participant_entity.freezed.dart` (generated)
- `lib/features/participant/data/models/participant_model.dart`
- `lib/features/participant/data/models/participant_model.freezed.dart` (generated)
- `lib/features/participant/data/models/participant_model.g.dart` (generated)
- `lib/features/participant/data/datasources/participant_local_datasource.dart`
- `lib/features/participant/data/datasources/participant_remote_datasource.dart`
- `lib/features/participant/domain/repositories/participant_repository.dart`
- `lib/features/participant/data/repositories/participant_repository_implementation.dart`
- `test/features/participant/domain/entities/participant_entity_test.dart`
- `test/features/participant/data/models/participant_model_test.dart`
- `test/features/participant/data/datasources/participant_local_datasource_test.dart`
- `test/features/participant/data/repositories/participant_repository_implementation_test.dart`

## Modified Files
- `lib/features/participant/participant.dart` (barrel file - added exports)

## Files Verified Unchanged (as required)
- `lib/core/database/tables/participants_table.dart` - NO CHANGES
- `lib/core/database/app_database.dart` - NO CHANGES

## Change Log

### 2026-02-19 - Implementation Complete

- Created ParticipantEntity with all required fields, computed age getter, ParticipantStatus enum, and Gender enum
- Created ParticipantModel with selective @JsonKey annotations, freezed + json_serializable
- Implemented model conversion methods: fromJson, fromDriftEntry, convertToEntity, toDriftCompanion, convertFromEntity
- Created ParticipantLocalDatasource wrapping AppDatabase CRUD methods
- Created ParticipantRemoteDatasource stub (throws UnimplementedError)
- Created ParticipantRepository interface and implementation with offline-first strategy
- Updated barrel file with all exports
- Generated freezed and json_serializable files
- Added comprehensive unit tests for entity, model, datasource, and repository
- Verified flutter analyze passes (info/warnings only, no new errors)
- Verified build_runner completes successfully
- Verified existing infrastructure unchanged

### 2026-02-19 - Code Review complete
- [CRITICAL FIX] Updated `getParticipantById` in `ParticipantRepositoryImplementation` to return `NotFoundFailure` instead of `LocalCacheAccessFailure` to align with the core failure type specifications.
- [MEDIUM FIX] Added missing insert and update tests to `participant_local_datasource_test.dart` to cover all implemented datasource methods.
- [FIX] Cleaned up `structure_test.dart` from the scaffold checking to permit real exports.
- All tests pass successfully and the story is verified.
