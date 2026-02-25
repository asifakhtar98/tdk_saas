# Story 5.1: Bracket Feature Structure

Status: done

**Created:** 2026-02-25

**Epic:** 5 - Bracket Generation & Seeding

**FRs Covered:** FR20-FR31 (Foundation for all Bracket Generation & Seeding features)

**Dependencies:** Epic 1 (Foundation) - COMPLETE | Epic 2 (Auth & Organization) - COMPLETE | Epic 3 (Tournament & Division Management) - COMPLETE | Epic 4 (Participant Management) - COMPLETE

---

## TL;DR — Critical Facts

**CURRENT STATE:** The bracket feature does NOT exist yet. There is NO `lib/features/bracket/` directory.

However, the following bracket-related infrastructure ALREADY EXISTS from earlier epics:

- ✅ `lib/core/database/tables/` — Contains tables for organizations, users, tournaments, divisions, participants — **NO brackets_table.dart or matches_table.dart yet**
- ✅ `lib/features/division/domain/entities/division_entity.dart` — Contains `BracketFormat` enum: `singleElimination`, `doubleElimination`, `roundRobin`, `poolPlay` — **DO NOT DUPLICATE**
- ✅ `lib/features/division/domain/entities/division_entity.dart` — Contains `DivisionStatus` enum: `setup`, `ready`, `inProgress`, `completed` — **DO NOT DUPLICATE**
- ✅ `lib/core/database/app_database.dart` — Current schema version 5, registered tables: Organizations, Users, SyncQueueTable, Tournaments, Divisions, Participants, Invitations, DivisionTemplates — **Brackets/Matches tables NOT yet registered**
- ✅ Architecture defines bracket feature at `features/bracket/` — **NOT under tournament or division**
- ❌ `lib/features/bracket/` — **DOES NOT EXIST** — Create in this story
- ❌ `test/features/bracket/` — **DOES NOT EXIST** — Create in this story
- ❌ `lib/core/database/tables/brackets_table.dart` — **DOES NOT EXIST** — Created in Story 5.2
- ❌ `lib/core/database/tables/matches_table.dart` — **DOES NOT EXIST** — Created in Story 5.3
- ❌ `lib/core/algorithms/seeding/` — **DOES NOT EXIST** — Created in Story 5.7

**TARGET STATE:** Complete Clean Architecture 3-layer feature structure matching `participant/`, `tournament/`, and `auth/` feature patterns, with barrel file, README, `.gitkeep` files, structure tests, and test directory mirror.

**KEY LESSONS FROM EPIC 2, EPIC 3, AND EPIC 4 — APPLY ALL:**
1. Use cases = `@injectable` (transient), Repos/Services = `@lazySingleton` (singleton) — mixing this up causes state leakage
2. JSON keys MUST be `snake_case` for Supabase (`@JsonKey(name: 'field_name')`)
3. Clean up orphaned `.freezed.dart`/`.g.dart` files when renaming
4. Repository manages `sync_version`, NOT use cases — Database transaction handles increment
5. Always verify organization ID matching in use cases (prevent cross-org attacks)
6. Run `build_runner build --delete-conflicting-outputs` after ANY generated file changes
7. `.gitkeep` files go in BOTH parent directories (`data/`, `domain/`, `presentation/`) AND leaf directories — in BOTH `lib/` AND `test/` trees
8. Barrel file starts with empty section headers — NEVER export files that don't exist yet
9. Use `mocktail` for testing — NOT `mockito`. NO `@GenerateMocks`
10. Use `fpdart` `Either<Failure, T>` pattern — NOT try/catch in use cases
11. Feature directory name MUST be `bracket/` (singular) — NOT `brackets/`
12. Epic 4 retro: BLoC with many parameters can hit DI parameter limits or caching issues — solve with `build_runner` re-run
13. Epic 3 retro: Centralizing algorithms (like scheduling conflict detection, seeding) into `core/` prevents duplication across features

---

## Story

**As a** developer,
**I want** the bracket feature properly structured with Clean Architecture layers,
**So that** all bracket-related code follows consistent patterns.

---

## Acceptance Criteria

- [x] **AC1**: Bracket feature directory structure exists with data/domain/presentation layers following Clean Architecture:
  ```
  lib/features/bracket/
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

- [x] **AC2**: Feature barrel file `lib/features/bracket/bracket.dart` exists with organized empty section headers (Data → Domain → Presentation) — NO exports of non-existent files

- [x] **AC3**: Feature is structurally ready for `injectable_generator` auto-discovery (proper Clean Architecture layout under `lib/features/`). Note: Zero DI registrations expected at this stage — annotated classes will be added in Stories 5.2+

- [x] **AC4**: Feature README `lib/features/bracket/README.md` documents scope (FRs covered, structure, planned dependencies)

- [x] **AC5**: `.gitkeep` files exist in ALL directories — both parent directories (`data/`, `domain/`, `presentation/`) AND leaf directories (9 leaf dirs) — totaling 12 `.gitkeep` files in `lib/features/bracket/`

- [x] **AC6**: Structure validation tests exist at `test/features/bracket/structure_test.dart` with architecture compliance checks

- [x] **AC7**: Test directory mirror structure exists with `.gitkeep` in every directory (12 `.gitkeep` files in test mirror):
  ```
  test/features/bracket/
  ├── data/                    # .gitkeep
  │   ├── datasources/         # .gitkeep
  │   ├── models/              # .gitkeep
  │   └── repositories/        # .gitkeep
  ├── domain/                  # .gitkeep
  │   ├── entities/            # .gitkeep
  │   ├── repositories/        # .gitkeep
  │   └── usecases/            # .gitkeep
  └── presentation/            # .gitkeep
      ├── bloc/                # .gitkeep
      ├── pages/               # .gitkeep
      └── widgets/             # .gitkeep
  ```

- [x] **AC8**: `flutter analyze` passes with zero new errors related to bracket feature

- [x] **AC9**: `dart run build_runner build --delete-conflicting-outputs` completes successfully

- [x] **AC10**: Existing infrastructure is UNTOUCHED — `division_entity.dart` (which contains `BracketFormat` enum), `app_database.dart`, and all existing tables remain unmodified

---

## Tasks / Subtasks

### Task 1: Verify Current State (AC: #10)

> **⚠️ CRITICAL: Do this FIRST before creating anything.**

- [x] 1.1: Run `ls -la tkd_brackets/lib/features/` to confirm bracket directory does NOT exist yet
- [x] 1.2: Run `cat tkd_brackets/lib/features/division/domain/entities/division_entity.dart` and confirm `BracketFormat` enum EXISTS (preserve — DO NOT DUPLICATE or modify)
- [x] 1.3: Verify `app_database.dart` has schema version 5 and NO brackets/matches tables registered
- [x] 1.4: Read `tkd_brackets/lib/features/participant/participant.dart` to study barrel file pattern
- [x] 1.5: Read `tkd_brackets/lib/features/participant/README.md` to study README pattern
- [x] 1.6: Read `tkd_brackets/test/features/participant/structure_test.dart` to study structure test pattern

### Task 2: Create Bracket Feature Directory Structure (AC: #1, #5)

> **Create ALL directories. Place `.gitkeep` in EVERY directory (parent + leaf).**

- [x] 2.1: Create `lib/features/bracket/` root directory
- [x] 2.2: Create `lib/features/bracket/data/` + add `.gitkeep`
- [x] 2.3: Create `lib/features/bracket/data/datasources/` + add `.gitkeep`
- [x] 2.4: Create `lib/features/bracket/data/models/` + add `.gitkeep`
- [x] 2.5: Create `lib/features/bracket/data/repositories/` + add `.gitkeep`
- [x] 2.6: Create `lib/features/bracket/domain/` + add `.gitkeep`
- [x] 2.7: Create `lib/features/bracket/domain/entities/` + add `.gitkeep`
- [x] 2.8: Create `lib/features/bracket/domain/repositories/` + add `.gitkeep`
- [x] 2.9: Create `lib/features/bracket/domain/usecases/` + add `.gitkeep`
- [x] 2.10: Create `lib/features/bracket/presentation/` + add `.gitkeep`
- [x] 2.11: Create `lib/features/bracket/presentation/bloc/` + add `.gitkeep`
- [x] 2.12: Create `lib/features/bracket/presentation/pages/` + add `.gitkeep`
- [x] 2.13: Create `lib/features/bracket/presentation/widgets/` + add `.gitkeep`

### Task 3: Create Feature Barrel File (AC: #2)

- [x] 3.1: Create `lib/features/bracket/bracket.dart` following the EXACT pattern below:

```dart
/// Bracket feature - exports public APIs.
library;

// Data exports (will be added in subsequent stories)

// Domain exports (will be added in subsequent stories)

// Presentation exports (will be added in subsequent stories)
```

> **⚠️ CRITICAL:** Do NOT add any `export` statements. There are NO files to export yet. Only add commented section headers. Exports will be added incrementally as Stories 5.2+ create new files.
>
> **❌ WRONG (DO NOT DO THIS):**
> ```dart
> export 'domain/entities/bracket_entity.dart'; // FILE DOESN'T EXIST YET!
> ```

### Task 4: Create Feature README (AC: #4)

- [x] 4.1: Create `lib/features/bracket/README.md` following this EXACT pattern:

```markdown
# Bracket Feature

Handles bracket generation, seeding algorithms, match tree construction, and bracket visualization for TKD Brackets.

## FRs Covered
- FR20-FR31 (Epic 5)

## Structure
- `data/` - Datasources, models, repository implementations
- `domain/` - Entities, repository interfaces, use cases
- `presentation/` - BLoC, pages, widgets

## Dependencies (Planned)
- `drift` - Local database (for Stories 5.2-5.3)
- `supabase_flutter` - Remote backend (for Stories 5.2-5.3)
- `flutter_bloc` - State management (for Story 5.13)
- `fpdart` - Functional error handling (for Stories 5.2+)
- `freezed` - Code generation for entities/events/states (for Stories 5.2+)

## Related Infrastructure
- `lib/core/database/tables/brackets_table.dart` - Drift table (to be created in Story 5.2)
- `lib/core/database/tables/matches_table.dart` - Drift table (to be created in Story 5.3)
- `lib/features/division/domain/entities/division_entity.dart` - BracketFormat enum (created in Epic 3)
- `lib/features/participant/domain/entities/participant_entity.dart` - ParticipantEntity (created in Epic 4)
- `lib/core/algorithms/seeding/` - Seeding algorithms (to be created in Story 5.7)
```

> **Note:** Follow the `participant/README.md` pattern. Mark ALL dependencies as `(Planned)` since no code exists yet.

### Task 5: Create Test Directory Mirror Structure (AC: #7)

- [x] 5.1: Create `test/features/bracket/` root directory
- [x] 5.2: Create `test/features/bracket/data/` + add `.gitkeep`
- [x] 5.3: Create `test/features/bracket/data/datasources/` + add `.gitkeep`
- [x] 5.4: Create `test/features/bracket/data/models/` + add `.gitkeep`
- [x] 5.5: Create `test/features/bracket/data/repositories/` + add `.gitkeep`
- [x] 5.6: Create `test/features/bracket/domain/` + add `.gitkeep`
- [x] 5.7: Create `test/features/bracket/domain/entities/` + add `.gitkeep`
- [x] 5.8: Create `test/features/bracket/domain/repositories/` + add `.gitkeep`
- [x] 5.9: Create `test/features/bracket/domain/usecases/` + add `.gitkeep`
- [x] 5.10: Create `test/features/bracket/presentation/` + add `.gitkeep`
- [x] 5.11: Create `test/features/bracket/presentation/bloc/` + add `.gitkeep`
- [x] 5.12: Create `test/features/bracket/presentation/pages/` + add `.gitkeep`
- [x] 5.13: Create `test/features/bracket/presentation/widgets/` + add `.gitkeep`

### Task 6: Create Structure Validation Tests (AC: #6)

- [x] 6.1: Create `test/features/bracket/structure_test.dart` following the **exact pattern** from `test/features/participant/structure_test.dart`

> **The test file MUST include ALL of the following test groups and cases. Copy the participant structure_test.dart pattern:**

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Tests that verify the bracket feature structure and
/// Clean Architecture compliance.
///
/// **IMPORTANT**: These tests must be run from the `tkd_brackets/` directory
/// as they use relative paths to check the lib/ structure.
///
/// ```bash
/// cd tkd_brackets
/// flutter test test/features/bracket/structure_test.dart
/// ```

void main() {
  group('Bracket Feature Structure', () {
    const basePath = 'lib/features/bracket';

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
        File('$basePath/bracket.dart').existsSync(),
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

    test('barrel file should have zero export statements', () {
      final barrelFile = File('$basePath/bracket.dart');
      final content = barrelFile.readAsStringSync();

      expect(
        content.contains('export '),
        isFalse,
        reason:
            'Barrel file should have zero exports '
            'at this scaffolding stage',
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
                  'Domain file ${file.path} should not '
                  'import data layer or infrastructure',
            );
          }
        }
      });

      test('barrel file should have organized export sections', () {
        final barrelFile = File('$basePath/bracket.dart');
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
          reason:
              'Barrel file should have Presentation exports '
              'section',
        );
      });

      test(
        'parent directories should have .gitkeep for consistency',
        () {
          final parentDirs = [
            '$basePath/data',
            '$basePath/domain',
            '$basePath/presentation',
          ];

          for (final dir in parentDirs) {
            expect(
              File('$dir/.gitkeep').existsSync(),
              isTrue,
              reason:
                  'Parent directory $dir should have '
                  '.gitkeep file',
            );
          }
        },
      );
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
> flutter test test/features/bracket/structure_test.dart
> ```

### Task 7: Verify Project Integrity (AC: #8, #9, #10)

> **⚠️ ALL commands below MUST be run from the `tkd_brackets/` directory.**

- [x] 7.1: Run `cd tkd_brackets && flutter analyze` — verify zero new issues related to bracket feature
- [x] 7.2: Run `cd tkd_brackets && dart run build_runner build --delete-conflicting-outputs` — verify code generation still works
- [x] 7.3: Verify `division_entity.dart` is UNMODIFIED:
  ```bash
  cd tkd_brackets && git diff lib/features/division/domain/entities/division_entity.dart
  ```
  Expected output: **empty** (no changes)
- [x] 7.4: Verify `app_database.dart` is UNMODIFIED:
  ```bash
  cd tkd_brackets && git diff lib/core/database/app_database.dart
  ```
  Expected output: **empty** (no changes)
- [x] 7.5: Run the new structure test:
  ```bash
  cd tkd_brackets && flutter test test/features/bracket/structure_test.dart
  ```
  Expected output: **All tests passed!**

### Task 8: Final Verification Checklist

- [x] 8.1: Count total lib directories created: `find lib/features/bracket -type d | wc -l` (expected: **13** — 1 root + 3 parent + 9 leaf)
- [x] 8.2: Count total lib `.gitkeep` files: `find lib/features/bracket -name '.gitkeep' | wc -l` (expected: **12** — 3 parent + 9 leaf)
- [x] 8.3: Count total test directories created: `find test/features/bracket -type d | wc -l` (expected: **13** — mirroring lib)
- [x] 8.4: Count total test `.gitkeep` files: `find test/features/bracket -name '.gitkeep' | wc -l` (expected: **12** — mirroring lib)
- [x] 8.5: Verify barrel file has ZERO export statements: `grep -c 'export ' lib/features/bracket/bracket.dart` (expected: **0**)
- [x] 8.6: Verify README mentions "Dependencies (Planned)" not just "Dependencies"
- [x] 8.7: Verify test structure mirrors lib structure (including `presentation/pages/` and `widgets/`)

### Task 9: Quick Validation Script (Run All Checks At Once)

> **Copy-paste this entire block into terminal from `tkd_brackets/` directory to validate everything in one shot:**

```bash
cd tkd_brackets && \
echo "=== 1. Checking lib directory count ===" && \
find lib/features/bracket -type d | wc -l && \
echo "=== 2. Checking lib .gitkeep count ===" && \
find lib/features/bracket -name '.gitkeep' | wc -l && \
echo "=== 3. Checking test directory count ===" && \
find test/features/bracket -type d | wc -l && \
echo "=== 4. Checking test .gitkeep count ===" && \
find test/features/bracket -name '.gitkeep' | wc -l && \
echo "=== 5. Checking barrel file exports (should be 0) ===" && \
grep -c 'export ' lib/features/bracket/bracket.dart || echo "0" && \
echo "=== 6. Checking README planned deps ===" && \
grep -c 'Dependencies (Planned)' lib/features/bracket/README.md && \
echo "=== 7. Checking division_entity.dart unchanged ===" && \
git diff --stat lib/features/division/domain/entities/division_entity.dart && \
echo "=== 8. Checking app_database.dart unchanged ===" && \
git diff --stat lib/core/database/app_database.dart && \
echo "=== 9. Running structure tests ===" && \
flutter test test/features/bracket/structure_test.dart && \
echo "=== 10. Running flutter analyze ===" && \
flutter analyze --no-fatal-infos && \
echo "=== ALL CHECKS PASSED ==="
```

**Expected output:**
- Directory counts: 13, 13
- `.gitkeep` counts: 12, 12
- Export count: 0
- Dependencies (Planned): 1
- Git diffs: empty
- Tests: All passed
- Analyze: No errors

### Task 10: Update Sprint Status

- [x] 10.1: After ALL tasks pass, update `_bmad-output/implementation-artifacts/sprint-status.yaml`:
  - Change `5-1-bracket-feature-structure` from `ready-for-dev` to `in-progress` (when starting)
  - Change to `review` when complete and ready for code review

---

## Dev Notes

### Architecture Patterns — MANDATORY

This story establishes the **foundation for all 13 stories in Epic 5** (Bracket Generation & Seeding). It MUST follow the EXACT same patterns established in the tournament, division, and participant features. Any deviation here will cascade errors across Stories 5.2-5.13.

### ⚠️ CRITICAL: BracketFormat Enum Already Exists — DO NOT DUPLICATE

The `BracketFormat` enum is **already defined** in `lib/features/division/domain/entities/division_entity.dart`:

```dart
enum BracketFormat {
  singleElimination('single_elimination'),
  doubleElimination('double_elimination'),
  roundRobin('round_robin'),
  poolPlay('pool_play');

  const BracketFormat(this.value);
  final String value;

  static BracketFormat fromString(String value) {
    return BracketFormat.values.firstWhere(
      (f) => f.value == value,
      orElse: () => BracketFormat.singleElimination,
    );
  }
}
```

**Why is this critical?** In Stories 5.2+, `BracketEntity` will reference `BracketFormat` from the division feature. The bracket feature will import it via:
```dart
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
```

> **⚠️ NOTE ON CROSS-FEATURE IMPORTS:** The architecture says "Features may only import from `core/` and their own feature." However, `BracketFormat` is a domain concept shared between division and bracket. The pragmatic solution used in the codebase is to import the entity file directly. In a future refactoring, `BracketFormat` could be moved to `core/` as a shared enum. **For this scaffolding story, no action is needed — this is context for Story 5.2.**

### ⚠️ CRITICAL: Drift Tables Are NOT Created in This Story

The architecture defines `brackets_table.dart` and `matches_table.dart` in `lib/core/database/tables/`. These will be created in Stories 5.2 and 5.3 respectively, following the established pattern:

- `brackets_table.dart` — Created in Story 5.2 (Bracket Entity & Repository)
- `matches_table.dart` — Created in Story 5.3 (Match Entity & Repository)
- `app_database.dart` — Updated in Story 5.2 to register new tables and increment schema version

**DO NOT** create these files or modify `app_database.dart` in this story.

### ⚠️ CRITICAL: Seeding Algorithm Directory NOT Created Here

The architecture places the seeding engine in `lib/core/algorithms/seeding/` — this is a **core** directory, NOT inside the bracket feature. It will be created in Story 5.7 (Dojang Separation Seeding Algorithm).

**DO NOT** create `lib/core/algorithms/` in this story.

### Established Feature Structure Pattern — EXACT REFERENCE

The existing features follow a **proven pattern**. The bracket feature MUST replicate this EXACTLY:

```
tkd_brackets/lib/features/
├── auth/                ← Reference feature (most files, 49 children)
│   ├── auth.dart        ← Barrel file
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
├── tournament/          ← Reference feature (most complete UI, 33 children)
│   ├── tournament.dart  ← Barrel file
│   ├── README.md        ← Feature documentation
│   ├── data/
│   ├── domain/
│   └── presentation/
│       ├── bloc/
│       ├── pages/
│       └── widgets/
│
├── participant/         ← Best reference for this story (Epic 4, 52 children)
│   ├── participant.dart ← Barrel file (currently has exports from 4.2+)
│   ├── README.md        ← Feature documentation
│   ├── data/
│   ├── domain/
│   └── presentation/
│       ├── bloc/
│       ├── pages/
│       └── widgets/
│
└── bracket/             ← THIS STORY — Create this EXACT structure
    ├── bracket.dart      ← Barrel file (empty sections)
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

> **NOTE on `services/` directory:** Some features have `data/services/` (tournament has one, auth has one) or `domain/services/` (participant has one). For bracket, do NOT create a `services/` directory in this scaffolding story. **Why?** The bracket feature's primary complex logic — the seeding algorithm — lives in `lib/core/algorithms/seeding/` (a core-level module), NOT inside the bracket feature's `domain/services/`. Any bracket-specific services (e.g., bye assignment) will be created in their respective stories (5.10+). Creating empty `services/` directories prematurely was identified as a problem in the Story 3.1 code review. The `data/services/` or `domain/services/` directory should ONLY be added when a specific story requires a service class.

### Barrel File Pattern — EXACT CODE

The barrel file MUST follow the `participant.dart` section organization pattern BUT with ZERO export lines:

```dart
/// Bracket feature - exports public APIs.
library;

// Data exports (will be added in subsequent stories)

// Domain exports (will be added in subsequent stories)

// Presentation exports (will be added in subsequent stories)
```

**What the barrel file WILL look like after Story 5.2 completes (for context only — DO NOT CREATE THIS NOW):**
```dart
/// Bracket feature - exports public APIs.
library;

// Data exports
export 'data/datasources/bracket_local_datasource.dart';
export 'data/datasources/bracket_remote_datasource.dart';
export 'data/models/bracket_model.dart';
export 'data/repositories/bracket_repository_implementation.dart';

// Domain exports
export 'domain/entities/bracket_entity.dart';
export 'domain/repositories/bracket_repository.dart';

// Presentation exports (will be added in subsequent stories)
```

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

### Naming Conventions — MANDATORY

| Element         | Pattern                                   | Bracket Example                          |
| --------------- | ----------------------------------------- | ---------------------------------------- |
| **Feature Dir** | `lib/features/{feature}/`                 | `lib/features/bracket/`                  |
| **Barrel File** | `{feature}.dart`                          | `bracket.dart`                           |
| **Entity**      | `{entity}_entity.dart`                    | `bracket_entity.dart`                    |
| **Model**       | `{entity}_model.dart`                     | `bracket_model.dart`                     |
| **Repository**  | `{entity}_repository.dart` (interface)    | `bracket_repository.dart`                |
| **Repo Impl**   | `{entity}_repository_implementation.dart` | `bracket_repository_implementation.dart` |
| **Use Cases**   | `{action}_{entity}_usecase.dart`          | `generate_bracket_usecase.dart`          |
| **Params**      | `{action}_{entity}_params.dart`           | `generate_bracket_params.dart`           |
| **Local DS**    | `{entity}_local_datasource.dart`          | `bracket_local_datasource.dart`          |
| **Remote DS**   | `{entity}_remote_datasource.dart`         | `bracket_remote_datasource.dart`         |
| **BLoC**        | `{feature}_bloc.dart`                     | `bracket_bloc.dart`                      |
| **Events**      | `{feature}_event.dart`                    | `bracket_event.dart`                     |
| **States**      | `{feature}_state.dart`                    | `bracket_state.dart`                     |
| **README**      | `README.md`                               | `README.md`                              |

> **⚠️ Use Case File Naming — KNOWN INCONSISTENCY IN CODEBASE:**
> - **Auth feature** uses TWO-WORD pattern: `accept_invitation_use_case.dart`, `create_organization_use_case.dart`
> - **Tournament/Participant features** use ONE-WORD pattern: `archive_tournament_usecase.dart`, `assign_participants_to_divisions_usecase.dart`
> - **For bracket feature: USE THE ONE-WORD PATTERN** (`usecase`) — this is the newer, more established convention from Epics 3-4. Do NOT follow the auth feature's older `use_case` (two words) pattern.

### DI Registration Patterns (for Story 5.2+ — context only)

When annotated classes are added in future stories, they follow these rules:

```dart
// Use Cases — TRANSIENT (new instance per injection)
@injectable
class GenerateBracketUseCase {
  final BracketRepository _bracketRepository;
  GenerateBracketUseCase(this._bracketRepository);
  // ...
}

// Repositories — SINGLETON (shared instance)
@LazySingleton(as: BracketRepository)
class BracketRepositoryImplementation implements BracketRepository {
  // ...
}

// Datasources — SINGLETON
@lazySingleton
class BracketLocalDatasource {
  // ...
}
```

### ⚠️ Database Schema Context (for Story 5.2+ — DO NOT IMPLEMENT NOW)

The architecture defines these Supabase/Drift tables for the bracket feature. This schema is provided as **read-only context** so dev agents understand what the bracket feature will eventually contain.

**Brackets Table** (from `architecture.md` lines 1463-1486):
```sql
CREATE TABLE brackets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    division_id UUID NOT NULL REFERENCES divisions(id) ON DELETE CASCADE,
    bracket_type TEXT NOT NULL 
        CHECK (bracket_type IN ('winners', 'losers', 'pool')),
    pool_identifier TEXT 
        CHECK (pool_identifier IS NULL OR 
               pool_identifier IN ('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H')),
    total_rounds INTEGER NOT NULL,
    is_finalized BOOLEAN NOT NULL DEFAULT FALSE,
    generated_at_timestamp TIMESTAMPTZ,
    finalized_at_timestamp TIMESTAMPTZ,
    bracket_data_json JSONB,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at_timestamp TIMESTAMPTZ,
    is_demo_data BOOLEAN NOT NULL DEFAULT FALSE,
    created_at_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sync_version BIGINT NOT NULL DEFAULT 1
);
```

**Matches Table** (from `architecture.md` lines 1488-1521):
```sql
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bracket_id UUID NOT NULL REFERENCES brackets(id) ON DELETE CASCADE,
    round_number INTEGER NOT NULL CHECK (round_number >= 1),
    match_number_in_round INTEGER NOT NULL CHECK (match_number_in_round >= 1),
    participant_red_id UUID REFERENCES participants(id),
    participant_blue_id UUID REFERENCES participants(id),
    winner_id UUID REFERENCES participants(id),
    winner_advances_to_match_id UUID REFERENCES matches(id),
    loser_advances_to_match_id UUID REFERENCES matches(id),
    scheduled_ring_number INTEGER,
    scheduled_time TIME,
    status TEXT NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'ready', 'in_progress', 'completed', 'cancelled')),
    result_type TEXT 
        CHECK (result_type IN ('points', 'knockout', 'disqualification', 
                               'withdrawal', 'referee_decision', 'bye')),
    notes TEXT,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at_timestamp TIMESTAMPTZ,
    is_demo_data BOOLEAN NOT NULL DEFAULT FALSE,
    started_at_timestamp TIMESTAMPTZ,
    completed_at_timestamp TIMESTAMPTZ,
    created_at_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sync_version BIGINT NOT NULL DEFAULT 1
);

-- Composite index for bracket rendering
CREATE INDEX idx_matches_bracket_round ON matches(bracket_id, round_number);
```

> **⚠️ This schema context is for future reference only. DO NOT create tables in this story.**

### ⚠️ Drift Table Patterns — BaseSyncMixin & BaseAuditMixin (for Story 5.2+ — context only)

All existing Drift tables use two mixins defined in `lib/core/database/tables/base_tables.dart`. The bracket and matches tables MUST also use these when created in Stories 5.2-5.3:

```dart
// base_tables.dart — provides common columns to ALL synced tables
mixin BaseSyncMixin on Table {
  IntColumn get syncVersion => integer().named('sync_version').withDefault(const Constant(1))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAtTimestamp => dateTime().nullable()();
  BoolColumn get isDemoData => boolean().withDefault(const Constant(false))();
}

mixin BaseAuditMixin on Table {
  DateTimeColumn get createdAtTimestamp => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAtTimestamp => dateTime().withDefault(currentDateAndTime)();
}
```

**Usage pattern** (from existing `divisions_table.dart`):
```dart
class Divisions extends Table with BaseSyncMixin, BaseAuditMixin {
  // Feature-specific columns go here
  // BaseSyncMixin provides: syncVersion, isDeleted, deletedAtTimestamp, isDemoData
  // BaseAuditMixin provides: createdAtTimestamp, updatedAtTimestamp
}
```

> **For this scaffolding story, no table creation is needed. This context ensures Story 5.2 dev agent knows to use these mixins.**

### What This Story Does NOT Include

This is a **scaffolding story only**. The following are implemented in subsequent stories:

| Component                     | Story      | Key Detail                                            |
| ----------------------------- | ---------- | ----------------------------------------------------- |
| `BracketEntity` (freezed)     | Story 5.2  | Domain entity for bracket structure                   |
| `BracketRepository` interface | Story 5.2  | Abstract class in `domain/repositories/`              |
| `brackets_table.dart` (Drift) | Story 5.2  | Drift table definition in `core/database/tables/`     |
| `MatchEntity` (freezed)       | Story 5.3  | Domain entity for match tree nodes                    |
| `MatchRepository` interface   | Story 5.3  | Tree traversal queries                                |
| `matches_table.dart` (Drift)  | Story 5.3  | Drift table definition; self-referential FK           |
| `SingleEliminationGenerator`  | Story 5.4  | Knockout bracket generation algorithm                 |
| `DoubleEliminationGenerator`  | Story 5.5  | Winners + Losers bracket pair                         |
| `RoundRobinGenerator`         | Story 5.6  | Round-robin schedule Generation                       |
| `DojangSeparationSeeder`      | Story 5.7  | Constraint-satisfaction seeding in `core/algorithms/` |
| `RegionalSeparationSeeder`    | Story 5.8  | Geographic separation seeding                         |
| `ManualSeedOverrideUseCase`   | Story 5.9  | Swap/pin seed positions                               |
| `ByeAssignmentService`        | Story 5.10 | Fair bye distribution                                 |
| `RegenerateBracketUseCase`    | Story 5.11 | Re-generate after participant changes                 |
| `LockBracketUseCase`          | Story 5.12 | Prevent accidental changes during competition         |
| `BracketVisualizationWidget`  | Story 5.13 | Zoomable/pannable bracket tree UI                     |

---

## Anti-Patterns — WHAT NOT TO DO

> **These are actual mistakes caught in previous epic code reviews. Do NOT repeat them.**

| ❌ Don't Do This                                 | ✅ Do This Instead                                   | Source                                       |
| ----------------------------------------------- | --------------------------------------------------- | -------------------------------------------- |
| Export files that don't exist in barrel         | Only export files that actually exist               | Epic 2 code reviews                          |
| Create database tables in feature dir           | Drift tables stay in `core/database/tables/`        | Architecture doc                             |
| Forget `.gitkeep` in parent directories         | Place `.gitkeep` in ALL directories                 | Story 3.1 code review                        |
| Mark dependencies as current in README          | Mark as `(Planned)` with story references           | Story 3.1 code review                        |
| Create `services/` directory prematurely        | Let subsequent stories create as needed             | Architecture alignment                       |
| Skip structure tests                            | Always create `structure_test.dart`                 | Story 3.1 pattern                            |
| Use `use_case` (two words) in filename          | Use `usecase` (one word) matching existing pattern  | Codebase consistency                         |
| Modify existing infrastructure                  | Bracket feature structure is scaffolding only       | Architecture boundary                        |
| Duplicate `BracketFormat` enum                  | Import from `division_entity.dart`                  | DRY principle                                |
| Create `brackets/` (plural) directory           | Feature directory is `bracket/` (singular)          | Architecture doc                             |
| Create seeding dirs inside bracket              | Seeding goes in `core/algorithms/seeding/`          | Architecture doc                             |
| Forget test mirror `pages/` and `widgets/` dirs | Include ALL presentation sub-dirs in test mirror    | Story 4.1 code review                        |
| Forget `.gitkeep` in test mirror directories    | Test mirror gets `.gitkeep` in EVERY dir (12 total) | Story 3.1 code review                        |
| Use `use_case` (two words) for new features     | Use `usecase` (one word) — newer Epics 3-4 pattern  | Auth vs Tournament/Participant inconsistency |

---

## Upstream/Downstream Dependencies

**Upstream (Required — ALL COMPLETE):**

| Story / Epic                   | Provides                                                                                                 | Status |
| ------------------------------ | -------------------------------------------------------------------------------------------------------- | ------ |
| Epic 1: Foundation & Demo Mode | Base directory structure, Clean Architecture setup, `get_it` + `injectable`, Drift database, core tables | ✅ DONE |
| Epic 2: Auth & Organization    | Auth feature structure pattern, DI patterns, barrel file patterns                                        | ✅ DONE |
| Epic 3: Tournament & Division  | Tournament/Division features, `BracketFormat` enum in `division_entity.dart`, `DivisionStatus` enum      | ✅ DONE |
| Epic 4: Participant Management | Participant feature structure (primary reference), `ParticipantEntity`, assignment to divisions          | ✅ DONE |

**Downstream (Enables — ALL BLOCKED until this story is DONE):**

| Story                                  | What It Needs From This Story                                                                         |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Story 5.2: Bracket Entity & Repository | `lib/features/bracket/` directory structure, `domain/entities/`, `domain/repositories/`, `data/` dirs |
| Story 5.3: Match Entity & Repository   | Same directory structure + bracket entity exists from 5.2                                             |
| Stories 5.4-5.6: Bracket Generators    | `domain/usecases/` directory for generator classes                                                    |
| Story 5.7: Dojang Separation           | Bracket entity and repository must exist (5.2) — NOT blocked by this story directly                   |
| Story 5.13: Bracket Visualization      | `presentation/bloc/`, `presentation/pages/`, `presentation/widgets/` directories                      |

---

## References

**Source Documents:**
- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 5: Bracket Generation & Seeding Stories, lines 1665-1931]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Clean Architecture (lines 1120-1165), Database Schema (lines 1463-1521), Naming Conventions, Seeding Algorithm Architecture (lines 1720-1853)]
- [Source: `_bmad-output/implementation-artifacts/4-1-participant-feature-structure.md` — Primary reference for feature structure story pattern]
- [Source: `_bmad-output/implementation-artifacts/3-1-tournament-feature-structure.md` — Secondary reference, includes code review fixes]
- [Source: `_bmad-output/implementation-artifacts/epic-3-retro-2026-02-25.md` — Epic 3 retrospective: division merge handling, centralized algorithms]
- [Source: `_bmad-output/implementation-artifacts/epic-4-retro-2026-02-25.md` — Epic 4 retrospective: DI parameter limits, build_runner caching, participant prerequisite for brackets]

**Code References (STUDY THESE before implementing):**
- `tkd_brackets/lib/features/participant/participant.dart` — Barrel file pattern (17 lines, has exports from 4.2+). **USE THIS as primary barrel file reference**
- `tkd_brackets/lib/features/tournament/tournament.dart` — Barrel file pattern (39 lines, fully populated with exports). **Shows what bracket.dart will eventually look like**
- `tkd_brackets/lib/features/participant/README.md` — README pattern (23 lines). **USE THIS as primary README reference**
- `tkd_brackets/lib/features/tournament/README.md` — README pattern (18 lines, slightly simpler). **Secondary README reference**
- `tkd_brackets/test/features/participant/structure_test.dart` — Structure test pattern (134 lines). **Primary test reference — USE THIS**
- `tkd_brackets/test/features/tournament/structure_test.dart` — Structure test pattern (159 lines, has tournament-specific tests). **Shows how to add feature-specific test cases**
- `tkd_brackets/lib/features/division/domain/entities/division_entity.dart` — BracketFormat enum (DO NOT MODIFY — 100 lines)
- `tkd_brackets/lib/core/database/app_database.dart` — Current schema v5, 8 registered tables (DO NOT MODIFY — 575 lines)
- `tkd_brackets/lib/core/database/tables/base_tables.dart` — BaseSyncMixin + BaseAuditMixin definitions (35 lines — context for Story 5.2+ Drift tables)

---

## Dev Agent Record

### Agent Model Used
Antigravity (Gemini 2.0 Flash)

### Debug Log References
- Verified bracket feature directory does not exist.
- Verified `BracketFormat` enum in `division_entity.dart`.
- Verified `app_database.dart` schema version 5.
- Created 13 lib directories and 12 `.gitkeep` files.
- Created `bracket.dart` barrel file with zero exports.
- Created `README.md` with planned dependencies.
- Created 13 test directories and 12 `.gitkeep` files.
- Created `structure_test.dart` and verified all tests pass.
- Ran `build_runner build` successfully.
- Ran `flutter analyze` and verified zero new issues in bracket feature.

### Completion Notes List
- Scaffolded bracket feature following Clean Architecture.
- Layers: data, domain, presentation.
- Tests mirror lib structure.
- Barrel file and README established.
- Verified integrity of existing core/division files.

### File List
- `lib/features/bracket/bracket.dart`
- `lib/features/bracket/README.md`
- `lib/features/bracket/data/.gitkeep`
- `lib/features/bracket/data/datasources/.gitkeep`
- `lib/features/bracket/data/models/.gitkeep`
- `lib/features/bracket/data/repositories/.gitkeep`
- `lib/features/bracket/domain/.gitkeep`
- `lib/features/bracket/domain/entities/.gitkeep`
- `lib/features/bracket/domain/repositories/.gitkeep`
- `lib/features/bracket/domain/usecases/.gitkeep`
- `lib/features/bracket/presentation/.gitkeep`
- `lib/features/bracket/presentation/bloc/.gitkeep`
- `lib/features/bracket/presentation/pages/.gitkeep`
- `lib/features/bracket/presentation/widgets/.gitkeep`
- `test/features/bracket/structure_test.dart`
- `test/features/bracket/data/.gitkeep`
- `test/features/bracket/data/datasources/.gitkeep`
- `test/features/bracket/data/models/.gitkeep`
- `test/features/bracket/data/repositories/.gitkeep`
- `test/features/bracket/domain/.gitkeep`
- `test/features/bracket/domain/entities/.gitkeep`
- `test/features/bracket/domain/repositories/.gitkeep`
- `test/features/bracket/domain/usecases/.gitkeep`
- `test/features/bracket/presentation/.gitkeep`
- `test/features/bracket/presentation/bloc/.gitkeep`
- `test/features/bracket/presentation/pages/.gitkeep`
- `test/features/bracket/presentation/widgets/.gitkeep`

---

## Change Log

- **2026-02-25**: Story file created with comprehensive context for bracket feature scaffolding. Modeled on Story 4.1 (participant feature structure) with bracket-specific context including database schema reference, seeding algorithm architecture context, BracketFormat enum cross-reference, and anti-patterns from all prior epic code reviews.
- **2026-02-25**: Adversarial checklist review applied — 12 improvements: fixed incomplete matches table schema (added `notes`, `started_at_timestamp`, `completed_at_timestamp`, `result_type` full values), added use_case naming inconsistency warning, added test dir `.gitkeep` verification, added exact shell commands for all validation tasks, added `BaseSyncMixin`/`BaseAuditMixin` context, expanded `services/` directory rationale, added upstream/downstream dependency table, incorporated Epic 3+4 retrospective insights, added quick validation script (Task 9), added sprint status update task (Task 10), added 2 new anti-patterns.
- **2026-02-25**: Implemented bracket feature structure. Created all directories, barrel file, README, and structure tests. Verified 100% test pass and zero analysis errors. Updated sprint status to review.
- **2026-02-25**: **Code Review (Antigravity)** — Adversarial review passed. 3 MEDIUM, 3 LOW issues found and fixed: (1) Checked off all 10 ACs that were left unchecked despite completed tasks, (2) Added TODO(Story-5.2) comment to zero-export test that will break when exports are added, (3) Fixed pre-existing sprint-status issue — Epic 4 and Story 4-3 moved to `done`. Status → done.
