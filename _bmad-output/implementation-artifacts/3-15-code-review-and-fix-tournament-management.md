# Story 3.15: Code Review & Fix — Tournament & Division Management

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a tech lead,
I want a thorough code review and fix of all Epic 3 implementation,
so that tournament and division management is robust, tested, and production-ready.

## Acceptance Criteria

1. `dart analyze .` (from `tkd_brackets/`) reports **zero** warnings or errors
2. All tournament and division feature files follow Clean Architecture layer rules — no cross-layer imports (domain must NOT import from data or presentation)
3. DI container registers all Epic 3 services; all resolvable at runtime
4. All tournament/division routes resolve to real widgets; navigation works end-to-end
5. Create, edit, archive, delete tournament all work with correct `Either<Failure, T>` returns — no raw exceptions escape
6. Smart Division Builder produces correct age/belt/weight/gender divisions for WT, ITF, ATA templates
7. Division merge creates a new merged division and soft-deletes source divisions
8. Division split into pool A/B correctly distributes participants
9. Ring assignment prevents assigning ring numbers outside configured `numberOfRings` range
10. Scheduling conflict detection correctly flags athletes assigned to overlapping divisions on the same ring
11. Duplicate tournament copies all settings and divisions but NOT participants or brackets
12. Tournament Management UI (Story 3-14) pages render without overflow, dead-end navigation, or console errors
13. All identified issues are fixed and verified
14. Final `dart analyze` clean after all fixes
15. `flutter test` passes — all existing tests pass (count may increase if new tests added)

## Tasks / Subtasks

### Task 1: Static Analysis Baseline (AC: #1, #14)

**Run `dart analyze` to establish baseline and fix any warnings.**

- [ ] Run `dart analyze .` from `tkd_brackets/`
- [ ] Fix any warnings or errors found
- [ ] Re-run `dart analyze .` — must report **zero** issues

### Task 2: Architecture Layer Audit — Tournament Feature (AC: #2)

**Scan for cross-layer import violations in the tournament feature.**

- [ ] Run these checks from `tkd_brackets/`:
  ```bash
  # Domain should NOT import from data or presentation
  grep -rn "import.*data/" lib/features/tournament/domain/ --include="*.dart" | grep -v ".g.dart" | grep -v ".freezed.dart"
  grep -rn "import.*presentation/" lib/features/tournament/domain/ --include="*.dart" | grep -v ".g.dart" | grep -v ".freezed.dart"
  
  # Data should NOT import from presentation
  grep -rn "import.*presentation/" lib/features/tournament/data/ --include="*.dart" | grep -v ".g.dart" | grep -v ".freezed.dart"
  ```
- [ ] **Expected**: All commands return empty (no violations).

### Task 3: Architecture Layer Audit — Division Feature (AC: #2)

**Scan for cross-layer import violations in the division feature.**

- [ ] Run these checks from `tkd_brackets/`:
  ```bash
  # Domain should NOT import from data or presentation
  grep -rn "import.*data/" lib/features/division/domain/ --include="*.dart" | grep -v ".g.dart" | grep -v ".freezed.dart"
  grep -rn "import.*presentation/" lib/features/division/domain/ --include="*.dart" | grep -v ".g.dart" | grep -v ".freezed.dart"
  
  # Data should NOT import from presentation
  grep -rn "import.*presentation/" lib/features/division/data/ --include="*.dart" | grep -v ".g.dart" | grep -v ".freezed.dart"
  ```
- [ ] **Expected**: All commands return empty.
- [ ] **Also check**: `lib/features/division/services/federation_template_registry.dart` — verify it only imports from domain and core layers (services folder at feature root is a known pattern in this project).

### Task 4: DI Container Verification — Epic 3 Services (AC: #3)

**Verify all Epic 3 services are registered in the generated DI config.**

- [ ] Open `lib/core/di/injection.config.dart` and confirm ALL of these are registered:

  | Service                                                                                                                                                                                                                                 | Registration   | Annotation            |
  | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | --------------------- |
  | `TournamentRepositoryImplementation` → `TournamentRepository`                                                                                                                                                                           | lazy singleton | `@LazySingleton(as:)` |
  | `DivisionRepositoryImplementation` → `DivisionRepository`                                                                                                                                                                               | lazy singleton | `@LazySingleton(as:)` |
  | `DivisionTemplateRepositoryImplementation` → `DivisionTemplateRepository`                                                                                                                                                               | lazy singleton | `@LazySingleton(as:)` |
  | `TournamentLocalDatasource`                                                                                                                                                                                                             | lazy singleton | `@lazySingleton`      |
  | `TournamentRemoteDatasource`                                                                                                                                                                                                            | lazy singleton | `@lazySingleton`      |
  | `DivisionLocalDatasource`                                                                                                                                                                                                               | lazy singleton | `@lazySingleton`      |
  | `DivisionRemoteDatasource`                                                                                                                                                                                                              | lazy singleton | `@lazySingleton`      |
  | `DivisionTemplateLocalDatasource`                                                                                                                                                                                                       | lazy singleton | `@lazySingleton`      |
  | `DivisionTemplateRemoteDatasource`                                                                                                                                                                                                      | lazy singleton | `@lazySingleton`      |
  | `ConflictDetectionService`                                                                                                                                                                                                              | factory        | `@injectable`         |
  | `FederationTemplateRegistry`                                                                                                                                                                                                            | lazy singleton | `@LazySingleton()`    |
  | `TournamentBloc`                                                                                                                                                                                                                        | factory        | `@injectable`         |
  | `TournamentDetailBloc`                                                                                                                                                                                                                  | factory        | `@injectable`         |
  | Use cases: `CreateTournamentUseCase`, `GetTournamentsUseCase`, `GetTournamentUseCase`, `UpdateTournamentSettingsUseCase`, `DuplicateTournamentUseCase`, `ArchiveTournamentUseCase`, `DeleteTournamentUseCase`                           | factory        | `@injectable`         |
  | Use cases: `SmartDivisionBuilderUseCase`, `CreateCustomDivisionUseCase`, `UpdateCustomDivisionUseCase`, `GetDivisionsUseCase`, `MergeDivisionsUseCase`, `SplitDivisionUseCase`, `AssignToRingUseCase`, `ApplyFederationTemplateUseCase` | factory        | `@injectable`         |

- [ ] Run: `flutter test test/core/di/injection_test.dart` — must pass.
- [ ] If any service missing, run `dart run build_runner build --delete-conflicting-outputs` to regenerate.

### Task 5: Tournament CRUD Use Cases Audit (AC: #5, #11)

**Verify all tournament use cases return `Either<Failure, T>` and handle edge cases.**

- [ ] **CreateTournamentUseCase** at `domain/usecases/create_tournament_usecase.dart`:
  - **Constructor**: `CreateTournamentUseCase(TournamentRepository, UserRepository)` — takes `_uuid = const Uuid()` as static const
  - **Validation**: name required (trimmed), `maxNameLength = 100`, `maxDescriptionLength = 1000`, `scheduledDate` >= today (date-only comparison)
  - Gets current user from `UserRepository.getCurrentUser()` to set `organizationId`, `createdByUserId`
  - If user is null or `user.organizationId.isEmpty` → `AuthenticationFailure`
  - Creates with defaults: `federationType: FederationType.wt`, `status: TournamentStatus.draft`, `numberOfRings: 1`, `isTemplate: false`, `settingsJson: {}`
  - Returns `Either<Failure, TournamentEntity>` via `_repository.createTournament(tournament, user.organizationId)`

- [ ] **UpdateTournamentSettingsUseCase** at `domain/usecases/update_tournament_settings_usecase.dart`:
  - **Constructor**: `UpdateTournamentSettingsUseCase(TournamentRepository, UserRepository)`
  - **Validation**: `ringCount` must be 1–20 (`minRingCount`/`maxRingCount` static consts), `venueName` max 200 chars, `venueAddress` max 500 chars
  - **Authorization**: Owner or Admin only (`user.role == UserRole.owner || user.role == UserRole.admin`)
  - **IMPORTANT**: Params use field `ringCount` but entity uses `numberOfRings` — line 103: `numberOfRings: params.ringCount ?? tournament.numberOfRings` — verify this mapping is correct
  - Returns `Either<Failure, TournamentEntity>`

- [ ] **DuplicateTournamentUseCase** at `domain/usecases/duplicate_tournament_usecase.dart`:
  - **Constructor**: `DuplicateTournamentUseCase(TournamentRepository, AuthRepository, DivisionRepository)` — note: uses `AuthRepository` not `UserRepository`
  - **Authorization**: Owner OR Admin can duplicate (line 105-106: `user.role == UserRole.owner || user.role == UserRole.admin`)
  - Checks source tournament exists AND is not soft-deleted
  - Fetches source divisions via `_repository.getDivisionsByTournamentId()` — filters soft-deleted with `d.isDeleted != true`
  - Creates new tournament: new UUID, name `"${sourceTournament.name} (Copy)"`, `status: TournamentStatus.draft`, `isTemplate: true`, `syncVersion: 0`, `scheduledDate: null`, `completedAtTimestamp: null`
  - Duplicates each division with new UUID, linked to new tournament ID, `syncVersion: 0`
  - **NO participants copied** ✅ — verify division loop only copies division config fields
  - **NO brackets/matches copied** ✅
  - Division creation failures are handled gracefully (logged but not blocking) — line 210-213
  - Returns `Either<Failure, TournamentEntity>`

- [ ] **ArchiveTournamentUseCase** at `domain/usecases/archive_tournament_usecase.dart`:
  - **Constructor**: `ArchiveTournamentUseCase(TournamentRepository, AuthRepository)`
  - Checks tournament exists, blocks if `status == TournamentStatus.active` → `TournamentActiveFailure`
  - **Authorization**: Owner or Admin only
  - Sets `status: TournamentStatus.archived`, increments `syncVersion`
  - Returns `Either<Failure, TournamentEntity>`

- [ ] **DeleteTournamentUseCase** at `domain/usecases/delete_tournament_usecase.dart`:
  - **Constructor**: `DeleteTournamentUseCase(TournamentRepository, AuthRepository)`
  - Checks tournament exists, blocks if `status == TournamentStatus.active` → `TournamentActiveFailure`
  - **Authorization**: Owner ONLY (stricter than archive — line 81: `user.role != UserRole.owner`)
  - **Two modes**: soft delete (default) and hard delete (`params.hardDelete`)
  - Soft delete: sets `isDeleted: true`, `deletedAtTimestamp: DateTime.now()`, `syncVersion + 1`
  - Cascade soft-deletes divisions via `_cascadeSoftDelete()` → fetches divisions from `_repository.getDivisionsByTournamentId()`, updates each with `isDeleted: true`, `syncVersion + 1`
  - Returns `Either<Failure, TournamentEntity>` (NOT `void` — returns the deleted tournament entity)

- [ ] Run all tournament use case tests:
  ```bash
  flutter test test/features/tournament/domain/usecases/
  ```

### Task 6: Smart Division Builder Algorithm Audit (AC: #6)

**Verify the Smart Division Builder produces correct divisions for all federation types.**

- [ ] **SmartDivisionBuilderUseCase** at `lib/features/division/domain/usecases/smart_division_builder_usecase.dart`:
  - **Constructor**: `SmartDivisionBuilderUseCase(DivisionRepository, AppDatabase)` — note: injects `AppDatabase` directly for participant queries
  - **⚠️ ARCHITECTURE WARNING**: This use case imports `core/database/app_database.dart` — verify this is the accepted pattern. Domain layer importing from core is allowed but importing `AppDatabase` directly (instead of through a repository) may be a violation to flag.
  - Generates divisions from 4 configuration axes: age groups × belt groups × weight classes × gender
  - **Default age groups** (from `AgeGroupConfig.defaultAgeGroups`): Pediatric 1 (5-7), Pediatric 2 (8-9), Pediatric 3 (10-11), Youth 1 (12-13), Youth 2 (14-15), Cadet (16-17), Junior (18-21), Senior (22-34), Veterans (35-99)
  - **Story age groups** (from `AgeGroupConfig.storyAgeGroups`): 6-8, 9-10, 11-12, 13-14, 15-17, 18-32, 33+
  - **Belt groups** (from `BeltGroupConfig.defaultBeltGroups`): white-yellow (order 1-2), green-blue (order 4-5), red-black (order 6-7)
  - **Weight classes**: Differ per federation — WT (7M/7F classes), ITF (8M/7F classes), ATA (5M/5F classes, named Light/Medium/Heavy)
  - Gender: For sparring → male + female separately; for poomsae/breaking/demoTeam → mixed only
  - `NamingConventionType` enum: `federationDefault`, `withAgePrefix`, `withoutAgePrefix`, `short`
  - **Performance guard**: 500ms timeout (line 45-53) — returns `InputValidationFailure` if exceeded
  - **Demo mode**: `isDemoMode` flag generates 8 hardcoded demo participants
  - Saves each generated division via `_divisionRepository.createDivision()` — failures don't block (graceful degradation)
  - Returns `Either<Failure, List<DivisionEntity>>`

- [ ] **SmartDivisionNamingService** at `lib/features/division/domain/usecases/smart_division_naming_service.dart`:
  - Verify naming produces human-readable names
  - No duplicate names for different criterion combinations
  - Verify naming handles all `NamingConventionType` variants

- [ ] Run:
  ```bash
  flutter test test/features/division/domain/usecases/smart_division_builder_usecase_test.dart
  ```

### Task 7: Federation Template Registry Audit (AC: #6)

**Verify federation templates are correct and complete for WT, ITF, ATA.**

- [ ] **FederationTemplateRegistry** at `lib/features/division/services/federation_template_registry.dart`:
  - **Annotation**: `@LazySingleton()` — singleton pattern (1771 lines, expensive to reconstruct)
  - **Constructor**: `FederationTemplateRegistry(DivisionTemplateRepository?)` — note: repository is **nullable** (`DivisionTemplateRepository?`) for offline/demo mode support
  - Lazy initialization via `_ensureInitialized()` / `_loadStaticTemplates()` pattern
  - Provides both sync `getAllTemplates()` and async `getAllTemplatesWithCustom()` APIs
  - Static templates loaded for WT, ITF, ATA — each with Cadet/Junior/Senior weight classes for male/female
  - Custom templates merged from `DivisionTemplateRepository` (overrides static by ID)
  - Helper methods: `getTemplatesByCategory()`, `getTemplatesByGender()`, `getTemplateById()`, `getTemplateByIdWithCustom()`
  - **Verify**: WT templates include correct weight ranges per official WT rules (Cadet 12-14, Junior 15-17, Senior 18+)
  - **Verify**: `_mergeTemplates()` correctly sorts by `displayOrder` after merging

- [ ] **ApplyFederationTemplateUseCase** at `lib/features/division/domain/usecases/apply_federation_template_usecase.dart`:
  - Applies template to a tournament
  - Creates divisions based on template configuration
  - Returns `Either<Failure, List<DivisionEntity>>`

- [ ] Run:
  ```bash
  flutter test test/features/division/services/federation_template_registry_test.dart
  ```

### Task 8: Division Merge & Split Audit (AC: #7, #8)

**Verify merge and split logic is correct and atomic.**

- [ ] **MergeDivisionsUseCase** at `lib/features/division/domain/usecases/merge_divisions_usecase.dart`:
  - **Constructor**: `MergeDivisionsUseCase(DivisionRepository, Uuid)` — injects `Uuid` for testability
  - **Returns `Either<Failure, List<DivisionEntity>>`** (NOT single entity — returns list from `_divisionRepository.mergeDivisions()`)
  - **Validation** (order matters):
    1. Cannot merge a division with itself (`divisionIdA == divisionIdB`)
    2. Both divisions must exist in DB
    3. Must be in same tournament (`tournamentId` match)
    4. Must have same `category` (e.g., both sparring)
    5. Neither can be already `isDeleted`
    6. Neither can be already `isCombined` (no re-merging)
  - **Race condition check**: `_checkRaceCondition()` re-fetches both divisions and compares `syncVersion` — returns `ValidationFailure` if modified concurrently
  - **Name uniqueness**: Proposed name checked via `_divisionRepository.isDivisionNameUnique()`
  - Merged division: broadened weight range (`_minWeight`/`_maxWeight` of both), broadened age range, `isCombined: true`, `isCustom: true`, `status: DivisionStatus.setup`, `displayOrder: max(a, b) + 1`
  - Gender resolution: if genders differ → `DivisionGender.mixed`
  - Participant deduplication: `_deduplicateParticipants()` by participant ID
  - Source divisions soft-deleted: `isDeleted: true`, `syncVersion + 1`
  - Belt rank comparison uses `_beltOrdinal()` with hardcoded order: white(0), yellow(1), orange(2), green(3), blue(4), purple(5), brown(6), red(7), black(8)

- [ ] **SplitDivisionUseCase** at `lib/features/division/domain/usecases/split_division_usecase.dart`:
  - **Constructor**: `SplitDivisionUseCase(DivisionRepository, Uuid)`
  - **Returns `Either<Failure, List<DivisionEntity>>`** (two pool divisions)
  - **Validation**:
    1. Division must exist
    2. Division must NOT be `isDeleted`
    3. Division must NOT be `isCombined` (cannot split merged divisions)
  - **⚠️ MINIMUM PARTICIPANTS**: Requires `participants.length >= 4` to split — returns `ValidationFailure` otherwise
  - **Distribution methods** via `SplitDistributionMethod` enum:
    - `alphabetical`: sorts by `lastName`
    - `random`: uses `Random()` shuffle
  - Midpoint: `(shuffled.length / 2).ceil()` — Pool A gets more if odd count
  - New divisions named: `"$baseName Pool A"` and `"$baseName Pool B"`
  - Pool divisions: `isCustom: true`, `isCombined: false`, `status: DivisionStatus.setup`, `syncVersion: 1`
  - Source division soft-deleted: `isDeleted: true`, `syncVersion + 1`
  - Atomic via `_divisionRepository.splitDivision()` — single transactional call

- [ ] Run:
  ```bash
  flutter test test/features/division/usecases/merge_divisions_usecase_test.dart
  flutter test test/features/division/usecases/split_division_usecase_test.dart
  ```

### Task 9: Ring Assignment Audit (AC: #9)

**Verify ring assignment validates within configured range.**

- [ ] **AssignToRingUseCase** at `lib/features/division/domain/usecases/assign_to_ring_usecase.dart`:
  - **Constructor**: `AssignToRingUseCase(DivisionRepository, TournamentRepository)` — crosses feature boundaries (division use case injects tournament repo)
  - **Two-level validation**:
    1. `_validateParams()`: `ringNumber >= 1`, `divisionId` not empty
    2. Main `call()`: Fetches division → fetches tournament → validates `ringNumber` in range `[1, tournament.numberOfRings]`
  - Sets `assignedRingNumber` on the division entity ✅ (correct field name)
  - Also sets `displayOrder` — auto-calculated via `_getNextDisplayOrder()` if not provided in params
  - `_getNextDisplayOrder()`: Gets all divisions for the tournament, filters to same ring + not deleted, finds max `displayOrder`, returns max + 1
  - Increments `syncVersion + 1` and sets `updatedAtTimestamp: DateTime.now()`
  - Returns `Either<Failure, DivisionEntity>` via `_divisionRepository.updateDivision()`
  - **✅ VALIDATION ALREADY EXISTS** (lines 47-61): Ring number validated against `tournament.numberOfRings`

- [ ] Run:
  ```bash
  flutter test test/features/division/usecases/assign_to_ring_usecase_test.dart
  ```

### Task 10: Conflict Detection Service Audit (AC: #10)

**Verify conflict detection logic correctly identifies scheduling conflicts.**

- [ ] **ConflictDetectionService** at `lib/features/division/domain/services/conflict_detection_service.dart`:
  - **Annotation**: `@injectable` (factory, NOT singleton)
  - **Constructor**: `ConflictDetectionService(DivisionRepository)`
  - **⚠️ ARCHITECTURE CHECK**: Service imports `core/database/app_database.dart` for `ParticipantEntry` type — verify this is acceptable (using `show ParticipantEntry` to limit exposure)
  - **3 public methods**:
    1. `detectConflicts(tournamentId)` → `Either<Failure, List<ConflictWarning>>` — full tournament scan
    2. `hasConflicts(tournamentId)` → `Either<Failure, bool>` — convenience wrapper
    3. `getConflictCount(tournamentId)` → `Either<Failure, int>` — convenience wrapper
    4. `detectConflictsForParticipant(tournamentId, participantId)` → `Either<Failure, List<ConflictWarning>>` — single participant scan
  - **Detection algorithm**: Fetches non-deleted divisions with `assignedRingNumber != null` → fetches non-deleted participants → builds participant→divisions map → groups by ring → if participant appears in 2+ divisions on same ring → `ConflictType.sameRing`
  - **Currently only detects `ConflictType.sameRing`** — `timeOverlap` is declared in enum but NOT implemented yet
  - Conflict IDs generated as sequential `'conflict-$conflictId'` strings
  - Conflicts are **warnings only** — they do NOT block saves

- [ ] **ConflictWarning** at `lib/features/division/domain/entities/conflict_warning.dart`:
  - Freezed class with `fromJson` factory (has `.g.dart` part)
  - Fields: `id`, `participantId`, `participantName`, `divisionId1`, `divisionName1`, `ringNumber1` (nullable `int?`), `divisionId2`, `divisionName2`, `ringNumber2` (nullable `int?`), `conflictType`, `dojangName` (optional)
  - Has `const ConflictWarning._()` private constructor for custom methods
  - `ConflictType` enum: `{ sameRing, timeOverlap }`
  - Verify freezed + json_serializable generation is up to date

- [ ] Run:
  ```bash
  flutter test test/features/division/services/conflict_detection_service_test.dart
  ```

### Task 11: Custom Division CRUD Audit (AC: #5)

**Verify custom division creation and update use cases.**

- [ ] **CreateCustomDivisionUsecase** at `lib/features/division/domain/usecases/create_custom_division_usecase.dart`:
  - Accepts free-form name, optional criteria, event type, bracket type, scoring config
  - Custom divisions are marked differently from template-generated ones
  - Returns `Either<Failure, DivisionEntity>`

- [ ] **UpdateCustomDivisionUsecase** at `lib/features/division/domain/usecases/update_custom_division_usecase.dart`:
  - Updates division fields
  - Returns `Either<Failure, DivisionEntity>`

- [ ] Run:
  ```bash
  flutter test test/features/division/usecases/create_custom_division_usecase_test.dart
  flutter test test/features/division/usecases/update_custom_division_usecase_test.dart
  ```

### Task 12: Repository Layer Audit (AC: #5)

**Verify tournament and division repositories follow established patterns.**

- [ ] **TournamentRepositoryImplementation** at `lib/features/tournament/data/repositories/tournament_repository_implementation.dart`:
  - All methods return `Either<Failure, T>`
  - Uses local datasource (Drift) for offline-first reads
  - Queues changes for sync via remote datasource
  - Handles exceptions with try/catch → maps to Failure types
  - **Verify**: `getTournaments()` filters out soft-deleted records (`isDeleted == false`)
  - **Verify**: `getTournament(id)` returns `NotFoundFailure` when not found (not an exception)

- [ ] **DivisionRepositoryImplementation** at `lib/features/division/data/repositories/division_repository_implementation.dart`:
  - All methods return `Either<Failure, T>`
  - `getDivisionsForTournament(tournamentId)` filters soft-deleted
  - `getDivisionsForRing(tournamentId, ringNumber)` correctly filters

- [ ] **TournamentRepository interface** — exact method signatures (verify implementation matches):
  ```dart
  Future<Either<Failure, List<TournamentEntity>>> getTournamentsForOrganization(String organizationId);
  Future<Either<Failure, TournamentEntity>> getTournamentById(String id);
  Future<Either<Failure, TournamentEntity>> createTournament(TournamentEntity tournament, String organizationId);
  Future<Either<Failure, TournamentEntity>> updateTournament(TournamentEntity tournament);
  Future<Either<Failure, Unit>> deleteTournament(String id);
  Future<Either<Failure, Unit>> hardDeleteTournament(String tournamentId);
  Future<Either<Failure, List<DivisionEntity>>> getDivisionsByTournamentId(String tournamentId);  // cross-aggregate
  Future<Either<Failure, DivisionEntity>> updateDivision(DivisionEntity division);  // cross-aggregate for cascade delete
  ```

- [ ] **DivisionRepository interface** — exact method signatures:
  ```dart
  Future<Either<Failure, List<DivisionEntity>>> getDivisionsForTournament(String tournamentId);
  Future<Either<Failure, DivisionEntity>> getDivisionById(String id);
  Future<Either<Failure, DivisionEntity>> getDivision(String id);  // alias → getDivisionById
  Future<Either<Failure, DivisionEntity>> createDivision(DivisionEntity division);
  Future<Either<Failure, DivisionEntity>> updateDivision(DivisionEntity division);
  Future<Either<Failure, Unit>> deleteDivision(String id);
  Future<Either<Failure, bool>> isDivisionNameUnique(String name, String tournamentId, {String? excludeDivisionId});
  Future<Either<Failure, List<ParticipantEntry>>> getParticipantsForDivision(String divisionId);
  Future<Either<Failure, List<ParticipantEntry>>> getParticipantsForDivisions(List<String> divisionIds);
  Future<Either<Failure, List<DivisionEntity>>> mergeDivisions({...});  // atomic merge operation
  Future<Either<Failure, List<DivisionEntity>>> getDivisionsForRing(String tournamentId, int ringNumber);
  Future<Either<Failure, List<DivisionEntity>>> splitDivision({...});  // atomic split operation
  ```

- [ ] Run:
  ```bash
  flutter test test/features/tournament/data/repositories/tournament_repository_implementation_test.dart
  flutter test test/features/division/data/repositories/division_repository_implementation_test.dart
  ```

### Task 13: Model & Entity Correctness (AC: #5)

**Verify models and entities match schema expectations.**

- [ ] **TournamentEntity** at `lib/features/tournament/domain/entities/tournament_entity.dart`:
  - **Required fields**: `id` (String), `organizationId` (String), `createdByUserId` (String), `name` (String), `federationType` (FederationType enum), `status` (TournamentStatus enum), `numberOfRings` (int), `settingsJson` (Map<String, dynamic>), `isTemplate` (bool), `createdAt` (DateTime), `updatedAtTimestamp` (DateTime)
  - **Optional fields**: `scheduledDate` (DateTime?), `description` (String?), `venueName` (String?), `venueAddress` (String?), `scheduledStartTime` (DateTime?), `scheduledEndTime` (DateTime?), `templateId` (String?), `completedAtTimestamp` (DateTime?), `deletedAtTimestamp` (DateTime?)
  - **Default fields**: `isDeleted` (@Default(false) bool), `syncVersion` (@Default(0) int)
  - **⚠️ NO `isDemoData` field on TournamentEntity** — only DivisionEntity has `isDemoData`
  - **⚠️ Audit field name**: Entity uses `createdAt` (NOT `createdAtTimestamp`) — inconsistent with DivisionEntity which uses `createdAtTimestamp`
  - `FederationType` enum: `wt`, `itf`, `ata`, `custom` — each with `.value` string getter and `fromString()` factory
  - `TournamentStatus` enum: `draft`, `active`, `completed`, `archived`, `cancelled` — each with `.value` and `fromString()`
  - Freezed generation must be up to date

- [ ] **DivisionEntity** at `lib/features/division/domain/entities/division_entity.dart`:
  - **Required fields**: `id`, `tournamentId`, `name`, `category` (DivisionCategory), `gender` (DivisionGender), `bracketFormat` (BracketFormat), `status` (DivisionStatus), `createdAtTimestamp`, `updatedAtTimestamp`
  - **Smart Builder nullable fields**: `ageMin` (int?), `ageMax` (int?), `weightMinKg` (double?), `weightMaxKg` (double?), `beltRankMin` (String?), `beltRankMax` (String?)
  - **Ring assignment**: `assignedRingNumber` (int?) ✅ — NOT `ringNumber`
  - **Default fields**: `isCombined` (@Default(false)), `displayOrder` (@Default(0) int — **NOT nullable**), `isDeleted` (@Default(false)), `isDemoData` (@Default(false)), `isCustom` (@Default(false)), `syncVersion` (@Default(1) int — **NOTE: defaults to 1, not 0**)
  - **⚠️ NO fields named**: `eventType`, `bracketType`, `scoringMethod`, `judgeCount` — these DO NOT EXIST. Category is `DivisionCategory` enum, bracket is `BracketFormat` enum
  - `DivisionCategory` enum: `sparring`, `poomsae`, `breaking`, `demoTeam` (with `demo_team` db value)
  - `DivisionGender` enum: `male`, `female`, `mixed`
  - `BracketFormat` enum: `singleElimination`, `doubleElimination`, `roundRobin`, `poolPlay`
  - `DivisionStatus` enum: `setup`, `ready`, `inProgress`, `completed`
  - Freezed generation must be up to date (no `.g.dart` — no JSON serialization on DivisionEntity)

- [ ] **TournamentModel** at `lib/features/tournament/data/models/tournament_model.dart`:
  - `toEntity()` correctly maps all fields including `createdAt` vs `createdAtTimestamp` naming
  - `fromEntity()` correctly maps all fields
  - `fromSupabaseJson()` handles Supabase column names (snake_case)

- [ ] **DivisionModel** at `lib/features/division/data/models/division_model.dart`:
  - Same mapping correctness checks
  - Verify nullable fields handled correctly (especially `assignedRingNumber`, `weightMinKg`, `weightMaxKg`)
  - Verify `displayOrder` maps as non-nullable int with default 0

- [ ] Run:
  ```bash
  flutter test test/features/tournament/domain/entities/tournament_entity_test.dart
  flutter test test/features/tournament/data/models/tournament_model_test.dart
  flutter test test/features/division/domain/entities/division_entity_test.dart
  ```

### Task 14: Datasource Layer Audit (AC: #5)

**Verify local and remote datasources follow established patterns.**

- [ ] **TournamentLocalDatasource** at `lib/features/tournament/data/datasources/tournament_local_datasource.dart`:
  - Uses Drift `AppDatabase` for local operations
  - All CRUD methods work correctly
  - Handles `isDeleted` filtering

- [ ] **TournamentRemoteDatasource** at `lib/features/tournament/data/datasources/tournament_remote_datasource.dart`:
  - Uses Supabase client for remote operations
  - Correct table name: `tournaments`
  - Handles RLS (organization_id filtering)

- [ ] Run:
  ```bash
  flutter test test/features/tournament/data/datasources/tournament_local_datasource_test.dart
  flutter test test/features/tournament/data/datasources/tournament_remote_datasource_test.dart
  ```

### Task 15: Tournament BLoC State Transition Audit (AC: #12)

**Verify TournamentBloc and TournamentDetailBloc handle all state transitions.**

- [ ] **TournamentBloc** at `lib/features/tournament/presentation/bloc/tournament_bloc.dart`:
  - **Constructor DI**: `TournamentBloc(GetTournamentsUseCase, ArchiveTournamentUseCase, DeleteTournamentUseCase, CreateTournamentUseCase)`
  - **6 registered event handlers**:
    1. `TournamentLoadRequested` → `TournamentLoadInProgress` → `TournamentLoadSuccess(tournaments, currentFilter)` or `TournamentLoadFailure`
    2. `TournamentRefreshRequested` → preserves current filter before emitting `LoadInProgress` → re-loads with same filter
    3. `TournamentFilterChanged` → filters locally from current state (only works if state is `TournamentLoadSuccess`)
    4. `TournamentDeleted` → calls `_deleteTournamentUseCase` → adds `TournamentRefreshRequested` on success
    5. `TournamentArchived` → calls `_archiveTournamentUseCase` → adds `TournamentRefreshRequested` on success  
    6. `TournamentCreateRequested` → `TournamentCreateInProgress` → `TournamentCreateSuccess` or `TournamentCreateFailure` → then adds `TournamentRefreshRequested`
  - **`TournamentFilter` enum** (defined in `tournament_event.dart`): `all`, `draft`, `active`, `archived`
  - **`_filterTournaments()`** always filters out `isDeleted` tournaments, then applies status filter
  - **State classes** (7 total): `TournamentInitial`, `TournamentLoadInProgress`, `TournamentLoadSuccess`, `TournamentLoadFailure`, `TournamentCreateInProgress`, `TournamentCreateSuccess`, `TournamentCreateFailure`
  - Verify `@injectable` annotation (NOT `@lazySingleton`)

- [ ] **TournamentDetailBloc** at `lib/features/tournament/presentation/bloc/tournament_detail_bloc.dart`:
  - **Constructor DI**: `TournamentDetailBloc(GetTournamentUseCase, UpdateTournamentSettingsUseCase, DeleteTournamentUseCase, ArchiveTournamentUseCase, GetDivisionsUseCase, ConflictDetectionService)`
  - **5 registered event handlers**:
    1. `TournamentDetailLoadRequested(tournamentId)` → `TournamentDetailLoadInProgress` → loads tournament + divisions + conflicts in sequence → `TournamentDetailLoadSuccess(tournament, divisions, conflicts)`
    2. `TournamentDetailUpdateRequested(tournamentId, venueName?, venueAddress?, ringCount?)` → `TournamentDetailUpdateInProgress` → `TournamentDetailUpdateSuccess(tournament)` or `TournamentDetailUpdateFailure`
    3. `TournamentDetailDeleteRequested(tournamentId)` → `TournamentDetailDeleteSuccess` or `TournamentDetailDeleteFailure`
    4. `TournamentDetailArchiveRequested(tournamentId)` → `TournamentDetailArchiveSuccess(tournament)` or `TournamentDetailArchiveFailure`
    5. `ConflictDismissed(conflictId)` → adds `conflictId` to `dismissedConflictIds` list in current `TournamentDetailLoadSuccess` state (uses `copyWith`)
  - **State classes** (9 total): `Initial`, `LoadInProgress`, `LoadSuccess`, `LoadFailure`, `UpdateInProgress`, `UpdateSuccess`, `UpdateFailure`, `DeleteSuccess`, `DeleteFailure`, `ArchiveSuccess`, `ArchiveFailure`
  - **`TournamentDetailLoadSuccess`** has `@Default([]) List<String> dismissedConflictIds` for conflict dismissal tracking
  - **CRITICAL**: `ConflictDetectionService` IS injected and called in `_onLoadRequested` (line 59)
  - Verify `@injectable` annotation

- [ ] Run:
  ```bash
  flutter test test/features/tournament/presentation/bloc/tournament_bloc_test.dart
  flutter test test/features/tournament/presentation/bloc/tournament_detail_bloc_test.dart
  ```

### Task 16: Tournament UI Rendering Verification (AC: #12)

**Verify all tournament presentation layer pages render correctly.**

- [ ] **TournamentListPage** at `lib/features/tournament/presentation/pages/tournament_list_page.dart`:
  - Renders tournament cards
  - FAB for create tournament
  - Filter chips work
  - Empty state shown when no tournaments
  - Loading indicator shown during fetch

- [ ] **TournamentDetailPage** at `lib/features/tournament/presentation/pages/tournament_detail_page.dart`:
  - Tabbed interface renders (Overview, Divisions, Settings)
  - Overflow menu (Edit, Duplicate, Archive, Delete) works
  - Conflict warnings displayed when present (via ConflictWarningBanner)
  - No dead-end navigation — back button works

- [ ] **DivisionBuilderWizard** at `lib/features/tournament/presentation/pages/division_builder_wizard.dart`:
  - Multi-step wizard renders all steps
  - Federation selection works
  - Preview of divisions to be created shows correctly
  - Submit creates divisions

- [ ] **TournamentFormDialog** at `lib/features/tournament/presentation/widgets/tournament_form_dialog.dart`:
  - Form validation works (name required, date >= today)
  - Cancel and Submit buttons function
  - Error messages display correctly

- [ ] **RingAssignmentWidget** at `lib/features/tournament/presentation/widgets/ring_assignment_widget.dart`:
  - Ring grid renders correctly
  - Division cards display division name
  - Conflict badges shown when applicable

- [ ] **ConflictWarningBanner** at `lib/features/tournament/presentation/widgets/conflict_warning_banner.dart`:
  - Banner appears when conflicts exist
  - Shows conflict count
  - Expandable details work

- [ ] Run any existing widget tests:
  ```bash
  flutter test test/features/tournament/presentation/
  ```

### Task 17: Router & Navigation Audit (AC: #4)

**Verify tournament routes resolve correctly and navigation flows work.**

- [ ] Cross-reference tournament routes in `app_router.dart` and `routes.dart`:

  | Route             | Path                         | Widget                  | Auth Required     |
  | ----------------- | ---------------------------- | ----------------------- | ----------------- |
  | Tournament List   | `/tournaments`               | `TournamentListPage`    | Yes (shell route) |
  | Tournament Detail | `/tournaments/:tournamentId` | `TournamentDetailPage`  | Yes               |
  | Division Builder  | `/tournaments/:id/divisions` | `DivisionBuilderWizard` | Yes               |

- [ ] Verify navigation flow: Tournament List → Tournament Detail → Division Builder → back to Detail
- [ ] Verify `demoAccessiblePrefixes` includes `/tournaments` for demo mode access
- [ ] Run: `flutter test test/core/router/` — all must pass

### Task 18: Barrel File Completeness Check (AC: #13)

**Verify barrel files export all public APIs.**

- [ ] **`tournament.dart`** barrel file — verify ALL public files are exported:
  - All datasources ✓
  - All models ✓
  - Repository implementation ✓
  - All domain entities ✓
  - Domain repository interface ✓
  - All use cases and params ✓
  - All BLoC classes ✓
  - All pages ✓
  - All widgets ✓

- [ ] **Division barrel file** — check if `lib/features/division/division.dart` exists:
  - If it exists, verify completeness (all datasources, models, repositories, entities, use cases, services)
  - If it does NOT exist, **create one** following the tournament.dart pattern
  - Must export: `ConflictDetectionService`, `ConflictWarning`, `FederationTemplateRegistry`, all use cases, all entities, all repos

### Task 19: Structure Test Verification (AC: #2)

**Verify structure tests validate correct file organization for tournament and division features.**

- [ ] Run: `flutter test test/features/tournament/structure_test.dart` — must pass
- [ ] Check if `test/features/division/structure_test.dart` exists:
  - If it exists, run and verify it passes
  - If it does NOT exist, **create one** following the tournament structure test pattern

### Task 20: Final Verification (AC: #1, #13, #14, #15)

- [ ] Run: `dart analyze .` from `tkd_brackets/` — expect **zero** issues
- [ ] Run: `dart run build_runner build --delete-conflicting-outputs` — expect clean generation
- [ ] Run: `flutter test` from `tkd_brackets/` — expect **all tests pass** (count may increase if new tests added)
- [ ] Confirm no regressions from any fixes applied
- [ ] Update this story status from `ready-for-dev` to `done`

---

## Dev Notes

### ⚠️ CRITICAL: Do Not Touch These

1. **`AuthenticationBloc`** — Singleton that manages global auth state. Do NOT modify.
2. **Bootstrap initialization order** in `bootstrap.dart` — Do NOT change.
3. **`@LazySingleton` annotations on all services** — For web startup performance. Do NOT change to `@singleton`.
4. **BLoCs use `@injectable`** — TournamentBloc and TournamentDetailBloc are feature-scoped (not singletons). Do NOT change to `@lazySingleton`.
5. **`organizationId` is `String` not nullable** — Established pattern from Epic 2. Do NOT change.
6. **`_syncableTables` in `sync_service.dart`** — Extended in later epics. The current list should already include `'tournaments'` and `'divisions'` (added in Epic 3). Do NOT remove entries.
7. **`ConflictDetectionService` is a domain service** — It lives in `lib/features/division/domain/services/`. This is correct architecture (domain services are allowed).
8. **`FederationTemplateRegistry` lives in `lib/features/division/services/`** — Feature-level services directory (not domain, not data). This is an accepted pattern in this project.

### ⚠️ CRITICAL: Field Name Correctness (from Story 3-13 learnings + source code verification)

- **DivisionEntity uses `assignedRingNumber`** ✅ (NOT `ringNumber`) — nullable `int?`
- **DivisionEntity uses `displayOrder`** — **non-nullable `int` with `@Default(0)`** (NOT nullable `int?`)
- **DivisionEntity uses `weightMinKg` / `weightMaxKg`** ✅ (NOT `weightMin` / `weightMax`) — nullable `double?`
- **DivisionEntity uses `beltRankMin` / `beltRankMax`** ✅ (NOT `beltMin` / `beltMax`) — nullable `String?`
- **DivisionEntity uses `category`** (DivisionCategory enum) — NOT `eventType`
- **DivisionEntity uses `bracketFormat`** (BracketFormat enum) — NOT `bracketType`
- **TournamentEntity uses `numberOfRings`** ✅ (NOT `ringCount`) — required `int`
- **TournamentEntity uses `createdAt`** (NOT `createdAtTimestamp`) — inconsistent with DivisionEntity
- **TournamentEntity has NO `isDemoData` field** — only DivisionEntity has it
- **UpdateTournamentSettingsParams uses `ringCount`** as the parameter field which maps to entity's `numberOfRings` — naming mismatch is intentional
- If any code references the wrong field names, **fix them** to match the entity definitions.

### ⚠️ Known Code Issues to Check

1. **`UpdateTournamentSettingsParams` has duplicate import** (lines 3-6): imports both `update_tournament_settings_usecase.dart` and `tournament.dart` for `UpdateTournamentSettingsUseCase` — one should be removed
2. **`ConflictDetectionService` imports `core/database/app_database.dart`** — domain service importing core DB type. Verify this is acceptable (it uses `show ParticipantEntry`)
3. **`SmartDivisionBuilderUseCase` injects `AppDatabase` directly** — bypasses repository pattern. May need to flag or document as accepted pattern
4. **`MergeDivisionsUseCase` imports `app_database.dart`** with `show ParticipantEntry` — same pattern as ConflictDetectionService
5. **`SplitDivisionUseCase` imports `app_database.dart`** with `show ParticipantEntry` — same pattern
6. **`DivisionEntity.syncVersion` defaults to `1`** while `TournamentEntity.syncVersion` defaults to `0`** — verify this inconsistency is intentional

### Architecture: Layer Rules

```
core/         → can import: only core/
domain/       → can import: core/ only (no data/, no presentation/)
data/         → can import: core/, domain/ (no presentation/)
presentation/ → can import: core/, domain/, data/ (via DI)
```

**Known intentional exception**: `app_router.dart` and `routes.dart` (in `core/router/`) import from `features/*/presentation/` because the router needs page widgets and auth state for guards.

### Architecture: Tournament Feature File Tree

```
lib/features/tournament/
├── tournament.dart                          # Barrel file
├── data/
│   ├── datasources/
│   │   ├── tournament_local_datasource.dart
│   │   └── tournament_remote_datasource.dart
│   ├── models/
│   │   ├── tournament_model.dart
│   │   ├── tournament_model.freezed.dart
│   │   └── tournament_model.g.dart
│   └── repositories/
│       └── tournament_repository_implementation.dart
├── domain/
│   ├── entities/
│   │   ├── tournament_entity.dart
│   │   └── tournament_entity.freezed.dart
│   ├── repositories/
│   │   └── tournament_repository.dart
│   └── usecases/
│       ├── archive_tournament_params.dart
│       ├── archive_tournament_usecase.dart
│       ├── create_tournament_params.dart
│       ├── create_tournament_usecase.dart
│       ├── delete_tournament_params.dart
│       ├── delete_tournament_usecase.dart
│       ├── duplicate_tournament_params.dart
│       ├── duplicate_tournament_usecase.dart
│       ├── get_tournament_usecase.dart
│       ├── get_tournaments_usecase.dart
│       ├── update_tournament_settings_params.dart
│       └── update_tournament_settings_usecase.dart
└── presentation/
    ├── bloc/
    │   ├── tournament_bloc.dart
    │   ├── tournament_event.dart  (+.freezed.dart)
    │   ├── tournament_state.dart  (+.freezed.dart)
    │   ├── tournament_detail_bloc.dart
    │   ├── tournament_detail_event.dart (+.freezed.dart)
    │   └── tournament_detail_state.dart (+.freezed.dart)
    ├── pages/
    │   ├── tournament_list_page.dart
    │   ├── tournament_detail_page.dart
    │   └── division_builder_wizard.dart
    └── widgets/
        ├── tournament_card.dart
        ├── tournament_form_dialog.dart
        ├── ring_assignment_widget.dart
        └── conflict_warning_banner.dart
```

### Architecture: Division Feature File Tree

```
lib/features/division/
├── data/
│   ├── datasources/
│   │   ├── division_local_datasource.dart
│   │   ├── division_remote_datasource.dart
│   │   ├── division_template_local_datasource.dart
│   │   └── division_template_remote_datasource.dart
│   ├── models/
│   │   ├── division_model.dart (+.freezed.dart, +.g.dart)
│   │   └── division_template_model.dart (+.freezed.dart, +.g.dart)
│   └── repositories/
│       ├── division_repository_implementation.dart
│       └── division_template_repository_implementation.dart
├── domain/
│   ├── entities/
│   │   ├── division_entity.dart (+.freezed.dart)
│   │   ├── division_template.dart (+.freezed.dart, +.g.dart)
│   │   ├── conflict_warning.dart (+.freezed.dart, +.g.dart)
│   │   └── scoring_method.dart
│   ├── repositories/
│   │   ├── division_repository.dart
│   │   └── division_template_repository.dart
│   ├── services/
│   │   └── conflict_detection_service.dart
│   └── usecases/
│       ├── assign_to_ring_params.dart (+.freezed.dart, +.g.dart)
│       ├── assign_to_ring_usecase.dart
│       ├── create_custom_division_params.dart (+.freezed.dart, +.g.dart)
│       ├── create_custom_division_usecase.dart
│       ├── get_divisions_usecase.dart
│       ├── merge_divisions_params.dart (+.freezed.dart, +.g.dart)
│       ├── merge_divisions_usecase.dart
│       ├── smart_division_builder_params.dart (+.freezed.dart)
│       ├── smart_division_builder_usecase.dart
│       ├── smart_division_naming_service.dart
│       ├── split_division_params.dart (+.freezed.dart, +.g.dart)
│       ├── split_division_usecase.dart
│       ├── update_custom_division_params.dart (+.freezed.dart, +.g.dart)
│       ├── update_custom_division_usecase.dart
│       └── apply_federation_template_params.dart (+.freezed.dart)
│           apply_federation_template_usecase.dart
└── services/
    └── federation_template_registry.dart
```

### Test File Tree (Epic 3 Scope)

```
test/features/tournament/
├── structure_test.dart
├── data/
│   ├── datasources/
│   │   ├── tournament_local_datasource_test.dart
│   │   └── tournament_remote_datasource_test.dart
│   ├── models/
│   │   └── tournament_model_test.dart
│   └── repositories/
│       └── tournament_repository_implementation_test.dart
├── domain/
│   ├── entities/
│   │   └── tournament_entity_test.dart
│   └── usecases/
│       ├── archive_tournament_usecase_test.dart
│       ├── create_tournament_usecase_test.dart
│       ├── delete_tournament_usecase_test.dart
│       ├── duplicate_tournament_usecase_test.dart
│       └── update_tournament_settings_usecase_test.dart
└── presentation/
    ├── bloc/
    │   ├── tournament_bloc_test.dart
    │   └── tournament_detail_bloc_test.dart
    └── pages/
        └── tournament_list_page_test.dart

test/features/division/
├── data/
│   └── repositories/
│       └── division_repository_implementation_test.dart
├── domain/
│   ├── entities/
│   │   └── division_entity_test.dart
│   └── usecases/
│       └── smart_division_builder_usecase_test.dart
├── services/
│   ├── conflict_detection_service_test.dart
│   └── federation_template_registry_test.dart
└── usecases/
    ├── assign_to_ring_usecase_test.dart
    ├── create_custom_division_usecase_test.dart
    ├── merge_divisions_usecase_test.dart
    ├── split_division_usecase_test.dart
    └── update_custom_division_usecase_test.dart
```

### Testing Patterns (Mandatory)

```dart
// === Mock pattern (mocktail) ===
class MockTournamentRepository extends Mock implements TournamentRepository {}
class MockDivisionRepository extends Mock implements DivisionRepository {}
class MockDivisionTemplateRepository extends Mock implements DivisionTemplateRepository {}
class MockConflictDetectionService extends Mock implements ConflictDetectionService {}
class MockFederationTemplateRegistry extends Mock implements FederationTemplateRegistry {}

// === BLoC test pattern ===
class MockTournamentBloc extends MockBloc<TournamentEvent, TournamentState>
    implements TournamentBloc {}
class MockTournamentDetailBloc
    extends MockBloc<TournamentDetailEvent, TournamentDetailState>
    implements TournamentDetailBloc {}

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

### Previous Code Review Learnings (from 1-13 and 2-12)

1. **Cross-layer imports are the most common violation** — Domain must never import from data. Use abstract interfaces in domain, implementations in data.
2. **Field naming inconsistencies** — Always verify field names match actual entity definitions (e.g., `assignedRingNumber` not `ringNumber`, `numberOfRings` not `ringCount`).
3. **`dart analyze` must be clean** — Fix ALL warnings, including unused imports in test files.
4. **Barrel file completeness matters** — Missing exports cause DI registration failures.
5. **Stale comments** — Update comments that reference "future Story X" if that story is now complete.
6. **Either pattern enforcement** — No raw exceptions should escape use cases. All errors mapped to `Failure` types.
7. **Build runner must be run** after any changes to freezed/injectable files: `dart run build_runner build --delete-conflicting-outputs`

### References

- [Source: epics.md#Story-3.15](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/_bmad-output/planning-artifacts/epics.md) — Story AC and user story statement
- [Source: 3-14-tournament-management-ui.md](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/_bmad-output/implementation-artifacts/3-14-tournament-management-ui.md) — Previous story (UI implementation)
- [Source: 2-12-code-review-and-fix-authentication.md](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/_bmad-output/implementation-artifacts/2-12-code-review-and-fix-authentication.md) — Code review pattern reference
- [Source: 1-13-code-review-and-fix-foundation.md](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/_bmad-output/implementation-artifacts/1-13-code-review-and-fix-foundation.md) — Code review pattern reference
- [Source: tournament.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/features/tournament/tournament.dart) — Tournament barrel file
- [Source: tournament_entity.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/features/tournament/domain/entities/tournament_entity.dart) — Tournament entity
- [Source: division_entity.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/features/division/domain/entities/division_entity.dart) — Division entity
- [Source: conflict_detection_service.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/features/division/domain/services/conflict_detection_service.dart) — Conflict detection
- [Source: federation_template_registry.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/features/division/services/federation_template_registry.dart) — Federation templates
- [Source: app_router.dart](file:///Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/lib/core/router/app_router.dart) — Router configuration

---

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4 (Antigravity)

### Debug Log References

### Completion Notes List

- **H1 FIXED**: `updateTournament` and `updateDivision` repos were returning stale input entity instead of the persisted entity with updated syncVersion. Changed to `return Right(model.convertToEntity())`.
- **H3 FIXED**: 3 `sync_service_test.dart` pull tests failing because mocks didn't stub `tournaments` and `divisions` table queries (added after Epic 3 extended `_syncableTables`). Added mock stubs for all 4 tables.
- **M1 FIXED**: `mergeDivisions` and `splitDivision` remote sync failure catch blocks were empty (no `_queueDivisionSync` calls). Added proper queue-for-sync calls.
- **M2 FIXED**: `updateParticipants` in `DivisionLocalDatasource` was double-incrementing syncVersion (callers already incremented). Removed the extra `+1`.
- **H2 DOCUMENTED**: `DivisionRepository` domain interface imports `app_database.dart` for `ParticipantEntry` — flagged as accepted tech debt for Epic 4 refactor.
- **M3 DOCUMENTED**: `getParticipantsForDivisions` N+1 query pattern — low-priority perf optimization.
- **M4 VERIFIED**: Division barrel file exists with proper exports; presentation dir is new/empty.
- **L1 DOCUMENTED**: `DivisionEntity.syncVersion` defaults to 1 vs `TournamentEntity.syncVersion` defaults to 0 — intentional per entity design.
- **L2 DOCUMENTED**: TODO comment for Epic 5 bracket soft-delete in merge/split — tracked in backlog.
- `dart analyze .` — zero issues ✅
- `flutter test` — 1596 tests pass, 0 failures ✅

### File List

- `lib/features/tournament/data/repositories/tournament_repository_implementation.dart` — Fixed stale entity return in updateTournament
- `lib/features/division/data/repositories/division_repository_implementation.dart` — Fixed stale entity return in updateDivision + added sync queue calls in merge/split
- `lib/features/division/data/datasources/division_local_datasource.dart` — Fixed double syncVersion increment in updateParticipants
- `test/core/sync/sync_service_test.dart` — Fixed 3 failing pull tests (added tournament/division table mocks)
