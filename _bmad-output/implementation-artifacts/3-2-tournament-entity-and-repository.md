# Story 3.2: Tournament Entity & Repository

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

**As a** developer,
**I want** the Tournament entity and repository implemented,
**So that** tournament data can be managed locally and synced to Supabase.

## Pre-Implementation Checklist

- [ ] Review existing code:
  - `lib/core/database/tables/tournaments_table.dart` - Table already exists
  - `lib/core/database/app_database.dart` - Tournament CRUD methods exist
  - `lib/features/auth/` - Pattern reference (Organization implementation)

## Acceptance Criteria

1. **AC1: TournamentEntity with Typed Enums** ✅
- [x] `TournamentEntity` exists in `lib/features/tournament/domain/entities/tournament_entity.dart`
    - [x] Defines `FederationType` enum: `wt`, `itf`, `ata`, `custom`
    - [x] Defines `TournamentStatus` enum: `draft`, `registrationOpen`, `registrationClosed`, `inProgress`, `completed`, `cancelled`
    - [x] Entity contains all fields from Supabase schema
    - [x] Uses `@freezed` for immutability and value equality
    - [x] Unit tests verify entity creation and equality

2. **AC2: TournamentModel with Full Conversions** ✅
- [x] `TournamentModel` exists in `lib/features/tournament/data/models/tournament_model.dart`
    - [x] Model includes `@JsonKey(name: 'field_name')` for all snake_case fields
    - [x] Model has `fromJson()` and `toJson()` for Supabase serialization
    - [x] Model has `fromDriftEntry(TournamentEntry entry)` for Drift reads
    - [x] Model has `toDriftCompanion()` for Drift writes
    - [x] Model has `convertToEntity()` and `convertFromEntity()` for domain conversion
    - [x] Handles `TimeOfDay` ↔ `DateTime` conversion for time fields
    - [x] Unit tests verify all conversion paths

3. **AC3: Repository Interface** ✅
- [x] `TournamentRepository` exists in `lib/features/tournament/domain/repositories/tournament_repository.dart`
    - [x] Interface methods:
      ```dart
      Future<Either<Failure, List<TournamentEntity>>> getTournamentsForOrganization(String organizationId);
      Future<Either<Failure, TournamentEntity>> getTournamentById(String id);
      Future<Either<Failure, TournamentEntity>> createTournament(TournamentEntity tournament, String organizationId);
      Future<Either<Failure, TournamentEntity>> updateTournament(TournamentEntity tournament);
      Future<Either<Failure, Unit>> deleteTournament(String id);
      ```
    - [x] All methods return `Either<Failure, T>`

4. **AC4: Local Datasource** ✅
- [x] `TournamentLocalDatasource` abstract class and implementation exist
    - [x] Location: `lib/features/tournament/data/datasources/tournament_local_datasource.dart`
    - [x] Methods delegate to `AppDatabase` (already has tournament CRUD)
    - [x] Methods: `getTournamentsForOrganization()`, `getTournamentById()`, `insertTournament()`, `updateTournament()`, `deleteTournament()` (soft delete)
    - [x] Converts between `TournamentEntry` (Drift) and `TournamentModel`

5. **AC5: Remote Datasource** ✅
- [x] `TournamentRemoteDatasource` abstract class and implementation exist
    - [x] Location: `lib/features/tournament/data/datasources/tournament_remote_datasource.dart`
    - [x] Uses Supabase client with RLS-protected queries
    - [x] Filters: `.eq('organization_id', organizationId)` and `.eq('is_deleted', false)`
    - [x] Methods: `getTournamentsForOrganization()`, `getTournamentById()`, `insertTournament()`, `updateTournament()`, `deleteTournament()` (soft delete)

6. **AC6: Repository Implementation** ✅
- [x] `TournamentRepositoryImplementation` exists
    - [x] Location: `lib/features/tournament/data/repositories/tournament_repository_implementation.dart`
    - [x] Implements offline-first read pattern: local first, fallback to remote
    - [x] Creates: Save local, sync to remote if online
    - [x] Updates: Increment sync_version (read current, AppDatabase handles increment)
    - [x] Soft deletes: Set `is_deleted = true`, `deleted_at_timestamp = now()`
    - [x] Maps exceptions to `Failure` types

7. **AC7: Dependency Injection** ✅
- [x] Repository: `@LazySingleton(as: TournamentRepository)`
    - [x] Datasources: `@LazySingleton(as: TournamentLocalDatasource/RemoteDatasource)`
    - [x] Run: `dart run build_runner build --delete-conflicting-outputs`
    - [x] Verify registrations in `lib/core/di/injection.config.dart`

8. **AC8: Barrel File Updates** ✅
- [x] Update `lib/features/tournament/tournament.dart`:
      ```dart
      // Domain
      export 'domain/entities/tournament_entity.dart';
      export 'domain/repositories/tournament_repository.dart';
      // Data
      export 'data/models/tournament_model.dart';
      export 'data/repositories/tournament_repository_implementation.dart';
      export 'data/datasources/tournament_local_datasource.dart';
      export 'data/datasources/tournament_remote_datasource.dart';
      ```

9. **AC9: Code Quality** ✅
- [x] `flutter analyze` passes with zero errors
    - [x] `dart run build_runner build` succeeds
    - [x] All unit tests pass
    - [x] No orphaned `.freezed.dart` or `.g.dart` files

## Implementation Templates

### Template 1: Entity with Enums

**File:** `lib/features/tournament/domain/entities/tournament_entity.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tournament_entity.freezed.dart';

@freezed
class TournamentEntity with _$TournamentEntity {
  const factory TournamentEntity({
    required String id,
    required String organizationId,
    required String createdByUserId,
    required String name,
    required DateTime scheduledDate,
    required FederationType federationType,
    required TournamentStatus status,
    String? description,
    String? venueName,
    String? venueAddress,
    DateTime? scheduledStartTime, // Stores TimeOfDay as DateTime
    DateTime? scheduledEndTime,
    String? templateId,
    required int numberOfRings,
    required Map<String, dynamic> settingsJson,
    required bool isTemplate,
    required DateTime createdAt,
  }) = _TournamentEntity;
}

enum FederationType {
  wt('wt'),
  itf('itf'),
  ata('ata'),
  custom('custom');

  const FederationType(this.value);
  final String value;

  static FederationType fromString(String value) {
    return FederationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FederationType.wt,
    );
  }
}

enum TournamentStatus {
  draft('draft'),
  registrationOpen('registration_open'),
  registrationClosed('registration_closed'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled');

  const TournamentStatus(this.value);
  final String value;

  static TournamentStatus fromString(String value) {
    return TournamentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TournamentStatus.draft,
    );
  }
}
```

### Template 2: Model with Conversions

**File:** `lib/features/tournament/data/models/tournament_model.dart`

```dart
// ignore_for_file: invalid_annotation_target

import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';

part 'tournament_model.freezed.dart';
part 'tournament_model.g.dart';

@freezed
class TournamentModel with _$TournamentModel {
  const factory TournamentModel({
    required String id,
    required String organizationId,
    required String createdByUserId,
    required String name,
    String? description,
    String? venueName,
    String? venueAddress,
    required DateTime scheduledDate,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    @JsonKey(name: 'federation_type') required String federationType,
    @JsonKey(name: 'status') required String status,
    @JsonKey(name: 'is_template') required bool isTemplate,
    @JsonKey(name: 'template_id') String? templateId,
    @JsonKey(name: 'number_of_rings') required int numberOfRings,
    @JsonKey(name: 'settings_json') required Map<String, dynamic> settingsJson,
    @JsonKey(name: 'sync_version') required int syncVersion,
    @JsonKey(name: 'is_deleted') required bool isDeleted,
    @JsonKey(name: 'is_demo_data') required bool isDemoData,
    @JsonKey(name: 'created_at_timestamp') required DateTime createdAtTimestamp,
    @JsonKey(name: 'updated_at_timestamp') required DateTime updatedAtTimestamp,
    @JsonKey(name: 'deleted_at_timestamp') DateTime? deletedAtTimestamp,
  }) = _TournamentModel;

  const TournamentModel._();

  factory TournamentModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentModelFromJson(json);

  factory TournamentModel.fromDriftEntry(TournamentEntry entry) {
    return TournamentModel(
      id: entry.id,
      organizationId: entry.organizationId,
      createdByUserId: entry.createdByUserId ?? '',
      name: entry.name,
      description: entry.description,
      venueName: entry.venueName,
      venueAddress: entry.venueAddress,
      scheduledDate: entry.scheduledDate,
      scheduledStartTime: entry.scheduledStartTime,
      scheduledEndTime: entry.scheduledEndTime,
      federationType: entry.federationType,
      status: entry.status,
      isTemplate: entry.isTemplate,
      templateId: entry.templateId,
      numberOfRings: entry.numberOfRings,
      settingsJson: {}, // Parse from entry.settingsJson if needed
      syncVersion: entry.syncVersion,
      isDeleted: entry.isDeleted,
      isDemoData: entry.isDemoData,
      createdAtTimestamp: entry.createdAtTimestamp,
      updatedAtTimestamp: entry.updatedAtTimestamp,
      deletedAtTimestamp: entry.deletedAtTimestamp,
    );
  }

  factory TournamentModel.convertFromEntity(
    TournamentEntity entity, {
    int syncVersion = 1,
    bool isDeleted = false,
    bool isDemoData = false,
    DateTime? updatedAtTimestamp,
  }) {
    final now = DateTime.now();
    return TournamentModel(
      id: entity.id,
      organizationId: entity.organizationId,
      createdByUserId: entity.createdByUserId,
      name: entity.name,
      description: entity.description,
      venueName: entity.venueName,
      venueAddress: entity.venueAddress,
      scheduledDate: entity.scheduledDate,
      scheduledStartTime: entity.scheduledStartTime,
      scheduledEndTime: entity.scheduledEndTime,
      federationType: entity.federationType.value,
      status: entity.status.value,
      isTemplate: entity.isTemplate,
      templateId: entity.templateId,
      numberOfRings: entity.numberOfRings,
      settingsJson: entity.settingsJson,
      syncVersion: syncVersion,
      isDeleted: isDeleted,
      isDemoData: isDemoData,
      createdAtTimestamp: entity.createdAt,
      updatedAtTimestamp: updatedAtTimestamp ?? now,
    );
  }

  TournamentsCompanion toDriftCompanion() {
    return TournamentsCompanion.insert(
      id: id,
      organizationId: organizationId,
      createdByUserId: Value(createdByUserId),
      name: name,
      description: Value(description),
      venueName: Value(venueName),
      venueAddress: Value(venueAddress),
      scheduledDate: scheduledDate,
      scheduledStartTime: Value(scheduledStartTime),
      scheduledEndTime: Value(scheduledEndTime),
      federationType: federationType,
      status: status,
      isTemplate: Value(isTemplate),
      templateId: Value(templateId),
      numberOfRings: Value(numberOfRings),
      settingsJson: Value(settingsJson.toString()),
      syncVersion: Value(syncVersion),
      isDeleted: Value(isDeleted),
      isDemoData: Value(isDemoData),
    );
  }

  TournamentEntity convertToEntity() {
    return TournamentEntity(
      id: id,
      organizationId: organizationId,
      createdByUserId: createdByUserId,
      name: name,
      description: description,
      venueName: venueName,
      venueAddress: venueAddress,
      scheduledDate: scheduledDate,
      scheduledStartTime: scheduledStartTime,
      scheduledEndTime: scheduledEndTime,
      federationType: FederationType.fromString(federationType),
      status: TournamentStatus.fromString(status),
      isTemplate: isTemplate,
      templateId: templateId,
      numberOfRings: numberOfRings,
      settingsJson: settingsJson,
      createdAt: createdAtTimestamp,
    );
  }
}
```

### Template 3: Repository Interface

**File:** `lib/features/tournament/domain/repositories/tournament_repository.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';

abstract class TournamentRepository {
  Future<Either<Failure, List<TournamentEntity>>> getTournamentsForOrganization(
    String organizationId,
  );
  Future<Either<Failure, TournamentEntity>> getTournamentById(String id);
  Future<Either<Failure, TournamentEntity>> createTournament(
    TournamentEntity tournament,
    String organizationId,
  );
  Future<Either<Failure, TournamentEntity>> updateTournament(
    TournamentEntity tournament,
  );
  Future<Either<Failure, Unit>> deleteTournament(String id);
}
```

### Template 4: Local Datasource

**File:** `lib/features/tournament/data/datasources/tournament_local_datasource.dart`

```dart
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/tournament/data/models/tournament_model.dart';

abstract class TournamentLocalDatasource {
  Future<List<TournamentModel>> getTournamentsForOrganization(String organizationId);
  Future<TournamentModel?> getTournamentById(String id);
  Future<void> insertTournament(TournamentModel tournament);
  Future<void> updateTournament(TournamentModel tournament);
  Future<void> deleteTournament(String id);
}

@LazySingleton(as: TournamentLocalDatasource)
class TournamentLocalDatasourceImplementation implements TournamentLocalDatasource {
  TournamentLocalDatasourceImplementation(this._database);
  final AppDatabase _database;

  @override
  Future<List<TournamentModel>> getTournamentsForOrganization(String organizationId) async {
    final entries = await _database.getTournamentsForOrganization(organizationId);
    return entries.map(TournamentModel.fromDriftEntry).toList();
  }

  @override
  Future<TournamentModel?> getTournamentById(String id) async {
    final entry = await _database.getTournamentById(id);
    if (entry == null) return null;
    return TournamentModel.fromDriftEntry(entry);
  }

  @override
  Future<void> insertTournament(TournamentModel tournament) async {
    await _database.insertTournament(tournament.toDriftCompanion());
  }

  @override
  Future<void> updateTournament(TournamentModel tournament) async {
    await _database.updateTournament(tournament.id, tournament.toDriftCompanion());
  }

  @override
  Future<void> deleteTournament(String id) async {
    await _database.softDeleteTournament(id);
  }
}
```

### Template 5: Remote Datasource

**File:** `lib/features/tournament/data/datasources/tournament_remote_datasource.dart`

```dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/features/tournament/data/models/tournament_model.dart';

abstract class TournamentRemoteDatasource {
  Future<List<TournamentModel>> getTournamentsForOrganization(String organizationId);
  Future<TournamentModel?> getTournamentById(String id);
  Future<TournamentModel> insertTournament(TournamentModel tournament);
  Future<TournamentModel> updateTournament(TournamentModel tournament);
  Future<void> deleteTournament(String id);
}

@LazySingleton(as: TournamentRemoteDatasource)
class TournamentRemoteDatasourceImplementation implements TournamentRemoteDatasource {
  TournamentRemoteDatasourceImplementation(this._supabase);
  final SupabaseClient _supabase;
  static const String _tableName = 'tournaments';

  @override
  Future<List<TournamentModel>> getTournamentsForOrganization(String organizationId) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('organization_id', organizationId)
        .eq('is_deleted', false)
        .order('scheduled_date', ascending: false);
    return response.map<TournamentModel>(TournamentModel.fromJson).toList();
  }

  @override
  Future<TournamentModel?> getTournamentById(String id) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('id', id)
        .eq('is_deleted', false)
        .maybeSingle();
    if (response == null) return null;
    return TournamentModel.fromJson(response);
  }

  @override
  Future<TournamentModel> insertTournament(TournamentModel tournament) async {
    final response = await _supabase
        .from(_tableName)
        .insert(tournament.toJson())
        .select()
        .single();
    return TournamentModel.fromJson(response);
  }

  @override
  Future<TournamentModel> updateTournament(TournamentModel tournament) async {
    final response = await _supabase
        .from(_tableName)
        .update(tournament.toJson())
        .eq('id', tournament.id)
        .select()
        .single();
    return TournamentModel.fromJson(response);
  }

  @override
  Future<void> deleteTournament(String id) async {
    await _supabase.from(_tableName).update({
      'is_deleted': true,
      'deleted_at_timestamp': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
```

### Template 6: Repository Implementation

**File:** `lib/features/tournament/data/repositories/tournament_repository_implementation.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/tournament/data/datasources/tournament_local_datasource.dart';
import 'package:tkd_brackets/features/tournament/data/datasources/tournament_remote_datasource.dart';
import 'package:tkd_brackets/features/tournament/data/models/tournament_model.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

@LazySingleton(as: TournamentRepository)
class TournamentRepositoryImplementation implements TournamentRepository {
  TournamentRepositoryImplementation(
    this._localDatasource,
    this._remoteDatasource,
    this._connectivityService,
  );

  final TournamentLocalDatasource _localDatasource;
  final TournamentRemoteDatasource _remoteDatasource;
  final ConnectivityService _connectivityService;

  @override
  Future<Either<Failure, List<TournamentEntity>>> getTournamentsForOrganization(
    String organizationId,
  ) async {
    try {
      // Try local first
      var models = await _localDatasource.getTournamentsForOrganization(organizationId);
      
      // If online, sync from remote
      if (await _connectivityService.hasInternetConnection()) {
        try {
          final remoteModels = await _remoteDatasource.getTournamentsForOrganization(organizationId);
          // Sync remote to local (simplified - no conflict resolution for now)
          for (final model in remoteModels) {
            final existing = await _localDatasource.getTournamentById(model.id);
            if (existing == null) {
              await _localDatasource.insertTournament(model);
            } else if (model.syncVersion > existing.syncVersion) {
              await _localDatasource.updateTournament(model);
            }
          }
          models = remoteModels;
        } on Exception catch (_) {
          // Use local data if remote fails
        }
      }
      
      return Right(models.map((m) => m.convertToEntity()).toList());
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TournamentEntity>> getTournamentById(String id) async {
    try {
      // Try local first
      final localModel = await _localDatasource.getTournamentById(id);
      if (localModel != null) {
        return Right(localModel.convertToEntity());
      }
      
      // Fallback to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        final remoteModel = await _remoteDatasource.getTournamentById(id);
        if (remoteModel != null) {
          await _localDatasource.insertTournament(remoteModel);
          return Right(remoteModel.convertToEntity());
        }
      }
      
      return const Left(LocalCacheAccessFailure(
        userFriendlyMessage: 'Tournament not found.',
      ));
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TournamentEntity>> createTournament(
    TournamentEntity tournament,
    String organizationId,
  ) async {
    try {
      final model = TournamentModel.convertFromEntity(
        tournament,
        organizationId: organizationId,
      );
      
      // Always save locally first
      await _localDatasource.insertTournament(model);
      
      // Sync to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.insertTournament(model);
        } on Exception catch (_) {
          // Queued for sync
        }
      }
      
      return Right(tournament);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TournamentEntity>> updateTournament(
    TournamentEntity tournament,
  ) async {
    try {
      // Read existing to get current syncVersion for remote sync
      final existing = await _localDatasource.getTournamentById(tournament.id);
      final newSyncVersion = (existing?.syncVersion ?? 0) + 1;
      
      final model = TournamentModel.convertFromEntity(
        tournament,
        syncVersion: newSyncVersion,
      );
      
      await _localDatasource.updateTournament(model);
      
      // Sync to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.updateTournament(model);
        } on Exception catch (_) {
          // Queued for sync
        }
      }
      
      return Right(tournament);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTournament(String id) async {
    try {
      await _localDatasource.deleteTournament(id);
      
      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.deleteTournament(id);
        } on Exception catch (_) {
          // Queued for sync
        }
      }
      
      return const Right(unit);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(technicalDetails: e.toString()));
    }
  }
}
```

## Dev Notes

### What Already Exists (From Epic 1/2)

✅ **Tournaments Table:** `lib/core/database/tables/tournaments_table.dart`
- Already defined with all fields
- Uses `BaseSyncMixin` and `BaseAuditMixin`
- Foreign keys to Organizations and Users

✅ **AppDatabase Tournament Methods:**
- `getTournamentsForOrganization(organizationId)`
- `getTournamentById(id)`
- `insertTournament(companion)`
- `updateTournament(id, companion)` - Auto-increments sync_version
- `softDeleteTournament(id)`

✅ **Pattern Reference:** `lib/features/auth/` Organization implementation
- Follow exact same structure
- Copy patterns from: entity → model → datasource → repository

### Critical Architecture Rules

**Domain Layer Isolation (MUST ENFORCE):**
- ❌ NO `import 'package:supabase_flutter/supabase_flutter.dart'` in domain
- ❌ NO `import 'package:drift/drift.dart'` in domain
- ❌ NO catching infrastructure exceptions in domain
- ✅ Domain only uses: `fpdart`, `freezed`, `equatable`, core Dart/Flutter

**Exception → Failure Mapping:**
- Repository implementations catch infrastructure exceptions
- Map to domain `Failure` types from `lib/core/error/failures.dart`
- Use cases receive `Either<Failure, T>`

**Clean Architecture Layer Rules:**

| Layer | Can Depend On | CANNOT Depend On |
|-------|---------------|------------------|
| **Presentation** | Domain | Data |
| **Domain** | Core only | Data, Presentation, External SDKs |
| **Data** | Domain (interfaces only) | Presentation |

### Key Patterns from Organization Implementation

1. **Enum Pattern:** Define typed enums with `fromString()` factory in entity file
2. **Model Conversions:** Three-way: JSON ↔ Model ↔ Entity ↔ Drift
3. **Repository Reads:** Local first, fallback to remote, cache remote results
4. **Repository Writes:** Local always, remote if online, fail silently for sync
5. **Sync Version:** Repository reads current, AppDatabase handles increment on update
6. **Soft Delete:** Set `is_deleted = true` + `deleted_at_timestamp`, never hard delete

### Testing Pattern

**File:** `test/features/tournament/data/repositories/tournament_repository_implementation_test.dart`

```dart
group('getTournamentById', () {
  test('should return TournamentEntity when local data exists', () async {
    // Arrange
    when(() => mockLocalDatasource.getTournamentById(any()))
        .thenAnswer((_) async => testModel);
    
    // Act
    final result = await repository.getTournamentById('test-id');
    
    // Assert
    expect(result.isRight(), true);
    verifyNever(() => mockRemoteDatasource.getTournamentById(any()));
  });

  test('should fallback to remote when local is empty and online', () async {
    // Arrange
    when(() => mockLocalDatasource.getTournamentById(any()))
        .thenAnswer((_) async => null);
    when(() => mockConnectivityService.hasInternetConnection())
        .thenAnswer((_) async => true);
    when(() => mockRemoteDatasource.getTournamentById(any()))
        .thenAnswer((_) async => testModel);
    
    // Act
    final result = await repository.getTournamentById('test-id');
    
    // Assert
    expect(result.isRight(), true);
    verify(() => mockLocalDatasource.insertTournament(testModel)).called(1);
  });
});
```

### File Naming Conventions

| Element | Pattern | Example |
|---------|---------|---------|
| **Implementation** | Full word | `tournament_repository_implementation.dart` NOT `impl` |
| **Files** | snake_case | `tournament_local_datasource.dart` |
| **Classes** | PascalCase, verbose | `TournamentRepositoryImplementation` |

### Dependencies

**Already available (pubspec.yaml):**
- `drift`, `supabase_flutter`, `fpdart`, `freezed_annotation`, `injectable`, `flutter_bloc`

**Already imported in codebase:**
- `lib/core/error/failures.dart` - Failure hierarchy
- `lib/core/network/connectivity_service.dart` - Network detection
- `lib/core/database/app_database.dart` - Drift database

### References

**Pattern References (Copy From):**
- `lib/features/auth/domain/entities/organization_entity.dart` - Entity + enums
- `lib/features/auth/data/models/organization_model.dart` - Model conversions
- `lib/features/auth/data/datasources/organization_local_datasource.dart` - Local datasource
- `lib/features/auth/data/datasources/organization_remote_datasource.dart` - Remote datasource
- `lib/features/auth/data/repositories/organization_repository_implementation.dart` - Repository
- `lib/features/auth/domain/repositories/organization_repository.dart` - Interface

**Existing Tournament Infrastructure:**
- `lib/core/database/tables/tournaments_table.dart` - Table definition
- `lib/core/database/app_database.dart` - Tournament CRUD methods (lines 205-262)

**Architecture:**
- [Source: planning-artifacts/architecture.md#Clean Architecture] - Layer rules
- [Source: planning-artifacts/architecture.md#Failure Hierarchy] - Error handling

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

1. Review existing `tournaments_table.dart` and `app_database.dart` methods before starting
2. Copy patterns exactly from Organization implementation
3. Ensure all three model conversions are implemented (JSON, Drift, Entity)
4. Run `dart run build_runner build` after creating entity and model
5. Verify DI registrations appear in `injection.config.dart`
6. Test repository offline-first behavior thoroughly

### File List

**To Create:**
- `lib/features/tournament/domain/entities/tournament_entity.dart`
- `lib/features/tournament/domain/entities/tournament_entity.freezed.dart` (generated)
- `lib/features/tournament/data/models/tournament_model.dart`
- `lib/features/tournament/data/models/tournament_model.freezed.dart` (generated)
- `lib/features/tournament/data/models/tournament_model.g.dart` (generated)
- `lib/features/tournament/domain/repositories/tournament_repository.dart`
- `lib/features/tournament/data/datasources/tournament_local_datasource.dart`
- `lib/features/tournament/data/datasources/tournament_remote_datasource.dart`
- `lib/features/tournament/data/repositories/tournament_repository_implementation.dart`
- `test/features/tournament/domain/entities/tournament_entity_test.dart`
- `test/features/tournament/data/models/tournament_model_test.dart`
- `test/features/tournament/data/datasources/tournament_local_datasource_test.dart`
- `test/features/tournament/data/datasources/tournament_remote_datasource_test.dart`
- `test/features/tournament/data/repositories/tournament_repository_implementation_test.dart`

**To Update:**
- `lib/features/tournament/tournament.dart` - Add new exports
- `lib/core/di/injection.config.dart` - Regenerate via injectable_generator
