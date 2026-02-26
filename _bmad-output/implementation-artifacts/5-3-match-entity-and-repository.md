# Story 5.3: Match Entity & Repository

Status: done

**Created:** 2026-02-25

**Epic:** 5 - Bracket Generation & Seeding

**FRs Covered:** FR23-FR32 (foundational entity & repository for match tracking within brackets)

**Dependencies:** Story 5.2 (Bracket Entity & Repository) - COMPLETE | Story 5.1 (Bracket Feature Structure) - COMPLETE | Epic 4 (Participant) - COMPLETE

---

## TL;DR — Critical Facts

**CURRENT STATE:**
- The `bracket` feature structure exists with entity, model, datasources, repository (from Story 5.2)
- No match-related code exists yet — this story creates ALL match files from scratch
- Schema is currently at version 6 — bumps to version 7
- Barrel file currently has 6 exports — will have 12 after this story
- AppDatabase currently has brackets CRUD — will add matches CRUD after brackets section

**ARCHITECTURE SCHEMA vs EPIC AC — CRITICAL RECONCILIATION:**

| Epic AC Field     | Architecture Schema Column    | Resolution                                                                         |
| ----------------- | ----------------------------- | ---------------------------------------------------------------------------------- |
| `positionInRound` | `match_number_in_round`       | Use `matchNumberInRound` — architecture is source of truth                         |
| `participant1Id`  | `participant_red_id`          | Use `participantRedId` — TKD uses red/blue corner naming                           |
| `participant2Id`  | `participant_blue_id`         | Use `participantBlueId` — matches TKD scoring convention                           |
| `nextMatchId`     | `winner_advances_to_match_id` | Use `winnerAdvancesToMatchId` — architecture has both winner AND loser advancement |
| `nextMatchSlot`   | `loser_advances_to_match_id`  | Use `loserAdvancesToMatchId` — for double elimination                              |
| `isBye`           | (not a column)                | Byes are tracked via `result_type = 'bye'` — NO `isBye` column                     |
| `matchNumber`     | `match_number_in_round`       | Same as `positionInRound` — use singular `matchNumberInRound`                      |

**⚠️ ARCHITECTURE IS THE SOURCE OF TRUTH — NOT THE EPIC SUMMARY.**

---

## Story

As a developer,
I want the Match entity and repository implemented,
so that match tree structure and progression can be tracked.

## Acceptance Criteria

1. `MatchEntity` is a freezed class containing ALL fields from architecture schema: `id`, `bracketId`, `roundNumber`, `matchNumberInRound`, `participantRedId`, `participantBlueId`, `winnerId`, `winnerAdvancesToMatchId`, `loserAdvancesToMatchId`, `scheduledRingNumber`, `scheduledTime`, `status`, `resultType`, `notes`, `startedAtTimestamp`, `completedAtTimestamp`, `createdAtTimestamp`, `updatedAtTimestamp`, `syncVersion`, `isDeleted`, `deletedAtTimestamp`, `isDemoData`
2. `MatchStatus` enum is defined with values: `pending`, `ready`, `inProgress`, `completed`, `cancelled` — each with string `.value` property and `fromString()` static method
3. `MatchResultType` enum is defined with values: `points`, `knockout`, `disqualification`, `withdrawal`, `refereeDecision`, `bye` — each with string `.value` property and `fromString()` static method
4. `matches` Drift table is created at `lib/core/database/tables/matches_table.dart` with `@DataClassName('MatchEntry')`, extending `Table with BaseSyncMixin, BaseAuditMixin`
5. Self-referential FKs work correctly: `winner_advances_to_match_id` and `loser_advances_to_match_id` both reference `Matches.id` as nullable columns
6. `MatchModel` is a freezed class with JSON serialization (`fromJson`/`toJson` with snake_case `@JsonKey`), Drift conversion (`fromDriftEntry`/`toDriftCompanion`), and entity conversion (`convertToEntity`/`convertFromEntity`)
7. `MatchLocalDatasource` interface and implementation provide CRUD operations through `AppDatabase`
8. `MatchRemoteDatasource` interface and stub implementation exist (throws `UnimplementedError`)
9. `MatchRepository` abstract interface is defined in domain layer returning `Either<Failure, T>`
10. `MatchRepositoryImplementation` implements local-first with remote sync attempt pattern (matches bracket repository pattern exactly)
11. `AppDatabase` is updated: `Matches` added to tables list, schema version incremented to 7, migration added, Matches CRUD methods added, `clearDemoData` updated
12. Unit tests exist for entity (including enum tests), model (JSON/Drift/entity conversions), local datasource (mocked DB), and repository (mocked deps with offline/online scenarios)
13. All existing tests continue to pass (no regressions)
14. `flutter analyze` produces zero new issues
15. Code generation (`build_runner`) succeeds
16. Barrel file updated with 6 new exports (total: 12)
17. Structure test updated to expect 12 exports
18. Database test schema version updated to expect 7
19. Repository includes bracket-context queries: `getMatchesForBracket`, `getMatchesForRound`

---

## Tasks / Subtasks (Compact View)

- [ ] Task 1: Create Drift table `matches_table.dart` (AC: #4, #5)
- [ ] Task 2: Update `tables.dart` barrel with matches export (AC: #4)
- [ ] Task 3: Create `MatchEntity` + `MatchStatus` + `MatchResultType` enums (AC: #1, #2, #3)
- [ ] Task 4: Create `MatchModel` with all conversions (AC: #6)
- [ ] Task 5: Create `MatchLocalDatasource` interface + impl (AC: #7)
- [ ] Task 6: Create `MatchRemoteDatasource` interface + stub (AC: #8)
- [ ] Task 7: Create `MatchRepository` interface (AC: #9)
- [ ] Task 8: Create `MatchRepositoryImplementation` (AC: #10, #19)
- [ ] Task 9: Update `AppDatabase` — tables, schema v7, migration, CRUD, clearDemoData (AC: #11)
- [ ] Task 10: Update `bracket.dart` barrel file (AC: #16)
- [ ] Task 11: Update `structure_test.dart` export count (AC: #17)
- [ ] Task 12: Run code generation (AC: #15)
- [ ] Task 13: Create all tests (AC: #12)
- [ ] Task 14: Verify project integrity (AC: #13, #14, #18)

---

## Tasks / Subtasks (Detailed View)

### Task 1: Create Drift Table (AC: #4, #5)

- [ ] 1.1: Create `lib/core/database/tables/matches_table.dart`
- [ ] 1.2: Use `@DataClassName('MatchEntry')` annotation
- [ ] 1.3: Extend `Table with BaseSyncMixin, BaseAuditMixin`
- [ ] 1.4: Define all columns matching architecture schema exactly
- [ ] 1.5: Self-referential FKs: `text().named('winner_advances_to_match_id').nullable().references(Matches, #id)()`
- [ ] 1.6: FK to brackets: `text().named('bracket_id').references(Brackets, #id)()`
- [ ] 1.7: FK to participants (nullable): no `.references()` — use plain `text().nullable()` to avoid circular import issues; FK enforced by schema, not Drift references
- [ ] 1.8: Set `@override Set<Column> get primaryKey => {id};`

### Task 2: Update Tables Barrel (AC: #4)

- [ ] 2.1: Add `export 'matches_table.dart';` to `lib/core/database/tables/tables.dart` in alphabetical order (between `invitations_table.dart` and `organizations_table.dart`)

### Task 3: Create MatchEntity + Enums (AC: #1, #2, #3)

- [ ] 3.1: Create `lib/features/bracket/domain/entities/match_entity.dart`
- [ ] 3.2: Define `MatchStatus` enum with `fromString()` and `.value`:
  ```dart
  enum MatchStatus {
    pending('pending'),
    ready('ready'),
    inProgress('in_progress'),
    completed('completed'),
    cancelled('cancelled');
    const MatchStatus(this.value);
    final String value;
    static MatchStatus fromString(String value) {
      return MatchStatus.values.firstWhere(
        (s) => s.value == value,
        orElse: () => MatchStatus.pending,
      );
    }
  }
  ```
- [ ] 3.3: Define `MatchResultType` enum with `fromString()` and `.value`:
  ```dart
  enum MatchResultType {
    points('points'),
    knockout('knockout'),
    disqualification('disqualification'),
    withdrawal('withdrawal'),
    refereeDecision('referee_decision'),
    bye('bye');
    const MatchResultType(this.value);
    final String value;
    static MatchResultType fromString(String value) {
      return MatchResultType.values.firstWhere(
        (r) => r.value == value,
        orElse: () => MatchResultType.points,
      );
    }
  }
  ```
- [ ] 3.4: Define `MatchEntity` freezed class with ALL fields, correct defaults:
  - `status` defaults to `MatchStatus.pending`
  - `syncVersion` defaults to `1`
  - `isDeleted` defaults to `false`
  - `isDemoData` defaults to `false`
  - `participantRedId`, `participantBlueId`, `winnerId` all nullable
  - `winnerAdvancesToMatchId`, `loserAdvancesToMatchId` nullable
  - `scheduledRingNumber` nullable int
  - `scheduledTime` nullable DateTime
  - `resultType` nullable MatchResultType
  - `notes` nullable String
  - `startedAtTimestamp`, `completedAtTimestamp`, `deletedAtTimestamp` nullable DateTime
- [ ] 3.5: Add `const MatchEntity._();` for freezed custom methods
- [ ] 3.6: Add `part 'match_entity.freezed.dart';` directive
- [ ] 3.7: ONLY import `freezed_annotation` — no data layer imports in domain

### Task 4: Create MatchModel (AC: #6)

- [ ] 4.1: Create `lib/features/bracket/data/models/match_model.dart`
- [ ] 4.2: Add `// ignore_for_file: invalid_annotation_target` at top
- [ ] 4.3: Import `drift` with `hide JsonKey`: `import 'package:drift/drift.dart' hide JsonKey;`
- [ ] 4.4: Import `freezed_annotation`, `app_database.dart`, and `match_entity.dart`
- [ ] 4.5: Add `part 'match_model.freezed.dart';` and `part 'match_model.g.dart';`
- [ ] 4.6: Define freezed class with `@JsonKey(name: 'snake_case')` on ALL camelCase fields
- [ ] 4.7: Model stores enums as `String` (not enum types): `status` as `String`, `resultType` as `String?`
- [ ] 4.8: Implement `factory MatchModel.fromJson(Map<String, dynamic> json)`
- [ ] 4.9: Implement `factory MatchModel.fromDriftEntry(MatchEntry entry)` — map all fields
- [ ] 4.10: Implement `factory MatchModel.convertFromEntity(MatchEntity entity)`:
  - `entity.status.value` converts enum → string
  - `entity.resultType?.value` converts nullable enum → nullable string
- [ ] 4.11: Implement `MatchesCompanion toDriftCompanion()` — use `Value()` wrappers for optional/default fields
- [ ] 4.12: Implement `MatchEntity convertToEntity()`:
  - `MatchStatus.fromString(status)` converts string → enum
  - `resultType != null ? MatchResultType.fromString(resultType!) : null` converts nullable string → nullable enum

### Task 5: Create MatchLocalDatasource (AC: #7)

- [ ] 5.1: Create `lib/features/bracket/data/datasources/match_local_datasource.dart`
- [ ] 5.2: Define abstract class with methods:
  - `getMatchesForBracket(String bracketId)` → `Future<List<MatchModel>>`
  - `getMatchesForRound(String bracketId, int roundNumber)` → `Future<List<MatchModel>>`
  - `getMatchById(String id)` → `Future<MatchModel?>`
  - `insertMatch(MatchModel match)` → `Future<void>`
  - `updateMatch(MatchModel match)` → `Future<void>`
  - `deleteMatch(String id)` → `Future<void>`
- [ ] 5.3: Implement `@LazySingleton(as: MatchLocalDatasource)` class using `AppDatabase`
- [ ] 5.4: All query methods convert `MatchEntry` → `MatchModel` via `MatchModel.fromDriftEntry`

### Task 6: Create MatchRemoteDatasource (AC: #8)

- [ ] 6.1: Create `lib/features/bracket/data/datasources/match_remote_datasource.dart`
- [ ] 6.2: Define abstract class with same method signatures as local datasource
- [ ] 6.3: Implement stub with `@LazySingleton(as: MatchRemoteDatasource)` — all methods throw `UnimplementedError('Supabase match sync not yet implemented')`

### Task 7: Create MatchRepository Interface (AC: #9)

- [ ] 7.1: Create `lib/features/bracket/domain/repositories/match_repository.dart`
- [ ] 7.2: Define abstract class with methods:
  - `getMatchesForBracket(String bracketId)` → `Future<Either<Failure, List<MatchEntity>>>`
  - `getMatchesForRound(String bracketId, int roundNumber)` → `Future<Either<Failure, List<MatchEntity>>>`
  - `getMatchById(String id)` → `Future<Either<Failure, MatchEntity>>`
  - `createMatch(MatchEntity match)` → `Future<Either<Failure, MatchEntity>>`
  - `updateMatch(MatchEntity match)` → `Future<Either<Failure, MatchEntity>>`
  - `deleteMatch(String id)` → `Future<Either<Failure, Unit>>`
- [ ] 7.3: ONLY import `fpdart`, `failures.dart`, `match_entity.dart` — NO data layer imports

### Task 8: Create MatchRepositoryImplementation (AC: #10, #19)

- [ ] 8.1: Create `lib/features/bracket/data/repositories/match_repository_implementation.dart`
- [ ] 8.2: Use `@LazySingleton(as: MatchRepository)` annotation
- [ ] 8.3: Inject 4 dependencies: `MatchLocalDatasource`, `MatchRemoteDatasource`, `ConnectivityService`, `AppDatabase`
- [ ] 8.4: Follow EXACT same patterns as `BracketRepositoryImplementation`:
  - `getMatchesForBracket`: local only → `Right(entities)` or `Left(LocalCacheAccessFailure)`
  - `getMatchesForRound`: local only → `Right(entities)` or `Left(LocalCacheAccessFailure)`
  - `getMatchById`: local first → remote fallback if online → `Left(NotFoundFailure)` if nowhere
  - `createMatch`: local insert → remote attempt if online → `Right(entity)` or `Left(LocalCacheWriteFailure)`
  - `updateMatch`: increment syncVersion → local update → remote attempt → `Right(updatedEntity)` or `Left(LocalCacheWriteFailure)`
  - `deleteMatch`: local soft delete → remote attempt → `Right(unit)` or `Left(LocalCacheWriteFailure)`

### Task 9: Update AppDatabase (AC: #11)

- [ ] 9.1: Add `Matches,` to `@DriftDatabase(tables: [...])` list — insert AFTER `Brackets,` and BEFORE `Invitations,`
- [ ] 9.2: Change `int get schemaVersion => 6;` to `int get schemaVersion => 7;`
- [ ] 9.3: Add migration block inside `onUpgrade` AFTER the `if (from < 6)` block:
  ```dart
  // Version 7: Add matches table for match tracking within brackets
  if (from < 7) {
    await m.createTable(matches);
  }
  ```
- [ ] 9.4: Add Matches CRUD section AFTER Brackets CRUD section (after `getActiveBrackets` method, BEFORE `// Invitations CRUD` comment):
  ```dart
  // Matches CRUD:
  // - getMatchesForBracket(bracketId) ordered by roundNumber, matchNumberInRound
  // - getMatchesByRound(bracketId, roundNumber) ordered by matchNumberInRound
  // - getMatchById(id)
  // - insertMatch(companion)
  // - updateMatch(id, companion) with syncVersion increment in transaction
  // - softDeleteMatch(id)
  // - getActiveMatches() — for testing
  ```
- [ ] 9.5: In `clearDemoData()`, add `await (delete(matches)..where((m) => m.isDemoData.equals(true))).go();` BEFORE the brackets delete line (reverse FK order: matches → brackets → participants → ...)

### Task 10: Update Barrel File (AC: #16)

- [ ] 10.1: Add 6 new match exports to `lib/features/bracket/bracket.dart` — organize under existing section comments like the current bracket exports.

**COMPLETE resulting file `lib/features/bracket/bracket.dart`:**
```dart
/// Bracket feature - exports public APIs.
library;

// Data exports
export 'data/datasources/bracket_local_datasource.dart';
export 'data/datasources/bracket_remote_datasource.dart';
export 'data/datasources/match_local_datasource.dart';
export 'data/datasources/match_remote_datasource.dart';
export 'data/models/bracket_model.dart';
export 'data/models/match_model.dart';
export 'data/repositories/bracket_repository_implementation.dart';
export 'data/repositories/match_repository_implementation.dart';

// Domain exports
export 'domain/entities/bracket_entity.dart';
export 'domain/entities/match_entity.dart';
export 'domain/repositories/bracket_repository.dart';
export 'domain/repositories/match_repository.dart';

// Presentation exports
```

### Task 11: Update Structure Test (AC: #17)

- [ ] 11.1: Update `test/features/bracket/structure_test.dart` — change export count from 6 to 12:
  ```dart
  expect(matches.length, 12, reason: 'Barrel file should have twelve exports for bracket & match entity & repo');
  ```

### Task 12: Run Code Generation (AC: #15)

**⚠️ IMPORTANT: Tasks 1-11 WILL produce compile errors because Drift/Freezed generated code does not exist yet. This is NORMAL for Drift+Freezed workflow. Do NOT panic or start debugging — just run code gen here.**

- [ ] 12.1: Run `dart run build_runner build --delete-conflicting-outputs` from `tkd_brackets/`
- [ ] 12.2: Verify ALL of these generated files exist after code gen:
  - `lib/features/bracket/domain/entities/match_entity.freezed.dart` ← freezed equality/copyWith
  - `lib/features/bracket/data/models/match_model.freezed.dart` ← freezed equality/copyWith
  - `lib/features/bracket/data/models/match_model.g.dart` ← JSON fromJson/toJson
  - `lib/core/database/app_database.g.dart` ← regenerated with Matches table, MatchEntry, MatchesCompanion
  - `lib/core/di/injection.config.dart` ← regenerated with MatchLocalDatasource, MatchRemoteDatasource, MatchRepository DI registrations
- [ ] 12.3: After code gen, ALL compile errors from Tasks 1-11 should resolve. If any remain, it's a real bug — fix it.

### Task 13: Create Tests (AC: #12)

- [ ] 13.1: Create `test/features/bracket/domain/entities/match_entity_test.dart`
  - Test entity creation with all required fields
  - Test default values: `status=MatchStatus.pending`, `syncVersion=1`, `isDeleted=false`, `isDemoData=false`
  - Test entity creation with all optional fields (nullable participants, advancement refs, timestamps, notes)
  - Test equality (same fields → equal, different fields → not equal)
  - Test `MatchStatus.fromString()` for 'pending', 'ready', 'in_progress', 'completed', 'cancelled'
  - Test `MatchStatus.fromString()` with unknown value → defaults to `pending`
  - Test `MatchStatus` enum `.value` property returns correct strings
  - Test `MatchResultType.fromString()` for 'points', 'knockout', 'disqualification', 'withdrawal', 'referee_decision', 'bye'
  - Test `MatchResultType.fromString()` with unknown value → defaults to `points`
  - Test `MatchResultType` enum `.value` property returns correct strings

- [ ] 13.2: Create `test/features/bracket/data/models/match_model_test.dart`
  - Test `fromJson` with full JSON including snake_case keys
  - Test `toJson` produces snake_case keys
  - Test `fromDriftEntry` converts all fields correctly
  - Test `convertToEntity` converts `String status` → `MatchStatus` enum
  - Test `convertToEntity` converts `String? resultType` → `MatchResultType?` enum
  - Test `convertToEntity` with `null` resultType → `null` in entity
  - Test `convertFromEntity` converts `MatchStatus` enum → string
  - Test `convertFromEntity` converts `MatchResultType?` enum → string?
  - Test `convertFromEntity` with `null` resultType → `null` in model
  - Test `toDriftCompanion` produces correct companion with `Value()` wrappers

- [ ] 13.3: Create `test/features/bracket/data/datasources/match_local_datasource_test.dart`
  - Mock `AppDatabase` with mocktail
  - **IMPORTANT:** Add `registerFallbackValue(const MatchesCompanion());` in `setUpAll` — required for `any()` matchers on companion parameters (same pattern as bracket_local_datasource_test.dart line 17)
  - Test `getMatchesForBracket` calls DB and converts entries to models
  - Test `getMatchesForRound` calls DB with bracketId and roundNumber
  - Test `getMatchById` returns model when found, null when not found
  - Test `insertMatch` calls `_database.insertMatch` with companion
  - Test `updateMatch` calls `_database.updateMatch` with id and companion
  - Test `deleteMatch` calls `_database.softDeleteMatch`

- [ ] 13.4: Create `test/features/bracket/data/repositories/match_repository_implementation_test.dart`
  - Mock all 4 deps: `MatchLocalDatasource`, `MatchRemoteDatasource`, `ConnectivityService`, `AppDatabase`
  - Use `registerFallbackValue(testModel)` and `registerFallbackValue(testEntity)` in `setUpAll`
  - **getMatchesForBracket:** test returns `Right` with list when offline; test returns `Left(LocalCacheAccessFailure)` on exception
  - **getMatchesForRound:** test returns `Right` with list when offline; test returns `Left(LocalCacheAccessFailure)` on exception
  - **getMatchById:** test returns `Right` when found locally; test returns `Left(NotFoundFailure)` when not found locally and offline; test returns `Right` when found remotely (caches locally)
  - **createMatch:** test returns `Right` when offline (local insert only); test returns `Left(LocalCacheWriteFailure)` on exception
  - **updateMatch:** test returns `Right` with incremented syncVersion; test verifies local update called
  - **deleteMatch:** test returns `Right(unit)` when offline; test returns `Left(LocalCacheWriteFailure)` on exception

### Task 14: Verify Project Integrity (AC: #13, #14, #18)

- [ ] 14.1: Run `flutter analyze` from `tkd_brackets/` — zero new issues
- [ ] 14.2: Run `dart run build_runner build --delete-conflicting-outputs` — succeeds (already done in Task 12, but re-run if you made any fixes)
- [ ] 14.3: Run ALL bracket tests: `flutter test test/features/bracket/`
- [ ] 14.4: Run full test suite: `flutter test` — all pass, no regressions
- [ ] 14.5: Verify structure test still passes: `flutter test test/features/bracket/structure_test.dart`
- [ ] 14.6: Update `test/core/database/app_database_test.dart` — find the line `expect(database.schemaVersion, 6)` and change `6` to `7`. This is currently at approximately line 23 of the test file. **IMPORTANT:** The test ALREADY EXISTS — you are ONLY changing the expected version number, NOT creating a new test.
- [ ] 14.7: Run the database test to verify: `flutter test test/core/database/app_database_test.dart`

---

## Dev Notes

### Drift Table Pattern (from brackets_table.dart)

- `@DataClassName('MatchEntry')` — generates `MatchEntry` data class and `MatchesCompanion`
- `extends Table with BaseSyncMixin, BaseAuditMixin` — adds sync + audit columns
- **IMPORT REQUIRED:** `import 'package:tkd_brackets/core/database/tables/brackets_table.dart';` — needed for `references(Brackets, #id)` on `bracketId` column (same pattern as brackets_table.dart importing divisions_table.dart)
- **IMPORT REQUIRED:** `import 'package:tkd_brackets/core/database/tables/base_tables.dart';` — needed for `BaseSyncMixin` and `BaseAuditMixin`
- FK references: `text().named('bracket_id').references(Brackets, #id)()`
- Self-referential FK: `text().named('winner_advances_to_match_id').nullable().references(Matches, #id)()` — works because Drift resolves at code-gen time, NOT parse time
- Participant FKs: Use plain `text().named('participant_red_id').nullable()()` — avoid Drift references to `Participants` table to prevent import complexity; FK semantics enforced by business logic
- `@override Set<Column> get primaryKey => {id};`

### COMPLETE FILE: `lib/core/database/tables/matches_table.dart`

```dart
import 'package:drift/drift.dart';
import 'package:tkd_brackets/core/database/tables/base_tables.dart';
import 'package:tkd_brackets/core/database/tables/brackets_table.dart';

/// Matches table for tracking individual bout matchups within a bracket.
///
/// Each match belongs to a bracket and tracks:
/// - Position: round_number + match_number_in_round
/// - Participants: red/blue corner assignments (TKD convention)
/// - Result: winner, status, result_type
/// - Tree navigation: winner_advances_to / loser_advances_to (self-referential FKs)
///
/// Self-referential FKs enable bracket tree traversal:
/// ```
/// Round 1, Match 1 ──winner──→ Round 2, Match 1
/// Round 1, Match 2 ──winner──→ Round 2, Match 1
///                   ──loser──→ Losers Bracket Match X (double elim only)
/// ```
@DataClassName('MatchEntry')
class Matches extends Table with BaseSyncMixin, BaseAuditMixin {
  /// Primary key - UUID stored as TEXT.
  TextColumn get id => text()();

  /// Foreign key to brackets table.
  TextColumn get bracketId =>
      text().named('bracket_id').references(Brackets, #id)();

  /// Round number within the bracket (1-indexed).
  IntColumn get roundNumber => integer().named('round_number')();

  /// Match position within the round (1-indexed).
  IntColumn get matchNumberInRound =>
      integer().named('match_number_in_round')();

  /// Red corner participant (nullable - may not be assigned yet).
  TextColumn get participantRedId =>
      text().named('participant_red_id').nullable()();

  /// Blue corner participant (nullable - may not be assigned yet).
  TextColumn get participantBlueId =>
      text().named('participant_blue_id').nullable()();

  /// Winner of the match (nullable - set when match completes).
  TextColumn get winnerId => text().named('winner_id').nullable()();

  /// Self-referential FK: which match the winner advances to.
  TextColumn get winnerAdvancesToMatchId => text()
      .named('winner_advances_to_match_id')
      .nullable()
      .references(Matches, #id)();

  /// Self-referential FK: which match the loser goes to (double elim only).
  TextColumn get loserAdvancesToMatchId => text()
      .named('loser_advances_to_match_id')
      .nullable()
      .references(Matches, #id)();

  /// Scheduled ring number for this match (nullable).
  IntColumn get scheduledRingNumber =>
      integer().named('scheduled_ring_number').nullable()();

  /// Scheduled time for this match (nullable).
  DateTimeColumn get scheduledTime =>
      dateTime().named('scheduled_time').nullable()();

  /// Match lifecycle status: pending, ready, in_progress, completed, cancelled.
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  /// How the match was decided (nullable - set on completion).
  TextColumn get resultType => text().named('result_type').nullable()();

  /// Additional notes about the match.
  TextColumn get notes => text().nullable()();

  /// When the match started (nullable).
  DateTimeColumn get startedAtTimestamp =>
      dateTime().named('started_at_timestamp').nullable()();

  /// When the match completed (nullable).
  DateTimeColumn get completedAtTimestamp =>
      dateTime().named('completed_at_timestamp').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### AppDatabase Modification Checklist — EXACT LINE LOCATIONS

**⚠️ These are the ONLY modifications to app_database.dart:**

1. **Line 28-29**: Add `Matches,` to `@DriftDatabase(tables: [...])` list — insert AFTER `Brackets,` (line 28) and BEFORE `Invitations,` (line 29)
2. **Line 44**: Change `int get schemaVersion => 6;` to `int get schemaVersion => 7;`
3. **Line 73-74** (inside `onUpgrade`): Add migration block AFTER the `if (from < 6)` block:
   ```dart
   // Version 7: Add matches table for match tracking within brackets
   if (from < 7) {
     await m.createTable(matches);
   }
   ```
4. **After line 455** (after `getActiveBrackets` method, BEFORE `// Invitations CRUD` comment at line 457): Insert entire Matches CRUD section
5. **Line 611** (in `clearDemoData()`): Add `await (delete(matches)..where((m) => m.isDemoData.equals(true))).go();` BEFORE the brackets delete line

### AppDatabase — Matches CRUD Methods

```dart
// ─────────────────────────────────────────────────────────────────────────
// Matches CRUD
// ─────────────────────────────────────────────────────────────────────────

/// Get all active matches for a bracket, ordered by round and position.
Future<List<MatchEntry>> getMatchesForBracket(String bracketId) {
  return (select(matches)
        ..where((m) => m.bracketId.equals(bracketId))
        ..where((m) => m.isDeleted.equals(false))
        ..orderBy([
          (m) => OrderingTerm.asc(m.roundNumber),
          (m) => OrderingTerm.asc(m.matchNumberInRound),
        ]))
      .get();
}

/// Get matches for a specific round within a bracket.
Future<List<MatchEntry>> getMatchesByRound(String bracketId, int roundNumber) {
  return (select(matches)
        ..where((m) => m.bracketId.equals(bracketId))
        ..where((m) => m.roundNumber.equals(roundNumber))
        ..where((m) => m.isDeleted.equals(false))
        ..orderBy([(m) => OrderingTerm.asc(m.matchNumberInRound)]))
      .get();
}

/// Get match by ID.
Future<MatchEntry?> getMatchById(String id) {
  return (select(matches)..where((m) => m.id.equals(id))).getSingleOrNull();
}

/// Insert a new match.
Future<int> insertMatch(MatchesCompanion match) {
  return into(matches).insert(match);
}

/// Update a match and increment sync_version.
Future<bool> updateMatch(String id, MatchesCompanion match) async {
  return transaction(() async {
    final current = await getMatchById(id);
    if (current == null) return false;
    final rows = await (update(matches)..where((m) => m.id.equals(id)))
        .write(match.copyWith(
          syncVersion: Value(current.syncVersion + 1),
          updatedAtTimestamp: Value(DateTime.now()),
        ));
    return rows > 0;
  });
}

/// Soft delete a match.
Future<bool> softDeleteMatch(String id) {
  return (update(matches)..where((m) => m.id.equals(id)))
      .write(MatchesCompanion(
        isDeleted: const Value(true),
        deletedAtTimestamp: Value(DateTime.now()),
        updatedAtTimestamp: Value(DateTime.now()),
      ))
      .then((rows) => rows > 0);
}

/// Get all active matches (for testing).
Future<List<MatchEntry>> getActiveMatches() {
  return (select(matches)..where((m) => m.isDeleted.equals(false))).get();
}
```

### MatchStatus vs MatchResultType — CRITICAL DISTINCTION

| Enum              | Location            | Values                                                                           | Purpose                              |
| ----------------- | ------------------- | -------------------------------------------------------------------------------- | ------------------------------------ |
| `MatchStatus`     | `match_entity.dart` | `pending`, `ready`, `inProgress`, `completed`, `cancelled`                       | Current lifecycle state of the match |
| `MatchResultType` | `match_entity.dart` | `points`, `knockout`, `disqualification`, `withdrawal`, `refereeDecision`, `bye` | HOW the match was decided            |

A match starts as `pending`, moves to `ready` (participants assigned), then `inProgress`, then `completed` with a `resultType` indicating how it was won.

### isBye Handling — NO DEDICATED COLUMN

The architecture schema does NOT have an `is_bye` column on matches. Instead:
- A bye match has `status = 'completed'` and `result_type = 'bye'`
- The winner is pre-set as the non-bye participant
- Story 5.10 (Bye Assignment Algorithm) will handle this logic

### Self-Referential FK — How It Works

A match tree is built by linking matches together:
- `winner_advances_to_match_id` → the match the winner plays next
- `loser_advances_to_match_id` → the match the loser plays next (double elimination only)

```
Round 1, Match 1 ──winner──→ Round 2, Match 1
Round 1, Match 2 ──winner──→ Round 2, Match 1
                  ──loser──→ Losers Bracket Match X (double elim)
```

In Drift, this is a nullable TEXT column with `.references(Matches, #id)`.

### Test Data Setup

```dart
final testDateTime = DateTime(2026, 1, 15, 10, 30);

// Model test data
final testModel = MatchModel(
  id: 'match-1',
  bracketId: 'bracket-1',
  roundNumber: 1,
  matchNumberInRound: 1,
  status: 'pending',
  syncVersion: 1,
  isDeleted: false,
  isDemoData: false,
  createdAtTimestamp: testDateTime,
  updatedAtTimestamp: testDateTime,
);

// Model with optional fields
final testModelFull = MatchModel(
  id: 'match-1',
  bracketId: 'bracket-1',
  roundNumber: 1,
  matchNumberInRound: 1,
  participantRedId: 'participant-red-1',
  participantBlueId: 'participant-blue-1',
  winnerId: 'participant-red-1',
  winnerAdvancesToMatchId: 'match-next-1',
  loserAdvancesToMatchId: 'match-loser-1',
  scheduledRingNumber: 2,
  scheduledTime: testDateTime,
  status: 'completed',
  resultType: 'points',
  notes: 'Great match',
  startedAtTimestamp: testDateTime,
  completedAtTimestamp: testDateTime,
  syncVersion: 1,
  isDeleted: false,
  isDemoData: false,
  createdAtTimestamp: testDateTime,
  updatedAtTimestamp: testDateTime,
);

// Entity test data
final testEntity = MatchEntity(
  id: 'match-1',
  bracketId: 'bracket-1',
  roundNumber: 1,
  matchNumberInRound: 1,
  createdAtTimestamp: testDateTime,
  updatedAtTimestamp: testDateTime,
);

// Entity with optional fields
final testEntityFull = MatchEntity(
  id: 'match-1',
  bracketId: 'bracket-1',
  roundNumber: 1,
  matchNumberInRound: 1,
  participantRedId: 'participant-red-1',
  participantBlueId: 'participant-blue-1',
  winnerId: 'participant-red-1',
  winnerAdvancesToMatchId: 'match-next-1',
  loserAdvancesToMatchId: 'match-loser-1',
  scheduledRingNumber: 2,
  scheduledTime: testDateTime,
  status: MatchStatus.completed,
  resultType: MatchResultType.points,
  notes: 'Great match',
  startedAtTimestamp: testDateTime,
  completedAtTimestamp: testDateTime,
  createdAtTimestamp: testDateTime,
  updatedAtTimestamp: testDateTime,
);
```

### Testing Mocks (use mocktail)

```dart
class MockMatchLocalDatasource extends Mock implements MatchLocalDatasource {}
class MockMatchRemoteDatasource extends Mock implements MatchRemoteDatasource {}
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockAppDatabase extends Mock implements AppDatabase {}
```

### MatchEntry Test Data (for datasource tests that create Drift entries directly)

```dart
// MatchEntry is the Drift-generated data class from @DataClassName('MatchEntry')
// Used in datasource tests where we mock AppDatabase returning MatchEntry objects
final testMatchEntry = MatchEntry(
  id: 'match-1',
  bracketId: 'bracket-1',
  roundNumber: 1,
  matchNumberInRound: 1,
  status: 'pending',
  syncVersion: 1,
  isDeleted: false,
  isDemoData: false,
  createdAtTimestamp: testDateTime,
  updatedAtTimestamp: testDateTime,
);
```

### JSON Test Data (for model fromJson/toJson tests)

```dart
final testJson = {
  'id': 'match-1',
  'bracket_id': 'bracket-1',
  'round_number': 1,
  'match_number_in_round': 1,
  'status': 'pending',
  'sync_version': 1,
  'is_deleted': false,
  'is_demo_data': false,
  'created_at_timestamp': testDateTime.toIso8601String(),
  'updated_at_timestamp': testDateTime.toIso8601String(),
};

// Full JSON with ALL optional fields populated
final testJsonFull = {
  'id': 'match-1',
  'bracket_id': 'bracket-1',
  'round_number': 1,
  'match_number_in_round': 1,
  'participant_red_id': 'participant-red-1',
  'participant_blue_id': 'participant-blue-1',
  'winner_id': 'participant-red-1',
  'winner_advances_to_match_id': 'match-next-1',
  'loser_advances_to_match_id': 'match-loser-1',
  'scheduled_ring_number': 2,
  'scheduled_time': testDateTime.toIso8601String(),
  'status': 'completed',
  'result_type': 'points',
  'notes': 'Great match',
  'started_at_timestamp': testDateTime.toIso8601String(),
  'completed_at_timestamp': testDateTime.toIso8601String(),
  'sync_version': 1,
  'is_deleted': false,
  'deleted_at_timestamp': null,
  'is_demo_data': false,
  'created_at_timestamp': testDateTime.toIso8601String(),
  'updated_at_timestamp': testDateTime.toIso8601String(),
};
```

### COMPLETE FILE: `lib/features/bracket/domain/entities/match_entity.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_entity.freezed.dart';

@freezed
class MatchEntity with _$MatchEntity {
  const factory MatchEntity({
    required String id,
    required String bracketId,
    required int roundNumber,
    required int matchNumberInRound,
    required DateTime createdAtTimestamp,
    required DateTime updatedAtTimestamp,
    String? participantRedId,
    String? participantBlueId,
    String? winnerId,
    String? winnerAdvancesToMatchId,
    String? loserAdvancesToMatchId,
    int? scheduledRingNumber,
    DateTime? scheduledTime,
    @Default(MatchStatus.pending) MatchStatus status,
    MatchResultType? resultType,
    String? notes,
    DateTime? startedAtTimestamp,
    DateTime? completedAtTimestamp,
    @Default(1) int syncVersion,
    @Default(false) bool isDeleted,
    DateTime? deletedAtTimestamp,
    @Default(false) bool isDemoData,
  }) = _MatchEntity;

  const MatchEntity._();
}

/// Match lifecycle status.
enum MatchStatus {
  pending('pending'),
  ready('ready'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled');

  const MatchStatus(this.value);
  final String value;

  static MatchStatus fromString(String value) {
    return MatchStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => MatchStatus.pending,
    );
  }
}

/// How a match was decided.
enum MatchResultType {
  points('points'),
  knockout('knockout'),
  disqualification('disqualification'),
  withdrawal('withdrawal'),
  refereeDecision('referee_decision'),
  bye('bye');

  const MatchResultType(this.value);
  final String value;

  static MatchResultType fromString(String value) {
    return MatchResultType.values.firstWhere(
      (r) => r.value == value,
      orElse: () => MatchResultType.points,
    );
  }
}
```

### COMPLETE FILE: `lib/features/bracket/data/models/match_model.dart`

**⚠️ CRITICAL:** `MatchesCompanion.insert()` requires ONLY: `id`, `bracketId`, `roundNumber`, `matchNumberInRound`. ALL other fields are optional (nullable or have defaults) and MUST be wrapped in `Value()`.

```dart
// Freezed uses @JsonKey on constructor parameters which triggers this lint.
// This is the documented freezed pattern and works correctly with code gen.
// ignore_for_file: invalid_annotation_target

import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';

part 'match_model.freezed.dart';
part 'match_model.g.dart';

/// Data model for Match with JSON and database conversions.
@freezed
class MatchModel with _$MatchModel {
  const factory MatchModel({
    required String id,
    @JsonKey(name: 'bracket_id') required String bracketId,
    @JsonKey(name: 'round_number') required int roundNumber,
    @JsonKey(name: 'match_number_in_round') required int matchNumberInRound,
    @JsonKey(name: 'sync_version') required int syncVersion,
    @JsonKey(name: 'created_at_timestamp') required DateTime createdAtTimestamp,
    @JsonKey(name: 'updated_at_timestamp') required DateTime updatedAtTimestamp,
    @JsonKey(name: 'participant_red_id') String? participantRedId,
    @JsonKey(name: 'participant_blue_id') String? participantBlueId,
    @JsonKey(name: 'winner_id') String? winnerId,
    @JsonKey(name: 'winner_advances_to_match_id') String? winnerAdvancesToMatchId,
    @JsonKey(name: 'loser_advances_to_match_id') String? loserAdvancesToMatchId,
    @JsonKey(name: 'scheduled_ring_number') int? scheduledRingNumber,
    @JsonKey(name: 'scheduled_time') DateTime? scheduledTime,
    @Default('pending') String status,
    @JsonKey(name: 'result_type') String? resultType,
    String? notes,
    @JsonKey(name: 'started_at_timestamp') DateTime? startedAtTimestamp,
    @JsonKey(name: 'completed_at_timestamp') DateTime? completedAtTimestamp,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
    @JsonKey(name: 'deleted_at_timestamp') DateTime? deletedAtTimestamp,
    @JsonKey(name: 'is_demo_data') @Default(false) bool isDemoData,
  }) = _MatchModel;

  const MatchModel._();

  factory MatchModel.fromJson(Map<String, dynamic> json) =>
      _$MatchModelFromJson(json);

  /// Convert from Drift-generated [MatchEntry] to [MatchModel].
  factory MatchModel.fromDriftEntry(MatchEntry entry) {
    return MatchModel(
      id: entry.id,
      bracketId: entry.bracketId,
      roundNumber: entry.roundNumber,
      matchNumberInRound: entry.matchNumberInRound,
      participantRedId: entry.participantRedId,
      participantBlueId: entry.participantBlueId,
      winnerId: entry.winnerId,
      winnerAdvancesToMatchId: entry.winnerAdvancesToMatchId,
      loserAdvancesToMatchId: entry.loserAdvancesToMatchId,
      scheduledRingNumber: entry.scheduledRingNumber,
      scheduledTime: entry.scheduledTime,
      status: entry.status,
      resultType: entry.resultType,
      notes: entry.notes,
      startedAtTimestamp: entry.startedAtTimestamp,
      completedAtTimestamp: entry.completedAtTimestamp,
      syncVersion: entry.syncVersion,
      isDeleted: entry.isDeleted,
      deletedAtTimestamp: entry.deletedAtTimestamp,
      isDemoData: entry.isDemoData,
      createdAtTimestamp: entry.createdAtTimestamp,
      updatedAtTimestamp: entry.updatedAtTimestamp,
    );
  }

  /// Create [MatchModel] from domain [MatchEntity].
  factory MatchModel.convertFromEntity(MatchEntity entity) {
    return MatchModel(
      id: entity.id,
      bracketId: entity.bracketId,
      roundNumber: entity.roundNumber,
      matchNumberInRound: entity.matchNumberInRound,
      participantRedId: entity.participantRedId,
      participantBlueId: entity.participantBlueId,
      winnerId: entity.winnerId,
      winnerAdvancesToMatchId: entity.winnerAdvancesToMatchId,
      loserAdvancesToMatchId: entity.loserAdvancesToMatchId,
      scheduledRingNumber: entity.scheduledRingNumber,
      scheduledTime: entity.scheduledTime,
      status: entity.status.value,
      resultType: entity.resultType?.value,
      notes: entity.notes,
      startedAtTimestamp: entity.startedAtTimestamp,
      completedAtTimestamp: entity.completedAtTimestamp,
      syncVersion: entity.syncVersion,
      isDeleted: entity.isDeleted,
      deletedAtTimestamp: entity.deletedAtTimestamp,
      isDemoData: entity.isDemoData,
      createdAtTimestamp: entity.createdAtTimestamp,
      updatedAtTimestamp: entity.updatedAtTimestamp,
    );
  }

  /// Convert to Drift [MatchesCompanion] for database operations.
  /// ONLY id, bracketId, roundNumber, matchNumberInRound are required.
  /// ALL other fields use Value() wrappers (nullable or have defaults).
  MatchesCompanion toDriftCompanion() {
    return MatchesCompanion.insert(
      id: id,
      bracketId: bracketId,
      roundNumber: roundNumber,
      matchNumberInRound: matchNumberInRound,
      participantRedId: Value(participantRedId),
      participantBlueId: Value(participantBlueId),
      winnerId: Value(winnerId),
      winnerAdvancesToMatchId: Value(winnerAdvancesToMatchId),
      loserAdvancesToMatchId: Value(loserAdvancesToMatchId),
      scheduledRingNumber: Value(scheduledRingNumber),
      scheduledTime: Value(scheduledTime),
      status: Value(status),
      resultType: Value(resultType),
      notes: Value(notes),
      startedAtTimestamp: Value(startedAtTimestamp),
      completedAtTimestamp: Value(completedAtTimestamp),
      syncVersion: Value(syncVersion),
      isDeleted: Value(isDeleted),
      deletedAtTimestamp: Value(deletedAtTimestamp),
      isDemoData: Value(isDemoData),
    );
  }

  /// Convert [MatchModel] to domain [MatchEntity].
  MatchEntity convertToEntity() {
    return MatchEntity(
      id: id,
      bracketId: bracketId,
      roundNumber: roundNumber,
      matchNumberInRound: matchNumberInRound,
      participantRedId: participantRedId,
      participantBlueId: participantBlueId,
      winnerId: winnerId,
      winnerAdvancesToMatchId: winnerAdvancesToMatchId,
      loserAdvancesToMatchId: loserAdvancesToMatchId,
      scheduledRingNumber: scheduledRingNumber,
      scheduledTime: scheduledTime,
      status: MatchStatus.fromString(status),
      resultType:
          resultType != null ? MatchResultType.fromString(resultType!) : null,
      notes: notes,
      startedAtTimestamp: startedAtTimestamp,
      completedAtTimestamp: completedAtTimestamp,
      syncVersion: syncVersion,
      isDeleted: isDeleted,
      deletedAtTimestamp: deletedAtTimestamp,
      isDemoData: isDemoData,
      createdAtTimestamp: createdAtTimestamp,
      updatedAtTimestamp: updatedAtTimestamp,
    );
  }
}
```

### COMPLETE FILE: `lib/features/bracket/data/datasources/match_local_datasource.dart`

```dart
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/bracket/data/models/match_model.dart';

/// Local datasource for match operations (Drift/SQLite).
abstract class MatchLocalDatasource {
  Future<List<MatchModel>> getMatchesForBracket(String bracketId);
  Future<List<MatchModel>> getMatchesForRound(
    String bracketId,
    int roundNumber,
  );
  Future<MatchModel?> getMatchById(String id);
  Future<void> insertMatch(MatchModel match);
  Future<void> updateMatch(MatchModel match);
  Future<void> deleteMatch(String id);
}

@LazySingleton(as: MatchLocalDatasource)
class MatchLocalDatasourceImplementation implements MatchLocalDatasource {
  MatchLocalDatasourceImplementation(this._database);
  final AppDatabase _database;

  @override
  Future<List<MatchModel>> getMatchesForBracket(String bracketId) async {
    final entries = await _database.getMatchesForBracket(bracketId);
    return entries.map(MatchModel.fromDriftEntry).toList();
  }

  @override
  Future<List<MatchModel>> getMatchesForRound(
    String bracketId,
    int roundNumber,
  ) async {
    final entries = await _database.getMatchesByRound(bracketId, roundNumber);
    return entries.map(MatchModel.fromDriftEntry).toList();
  }

  @override
  Future<MatchModel?> getMatchById(String id) async {
    final entry = await _database.getMatchById(id);
    return entry != null ? MatchModel.fromDriftEntry(entry) : null;
  }

  @override
  Future<void> insertMatch(MatchModel match) async {
    await _database.insertMatch(match.toDriftCompanion());
  }

  @override
  Future<void> updateMatch(MatchModel match) async {
    await _database.updateMatch(match.id, match.toDriftCompanion());
  }

  @override
  Future<void> deleteMatch(String id) async {
    await _database.softDeleteMatch(id);
  }
}
```

### COMPLETE FILE: `lib/features/bracket/data/datasources/match_remote_datasource.dart`

```dart
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/bracket/data/models/match_model.dart';

/// Remote datasource for match operations (Supabase).
/// Stub implementation — Supabase sync not yet implemented.
abstract class MatchRemoteDatasource {
  Future<List<MatchModel>> getMatchesForBracket(String bracketId);
  Future<List<MatchModel>> getMatchesForRound(
    String bracketId,
    int roundNumber,
  );
  Future<MatchModel?> getMatchById(String id);
  Future<void> insertMatch(MatchModel match);
  Future<void> updateMatch(MatchModel match);
  Future<void> deleteMatch(String id);
}

@LazySingleton(as: MatchRemoteDatasource)
class MatchRemoteDatasourceImplementation implements MatchRemoteDatasource {
  @override
  Future<List<MatchModel>> getMatchesForBracket(String bracketId) async {
    throw UnimplementedError('Supabase match sync not yet implemented');
  }

  @override
  Future<List<MatchModel>> getMatchesForRound(
    String bracketId,
    int roundNumber,
  ) async {
    throw UnimplementedError('Supabase match sync not yet implemented');
  }

  @override
  Future<MatchModel?> getMatchById(String id) async {
    throw UnimplementedError('Supabase match sync not yet implemented');
  }

  @override
  Future<void> insertMatch(MatchModel match) async {
    throw UnimplementedError('Supabase match sync not yet implemented');
  }

  @override
  Future<void> updateMatch(MatchModel match) async {
    throw UnimplementedError('Supabase match sync not yet implemented');
  }

  @override
  Future<void> deleteMatch(String id) async {
    throw UnimplementedError('Supabase match sync not yet implemented');
  }
}
```

### COMPLETE FILE: `lib/features/bracket/domain/repositories/match_repository.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';

/// Repository interface for match operations.
abstract class MatchRepository {
  Future<Either<Failure, List<MatchEntity>>> getMatchesForBracket(
    String bracketId,
  );
  Future<Either<Failure, List<MatchEntity>>> getMatchesForRound(
    String bracketId,
    int roundNumber,
  );
  Future<Either<Failure, MatchEntity>> getMatchById(String id);
  Future<Either<Failure, MatchEntity>> createMatch(MatchEntity match);
  Future<Either<Failure, MatchEntity>> updateMatch(MatchEntity match);
  Future<Either<Failure, Unit>> deleteMatch(String id);
}
```

### COMPLETE FILE: `lib/features/bracket/data/repositories/match_repository_implementation.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/bracket/data/datasources/match_local_datasource.dart';
import 'package:tkd_brackets/features/bracket/data/datasources/match_remote_datasource.dart';
import 'package:tkd_brackets/features/bracket/data/models/match_model.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';

@LazySingleton(as: MatchRepository)
class MatchRepositoryImplementation implements MatchRepository {
  MatchRepositoryImplementation(
    this._localDatasource,
    this._remoteDatasource,
    this._connectivityService,
    this._database,
  );

  final MatchLocalDatasource _localDatasource;
  final MatchRemoteDatasource _remoteDatasource;
  final ConnectivityService _connectivityService;
  final AppDatabase _database;

  @override
  Future<Either<Failure, List<MatchEntity>>> getMatchesForBracket(
    String bracketId,
  ) async {
    try {
      final models = await _localDatasource.getMatchesForBracket(bracketId);
      return Right(models.map((m) => m.convertToEntity()).toList());
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(
        technicalDetails: 'Failed to get matches for bracket: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, List<MatchEntity>>> getMatchesForRound(
    String bracketId,
    int roundNumber,
  ) async {
    try {
      final models =
          await _localDatasource.getMatchesForRound(bracketId, roundNumber);
      return Right(models.map((m) => m.convertToEntity()).toList());
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(
        technicalDetails: 'Failed to get matches for round: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, MatchEntity>> getMatchById(String id) async {
    try {
      final model = await _localDatasource.getMatchById(id);
      if (model != null) return Right(model.convertToEntity());

      final hasConnection =
          await _connectivityService.hasInternetConnection();
      if (!hasConnection) {
        return const Left(NotFoundFailure(
          userFriendlyMessage: 'Match not found',
        ));
      }

      try {
        final remoteModel = await _remoteDatasource.getMatchById(id);
        if (remoteModel != null) {
          await _localDatasource.insertMatch(remoteModel);
          return Right(remoteModel.convertToEntity());
        }
      } on Object {
        // Remote fetch failed, return not found
      }

      return const Left(NotFoundFailure(
        userFriendlyMessage: 'Match not found',
      ));
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(
        technicalDetails: 'Failed to get match: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, MatchEntity>> createMatch(
    MatchEntity match,
  ) async {
    try {
      final model = MatchModel.convertFromEntity(match);
      await _localDatasource.insertMatch(model);

      final hasConnection =
          await _connectivityService.hasInternetConnection();
      if (hasConnection) {
        try {
          await _remoteDatasource.insertMatch(model);
        } on Object {
          // Remote insert failed, will sync later
        }
      }

      return Right(match);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(
        technicalDetails: 'Failed to create match: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, MatchEntity>> updateMatch(
    MatchEntity match,
  ) async {
    try {
      final existing = await _localDatasource.getMatchById(match.id);
      final newSyncVersion = (existing?.syncVersion ?? 0) + 1;

      final updatedEntity = match.copyWith(syncVersion: newSyncVersion);
      final model = MatchModel.convertFromEntity(updatedEntity);
      await _localDatasource.updateMatch(model);

      final hasConnection =
          await _connectivityService.hasInternetConnection();
      if (hasConnection) {
        try {
          await _remoteDatasource.updateMatch(model);
        } on Object {
          // Remote update failed, will sync later
        }
      }

      return Right(updatedEntity);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(
        technicalDetails: 'Failed to update match: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteMatch(String id) async {
    try {
      await _localDatasource.deleteMatch(id);

      final hasConnection =
          await _connectivityService.hasInternetConnection();
      if (hasConnection) {
        try {
          await _remoteDatasource.deleteMatch(id);
        } on Object {
          // Remote delete failed, will sync later
        }
      }

      return const Right(unit);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(
        technicalDetails: 'Failed to delete match: $e',
      ));
    }
  }
}
```

### File Structure After This Story

```
lib/core/database/tables/
├── matches_table.dart                                   ← NEW

lib/features/bracket/
├── bracket.dart                                         ← UPDATED barrel (12 exports)
├── README.md                                            ← Unchanged
├── data/
│   ├── datasources/
│   │   ├── bracket_local_datasource.dart
│   │   ├── bracket_remote_datasource.dart
│   │   ├── match_local_datasource.dart                  ← NEW
│   │   └── match_remote_datasource.dart                 ← NEW (stub)
│   ├── models/
│   │   ├── bracket_model.dart
│   │   ├── bracket_model.freezed.dart
│   │   ├── bracket_model.g.dart
│   │   ├── match_model.dart                             ← NEW
│   │   ├── match_model.freezed.dart                     ← GENERATED
│   │   └── match_model.g.dart                           ← GENERATED
│   └── repositories/
│       ├── bracket_repository_implementation.dart
│       └── match_repository_implementation.dart          ← NEW
├── domain/
│   ├── entities/
│   │   ├── bracket_entity.dart
│   │   ├── bracket_entity.freezed.dart
│   │   ├── match_entity.dart                            ← NEW
│   │   └── match_entity.freezed.dart                    ← GENERATED
│   ├── repositories/
│   │   ├── bracket_repository.dart
│   │   └── match_repository.dart                        ← NEW
│   └── usecases/                                        ← Empty (Story 5.4+)
└── presentation/                                        ← Empty (Story 5.13)

test/features/bracket/
├── structure_test.dart                                  ← UPDATED (12 exports)
├── data/
│   ├── datasources/
│   │   ├── bracket_local_datasource_test.dart
│   │   └── match_local_datasource_test.dart             ← NEW
│   ├── models/
│   │   ├── bracket_model_test.dart
│   │   └── match_model_test.dart                        ← NEW
│   └── repositories/
│       ├── bracket_repository_implementation_test.dart
│       └── match_repository_implementation_test.dart     ← NEW
└── domain/
    └── entities/
        ├── bracket_entity_test.dart
        └── match_entity_test.dart                       ← NEW
```

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 5, Story 5.3 (lines 1714-1728)]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Database Schema: matches table (lines 1488-1521)]
- [Source: `_bmad-output/implementation-artifacts/5-2-bracket-entity-and-repository.md` — Previous story context]
- [Source: `tkd_brackets/lib/core/database/tables/brackets_table.dart` — Drift table pattern]
- [Source: `tkd_brackets/lib/core/database/tables/base_tables.dart` — BaseSyncMixin/BaseAuditMixin]
- [Source: `tkd_brackets/lib/core/database/app_database.dart` — DB migration + CRUD pattern]
- [Source: `tkd_brackets/lib/features/bracket/` — Full entity/model/repo/datasource pattern]
- [Source: `tkd_brackets/lib/core/error/failures.dart` — Failure types]
- [Source: `tkd_brackets/lib/core/network/connectivity_service.dart` — ConnectivityService interface]

---

## Anti-Patterns — WHAT NOT TO DO

| ❌ Don't Do This                                                   | ✅ Do This Instead                                                                                                                                                                   | Source                  |
| ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------- |
| Use `participant1Id`/`participant2Id` field names                 | Use `participantRedId`/`participantBlueId` — TKD uses red/blue corners                                                                                                              | Architecture schema     |
| Use `nextMatchId`/`nextMatchSlot` field names                     | Use `winnerAdvancesToMatchId`/`loserAdvancesToMatchId`                                                                                                                              | Architecture schema     |
| Add `isBye` column to the Drift table                             | Use `resultType = 'bye'` — byes are a result type, not a column                                                                                                                     | Architecture schema     |
| Import `drift` or `supabase_flutter` in domain layer              | Domain only uses `fpdart`, `freezed`, core Dart                                                                                                                                     | Architecture doc        |
| Create matches table in `lib/features/bracket/`                   | Drift tables go in `core/database/tables/`                                                                                                                                          | Architecture boundary   |
| Use `@injectable` on repository (transient)                       | Use `@LazySingleton(as: MatchRepository)` (singleton)                                                                                                                               | Bracket pattern         |
| Skip `@JsonKey` on multi-word model fields                        | EVERY multi-word field needs `@JsonKey(name: 'snake_case')` — only `id` doesn't need one since camelCase == snake_case. See bracket_model.dart which has 13 `@JsonKey` annotations. | Bracket model pattern   |
| Use `CacheFailure` in repository                                  | Use `LocalCacheAccessFailure` / `LocalCacheWriteFailure` / `NotFoundFailure`                                                                                                        | failures.dart           |
| Skip updating `schemaVersion` in app_database                     | Increment to 7 and add migration step                                                                                                                                               | Drift migration pattern |
| Forget to add `Matches` to `clearDemoData()`                      | Add match delete BEFORE brackets delete (reverse FK order)                                                                                                                          | FK constraint safety    |
| Create `MatchType` enum for `matchType` field                     | There is NO `matchType` field — don't confuse with `BracketType`                                                                                                                    | Architecture schema     |
| Add `positionInRound` as separate field from `matchNumberInRound` | They're the same concept — use `matchNumberInRound` only                                                                                                                            | Architecture schema     |
| Use `.references(Participants, #id)` for participant FKs          | Use plain `text().nullable()()` — avoids import complexity with Participants                                                                                                        | Pragmatic approach      |
| Skip `// ignore_for_file: invalid_annotation_target`              | Add at top of model file for freezed `@JsonKey` lint                                                                                                                                | Bracket model pattern   |
| Import `package:drift/drift.dart` without hiding `JsonKey`        | Use `import 'package:drift/drift.dart' hide JsonKey;`                                                                                                                               | Bracket model pattern   |
| Forget to update `app_database_test.dart` schema version          | Change expectation: `expect(database.schemaVersion, 6)` → `7`                                                                                                                       | Drift migration         |
| Forget to update `structure_test.dart` export count               | Change assertion: `expect(matches.length, 6)` → `12`                                                                                                                                | Barrel file growth      |
| Store `MatchStatus`/`MatchResultType` as enums in `MatchModel`    | Model stores them as `String`/`String?` — only entity uses enum types                                                                                                               | Clean Architecture      |
| Forget `import 'package:drift/drift.dart'` in matches_table.dart  | Required for `TextColumn`, `IntColumn`, `Table`, `Constant`, etc.                                                                                                                   | Drift table pattern     |
| Use `MatchesCompanion()` (default constructor) for insert         | Use `MatchesCompanion.insert()` — it knows which fields are required vs optional                                                                                                    | Drift pattern           |
| Append barrel exports without section comments                    | Organize under `// Data exports` and `// Domain exports` sections                                                                                                                   | Barrel file convention  |

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### File List

**Created:**
- `lib/core/database/tables/matches_table.dart` — Drift table definition
- `lib/features/bracket/domain/entities/match_entity.dart` — MatchEntity + MatchStatus + MatchResultType enums
- `lib/features/bracket/data/models/match_model.dart` — MatchModel with JSON/Drift/Entity conversions
- `lib/features/bracket/data/datasources/match_local_datasource.dart` — Local datasource (Drift)
- `lib/features/bracket/data/datasources/match_remote_datasource.dart` — Remote datasource stub
- `lib/features/bracket/domain/repositories/match_repository.dart` — Repository interface
- `lib/features/bracket/data/repositories/match_repository_implementation.dart` — Repository implementation
- `test/features/bracket/domain/entities/match_entity_test.dart` — Entity + enum tests
- `test/features/bracket/data/models/match_model_test.dart` — Model tests
- `test/features/bracket/data/datasources/match_local_datasource_test.dart` — Datasource tests
- `test/features/bracket/data/repositories/match_repository_implementation_test.dart` — Repository tests

**Modified:**
- `lib/core/database/app_database.dart` — Added Matches table, schema v7, migration, CRUD methods, clearDemoData
- `lib/core/database/tables/tables.dart` — Added matches_table.dart export
- `lib/features/bracket/bracket.dart` — Added 6 new exports (total: 12)
- `test/features/bracket/structure_test.dart` — Updated export count to expect 12
- `test/core/database/app_database_test.dart` — Updated schema version expectation to 7

**Generated:**
- `lib/features/bracket/domain/entities/match_entity.freezed.dart`
- `lib/features/bracket/data/models/match_model.freezed.dart`
- `lib/features/bracket/data/models/match_model.g.dart`

### Completion Notes List

- Cross-referenced architecture schema (lines 1488-1521) with epics AC for field reconciliation
- Identified 7 field name mismatches between epic summary and architecture schema; architecture wins
- Confirmed `isBye` is NOT a column — byes use `result_type = 'bye'`
- Documented self-referential FK pattern for bracket tree navigation
- Match entity lives in bracket feature (not its own feature) per architecture structure
- self-referential FK on matches table requires careful Drift definition
- AppDatabase modification scope precisely defined (schema v6→v7, one new table, CRUD methods)
- All patterns verified against implemented bracket feature code (not just docs)

### Change Log

- 2026-02-25: Story created — ready for implementation
