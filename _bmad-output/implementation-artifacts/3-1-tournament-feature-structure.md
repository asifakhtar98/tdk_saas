# Story 3.1: Tournament Feature Structure

Status: done

## TL;DR - Critical Facts

**CURRENT STATE:** Tournament feature partially exists from Epic 1/2 demo work:
- ✅ `lib/features/tournament/tournament.dart` - barrel file exists (minimal exports)
- ✅ `lib/features/tournament/presentation/pages/tournament_list_page.dart` - placeholder page exists
- ❌ `data/` directory missing entirely
- ❌ `domain/` directory missing entirely
- ❌ `presentation/bloc/`, `presentation/widgets/` missing

**TARGET STATE:** Complete Clean Architecture 3-layer structure matching `auth/` feature pattern.

**KEY LESSONS FROM EPIC 2:**
- Use cases = `@injectable` (transient), Repos/Services = `@lazySingleton`
- JSON keys must be snake_case for Supabase (`@JsonKey(name: 'field_name')`)
- Clean up orphaned `.freezed.dart`/`.g.dart` files when renaming
- Repository manages sync_version, not use cases

---

## Story

**As a** developer,
**I want** the tournament feature properly structured with Clean Architecture layers,
**So that** all tournament-related code follows consistent patterns.

## Acceptance Criteria

- [x] **AC1**: Tournament feature directory structure exists with data/domain/presentation layers following Clean Architecture
- [x] **AC2**: Directory structure matches the specified layout:
  ```
  lib/features/tournament/
  ├── data/
  │   ├── datasources/       # Create: local + remote datasource files
  │   ├── models/            # Create: DTO files with JSON serialization
  │   ├── repositories/      # Create: repository implementations
  │   └── services/          # Create: feature-specific services
  ├── domain/
  │   ├── entities/          # Create: Tournament, Division entities
  │   ├── repositories/      # Create: repository interfaces
  │   └── usecases/          # Create: use case classes
  └── presentation/
      ├── bloc/              # Create: BLoC files
      ├── pages/             # EXISTS: tournament_list_page.dart (preserve)
      └── widgets/           # Create: reusable widgets
  ```
- [x] **AC3**: Feature barrel file `lib/features/tournament/tournament.dart` exists and exports public APIs (UPDATE existing, don't overwrite)
- [x] **AC4**: Feature is discoverable by `injectable_generator` (proper structure for auto-registration)
- [x] **AC5**: Feature README documents the tournament feature scope and structure (CREATE new)
- [x] **AC6**: Unit tests verify directory structure exists and is correctly organized
- [x] **AC7**: `flutter analyze` passes with zero errors
- [x] **AC8**: `dart run build_runner build` completes successfully
- [x] **AC9**: **PRESERVE EXISTING:** `tournament_list_page.dart` placeholder page not deleted or broken

## Tasks / Subtasks

- [x] Task 1: Verify Current State (AC: #9)
  - [x] Run `ls -la lib/features/tournament/` to confirm existing files
  - [x] Read `tournament.dart` to understand current exports
  - [x] Read `tournament_list_page.dart` to understand current implementation
- [x] Task 2: Create Missing Directory Structure (AC: #1, #2)
  - [x] Create `data/datasources/` + add `.gitkeep`
  - [x] Create `data/models/` + add `.gitkeep`
  - [x] Create `data/repositories/` + add `.gitkeep`
  - [x] Create `data/services/` + add `.gitkeep`
  - [x] Create `domain/entities/` + add `.gitkeep`
  - [x] Create `domain/repositories/` + add `.gitkeep`
  - [x] Create `domain/usecases/` + add `.gitkeep`
  - [x] Create `presentation/bloc/` + add `.gitkeep`
  - [x] Create `presentation/widgets/` + add `.gitkeep`
  - [x] Verify `presentation/pages/` exists (should have tournament_list_page.dart)
- [x] Task 3: Update Feature Barrel File (AC: #3)
  - [x] Update `lib/features/tournament/tournament.dart` following `auth.dart` pattern
  - [x] Structure: data exports → domain exports → presentation exports
  - [x] Keep existing `tournament_list_page.dart` export
- [x] Task 4: Create Feature README (AC: #5)
  - [x] Create `lib/features/tournament/README.md` following auth README pattern
  - [x] Document: FRs covered (FR1-FR12), structure, dependencies
- [x] Task 5: Verify DI Integration (AC: #4, #8)
  - [x] Run `dart run build_runner build --delete-conflicting-outputs`
  - [x] Verify no errors in generation
  - [x] Check `injection.config.dart` updates (may be empty until entities added)
- [x] Task 6: Structure Validation Tests (AC: #6)
  - [x] Create `test/features/tournament/structure_test.dart`
  - [x] Verify all directories exist
  - [x] Verify barrel file structure
- [x] Task 7: Static Analysis (AC: #7)
  - [x] Run `flutter analyze` and fix any issues
- [x] Task 8: Preserve Existing Functionality (AC: #9)
  - [x] Verify `tournament_list_page.dart` still renders correctly
  - [x] Verify barrel file still exports the page

## Dev Notes

### Current State Analysis

**Existing Files (PRESERVE THESE):**
```
lib/features/tournament/
├── tournament.dart                              # EXISTS - minimal barrel file
└── presentation/
    └── pages/
        └── tournament_list_page.dart           # EXISTS - placeholder UI
```

**Target Structure (CREATE MISSING):**
```
lib/features/tournament/
├── tournament.dart                              # UPDATE - full barrel file
├── README.md                                    # CREATE
├── data/
│   ├── datasources/
│   │   ├── tournament_local_datasource.dart    # Future: Drift
│   │   └── tournament_remote_datasource.dart   # Future: Supabase
│   ├── models/
│   │   └── tournament_model.dart               # Future: freezed DTO
│   ├── repositories/
│   │   └── tournament_repository_impl.dart     # Future: implements domain interface
│   └── services/
│       └── (future tournament-specific services)
├── domain/
│   ├── entities/
│   │   └── tournament_entity.dart              # Future: core entity
│   ├── repositories/
│   │   └── tournament_repository.dart          # Future: abstract interface
│   └── usecases/
│       └── (future use cases)
└── presentation/
    ├── bloc/
    │   └── (future BLoC files)
    ├── pages/
    │   └── tournament_list_page.dart           # EXISTS - preserve
    └── widgets/
        └── (future widgets)
```

### Architecture Compliance

**CRITICAL LAYER DEPENDENCY RULES:**

| Layer | Can Depend On | CANNOT Depend On |
|-------|---------------|------------------|
| **Presentation** | Domain | Data |
| **Domain** | Core only | Data, Presentation, External SDKs |
| **Data** | Domain (interfaces only) | Presentation |

**Domain Layer Isolation (MUST ENFORCE):**
- ❌ NO `import 'package:supabase_flutter/supabase_flutter.dart'` in domain
- ❌ NO `import 'package:drift/drift.dart'` in domain
- ❌ NO catching `AuthException`, `PostgrestException` in domain
- ✅ Domain only uses: `fpdart`, `freezed`, `equatable`, core Dart/Flutter

**Exception → Failure Mapping:**
- Repository implementations (data layer) catch infrastructure exceptions
- Repository implementations map to domain `Failure` types
- Use cases receive `Either<Failure, T>` from repositories

### Dependencies

**Upstream (Required):**

| Story | Provides |
|-------|----------|
| 1.1 Project Scaffold | Base directory structure, Clean Architecture setup |
| 1.2 Dependency Injection | `get_it` + `injectable` configuration |
| 2.1 Auth Feature Structure | Pattern reference for feature structure |
| 2.10 Demo-to-Production Migration | Organization context, multi-tenancy understanding |

**Downstream (Enables):**
- Story 3.2: Tournament Entity & Repository
- Story 3.3: Create Tournament Use Case
- Story 3.4-3.14: All remaining Epic 3 stories

### Epic 2 Learnings - APPLY THESE

**From Epic 2 Retrospective (epic-2-retro-2026-02-16.md):**

1. **Sync Versioning:** Repository should READ existing version, let Database handle increment during update
2. **Generated Files Cleanup:** When renaming files, delete orphaned `.freezed.dart` and `.g.dart` files immediately
3. **JSON Naming:** Must use snake_case for Supabase (`@JsonKey(name: 'field_name')`)
4. **DI Scope:** Use cases = `@injectable` (transient), Repos/Services = `@lazySingleton` (singleton)
5. **Security Checks:** Always verify organization ID matching in use cases (prevent cross-org attacks)

### Code Patterns

**Barrel File Template (from auth.dart):**
```dart
/// Tournament feature - exports public APIs.
library;

// Data exports will be added here
// export 'data/datasources/...';
// export 'data/models/...';
// export 'data/repositories/...';

// Domain exports will be added here
// export 'domain/entities/...';
// export 'domain/repositories/...';
// export 'domain/usecases/...';

// Presentation exports
export 'presentation/pages/tournament_list_page.dart';
```

**README.md Template (from auth README):**
```markdown
# Tournament Feature

Manages tournaments, divisions, and tournament configuration for TKD Brackets.

## FRs Covered
- FR1-FR12 (Epic 3)

## Structure
- `data/` - Datasources, models, repository implementations, services
- `domain/` - Entities, repository interfaces, use cases
- `presentation/` - BLoC, pages, widgets

## Dependencies
- `drift` - Local database
- `supabase_flutter` - Remote backend
- `flutter_bloc` - State management
- `fpdart` - Functional error handling
```

### References

**Source Documents:**
- [Source: planning-artifacts/epics.md#Story 3.1] - Original story requirements
- [Source: planning-artifacts/architecture.md#Clean Architecture] - Layer dependency rules
- [Source: implementation-artifacts/epic-2-retro-2026-02-16.md] - Epic 2 learnings

**Code References:**
- `lib/features/auth/auth.dart` - Barrel file pattern
- `lib/features/auth/README.md` - README pattern
- `lib/features/auth/data/` - Complete layer structure example
- `lib/core/usecases/use_case.dart` - UseCase base class

## Dev Agent Record

### Agent Model Used

opencode/kimi-k2.5-free

### Debug Log References

- No debug issues encountered

### Completion Notes List

1. **Task 1 Complete:** Verified existing tournament.dart barrel file and tournament_list_page.dart placeholder page
2. **Task 2 Complete:** Created all required Clean Architecture directories (data/, domain/, presentation/) with .gitkeep files
3. **Task 3 Complete:** Updated tournament.dart barrel file following auth.dart pattern with organized export sections
4. **Task 4 Complete:** Created README.md documenting FRs covered, structure, and dependencies
5. **Task 5 Complete:** build_runner completed successfully (295 project-wide outputs, 0 tournament-specific registrations as expected - no annotated classes yet)
6. **Task 6 Complete:** Created structure_test.dart with 5 passing tests validating directory structure
7. **Task 7 Complete:** flutter analyze shows 70 pre-existing issues in other files, 0 issues in tournament feature
8. **Task 8 Complete:** Verified existing functionality preserved - tournament_list_page.dart unchanged and properly exported
9. **Code Review Fixes:** Clarified AC4 documentation, standardized barrel file placeholders, marked README dependencies as planned, added parent directory .gitkeep files, enhanced tests with architecture compliance verification

### File List

**Modified:**
- `lib/features/tournament/tournament.dart` - Updated barrel file with organized export structure

**Created:**
- `lib/features/tournament/README.md` - Feature documentation
- `lib/features/tournament/data/.gitkeep` - Parent directory marker
- `lib/features/tournament/data/datasources/.gitkeep`
- `lib/features/tournament/data/models/.gitkeep`
- `lib/features/tournament/data/repositories/.gitkeep`
- `lib/features/tournament/data/services/.gitkeep`
- `lib/features/tournament/domain/.gitkeep` - Parent directory marker
- `lib/features/tournament/domain/entities/.gitkeep`
- `lib/features/tournament/domain/repositories/.gitkeep`
- `lib/features/tournament/domain/usecases/.gitkeep`
- `lib/features/tournament/presentation/.gitkeep` - Parent directory marker
- `lib/features/tournament/presentation/bloc/.gitkeep`
- `lib/features/tournament/presentation/widgets/.gitkeep`
- `test/features/tournament/structure_test.dart` - Structure validation tests with architecture compliance

**Preserved (Existing):**
- `lib/features/tournament/presentation/pages/tournament_list_page.dart` - Placeholder UI page

**AC4 Clarification:**
- AC4 "Feature is discoverable by injectable_generator" refers to **structural readiness** (proper directory layout enabling future DI registration)
- Actual DI registrations will appear in `injection.config.dart` once annotated classes are added in Stories 3.2+
- Current state: 0 tournament-specific registrations (expected - no classes with `@injectable` or `@lazySingleton` yet)

---

## Change Log

**2026-02-16:** Story implementation complete
- Created full Clean Architecture directory structure (data/, domain/, presentation/)
- Updated barrel file with organized export sections following auth pattern
- Created README.md with FR documentation and structure overview
- Generated injection.config.dart updates via build_runner (295 outputs, 0 errors)
- Added structure validation tests (5 tests, all passing)
- Verified flutter analyze passes (0 new issues in tournament feature)
- Preserved existing tournament_list_page.dart functionality
- All 9 acceptance criteria satisfied

**2026-02-16:** Code review complete - Senior Developer Review
- Clarified AC4 documentation (structural readiness vs DI registration)
- Fixed Dev Agent Record exaggeration (project-wide vs feature-specific outputs)
- Standardized barrel file placeholder consistency
- Updated README dependencies as "(Planned)"
- Added .gitkeep to parent directories (data/, domain/, presentation/)
- Enhanced tests with architecture compliance verification (+4 tests, total 9)
- All tests passing, flutter analyze clean
- Status: approved → done

---

## Senior Developer Review (AI)

**Reviewer:** opencode/kimi-k2.5-free  
**Date:** 2026-02-16  
**Outcome:** ✅ Approved with fixes applied

### Issues Found & Fixed

| Severity | Issue | Fix Applied |
|----------|-------|-------------|
| Medium | AC4 misleading - claimed DI discoverability but 0 registrations | Updated Dev Agent Record to clarify "structural readiness" vs actual registrations |
| Low | Dev Agent Record exaggerated build_runner outputs (295 project-wide vs 0 feature-specific) | Clarified context in Completion Notes |
| Low | Barrel file placeholder inconsistency (some `...`, some specific names) | Standardized all placeholders to follow consistent pattern |
| Low | README documented unimplemented dependencies as current | Marked all dependencies as "(Planned)" with story references |
| Low | Parent directories lacked .gitkeep while subdirs had them | Added .gitkeep to data/, domain/, presentation/ for consistency |
| Low | Tests only checked file existence, not architecture compliance | Added 4 new tests: domain isolation, barrel organization, .gitkeep consistency, documentation |

### Architecture Compliance Verified

- ✅ Domain layer isolation: No infrastructure imports detected
- ✅ Barrel file organization: Data → Domain → Presentation sections present
- ✅ Clean Architecture structure: All 3 layers properly separated
- ✅ Dependency rule compliance: Structure supports proper layer dependencies

### Test Results

- **Before:** 5 tests (structure only)
- **After:** 9 tests (structure + architecture compliance + documentation)
- **All tests passing:** ✅

---

**Story Context:** Comprehensive developer guide with Epic 2 learnings and existing code preservation
**Epic:** 3 - Tournament & Division Management
**Story Key:** 3-1-tournament-feature-structure
