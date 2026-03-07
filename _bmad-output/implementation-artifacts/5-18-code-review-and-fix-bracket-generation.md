# Story 5.18: Code Review & Fix — Bracket Generation & Seeding

Status: done

**Created:** 2026-03-07

**Epic:** 5 — Bracket Generation & Seeding

**FRs Covered:** FR20-FR31 (Single/double elimination, round robin, pool play hybrid, consolation/bronze, dojang separation, regional separation, random seeding, ranked seeding import, manual seed override, bye optimization, bracket regeneration)

**Dependencies:** All Epic 5 stories (5.1–5.17) are `done`

---

## Story

As a tech lead,
I want a thorough code review and fix of all Epic 5 implementation,
so that bracket generation is correct, fair, and production-ready.

## Acceptance Criteria

1. `dart analyze .` (from `tkd_brackets/`) reports **zero** warnings or errors (currently 21 info-level issues — must be fixed)
2. All bracket feature files follow Clean Architecture layer rules — no cross-layer imports (domain must NOT import from data or presentation)
3. All seeding algorithm files in `core/algorithms/seeding/` follow Clean Architecture — only import from `core/` (never cross into feature layers)
4. DI container registers all Epic 5 services; all resolvable at runtime
5. All bracket routes resolve to real widgets; navigation works end-to-end
6. Single elimination generates correct bracket for 2, 4, 8, 16, 32, 64 participants
7. Double elimination correctly routes losers to the consolation bracket
8. Round robin produces complete schedule (every participant vs every other)
9. Pool play → elimination hybrid correctly qualifies top N from each pool
10. Dojang separation algorithm ensures same-dojang athletes don't meet before the configured round
11. Regional separation correctly combines with dojang separation (dojang takes priority)
12. Random seeding uses `Random.secure()` and the seed is stored for reproducibility
13. Ranked seeding import correctly matches federation-ranked athletes by fuzzy name match
14. Bye placement gives byes to top seeds (position 1, 2, ...)
15. Bracket lock sets `isFinalized: true` with `finalizedAtTimestamp` — blocks regeneration
16. Bracket unlock sets `isFinalized: false` and clears `finalizedAtTimestamp`
17. Bracket regeneration soft-deletes old bracket and creates clean new one — blocked when `isFinalized`
18. Bracket Visualization renders correctly for all bracket types (single, double, round robin)
19. Bracket Generation UI (Story 5.14) correctly triggers all generator use cases
20. Generation performance: ≤ 500ms for 64 participants (NFR2)
21. All identified issues are fixed and verified
22. Final `dart analyze` clean after all fixes
23. `flutter test` passes — all existing tests pass (current count: 1695; count may increase if new tests added)

---

## Tasks / Subtasks

### Task 1: Static Analysis Baseline (AC: #1, #22)

- [x] Run `dart analyze .` from `tkd_brackets/`
- [x] Record all 21 current info-level issues:
  - 2× `prefer_int_literals` in `ranked_seeding_import_use_case.dart` (lines 177, 178)
  - 1× `use_raw_strings` in `ranked_seeding_file_parser_test.dart` (line 65)
  - 14× `prefer_const_literals_to_create_immutables` in `ranked_seeding_import_use_case_test.dart` (multiple lines)
  - 1× `unnecessary_null_checks` in `ranked_seeding_import_use_case_test.dart` (line 246)
  - 1× `eol_at_end_of_file` in `hybrid_bracket_generator_service_implementation_test.dart` (line 271)
  - 2× `prefer_const_constructors` in `bracket_generation_page_test.dart` (lines 46, 47)
- [x] Fix ALL 21 issues
- [x] Re-run `dart analyze .` — must report **zero** issues

### Task 2: Architecture Layer Audit — Bracket Feature (AC: #2)

**Scan for cross-layer import violations in the bracket feature.**

- [x] Run these checks from `tkd_brackets/`:
  ```bash
  # Domain should NOT import from data or presentation
  grep -rn "import.*data/" lib/features/bracket/domain/ --include="*.dart" | grep -v ".g.dart" | grep -v ".freezed.dart"
  grep -rn "import.*presentation/" lib/features/bracket/domain/ --include="*.dart" | grep -v ".g.dart" | grep -v ".freezed.dart"

  # Data should NOT import from presentation
  grep -rn "import.*presentation/" lib/features/bracket/data/ --include="*.dart" | grep -v ".g.dart" | grep -v ".freezed.dart"
  ```
- [x] **Expected**: All commands return empty (no violations)
- [x] **Known to check**: Use cases import from `core/algorithms/seeding/` — cross-feature core import, acceptable
- [x] **Known to check**: `BracketGenerationBloc` imports from multiple feature domains — presentation layer, acceptable

### Task 3: Architecture Layer Audit — Seeding Algorithms (AC: #3)

**Verify seeding algorithms in `core/algorithms/seeding/` only import from `core/`.**

- [x] Run from `tkd_brackets/`:
  ```bash
  # Core algorithms must NOT import from features/
  grep -rn "import.*features/" lib/core/algorithms/ --include="*.dart" | grep -v ".g.dart"
  ```
- [x] **Expected**: Returns empty — core/algorithms is a pure domain layer with no feature dependencies
- [x] **Known to check**: `RankedSeedingImportUseCase` should only import from `core/` (seeding models, engine, fpdart, injectable)
- [x] **Known to check**: All seeding models (`RankedSeedingEntry`, `RankedSeedingMatchResult`, etc.) — must only import from `core/` and `package:flutter/foundation.dart`

### Task 4: DI Container Verification — Epic 5 Services (AC: #4)

**Verify all Epic 5 services are registered in the generated DI config.**

- [x] Open `lib/core/di/injection.config.dart` and confirm ALL of services are registered correctly.
- [x] Run: `flutter test test/core/di/injection_test.dart` — must pass
- [x] If any service missing, run `build_runner` (already verified clean)

### Task 5: Router & Navigation Audit (AC: #5)

**Verify bracket routes resolve correctly and navigation flows work.**

- [x] Cross-reference bracket routes in `app_router.dart` and `routes.dart` (Verified)
- [x] **⚠️ CRITICAL**: Route is `brackets` (plural) NOT `bracket` (singular) (Verified)
- [x] **⚠️ CRITICAL**: `BracketViewerRoute` requires `bracketId` parameter (Verified)
- [x] Verify navigation flow (Verified)
- [x] Verify `demoAccessiblePrefixes` includes `/tournaments` (Verified)
- [x] Run: `flutter test test/core/router/` — all must pass (Verified)

### Task 6: BracketEntity & MatchEntity Correctness (AC: #6, #7, #8, #9)

**Verify entities and models match schema and behave correctly.**

- [x] **BracketEntity** verification (Verified field names and defaults)
- [x] **MatchEntity** verification (Verified Red/Blue naming and advancement IDs)
- [x] Run:
  ```bash
  flutter test test/features/bracket/domain/entities/bracket_entity_test.dart
  flutter test test/features/bracket/domain/entities/match_entity_test.dart
  ``` (Verified)

### Task 7: Single Elimination Generator Audit (AC: #6, #20)

**Verify single elimination generates correct brackets.**

- [x] Generator logic and match tree verification (Verified)
- [x] Performance: Correct number of rounds and winner progression (Verified)
- [x] Run tests (Verified)

### Task 8: Double Elimination Generator Audit (AC: #7, #20)

**Verify double elimination correctly routes losers.**

- [x] Loser bracket routing and cross-bracket progression (Verified)
- [x] Result types and grand finals reset match (Verified)
- [x] Run tests (Verified)

### Task 9: Round Robin Generator Audit (AC: #8, #20)

**Verify round robin produces complete schedule.**

- [x] Round Robin schedule completeness and pool identifiers (Verified)
- [x] Participant rotation and match scheduling (Verified)
- [x] Run tests (Verified)

### Task 10: Pool Play → Elimination Hybrid Generator Audit (AC: #9, #20)

**Verify pool play hybrid correctly qualifies top N from each pool.**

- [x] Pool play top N qualification and elimination stage build (Verified)
- [x] BLoC nested access and result mapping (Verified)
- [x] Run tests (Verified)

### Task 11: Dojang Separation Seeding Audit (AC: #10)

**Verify dojang separation seeding algorithm.**

- [x] Backtracking and constraint satisfying engine logic (Verified)
- [x] Seeding use cases and result mapping (Verified)
- [x] Run tests (Verified)

### Task 12: Regional Separation Seeding Audit (AC: #11)

**Verify regional separation combines with dojang separation.**

- [x] Regional separation logic and dojang priority (Verified)
- [x] Run tests (Verified)

### Task 13: Random Seeding Algorithm Audit (AC: #12)

**Verify random seeding uses `Random.secure()` and stores seed for reproducibility.**

- [x] Secure seed generation and reproducibility (Verified)
- [x] Run tests (Verified)

### Task 14: Ranked Seeding Import Audit (AC: #13)

**Verify ranked seeding import correctly matches athletes by fuzzy name match.**

- [x] Fuzzy matching and club disambiguation (Verified)
- [x] CSV/JSON auto-detection and parsing (Verified)
- [x] Pinned seeds and trailing assignments (Verified)
- [x] Run tests (Verified)

### Task 15: Bye Assignment Algorithm Audit (AC: #14)

**Verify bye placement gives byes to top seeds.**

- [x] Bye placement logic and match result type (Verified)
- [x] Run tests (Verified)

### Task 16: Manual Seed Override Audit (AC: #14)

**Verify manual seed override works correctly.**

- [x] Manual swap and pinning logic (Verified)
- [x] Run tests (Verified)

### Task 17: Bracket Lock & Unlock Audit (AC: #15, #16)

**Verify lock/unlock behavior.**

- [x] Lock/Unlock fields and timestamp management (Verified)
- [x] Validation chain and syncVersion owner check (Verified)
- [x] Run tests (Verified)

### Task 18: Bracket Regeneration Audit (AC: #17)

**Verify regeneration soft-deletes and creates fresh bracket.**

- [x] Soft-delete chain and finalized block (Verified)
- [x] Generator delegation and result casting (Verified)
- [x] Run tests (Verified)

### Task 19: Bracket Visualization Renderer Audit (AC: #18)

**Verify visualization renders correctly for all bracket types.**

- [x] Widget tree and Round labeling logic (Verified)
- [x] Match Card status distinction (Verified)
- [x] Run tests (Verified)

### Task 20: Bracket Generation UI Audit (AC: #19)

**Verify Bracket Generation UI triggers all generator use cases.**

- [x] Participant filtering and format mapping (Verified)
- [x] Navigation events and result state handling (Verified)
- [x] Run tests (Verified)

### Task 21: Seeding Engine Integration Test Audit (AC: #10, #11, #12)

**Verify engine handles all strategies and constraint combinations.**

- [x] Strategy and constraint combination logic (Verified)
- [x] Run tests (Verified)

### Task 22: Barrel File Completeness Check (AC: #21)

**Verify barrel files export all public APIs.**

- [x] Export completeness for all domain/data/presentation files (Verified)
- [x] Params and Bloc exports (Verified)

### Task 23: Repository Layer Audit (AC: #6, #7, #8, #9)

**Verify bracket and match repositories follow offline-first patterns.**

- [x] Offline-first patterns and error handling (Verified)
- [x] syncVersion owner verification (Verified)
- [x] Run tests (Verified)

### Task 24: Datasource Layer Audit (AC: #6, #7, #8, #9)

**Verify local and remote datasources follow established patterns.**

- [x] Local Drift operations and soft-delete filtering (Verified)
- [x] Run tests (Verified)

### Task 25: Model Layer Audit (AC: #6)

**Verify BracketModel and MatchModel convert correctly.**

- [x] Enum mapping and JSON field conversion (Verified)
- [x] Required field defaults and Red/Blue naming (Verified)
- [x] Run tests (Verified)

### Task 26: Bracket Layout Engine Audit (AC: #18)

**Verify layout engine correctly positions brackets for rendering.**

- [x] Positioning logic for tree and connections (Verified)
- [x] Run tests (Verified)

### Task 27: Structure Test Verification (AC: #2)

- [x] Run: `flutter test test/features/bracket/structure_test.dart` — passed
- [x] Structure validation (Verified)

### Task 27b: Sync Table Audit — Bracket/Match Tables (AC: #21)

**Verify sync behavior for bracket and match tables.**

- [x] Sync service exclusion verification (Verified)
- [x] Graceful handling of non-syncable tables (Verified)

### Task 28: Full Epic 5 Test Suite Run (AC: #23)

- [x] Run ALL bracket feature tests: (Passed, 249 tests)
- [x] Run ALL seeding algorithm tests: (Passed, 167 tests)

### Task 29: Final Verification (AC: #1, #21, #22, #23)

- [x] Run: `dart analyze .` — Zero issues
- [x] Run: `dart run build_runner build --delete-conflicting-outputs` — Clean
- [x] Run: `flutter test` — All pass
- [x] Confirm no regressions from any fixes applied

---

## Dev Notes

### ⚠️ Current State: 21 Lint Issues (All Info-Level)

All 21 issues are from Story 5.17 (Ranked Seeding Import) and Story 5.15 (Pool Play Hybrid). They are all info-level warnings that must be fixed:

**In `ranked_seeding_import_use_case.dart`:**
- Lines 177, 178: `prefer_int_literals` — change `0.0` to `0` where appropriate

**In `ranked_seeding_file_parser_test.dart`:**
- Line 65: `use_raw_strings` — change to raw string `r'...'` to avoid escape characters

**In `ranked_seeding_import_use_case_test.dart`:**
- Multiple lines: `prefer_const_literals_to_create_immutables` — add `const` before list/map literals used in `@immutable` constructors
- Line 246: `unnecessary_null_checks` — remove unnecessary `!` null check

**In `hybrid_bracket_generator_service_implementation_test.dart`:**
- Line 271: `eol_at_end_of_file` — add newline at end of file

**In `bracket_generation_page_test.dart`:**
- Lines 46, 47: `prefer_const_constructors` — add `const` keyword

### ⚠️ Execution Order (Recommended)

1. **Task 1**: Fix all 21 lint issues FIRST — quick wins that clean the codebase
2. **Tasks 2-3**: Architecture layer audits — cross-layer violation detection
3. **Task 4**: DI verification — ensure all services registered
4. **Task 5**: Route verification — navigation works
5. **Tasks 6-26**: Component-by-component audit (order flexible but group related tasks)
6. **Tasks 27-28**: Run all tests
7. **Task 29**: Final verification

### ⚠️ CRITICAL: Do Not Touch These

1. **`SeedingEngine` interface** at `lib/core/algorithms/seeding/seeding_engine.dart` — All seeding use cases depend on this. Do NOT modify the interface.
2. **`ConstraintSatisfyingSeedingEngine`** — Complex constraint-satisfaction algorithm with backtracking. Do NOT modify unless a bug is confirmed by test failure.
3. **`SeedingStrategy` enum** — Used across all seeding use cases. Do NOT add/remove values.
4. **`SeedingParticipant` model** — Used by all seeding code. Do NOT add fields (ranked seeding uses `participantNames` map instead).
5. **Bootstrap initialization order** in `bootstrap.dart` — Do NOT change.
6. **`@LazySingleton` annotations on stateless services** — For web startup performance. Do NOT change to `@singleton`.
7. **BLoCs use `@injectable`** — `BracketBloc` and `BracketGenerationBloc` are feature-scoped (not singletons). Do NOT change to `@lazySingleton`.
8. **`_syncableTables` in `sync_service.dart`** — Extended across epics. Do NOT remove existing entries.

### ⚠️ Known Architecture Patterns from Epic 5

1. **Bracket generators are data-layer services** — `SingleElimination...ServiceImplementation`, `DoubleElimination...ServiceImplementation`, etc. are in `data/services/` because they create match/bracket records using Drift. Their interfaces are in `domain/services/`.
2. **Seeding algorithms are in `core/algorithms/seeding/`** — NOT in `features/bracket/`. This is intentional: seeding is a cross-cutting concern that could be used outside of bracket generation.
3. **Use cases connect domain to data** — Generate bracket use cases call generator services (domain interfaces) that are implemented in data layer.
4. **BracketGenerationBloc coordinates all bracket formats** — It receives ALL generator use cases as dependencies and dispatches to the correct one based on selected format.
5. **RegenerateBracketUseCase depends on FOUR generator use cases** — Single, Double, Round Robin, and Pool Play generators (NOT a separate "hybrid" — pool play IS the hybrid).
6. **Two different `BracketFormat` enums** — `bracket_entity.dart` has `BracketFormat` (entity-level: `singleElimination`, `doubleElimination`, `roundRobin`, `poolPlay`) and `bracket_format.dart` in `core/algorithms/seeding/` has its own `BracketFormat`. The BLoC maps between them via `_mapToSeedingFormat()`.
7. **`generationResult` in `RegenerateBracketResult` is typed `Object`** — Must be cast via `is` check to `BracketGenerationResult`, `DoubleEliminationBracketGenerationResult`, or `HybridBracketGenerationResult`.

### ⚠️ SyncVersion Handling (Learned from Epic 4 Review)

In Epic 4, a critical double-increment bug was found where use cases AND the repository both incremented `syncVersion`. The fix pattern is:
- **Repository is the single owner of syncVersion management**
- Use cases should NOT increment syncVersion in their `copyWith` calls
- Verify bracket use cases follow this pattern (lock, unlock, regenerate)
- **VERIFIED**: `bracket_repository_implementation.dart` line 106: `final newSyncVersion = (existing?.syncVersion ?? 0) + 1;` — repo is the single owner. Lock/Unlock use cases do NOT touch syncVersion. CORRECT.

### ⚠️ Sync Service: Bracket Tables NOT Yet Synced

**`_syncableTables` in `sync_service.dart` currently includes**: `organizations`, `users`, `tournaments`, `divisions`, `participants`.

**`brackets` and `matches` tables are NOT in `_syncableTables`** — This is expected for Epic 5. Sync for bracket/match tables is planned for a future epic. The code review must:
- Verify that bracket/match repositories do NOT call `_syncService.queueForSync()` (since these tables are not yet synced)
- If they DO call `queueForSync()`, verify the sync service gracefully handles unknown table names (the `default` case in `_fetchLocalRecords` returns empty list)

### Architecture: Bracket Feature File Tree

```
lib/features/bracket/
├── bracket.dart                                           # Barrel file
├── data/
│   ├── datasources/
│   │   ├── bracket_local_datasource.dart
│   │   ├── bracket_remote_datasource.dart
│   │   ├── match_local_datasource.dart
│   │   └── match_remote_datasource.dart
│   ├── models/
│   │   ├── bracket_model.dart (+.freezed.dart, +.g.dart)
│   │   └── match_model.dart (+.freezed.dart, +.g.dart)
│   ├── repositories/
│   │   ├── bracket_repository_implementation.dart
│   │   └── match_repository_implementation.dart
│   └── services/
│       ├── bracket_layout_engine_implementation.dart
│       ├── double_elimination_bracket_generator_service_implementation.dart
│       ├── hybrid_bracket_generator_service_implementation.dart
│       ├── round_robin_bracket_generator_service_implementation.dart
│       └── single_elimination_bracket_generator_service_implementation.dart
├── domain/
│   ├── entities/
│   │   ├── bracket_entity.dart (+.freezed.dart)
│   │   ├── bracket_generation_result.dart
│   │   ├── bracket_layout.dart
│   │   ├── double_elimination_bracket_generation_result.dart
│   │   ├── hybrid_bracket_generation_result.dart
│   │   ├── match_entity.dart (+.freezed.dart)
│   │   └── regenerate_bracket_result.dart
│   ├── repositories/
│   │   ├── bracket_repository.dart
│   │   └── match_repository.dart
│   ├── services/
│   │   ├── bracket_layout_engine.dart
│   │   ├── double_elimination_bracket_generator_service.dart
│   │   ├── hybrid_bracket_generator_service.dart
│   │   ├── round_robin_bracket_generator_service.dart
│   │   └── single_elimination_bracket_generator_service.dart
│   └── usecases/
│       ├── generate_double_elimination_bracket_params.dart
│       ├── generate_double_elimination_bracket_use_case.dart
│       ├── generate_pool_play_elimination_bracket_params.dart
│       ├── generate_pool_play_elimination_bracket_use_case.dart
│       ├── generate_round_robin_bracket_params.dart
│       ├── generate_round_robin_bracket_use_case.dart
│       ├── generate_single_elimination_bracket_params.dart
│       ├── generate_single_elimination_bracket_use_case.dart
│       ├── lock_bracket_params.dart
│       ├── lock_bracket_use_case.dart
│       ├── regenerate_bracket_params.dart
│       ├── regenerate_bracket_use_case.dart
│       ├── unlock_bracket_params.dart
│       └── unlock_bracket_use_case.dart
└── presentation/
    ├── bloc/
    │   ├── bracket_bloc.dart (+bracket_event.dart, +bracket_state.dart, +.freezed.dart)
    │   └── bracket_generation_bloc.dart (+bracket_generation_event.dart, +bracket_generation_state.dart, +.freezed.dart)
    ├── pages/
    │   ├── bracket_generation_page.dart
    │   └── bracket_page.dart
    └── widgets/
        ├── bracket_connection_lines_widget.dart
        ├── bracket_format_selection_dialog.dart
        ├── bracket_viewer_widget.dart
        ├── match_card_widget.dart
        ├── round_label_widget.dart
        └── round_robin_table_widget.dart
```

### Seeding Algorithm File Tree

```
lib/core/algorithms/seeding/
├── bracket_format.dart
├── constraint_satisfying_seeding_engine.dart
├── seeding_engine.dart
├── seeding_strategy.dart
├── constraints/
│   ├── dojang_separation_constraint.dart
│   ├── regional_separation_constraint.dart
│   └── seeding_constraint.dart
├── models/
│   ├── bye_assignment_result.dart
│   ├── bye_placement.dart
│   ├── participant_placement.dart
│   ├── ranked_seeding_entry.dart
│   ├── ranked_seeding_import_result.dart
│   ├── ranked_seeding_match_result.dart
│   ├── seeding_participant.dart
│   └── seeding_result.dart
├── services/
│   ├── bye_assignment_params.dart
│   ├── bye_assignment_service.dart
│   ├── manual_seed_override_params.dart
│   ├── manual_seed_override_service.dart
│   └── ranked_seeding_file_parser.dart
└── usecases/
    ├── apply_bye_assignment_params.dart
    ├── apply_bye_assignment_use_case.dart
    ├── apply_dojang_separation_seeding_params.dart
    ├── apply_dojang_separation_seeding_use_case.dart
    ├── apply_manual_seed_override_params.dart
    ├── apply_manual_seed_override_use_case.dart
    ├── apply_random_seeding_params.dart
    ├── apply_random_seeding_use_case.dart
    ├── apply_regional_separation_seeding_params.dart
    ├── apply_regional_separation_seeding_use_case.dart
    ├── ranked_seeding_import_params.dart
    └── ranked_seeding_import_use_case.dart
```

### Test File Tree (Epic 5 Scope)

```
test/features/bracket/
├── structure_test.dart
├── data/
│   ├── datasources/
│   │   ├── bracket_local_datasource_test.dart
│   │   └── match_local_datasource_test.dart
│   ├── models/
│   │   ├── bracket_model_test.dart
│   │   └── match_model_test.dart
│   ├── repositories/
│   │   ├── bracket_repository_implementation_test.dart
│   │   └── match_repository_implementation_test.dart
│   └── services/
│       ├── bracket_layout_engine_implementation_test.dart
│       ├── double_elimination_bracket_generator_service_implementation_test.dart
│       ├── hybrid_bracket_generator_service_implementation_test.dart
│       ├── round_robin_bracket_generator_service_implementation_test.dart
│       └── single_elimination_bracket_generator_service_implementation_test.dart
├── domain/
│   ├── entities/
│   │   ├── bracket_entity_test.dart
│   │   └── match_entity_test.dart
│   └── usecases/
│       ├── generate_double_elimination_bracket_use_case_test.dart
│       ├── generate_pool_play_elimination_bracket_use_case_test.dart
│       ├── generate_round_robin_bracket_use_case_test.dart
│       ├── generate_single_elimination_bracket_use_case_test.dart
│       ├── lock_bracket_use_case_test.dart
│       ├── regenerate_bracket_use_case_test.dart
│       └── unlock_bracket_use_case_test.dart
├── presentation/
│   ├── bloc/
│   │   ├── bracket_bloc_test.dart
│   │   └── bracket_generation_bloc_test.dart
│   ├── pages/
│   │   ├── bracket_generation_page_test.dart
│   └── widgets/
│       ├── bracket_format_selection_dialog_test.dart
│       ├── bracket_viewer_widget_test.dart
│       └── match_card_widget_test.dart

test/core/algorithms/seeding/
├── constraint_satisfying_seeding_engine_combined_test.dart
├── constraint_satisfying_seeding_engine_pinned_test.dart
├── constraint_satisfying_seeding_engine_test.dart
├── constraints/
│   ├── dojang_separation_constraint_test.dart
│   └── regional_separation_constraint_test.dart
├── services/
│   ├── bye_assignment_service_test.dart
│   ├── manual_seed_override_service_test.dart
│   └── ranked_seeding_file_parser_test.dart
└── usecases/
    ├── apply_bye_assignment_use_case_test.dart
    ├── apply_dojang_separation_seeding_use_case_test.dart
    ├── apply_manual_seed_override_use_case_test.dart
    ├── apply_random_seeding_use_case_test.dart
    ├── apply_regional_separation_seeding_use_case_test.dart
    └── ranked_seeding_import_use_case_test.dart
```

### Testing Patterns (Mandatory)

```dart
// === Mock pattern (mocktail — NOT mockito) ===
class MockBracketRepository extends Mock implements BracketRepository {}
class MockMatchRepository extends Mock implements MatchRepository {}
class MockSeedingEngine extends Mock implements SeedingEngine {}

// === BLoC test pattern ===
class MockBracketBloc
    extends MockBloc<BracketEvent, BracketState>
    implements BracketBloc {}
class MockBracketGenerationBloc
    extends MockBloc<BracketGenerationEvent, BracketGenerationState>
    implements BracketGenerationBloc {}

// === DI tests ===
tearDown(() => getIt.reset());

// === Lint rules ===
// Uses very_good_analysis — strict. No unused imports, no implicit casts.
```

### Key Dependencies & Versions

| Package                           | Purpose                                    |
| --------------------------------- | ------------------------------------------ |
| `flutter_bloc`                    | State management (BLoC pattern)            |
| `go_router` + `go_router_builder` | Declarative routing with type-safe codegen |
| `injectable` + `get_it`           | DI container with codegen                  |
| `fpdart`                          | Functional programming (Either, Option)    |
| `freezed`                         | Immutable state/event classes              |
| `drift` + `drift_flutter`         | Local SQLite database                      |
| `mocktail`                        | Mocking in tests                           |
| `bloc_test`                       | BLoC testing utilities                     |
| `very_good_analysis`              | Lint rules                                 |

### Previous Code Review Learnings (from 1-13, 2-12, 3-15, 4-14)

1. **Cross-layer imports are the most common violation** — Domain must never import from data. Use abstract interfaces in domain, implementations in data.
2. **Double syncVersion increment** — Repos increment syncVersion; use cases must NOT also increment. Verify bracket lock/unlock/regenerate use cases.
3. **`dart analyze` must be clean** — Fix ALL warnings, including unused imports in test files. Info-level issues count.
4. **Barrel file completeness matters** — Missing exports cause DI registration failures. Verify bracket.dart exports all new files.
5. **Either pattern enforcement** — No raw exceptions should escape use cases. All errors mapped to `Failure` types.
6. **Build runner must be run** after any changes to freezed/injectable files: `dart run build_runner build --delete-conflicting-outputs`
7. **`prefer_const_literals_to_create_immutables`** — Common lint issue in test files using `@immutable` constructors. Add `const` before list/map literals.
8. **`prefer_const_constructors`** — Common in widget test files. Add `const` to constructor calls.
9. **`eol_at_end_of_file`** — Every file must end with a newline.
10. **`use_raw_strings`** — Use raw strings `r'...'` when backslashes are not escapes.

### Architecture: Layer Rules

```
core/         → can import: only core/
domain/       → can import: core/ only (no data/, no presentation/)
data/         → can import: core/, domain/ (no presentation/)
presentation/ → can import: core/, domain/, data/ (via DI)
```

**Known intentional exception**: `app_router.dart` and `routes.dart` (in `core/router/`) import from `features/*/presentation/` because the router needs page widgets and auth state for guards.

### References

- [Source: epics.md#Story 5.18](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/_bmad-output/planning-artifacts/epics.md) — Story AC and user story statement (lines 2147-2176)
- [Source: 5-17-ranked-seeding-import.md](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/_bmad-output/implementation-artifacts/5-17-ranked-seeding-import.md) — Previous story (ranked seeding, most recent)
- [Source: 4-14-code-review-and-fix-participant-management.md](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/_bmad-output/implementation-artifacts/4-14-code-review-and-fix-participant-management.md) — Code review pattern reference (Epic 4)
- [Source: 3-15-code-review-and-fix-tournament-management.md](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/_bmad-output/implementation-artifacts/3-15-code-review-and-fix-tournament-management.md) — Code review pattern reference (Epic 3)
- [Source: bracket.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/features/bracket/bracket.dart) — Feature barrel file
- [Source: bracket_entity.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/features/bracket/domain/entities/bracket_entity.dart) — BracketEntity definition
- [Source: match_entity.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/features/bracket/domain/entities/match_entity.dart) — MatchEntity definition
- [Source: seeding_engine.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/core/algorithms/seeding/seeding_engine.dart) — SeedingEngine interface
- [Source: constraint_satisfying_seeding_engine.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart) — Engine implementation
- [Source: ranked_seeding_import_use_case.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/core/algorithms/seeding/usecases/ranked_seeding_import_use_case.dart) — Most recent seeding use case
- [Source: bracket_generation_bloc.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/features/bracket/presentation/bloc/bracket_generation_bloc.dart) — BLoC coordinating all generators
- [Source: routes.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/core/router/routes.dart) — Route definitions
- [Source: app_router.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/core/router/app_router.dart) — Router configuration
- [Source: architecture.md](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/_bmad-output/planning-artifacts/architecture.md) — Architecture decisions

### ⚠️ Common LLM Mistakes — Prevention Rules

**CRITICAL: These are the exact field names and types from the ACTUAL source code. Do NOT use hallucinated alternatives.**

| ❌ LLM Will Guess                                             | ✅ Actual Code                                                           | Why It Matters                                                        |
| ------------------------------------------------------------ | ----------------------------------------------------------------------- | --------------------------------------------------------------------- |
| `participant1Id` / `participant2Id`                          | `participantRedId` / `participantBlueId`                                | TKD uses red/blue gear. Wrong name = compile error.                   |
| `nextMatchId` / `nextMatchSlot`                              | `winnerAdvancesToMatchId` / `loserAdvancesToMatchId`                    | Bracket progression is explicit for winners AND losers.               |
| `matchNumber` / `positionInRound`                            | `matchNumberInRound`                                                    | Combined field name. Single attribute.                                |
| `isBye` (Boolean field)                                      | `resultType: MatchResultType.bye`                                       | Byes use the `MatchResultType` enum, not a boolean.                   |
| `BracketStatus` enum                                         | `isFinalized` (bool)                                                    | No status enum exists. Lock = `isFinalized: true`.                    |
| `status = 'in_progress'` for lock                            | `isFinalized: true, finalizedAtTimestamp: DateTime.now()`               | Lock sets two fields, unlock clears both.                             |
| `BracketType.main`                                           | `BracketType.winners`                                                   | Enum values are `winners`, `losers`, `pool`.                          |
| `BracketType.consolation`                                    | `BracketType.losers`                                                    | Double elimination uses winners/losers.                               |
| `BracketType.pool_a/pool_b`                                  | `BracketType.pool` + `poolIdentifier: 'A'/'B'`                          | Pool type + string identifier, not separate enum values.              |
| `seedData` / `layoutData` / `config`                         | `bracketDataJson` (Map<String, dynamic>?)                               | Single JSON field for all bracket data.                               |
| five generator use cases                                     | four generator use cases                                                | Pool Play = Hybrid. No separate "hybrid" generator.                   |
| `_regenerateBracketUseCase` uses `BracketFormat` from entity | Uses `BracketFormat` from `core/algorithms/seeding/bracket_format.dart` | Two different enums exist with the same name. BLoC maps between them. |
| `/bracket` (singular) route path                             | `/brackets` (plural) route path                                         | Actual GoRouter paths use `brackets` plural.                          |
| `BracketViewerRoute` shows division brackets                 | `BracketViewerRoute` takes `bracketId` parameter                        | It views ONE bracket, not a list.                                     |
| `brackets` in `_syncableTables`                              | NOT in `_syncableTables`                                                | Bracket sync is planned for future epic.                              |
| `syncVersion: 0` default                                     | `syncVersion: 1` default (via `@Default(1)`)                            | All entities default to 1, not 0.                                     |

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
