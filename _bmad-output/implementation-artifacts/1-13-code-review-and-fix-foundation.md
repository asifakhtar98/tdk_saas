# Story 1.13: Code Review & Fix — Foundation & Demo Mode

Status: in-progress

## Story

As a tech lead,
I want a thorough code review and fix of all Epic 1 implementation,
so that the foundation layer is clean, correct, and production-ready before launch.

## Acceptance Criteria

1. `dart analyze .` (from `tkd_brackets/`) reports **zero** warnings or errors
2. All files follow Clean Architecture layer rules — no cross-layer imports
3. DI container registers all Epic 1 services; all resolvable at runtime
4. Router has no dead routes; all auth guards function correctly
5. `SyncService`, `AutosaveService`, `ConnectivityService` have ≥ 80% unit test coverage
6. Demo mode seeding creates exact expected records, all with `is_demo_data = true`
7. Drift migrations run without errors on a clean database (v1→v7)
8. Sentry: disabled in dev builds (empty DSN), enabled in prod
9. All identified issues fixed and verified
10. Final `dart analyze` clean after all fixes

---

## Tasks / Subtasks

### Task 1: Fix Analysis Warning (AC: #1, #10)

**The single known warning — fix it first so all subsequent `dart analyze` runs are clean.**

- [ ] Edit `test/features/bracket/data/services/bracket_layout_engine_implementation_test.dart`
  - **Line 2**: `import 'dart:ui' show Offset, Size;`
  - **Fix**: Remove `Offset` from the `show` clause → `import 'dart:ui' show Size;`
  - `Offset` is imported but never used in this test file. `Size` IS used (line 68: `Size.zero`, line 279: `Size.zero`).
  - **Do NOT** remove `Size` — only `Offset`.
- [ ] Run `dart analyze .` from `tkd_brackets/` — must report **zero** issues.

### Task 2: Fix Stale Comment in AutosaveService (AC: #9)

**Stale comment references "future Story 1.10" but Story 1.10 is already implemented.**

- [ ] Edit `lib/core/sync/autosave_service.dart`
  - **Lines 172-173** currently read:
    ```dart
    // Queue for sync (implementation in future Story 1.10)
    // For now, just log that we would sync
    ```
  - **Replace with**:
    ```dart
    // SyncService (Story 1.10) handles cloud sync separately.
    // Log breadcrumb for autosave audit trail.
    ```
  - This is a comment-only change. No logic change.

### Task 3: Fix SyncService Exhausted Retry Bug (AC: #9)

**Bug: When `_shouldRetry` returns `false`, the sync queue item is silently skipped — it stays in the queue forever.**

- [ ] Edit `lib/core/sync/sync_service.dart` — in the `push()` method, around **lines 248-254**
  - Current code:
    ```dart
    for (final item in items) {
      if (_shouldRetry(item.attemptCount)) {
        await _syncQueue.markFailed(item.id, e.toString());
        failedCount++;
      }
    }
    ```
  - **Fix**: Add an `else` branch to mark exhausted items as permanently failed:
    ```dart
    for (final item in items) {
      if (_shouldRetry(item.attemptCount)) {
        await _syncQueue.markFailed(item.id, e.toString());
        failedCount++;
      } else {
        // Exhausted all retry attempts — mark as permanently failed
        // so it doesn't stay in the queue indefinitely.
        await _syncQueue.markFailed(
          item.id,
          'Exhausted $_maxRetryAttempts retry attempts: $e',
        );
        failedCount++;
        _errorReportingService.reportError(
          'Sync item ${item.id} exhausted retries for ${item.tableName}',
          error: e,
        );
      }
    }
    ```
  - **Why**: Without this, items that exceed `_maxRetryAttempts` (5) remain in the queue, are re-fetched on every `push()`, and silently dropped each time. This creates an invisible data-loss scenario.
  - **Verify**: `_shouldRetry` method (should be `attemptCount < _maxRetryAttempts`). Confirm the logic is `<` not `<=`. If `<=`, the threshold is `_maxRetryAttempts + 1`.

### Task 4: Architecture Layer Audit (AC: #2)

**Scan for cross-layer import violations using grep.**

- [ ] Run these checks from `tkd_brackets/`:
  ```bash
  # Core should NOT import from features
  grep -r "import.*features/" lib/core/ --include="*.dart" | grep -v ".g.dart"
  
  # Domain should NOT import from data or presentation
  grep -r "import.*data/" lib/features/*/domain/ --include="*.dart" | grep -v ".g.dart"
  grep -r "import.*presentation/" lib/features/*/domain/ --include="*.dart" | grep -v ".g.dart"
  
  # Data should NOT import from presentation
  grep -r "import.*presentation/" lib/features/*/data/ --include="*.dart" | grep -v ".g.dart"
  ```
- [ ] **Expected**: All commands return empty (no violations).
- [ ] **Known exception**: `app_router.dart` imports from `features/auth/presentation/bloc/` — this is intentional (router needs auth state for guards). **Do NOT flag this.**
- [ ] If violations found, fix them. If none, mark as verified.

### Task 5: DI Container Verification (AC: #3)

**Verify all Epic 1 services are in the generated DI config.**

- [ ] Open `lib/core/di/injection.config.dart` and confirm ALL of these are registered:

  | Service                                                     | Registration         | Annotation                        |
  | ----------------------------------------------------------- | -------------------- | --------------------------------- |
  | `AppDatabase`                                               | singleton            | `@lazySingleton`                  |
  | `ConnectivityServiceImplementation` → `ConnectivityService` | lazy singleton       | `@LazySingleton(as:)`             |
  | `AutosaveServiceImplementation` → `AutosaveService`         | lazy singleton       | `@LazySingleton(as:)`             |
  | `SyncServiceImplementation` → `SyncService`                 | lazy singleton       | `@LazySingleton(as:)`             |
  | `SyncQueueImplementation` → `SyncQueue`                     | lazy singleton       | `@LazySingleton(as:)`             |
  | `SyncNotificationService`                                   | lazy singleton       | `@lazySingleton`                  |
  | `DemoDataServiceImpl` → `DemoDataService`                   | lazy singleton       | `@LazySingleton(as:)`             |
  | `ErrorReportingService`                                     | lazy singleton       | `@lazySingleton`                  |
  | `LoggerService`                                             | lazy singleton       | `@lazySingleton`                  |
  | `AppRouter`                                                 | lazy singleton       | `@lazySingleton`                  |
  | `AuthenticationBloc`                                        | factory or singleton | `@injectable` or `@lazySingleton` |
  | `SupabaseClient`                                            | lazy singleton       | via `register_module.dart`        |
  | `Connectivity`                                              | lazy singleton       | via `register_module.dart`        |
  | `InternetConnection`                                        | lazy singleton       | via `register_module.dart`        |
  | `Uuid`                                                      | lazy singleton       | via `register_module.dart`        |

- [ ] Run: `flutter test test/core/di/injection_test.dart` — must pass.
- [ ] If any service missing, run `dart run build_runner build --delete-conflicting-outputs` to regenerate, then verify.

### Task 6: Router Audit (AC: #4)

**Verify all routes in `app_router.dart` resolve to real widgets — no placeholders.**

- [ ] Cross-reference routes in `app_router.dart` (lines 63-79) with `routes.dart`:

  | Route Variable              | Path                                          | Widget                  | Status        |
  | --------------------------- | --------------------------------------------- | ----------------------- | ------------- |
  | `$homeRoute`                | `/`                                           | `HomePage`              | ✅ real widget |
  | `$demoRoute`                | `/demo`                                       | `DemoPage`              | ✅ real widget |
  | `$dashboardRoute`           | `/dashboard`                                  | `DashboardPage`         | ✅ real widget |
  | `$tournamentListRoute`      | `/tournaments`                                | `TournamentListPage`    | ✅ real widget |
  | `$tournamentDetailsRoute`   | `/tournaments/:tournamentId`                  | `TournamentDetailPage`  | ✅ real widget |
  | `$tournamentDivisionsRoute` | `/tournaments/:id/divisions`                  | `DivisionBuilderWizard` | ✅ real widget |
  | `$participantListRoute`     | `/tournaments/:id/divisions/:id/participants` | `ParticipantListPage`   | ✅ real widget |
  | `$csvImportRoute`           | `…/participants/import`                       | `CSVImportPage`         | ✅ real widget |
  | `$settingsRoute`            | `/settings`                                   | `SettingsPage`          | ✅ real widget |

- [ ] Verify redirect guard logic in `_redirectGuard()` (lines 92-138):
  - `publicRoutes = ['/', '/demo']` — unauthenticated users can access
  - `demoAccessiblePrefixes = ['/tournaments']` — demo users can browse tournaments
  - Authenticated users on `/` → redirected to `/dashboard`
  - Unauthenticated users on protected routes → redirected to `/`
  - During `AuthenticationCheckInProgress` or `AuthenticationInitial` → no redirect (prevents flash)
- [ ] Run: `flutter test test/core/router/` — all must pass.

### Task 7: Core Services Coverage ≥ 80% (AC: #5)

**Run targeted coverage and verify thresholds.**

- [ ] Run: `flutter test --coverage test/core/sync/ test/core/network/`
- [ ] Generate report: `genhtml coverage/lcov.info -o coverage/html` (or use `lcov --summary`)
- [ ] Check coverage for:
  - `lib/core/sync/sync_service.dart` → ≥ 80%
  - `lib/core/sync/autosave_service.dart` → ≥ 80%
  - `lib/core/network/connectivity_service.dart` → ≥ 80%

- [ ] **If below 80%**, add tests for these specific uncovered branches:

  **`sync_service.dart` uncovered areas to target:**
  - `_applyRemoteOrganization` — the `else` branch where existing org is updated (vs inserted)
  - `_applyRemoteUser` — the `else` branch where existing user is updated (vs inserted)
  - `push()` when `_shouldRetry` returns `false` (the new else-branch from Task 3)
  - `_calculateBackoff` edge case: `attemptCount >= _maxRetryAttempts`

  **`autosave_service.dart` uncovered areas to target:**
  - `didChangeAppLifecycleState(AppLifecycleState.paused)` → should trigger `saveNow()`
  - `didChangeAppLifecycleState(AppLifecycleState.inactive)` → should trigger `saveNow()`
  - `saveNow()` when `hasDirtyEntities` is `false` (should return early)
  - `saveNow()` when already `_isSaving = true` (should return early)
  - `_saveToLocalDatabase()` is an intentional stub — it just logs a breadcrumb. **Do NOT add entity persistence logic.** Just test that the breadcrumb is added.

  **`connectivity_service.dart` uncovered areas to target:**
  - `_handleConnectivityChange` when `results.isEmpty` → should set offline
  - `_handleConnectivityChange` when `results.contains(ConnectivityResult.none)` → should set offline
  - `_performInitialCheck` when `hasInternetConnection()` throws → should set offline (the `on Object` catch block)

  **Test patterns to use:**
  ```dart
  // Database test pattern:
  AppDatabase.forTesting(NativeDatabase.memory())
  
  // Mock pattern (uses mocktail):
  class MockConnectivityService extends Mock implements ConnectivityService {}
  class MockSyncQueue extends Mock implements SyncQueue {}
  
  // Verify stream emissions:
  expectLater(service.statusStream, emitsInOrder([...]));
  ```

### Task 8: Demo Data Verification (AC: #6)

- [ ] Run: `flutter test test/core/demo/`
- [ ] Verify `demo_data_service_test.dart` asserts:
  - After `seedDemoData()`: 1 organization, 1 user, 1 tournament, 1 division, 8 participants
  - All records have `isDemoData == true`
  - `hasDemoData()` returns `true` after seeding
  - `shouldSeedDemoData()` returns `false` after seeding (because organizations now exist)
- [ ] Verify `demo_data_constants_test.dart` asserts:
  - `DemoDataConstants.demoParticipantIds.length == 8`
  - `DemoDataConstants.sampleDojangs.length == 4`
- [ ] Check `demo_data_service.dart` line 161: participant `checkInStatus` is hardcoded to `'pending'`. This is acceptable for demo data — no fix needed, but verify the string matches the domain enum if one exists.
- [ ] If any assertion listed above is missing from the tests, **add it**.

### Task 9: Drift Migration Verification (AC: #7)

- [ ] Verify migration ladder in `lib/core/database/app_database.dart` (lines 48-86):

  | From  | To  | Tables Added                                 |
  | ----- | --- | -------------------------------------------- |
  | fresh | v1  | `organizations`, `users` (via `createAll()`) |
  | v1    | v2  | `syncQueueTable`                             |
  | v2    | v3  | `tournaments`, `divisions`, `participants`   |
  | v3    | v4  | `invitations`                                |
  | v4    | v5  | `divisionTemplates`                          |
  | v5    | v6  | `brackets`                                   |
  | v6    | v7  | `matches`                                    |

- [ ] Verify `schemaVersion` getter returns `7` (line 45).
- [ ] Verify `beforeOpen` enables foreign keys: `PRAGMA foreign_keys = ON` (line 83).
- [ ] Run: `flutter test test/core/database/app_database_test.dart` — must pass.
- [ ] If no test exists that verifies fresh DB creation with all 10 tables, add one:
  ```dart
  test('fresh database should have all 10 tables', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    // Verify schema version
    expect(db.schemaVersion, 7);
    // Verify all table getters exist (compile-time check)
    expect(db.organizations, isNotNull);
    expect(db.users, isNotNull);
    expect(db.syncQueueTable, isNotNull);
    expect(db.tournaments, isNotNull);
    expect(db.divisions, isNotNull);
    expect(db.participants, isNotNull);
    expect(db.invitations, isNotNull);
    expect(db.divisionTemplates, isNotNull);
    expect(db.brackets, isNotNull);
    expect(db.matches, isNotNull);
    await db.close();
  });
  ```

### Task 10: Sentry Environment Verification (AC: #8)

- [ ] Verify entry points:
  - `lib/main_development.dart` line 10: `sentryDsn: ''` → empty string, Sentry disabled ✅
  - `lib/main_production.dart` line 9: `sentryDsn: Env.sentryDsn ?? ''` → reads env var ✅
  - `lib/main_staging.dart`: confirm similar pattern
- [ ] Verify `SentryService.initialize()` behavior:
  - When `dsn.isEmpty` → `_enabled = false`, skips `SentryFlutter.init()`, calls `appRunner()` directly
  - When `dsn` has value → `_enabled = true`, initializes `SentryFlutter`
- [ ] Run: `flutter test test/core/monitoring/sentry_service_test.dart`
- [ ] If test "initialize with empty DSN sets isEnabled = false" is missing, add it:
  ```dart
  test('initialize with empty DSN disables Sentry', () async {
    await SentryService.initialize(
      dsn: '',
      environment: 'test',
      appRunner: () async {},
    );
    expect(SentryService.isEnabled, isFalse);
    expect(SentryService.isInitialized, isTrue);
  });
  ```

### Task 11: Final Verification (AC: #1, #9, #10)

- [ ] Run: `dart analyze .` from `tkd_brackets/` — expect **zero** issues
- [ ] Run: `flutter test` from `tkd_brackets/` — expect **all 1540+ tests pass** (count may increase if new tests added)
- [ ] Confirm no regressions from Task 3 fix (the retry exhaustion `else` branch)
- [ ] Update this story status from `ready-for-dev` to `done`

---

## Dev Notes

### ⚠️ CRITICAL: Do Not Touch These

1. **`_saveToLocalDatabase()` in `autosave_service.dart`** (lines 213-241) — This is an **intentional stub**. It only logs a breadcrumb. Real entity persistence is added in later epics as features are implemented. **Do NOT add save logic here.**
2. **`_syncableTables = ['organizations', 'users']`** in `sync_service.dart` (line 114) — Intentionally limited to Epic 1 scope. Later epics extend this list. **Do NOT add more tables.**
3. **Bootstrap initialization order** in `bootstrap.dart`:
   ```
   SupabaseConfig.initialize()  →  SentryService.initialize()  →  [inside appRunner]:
     configureDependencies()  →  Bloc.observer  →  DemoDataService.seedDemoData()  →  runApp()
   ```
   This order is critical. DI must be inside `appRunner` so Sentry wraps the entire app. Supabase must be before DI so `SupabaseClient` is injectable.
4. **`@LazySingleton` annotations** — All services use lazy init for web startup performance. Do NOT change to `@singleton` (eager).

### Architecture: Layer Rules

```
core/         → can import: only core/
domain/       → can import: core/ only (no data/, no presentation/)
data/         → can import: core/, domain/ (no presentation/)
presentation/ → can import: core/, domain/, data/ (via DI)
```

**Known intentional exception**: `app_router.dart` (in `core/router/`) imports `features/auth/presentation/bloc/` because the router guard needs auth state. This is an accepted architecture decision.

### Architecture: File Tree (Epic 1 Scope)

```
lib/
├── app/app.dart                          # MaterialApp.router
├── bootstrap.dart                        # Init sequence (see above)
├── main_development.dart                 # sentryDsn: '' (disabled)
├── main_production.dart                  # sentryDsn: Env.sentryDsn ?? ''
├── main_staging.dart                     # sentryDsn: Env.sentryDsn ?? ''
└── core/
    ├── config/
    │   ├── env.dart                      # @Envied — reads .env
    │   └── supabase_config.dart          # SupabaseConfig (Completer pattern, resetForTesting)
    ├── database/
    │   ├── app_database.dart             # AppDatabase: schemaVersion=7, 10 tables, migration ladder
    │   ├── app_database.g.dart           # Generated by Drift
    │   └── tables/                       # organizations, users, sync_queue, tournaments, divisions,
    │                                     # participants, invitations, division_templates, brackets, matches
    ├── demo/
    │   ├── demo_data_constants.dart      # Fixed UUIDs, names, 8 participant IDs, 4 dojangs
    │   └── demo_data_service.dart        # Seeds: 1 org → 1 user → 1 tournament → 1 division → 8 participants
    ├── di/
    │   ├── injection.dart                # configureDependencies(environment)
    │   ├── injection.config.dart         # Generated by injectable
    │   └── register_module.dart          # Manual: SupabaseClient, Connectivity, InternetConnection, Uuid
    ├── error/
    │   ├── exceptions.dart               # ServerException, CacheException, AuthException
    │   ├── failures.dart                 # Failure hierarchy: Server, Local, Auth, Validation, Sync, etc.
    │   └── error_reporting_service.dart  # Unified: reportFailure, reportException, addBreadcrumb → Sentry + Logger
    ├── monitoring/
    │   ├── sentry_service.dart           # Static class: initialize(dsn, env, appRunner), resetForTesting
    │   └── bloc_observer.dart            # AppBlocObserver (logs bloc events)
    ├── network/
    │   ├── connectivity_service.dart     # Connectivity + InternetConnectionChecker, stream + point-in-time
    │   └── connectivity_status.dart      # enum {online, offline}
    ├── router/
    │   ├── app_router.dart               # GoRouter with auth guards, SentryNavigatorObserver
    │   ├── routes.dart                   # @TypedGoRoute for 9 routes, go_router_builder codegen
    │   ├── routes.g.dart                 # Generated route constructors
    │   ├── shell_routes.dart             # AppShellScaffold: responsive NavigationBar/NavigationRail
    │   └── navigation_items.dart         # NavItem list
    ├── services/
    │   └── logger_service.dart           # LoggerService (@lazySingleton)
    ├── sync/
    │   ├── sync_service.dart             # LWW push/pull, batch ops, exponential backoff, _syncableTables
    │   ├── autosave_service.dart         # 5s timer, WidgetsBindingObserver, markDirty/clearDirty/saveNow
    │   ├── autosave_status.dart          # enum {idle, saving, saved, error}
    │   ├── sync_queue.dart               # Persistent queue via Drift sync_queue_table
    │   ├── sync_notification_service.dart # Conflict resolution notifications
    │   └── sync_status.dart              # enum SyncStatus, class SyncError
    ├── theme/app_theme.dart              # Material 3, Navy/Gold palette
    ├── usecases/use_case.dart            # UseCase<Type, Params> base class
    └── widgets/
        └── sync_status_indicator_widget.dart  # StreamBuilder on SyncService.statusStream
```

### Testing Patterns (Mandatory)

```dart
// === Database tests ===
final db = AppDatabase.forTesting(NativeDatabase.memory());
// Always close: addTearDown(() => db.close());

// === Sentry tests ===
setUp(() => SentryService.resetForTesting());
tearDown(() => SentryService.resetForTesting());

// === Supabase tests ===
setUp(() => SupabaseConfig.resetForTesting());
tearDown(() => SupabaseConfig.resetForTesting());

// === DI tests ===
tearDown(() => getIt.reset());

// === Mock pattern (mocktail) ===
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockSyncQueue extends Mock implements SyncQueue {}
class MockAppDatabase extends Mock implements AppDatabase {}
class MockErrorReportingService extends Mock implements ErrorReportingService {}

// === Stream assertion ===
expectLater(service.statusStream, emitsInOrder([SyncStatus.syncing, SyncStatus.synced]));

// === Lint rules ===
// Uses very_good_analysis — strict. No unused imports, no implicit casts.
```

### Key Dependencies & Versions

| Package                            | Purpose                                        |
| ---------------------------------- | ---------------------------------------------- |
| `drift` + `drift_flutter`          | Local SQLite via sqlite3.wasm (web-compatible) |
| `supabase_flutter`                 | Supabase client (auth, realtime, storage)      |
| `flutter_bloc`                     | State management (BLoC pattern)                |
| `go_router` + `go_router_builder`  | Declarative routing with type-safe codegen     |
| `injectable` + `get_it`            | DI container with codegen                      |
| `sentry_flutter`                   | Error tracking (disabled when DSN empty)       |
| `connectivity_plus`                | Network interface monitoring                   |
| `internet_connection_checker_plus` | Actual internet reachability check             |
| `fpdart`                           | Functional programming (Either, Option)        |
| `equatable`                        | Value equality for Failure classes             |
| `mocktail`                         | Mocking in tests                               |
| `very_good_analysis`               | Lint rules                                     |

### References

- [architecture.md](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/_bmad-output/planning-artifacts/architecture.md)
- [epics.md — Epic 1](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/_bmad-output/planning-artifacts/epics.md)
- [1-12-foundation-ui-shell.md](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/_bmad-output/implementation-artifacts/1-12-foundation-ui-shell.md)
- [sync_service.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/core/sync/sync_service.dart)
- [autosave_service.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/core/sync/autosave_service.dart)
- [app_database.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/core/database/app_database.dart)
- [bootstrap.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/bootstrap.dart)
- [sentry_service.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/core/monitoring/sentry_service.dart)
- [app_router.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/core/router/app_router.dart)

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List

*Files modified/created during implementation will be listed here by the dev agent.*
