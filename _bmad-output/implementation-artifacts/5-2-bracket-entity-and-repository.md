# Story 5.2: Bracket Entity & Repository

Status: done

**Created:** 2026-02-25

**Epic:** 5 - Bracket Generation & Seeding

**FRs Covered:** FR20-FR31 (foundational entity & repository for all bracket operations)

**Dependencies:** Story 5.1 (Bracket Feature Structure) - COMPLETE | Epic 4 (Participant) - COMPLETE | Epic 3 (Tournament & Division) - COMPLETE

---

## TL;DR — Critical Facts

**CURRENT STATE:**
- ✅ `lib/features/bracket/` — Feature structure exists (empty dirs + barrel + README) from Story 5.1
- ✅ `lib/features/division/domain/entities/division_entity.dart` — Contains `BracketFormat` enum — **DO NOT DUPLICATE**
- ✅ `lib/core/database/tables/base_tables.dart` — `BaseSyncMixin` + `BaseAuditMixin` — **REUSE**
- ✅ `lib/core/database/app_database.dart` — schema version 5 — **WILL BE MODIFIED** (add Brackets table + CRUD + migration v6)
- ✅ `lib/core/database/tables/tables.dart` — barrel file — **WILL BE MODIFIED** (add brackets export)
- ❌ `lib/core/database/tables/brackets_table.dart` — **DOES NOT EXIST** — Create in this story
- ❌ `BracketEntity` — **DOES NOT EXIST** — Create in this story
- ❌ `BracketModel` — **DOES NOT EXIST** — Create in this story
- ❌ `BracketRepository` (interface) — **DOES NOT EXIST** — Create in this story
- ❌ `BracketRepositoryImplementation` — **DOES NOT EXIST** — Create in this story
- ❌ `BracketLocalDatasource` — **DOES NOT EXIST** — Create in this story
- ❌ `BracketRemoteDatasource` — **DOES NOT EXIST** — Create in this story

**TARGET STATE:** Complete Drift table, domain entity, data model, datasource layer (local + remote stubs), repository interface, and repository implementation — following EXACT patterns from `participant` feature.

**EPICS AC vs DB SCHEMA RECONCILIATION:**
> The epics AC says entity should contain: `divisionId`, `bracketType`, `seedingMethod`, `seedData` (JSONB), `layoutData` (JSONB), `status`.
> **Architecture DB schema (source of truth) defines these columns:**

| Epics AC Field   | Architecture Schema Column | Entity Field           | Notes                                                             |
| ---------------- | -------------------------- | ---------------------- | ----------------------------------------------------------------- |
| `divisionId`     | `division_id`              | `divisionId`           | FK → divisions                                                    |
| `bracketType`    | `bracket_type`             | `bracketType`          | Enum: `winners`, `losers`, `pool`                                 |
| N/A              | `pool_identifier`          | `poolIdentifier`       | Nullable: A-H, only for pool brackets                             |
| N/A              | `total_rounds`             | `totalRounds`          | Required integer                                                  |
| N/A              | `is_finalized`             | `isFinalized`          | Default false                                                     |
| N/A              | `generated_at_timestamp`   | `generatedAtTimestamp` | Nullable                                                          |
| N/A              | `finalized_at_timestamp`   | `finalizedAtTimestamp` | Nullable                                                          |
| `seedData`       | `bracket_data_json`        | `bracketDataJson`      | JSONB stored as TEXT in SQLite; maps to `Map<String, dynamic>?`   |
| `layoutData`     | merged into bracket_data   | (part of above)        | Architecture merged seed/layout into single `bracket_data_json`   |
| `seedingMethod`  | NOT in schema              | N/A                    | Deferred — seeding method stored in seed_data JSON, not a column  |
| `status`         | NOT a column               | N/A                    | Status derived from `is_finalized` boolean, not a separate column |
| + BaseSyncMixin  |                            |                        | syncVersion, isDeleted, deletedAtTimestamp, isDemoData            |
| + BaseAuditMixin |                            |                        | createdAtTimestamp, updatedAtTimestamp                            |

**⚠️ STRUCTURE TEST WILL BREAK — MUST UPDATE:**
> `test/features/bracket/structure_test.dart` line 60-71 asserts `barrel file should have zero export statements`. When you add exports to `bracket.dart`, this test WILL FAIL. You MUST update this test — the TODO comment at line 57 confirms this. Either remove the assertion or change it to verify exports exist.

**KEY LESSONS FROM EPICS 2-4 — APPLY ALL:**
1. Use cases = `@injectable` (transient), Repos/Services = `@lazySingleton` — mixing causes state leakage
2. `@JsonKey(name: 'snake_case')` SELECTIVELY on model fields where camelCase ≠ snake_case
3. Repository manages `sync_version`, NOT use cases — Database transaction handles increment
4. Run `build_runner build --delete-conflicting-outputs` after ANY generated file changes
5. Model needs `fromDriftEntry`, `fromJson`, `convertToEntity`, `toDriftCompanion`, `convertFromEntity`
6. Entity uses `freezed` for immutability; Model uses `freezed` + `json_serializable`
7. Datasource abstract + implementation in SAME file
8. `// ignore_for_file: invalid_annotation_target` at top of Model file for freezed `@JsonKey`
9. `import 'package:drift/drift.dart' hide JsonKey;` in model file
10. **Failure types:** `LocalCacheAccessFailure` for reads, `LocalCacheWriteFailure` for writes, `NotFoundFailure` for not-found
11. Repository constructor injects ALL 4 deps: local datasource, remote datasource, connectivity service, app database
12. `BracketFormat` enum lives in `division_entity.dart` — **IMPORT IT, DO NOT CREATE NEW ENUM**
13. `app_database_test.dart` line 21 asserts `schemaVersion` is `5` — **MUST change to `6`**

---

## Story

**As a** developer,
**I want** the Bracket entity and repository implemented,
**So that** bracket structure and seeding data can be persisted.

---

## Acceptance Criteria

- [x] **AC1**: `brackets_table.dart` Drift table created with:
  - `id`, `division_id` (FK), `bracket_type` (Enum), `total_rounds`, `is_finalized`.
  - `generated_at_timestamp`, `finalized_at_timestamp`.
  - `bracket_data_json` (TEXT column for JSONB).
  - Proper mixins (`BaseSyncMixin`, `BaseAuditMixin`).
- [x] **AC2**: `BracketType` enum created in entity file with values: `winners`, `losers`, `pool`.
- [x] **AC3**: `BracketEntity` (Freezed) created with all fields mapping to DB.
- [x] **AC4**: `BracketModel` created with:
  - `fromDriftEntry`, `toDriftCompanion`.
  - `convertToEntity`, `convertFromEntity`.
  - Proper JSONB handling (JSON string in DB <-> Map in Entity).
- [x] **AC5**: `BracketRepository` interface defined in domain.
- [x] **AC6**: `BracketRepositoryImplementation` created in data/repositories/.
  - Implements offline-first pattern matching `ParticipantRepository`.
  - Injects `BracketLocalDatasource`, `BracketRemoteDatasource`, `ConnectivityService`.
- [x] **AC7**: `BracketLocalDatasource` (Drift) implemented with standard CRUD.
- [x] **AC8**: `BracketRemoteDatasource` (Supabase) stub created (UnimplementedError).
- [x] **AC9**: `AppDatabase` updated:
  - Schema version bumped to 6.
  - Migration added to `onUpgrade`.
  - CRUD helper methods added.
- [x] **AC10**: Barrel file `lib/features/bracket/bracket.dart` updated.
- [x] **AC11**: `build_runner` executed successfully without conflicts.
- [x] **AC12**: Unit tests created for Entity, Model, LocalDatasource, and Repository.
- [x] **AC13**: Analysis clean and all tests passing.

## Tasks / Subtasks

### Task 1: Verify Current State (AC: #18)
- [x] 1.1: Verify `lib/features/bracket/` structure exists (from Story 5.1).
- [x] 1.2: Check `lib/core/database/tables/tables.dart` for current exports.

### Task 2: Create Brackets Drift Table (AC: #1)
- [x] 2.1: Create `lib/core/database/tables/brackets_table.dart`.
- [x] 2.2: Export in `lib/core/database/tables/tables.dart`.

### Task 3: Update AppDatabase (AC: #9, #18)
- [x] 3.1: Add `Brackets` to `@DriftDatabase(tables: [...])` list in `lib/core/database/app_database.dart`.
- [x] 3.2: Update `schemaVersion` from 5 to 6.
- [x] 3.3: Add migration step: `if (from < 6) { await m.createTable(brackets); }`.
- [x] 3.4: Add Bracket CRUD methods (similar to Participants).
- [x] 3.5: Add `brackets` to `clearDemoData()` (after participants/divisions).
- [x] 3.6: Update `test/core/database/app_database_test.dart` to expect version 6.

### Task 4: Create BracketEntity (AC: #2, #3)
- [x] 4.1: Create `lib/features/bracket/domain/entities/bracket_entity.dart`.
- [x] 4.2: Define `BracketType` enum with `fromString` helper.
- [x] 4.3: Define `BracketEntity` (Freezed) with all table fields.

### Task 5: Create BracketModel (AC: #4)
- [x] 5.1: Create `lib/features/bracket/data/models/bracket_model.dart`.
- [x] 5.2: Implement `fromDriftEntry` and `toDriftCompanion`.
- [x] 5.3: Implement `convertToEntity` and `convertFromEntity` (encode/decode `bracketDataJson`).

### Task 6: Create BracketLocalDatasource (AC: #7)
- [x] 6.1: Create `lib/features/bracket/data/datasources/bracket_local_datasource.dart`.
- [x] 6.2: Implement `BracketLocalDatasourceImplementation` calling `AppDatabase` methods.

### Task 7: Create BracketRemoteDatasource Stub (AC: #8)
- [x] 7.1: Create `lib/features/bracket/data/datasources/bracket_remote_datasource.dart`.
- [x] 7.2: Provide stub implementation throwing `UnimplementedError`.

### Task 8: Create BracketRepository Interface (AC: #5)
- [x] 8.1: Create `lib/features/bracket/domain/repositories/bracket_repository.dart`.

### Task 9: Create BracketRepositoryImplementation (AC: #6)
- [x] 9.1: Create `lib/features/bracket/data/repositories/bracket_repository_implementation.dart`.
- [x] 9.2: Implement CRUD methods with offline-first logic (Prioritize Local -> Remote).

### Task 10: Update Barrel File and Fix Structure Test (AC: #10, #18)
- [x] 10.1: Update `lib/features/bracket/bracket.dart` to export new files.
- [x] 10.2: Update `test/features/bracket/structure_test.dart` to expect 6 exports (currently 0).

### Task 11: Run Code Generation (AC: #4, #13)
- [x] 11.1: Run `flutter pub run build_runner build --delete-conflicting-outputs`.

### Task 12: Write Unit Tests (AC: #12, #14-17)
- [x] 12.1: Create `test/features/bracket/domain/entities/bracket_entity_test.dart`.
- [x] 12.2: Create `test/features/bracket/data/models/bracket_model_test.dart`.
- [x] 12.3: Create `test/features/bracket/data/datasources/bracket_local_datasource_test.dart`.
- [x] 12.4: Create `test/features/bracket/data/repositories/bracket_repository_implementation_test.dart`.

### Task 13: Verify Project Integrity (AC: #18)
- [x] 13.1: Run `flutter analyze` and ensure no new errors.
- [x] 13.2: Run `flutter test test/features/bracket/` and ensure all 29+ pass.
- [x] 13.3: Run `flutter test test/core/database/app_database_test.dart`.

### Task 2: Create Brackets Drift Table (AC: #1)

- [x] 2.1: Create `lib/core/database/tables/brackets_table.dart`

```dart
import 'package:drift/drift.dart';
import 'package:tkd_brackets/core/database/tables/base_tables.dart';
import 'package:tkd_brackets/core/database/tables/divisions_table.dart';

/// Brackets table for tournament bracket structures.
///
/// Each bracket belongs to a division. Multiple brackets per division
/// are possible (e.g., winners + losers for double elimination).
@DataClassName('BracketEntry')
class Brackets extends Table with BaseSyncMixin, BaseAuditMixin {
  /// Primary key - UUID stored as TEXT.
  TextColumn get id => text()();

  /// Foreign key to divisions table.
  TextColumn get divisionId =>
      text().named('division_id').references(Divisions, #id)();

  /// Bracket type: 'winners', 'losers', 'pool'.
  TextColumn get bracketType => text().named('bracket_type')();

  /// Pool identifier: A-H (nullable, only for pool brackets).
  TextColumn get poolIdentifier =>
      text().named('pool_identifier').nullable()();

  /// Total number of rounds in this bracket.
  IntColumn get totalRounds => integer().named('total_rounds')();

  /// Whether the bracket has been finalized.
  BoolColumn get isFinalized =>
      boolean().named('is_finalized').withDefault(const Constant(false))();

  /// When the bracket was generated (nullable).
  DateTimeColumn get generatedAtTimestamp =>
      dateTime().named('generated_at_timestamp').nullable()();

  /// When the bracket was finalized (nullable).
  DateTimeColumn get finalizedAtTimestamp =>
      dateTime().named('finalized_at_timestamp').nullable()();

  /// JSONB bracket data stored as TEXT in SQLite.
  TextColumn get bracketDataJson =>
      text().named('bracket_data_json').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] 2.2: Update `lib/core/database/tables/tables.dart` — add `export 'brackets_table.dart';`

### Task 3: Update AppDatabase (AC: #9, #18)

- [ ] 3.1: Add `Brackets` to `@DriftDatabase(tables: [...])` list
- [ ] 3.2: Update `schemaVersion` from 5 to 6
- [ ] 3.3: Add migration step: `if (from < 6) { await m.createTable(brackets); }`
- [ ] 3.4: Add Bracket CRUD methods following participant pattern:

```dart
// ─────────────────────────────────────────────────────────────────────────
// Brackets CRUD
// ─────────────────────────────────────────────────────────────────────────

/// Get all active brackets for a division.
Future<List<BracketEntry>> getBracketsForDivision(String divisionId) {
  return (select(brackets)
        ..where((b) => b.divisionId.equals(divisionId))
        ..where((b) => b.isDeleted.equals(false)))
      .get();
}

/// Get bracket by ID.
Future<BracketEntry?> getBracketById(String id) {
  return (select(brackets)..where((b) => b.id.equals(id))).getSingleOrNull();
}

/// Insert a new bracket.
Future<int> insertBracket(BracketsCompanion bracket) {
  return into(brackets).insert(bracket);
}

/// Update a bracket and increment sync_version.
Future<bool> updateBracket(String id, BracketsCompanion bracket) async {
  return transaction(() async {
    final current = await getBracketById(id);
    if (current == null) return false;
    final rows = await (update(brackets)..where((b) => b.id.equals(id)))
        .write(bracket.copyWith(
          syncVersion: Value(current.syncVersion + 1),
          updatedAtTimestamp: Value(DateTime.now()),
        ));
    return rows > 0;
  });
}

/// Soft delete a bracket.
Future<bool> softDeleteBracket(String id) {
  return (update(brackets)..where((b) => b.id.equals(id)))
      .write(BracketsCompanion(
        isDeleted: const Value(true),
        deletedAtTimestamp: Value(DateTime.now()),
        updatedAtTimestamp: Value(DateTime.now()),
      ))
      .then((rows) => rows > 0);
}

/// Get all active brackets (for testing).
Future<List<BracketEntry>> getActiveBrackets() {
  return (select(brackets)..where((b) => b.isDeleted.equals(false))).get();
}
```

- [ ] 3.5: Add `brackets` to `clearDemoData()` — insert BEFORE participants delete (reverse FK order)
- [ ] 3.6: Update `app_database_test.dart` to expect schema version 6

### Task 4: Create BracketEntity (AC: #2, #3)

- [ ] 4.1: Create `lib/features/bracket/domain/entities/bracket_entity.dart`

**Key design decisions:**
- `BracketType` enum defined HERE (NOT `BracketFormat` — that's in division_entity.dart)
- `bracketDataJson` stored as `Map<String, dynamic>?` in entity (parsed from TEXT)
- Uses `@freezed` with `const factory` + `_$BracketEntity` mixin
- Private constructor `const BracketEntity._();` for custom getters if needed

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bracket_entity.freezed.dart';

@freezed
class BracketEntity with _$BracketEntity {
  const factory BracketEntity({
    required String id,
    required String divisionId,
    required BracketType bracketType,
    required int totalRounds,
    required DateTime createdAtTimestamp,
    required DateTime updatedAtTimestamp,
    String? poolIdentifier,
    @Default(false) bool isFinalized,
    DateTime? generatedAtTimestamp,
    DateTime? finalizedAtTimestamp,
    Map<String, dynamic>? bracketDataJson,
    @Default(1) int syncVersion,
    @Default(false) bool isDeleted,
    DateTime? deletedAtTimestamp,
    @Default(false) bool isDemoData,
  }) = _BracketEntity;

  const BracketEntity._();
}

/// Bracket type — winners/losers for elimination, pool for round robin.
enum BracketType {
  winners('winners'),
  losers('losers'),
  pool('pool');

  const BracketType(this.value);
  final String value;

  static BracketType fromString(String value) {
    return BracketType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => BracketType.winners,
    );
  }
}
```

### Task 5: Create BracketModel (AC: #4)

- [ ] 5.1: Create `lib/features/bracket/data/models/bracket_model.dart`

**⚠️ CRITICAL: `bracketDataJson` is `String?` in model (TEXT column), `Map<String, dynamic>?` in entity. Use `dart:convert` for conversion.**

**Fields that NEED `@JsonKey(name: 'snake_case')`:** `divisionId`, `bracketType`, `poolIdentifier`, `totalRounds`, `isFinalized`, `generatedAtTimestamp`, `finalizedAtTimestamp`, `bracketDataJson`, `syncVersion`, `isDeleted`, `deletedAtTimestamp`, `isDemoData`, `createdAtTimestamp`, `updatedAtTimestamp`

**Fields that DO NOT need `@JsonKey`:** `id` (same in both cases)

```dart
// Freezed uses @JsonKey on constructor parameters which triggers this lint.
// This is the documented freezed pattern and works correctly with code gen.
// ignore_for_file: invalid_annotation_target

import 'dart:convert';

import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';

part 'bracket_model.freezed.dart';
part 'bracket_model.g.dart';

/// Data model for Bracket with JSON and database conversions.
@freezed
class BracketModel with _$BracketModel {
  const factory BracketModel({
    required String id,
    @JsonKey(name: 'division_id') required String divisionId,
    @JsonKey(name: 'bracket_type') required String bracketType,
    @JsonKey(name: 'total_rounds') required int totalRounds,
    @JsonKey(name: 'is_finalized') @Default(false) bool isFinalized,
    @JsonKey(name: 'sync_version') required int syncVersion,
    @JsonKey(name: 'created_at_timestamp') required DateTime createdAtTimestamp,
    @JsonKey(name: 'updated_at_timestamp') required DateTime updatedAtTimestamp,
    @JsonKey(name: 'pool_identifier') String? poolIdentifier,
    @JsonKey(name: 'generated_at_timestamp') DateTime? generatedAtTimestamp,
    @JsonKey(name: 'finalized_at_timestamp') DateTime? finalizedAtTimestamp,
    @JsonKey(name: 'bracket_data_json') String? bracketDataJson,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
    @JsonKey(name: 'deleted_at_timestamp') DateTime? deletedAtTimestamp,
    @JsonKey(name: 'is_demo_data') @Default(false) bool isDemoData,
  }) = _BracketModel;

  const BracketModel._();

  factory BracketModel.fromJson(Map<String, dynamic> json) =>
      _$BracketModelFromJson(json);

  /// Convert from Drift-generated [BracketEntry] to [BracketModel].
  factory BracketModel.fromDriftEntry(BracketEntry entry) {
    return BracketModel(
      id: entry.id,
      divisionId: entry.divisionId,
      bracketType: entry.bracketType,
      poolIdentifier: entry.poolIdentifier,
      totalRounds: entry.totalRounds,
      isFinalized: entry.isFinalized,
      generatedAtTimestamp: entry.generatedAtTimestamp,
      finalizedAtTimestamp: entry.finalizedAtTimestamp,
      bracketDataJson: entry.bracketDataJson,
      syncVersion: entry.syncVersion,
      isDeleted: entry.isDeleted,
      deletedAtTimestamp: entry.deletedAtTimestamp,
      isDemoData: entry.isDemoData,
      createdAtTimestamp: entry.createdAtTimestamp,
      updatedAtTimestamp: entry.updatedAtTimestamp,
    );
  }

  /// Create [BracketModel] from domain [BracketEntity].
  factory BracketModel.convertFromEntity(BracketEntity entity) {
    return BracketModel(
      id: entity.id,
      divisionId: entity.divisionId,
      bracketType: entity.bracketType.value,
      poolIdentifier: entity.poolIdentifier,
      totalRounds: entity.totalRounds,
      isFinalized: entity.isFinalized,
      generatedAtTimestamp: entity.generatedAtTimestamp,
      finalizedAtTimestamp: entity.finalizedAtTimestamp,
      bracketDataJson: entity.bracketDataJson != null
          ? jsonEncode(entity.bracketDataJson)
          : null,
      syncVersion: entity.syncVersion,
      isDeleted: entity.isDeleted,
      deletedAtTimestamp: entity.deletedAtTimestamp,
      isDemoData: entity.isDemoData,
      createdAtTimestamp: entity.createdAtTimestamp,
      updatedAtTimestamp: entity.updatedAtTimestamp,
    );
  }

  /// Convert to Drift [BracketsCompanion] for database operations.
  BracketsCompanion toDriftCompanion() {
    return BracketsCompanion.insert(
      id: id,
      divisionId: divisionId,
      bracketType: bracketType,
      totalRounds: totalRounds,
      poolIdentifier: Value(poolIdentifier),
      isFinalized: Value(isFinalized),
      generatedAtTimestamp: Value(generatedAtTimestamp),
      finalizedAtTimestamp: Value(finalizedAtTimestamp),
      bracketDataJson: Value(bracketDataJson),
      syncVersion: Value(syncVersion),
      isDeleted: Value(isDeleted),
      deletedAtTimestamp: Value(deletedAtTimestamp),
      isDemoData: Value(isDemoData),
    );
  }

  /// Convert [BracketModel] to domain [BracketEntity].
  BracketEntity convertToEntity() {
    return BracketEntity(
      id: id,
      divisionId: divisionId,
      bracketType: BracketType.fromString(bracketType),
      poolIdentifier: poolIdentifier,
      totalRounds: totalRounds,
      isFinalized: isFinalized,
      generatedAtTimestamp: generatedAtTimestamp,
      finalizedAtTimestamp: finalizedAtTimestamp,
      bracketDataJson: bracketDataJson != null
          ? jsonDecode(bracketDataJson!) as Map<String, dynamic>
          : null,
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

### Task 6: Create BracketLocalDatasource (AC: #7)

- [ ] 6.1: Create `lib/features/bracket/data/datasources/bracket_local_datasource.dart`

```dart
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/bracket/data/models/bracket_model.dart';

/// Local datasource for bracket operations (Drift/SQLite).
abstract class BracketLocalDatasource {
  Future<List<BracketModel>> getBracketsForDivision(String divisionId);
  Future<BracketModel?> getBracketById(String id);
  Future<void> insertBracket(BracketModel bracket);
  Future<void> updateBracket(BracketModel bracket);
  Future<void> deleteBracket(String id);
}

@LazySingleton(as: BracketLocalDatasource)
class BracketLocalDatasourceImplementation implements BracketLocalDatasource {
  BracketLocalDatasourceImplementation(this._database);
  final AppDatabase _database;

  @override
  Future<List<BracketModel>> getBracketsForDivision(String divisionId) async {
    final entries = await _database.getBracketsForDivision(divisionId);
    return entries.map(BracketModel.fromDriftEntry).toList();
  }

  @override
  Future<BracketModel?> getBracketById(String id) async {
    final entry = await _database.getBracketById(id);
    return entry != null ? BracketModel.fromDriftEntry(entry) : null;
  }

  @override
  Future<void> insertBracket(BracketModel bracket) async {
    await _database.insertBracket(bracket.toDriftCompanion());
  }

  @override
  Future<void> updateBracket(BracketModel bracket) async {
    await _database.updateBracket(bracket.id, bracket.toDriftCompanion());
  }

  @override
  Future<void> deleteBracket(String id) async {
    await _database.softDeleteBracket(id);
  }
}
```

### Task 7: Create BracketRemoteDatasource Stub (AC: #8)

- [ ] 7.1: Create `lib/features/bracket/data/datasources/bracket_remote_datasource.dart`

```dart
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/bracket/data/models/bracket_model.dart';

/// Remote datasource for bracket operations (Supabase).
/// Stub implementation — Supabase sync not yet implemented.
abstract class BracketRemoteDatasource {
  Future<List<BracketModel>> getBracketsForDivision(String divisionId);
  Future<BracketModel?> getBracketById(String id);
  Future<void> insertBracket(BracketModel bracket);
  Future<void> updateBracket(BracketModel bracket);
  Future<void> deleteBracket(String id);
}

@LazySingleton(as: BracketRemoteDatasource)
class BracketRemoteDatasourceImplementation implements BracketRemoteDatasource {
  @override
  Future<List<BracketModel>> getBracketsForDivision(String divisionId) async {
    throw UnimplementedError('Supabase bracket sync not yet implemented');
  }

  @override
  Future<BracketModel?> getBracketById(String id) async {
    throw UnimplementedError('Supabase bracket sync not yet implemented');
  }

  @override
  Future<void> insertBracket(BracketModel bracket) async {
    throw UnimplementedError('Supabase bracket sync not yet implemented');
  }

  @override
  Future<void> updateBracket(BracketModel bracket) async {
    throw UnimplementedError('Supabase bracket sync not yet implemented');
  }

  @override
  Future<void> deleteBracket(String id) async {
    throw UnimplementedError('Supabase bracket sync not yet implemented');
  }
}
```

### Task 8: Create BracketRepository Interface (AC: #5)

- [ ] 8.1: Create `lib/features/bracket/domain/repositories/bracket_repository.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';

/// Repository interface for bracket operations.
abstract class BracketRepository {
  Future<Either<Failure, List<BracketEntity>>> getBracketsForDivision(
    String divisionId,
  );
  Future<Either<Failure, BracketEntity>> getBracketById(String id);
  Future<Either<Failure, BracketEntity>> createBracket(BracketEntity bracket);
  Future<Either<Failure, BracketEntity>> updateBracket(BracketEntity bracket);
  Future<Either<Failure, Unit>> deleteBracket(String id);
}
```

### Task 9: Create BracketRepositoryImplementation (AC: #6)

- [ ] 9.1: Create `lib/features/bracket/data/repositories/bracket_repository_implementation.dart`

**⚠️ Follow participant_repository_implementation.dart EXACTLY. Key pattern: offline-first, try local → if null and online → try remote → cache locally.**

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/bracket/data/datasources/bracket_local_datasource.dart';
import 'package:tkd_brackets/features/bracket/data/datasources/bracket_remote_datasource.dart';
import 'package:tkd_brackets/features/bracket/data/models/bracket_model.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';

@LazySingleton(as: BracketRepository)
class BracketRepositoryImplementation implements BracketRepository {
  BracketRepositoryImplementation(
    this._localDatasource,
    this._remoteDatasource,
    this._connectivityService,
    this._database,
  );

  final BracketLocalDatasource _localDatasource;
  final BracketRemoteDatasource _remoteDatasource;
  final ConnectivityService _connectivityService;
  final AppDatabase _database;

  @override
  Future<Either<Failure, List<BracketEntity>>> getBracketsForDivision(
    String divisionId,
  ) async {
    try {
      final models = await _localDatasource.getBracketsForDivision(divisionId);
      return Right(models.map((m) => m.convertToEntity()).toList());
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(
        technicalDetails: 'Failed to get brackets for division: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, BracketEntity>> getBracketById(String id) async {
    try {
      final model = await _localDatasource.getBracketById(id);
      if (model != null) return Right(model.convertToEntity());

      final hasConnection =
          await _connectivityService.hasInternetConnection();
      if (!hasConnection) {
        return const Left(NotFoundFailure(
          userFriendlyMessage: 'Bracket not found',
        ));
      }

      try {
        final remoteModel = await _remoteDatasource.getBracketById(id);
        if (remoteModel != null) {
          await _localDatasource.insertBracket(remoteModel);
          return Right(remoteModel.convertToEntity());
        }
      } on Object {
        // Remote fetch failed, return not found
      }

      return const Left(NotFoundFailure(
        userFriendlyMessage: 'Bracket not found',
      ));
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(
        technicalDetails: 'Failed to get bracket: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, BracketEntity>> createBracket(
    BracketEntity bracket,
  ) async {
    try {
      final model = BracketModel.convertFromEntity(bracket);
      await _localDatasource.insertBracket(model);

      final hasConnection =
          await _connectivityService.hasInternetConnection();
      if (hasConnection) {
        try {
          await _remoteDatasource.insertBracket(model);
        } on Object {
          // Remote insert failed, will sync later
        }
      }

      return Right(bracket);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(
        technicalDetails: 'Failed to create bracket: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, BracketEntity>> updateBracket(
    BracketEntity bracket,
  ) async {
    try {
      final existing = await _localDatasource.getBracketById(bracket.id);
      final newSyncVersion = (existing?.syncVersion ?? 0) + 1;

      final updatedEntity = bracket.copyWith(syncVersion: newSyncVersion);
      final model = BracketModel.convertFromEntity(updatedEntity);
      await _localDatasource.updateBracket(model);

      final hasConnection =
          await _connectivityService.hasInternetConnection();
      if (hasConnection) {
        try {
          await _remoteDatasource.updateBracket(model);
        } on Object {
          // Remote update failed, will sync later
        }
      }

      return Right(updatedEntity);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(
        technicalDetails: 'Failed to update bracket: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteBracket(String id) async {
    try {
      await _localDatasource.deleteBracket(id);

      final hasConnection =
          await _connectivityService.hasInternetConnection();
      if (hasConnection) {
        try {
          await _remoteDatasource.deleteBracket(id);
        } on Object {
          // Remote delete failed, will sync later
        }
      }

      return const Right(unit);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(
        technicalDetails: 'Failed to delete bracket: $e',
      ));
    }
  }
}
```

### Task 10: Update Barrel File + Fix Structure Test (AC: #10, #11)

- [ ] 10.1: Update `lib/features/bracket/bracket.dart` — replace entire content:

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

- [ ] 10.2: Update `test/features/bracket/structure_test.dart` — **REMOVE or MODIFY** the test at line 60-71 that asserts zero exports. Replace with:

```dart
test('barrel file should have export statements', () {
  final barrelFile = File('$basePath/bracket.dart');
  final content = barrelFile.readAsStringSync();

  expect(
    content.contains('export '),
    isTrue,
    reason: 'Barrel file should have exports after Story 5.2',
  );
});
```

- [ ] 10.3: Verify `tables.dart` has brackets export (done in Task 2)

### Task 11: Run Code Generation (AC: #17)

- [ ] 11.1: Run `dart run build_runner build --delete-conflicting-outputs` from `tkd_brackets/`
- [ ] 11.2: Verify generated files: `bracket_entity.freezed.dart`, `bracket_model.freezed.dart`, `bracket_model.g.dart`, `app_database.g.dart`, `injection.config.dart`

### Task 12: Create Tests (AC: #12-15)

- [ ] 12.1: Create `test/features/bracket/domain/entities/bracket_entity_test.dart`
  - Test entity creation with all required fields
  - Test default values: `isFinalized=false`, `syncVersion=1`, `isDeleted=false`, `isDemoData=false`
  - Test entity creation with optional fields (poolIdentifier, bracketDataJson, timestamps)
  - Test equality (same fields → equal, different fields → not equal)
  - Test `BracketType.fromString()` for 'winners', 'losers', 'pool'
  - Test `BracketType.fromString()` with unknown value → defaults to `winners`
  - Test `BracketType` enum `.value` property returns correct strings

- [ ] 12.2: Create `test/features/bracket/data/models/bracket_model_test.dart`
  - Test `fromJson` with full JSON including snake_case keys
  - Test `toJson` produces snake_case keys
  - Test `fromDriftEntry` converts all fields correctly (mock `BracketEntry` not needed — use concrete test data)
  - Test `convertToEntity` converts `String bracketType` → `BracketType` enum
  - Test `convertToEntity` with `bracketDataJson` as JSON string → `Map<String, dynamic>`
  - Test `convertToEntity` with `null` bracketDataJson → `null` in entity
  - Test `convertFromEntity` converts `BracketType` enum → string
  - Test `convertFromEntity` with `Map<String, dynamic>` bracketDataJson → JSON string
  - Test `convertFromEntity` with `null` bracketDataJson → `null` in model
  - Test `toDriftCompanion` produces correct companion with `Value()` wrappers

- [ ] 12.3: Create `test/features/bracket/data/datasources/bracket_local_datasource_test.dart`
  - Mock `AppDatabase` with mocktail
  - Test `getBracketsForDivision` calls DB and converts entries to models
  - Test `getBracketById` returns model when found, null when not found
  - Test `insertBracket` calls `_database.insertBracket` with companion
  - Test `updateBracket` calls `_database.updateBracket` with id and companion
  - Test `deleteBracket` calls `_database.softDeleteBracket`

- [ ] 12.4: Create `test/features/bracket/data/repositories/bracket_repository_implementation_test.dart`
  - Mock all 4 deps: `BracketLocalDatasource`, `BracketRemoteDatasource`, `ConnectivityService`, `AppDatabase`
  - Use `registerFallbackValue(testModel)` and `registerFallbackValue(testEntity)` in `setUpAll`
  - **getBracketsForDivision:** test returns `Right` with list when offline; test returns `Left(LocalCacheAccessFailure)` on exception
  - **getBracketById:** test returns `Right` when found locally; test returns `Left(NotFoundFailure)` when not found locally and offline; test returns `Right` when found remotely (caches locally)
  - **createBracket:** test returns `Right` when offline (local insert only); test returns `Left(LocalCacheWriteFailure)` on exception
  - **updateBracket:** test returns `Right` with incremented syncVersion; test verifies local update called
  - **deleteBracket:** test returns `Right(unit)` when offline; test returns `Left(LocalCacheWriteFailure)` on exception

### Task 13: Verify Project Integrity (AC: #16-18)

- [ ] 13.1: Run `flutter analyze` from `tkd_brackets/` — zero new issues
- [ ] 13.2: Run `dart run build_runner build --delete-conflicting-outputs` — succeeds
- [ ] 13.3: Run ALL bracket tests: `flutter test test/features/bracket/`
- [ ] 13.4: Run full test suite: `flutter test` — all pass, no regressions
- [ ] 13.5: Verify structure test still passes: `flutter test test/features/bracket/structure_test.dart`

---

## Dev Notes

### Drift Table Pattern (from participants_table.dart)

- `@DataClassName('BracketEntry')` — generates `BracketEntry` data class and `BracketsCompanion`
- `extends Table with BaseSyncMixin, BaseAuditMixin` — adds sync + audit columns
- FK references: `text().named('division_id').references(Divisions, #id)()`
- `@override Set<Column> get primaryKey => {id};`

### AppDatabase Modification Checklist — EXACT LINE LOCATIONS

**⚠️ These are the ONLY modifications to app_database.dart:**
1. **Line 27**: Add `Brackets,` to `@DriftDatabase(tables: [...])` list — insert AFTER `Participants,` (line 27) and BEFORE `Invitations,` (line 28)
2. **Line 43**: Change `int get schemaVersion => 5;` to `int get schemaVersion => 6;`
3. **Line 69** (inside `onUpgrade`): Add migration block AFTER the `if (from < 5)` block:
   ```dart
   // Version 6: Add brackets table for bracket generation
   if (from < 6) {
     await m.createTable(brackets);
   }
   ```
4. **After line 398** (after `getActiveParticipants` method, BEFORE `// Invitations CRUD` comment at line 400): Insert entire Brackets CRUD section
5. **Line 554** (in `clearDemoData()`): Add `await (delete(brackets)..where((b) => b.isDemoData.equals(true))).go();` BEFORE the participants delete line

### JSONB/TEXT Handling Pattern

The `bracket_data_json` column stores JSON as TEXT in SQLite:
- **Drift table:** `TextColumn` (nullable)
- **Model:** `String?` field with `@JsonKey(name: 'bracket_data_json')`
- **Entity:** `Map<String, dynamic>?` field
- **Model→Entity:** `jsonDecode(bracketDataJson!)` when non-null
- **Entity→Model:** `jsonEncode(bracketDataJson!)` when non-null
- Use `dart:convert` for encode/decode

### BracketType vs BracketFormat — CRITICAL DISTINCTION

| Enum            | Location                    | Values                                                             | Purpose                              |
| --------------- | --------------------------- | ------------------------------------------------------------------ | ------------------------------------ |
| `BracketFormat` | `division_entity.dart`      | `singleElimination`, `doubleElimination`, `roundRobin`, `poolPlay` | Division's chosen format             |
| `BracketType`   | `bracket_entity.dart` (NEW) | `winners`, `losers`, `pool`                                        | Individual bracket's structural type |

A division with `BracketFormat.doubleElimination` spawns TWO brackets: one `BracketType.winners` + one `BracketType.losers`.

### Test Data Setup

```dart
final testDateTime = DateTime(2026, 1, 15, 10, 30);

// Model test data
final testModel = BracketModel(
  id: 'bracket-1',
  divisionId: 'division-1',
  bracketType: 'winners',
  totalRounds: 3,
  isFinalized: false,
  syncVersion: 1,
  isDeleted: false,
  isDemoData: false,
  createdAtTimestamp: testDateTime,
  updatedAtTimestamp: testDateTime,
);

// Entity test data
final testEntity = BracketEntity(
  id: 'bracket-1',
  divisionId: 'division-1',
  bracketType: BracketType.winners,
  totalRounds: 3,
  createdAtTimestamp: testDateTime,
  updatedAtTimestamp: testDateTime,
);
```

### Testing Mocks (use mocktail)

```dart
class MockBracketLocalDatasource extends Mock implements BracketLocalDatasource {}
class MockBracketRemoteDatasource extends Mock implements BracketRemoteDatasource {}
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockAppDatabase extends Mock implements AppDatabase {}
```

### File Structure After This Story

```
lib/core/database/tables/
├── brackets_table.dart                                  ← NEW

lib/features/bracket/
├── bracket.dart                                         ← UPDATED barrel
├── README.md                                            ← Unchanged
├── data/
│   ├── datasources/
│   │   ├── bracket_local_datasource.dart                ← NEW
│   │   └── bracket_remote_datasource.dart               ← NEW (stub)
│   ├── models/
│   │   ├── bracket_model.dart                           ← NEW
│   │   ├── bracket_model.freezed.dart                   ← GENERATED
│   │   └── bracket_model.g.dart                         ← GENERATED
│   └── repositories/
│       └── bracket_repository_implementation.dart        ← NEW
├── domain/
│   ├── entities/
│   │   ├── bracket_entity.dart                          ← NEW
│   │   └── bracket_entity.freezed.dart                  ← GENERATED
│   ├── repositories/
│   │   └── bracket_repository.dart                      ← NEW
│   └── usecases/                                        ← Empty (Story 5.4+)
└── presentation/                                        ← Empty (Story 5.13)

test/features/bracket/
├── structure_test.dart                                  ← UPDATED (remove zero-exports assertion)
├── data/
│   ├── datasources/
│   │   └── bracket_local_datasource_test.dart           ← NEW
│   ├── models/
│   │   └── bracket_model_test.dart                      ← NEW
│   └── repositories/
│       └── bracket_repository_implementation_test.dart   ← NEW
└── domain/
    └── entities/
        └── bracket_entity_test.dart                     ← NEW
```

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 5, Story 5.2]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Database Schema: brackets table (lines 1466-1485)]
- [Source: `_bmad-output/implementation-artifacts/5-1-bracket-feature-structure.md` — Previous story context]
- [Source: `_bmad-output/implementation-artifacts/4-2-participant-entity-and-repository.md` — Analogous story pattern]
- [Source: `tkd_brackets/lib/core/database/tables/participants_table.dart` — Drift table pattern]
- [Source: `tkd_brackets/lib/core/database/tables/base_tables.dart` — BaseSyncMixin/BaseAuditMixin]
- [Source: `tkd_brackets/lib/core/database/app_database.dart` — DB migration + CRUD pattern]
- [Source: `tkd_brackets/lib/features/participant/` — Full entity/model/repo/datasource pattern]
- [Source: `tkd_brackets/lib/features/division/domain/entities/division_entity.dart` — BracketFormat enum]

---

## Anti-Patterns — WHAT NOT TO DO

| ❌ Don't Do This                                            | ✅ Do This Instead                                                            | Source                  |
| ---------------------------------------------------------- | ---------------------------------------------------------------------------- | ----------------------- |
| Create `BracketFormat` enum in bracket_entity.dart         | Import from `division_entity.dart` — it already exists there                 | Story 5.1               |
| Import `drift` or `supabase_flutter` in domain layer       | Domain only uses `fpdart`, `freezed`, core Dart                              | Architecture doc        |
| Create brackets table in `lib/features/bracket/`           | Drift tables go in `core/database/tables/`                                   | Architecture boundary   |
| Use `@injectable` on repository (transient)                | Use `@LazySingleton(as: BracketRepository)` (singleton)                      | Epic 2 lessons          |
| Use `@JsonKey` on ALL model fields                         | SELECTIVE `@JsonKey` only where camelCase ≠ snake_case                       | Participant pattern     |
| Use `CacheFailure` in repository                           | Use `LocalCacheAccessFailure` / `LocalCacheWriteFailure` / `NotFoundFailure` | failures.dart           |
| Store `bracketDataJson` as `Map` in model                  | Store as `String?` in model, convert to `Map<String, dynamic>?` in entity    | SQLite TEXT column      |
| Add `seedingMethod` or `status` columns to Drift table     | These are NOT in the architecture schema — derive status from `isFinalized`  | Architecture schema     |
| Skip updating `schemaVersion` in app_database              | Increment to 6 and add migration step                                        | Drift migration pattern |
| Forget to add `Brackets` to `clearDemoData()`              | Add bracket delete BEFORE participants delete (reverse FK order)             | FK constraint safety    |
| Create `services/` directory                               | Not needed until Story 5.4+ when generators are created                      | Story 5.1 notes         |
| Skip `// ignore_for_file: invalid_annotation_target`       | Add at top of model file for freezed `@JsonKey` lint                         | Participant pattern     |
| Import `package:drift/drift.dart` without hiding `JsonKey` | Use `import 'package:drift/drift.dart' hide JsonKey;`                        | Participant pattern     |
| Leave `structure_test.dart` zero-exports assertion as-is   | Update/remove the test — it WILL FAIL once barrel file has exports           | Story 5.1 TODO line 57  |
| Forget to update `app_database_test.dart` schema version   | Change line 21: `expect(database.schemaVersion, 5)` → `6`                    | Drift migration         |
| Store `bracketDataJson` as `Map` in Drift table            | Drift table stores as `TextColumn` (TEXT); JSON parsing happens in model     | SQLite limitation       |

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### File List

**Created:**
- `lib/core/database/tables/brackets_table.dart` — Drift table definition
- `lib/features/bracket/domain/entities/bracket_entity.dart` — BracketEntity + BracketType enum
- `lib/features/bracket/data/models/bracket_model.dart` — BracketModel with JSON/Drift/Entity conversions
- `lib/features/bracket/data/datasources/bracket_local_datasource.dart` — Local datasource (Drift)
- `lib/features/bracket/data/datasources/bracket_remote_datasource.dart` — Remote datasource stub
- `lib/features/bracket/domain/repositories/bracket_repository.dart` — Repository interface
- `lib/features/bracket/data/repositories/bracket_repository_implementation.dart` — Repository implementation
- `test/features/bracket/domain/entities/bracket_entity_test.dart` — Entity tests (6 tests)
- `test/features/bracket/data/models/bracket_model_test.dart` — Model tests (8 tests)
- `test/features/bracket/data/datasources/bracket_local_datasource_test.dart` — Datasource tests (5 tests)
- `test/features/bracket/data/repositories/bracket_repository_implementation_test.dart` — Repository tests (10 tests)

**Modified:**
- `lib/core/database/app_database.dart` — Added Brackets table, schema v6, migration, CRUD methods, clearDemoData
- `lib/core/database/tables/tables.dart` — Added brackets_table.dart export
- `lib/features/bracket/bracket.dart` — Added 6 exports
- `test/features/bracket/structure_test.dart` — Updated zero-exports assertion to expect 6
- `test/core/database/app_database_test.dart` — Updated schema version expectation to 6

**Generated:**
- `lib/features/bracket/domain/entities/bracket_entity.freezed.dart`
- `lib/features/bracket/data/models/bracket_model.freezed.dart`
- `lib/features/bracket/data/models/bracket_model.g.dart`

### Completion Notes List

- Cross-referenced architecture schema (lines 1466-1485) with epics AC for field reconciliation
- Verified BracketFormat enum location in division_entity.dart (DO NOT DUPLICATE)
- Identified JSONB→TEXT→Map conversion pattern for bracket_data_json
- Documented BracketType vs BracketFormat distinction to prevent enum confusion
- AppDatabase modification scope precisely defined (schema v5→v6, one new table, CRUD methods)
- All patterns verified against implemented participant feature code (not just docs)

### Change Log

- 2026-02-25: Story implemented — all 13 ACs satisfied
- 2026-02-25: Code review performed — 8 issues found (1H, 5M, 2L), 6 fixed, 2 noted as systemic

### Senior Developer Review (AI)

**Reviewer:** Asak on 2026-02-25
**Outcome:** Approved with fixes applied

**Fixed Issues:**
1. **[M1] Entity test coverage** — Added 3 missing tests: default values, optional fields, inequality (3→6 tests)
2. **[M2] Model test coverage** — Added 4 missing tests: toJson snake_case keys, null bracketDataJson round-trips, fromDriftEntry full conversion (4→8 tests)
3. **[M3] Repository test coverage** — Added 4 missing tests: NotFoundFailure offline, LocalCacheWriteFailure on create/delete, offline-only create path (6→10 tests)
4. **[M5] Dev Agent Record missing File List** — Added complete File List section
5. **[L1] Duplicate Task sections** — Noted; left as-is (story template format with compact + detailed views)
6. **[L2] tables.dart export ordering** — Fixed to alphabetical order

**Noted (Systemic, Not Fixed):**
1. **[H1] Repository updateBracket double syncVersion increment** — Both repository and AppDatabase.updateBracket increment syncVersion independently. The DB's transaction overrides the companion value, so the final DB value is correct, but the entity returned to the caller uses the repository's calculation. This matches the ParticipantRepository pattern and is a systemic concern for a future pass.
2. **[M4] Unused `_database` field in repository** — Injected but unreferenced. Matches ParticipantRepository pattern; kept for future direct-query needs and DI consistency.

**Test Results After Review:** 40 tests passing (up from 29), all bracket tests green.
