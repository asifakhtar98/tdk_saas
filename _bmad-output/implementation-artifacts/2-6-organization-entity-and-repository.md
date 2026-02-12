# Story 2.6: Organization Entity & Repository

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

**As a** developer,
**I want** the Organization entity and repository implemented,
**So that** organization data can be managed for multi-tenancy.

## Acceptance Criteria

- [x] **AC1**: `OrganizationEntity` exists in `lib/features/auth/domain/entities/organization_entity.dart` with all required fields
- [x] **AC2**: `organizations` table exists in Drift (**ALREADY EXISTS** — `lib/core/database/tables/organizations_table.dart`)
- [x] **AC3**: `OrganizationRepository` interface exists in `lib/features/auth/domain/repositories/organization_repository.dart`
- [x] **AC4**: `OrganizationRepositoryImplementation` implements local (Drift) and remote (Supabase) operations with offline-first strategy
- [x] **AC5**: `OrganizationModel` handles JSON serialization (`fromJson`/`toJson`), Drift conversion (`fromDriftEntry`/`toDriftCompanion`), and entity conversion (`convertToEntity`/`convertFromEntity`)
- [x] **AC6**: `OrganizationLocalDatasource` wraps `AppDatabase` organization methods with model conversion
- [x] **AC7**: `OrganizationRemoteDatasource` wraps Supabase `organizations` table operations
- [x] **AC8**: Organization is linked to users via `organization_id` (already established in Users table FK)
- [x] **AC9**: Unit tests verify organization CRUD operations (mocked datasources) — 69 tests passing
- [x] **AC10**: `flutter analyze` passes with zero errors from new code (30 pre-existing info/warnings remain)
- [x] **AC11**: `dart run build_runner build` completes successfully (223 outputs)
- [x] **AC12**: Auth barrel file (`lib/features/auth/auth.dart`) updated with all new exports

---

## Project Context

> **⚠️ CRITICAL: All paths are relative to `tkd_brackets/`**
>
> Project root: `/Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/`
>
> When creating files, always work within `tkd_brackets/lib/`

---

## Dependencies

### Upstream (Required) ✅

| Story                      | Provides                                                      |
| -------------------------- | ------------------------------------------------------------- |
| 1.5 Drift Database         | `AppDatabase` with organizations table and CRUD methods       |
| 1.6 Supabase Client        | `SupabaseClient` instance registered in DI                    |
| 1.8 Connectivity Service   | `ConnectivityService` for online/offline detection            |
| 2.1 Auth Feature Structure | Feature directory structure, `UseCase<T, Params>` base class  |
| 2.2 User Entity & Repo     | `UserEntity`, `UserModel` (establishes the pattern to follow) |
| 1.4 Error Handling         | `Failure` hierarchy in `core/error/failures.dart`             |

### Downstream (Enables)

- Story 2.7: Create Organization Use Case (consumes `OrganizationRepository`)
- Story 2.8: Invitation Entity & Send Invite (needs organization context)
- Story 2.9: RBAC Permission Service (enforces org-level permissions)
- Story 2.10: Demo-to-Production Migration (migrates demo org data)

---

## ⚠️ CRITICAL: What Already Exists

> **DO NOT recreate these — they are implemented and working!**

### Organizations Table (Drift) — `lib/core/database/tables/organizations_table.dart`

```dart
@DataClassName('OrganizationEntry')
class Organizations extends Table with BaseSyncMixin, BaseAuditMixin {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get slug => text().unique()();
  TextColumn get subscriptionTier => text().withDefault(const Constant('free'))();
  TextColumn get subscriptionStatus => text().withDefault(const Constant('active'))();
  IntColumn get maxTournamentsPerMonth => integer().withDefault(const Constant(2))();
  IntColumn get maxActiveBrackets => integer().withDefault(const Constant(3))();
  IntColumn get maxParticipantsPerBracket => integer().withDefault(const Constant(32))();
  IntColumn get maxParticipantsPerTournament => integer().withDefault(const Constant(100))();
  IntColumn get maxScorers => integer().withDefault(const Constant(2))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  // BaseSyncMixin adds: syncVersion, isDeleted, deletedAtTimestamp, isDemoData
  // BaseAuditMixin adds: createdAtTimestamp, updatedAtTimestamp
  @override Set<Column> get primaryKey => {id};
}
```

### AppDatabase Organization Methods — `lib/core/database/app_database.dart`

```dart
// All these methods already exist — use them, don't recreate!
Future<List<OrganizationEntry>> getActiveOrganizations()
Future<OrganizationEntry?> getOrganizationById(String id)
Future<int> insertOrganization(OrganizationsCompanion org)
Future<bool> updateOrganization(String id, OrganizationsCompanion org)
Future<bool> softDeleteOrganization(String id)
```

### Supabase Organizations Table Schema (Remote)

```sql
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    subscription_tier TEXT NOT NULL DEFAULT 'free'
        CHECK (subscription_tier IN ('free', 'pro', 'enterprise')),
    subscription_status TEXT NOT NULL DEFAULT 'active'
        CHECK (subscription_status IN ('active', 'past_due', 'cancelled')),
    max_tournaments_per_month INTEGER NOT NULL DEFAULT 2,
    max_active_brackets INTEGER NOT NULL DEFAULT 3,
    max_participants_per_bracket INTEGER NOT NULL DEFAULT 32,
    max_participants_per_tournament INTEGER NOT NULL DEFAULT 100,
    max_scorers INTEGER NOT NULL DEFAULT 2,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sync_version INTEGER NOT NULL DEFAULT 1,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at_timestamp TIMESTAMPTZ,
    is_demo_data BOOLEAN NOT NULL DEFAULT FALSE,
    created_at_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### Failure Hierarchy — `lib/core/error/failures.dart`

```dart
// Already exists — use these, don't recreate:
abstract class Failure extends Equatable { ... }
class ServerConnectionFailure extends Failure { ... }
class LocalCacheAccessFailure extends Failure { ... }
class LocalCacheWriteFailure extends Failure { ... }
```

### ConnectivityService — `lib/core/network/connectivity_service.dart`

```dart
// Already exists — inject via DI:
abstract class ConnectivityService {
  Future<bool> hasInternetConnection();
  // ...
}
```

### Existing Pattern Reference — `UserModel` (follow this exactly)

```dart
// UserModel uses freezed + json_serializable with @JsonKey annotations
// It has these factory methods:
//   UserModel.fromJson(Map<String, dynamic> json) — via json_serializable
//   UserModel.fromDriftEntry(UserEntry entry) — manual conversion
//   UserModel.convertFromEntity(UserEntity entity, {...}) — from domain entity
// And these instance methods:
//   toJson() — via json_serializable
//   toDriftCompanion() — returns UsersCompanion
//   convertToEntity() — returns UserEntity
```

---

## ⚠️ CRITICAL: Naming & Architecture Conventions

> **Enforce these — common LLM mistakes highlighted!**

### Class Naming

| Item                   | Correct Name                                 | ❌ Common Mistake                   |
| ---------------------- | -------------------------------------------- | ---------------------------------- |
| Entity                 | `OrganizationEntity`                         | `Organization`                     |
| Model                  | `OrganizationModel`                          | `OrganizationDto`                  |
| Repository interface   | `OrganizationRepository`                     | `IOrganizationRepository`          |
| Repository impl        | `OrganizationRepositoryImplementation`       | `OrganizationRepositoryImpl`       |
| Local datasource       | `OrganizationLocalDatasource`                | `OrganizationLocalDataSource`      |
| Local datasource impl  | `OrganizationLocalDatasourceImplementation`  | `OrganizationLocalDatasourceImpl`  |
| Remote datasource      | `OrganizationRemoteDatasource`               | `OrganizationRemoteDataSource`     |
| Remote datasource impl | `OrganizationRemoteDatasourceImplementation` | `OrganizationRemoteDatasourceImpl` |

### File Naming (snake_case)

| File                 | Correct Path                                                                      |
| -------------------- | --------------------------------------------------------------------------------- |
| Entity               | `lib/features/auth/domain/entities/organization_entity.dart`                      |
| Model                | `lib/features/auth/data/models/organization_model.dart`                           |
| Repository interface | `lib/features/auth/domain/repositories/organization_repository.dart`              |
| Repository impl      | `lib/features/auth/data/repositories/organization_repository_implementation.dart` |
| Local datasource     | `lib/features/auth/data/datasources/organization_local_datasource.dart`           |
| Remote datasource    | `lib/features/auth/data/datasources/organization_remote_datasource.dart`          |

### Architecture Rules

- ❌ Domain layer CANNOT import from data layer or external SDKs
- ❌ Entity CANNOT have `fromJson`/`toJson` — that's the model's job
- ❌ Repository interface CANNOT reference `SupabaseClient`, `AppDatabase`, or `OrganizationModel`
- ✅ Domain layer: only `freezed`, `fpdart`, `core/error/failures.dart`
- ✅ Data layer: can import domain interfaces, `injectable`, `drift`, `supabase_flutter`

### JSON Field Names → snake_case (for Supabase)

```
subscription_tier, subscription_status, max_tournaments_per_month,
max_active_brackets, max_participants_per_bracket,
max_participants_per_tournament, max_scorers, is_active,
is_deleted, deleted_at_timestamp, is_demo_data,
created_at_timestamp, updated_at_timestamp, sync_version
```

---

## Tasks

### Task 1: Create OrganizationEntity (Domain Layer) — AC1

**File:** `lib/features/auth/domain/entities/organization_entity.dart`

**⚠️ CRITICAL DIFFERENCES FROM EPICS:** The epics list `ownerId` and `logoUrl` fields. These do NOT exist in the Supabase schema or Drift table. The actual schema has `subscription_tier`, `subscription_status`, and limit fields instead. **Use the actual schema, not the epics summary.**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'organization_entity.freezed.dart';

/// Immutable domain entity representing an organization.
///
/// An organization is the top-level tenant in the multi-tenancy model.
/// All tournaments, divisions, and participants belong to an organization.
@freezed
class OrganizationEntity with _$OrganizationEntity {
  const factory OrganizationEntity({
    /// Unique identifier (UUID).
    required String id,

    /// Organization display name (e.g., "Dragon Martial Arts").
    required String name,

    /// URL-safe slug, unique across all organizations.
    required String slug,

    /// Subscription tier: 'free', 'pro', 'enterprise'.
    required SubscriptionTier subscriptionTier,

    /// Subscription status: 'active', 'past_due', 'cancelled'.
    required SubscriptionStatus subscriptionStatus,

    /// Max tournaments per month for this tier.
    required int maxTournamentsPerMonth,

    /// Max active brackets for this tier.
    required int maxActiveBrackets,

    /// Max participants per bracket for this tier.
    required int maxParticipantsPerBracket,

    /// Max participants per tournament (soft cap).
    required int maxParticipantsPerTournament,

    /// Max scorers for this tier.
    required int maxScorers,

    /// Whether the organization is active.
    required bool isActive,

    /// When the organization was created.
    required DateTime createdAt,
  }) = _OrganizationEntity;
}

/// Enum for subscription tiers.
enum SubscriptionTier {
  free('free'),
  pro('pro'),
  enterprise('enterprise');

  const SubscriptionTier(this.value);

  final String value;

  /// Parse tier from database string value.
  static SubscriptionTier fromString(String value) {
    return SubscriptionTier.values.firstWhere(
      (tier) => tier.value == value,
      orElse: () => SubscriptionTier.free,
    );
  }
}

/// Enum for subscription statuses.
enum SubscriptionStatus {
  active('active'),
  pastDue('past_due'),
  cancelled('cancelled');

  const SubscriptionStatus(this.value);

  final String value;

  /// Parse status from database string value.
  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SubscriptionStatus.active,
    );
  }
}
```

---

### Task 2: Create OrganizationRepository Interface (Domain Layer) — AC3

**File:** `lib/features/auth/domain/repositories/organization_repository.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/organization_entity.dart';

/// Repository interface for organization operations.
///
/// Implementations handle data source coordination
/// (local Drift, remote Supabase).
abstract class OrganizationRepository {
  /// Get organization by ID.
  /// Returns [Left(Failure)] if not found or error occurs.
  Future<Either<Failure, OrganizationEntity>> getOrganizationById(
    String id,
  );

  /// Get organization by slug.
  /// Returns [Left(Failure)] if not found or error occurs.
  Future<Either<Failure, OrganizationEntity>> getOrganizationBySlug(
    String slug,
  );

  /// Get all active (non-deleted) organizations.
  Future<Either<Failure, List<OrganizationEntity>>>
      getActiveOrganizations();

  /// Create a new organization (local + remote sync).
  /// Returns created organization on success.
  Future<Either<Failure, OrganizationEntity>> createOrganization(
    OrganizationEntity organization,
  );

  /// Update an existing organization.
  /// Returns updated organization on success.
  Future<Either<Failure, OrganizationEntity>> updateOrganization(
    OrganizationEntity organization,
  );

  /// Delete an organization (soft delete).
  Future<Either<Failure, Unit>> deleteOrganization(String id);
}
```

---

### Task 3: Create OrganizationModel (Data Layer) — AC5

**File:** `lib/features/auth/data/models/organization_model.dart`

**⚠️ CRITICAL:** Follow the exact same pattern as `UserModel`:
- `freezed` + `json_serializable` with `@JsonKey` annotations for snake_case mapping
- `fromDriftEntry()` factory for Drift → Model
- `convertFromEntity()` factory for Entity → Model
- `toDriftCompanion()` method for Model → Drift Companion
- `convertToEntity()` method for Model → Entity
- `fromJson()` / `toJson()` via json_serializable for Supabase JSON

**⚠️ CRITICAL: `@JsonKey` usage with freezed**
Add this suppress comment at the top of the file (same as `user_model.dart`):
```dart
// Freezed uses @JsonKey on constructor parameters which triggers this lint.
// This is the documented freezed pattern and works correctly with code gen.
// ignore_for_file: invalid_annotation_target
```

```dart
// Freezed uses @JsonKey on constructor parameters which triggers this lint.
// This is the documented freezed pattern and works correctly with code gen.
// ignore_for_file: invalid_annotation_target

import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/auth/domain/entities/organization_entity.dart';

part 'organization_model.freezed.dart';
part 'organization_model.g.dart';

/// Data model for Organization with JSON and database conversions.
///
/// Uses freezed for immutability and json_serializable for JSON handling.
/// Uses @JsonKey for each field to map to snake_case JSON keys.
@freezed
class OrganizationModel with _$OrganizationModel {
  /// Creates an [OrganizationModel] instance.
  const factory OrganizationModel({
    required String id,
    required String name,
    required String slug,
    @JsonKey(name: 'subscription_tier')
    required String subscriptionTier,
    @JsonKey(name: 'subscription_status')
    required String subscriptionStatus,
    @JsonKey(name: 'max_tournaments_per_month')
    required int maxTournamentsPerMonth,
    @JsonKey(name: 'max_active_brackets')
    required int maxActiveBrackets,
    @JsonKey(name: 'max_participants_per_bracket')
    required int maxParticipantsPerBracket,
    @JsonKey(name: 'max_participants_per_tournament')
    required int maxParticipantsPerTournament,
    @JsonKey(name: 'max_scorers') required int maxScorers,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at_timestamp')
    required DateTime createdAtTimestamp,
    @JsonKey(name: 'updated_at_timestamp')
    required DateTime updatedAtTimestamp,
    @JsonKey(name: 'sync_version') required int syncVersion,
    @JsonKey(name: 'is_deleted') required bool isDeleted,
    @JsonKey(name: 'is_demo_data') required bool isDemoData,
    @JsonKey(name: 'deleted_at_timestamp')
    DateTime? deletedAtTimestamp,
  }) = _OrganizationModel;

  /// Private constructor for freezed mixin.
  const OrganizationModel._();

  /// Convert from Supabase JSON to [OrganizationModel].
  factory OrganizationModel.fromJson(Map<String, dynamic> json) =>
      _$OrganizationModelFromJson(json);

  /// Convert from Drift-generated [OrganizationEntry] to
  /// [OrganizationModel].
  factory OrganizationModel.fromDriftEntry(
    OrganizationEntry entry,
  ) {
    return OrganizationModel(
      id: entry.id,
      name: entry.name,
      slug: entry.slug,
      subscriptionTier: entry.subscriptionTier,
      subscriptionStatus: entry.subscriptionStatus,
      maxTournamentsPerMonth: entry.maxTournamentsPerMonth,
      maxActiveBrackets: entry.maxActiveBrackets,
      maxParticipantsPerBracket: entry.maxParticipantsPerBracket,
      maxParticipantsPerTournament:
          entry.maxParticipantsPerTournament,
      maxScorers: entry.maxScorers,
      isActive: entry.isActive,
      createdAtTimestamp: entry.createdAtTimestamp,
      updatedAtTimestamp: entry.updatedAtTimestamp,
      syncVersion: entry.syncVersion,
      isDeleted: entry.isDeleted,
      isDemoData: entry.isDemoData,
      deletedAtTimestamp: entry.deletedAtTimestamp,
    );
  }

  /// Create [OrganizationModel] from domain
  /// [OrganizationEntity].
  factory OrganizationModel.convertFromEntity(
    OrganizationEntity entity, {
    int syncVersion = 1,
    bool isDeleted = false,
    bool isDemoData = false,
    DateTime? updatedAtTimestamp,
    DateTime? deletedAtTimestamp,
  }) {
    final now = DateTime.now();
    return OrganizationModel(
      id: entity.id,
      name: entity.name,
      slug: entity.slug,
      subscriptionTier: entity.subscriptionTier.value,
      subscriptionStatus: entity.subscriptionStatus.value,
      maxTournamentsPerMonth: entity.maxTournamentsPerMonth,
      maxActiveBrackets: entity.maxActiveBrackets,
      maxParticipantsPerBracket: entity.maxParticipantsPerBracket,
      maxParticipantsPerTournament:
          entity.maxParticipantsPerTournament,
      maxScorers: entity.maxScorers,
      isActive: entity.isActive,
      createdAtTimestamp: entity.createdAt,
      updatedAtTimestamp: updatedAtTimestamp ?? now,
      syncVersion: syncVersion,
      isDeleted: isDeleted,
      isDemoData: isDemoData,
      deletedAtTimestamp: deletedAtTimestamp,
    );
  }

  /// Convert to Drift [OrganizationsCompanion] for database
  /// operations.
  OrganizationsCompanion toDriftCompanion() {
    return OrganizationsCompanion.insert(
      id: id,
      name: name,
      slug: slug,
      subscriptionTier: Value(subscriptionTier),
      subscriptionStatus: Value(subscriptionStatus),
      maxTournamentsPerMonth: Value(maxTournamentsPerMonth),
      maxActiveBrackets: Value(maxActiveBrackets),
      maxParticipantsPerBracket:
          Value(maxParticipantsPerBracket),
      maxParticipantsPerTournament:
          Value(maxParticipantsPerTournament),
      maxScorers: Value(maxScorers),
      isActive: Value(isActive),
      syncVersion: Value(syncVersion),
      isDeleted: Value(isDeleted),
      isDemoData: Value(isDemoData),
    );
  }

  /// Convert [OrganizationModel] to domain
  /// [OrganizationEntity].
  OrganizationEntity convertToEntity() {
    return OrganizationEntity(
      id: id,
      name: name,
      slug: slug,
      subscriptionTier:
          SubscriptionTier.fromString(subscriptionTier),
      subscriptionStatus:
          SubscriptionStatus.fromString(subscriptionStatus),
      maxTournamentsPerMonth: maxTournamentsPerMonth,
      maxActiveBrackets: maxActiveBrackets,
      maxParticipantsPerBracket: maxParticipantsPerBracket,
      maxParticipantsPerTournament:
          maxParticipantsPerTournament,
      maxScorers: maxScorers,
      isActive: isActive,
      createdAt: createdAtTimestamp,
    );
  }
}
```

---

### Task 4: Create OrganizationLocalDatasource (Data Layer) — AC6

**File:** `lib/features/auth/data/datasources/organization_local_datasource.dart`

**⚠️ CRITICAL:** Follow the exact same pattern as `UserLocalDatasource`.
- Abstract class defines the interface
- Implementation class wraps `AppDatabase` methods
- All methods convert between `OrganizationEntry` (Drift) and `OrganizationModel`
- `@LazySingleton(as: OrganizationLocalDatasource)` annotation

**⚠️ PRE-REQUISITE:** Before creating this file, add `getOrganizationBySlug` to `AppDatabase` (see Dev Notes below for the code). This enables offline slug lookups.

```dart
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/auth/data/models/organization_model.dart';

/// Local datasource for organization operations using Drift
/// database.
///
/// Wraps existing [AppDatabase] methods with model conversion.
abstract class OrganizationLocalDatasource {
  Future<OrganizationModel?> getOrganizationById(String id);
  Future<OrganizationModel?> getOrganizationBySlug(String slug);
  Future<List<OrganizationModel>> getActiveOrganizations();
  Future<void> insertOrganization(OrganizationModel organization);
  Future<void> updateOrganization(OrganizationModel organization);
  Future<void> deleteOrganization(String id);
}

@LazySingleton(as: OrganizationLocalDatasource)
class OrganizationLocalDatasourceImplementation
    implements OrganizationLocalDatasource {
  OrganizationLocalDatasourceImplementation(this._database);

  final AppDatabase _database;

  @override
  Future<OrganizationModel?> getOrganizationById(
    String id,
  ) async {
    final entry = await _database.getOrganizationById(id);
    if (entry == null) return null;
    return OrganizationModel.fromDriftEntry(entry);
  }

  @override
  Future<OrganizationModel?> getOrganizationBySlug(
    String slug,
  ) async {
    final entry =
        await _database.getOrganizationBySlug(slug);
    if (entry == null) return null;
    return OrganizationModel.fromDriftEntry(entry);
  }

  @override
  Future<List<OrganizationModel>> getActiveOrganizations() async {
    final entries = await _database.getActiveOrganizations();
    return entries
        .map(OrganizationModel.fromDriftEntry)
        .toList();
  }

  @override
  Future<void> insertOrganization(
    OrganizationModel organization,
  ) async {
    await _database.insertOrganization(
      organization.toDriftCompanion(),
    );
  }

  @override
  Future<void> updateOrganization(
    OrganizationModel organization,
  ) async {
    await _database.updateOrganization(
      organization.id,
      organization.toDriftCompanion(),
    );
  }

  @override
  Future<void> deleteOrganization(String id) async {
    await _database.softDeleteOrganization(id);
  }
}
```

---

### Task 5: Create OrganizationRemoteDatasource (Data Layer) — AC7

**File:** `lib/features/auth/data/datasources/organization_remote_datasource.dart`

**⚠️ CRITICAL:** Follow the exact same pattern as `UserRemoteDatasource`.
- Uses `SupabaseClient` directly
- Table name is `'organizations'`
- All queries filter `is_deleted = false` for reads
- Soft delete uses `is_deleted = true` + `deleted_at_timestamp`
- `@LazySingleton(as: OrganizationRemoteDatasource)` annotation

**⚠️ NOTE:** Unlike `UserRemoteDatasource`, this datasource does NOT need `currentAuthUser` or `authStateChanges` — those are auth-specific concerns.

```dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/features/auth/data/models/organization_model.dart';

/// Remote datasource for organization operations using Supabase.
///
/// All queries go through RLS-protected tables.
abstract class OrganizationRemoteDatasource {
  Future<OrganizationModel?> getOrganizationById(String id);
  Future<OrganizationModel?> getOrganizationBySlug(String slug);
  Future<List<OrganizationModel>> getActiveOrganizations();
  Future<OrganizationModel> insertOrganization(
    OrganizationModel organization,
  );
  Future<OrganizationModel> updateOrganization(
    OrganizationModel organization,
  );
  Future<void> deleteOrganization(String id);
}

@LazySingleton(as: OrganizationRemoteDatasource)
class OrganizationRemoteDatasourceImplementation
    implements OrganizationRemoteDatasource {
  OrganizationRemoteDatasourceImplementation(this._supabase);

  final SupabaseClient _supabase;

  static const String _tableName = 'organizations';

  @override
  Future<OrganizationModel?> getOrganizationById(
    String id,
  ) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('id', id)
        .eq('is_deleted', false)
        .maybeSingle();

    if (response == null) return null;
    return OrganizationModel.fromJson(response);
  }

  @override
  Future<OrganizationModel?> getOrganizationBySlug(
    String slug,
  ) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('slug', slug)
        .eq('is_deleted', false)
        .maybeSingle();

    if (response == null) return null;
    return OrganizationModel.fromJson(response);
  }

  @override
  Future<List<OrganizationModel>> getActiveOrganizations() async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('is_deleted', false)
        .order('name');

    return response
        .map<OrganizationModel>(OrganizationModel.fromJson)
        .toList();
  }

  @override
  Future<OrganizationModel> insertOrganization(
    OrganizationModel organization,
  ) async {
    final response = await _supabase
        .from(_tableName)
        .insert(organization.toJson())
        .select()
        .single();

    return OrganizationModel.fromJson(response);
  }

  @override
  Future<OrganizationModel> updateOrganization(
    OrganizationModel organization,
  ) async {
    final response = await _supabase
        .from(_tableName)
        .update(organization.toJson())
        .eq('id', organization.id)
        .select()
        .single();

    return OrganizationModel.fromJson(response);
  }

  @override
  Future<void> deleteOrganization(String id) async {
    // Soft delete by setting is_deleted = true
    await _supabase.from(_tableName).update({
      'is_deleted': true,
      'deleted_at_timestamp': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
```

---

### Task 6: Create OrganizationRepositoryImplementation (Data Layer) — AC4

**File:** `lib/features/auth/data/repositories/organization_repository_implementation.dart`

**⚠️ CRITICAL:** Follow the exact same offline-first pattern as `UserRepositoryImplementation`:
- Read: Try local first, fallback to remote if online
- Write: Write to local first, sync to remote if online
- All methods return `Either<Failure, T>`
- Catch `Exception` specifically (not bare `catch`)
- Use `LocalCacheAccessFailure` for read errors, `LocalCacheWriteFailure` for write errors

**⚠️ CRITICAL: DO NOT manually increment `syncVersion`** — `AppDatabase.updateOrganization()` already increments `syncVersion` and sets `updatedAtTimestamp` inside a transaction. If the repository also increments, you get a **double increment bug**. Let the database handle it.

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/auth/data/datasources/organization_local_datasource.dart';
import 'package:tkd_brackets/features/auth/data/datasources/organization_remote_datasource.dart';
import 'package:tkd_brackets/features/auth/data/models/organization_model.dart';
import 'package:tkd_brackets/features/auth/domain/entities/organization_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/organization_repository.dart';

/// Implementation of [OrganizationRepository] with offline-first
/// strategy.
///
/// - Read: Try local first, fallback to remote if not found
/// - Write: Write to local, queue for sync if offline
/// - Sync: Last-Write-Wins based on sync_version
@LazySingleton(as: OrganizationRepository)
class OrganizationRepositoryImplementation
    implements OrganizationRepository {
  OrganizationRepositoryImplementation(
    this._localDatasource,
    this._remoteDatasource,
    this._connectivityService,
  );

  final OrganizationLocalDatasource _localDatasource;
  final OrganizationRemoteDatasource _remoteDatasource;
  final ConnectivityService _connectivityService;

  @override
  Future<Either<Failure, OrganizationEntity>>
      getOrganizationById(String id) async {
    try {
      // Try local first
      final localOrg =
          await _localDatasource.getOrganizationById(id);
      if (localOrg != null) {
        return Right(localOrg.convertToEntity());
      }

      // Fallback to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        final remoteOrg =
            await _remoteDatasource.getOrganizationById(id);
        if (remoteOrg != null) {
          // Cache locally
          await _localDatasource.insertOrganization(remoteOrg);
          return Right(remoteOrg.convertToEntity());
        }
      }

      return const Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Organization not found.',
          technicalDetails:
              'No organization found with the given ID '
              'in local or remote.',
        ),
      );
    } on Exception catch (e) {
      return Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Failed to retrieve organization.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, OrganizationEntity>>
      getOrganizationBySlug(String slug) async {
    try {
      // Try local first (offline-first)
      final localOrg =
          await _localDatasource.getOrganizationBySlug(slug);
      if (localOrg != null) {
        return Right(localOrg.convertToEntity());
      }

      // Fallback to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        final remoteOrg =
            await _remoteDatasource.getOrganizationBySlug(slug);
        if (remoteOrg != null) {
          // Cache locally
          await _localDatasource.insertOrganization(remoteOrg);
          return Right(remoteOrg.convertToEntity());
        }
      }

      return const Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Organization not found.',
          technicalDetails:
              'No organization found with the given slug.',
        ),
      );
    } on Exception catch (e) {
      return Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Failed to retrieve organization.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<OrganizationEntity>>>
      getActiveOrganizations() async {
    try {
      // Try local first
      var organizations =
          await _localDatasource.getActiveOrganizations();

      // If online, fetch from remote and update local cache
      if (await _connectivityService.hasInternetConnection()) {
        try {
          final remoteOrgs =
              await _remoteDatasource.getActiveOrganizations();
          // Sync remote to local
          for (final org in remoteOrgs) {
            final existing =
                await _localDatasource.getOrganizationById(
              org.id,
            );
            if (existing == null) {
              await _localDatasource.insertOrganization(org);
            } else if (org.syncVersion > existing.syncVersion) {
              await _localDatasource.updateOrganization(org);
            }
          }
          organizations = remoteOrgs;
        } on Exception catch (_) {
          // Use local data if remote fails
        }
      }

      return Right(
        organizations
            .map((m) => m.convertToEntity())
            .toList(),
      );
    } on Exception catch (e) {
      return Left(
        LocalCacheAccessFailure(
          userFriendlyMessage:
              'Failed to retrieve organizations.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, OrganizationEntity>>
      createOrganization(
    OrganizationEntity organization,
  ) async {
    try {
      final model =
          OrganizationModel.convertFromEntity(organization);

      // Always save locally first
      await _localDatasource.insertOrganization(model);

      // Sync to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.insertOrganization(model);
        } on Exception catch (_) {
          // Queued for sync — continue with local success
        }
      }

      return Right(organization);
    } on Exception catch (e) {
      return Left(
        LocalCacheWriteFailure(
          userFriendlyMessage:
              'Failed to create organization.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, OrganizationEntity>>
      updateOrganization(
    OrganizationEntity organization,
  ) async {
    try {
      // DO NOT manually increment syncVersion here!
      // AppDatabase.updateOrganization() already increments
      // syncVersion and sets updatedAtTimestamp in a
      // transaction.
      final model = OrganizationModel.convertFromEntity(
        organization,
      );

      await _localDatasource.updateOrganization(model);

      // Sync to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.updateOrganization(model);
        } on Exception catch (_) {
          // Queued for sync — continue with local success
        }
      }

      return Right(organization);
    } on Exception catch (e) {
      return Left(
        LocalCacheWriteFailure(
          userFriendlyMessage:
              'Failed to update organization.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteOrganization(
    String id,
  ) async {
    try {
      await _localDatasource.deleteOrganization(id);

      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.deleteOrganization(id);
        } on Exception catch (_) {
          // Queued for sync
        }
      }

      return const Right(unit);
    } on Exception catch (e) {
      return Left(
        LocalCacheWriteFailure(
          userFriendlyMessage:
              'Failed to delete organization.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }
}
```

---

### Task 7: Update Auth Barrel File — AC12

**File:** `lib/features/auth/auth.dart`

**Add these exports** (maintain alphabetical order within each section):

```dart
// Data - Datasources (add these two)
export 'data/datasources/organization_local_datasource.dart';
export 'data/datasources/organization_remote_datasource.dart';

// Data - Models (add this)
export 'data/models/organization_model.dart';

// Data - Repositories (add this)
export 'data/repositories/organization_repository_implementation.dart';

// Domain - Entities (add this)
export 'domain/entities/organization_entity.dart';

// Domain - Repositories (add this)
export 'domain/repositories/organization_repository.dart';
```

**Expected final barrel file after edits:**

```dart
/// Authentication feature - exports public APIs.
library;

// Data - Datasources (for DI visibility)
export 'data/datasources/organization_local_datasource.dart';
export 'data/datasources/organization_remote_datasource.dart';
export 'data/datasources/supabase_auth_datasource.dart';
export 'data/datasources/user_local_datasource.dart';
export 'data/datasources/user_remote_datasource.dart';

// Data - Models
export 'data/models/organization_model.dart';
export 'data/models/user_model.dart';

// Data - Repositories
export 'data/repositories/auth_repository_implementation.dart';
export 'data/repositories/organization_repository_implementation.dart';
export 'data/repositories/user_repository_implementation.dart';

// Domain - Entities
export 'domain/entities/organization_entity.dart';
export 'domain/entities/user_entity.dart';

// Domain - Repositories
export 'domain/repositories/auth_repository.dart';
export 'domain/repositories/organization_repository.dart';
export 'domain/repositories/user_repository.dart';

// Domain - Use Cases
export 'domain/usecases/get_current_user_use_case.dart';
export 'domain/usecases/sign_in_with_email_params.dart';
export 'domain/usecases/sign_in_with_email_use_case.dart';
export 'domain/usecases/sign_out_use_case.dart';
export 'domain/usecases/sign_up_with_email_params.dart';
export 'domain/usecases/sign_up_with_email_use_case.dart';
export 'domain/usecases/verify_magic_link_params.dart';
export 'domain/usecases/verify_magic_link_use_case.dart';

// Presentation - BLoC
export 'presentation/bloc/authentication_bloc.dart';
export 'presentation/bloc/authentication_event.dart';
export 'presentation/bloc/authentication_state.dart';
```

---

### Task 8: Run build_runner — AC11

```bash
cd tkd_brackets && dart run build_runner build --delete-conflicting-outputs
```

This generates:
- `organization_entity.freezed.dart`
- `organization_model.freezed.dart`
- `organization_model.g.dart`
- Updated `injection.config.dart` (auto-registers new `@LazySingleton` classes)

---

### Task 9: Run flutter analyze — AC10

```bash
cd tkd_brackets && flutter analyze
```

Must pass with zero errors. Common issues to watch for:
- `invalid_annotation_target` — suppressed via `ignore_for_file` comment
- Line length > 80 chars — break long lines
- Unused imports — remove any extras
- Missing `part` directives — ensure `.freezed.dart` and `.g.dart` parts are declared

---

### Task 10: Write Unit Tests — AC9

#### Test File: `test/features/auth/data/datasources/organization_local_datasource_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/auth/data/datasources/organization_local_datasource.dart';
import 'package:tkd_brackets/features/auth/data/models/organization_model.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

class FakeOrganizationsCompanion extends Fake
    implements OrganizationsCompanion {}

void main() {
  late OrganizationLocalDatasourceImplementation datasource;
  late MockAppDatabase mockDatabase;

  // Create a test OrganizationEntry that matches what the Drift
  // database returns
  final testEntry = OrganizationEntry(
    id: 'org-1',
    name: 'Test Dojang',
    slug: 'test-dojang',
    subscriptionTier: 'free',
    subscriptionStatus: 'active',
    maxTournamentsPerMonth: 2,
    maxActiveBrackets: 3,
    maxParticipantsPerBracket: 32,
    maxParticipantsPerTournament: 100,
    maxScorers: 2,
    isActive: true,
    syncVersion: 1,
    isDeleted: false,
    isDemoData: false,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
    deletedAtTimestamp: null,
  );

  setUpAll(() {
    registerFallbackValue(FakeOrganizationsCompanion());
  });

  setUp(() {
    mockDatabase = MockAppDatabase();
    datasource =
        OrganizationLocalDatasourceImplementation(mockDatabase);
  });

  group('getOrganizationById', () {
    test('returns OrganizationModel when entry exists', () async {
      when(() => mockDatabase.getOrganizationById('org-1'))
          .thenAnswer((_) async => testEntry);

      final result =
          await datasource.getOrganizationById('org-1');

      expect(result, isNotNull);
      expect(result!.id, 'org-1');
      expect(result.name, 'Test Dojang');
    });

    test('returns null when entry does not exist', () async {
      when(() => mockDatabase.getOrganizationById('org-999'))
          .thenAnswer((_) async => null);

      final result =
          await datasource.getOrganizationById('org-999');

      expect(result, isNull);
    });
  });

  group('getActiveOrganizations', () {
    test('returns list of OrganizationModels', () async {
      when(() => mockDatabase.getActiveOrganizations())
          .thenAnswer((_) async => [testEntry]);

      final result = await datasource.getActiveOrganizations();

      expect(result.length, 1);
      expect(result.first.id, 'org-1');
    });

    test('returns empty list when no organizations', () async {
      when(() => mockDatabase.getActiveOrganizations())
          .thenAnswer((_) async => []);

      final result = await datasource.getActiveOrganizations();

      expect(result, isEmpty);
    });
  });

  group('insertOrganization', () {
    test('calls database insertOrganization', () async {
      when(() => mockDatabase.insertOrganization(any()))
          .thenAnswer((_) async => 1);

      final model = OrganizationModel.fromDriftEntry(testEntry);
      await datasource.insertOrganization(model);

      verify(() => mockDatabase.insertOrganization(any()))
          .called(1);
    });
  });

  group('updateOrganization', () {
    test('calls database updateOrganization with id', () async {
      when(() => mockDatabase.updateOrganization(any(), any()))
          .thenAnswer((_) async => true);

      final model = OrganizationModel.fromDriftEntry(testEntry);
      await datasource.updateOrganization(model);

      verify(
        () => mockDatabase.updateOrganization('org-1', any()),
      ).called(1);
    });
  });

  group('deleteOrganization', () {
    test('calls database softDeleteOrganization', () async {
      when(() => mockDatabase.softDeleteOrganization('org-1'))
          .thenAnswer((_) async => true);

      await datasource.deleteOrganization('org-1');

      verify(() => mockDatabase.softDeleteOrganization('org-1'))
          .called(1);
    });
  });
}
```

#### Test File: `test/features/auth/data/datasources/organization_remote_datasource_test.dart`

Follow the same pattern as `user_remote_datasource_test.dart`. Test all methods with mocked `SupabaseClient`. Key tests:
- `getOrganizationById` — returns model when found, null when not
- `getOrganizationBySlug` — returns model when found, null when not
- `getActiveOrganizations` — returns list
- `insertOrganization` — calls insert().select().single()
- `updateOrganization` — calls update().eq().select().single()
- `deleteOrganization` — calls update() with soft delete fields

#### Test File: `test/features/auth/data/repositories/organization_repository_implementation_test.dart`

Follow the exact same pattern as `user_repository_implementation_test.dart`. Key test groups:

```
group('getOrganizationById')
  - returns org from local when available
  - fetches from remote when local not found and online
  - returns failure when not found locally and offline
  - returns failure when not found in both sources
  - returns failure on exception

group('getOrganizationBySlug')
  - returns org from local when available
  - fetches from remote when local not found and online
  - returns failure when not found locally and offline
  - returns failure when not found in both sources

group('getActiveOrganizations')
  - returns orgs from local when offline
  - syncs from remote when online
  - handles remote failure gracefully (falls back to local)

group('createOrganization')
  - saves locally first then syncs to remote
  - succeeds with local only when offline

group('updateOrganization')
  - updates locally and syncs to remote when online
  - succeeds with local only when offline

group('deleteOrganization')
  - deletes locally and syncs to remote when online
  - succeeds with local only when offline
```

#### Test File: `test/features/auth/data/models/organization_model_test.dart`

Test all conversion methods:

```
group('fromDriftEntry')
  - converts all fields correctly

group('fromJson')
  - converts snake_case JSON keys correctly
  - handles nullable fields

group('toJson')
  - produces correct snake_case keys
  - handles nullable fields

group('convertToEntity')
  - maps all fields including enums

group('convertFromEntity')
  - maps entity back to model with defaults

group('toDriftCompanion')
  - produces correct OrganizationsCompanion
```

#### Test File: `test/features/auth/domain/entities/organization_entity_test.dart`

```
group('SubscriptionTier')
  - fromString returns correct tier for valid values
  - fromString returns free for unknown values

group('SubscriptionStatus')
  - fromString returns correct status for valid values
  - fromString returns active for unknown values

group('OrganizationEntity')
  - can be created with all required fields
  - supports value equality (freezed)
  - supports copyWith (freezed)
```

---

## Dev Notes

### Key Patterns to Follow

1. **This story mirrors Story 2.2 exactly.** The User entity/repository pattern is the blueprint. When in doubt, look at what `UserModel`, `UserLocalDatasource`, `UserRemoteDatasource`, and `UserRepositoryImplementation` do.

2. **Organization lives in the `auth` feature**, NOT a separate `organization` feature. The architecture maps FR51-FR58 (Authentication & RBAC) → `features/authentication/`. Since organizations are tightly coupled to auth and multi-tenancy, they share the `auth` feature directory.

3. **The Drift table and AppDatabase CRUD methods already exist.** Do NOT create new table definitions. The only modification to `app_database.dart` is adding `getOrganizationBySlug` (see below).

4. **`freezed` entities use `part` directives**, NOT `export`. The `.freezed.dart` and `.g.dart` files are generated via `build_runner`.

5. **`@LazySingleton` registration** — All datasource implementations and repository implementations use `@LazySingleton(as: InterfaceType)`. This is picked up by `injectable` code generation.

### Epics vs. Actual Schema Discrepancy

The epics file lists `OrganizationEntity` fields as: `id`, `name`, `slug`, `logoUrl`, `subscriptionTier`, `ownerId`, `createdAt`. However, the **actual Supabase schema and Drift table** do NOT have `logoUrl` or `ownerId`. Instead they have subscription limits (`maxTournamentsPerMonth`, etc.), `subscriptionStatus`, and `isActive`. **Always use the actual schema as the source of truth.**

### AppDatabase: Add `getOrganizationBySlug`

**File:** `lib/core/database/app_database.dart`

Add this method in the Organizations CRUD section (after `getOrganizationById`):

```dart
/// Get organization by slug.
Future<OrganizationEntry?> getOrganizationBySlug(String slug) {
  return (select(organizations)
        ..where((o) => o.slug.equals(slug)))
      .getSingleOrNull();
}
```

### Project Structure Notes

Files created/modified by this story:
```
lib/core/database/
└── app_database.dart                              ← MODIFIED (add getOrganizationBySlug)

lib/features/auth/
├── data/
│   ├── datasources/
│   │   ├── organization_local_datasource.dart     ← NEW
│   │   └── organization_remote_datasource.dart    ← NEW
│   ├── models/
│   │   └── organization_model.dart                ← NEW
│   └── repositories/
│       └── organization_repository_implementation.dart  ← NEW
├── domain/
│   ├── entities/
│   │   └── organization_entity.dart               ← NEW
│   └── repositories/
│       └── organization_repository.dart           ← NEW
└── auth.dart                                      ← MODIFIED (add exports)

test/features/auth/
├── data/
│   ├── datasources/
│   │   ├── organization_local_datasource_test.dart     ← NEW
│   │   └── organization_remote_datasource_test.dart    ← NEW
│   ├── models/
│   │   └── organization_model_test.dart                ← NEW
│   └── repositories/
│       └── organization_repository_implementation_test.dart  ← NEW
└── domain/
    └── entities/
        └── organization_entity_test.dart               ← NEW
```

### Testing Standards

- Use `mocktail` for mocking (NOT `mockito`)
- Register fallback values in `setUpAll()` for any `Fake` classes
- Use `verify()` to ensure correct methods are called
- Test both success and failure paths
- Test offline-first behavior (local-only when offline)
- Test sync version increment on updates

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Story 2.6 definition]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Organizations schema, naming conventions, Clean Architecture rules]
- [Source: `lib/core/database/tables/organizations_table.dart` — Drift table definition]
- [Source: `lib/core/database/app_database.dart` — Existing CRUD methods]
- [Source: `lib/features/auth/data/models/user_model.dart` — Model pattern reference]
- [Source: `lib/features/auth/data/datasources/user_local_datasource.dart` — Local datasource pattern]
- [Source: `lib/features/auth/data/datasources/user_remote_datasource.dart` — Remote datasource pattern]
- [Source: `lib/features/auth/data/repositories/user_repository_implementation.dart` — Repository pattern]
- [Source: `test/features/auth/data/repositories/user_repository_implementation_test.dart` — Test pattern]

---

## Dev Agent Record

### Agent Model Used
Antigravity (Google DeepMind)

### Debug Log References
- build_runner: 223 outputs, 16s build time with warnings (SDK version mismatch only)
- flutter analyze: 31 pre-existing issues (info/warning), zero from new code
- Test suite: 544 total tests passing (69 new + 475 existing)

### Completion Notes List
- Task 1: Created `OrganizationEntity` with `SubscriptionTier` and `SubscriptionStatus` enums
- Task 2: Created `OrganizationRepository` interface with 6 methods
- Task 3: Created `OrganizationModel` with all conversion methods (fromJson, toJson, fromDriftEntry, toDriftCompanion, convertToEntity, convertFromEntity)
- Task 4: Created `OrganizationLocalDatasource` wrapping AppDatabase
- Task 4 prerequisite: Added `getOrganizationBySlug` to AppDatabase
- Task 5: Created `OrganizationRemoteDatasource` wrapping Supabase
- Task 6: Created `OrganizationRepositoryImplementation` with offline-first strategy
- Task 7: Updated `auth.dart` barrel file with all new exports
- syncVersion handling: Repository reads existing syncVersion and increments for remote sync; AppDatabase independently computes syncVersion+1 for local write inside its transaction (both agree on the same value, no double-increment)
- All tests use `mocktail` for mocking, following existing patterns

### Code Review Fixes Applied
- **H3 fix**: `updateOrganization()` now reads existing `syncVersion` before update so the model sent to Supabase has the correct incremented version (was sending default `syncVersion: 1`)
- **H1 fix**: Created missing `organization_remote_datasource_test.dart` with contract-level tests
- **M1 fix**: Removed unused imports (`organization_entity.dart`, `fpdart.dart`) from repository test
- **New test**: Added `sends correct incremented syncVersion to remote` test with assertion capture
- Test count increased from 54 → 69

### File List

**New Files:**
- `lib/features/auth/domain/entities/organization_entity.dart`
- `lib/features/auth/domain/repositories/organization_repository.dart`
- `lib/features/auth/data/models/organization_model.dart`
- `lib/features/auth/data/datasources/organization_local_datasource.dart`
- `lib/features/auth/data/datasources/organization_remote_datasource.dart`
- `lib/features/auth/data/repositories/organization_repository_implementation.dart`
- `test/features/auth/domain/entities/organization_entity_test.dart`
- `test/features/auth/data/models/organization_model_test.dart`
- `test/features/auth/data/datasources/organization_local_datasource_test.dart`
- `test/features/auth/data/datasources/organization_remote_datasource_test.dart`
- `test/features/auth/data/repositories/organization_repository_implementation_test.dart`

**Modified Files:**
- `lib/core/database/app_database.dart` — Added `getOrganizationBySlug` method
- `lib/features/auth/auth.dart` — Added organization exports
