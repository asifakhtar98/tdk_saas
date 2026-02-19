# Story 4.1: Participant Feature Structure

**Status:** done

**Created:** 2026-02-19

**Epic:** 4 - Participant Management

**FRs Covered:** FR13-FR19 (Foundation for all Participant Management features)

**Dependencies:** Epic 1 (Foundation) - COMPLETE | Epic 2 (Auth & Organization) - COMPLETE | Epic 3 (Tournament & Division Management) - COMPLETE

---

## TL;DR — Critical Facts

**CURRENT STATE:** The participant feature does NOT exist yet. There is NO `lib/features/participant/` directory.

However, the following participant-related infrastructure ALREADY EXISTS from earlier epics:

- ✅ `lib/core/database/tables/participants_table.dart` — Drift table definition (Epic 1) — **DO NOT TOUCH**
- ✅ `test/core/database/tables/participants_table_test.dart` — Drift table tests (Epic 1) — **DO NOT TOUCH**
- ✅ `DivisionRepository.getParticipantsForDivision()` — Cross-feature query method (Epic 3) — **DO NOT TOUCH**
- ✅ `DivisionRepository.getParticipantsForDivisions()` — Cross-feature query method (Epic 3) — **DO NOT TOUCH**
- ❌ `lib/features/participant/` — **DOES NOT EXIST** — Create in this story
- ❌ `test/features/participant/` — **DOES NOT EXIST** — Create in this story

**TARGET STATE:** Complete Clean Architecture 3-layer feature structure matching `tournament/` and `auth/` feature patterns, with barrel file, README, `.gitkeep` files, structure tests, and test directory mirror.

**KEY LESSONS FROM EPIC 2 & EPIC 3 — APPLY ALL:**
1. Use cases = `@injectable` (transient), Repos/Services = `@lazySingleton` (singleton) — mixing this up causes state leakage
2. JSON keys MUST be `snake_case` for Supabase (`@JsonKey(name: 'field_name')`)
3. Clean up orphaned `.freezed.dart`/`.g.dart` files when renaming
4. Repository manages `sync_version`, NOT use cases — Database transaction handles increment
5. Always verify organization ID matching in use cases (prevent cross-org attacks)
6. Run `build_runner build --delete-conflicting-outputs` after ANY generated file changes
7. `.gitkeep` files go in BOTH parent directories (`data/`, `domain/`, `presentation/`) AND leaf directories
8. Barrel file starts with empty section headers — NEVER export files that don't exist yet

---

## Story

**As a** developer,
**I want** the participant feature properly structured with Clean Architecture layers,
**So that** all participant-related code follows consistent patterns.

---

## Acceptance Criteria

- [x] **AC1**: Participant feature directory structure exists with data/domain/presentation layers following Clean Architecture:
  ```
  lib/features/participant/
  ├── data/
  │   ├── datasources/       # Empty + .gitkeep
  │   ├── models/            # Empty + .gitkeep
  │   └── repositories/      # Empty + .gitkeep
  ├── domain/
  │   ├── entities/          # Empty + .gitkeep
  │   ├── repositories/      # Empty + .gitkeep
  │   └── usecases/          # Empty + .gitkeep
  └── presentation/
      ├── bloc/              # Empty + .gitkeep
      ├── pages/             # Empty + .gitkeep
      └── widgets/           # Empty + .gitkeep
  ```

- [x] **AC2**: Feature barrel file `lib/features/participant/participant.dart` exists with organized empty section headers (Data → Domain → Presentation) — NO exports of non-existent files

- [x] **AC3**: Feature is structurally ready for `injectable_generator` auto-discovery (proper Clean Architecture layout under `lib/features/`). Note: Zero DI registrations expected at this stage — annotated classes will be added in Stories 4.2+

- [x] **AC4**: Feature README `lib/features/participant/README.md` documents scope (FRs covered, structure, planned dependencies)

- [x] **AC5**: `.gitkeep` files exist in ALL directories — both parent directories (`data/`, `domain/`, `presentation/`) AND leaf directories (9 leaf dirs)

- [x] **AC6**: Structure validation tests exist at `test/features/participant/structure_test.dart` with architecture compliance checks

- [x] **AC7**: Test directory mirror structure exists:
  ```
  test/features/participant/
  ├── data/
  │   ├── datasources/
  │   ├── models/
  │   └── repositories/
  ├── domain/
  │   ├── entities/
  │   ├── repositories/
  │   └── usecases/
  └── presentation/
      └── bloc/
  ```

- [x] **AC8**: `flutter analyze` passes with zero new errors related to participant feature

- [x] **AC9**: `dart run build_runner build --delete-conflicting-outputs` completes successfully

- [x] **AC10**: Existing participant-related infrastructure is UNTOUCHED — `participants_table.dart`, `DivisionRepository` participant methods remain unmodified

---

## Tasks / Subtasks

### Task 1: Verify Current State (AC: #10)

> **⚠️ CRITICAL: Do this FIRST before creating anything.**

- [x] 1.1: Run `ls -la tkd_brackets/lib/features/` to confirm participant directory does NOT exist yet
- [x] 1.2: Run `ls -la tkd_brackets/lib/core/database/tables/participants_table.dart` to confirm Drift table EXISTS (preserve — DO NOT MODIFY)
- [x] 1.3: Run `cat tkd_brackets/lib/features/division/domain/repositories/division_repository.dart` and confirm `getParticipantsForDivision` and `getParticipantsForDivisions` methods exist (preserve — DO NOT DUPLICATE)
- [x] 1.4: Read `tkd_brackets/lib/features/tournament/tournament.dart` to study barrel file pattern
- [x] 1.5: Read `tkd_brackets/lib/features/tournament/README.md` to study README pattern
- [x] 1.6: Read `tkd_brackets/test/features/tournament/structure_test.dart` to study structure test pattern

### Task 2: Create Participant Feature Directory Structure (AC: #1, #5)

> **Create ALL directories. Place `.gitkeep` in EVERY directory (parent + leaf).**

- [x] 2.1: Create `lib/features/participant/` root directory
- [x] 2.2: Create `lib/features/participant/data/` + add `.gitkeep`
- [x] 2.3: Create `lib/features/participant/data/datasources/` + add `.gitkeep`
- [x] 2.4: Create `lib/features/participant/data/models/` + add `.gitkeep`
- [x] 2.5: Create `lib/features/participant/data/repositories/` + add `.gitkeep`
- [x] 2.6: Create `lib/features/participant/domain/` + add `.gitkeep`
- [x] 2.7: Create `lib/features/participant/domain/entities/` + add `.gitkeep`
- [x] 2.8: Create `lib/features/participant/domain/repositories/` + add `.gitkeep`
- [x] 2.9: Create `lib/features/participant/domain/usecases/` + add `.gitkeep`
- [x] 2.10: Create `lib/features/participant/presentation/` + add `.gitkeep`
- [x] 2.11: Create `lib/features/participant/presentation/bloc/` + add `.gitkeep`
- [x] 2.12: Create `lib/features/participant/presentation/pages/` + add `.gitkeep`
- [x] 2.13: Create `lib/features/participant/presentation/widgets/` + add `.gitkeep`

### Task 3: Create Feature Barrel File (AC: #2)

- [x] 3.1: Create `lib/features/participant/participant.dart` following the EXACT pattern below:

```dart
/// Participant feature - exports public APIs.
library;

// Data exports (will be added in subsequent stories)

// Domain exports (will be added in subsequent stories)

// Presentation exports (will be added in subsequent stories)
```

> **⚠️ CRITICAL:** Do NOT add any `export` statements. There are NO files to export yet. Only add commented section headers. Exports will be added incrementally as Stories 4.2+ create new files.
>
> **❌ WRONG (DO NOT DO THIS):**
> ```dart
> export 'domain/entities/participant_entity.dart'; // FILE DOESN'T EXIST YET!
> ```

### Task 4: Create Feature README (AC: #4)

- [x] 4.1: Create `lib/features/participant/README.md` following this EXACT pattern:

```markdown
# Participant Feature

Manages tournament participants — registration, CSV import, division assignment, and status tracking for TKD Brackets.

## FRs Covered
- FR13-FR19 (Epic 4)

## Structure
- `data/` - Datasources, models, repository implementations
- `domain/` - Entities, repository interfaces, use cases
- `presentation/` - BLoC, pages, widgets

## Dependencies (Planned)
- `drift` - Local database (for Stories 4.2+)
- `supabase_flutter` - Remote backend (for Stories 4.2+)
- `flutter_bloc` - State management (for Story 4.12)
- `fpdart` - Functional error handling (for Stories 4.2+)
- `freezed` - Code generation for entities/events/states (for Stories 4.2+)

## Related Infrastructure
- `lib/core/database/tables/participants_table.dart` - Drift table (created in Epic 1)
- `lib/features/division/domain/repositories/division_repository.dart` - Cross-feature participant queries
```

> **Note:** Follow the `tournament/README.md` pattern. Mark ALL dependencies as `(Planned)` since no code exists yet.

### Task 5: Create Test Directory Mirror Structure (AC: #7)

- [x] 5.1: Create `test/features/participant/` root directory
- [x] 5.2: Create `test/features/participant/data/` + add `.gitkeep`
- [x] 5.3: Create `test/features/participant/data/datasources/` + add `.gitkeep`
- [x] 5.4: Create `test/features/participant/data/models/` + add `.gitkeep`
- [x] 5.5: Create `test/features/participant/data/repositories/` + add `.gitkeep`
- [x] 5.6: Create `test/features/participant/domain/` + add `.gitkeep`
- [x] 5.7: Create `test/features/participant/domain/entities/` + add `.gitkeep`
- [x] 5.8: Create `test/features/participant/domain/repositories/` + add `.gitkeep`
- [x] 5.9: Create `test/features/participant/domain/usecases/` + add `.gitkeep`
- [x] 5.10: Create `test/features/participant/presentation/` + add `.gitkeep`
- [x] 5.11: Create `test/features/participant/presentation/bloc/` + add `.gitkeep`

### Task 6: Create Structure Validation Tests (AC: #6)

- [x] 6.1: Create `test/features/participant/structure_test.dart` following the **exact pattern** from `test/features/tournament/structure_test.dart`

> **The test file MUST include ALL of the following test groups and cases. Copy the tournament structure_test.dart pattern:**

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Tests that verify the participant feature structure and Clean Architecture compliance.
///
/// **IMPORTANT**: These tests must be run from the `tkd_brackets/` directory
/// as they use relative paths to check the lib/ structure.
///
/// ```bash
/// cd tkd_brackets
/// flutter test test/features/participant/structure_test.dart
/// ```

void main() {
  group('Participant Feature Structure', () {
    const basePath = 'lib/features/participant';

    test('should have all required directories', () {
      final directories = [
        '$basePath/data/datasources',
        '$basePath/data/models',
        '$basePath/data/repositories',
        '$basePath/domain/entities',
        '$basePath/domain/repositories',
        '$basePath/domain/usecases',
        '$basePath/presentation/bloc',
        '$basePath/presentation/pages',
        '$basePath/presentation/widgets',
      ];

      for (final dir in directories) {
        expect(
          Directory(dir).existsSync(),
          isTrue,
          reason: 'Directory $dir should exist',
        );
      }
    });

    test('should have barrel file', () {
      expect(
        File('$basePath/participant.dart').existsSync(),
        isTrue,
        reason: 'Barrel file should exist',
      );
    });

    test('should have README', () {
      expect(
        File('$basePath/README.md').existsSync(),
        isTrue,
        reason: 'README should exist',
      );
    });

    group('Clean Architecture Compliance', () {
      test('domain layer should not contain data imports', () {
        final domainDir = Directory('$basePath/domain');
        if (domainDir.existsSync()) {
          final dartFiles = domainDir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'));

          for (final file in dartFiles) {
            final content = file.readAsStringSync();
            expect(
              content.contains("import '../data/") ||
                  content.contains('import "../data/') ||
                  content.contains("import 'package:drift") ||
                  content.contains("import 'package:supabase_flutter"),
              isFalse,
              reason:
                  'Domain file ${file.path} should not import data layer or infrastructure',
            );
          }
        }
      });

      test('barrel file should have organized export sections', () {
        final barrelFile = File('$basePath/participant.dart');
        final content = barrelFile.readAsStringSync();

        expect(
          content.contains('// Data exports'),
          isTrue,
          reason: 'Barrel file should have Data exports section',
        );
        expect(
          content.contains('// Domain exports'),
          isTrue,
          reason: 'Barrel file should have Domain exports section',
        );
        expect(
          content.contains('// Presentation exports'),
          isTrue,
          reason: 'Barrel file should have Presentation exports section',
        );
      });

      test('parent directories should have .gitkeep for consistency', () {
        final parentDirs = [
          '$basePath/data',
          '$basePath/domain',
          '$basePath/presentation',
        ];

        for (final dir in parentDirs) {
          expect(
            File('$dir/.gitkeep').existsSync(),
            isTrue,
            reason: 'Parent directory $dir should have .gitkeep file',
          );
        }
      });
    });

    group('Documentation', () {
      test('README should document planned dependencies', () {
        final readme = File('$basePath/README.md');
        final content = readme.readAsStringSync();

        expect(
          content.contains('Dependencies (Planned)'),
          isTrue,
          reason: 'README should mark dependencies as planned',
        );
      });
    });
  });
}
```

> **⚠️ IMPORTANT:** The test MUST be runnable with:
> ```bash
> cd tkd_brackets
> flutter test test/features/participant/structure_test.dart
> ```

### Task 7: Verify Project Integrity (AC: #8, #9, #10)

- [x] 7.1: Run `flutter analyze` from `tkd_brackets/` — verify zero new issues related to participant feature
- [x] 7.2: Run `dart run build_runner build --delete-conflicting-outputs` from `tkd_brackets/` — verify code generation still works
- [x] 7.3: Verify `participants_table.dart` is UNMODIFIED (run `git diff lib/core/database/tables/participants_table.dart` — should show no changes)
- [x] 7.4: Run the new structure test: `flutter test test/features/participant/structure_test.dart` — ALL tests must pass

### Task 8: Final Verification Checklist

- [x] 8.1: Count total directories created (expected: 13 directories — 1 root + 3 parent + 9 leaf = 13 total)
- [x] 8.2: Count total `.gitkeep` files (expected: 12 — one in each parent + leaf directory)
- [x] 8.3: Verify barrel file has ZERO export statements (only commented section headers)
- [x] 8.4: Verify README mentions "Dependencies (Planned)" not just "Dependencies"
- [x] 8.5: Verify test structure mirrors lib structure

---

## Dev Notes

### Architecture Patterns — MANDATORY

This story establishes the **foundation for all 12 stories in Epic 4** (Participant Management). It MUST follow the EXACT same patterns established in the tournament and division features. Any deviation here will cascade errors across Stories 4.2-4.12.

### Established Feature Structure Pattern — EXACT REFERENCE

The existing features follow a **proven pattern**. The participant feature MUST replicate this EXACTLY:

```
tkd_brackets/lib/features/
├── auth/                ← Reference feature (most files)
│   ├── auth.dart        ← Barrel file (66 lines, many exports)
│   ├── README.md        ← Feature documentation
│   ├── data/
│   │   ├── datasources/
│   │   ├── models/
│   │   ├── repositories/
│   │   └── services/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   └── presentation/
│       └── bloc/
│
├── tournament/          ← Reference feature (most complete UI)
│   ├── tournament.dart  ← Barrel file (42 lines)
│   ├── README.md        ← Feature documentation
│   ├── data/
│   │   ├── datasources/
│   │   ├── models/
│   │   ├── repositories/
│   │   └── services/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   └── presentation/
│       ├── bloc/
│       ├── pages/
│       └── widgets/
│
├── division/            ← Reference feature (domain-heavy, services as top-level)
│   ├── data/
│   │   ├── datasources/
│   │   ├── models/
│   │   └── repositories/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   ├── services/          ← NOTE: domain-level services
│   │   └── usecases/
│   ├── presentation/
│   └── services/              ← NOTE: top-level services
│
└── participant/         ← THIS STORY — Create this EXACT structure
    ├── participant.dart  ← Barrel file (empty sections)
    ├── README.md         ← Feature documentation
    ├── data/
    │   ├── datasources/
    │   ├── models/
    │   └── repositories/
    ├── domain/
    │   ├── entities/
    │   ├── repositories/
    │   └── usecases/
    └── presentation/
        ├── bloc/
        ├── pages/
        └── widgets/
```

> **NOTE on `services/` directory:** Tournament has `data/services/`, division has `domain/services/` AND a top-level `services/`. For participant, do NOT create a `services/` directory in this scaffolding story. Services directories (if needed) will be created in subsequent stories (e.g., Story 4.4 CSVParserService, Story 4.5 DuplicateDetectionService, Story 4.9 AutoAssignService). This avoids premature structure decisions.

### Barrel File Pattern — EXACT CODE

The barrel file MUST follow the `tournament.dart` section organization pattern BUT with ZERO export lines:

```dart
/// Participant feature - exports public APIs.
library;

// Data exports (will be added in subsequent stories)

// Domain exports (will be added in subsequent stories)

// Presentation exports (will be added in subsequent stories)
```

**What the barrel file WILL look like after Story 4.2 completes (for context only — DO NOT CREATE THIS NOW):**
```dart
/// Participant feature - exports public APIs.
library;

// Data exports
export 'data/datasources/participant_local_datasource.dart';
export 'data/datasources/participant_remote_datasource.dart';
export 'data/models/participant_model.dart';
export 'data/repositories/participant_repository_implementation.dart';

// Domain exports
export 'domain/entities/participant_entity.dart';
export 'domain/repositories/participant_repository.dart';

// Presentation exports (will be added in subsequent stories)
```

### ⚠️ CRITICAL — Existing Participant Infrastructure (DO NOT TOUCH)

The following files were created in earlier epics and MUST NOT be modified in this story:

#### 1. Drift Participants Table (Epic 1 — Foundation)

**File:** `lib/core/database/tables/participants_table.dart`

This Drift table definition is the **source of truth** for the database schema. The participant feature will use this table via datasources in Story 4.2 — it does NOT need to create or modify the table.

**`ParticipantEntry` Drift columns (for reference — you'll need these in Story 4.2):**

| Column               | Dart Type        | DB Column Name          | Nullable | Notes                                                                       |
| -------------------- | ---------------- | ----------------------- | -------- | --------------------------------------------------------------------------- |
| `id`                 | `TextColumn`     | `id`                    | No       | Primary key, UUID as TEXT                                                   |
| `divisionId`         | `TextColumn`     | `division_id`           | No       | FK to divisions table                                                       |
| `firstName`          | `TextColumn`     | `first_name`            | No       | Required                                                                    |
| `lastName`           | `TextColumn`     | `last_name`             | No       | Required                                                                    |
| `dateOfBirth`        | `DateTimeColumn` | `date_of_birth`         | Yes      | Age verification                                                            |
| `gender`             | `TextColumn`     | `gender`                | Yes      | Values: 'male', 'female'                                                    |
| `weightKg`           | `RealColumn`     | `weight_kg`             | Yes      | Weight in kilograms                                                         |
| `schoolOrDojangName` | `TextColumn`     | `school_or_dojang_name` | Yes      | **CRITICAL for dojang separation seeding**                                  |
| `beltRank`           | `TextColumn`     | `belt_rank`             | Yes      | e.g., "black 1dan", "red"                                                   |
| `seedNumber`         | `IntColumn`      | `seed_number`           | Yes      | Bracket placement, >= 1                                                     |
| `registrationNumber` | `TextColumn`     | `registration_number`   | Yes      | External system reference                                                   |
| `isBye`              | `BoolColumn`     | `is_bye`                | No       | Default: false                                                              |
| `checkInStatus`      | `TextColumn`     | `check_in_status`       | No       | Default: 'pending'. Values: 'pending', 'checked_in', 'no_show', 'withdrawn' |
| `checkInAtTimestamp` | `DateTimeColumn` | `check_in_at_timestamp` | Yes      | When checked in                                                             |
| `photoUrl`           | `TextColumn`     | `photo_url`             | Yes      | Optional photo                                                              |
| `notes`              | `TextColumn`     | `notes`                 | Yes      | Additional notes                                                            |

**Plus `BaseSyncMixin` columns:**
- `syncVersion` — `IntColumn`, default 1, for LWW sync conflict resolution
- `isDeleted` — `BoolColumn`, default false, soft delete flag
- `deletedAtTimestamp` — `DateTimeColumn`, nullable, when soft deleted
- `isDemoData` — `BoolColumn`, default false, demo mode marker

**Plus `BaseAuditMixin` columns:**
- `createdAtTimestamp` — `DateTimeColumn`, default `currentDateAndTime`
- `updatedAtTimestamp` — `DateTimeColumn`, default `currentDateAndTime`

#### 2. DivisionRepository Participant Methods (Epic 3 — Division Management)

**File:** `lib/features/division/domain/repositories/division_repository.dart`

The division repository already has these participant-related methods:

```dart
// Returns raw ParticipantEntry (Drift generated class), NOT domain entities
Future<Either<Failure, List<ParticipantEntry>>> getParticipantsForDivision(
    String divisionId,
);

Future<Either<Failure, List<ParticipantEntry>>> getParticipantsForDivisions(
    List<String> divisionIds,
);
```

> **ARCHITECTURAL BOUNDARY:** These methods return `ParticipantEntry` (Drift generated class) not domain entities. This is a known tech debt from Epic 3 — the participant feature in Story 4.2 will create a proper `ParticipantEntity` domain entity and the participant repository will return that instead. The division repository methods are for cross-feature queries and will be updated in a future story if needed.

### Clean Architecture Layer Rules — ENFORCED

| Layer            | Can Depend On            | CANNOT Depend On                  |
| ---------------- | ------------------------ | --------------------------------- |
| **Presentation** | Domain                   | Data                              |
| **Domain**       | Nothing (core only)      | Data, Presentation, External SDKs |
| **Data**         | Domain (interfaces only) | Presentation                      |

**Domain Layer Isolation (MUST ENFORCE):**
- ❌ NO `import 'package:supabase_flutter/supabase_flutter.dart'` in domain
- ❌ NO `import 'package:drift/drift.dart'` in domain
- ❌ NO catching `AuthException`, `PostgrestException` in domain
- ✅ Domain only uses: `fpdart`, `freezed`, `equatable`, core Dart/Flutter

**Exception → Failure Mapping (Applied in Story 4.2+):**
- Repository implementations (data layer) catch infrastructure exceptions
- Repository implementations map to domain `Failure` types
- Use cases receive `Either<Failure, T>` from repositories

### Naming Conventions — MANDATORY

| Element         | Pattern                                   | Participant Example                          |
| --------------- | ----------------------------------------- | -------------------------------------------- |
| **Feature Dir** | `lib/features/{feature}/`                 | `lib/features/participant/`                  |
| **Barrel File** | `{feature}.dart`                          | `participant.dart`                           |
| **Entity**      | `{entity}_entity.dart`                    | `participant_entity.dart`                    |
| **Model**       | `{entity}_model.dart`                     | `participant_model.dart`                     |
| **Repository**  | `{entity}_repository.dart` (interface)    | `participant_repository.dart`                |
| **Repo Impl**   | `{entity}_repository_implementation.dart` | `participant_repository_implementation.dart` |
| **Use Cases**   | `{action}_{entity}_usecase.dart`          | `create_participant_usecase.dart`            |
| **Params**      | `{action}_{entity}_params.dart`           | `create_participant_params.dart`             |
| **Local DS**    | `{entity}_local_datasource.dart`          | `participant_local_datasource.dart`          |
| **Remote DS**   | `{entity}_remote_datasource.dart`         | `participant_remote_datasource.dart`         |
| **BLoC**        | `{feature}_bloc.dart`                     | `participant_bloc.dart`                      |
| **Events**      | `{feature}_event.dart`                    | `participant_event.dart`                     |
| **States**      | `{feature}_state.dart`                    | `participant_state.dart`                     |
| **README**      | `README.md`                               | `README.md`                                  |

> **⚠️ Use Case File Naming Variance:** Check existing patterns — tournament uses `create_tournament_usecase.dart` (no underscore between "use" and "case"). Stick with the SAME pattern: `{action}_{entity}_usecase.dart` (single word `usecase`).

### DI Registration Patterns (for Story 4.2+ — context only)

When annotated classes are added in future stories, they follow these rules:

```dart
// Use Cases — TRANSIENT (new instance per injection)
@injectable
class CreateParticipantUseCase extends UseCase<ParticipantEntity, CreateParticipantParams> { ... }

// Repositories — SINGLETON (shared instance)
@LazySingleton(as: ParticipantRepository)
class ParticipantRepositoryImplementation implements ParticipantRepository { ... }

// Datasources — SINGLETON
@lazySingleton
class ParticipantLocalDatasource { ... }
```

### What This Story Does NOT Include

This is a **scaffolding story only**. The following are implemented in subsequent stories:

| Component                           | Story      | Key Detail                                          |
| ----------------------------------- | ---------- | --------------------------------------------------- |
| `ParticipantEntity` (freezed)       | Story 4.2  | Domain entity mapping from Drift `ParticipantEntry` |
| `ParticipantRepository` interface   | Story 4.2  | Abstract class in `domain/repositories/`            |
| `ParticipantModel` (freezed + json) | Story 4.2  | DTO with `@JsonKey(name: 'snake_case')`             |
| `ParticipantLocalDatasource`        | Story 4.2  | Drift queries using existing `participants` table   |
| `ParticipantRemoteDatasource`       | Story 4.2  | Supabase queries                                    |
| `ParticipantRepositoryImpl`         | Story 4.2  | Implements interface, handles sync                  |
| `CreateParticipantUseCase`          | Story 4.3  | Validation: name, dojang, belt required             |
| `CSVParserService`                  | Story 4.4  | Column mapping, date parsing, belt normalization    |
| `DuplicateDetectionService`         | Story 4.5  | Levenshtein distance, fuzzy matching                |
| `BulkImportUseCase`                 | Story 4.6  | Preview + confirm workflow                          |
| Status management use cases         | Story 4.7  | No-show, disqualification                           |
| `AssignToDivisionUseCase`           | Story 4.8  | `division_participant` records                      |
| `AutoAssignService`                 | Story 4.9  | Age/belt/weight/gender matching                     |
| `GetDivisionParticipantsUseCase`    | Story 4.10 | Sorted list with counts                             |
| Transfer/Edit use cases             | Story 4.11 | Transfer blocked if bracket in_progress             |
| `ParticipantBloc` + UI              | Story 4.12 | List page, CSV wizard, assignment view              |

---

## Anti-Patterns — WHAT NOT TO DO

> **These are actual mistakes caught in previous epic code reviews. Do NOT repeat them.**

| ❌ Don't Do This                          | ✅ Do This Instead                                  | Source                 |
| ---------------------------------------- | -------------------------------------------------- | ---------------------- |
| Export files that don't exist in barrel  | Only export files that actually exist              | Epic 2 code reviews    |
| Create database tables in feature dir    | Drift tables stay in `core/database/tables/`       | Architecture doc       |
| Forget `.gitkeep` in parent directories  | Place `.gitkeep` in ALL directories                | Story 3.1 code review  |
| Mark dependencies as current in README   | Mark as `(Planned)` with story references          | Story 3.1 code review  |
| Create `services/` directory prematurely | Let subsequent stories create as needed            | Architecture alignment |
| Skip structure tests                     | Always create `structure_test.dart`                | Story 3.1 pattern      |
| Use `use_case` (two words) in filename   | Use `usecase` (one word) matching existing pattern | Codebase consistency   |
| Modify existing Drift table definition   | Participant Drift table is in `core/`, not feature | Architecture boundary  |

---

## References

**Source Documents:**
- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 4: Participant Management Stories]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Clean Architecture, Database Schema, Naming Conventions]
- [Source: `_bmad-output/implementation-artifacts/epic-2-retro-2026-02-16.md` — Key learnings from Epic 2]
- [Source: `_bmad-output/implementation-artifacts/3-1-tournament-feature-structure.md` — Reference implementation of feature structure story]

**Code References (STUDY THESE before implementing):**
- `tkd_brackets/lib/features/tournament/tournament.dart` — Barrel file pattern (42 lines)
- `tkd_brackets/lib/features/auth/auth.dart` — Barrel file pattern mature (66 lines)
- `tkd_brackets/lib/features/tournament/README.md` — README pattern
- `tkd_brackets/lib/features/auth/README.md` — README pattern
- `tkd_brackets/test/features/tournament/structure_test.dart` — Structure test pattern (159 lines)
- `tkd_brackets/lib/core/database/tables/participants_table.dart` — Existing Drift table (DO NOT MODIFY)
- `tkd_brackets/lib/core/database/tables/base_tables.dart` — BaseSyncMixin + BaseAuditMixin definitions
- `tkd_brackets/lib/features/division/domain/repositories/division_repository.dart` — Existing participant query methods
- `tkd_brackets/lib/core/usecases/use_case.dart` — UseCase base class (for Story 4.2+ context)

---

## Dev Agent Record

### Agent Model Used

Gemini 2.5 Pro (antigravity)

### Debug Log References

### Completion Notes List

- Comprehensive context engine analysis completed — exhaustive developer guide created
- Validated against create-story checklist — all gaps addressed
- Enhanced with disaster prevention anti-patterns from Epic 2 + 3 retrospectives
- Cross-referenced with Story 3.1 (tournament feature structure) for pattern fidelity
- **Story 4.1 Implementation Completed:**
  - Created complete Clean Architecture directory structure (12 directories)
  - Created barrel file with zero exports (only section headers)
  - Created README with planned dependencies
  - Created test structure mirror with 10 directories
  - Created structure validation tests (7 tests, all passing)
  - Verified: flutter analyze passes (no new errors)
  - Verified: build_runner completes successfully
  - Verified: participants_table.dart unchanged

### File List

**New directories created (lib/features/participant/):**
- lib/features/participant/data/
- lib/features/participant/data/datasources/
- lib/features/participant/data/models/
- lib/features/participant/data/repositories/
- lib/features/participant/domain/
- lib/features/participant/domain/entities/
- lib/features/participant/domain/repositories/
- lib/features/participant/domain/usecases/
- lib/features/participant/presentation/
- lib/features/participant/presentation/bloc/
- lib/features/participant/presentation/pages/
- lib/features/participant/presentation/widgets/

**New files created:**
- lib/features/participant/participant.dart (barrel file)
- lib/features/participant/README.md

**New directories created (test/features/participant/):**
- test/features/participant/data/
- test/features/participant/data/datasources/
- test/features/participant/data/models/
- test/features/participant/data/repositories/
- test/features/participant/domain/
- test/features/participant/domain/entities/
- test/features/participant/domain/repositories/
- test/features/participant/domain/usecases/
- test/features/participant/presentation/
- test/features/participant/presentation/bloc/

**New test files:**
- test/features/participant/structure_test.dart

**New .gitkeep files in test/ (12 total, added 2 via code review):**
- test/features/participant/data/.gitkeep
- test/features/participant/data/datasources/.gitkeep
- test/features/participant/data/models/.gitkeep
- test/features/participant/data/repositories/.gitkeep
- test/features/participant/domain/.gitkeep
- test/features/participant/domain/entities/.gitkeep
- test/features/participant/domain/repositories/.gitkeep
- test/features/participant/domain/usecases/.gitkeep
- test/features/participant/presentation/.gitkeep
- test/features/participant/presentation/bloc/.gitkeep
- test/features/participant/presentation/pages/.gitkeep (added in code review)
- test/features/participant/presentation/widgets/.gitkeep (added in code review)

**Test directories added in code review:**
- test/features/participant/presentation/pages/
- test/features/participant/presentation/widgets/

**Sprint status updated:**
- _bmad-output/implementation-artifacts/sprint-status.yaml

**New .gitkeep files (12 total):**
- lib/features/participant/data/.gitkeep
- lib/features/participant/data/datasources/.gitkeep
- lib/features/participant/data/models/.gitkeep
- lib/features/participant/data/repositories/.gitkeep
- lib/features/participant/domain/.gitkeep
- lib/features/participant/domain/entities/.gitkeep
- lib/features/participant/domain/repositories/.gitkeep
- lib/features/participant/domain/usecases/.gitkeep
- lib/features/participant/presentation/.gitkeep
- lib/features/participant/presentation/bloc/.gitkeep
- lib/features/participant/presentation/pages/.gitkeep
- lib/features/participant/presentation/widgets/.gitkeep

---

## Change Log

- **2026-02-19**: Created participant feature structure with Clean Architecture layers (data/domain/presentation), barrel file, README, test structure mirror, and structure validation tests. All ACs satisfied.
- **2026-02-19**: Code review (AI) — Fixed 3 medium + 4 low issues: added missing `test/presentation/{pages,widgets}/` mirror dirs + .gitkeep files (M1); fixed 2 `lines_longer_than_80_chars` lint warnings in structure_test.dart (M2); added sprint-status.yaml to File List (M3); corrected directory count 12→13 (L1); added test .gitkeep inventory to File List (L2); filled agent model placeholder (L3); added zero-export assertion to structure test (L4).
