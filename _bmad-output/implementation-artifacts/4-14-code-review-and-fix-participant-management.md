# Story 4.14: Code Review & Fix — Participant Management

Status: done

**Created:** 2026-03-05

**Epic:** 4 — Participant Management

**FRs Covered:** FR13-FR19 (Manual entry, CSV import, Paste from spreadsheet, Auto-assign, Move participant, No-show, DQ)

**Dependencies:** All Epic 4 stories (4.1–4.13) are `done`

---

## Story

As a tech lead,
I want a thorough code review and fix of all Epic 4 implementation,
so that participant management is correct, performant, and production-ready.

## Acceptance Criteria

1. `dart analyze .` (from `tkd_brackets/`) reports **zero** warnings or errors
2. All participant feature files follow Clean Architecture layer rules — no cross-layer imports (domain must NOT import from data or presentation)
3. DI container registers all Epic 4 services; all resolvable at runtime
4. All participant routes resolve to real widgets; navigation works end-to-end
5. Manual participant entry validates all required fields (firstName, lastName, schoolOrDojangName, beltRank) before saving
6. CSV import handles all supported date formats and belt normalizations without crashing
7. Duplicate detection correctly identifies exact and fuzzy matches (Levenshtein ≤ 2)
8. Bulk import shows correct row-level validation (green/yellow/red) before commit
9. Paste from spreadsheet (Story 4.13) correctly parses tab-delimited clipboard data and feeds through the existing CSV pipeline
10. Auto-assignment correctly matches all criteria (age, belt, weight, gender)
11. Participant transfer is blocked if source or target division status is `inProgress` or `completed` (checks `DivisionStatus`, not bracket status)
12. No-show and DQ status changes correctly set participant status and `dqReason`
13. Participant Management UI (Story 4.12) renders correctly — no overflow, dead-end navigation, or console errors
14. All participant search filters (name, dojang, belt) apply correctly
15. All identified issues are fixed and verified
16. Final `dart analyze` clean after all fixes
17. `flutter test` passes — all existing tests pass (count may increase if new tests added)

---

## Tasks / Subtasks

### Task 1: Static Analysis Baseline (AC: #1, #16)

- [x] Run `dart analyze .` from `tkd_brackets/`
- [x] Fix any warnings or errors found
- [x] Re-run `dart analyze .` — must report **zero** issues

### Task 2: Architecture Layer Audit — Participant Feature (AC: #2)

**Scan for cross-layer import violations in the participant feature.**

- [x] Run these checks from `tkd_brackets/`:
  ```bash
  # Domain should NOT import from data or presentation
  grep -rn "import.*data/" lib/features/participant/domain/ --include="*.dart" | grep -v ".g.dart" | grep -v ".freezed.dart"
  grep -rn "import.*presentation/" lib/features/participant/domain/ --include="*.dart" | grep -v ".g.dart" | grep -v ".freezed.dart"

  # Data should NOT import from presentation
  grep -rn "import.*presentation/" lib/features/participant/data/ --include="*.dart" | grep -v ".g.dart" | grep -v ".freezed.dart"
  ```
- [x] **Expected**: All commands return empty (no violations).
- [x] **⚠️ KNOWN VIOLATION — FIXED**: `DuplicateDetectionService` now uses `ParticipantRepository.getParticipantsForTournament()` — no data-layer imports remain.
- [x] **Known to check**: `BulkImportUseCase` (domain layer) — verified, does NOT import presentation types.
- [x] **Known to check**: `CSVParserService` and `ClipboardInputService` (domain services) — verified, only import from `core/` or `domain/`.
- [x] **Known to check**: `AutoAssignmentService` imports `division/domain/entities/belt_rank.dart` — cross-feature domain import, acceptable.

### Task 3: DI Container Verification — Epic 4 Services (AC: #3)

**Verify all Epic 4 services are registered in the generated DI config.**

- [x] Open `lib/core/di/injection.config.dart` and confirm ALL of these are registered:

  | Service                                                         | Registration   | Annotation            |
  | --------------------------------------------------------------- | -------------- | --------------------- |
  | `ParticipantRepositoryImplementation` → `ParticipantRepository` | lazy singleton | `@LazySingleton(as:)` |
  | `ParticipantLocalDatasource`                                    | lazy singleton | `@lazySingleton`      |
  | `ParticipantRemoteDatasource`                                   | lazy singleton | `@lazySingleton`      |
  | `CSVParserService`                                              | lazy singleton | `@lazySingleton`      |
  | `ClipboardInputService`                                         | lazy singleton | `@lazySingleton`      |
  | `DuplicateDetectionService`                                     | lazy singleton | `@lazySingleton`      |
  | `AutoAssignmentService`                                         | factory        | `@injectable`         |
  | `BulkImportUseCase`                                             | factory        | `@injectable`         |
  | `CreateParticipantUseCase`                                      | factory        | `@injectable`         |
  | `UpdateParticipantUseCase`                                      | factory        | `@injectable`         |
  | `DeleteParticipantUseCase`                                      | factory        | `@injectable`         |
  | `TransferParticipantUseCase`                                    | factory        | `@injectable`         |
  | `MarkNoShowUseCase`                                             | factory        | `@injectable`         |
  | `DisqualifyParticipantUseCase`                                  | factory        | `@injectable`         |
  | `AssignToDivisionUseCase`                                       | factory        | `@injectable`         |
  | `AutoAssignParticipantsUseCase`                                 | factory        | `@injectable`         |
  | `GetDivisionParticipantsUseCase`                                | factory        | `@injectable`         |
  | `UpdateParticipantStatusUseCase`                                | factory        | `@injectable`         |
  | `UpdateSeedPositionsUseCase`                                    | factory        | `@injectable`         |
  | `ParticipantListBloc`                                           | factory        | `@injectable`         |
  | `CSVImportBloc`                                                 | factory        | `@injectable`         |

- [x] Run: `flutter test test/core/di/injection_test.dart` — must pass.
- [x] If any service missing, run `dart run build_runner build --delete-conflicting-outputs` to regenerate.

### Task 4: Router & Navigation Audit (AC: #4)

**Verify participant routes resolve correctly and navigation flows work.**

- [x] Cross-reference participant routes in `app_router.dart` and `routes.dart`:

  | Route            | Path                                                                   | Widget                | Auth Required     |
  | ---------------- | ---------------------------------------------------------------------- | --------------------- | ----------------- |
  | Participant List | `/tournaments/:tournamentId/divisions/:divisionId/participants`        | `ParticipantListPage` | Yes (shell route) |
  | CSV Import       | `/tournaments/:tournamentId/divisions/:divisionId/participants/import` | `CSVImportPage`       | Yes               |

- [x] Verify navigation flow: Tournament Detail → Division → Participant List → CSV Import → back to Participant List
- [x] Verify `demoAccessiblePrefixes` in `app_router.dart` includes `/tournaments` for demo mode access to participant routes
- [x] Run: `flutter test test/core/router/` — all must pass

### Task 5: ParticipantEntity & Model Correctness (AC: #5)

**Verify entity and model match schema and behave correctly.**

- [x] **ParticipantEntity** at `lib/features/participant/domain/entities/participant_entity.dart`:
  - **Required fields**: `id` (String), `divisionId` (String), `firstName` (String), `lastName` (String), `createdAtTimestamp` (DateTime), `updatedAtTimestamp` (DateTime)
  - **Optional fields**: `dateOfBirth` (DateTime?), `gender` (Gender?), `weightKg` (double?), `schoolOrDojangName` (String?), `beltRank` (String?), `seedNumber` (int?), `registrationNumber` (String?), `checkInAtTimestamp` (DateTime?), `dqReason` (String?), `photoUrl` (String?), `notes` (String?)
  - **Default fields**: `isBye` (@Default(false) bool), `checkInStatus` (@Default(ParticipantStatus.pending)), `syncVersion` (@Default(1) int), `isDeleted` (@Default(false) bool), `isDemoData` (@Default(false) bool)
  - **⚠️ `syncVersion` defaults to 1** (same as DivisionEntity, different from TournamentEntity which defaults to 0) — this is intentional
  - **Computed `age` getter**: Verify it correctly handles null dateOfBirth → returns null; non-null → calculates age correctly considering month/day
  - **Field name**: Entity uses `schoolOrDojangName` — NOT `dojangName` or `school`
  - **Field name**: Entity uses `weightKg` — NOT `weight` or `weightInKg`
  - **Field name**: Entity uses `beltRank` — NOT `belt` or `rank`
  - Freezed generation must be up to date

- [x] **ParticipantModel** at `lib/features/participant/data/models/participant_model.dart`:
  - `toEntity()` / `convertToEntity()` correctly maps ALL fields
  - `fromEntity()` / `convertFromEntity()` correctly maps ALL fields
  - `fromSupabaseJson()` handles Supabase column names (snake_case)
  - Verify `checkInStatus` enum conversion round-trips correctly
  - Verify `gender` enum conversion round-trips correctly
  - Verify nullable `DateTime?` fields handle null from DB correctly

- [x] Run:
  ```bash
  flutter test test/features/participant/domain/entities/participant_entity_test.dart
  flutter test test/features/participant/data/models/participant_model_test.dart
  ```

### Task 6: CreateParticipantUseCase Audit (AC: #5)

**Verify manual participant entry validates all required fields.**

- [x] **CreateParticipantUseCase** at `domain/usecases/create_participant_usecase.dart`:
  - **Constructor**: `CreateParticipantUseCase(ParticipantRepository, DivisionRepository, TournamentRepository, UserRepository)` — 4 dependencies
  - **Static consts**: `_uuid = Uuid()`, `minAge = 4`, `maxAge = 80`, `maxWeightKg = 150`
  - **Validation (`_validateInputs`)**: Returns `Map<String, String>` field errors:
    - `firstName` required (trimmed, not empty)
    - `lastName` required (trimmed, not empty)
    - `schoolOrDojangName` required (trimmed, not empty)
    - `beltRank` required AND validated via `_isValidBeltRank()` — accepts: white, yellow, orange, green, blue, red, black, black+Nth+dan patterns
    - `weightKg` optional but if provided: must not be negative, must not exceed `maxWeightKg` (150)
    - `dateOfBirth` optional but if provided: must not be future, age must be `minAge`–`maxAge` (4-80)
  - **Auth check**: Gets current user from `UserRepository.getCurrentUser()` → if null or empty orgId → `AuthorizationPermissionDeniedFailure`
  - **Division lookup**: Verifies division exists via `DivisionRepository.getDivisionById()`
  - **Tournament org check**: Verifies tournament's orgId matches user's orgId
  - **Entity creation**: Sets `syncVersion: 1`, `seedNumber: null`, `isBye: false`, `checkInStatus: pending`
  - Returns `Either<Failure, ParticipantEntity>` via `_participantRepository.createParticipant()`
  - No raw exceptions escape — all caught and mapped to `Failure`

- [x] Run:
  ```bash
  flutter test test/features/participant/domain/usecases/create_participant_usecase_test.dart
  ```

### Task 7: CSVParserService Audit (AC: #6)

**Verify CSV parsing handles all supported formats correctly.**

- [x] **CSVParserService** at `domain/services/csv_parser_service.dart`:
  - **Annotation**: `@lazySingleton`
  - **Static consts** (mirrored from CreateParticipantUseCase): `minAge = 4`, `maxAge = 80`, `maxWeightKg = 150`
  - **Column aliases** (52 entries in `_columnAliases` map):
    - `firstName`: `firstname`, `first_name`, `first name`
    - `lastName`: `lastname`, `last_name`, `last name`
    - `dateOfBirth`: `dob`, `dateofbirth`, `date_of_birth`, `birthday`, `date of birth`
    - `gender`: `gender`, `sex`
    - `schoolOrDojangName`: `dojang`, `school`, `schoolordojangname`, `school name`, `dojang name`
    - `beltRank`: `belt`, `beltrank`, `rank`, `belt rank`
    - `weightKg`: `weight`, `weightkg`, `weight_kg`, `weight kg`
    - `registrationNumber`: `regnumber`, `registrationnumber`, `registration number`
    - `notes`: `notes`
  - **Required columns**: `firstName`, `lastName`, `schoolOrDojangName`, `beltRank` — missing any returns `Left(ValidationFailure)`
  - **Date parsing** (`_parseDate`): ISO `YYYY-MM-DD`, US `MM/DD/YYYY`, EU `DD-MM-YYYY` — validated for valid month/day ranges
  - **Belt rank parsing** (`_tryParseBeltRank`): Normalizes to `BeltRank` enum via `BeltRank.fromString()`. Accepts base belts + black Nth dan patterns.
  - **Gender parsing** (`_tryParseGender`): `m`/`male` → `Gender.male`, `f`/`female` → `Gender.female`
  - **Per-row error collection**: Single bad row produces `CSVRowError` entries but does NOT fail entire import
  - **`_parseCSVLine`**: Splits on comma ONLY (handles RFC 4180 quoted fields with escaped double-quotes)
  - **`_mapColumnName`**: `header.toLowerCase().trim()` → lookup in `_columnAliases`
  - **Row data**: Valid rows stored as `CSVRowData` with belt stored as `beltRank.name` (BeltRank enum name)

- [x] Run:
  ```bash
  flutter test test/features/participant/domain/services/csv_parser_service_test.dart
  ```

### Task 8: ClipboardInputService Audit (AC: #9)

**Verify clipboard paste from spreadsheet works correctly.**

- [x] **ClipboardInputService** at `domain/services/clipboard_input_service.dart`:
  - `normalizeToCSV(String rawInput)` — synchronous method
  - Detection: If first non-empty line contains tab → entire input treated as tab-delimited
  - Tab-to-CSV conversion with RFC 4180 quoting (commas/quotes in cells)
  - Empty/whitespace input → returns input unchanged
  - Mixed line endings (`\r\n`, `\n`) → normalized to `\n`

- [x] Run:
  ```bash
  flutter test test/features/participant/domain/services/clipboard_input_service_test.dart
  ```

### Task 9: DuplicateDetectionService Audit (AC: #7)

**Verify duplicate detection correctly handles all match types.**

- [x] **DuplicateDetectionService** at `domain/services/duplicate_detection_service.dart`:
  - **Constructor**: `DuplicateDetectionService(DivisionRepository)` — uses division repo to fetch existing participants across tournament
  - **⚠️ CROSS-LAYER VIOLATION**: Line 6 imports `participant/data/models/participant_model.dart` — domain service importing data model. Uses `ParticipantModel.fromDriftEntry(entry)` in `_getExistingParticipantsForTournament()` to convert `ParticipantEntry` (Drift type) to entity. **MUST FIX** — extract conversion to repository or add domain-layer factory.
  - **Match types** (from `DuplicateMatchType` enum): `exact`, `fuzzy`, `dateOfBirth`
  - **Exact match**: Same firstName + lastName + same schoolOrDojangName → confidence `1.0`
  - **Exact name, different dojang**: Same firstName + lastName but different dojang → confidence `0.1` (flagged as low-confidence match)
  - **Fuzzy match**: One name exact + other name Levenshtein ≤ 2 + same dojang → confidence `0.9` (distance 1) or `0.7` (distance 2); DOB match adds `+0.1` bonus
  - **DOB match**: Same DOB + same dojang + at least one name exact → confidence `0.5`
  - **Confidence scores**: `DuplicateConfidence` class — `exactMatch=1.0`, `fuzzyDistance1=0.9`, `fuzzyDistance2=0.7`, `dobBonus=0.1`, `differentDojang=0.1`, `dobPrimaryMatch=0.5`
  - **Batch method**: `checkForDuplicatesBatch()` — fetches existing once, reuses for all checks (N+1 avoidance)
  - **Important**: Fuzzy matching requires the OTHER name to be exact (not both fuzzy) — prevents excessive false positives
  - Returns confidence-sorted `List<DuplicateMatch>` (highest first)

- [x] Run:
  ```bash
  flutter test test/features/participant/domain/services/duplicate_detection_service_test.dart
  ```

### Task 10: BulkImportUseCase Audit (AC: #8)

**Verify bulk import preview and commit flow.**

- [x] **BulkImportUseCase** at `domain/usecases/bulk_import_usecase.dart`:
  - **Annotation**: `@injectable` (factory, NOT singleton)
  - **Constructor**: `BulkImportUseCase(CSVParserService, DuplicateDetectionService, ParticipantRepository)` — 3 dependencies
  - **`generatePreview(csvContent, divisionId, tournamentId)`**:
    1. Calls `_csvParserService.parseCSV(csvContent: csvContent, divisionId: divisionId)`
    2. Groups parse errors by row number into `errorsByRow`
    3. Creates error rows as `BulkImportPreviewRow(status: error)` with `validationErrors` map
    4. For valid rows: converts to `ParticipantCheckData` list, calls `_duplicateDetectionService.checkForDuplicatesBatch()`
    5. Determines row status via `_determineStatus()`: no validation errors + no duplicates = `valid`; has duplicates = `warning`; has errors = `error`
    6. Sorts preview rows by `sourceRowNumber`
    7. Returns `BulkImportPreview` with `validCount`, `warningCount`, `errorCount`, `totalRows`
  - **`importSelected(selectedRows, divisionId)`**:
    1. Skips rows with `BulkImportRowStatus.error` (adds error message to output)
    2. Creates `ParticipantEntity` for each valid row via `row.rowData.toCreateParticipantParams(divisionId)` with `_uuid.v4()` ID, `syncVersion: 1`, `checkInStatus: pending`
    3. Calls `_participantRepository.createParticipantsBatch(participants)`
    4. Returns `BulkImportResult(successCount, failureCount, errorMessages)`
  - Returns `Either<Failure, T>` — no raw exceptions
  - **⚠️ NOTE**: Error rows in `importSelected` are SILENTLY skipped with message added. They are NOT re-validated. The UI should prevent error rows from being selected.

- [x] Run:
  ```bash
  flutter test test/features/participant/domain/usecases/bulk_import_usecase_test.dart
  ```

### Task 11: AutoAssignmentService Audit (AC: #10)

**Verify auto-assignment matches all criteria correctly.**

- [x] **AutoAssignmentService** at `domain/services/auto_assignment_service.dart`:
  - **Annotation**: `@injectable` (factory, NOT singleton)
  - **Matching logic** (`evaluateMatch`): AND logic — ALL criteria must pass for a match. Returns `null` on first fail.
  - **Null rule**: Null on participant = always matches. Null constraint on division = no restriction.
  - **Age check** (`_checkAgeMatch`): Uses `participant.age` computed getter (from dateOfBirth). Null age = always matches. Compares against `division.ageMin`/`ageMax`.
  - **Gender check** (`_checkGenderMatch`): `DivisionGender.mixed` accepts all. Null gender on participant = always matches. Otherwise `p.gender.value == d.gender.value`.
  - **Weight check** (`_checkWeightMatch`): Null weightKg = always matches. Compares against `division.weightMinKg`/`weightMaxKg`.
  - **Belt check** (`_checkBeltMatch`): Uses `BeltRank.fromString(p.beltRank)` — if unknown belt string returns `null`, treated as always matches. Compares `BeltRank.order` (int) against `division.beltRankMin`/`beltRankMax` via `BeltRank.fromString()`.
  - **Match score**: Incremented for each matched criteria category (age, gender always counted; weight/belt counted only if division has constraints)
  - **`determineUnmatchedReason`**: Checks each criterion independently to provide human-readable explanation
  - **⚠️ CHECK**: Verify `BeltRank` import path — uses `division/domain/entities/belt_rank.dart` (cross-feature domain, acceptable)

- [x] **AutoAssignParticipantsUseCase** at `domain/usecases/auto_assign_participants_usecase.dart`:
  - Coordinates with `AutoAssignmentService` and `AssignToDivisionUseCase`
  - Returns `Either<Failure, AutoAssignmentResult>`

- [x] Run:
  ```bash
  flutter test test/features/participant/domain/services/auto_assignment_service_test.dart
  flutter test test/features/participant/domain/usecases/auto_assign_participants_usecase_test.dart
  ```

### Task 12: Participant Status Management Audit (AC: #12)

**Verify no-show and DQ status changes work correctly.**

- [x] **MarkNoShowUseCase** at `domain/usecases/mark_no_show_usecase.dart`:
  - **Constructor**: `MarkNoShowUseCase(ParticipantRepository)` — single dep
  - Takes single `String participantId` positional arg (not named params)
  - Fetches participant, then `copyWith(checkInStatus: noShow, checkInAtTimestamp: null, dqReason: null, syncVersion: +1, updatedAtTimestamp: now)`
  - Calls `_participantRepository.updateParticipant(updatedParticipant)`
  - **⚠️ CONFIRMED DOUBLE-INCREMENT BUG**: Use case increments `syncVersion +1` on line 23, then `updateParticipant()` in repository ALSO increments syncVersion (lines 118-120 of repo). Result: syncVersion incremented by 2 instead of 1. **MUST FIX** — either remove increment from use case OR from repository. Recommend removing from use case (let repo handle it, pattern from 3-15 fix).
  - Returns `Either<Failure, ParticipantEntity>`

- [x] **DisqualifyParticipantUseCase** at `domain/usecases/disqualify_participant_usecase.dart`:
  - **Constructor**: `DisqualifyParticipantUseCase(ParticipantRepository)` — single dep
  - Takes named params: `{required String participantId, required String dqReason}`
  - Validates: `dqReason.trim()` must not be empty → `InputValidationFailure` with `fieldErrors: {'dqReason': 'Cannot be empty'}`
  - Sets `checkInStatus: disqualified`, `checkInAtTimestamp: null`, `dqReason: trimmedReason`
  - **⚠️ SAME DOUBLE-INCREMENT BUG**: syncVersion incremented in use case line 36 AND again in repo. **MUST FIX**.
  - Returns `Either<Failure, ParticipantEntity>`

- [x] **UpdateParticipantStatusUseCase** at `domain/usecases/update_participant_status_usecase.dart`:
  - Generic status update path — **CHECK for same double-increment pattern**
  - Returns `Either<Failure, ParticipantEntity>`

- [x] Run:
  ```bash
  flutter test test/features/participant/domain/usecases/mark_no_show_usecase_test.dart
  flutter test test/features/participant/domain/usecases/disqualify_participant_usecase_test.dart
  flutter test test/features/participant/domain/usecases/update_participant_status_usecase_test.dart
  ```

### Task 13: TransferParticipantUseCase Audit (AC: #11)

**Verify participant transfer blocks correctly.**

- [x] **TransferParticipantUseCase** at `domain/usecases/transfer_participant_usecase.dart`:
  - **Constructor**: `TransferParticipantUseCase(ParticipantRepository, DivisionRepository, TournamentRepository, UserRepository)` — 4 dependencies
  - **14-step validation chain** (order matters):
    1. `participantId` not empty
    2. `targetDivisionId` not empty
    3. Auth — get current user, check orgId
    4. Get participant by ID
    5. Check participant not already in target division (`divisionId == targetDivisionId`)
    6. Get source division from `participant.divisionId`
    7. Get target division from `params.targetDivisionId`
    8. Verify same tournament (`sourceDivision.tournamentId == targetDivision.tournamentId`)
    9. Get tournament for org verification
    10. Verify org ownership
    11. **Check source division status**: Must be `DivisionStatus.setup` or `DivisionStatus.ready` — blocks if `inProgress` or `completed`
    12. **Check target division status**: Same check — must be `setup` or `ready`
    13. Update participant: `copyWith(divisionId: target, seedNumber: null, syncVersion: +1, updatedAtTimestamp: now)`
    14. Persist via `_participantRepository.updateParticipant()`
  - **⚠️ IMPORTANT**: Transfer checks `DivisionStatus` NOT bracket status. This is correct for Epic 4 scope (brackets are Epic 5). No dependency on bracket entity.
  - **⚠️ RESETS seedNumber to null** — seeds are division-specific, must be reset on transfer
  - **⚠️ SAME DOUBLE-INCREMENT BUG**: Use case increments syncVersion on line 183, repo also increments. **MUST FIX**.
  - Returns `Either<Failure, ParticipantEntity>`

- [x] Run:
  ```bash
  flutter test test/features/participant/domain/usecases/transfer_participant_usecase_test.dart
  ```

### Task 14: Repository Layer Audit (AC: #5)

**Verify participant repository follows offline-first patterns.**

- [x] **ParticipantRepositoryImplementation** at `data/repositories/participant_repository_implementation.dart`:
  - **Annotation**: `@LazySingleton(as: ParticipantRepository)`
  - **Constructor**: Takes `ParticipantLocalDatasource`, `ParticipantRemoteDatasource`, `ConnectivityService`
  - All methods return `Either<Failure, T>`
  - `getParticipantsForDivision(divisionId)` — reads local first; if online, fetches remote and applies LWW (Last-Write-Wins) per syncVersion; replaces local with remote list
  - `getParticipantById(id)` — local first, remote fallback, `NotFoundFailure` if neither has it
  - `createParticipant(participant)` — writes local, attempts remote if online. **Returns INPUT entity** (not persisted) — acceptable since no fields change on insert
  - `updateParticipant(participant)` — **KEY LOGIC** (lines 114-141):
    1. Re-reads existing from local to get current `syncVersion`
    2. Computes `newSyncVersion = (existing?.syncVersion ?? 0) + 1`
    3. Creates model with `participant.copyWith(syncVersion: newSyncVersion)`
    4. Writes to local, attempts remote
    5. **Returns `participant.copyWith(syncVersion: newSyncVersion)`** — constructs correct return value
  - **⚠️ CONFIRMED DOUBLE-INCREMENT**: The repo always increments syncVersion in step 2. But callers (`MarkNoShowUseCase`, `DisqualifyParticipantUseCase`, `TransferParticipantUseCase`, and potentially others) ALSO increment before calling. Result: syncVersion goes up by 2 per update.
  - **FIX STRATEGY**: Remove syncVersion increment from ALL use cases. Let the repository be the single source of syncVersion management. This matches the fix pattern from Story 3-15.
  - `deleteParticipant(id)` — local delete, attempts remote
  - `createParticipantsBatch(participants)` — batch local insert via `insertParticipantsBatch()`, then sequential remote inserts with fallback. **Returns INPUT entities** (not persisted)
  - **⚠️ CHECK**: Remote sync failure catch blocks have `// Queued for sync` comments but no actual queue mechanism — these are aspirational comments. Verify if `SyncService` handles offline reconciliation separately.

- [x] Run:
  ```bash
  flutter test test/features/participant/data/repositories/participant_repository_implementation_test.dart
  ```

### Task 15: Datasource Layer Audit (AC: #5)

**Verify local and remote datasources follow established patterns.**

- [x] **ParticipantLocalDatasource** at `data/datasources/participant_local_datasource.dart`:
  - Uses Drift `AppDatabase` for local operations
  - All CRUD methods work correctly
  - `getParticipantsForDivision()` filters `isDeleted == false`
  - `insertParticipantsBatch()` handles batch correctly (single transaction)

- [x] Run:
  ```bash
  flutter test test/features/participant/data/datasources/participant_local_datasource_test.dart
  ```

### Task 16: ParticipantListBloc State Transition Audit (AC: #13, #14)

**Verify ParticipantListBloc handles all state transitions.**

- [x] **ParticipantListBloc** at `presentation/bloc/participant_list_bloc.dart`:
  - **Constructor DI**: Check dependencies injected via `@injectable`
  - **Event handlers**: Load, Refresh, Search, Filter, Sort, Create, Edit, StatusChange, Transfer, Remove
  - **Search**: Filters by name, dojang (schoolOrDojangName), belt — verify all three filters apply correctly
  - **Filter enum**: `ParticipantFilter` — verify all filter options work
  - **Sort enum**: `ParticipantSort` — verify all sort options work
  - **State transitions**: Initial → LoadInProgress → LoadSuccess/LoadFailure
  - **`_processParticipants`**: Verify it applies search query, filter, and sort in correct order
  - **CRITICAL**: Verify BLoC properly handles large lists (500+ participants) — no O(n²) operations in `_processParticipants`

- [x] Run:
  ```bash
  flutter test test/features/participant/presentation/bloc/participant_list_bloc_test.dart
  ```

### Task 17: CSVImportBloc State Transition Audit (AC: #9, #13)

**Verify CSVImportBloc handles all states including tab-delimited paste.**

- [x] **CSVImportBloc** at `presentation/bloc/csv_import_bloc.dart`:
  - **Annotation**: `@injectable` (factory)
  - **Constructor**: `CSVImportBloc(BulkImportUseCase, ClipboardInputService)` — 2 positional args
  - **Event handlers**:
    - `_onPreviewRequested(PreviewRequested event)`: 
      1. Emits `CSVImportPreviewInProgress`
      2. Calls `_clipboardInputService.normalizeToCSV(event.csvContent)` **BEFORE** parsing
      3. Calls `_bulkImportUseCase.generatePreview(csvContent: normalized, divisionId, tournamentId)`
      4. Success → `CSVImportPreviewSuccess(preview, csvContent: event.csvContent)` — stores ORIGINAL input, not normalized
      5. Failure → `CSVImportPreviewFailure(message)`
    - `_onImportRequested(ImportRequested event)`: Emits `ImportInProgress`, calls `importSelected()`, then `ImportSuccess` or `ImportFailure`
    - `_onResetRequested(ResetRequested event)`: Emits `CSVImportInitial`
    - `_onRowSelectionToggled`: Toggles row selection — **cannot select rows with `BulkImportRowStatus.error`**
  - **State hierarchy**: `CSVImportInitial` → `PreviewInProgress` → `PreviewSuccess`/`PreviewFailure` → `ImportInProgress` → `ImportSuccess`/`ImportFailure`
  - **⚠️ KEY INVARIANT**: State stores `csvContent` as ORIGINAL user input, not normalized CSV. This is correct for display/back and re-edit.

- [x] Run:
  ```bash
  flutter test test/features/participant/presentation/bloc/csv_import_bloc_test.dart
  ```

### Task 18: UI Rendering Verification (AC: #13)

**Verify all participant presentation layer pages render correctly.**

- [x] **ParticipantListPage** at `presentation/pages/participant_list_page.dart`:
  - Renders participant cards/list items
  - AppBar has "Import CSV" button (navigates to `CsvImportRoute`)
  - Search bar works
  - Filter/sort options accessible
  - Empty state shown when no participants in division
  - Loading indicator shown during fetch
  - No overflow issues with long participant names or dojang names

- [x] **CSVImportPage** at `presentation/pages/csv_import_page.dart`:
  - Step 1 (Input): Text area with hint text mentioning "Paste CSV or spreadsheet data"
  - Step 2 (Preview): Table with green/yellow/red row indicators
  - Step 3 (Import): Import confirmation and result display
  - **CRITICAL**: `BlocProvider` create uses `getIt<BulkImportUseCase>()` AND `getIt<ClipboardInputService>()` — NOT manual instantiation of services
  - Back navigation works at each step

- [x] **ParticipantCard** at `presentation/widgets/participant_card.dart`:
  - Renders participant name, dojang, belt, status correctly
  - Status badges (pending, checked_in, no_show, disqualified) display correctly

### Task 19: Barrel File Completeness Check (AC: #15)

**Verify barrel files export all public APIs.**

- [x] **`participant.dart`** barrel file at `lib/features/participant/participant.dart`:
  - Current exports: data (datasources, model, repository impl), domain (entity, repository interface, services, usecases)
  - **CHECK**: Presentation exports are missing (comment says "will be added in subsequent stories") — presentation layer exists now (BLoCs, pages, widgets). Add presentation exports:
    ```dart
    // Presentation exports
    export 'presentation/bloc/csv_import_bloc.dart';
    export 'presentation/bloc/csv_import_event.dart';
    export 'presentation/bloc/csv_import_state.dart';
    export 'presentation/bloc/participant_list_bloc.dart';
    export 'presentation/bloc/participant_list_event.dart';
    export 'presentation/bloc/participant_list_state.dart';
    export 'presentation/pages/csv_import_page.dart';
    export 'presentation/pages/participant_list_page.dart';
    export 'presentation/widgets/participant_card.dart';
    ```
  - [x] **CHECK**: `domain/services/services.dart` barrel — verify all 10 exports present (auto_assignment_service, clipboard_input_service, csv_import_result, csv_parser_service, csv_row_data, csv_row_error, duplicate_detection_service, duplicate_match, duplicate_match_type, participant_check_data)
  - [x] **CHECK**: `domain/usecases/usecases.dart` barrel — verify all 22 exports present

### Task 20: Structure Test Verification (AC: #2)

- [x] Run: `flutter test test/features/participant/structure_test.dart` — must pass
- [x] Verify the structure test validates correct file organization for the participant feature

### Task 21: Sync Service Integration Check (AC: #15)

**Verify `sync_service.dart` includes participant table in syncable tables.**

- [x] Check `_syncableTables` in `lib/core/sync/sync_service.dart` — must include `'participants'`
- [x] Run: `flutter test test/core/sync/sync_service_test.dart` — must pass
- [x] Verify participant sync tests have proper mocks (learned from 3-15: missing table mocks cause test failures)

### Task 22: Full Test Suite Run (AC: #17)

- [x] Run ALL participant tests:
  ```bash
  flutter test test/features/participant/
  ```
- [x] Note total test count and any failures

### Task 23: Final Verification (AC: #1, #15, #16, #17)

- [x] Run: `dart analyze .` from `tkd_brackets/` — expect **zero** issues
- [x] Run: `dart run build_runner build --delete-conflicting-outputs` — expect clean generation
- [x] Run: `flutter test` from `tkd_brackets/` — expect **all tests pass** (last known count: 1608)
- [x] Confirm no regressions from any fixes applied

---

## Dev Notes

### ⚠️ Execution Order (Recommended)

1. **Task 1**: Run `dart analyze` baseline — capture initial state
2. **Task 2**: Fix cross-layer violations FIRST (DuplicateDetectionService import is a structural change)
3. **Task 3**: Regenerate DI after Task 2 fix: `dart run build_runner build --delete-conflicting-outputs`
4. **Tasks 12-13-14**: Fix double syncVersion increment across all use cases + repository (interconnected)
5. **Task 19**: Fix barrel file exports
6. **Tasks 5-11, 15-18**: Audit remaining components (order flexible)
7. **Tasks 20-22**: Run all tests
8. **Task 23**: Final verification

### ⚠️ CRITICAL: Do Not Touch These

1. **`AuthenticationBloc`** — Singleton that manages global auth state. Do NOT modify.
2. **Bootstrap initialization order** in `bootstrap.dart` — Do NOT change.
3. **`@LazySingleton` annotations on stateless services** — For web startup performance. Do NOT change to `@singleton`.
4. **BLoCs use `@injectable`** — `ParticipantListBloc` and `CSVImportBloc` are feature-scoped (not singletons). Do NOT change to `@lazySingleton`.
5. **`_syncableTables` in `sync_service.dart`** — Extended across epics. Do NOT remove existing entries.
6. **`CSVParserService._parseCSVLine`** — Splits on comma ONLY. Tab-to-CSV conversion is handled upstream by `ClipboardInputService`. Do NOT modify the CSV parser's delimiter logic.
7. **`BulkImportUseCase`** — Receives normalized CSV from BLoC. No changes needed in the use case.

### ⚠️ CRITICAL: Field Name Correctness (from source code verification)

- **ParticipantEntity uses `schoolOrDojangName`** ✅ (NOT `dojangName`, `school`, or `dojang`)
- **ParticipantEntity uses `weightKg`** ✅ (NOT `weight` or `weightInKg`)
- **ParticipantEntity uses `beltRank`** ✅ (NOT `belt` or `rank`)
- **ParticipantEntity uses `checkInStatus`** (ParticipantStatus enum) ✅ (NOT `status`)
- **ParticipantEntity uses `dateOfBirth`** ✅ (NOT `dob` or `birthDate`)
- **ParticipantEntity uses `divisionId`** ✅ — each participant belongs to ONE division
- **ParticipantEntity `syncVersion` defaults to `1`** — same as DivisionEntity, intentional
- **ParticipantEntity has computed `age` getter** — not stored, calculated from `dateOfBirth`
- **CSVParserService maps column aliases to**: `firstName`, `lastName`, `dateOfBirth`, `beltRank`, `weightKg`, `schoolOrDojangName`, `registrationNumber`, `gender`
- If any code references the wrong field names, **fix them** to match the entity definitions.

### ⚠️ CONFIRMED Bugs to Fix (from source code analysis)

1. **🚨 CRITICAL — Cross-Layer Import Violation**: `DuplicateDetectionService` at `domain/services/duplicate_detection_service.dart` line 6 imports `participant/data/models/participant_model.dart`. The `_getExistingParticipantsForTournament()` method uses `ParticipantModel.fromDriftEntry(entry)` to convert `ParticipantEntry` (Drift DB type). **FIX**: Add a method to `ParticipantRepository` interface that returns `List<ParticipantEntity>` for a tournament (resolving across divisions internally), so the domain service never touches data-layer types.

2. **🚨 CRITICAL — Double syncVersion Increment**: Multiple use cases increment `syncVersion + 1` before calling `repo.updateParticipant()`, which ALSO increments syncVersion. Affected use cases:
   - `MarkNoShowUseCase` (line 23: `syncVersion: participant.syncVersion + 1`)
   - `DisqualifyParticipantUseCase` (line 36: `syncVersion: participant.syncVersion + 1`)
   - `TransferParticipantUseCase` (line 183: `syncVersion: participant.syncVersion + 1`)
   - `UpdateParticipantUseCase` (CHECK)
   - `UpdateParticipantStatusUseCase` (CHECK)
   - `UpdateSeedPositionsUseCase` (CHECK)
   **FIX**: Remove `syncVersion` increment from ALL use case `copyWith` calls. Let `ParticipantRepositoryImplementation.updateParticipant()` be the single owner of syncVersion management.

3. **MEDIUM — Barrel file missing presentation exports**: `participant.dart` barrel file has comment `// Presentation exports (will be added in subsequent stories)` but presentation layer files exist (BLoCs, pages, widgets). **FIX**: Add all presentation exports.

4. **LOW — Aspirational sync comments**: Repository catch blocks have `// Queued for sync` comments but no actual queuing mechanism. Document this as known tech debt — `SyncService` handles offline reconciliation at next sync cycle via diff detection.

### Architecture: Participant Feature File Tree

```
lib/features/participant/
├── participant.dart                          # Barrel file (needs presentation exports)
├── data/
│   ├── datasources/
│   │   ├── participant_local_datasource.dart
│   │   └── participant_remote_datasource.dart
│   ├── models/
│   │   ├── participant_model.dart
│   │   ├── participant_model.freezed.dart
│   │   └── participant_model.g.dart
│   └── repositories/
│       └── participant_repository_implementation.dart
├── domain/
│   ├── entities/
│   │   ├── participant_entity.dart
│   │   └── participant_entity.freezed.dart
│   ├── repositories/
│   │   └── participant_repository.dart
│   ├── services/
│   │   ├── auto_assignment_service.dart
│   │   ├── clipboard_input_service.dart
│   │   ├── csv_import_result.dart
│   │   ├── csv_parser_service.dart
│   │   ├── csv_row_data.dart
│   │   ├── csv_row_error.dart
│   │   ├── duplicate_detection_service.dart
│   │   ├── duplicate_match.dart
│   │   ├── duplicate_match_type.dart
│   │   ├── participant_check_data.dart
│   │   └── services.dart                    # Barrel (10 exports)
│   └── usecases/
│       ├── assign_to_division_usecase.dart
│       ├── auto_assign_participants_usecase.dart
│       ├── auto_assignment_match.dart
│       ├── auto_assignment_result.dart
│       ├── bulk_import_preview.dart
│       ├── bulk_import_preview_row.dart
│       ├── bulk_import_result.dart
│       ├── bulk_import_row_status.dart
│       ├── bulk_import_usecase.dart
│       ├── create_participant_params.dart
│       ├── create_participant_usecase.dart
│       ├── delete_participant_usecase.dart
│       ├── disqualify_participant_usecase.dart
│       ├── division_participant_view.dart
│       ├── get_division_participants_usecase.dart
│       ├── mark_no_show_usecase.dart
│       ├── transfer_participant_params.dart
│       ├── transfer_participant_usecase.dart
│       ├── update_participant_params.dart
│       ├── update_participant_status_usecase.dart
│       ├── update_participant_usecase.dart
│       ├── update_seed_positions_usecase.dart
│       └── usecases.dart                    # Barrel (22 exports)
└── presentation/
    ├── bloc/
    │   ├── csv_import_bloc.dart
    │   ├── csv_import_event.dart (+.freezed.dart)
    │   ├── csv_import_state.dart (+.freezed.dart)
    │   ├── participant_list_bloc.dart
    │   ├── participant_list_event.dart (+.freezed.dart)
    │   └── participant_list_state.dart (+.freezed.dart)
    ├── pages/
    │   ├── csv_import_page.dart
    │   └── participant_list_page.dart
    └── widgets/
        ├── participant_card.dart
        └── participant_import_button.dart (if exists)
```

### Test File Tree (Epic 4 Scope)

```
test/features/participant/
├── structure_test.dart
├── data/
│   ├── datasources/
│   │   └── participant_local_datasource_test.dart
│   ├── models/
│   │   └── participant_model_test.dart
│   └── repositories/
│       └── participant_repository_implementation_test.dart
├── domain/
│   ├── entities/
│   │   └── participant_entity_test.dart
│   ├── services/
│   │   ├── auto_assignment_service_test.dart
│   │   ├── clipboard_input_service_test.dart
│   │   ├── csv_parser_service_test.dart
│   │   └── duplicate_detection_service_test.dart
│   └── usecases/
│       ├── assign_to_division_usecase_test.dart
│       ├── auto_assign_participants_usecase_test.dart
│       ├── bulk_import_usecase_test.dart
│       ├── create_participant_usecase_test.dart
│       ├── disqualify_participant_usecase_test.dart
│       ├── get_division_participants_usecase_test.dart
│       ├── mark_no_show_usecase_test.dart
│       ├── transfer_participant_usecase_test.dart
│       ├── update_participant_status_usecase_test.dart
│       ├── update_participant_usecase_test.dart
│       └── update_seed_positions_usecase_test.dart
└── presentation/
    └── bloc/
        ├── csv_import_bloc_test.dart
        └── participant_list_bloc_test.dart
```

### Testing Patterns (Mandatory)

```dart
// === Mock pattern (mocktail — NOT mockito) ===
class MockParticipantRepository extends Mock implements ParticipantRepository {}
class MockCSVParserService extends Mock implements CSVParserService {}
class MockClipboardInputService extends Mock implements ClipboardInputService {}
class MockDuplicateDetectionService extends Mock implements DuplicateDetectionService {}
class MockAutoAssignmentService extends Mock implements AutoAssignmentService {}
class MockBulkImportUseCase extends Mock implements BulkImportUseCase {}

// === BLoC test pattern ===
class MockParticipantListBloc
    extends MockBloc<ParticipantListEvent, ParticipantListState>
    implements ParticipantListBloc {}
class MockCSVImportBloc
    extends MockBloc<CSVImportEvent, CSVImportState>
    implements CSVImportBloc {}

// === ClipboardInputService stub (for BLoC tests) ===
// Default: return input unchanged (CSV passthrough)
when(() => mockClipboardInputService.normalizeToCSV(any()))
    .thenAnswer((inv) => inv.positionalArguments[0] as String);

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

### Previous Code Review Learnings (from 1-13, 2-12, 3-15)

1. **Cross-layer imports are the most common violation** — Domain must never import from data. Use abstract interfaces in domain, implementations in data. **CONFIRMED in 4-14**: `DuplicateDetectionService` imports from data.
2. **Field naming inconsistencies** — Always verify field names match actual entity definitions. **Verified**: All participant field names are correct in current code.
3. **`dart analyze` must be clean** — Fix ALL warnings, including unused imports in test files.
4. **Barrel file completeness matters** — Missing exports cause DI registration failures. **CONFIRMED in 4-14**: presentation exports missing.
5. **Stale comments** — Update comments that reference "future Story X" if that story is now complete. **CONFIRMED**: barrel file has stale comment.
6. **Either pattern enforcement** — No raw exceptions should escape use cases. All errors mapped to `Failure` types.
7. **Build runner must be run** after any changes to freezed/injectable files: `dart run build_runner build --delete-conflicting-outputs`
8. **Stale entity returns in repository update operations** — Repos should return the entity reflecting the persisted state. **VERIFIED**: Participant repo constructs correct return via `copyWith(syncVersion: newSyncVersion)` — no stale return issue here.
9. **Double syncVersion increment** — If repo increments syncVersion AND caller also increments → double increment. **CONFIRMED in 4-14**: MarkNoShowUseCase, DisqualifyParticipantUseCase, TransferParticipantUseCase all double-increment.
10. **Missing sync queue calls** — Empty catch blocks in remote sync should still queue for later sync. **CONFIRMED**: Aspirational comments only, no actual queue mechanism.

### Architecture: Layer Rules

```
core/         → can import: only core/
domain/       → can import: core/ only (no data/, no presentation/)
data/         → can import: core/, domain/ (no presentation/)
presentation/ → can import: core/, domain/, data/ (via DI)
```

**Known intentional exception**: `app_router.dart` and `routes.dart` (in `core/router/`) import from `features/*/presentation/` because the router needs page widgets and auth state for guards.

### References

- [Source: epics.md#Story 4.14](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/_bmad-output/planning-artifacts/epics.md) — Story AC and user story statement (lines 1776-1801)
- [Source: 4-13-paste-from-spreadsheet.md](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/_bmad-output/implementation-artifacts/4-13-paste-from-spreadsheet.md) — Previous story (clipboard paste, most recent)
- [Source: 3-15-code-review-and-fix-tournament-management.md](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/_bmad-output/implementation-artifacts/3-15-code-review-and-fix-tournament-management.md) — Code review pattern reference (Epic 3)
- [Source: participant_entity.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/features/participant/domain/entities/participant_entity.dart) — Entity definition
- [Source: participant_repository.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/features/participant/domain/repositories/participant_repository.dart) — Repository interface
- [Source: participant_repository_implementation.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/features/participant/data/repositories/participant_repository_implementation.dart) — Repository implementation
- [Source: csv_import_bloc.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/features/participant/presentation/bloc/csv_import_bloc.dart) — CSV import BLoC with ClipboardInputService
- [Source: participant_list_bloc.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/features/participant/presentation/bloc/participant_list_bloc.dart) — Participant list BLoC
- [Source: participant.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/features/participant/participant.dart) — Feature barrel file
- [Source: routes.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/core/router/routes.dart) — Route definitions (ParticipantListRoute, CsvImportRoute)
- [Source: app_router.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/core/router/app_router.dart) — Router configuration

---

## Dev Agent Record

### Agent Model Used

Antigravity (Google Deepmind)

### Debug Log References

### Completion Notes List

- `dart analyze .` — zero issues
- 343 participant tests pass
- 1608 total tests pass, zero failures
- Cross-layer violation in DuplicateDetectionService: FIXED (uses ParticipantRepository.getParticipantsForTournament)
- Double syncVersion increment: FIXED in MarkNoShowUseCase, DisqualifyParticipantUseCase, TransferParticipantUseCase, UpdateParticipantUseCase, UpdateParticipantStatusUseCase, UpdateSeedPositionsUseCase
- Barrel file presentation exports: FIXED
- Known tech debt: TODO(sync) comments in repo — no actual queue mechanism, SyncService handles reconciliation

### File List

- lib/features/participant/domain/services/duplicate_detection_service.dart (fixed cross-layer import)
- lib/features/participant/domain/repositories/participant_repository.dart (added getParticipantsForTournament)
- lib/features/participant/data/repositories/participant_repository_implementation.dart (implemented getParticipantsForTournament)
- lib/features/participant/domain/usecases/mark_no_show_usecase.dart (removed syncVersion increment)
- lib/features/participant/domain/usecases/disqualify_participant_usecase.dart (removed syncVersion increment)
- lib/features/participant/domain/usecases/transfer_participant_usecase.dart (removed syncVersion increment)
- lib/features/participant/domain/usecases/update_participant_usecase.dart (removed syncVersion increment)
- lib/features/participant/domain/usecases/update_participant_status_usecase.dart (removed syncVersion increment)
- lib/features/participant/domain/usecases/update_seed_positions_usecase.dart (removed syncVersion increment)
- lib/features/participant/domain/usecases/assign_to_division_usecase.dart (removed syncVersion increment)
- lib/features/participant/domain/usecases/auto_assign_participants_usecase.dart (verified clean)
- lib/features/participant/participant.dart (added presentation exports)
- lib/core/sync/sync_service.dart (verified participants in _syncableTables)
- lib/core/database/app_database.dart (updated for getParticipantsForTournament support)
- lib/features/participant/data/datasources/participant_local_datasource.dart (added getParticipantsForTournament)
- lib/features/participant/data/datasources/participant_remote_datasource.dart (added getParticipantsForTournament)
- test/features/participant/domain/services/duplicate_detection_service_test.dart (updated for new repo pattern)
- test/features/participant/domain/usecases/*.dart (updated for syncVersion fix)
- test/core/sync/sync_service_test.dart (verified participant mocks)
