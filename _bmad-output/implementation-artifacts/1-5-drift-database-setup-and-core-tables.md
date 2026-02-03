# Story 1.5: Drift Database Setup & Core Tables

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer**,
I want **Drift configured with core database tables**,
So that **local data persistence is available for offline-first functionality**.

## Acceptance Criteria

1. **Given** the project infrastructure is in place, **When** I examine the database configuration, **Then** `lib/core/database/app_database.dart` defines the AppDatabase.

2. **Given** the AppDatabase exists, **When** I examine the common table patterns, **Then** the following are implemented:
   - `BaseSyncTable` mixin with `sync_version`, `is_deleted`, `deleted_at_timestamp`, `is_demo_data`
   - `BaseAuditTable` mixin with `created_at_timestamp`, `updated_at_timestamp`

3. **Given** the table patterns exist, **When** I examine the initial tables, **Then** `organizations` and `users` tables are created with proper migrations.

4. **Given** the project uses Flutter web, **When** I examine the database configuration, **Then** `drift_flutter` web support is configured properly.

5. **Given** the database is configured, **When** I run `dart run build_runner build`, **Then** `.g.dart` files are generated without errors.

6. **Given** the database implementation exists, **When** I run unit tests, **Then** they verify table creation and basic CRUD operations.

## Current Implementation State

### ✅ Already Implemented (from Stories 1.1-1.4)

| Component            | Location                                | Status     |
| -------------------- | --------------------------------------- | ---------- |
| Project scaffold     | `lib/`                                  | ✅ Complete |
| DI configuration     | `lib/core/di/`                          | ✅ Complete |
| Router configuration | `lib/core/router/`                      | ✅ Complete |
| Error handling       | `lib/core/error/`                       | ✅ Complete |
| LoggerService        | `lib/core/services/logger_service.dart` | ✅ Complete |

### ❌ Missing (To Be Implemented This Story)

1. **`lib/core/database/app_database.dart`** — Main Drift database definition
2. **`lib/core/database/tables/`** — Table definitions directory
3. **`lib/core/database/tables/base_tables.dart`** — Mixin classes for shared columns
4. **`lib/core/database/tables/organizations_table.dart`** — Organizations table
5. **`lib/core/database/tables/users_table.dart`** — Users table
6. **Unit tests** for database and tables in `test/core/database/`

## Tasks / Subtasks

- [x] **Task 1: Create Database Directory Structure (AC: #1)**
  - [x] Create `lib/core/database/` directory
  - [x] Create `lib/core/database/tables/` subdirectory

- [x] **Task 2: Create Base Table Mixins (AC: #2)**
  - [x] Create `lib/core/database/tables/base_tables.dart`
  - [x] Implement `BaseSyncMixin` with sync columns
  - [x] Implement `BaseAuditMixin` with timestamp columns

- [x] **Task 3: Create Organizations Table (AC: #3)**
  - [x] Create `lib/core/database/tables/organizations_table.dart`
  - [x] Define all columns per architecture schema
  - [x] Include soft delete and sync columns

- [x] **Task 4: Create Users Table (AC: #3)**
  - [x] Create `lib/core/database/tables/users_table.dart`
  - [x] Define all columns per architecture schema
  - [x] Include foreign key to organizations

- [x] **Task 5: Create AppDatabase with Web Support (AC: #1, #4)**
  - [x] Create `lib/core/database/app_database.dart`
  - [x] Configure `@DriftDatabase` annotation with tables
  - [x] Configure `drift_flutter` for web platform
  - [x] Register as `@lazySingleton` in DI
  - [x] Create `lib/core/database/database.dart` barrel file
  - [x] Create `lib/core/database/tables/tables.dart` barrel file

- [x] **Task 6: Run Build Runner (AC: #5)**
  - [x] Run `dart run build_runner build --delete-conflicting-outputs`
  - [x] Verify `app_database.g.dart` is generated
  - [x] Verify no analyzer warnings

- [x] **Task 7: Write Unit Tests (AC: #6)**
  - [x] Create `test/core/database/app_database_test.dart`
  - [x] Test database construction
  - [x] Test organizations table CRUD
  - [x] Test users table CRUD
  - [x] Test soft delete behavior
  - [x] Test sync_version updates

- [x] **Task 8: Verification**
  - [x] Run `dart analyze` with zero issues
  - [x] Run `flutter test` with all tests passing
  - [x] Run `flutter build web` successfully

## Dev Notes

### Project Location

**CRITICAL:** All code changes are in:
```
/Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/
```

### Dependencies (Already in pubspec.yaml)

```yaml
dependencies:
  drift: ^2.23.1
  drift_flutter: ^0.2.4

dev_dependencies:
  drift_dev: ^2.23.1
```

### Previous Story Learnings (Stories 1.1-1.4)

| Learning                               | Application                             |
| -------------------------------------- | --------------------------------------- |
| Use `Implementation` suffix not `Impl` | Apply to any repository implementations |
| `@lazySingleton` for DI registration   | Apply to AppDatabase                    |
| Test file structure mirrors lib/       | Create tests in `test/core/database/`   |
| LoggerService already exists           | Inject for error logging if needed      |
| Run build_runner after changes         | Regenerate `app_database.g.dart`        |

---

## Architecture Requirements

### Database Schema from Architecture Document

**Common Columns (All Tables):**
- `is_deleted BOOLEAN NOT NULL DEFAULT FALSE`
- `deleted_at_timestamp TIMESTAMPTZ` (nullable)
- `is_demo_data BOOLEAN NOT NULL DEFAULT FALSE`
- `created_at_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- `updated_at_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- `sync_version BIGINT NOT NULL DEFAULT 1` (on mutable tables)

### Naming Conventions

| Element      | Pattern                  | Example                                   |
| ------------ | ------------------------ | ----------------------------------------- |
| Tables       | `snake_case`, plural     | `organizations`, `users`                  |
| Columns      | `snake_case`, full words | `created_at_timestamp`, `organization_id` |
| Primary Keys | `id` (UUID as TEXT)      | `id TEXT NOT NULL`                        |
| Foreign Keys | `{table_singular}_id`    | `organization_id`                         |

---

## Code Specifications

### 📄 `lib/core/database/tables/base_tables.dart`

```dart
import 'package:drift/drift.dart';

/// Mixin providing soft delete and sync-related columns.
///
/// All tables that need to sync with Supabase should include this mixin.
/// The sync_version is incremented on every update for LWW conflict resolution.
mixin BaseSyncMixin on Table {
  /// For Last-Write-Wins sync conflict resolution.
  /// Increment on every local update.
  IntColumn get syncVersion => integer().withDefault(const Constant(1))();
  
  /// Soft delete flag. Never physically delete synced data.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  /// When the record was soft deleted. Null if not deleted.
  DateTimeColumn get deletedAtTimestamp => dateTime().nullable()();
  
  /// True for demo mode data that needs special handling on signup.
  BoolColumn get isDemoData => boolean().withDefault(const Constant(false))();
}

/// Mixin providing audit timestamp columns.
///
/// All tables should include this mixin for tracking record lifecycle.
mixin BaseAuditMixin on Table {
  /// When the record was created. Set once on insert.
  DateTimeColumn get createdAtTimestamp => dateTime()
      .withDefault(currentDateAndTime)();
  
  /// When the record was last updated. Updated on every modification.
  DateTimeColumn get updatedAtTimestamp => dateTime()
      .withDefault(currentDateAndTime)();
}
```

### 📄 `lib/core/database/tables/tables.dart` (Barrel File)

```dart
/// Barrel file exporting all table definitions.
export 'base_tables.dart';
export 'organizations_table.dart';
export 'users_table.dart';
```

### 📄 `lib/core/database/tables/organizations_table.dart`

```dart
import 'package:drift/drift.dart';
import 'package:tkd_brackets/core/database/tables/base_tables.dart';

/// Organizations table for multi-tenant data isolation.
///
/// Each organization represents a dojang or tournament organizing body.
/// Subscription limits are enforced at the organization level.
@DataClassName('OrganizationEntry')
class Organizations extends Table with BaseSyncMixin, BaseAuditMixin {
  /// Primary key - UUID stored as TEXT for SQLite compatibility.
  TextColumn get id => text()();
  
  /// Organization display name (e.g., "Dragon Martial Arts").
  TextColumn get name => text().withLength(min: 1, max: 255)();
  
  /// URL-safe slug, unique across all organizations.
  TextColumn get slug => text().unique()();
  
  /// Subscription tier: 'free', 'pro', 'enterprise'.
  TextColumn get subscriptionTier => text()
      .withDefault(const Constant('free'))
      .check(subscriptionTier.isIn(['free', 'pro', 'enterprise']))();
  
  /// Subscription status: 'active', 'past_due', 'cancelled'.
  TextColumn get subscriptionStatus => text()
      .withDefault(const Constant('active'))
      .check(subscriptionStatus.isIn(['active', 'past_due', 'cancelled']))();
  
  /// Free tier: 2 tournaments per month.
  IntColumn get maxTournamentsPerMonth => integer().withDefault(const Constant(2))();
  
  /// Free tier: 3 active brackets.
  IntColumn get maxActiveBrackets => integer().withDefault(const Constant(3))();
  
  /// Free tier: 32 participants per bracket.
  IntColumn get maxParticipantsPerBracket => integer().withDefault(const Constant(32))();
  
  /// Soft cap for performance.
  IntColumn get maxParticipantsPerTournament => integer().withDefault(const Constant(100))();
  
  /// Free tier: 2 scorers.
  IntColumn get maxScorers => integer().withDefault(const Constant(2))();
  
  /// Whether organization is active.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

### 📄 `lib/core/database/tables/users_table.dart`

```dart
import 'package:drift/drift.dart';
import 'package:tkd_brackets/core/database/tables/base_tables.dart';
import 'package:tkd_brackets/core/database/tables/organizations_table.dart';

/// Users table for authentication and authorization.
///
/// Users belong to exactly one organization and have a role that
/// determines their permissions (RBAC).
@DataClassName('UserEntry')
class Users extends Table with BaseSyncMixin, BaseAuditMixin {
  /// Primary key - matches Supabase auth.users.id (UUID as TEXT).
  TextColumn get id => text()();
  
  /// Foreign key to organizations table.
  TextColumn get organizationId => text()
      .references(Organizations, #id)();
  
  /// User's email address, unique across all users.
  TextColumn get email => text().unique()();
  
  /// Display name shown in UI.
  TextColumn get displayName => text().withLength(min: 1, max: 255)();
  
  /// Role: 'owner', 'admin', 'scorer', 'viewer'.
  TextColumn get role => text()
      .withDefault(const Constant('viewer'))
      .check(role.isIn(['owner', 'admin', 'scorer', 'viewer']))();
  
  /// Optional avatar URL (Supabase Storage or external).
  TextColumn get avatarUrl => text().nullable()();
  
  /// Whether user account is active.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  /// Last successful sign-in timestamp.
  DateTimeColumn get lastSignInAtTimestamp => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

### 📄 `lib/core/database/app_database.dart`

```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:tkd_brackets/core/database/tables/organizations_table.dart';
import 'package:tkd_brackets/core/database/tables/users_table.dart';

part 'app_database.g.dart';

/// Main application database using Drift for type-safe SQLite operations.
///
/// This database supports Flutter web via sqlite3.wasm and provides
/// offline-first functionality with sync support.
///
/// Usage:
/// ```dart
/// final db = getIt<AppDatabase>();
/// final orgs = await db.select(db.organizations).get();
/// ```
@lazySingleton
@DriftDatabase(tables: [Organizations, Users])
class AppDatabase extends _$AppDatabase {
  /// Creates database with platform-appropriate connection.
  ///
  /// For testing, inject a custom [QueryExecutor] instead.
  AppDatabase() : super(_openConnection());
  
  /// Constructor for testing with custom executor.
  @visibleForTesting
  AppDatabase.forTesting(super.e);
  
  @override
  int get schemaVersion => 1;
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations go here
        // if (from < 2) { await m.addColumn(...); }
      },
      beforeOpen: (details) async {
        // Enable foreign key constraints
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // Organizations CRUD
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Get all active (non-deleted) organizations.
  Future<List<OrganizationEntry>> getActiveOrganizations() {
    return (select(organizations)
          ..where((o) => o.isDeleted.equals(false))
          ..orderBy([(o) => OrderingTerm.asc(o.name)]))
        .get();
  }
  
  /// Get organization by ID.
  Future<OrganizationEntry?> getOrganizationById(String id) {
    return (select(organizations)..where((o) => o.id.equals(id)))
        .getSingleOrNull();
  }
  
  /// Insert a new organization.
  Future<int> insertOrganization(OrganizationsCompanion org) {
    return into(organizations).insert(org);
  }
  
  /// Update an organization and increment sync_version.
  /// 
  /// Note: sync_version is incremented by reading current value first.
  /// In production, consider using a transaction for atomicity.
  Future<bool> updateOrganization(String id, OrganizationsCompanion org) async {
    final current = await getOrganizationById(id);
    if (current == null) return false;
    
    return (update(organizations)..where((o) => o.id.equals(id)))
        .write(org.copyWith(
          syncVersion: Value(current.syncVersion + 1),
          updatedAtTimestamp: Value(DateTime.now()),
        ))
        .then((rows) => rows > 0);
  }
  
  /// Soft delete an organization.
  Future<bool> softDeleteOrganization(String id) {
    return (update(organizations)..where((o) => o.id.equals(id)))
        .write(OrganizationsCompanion(
          isDeleted: const Value(true),
          deletedAtTimestamp: Value(DateTime.now()),
          updatedAtTimestamp: Value(DateTime.now()),
        ))
        .then((rows) => rows > 0);
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // Users CRUD
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Get all active users for an organization.
  Future<List<UserEntry>> getUsersForOrganization(String organizationId) {
    return (select(users)
          ..where((u) => u.organizationId.equals(organizationId))
          ..where((u) => u.isDeleted.equals(false))
          ..orderBy([(u) => OrderingTerm.asc(u.displayName)]))
        .get();
  }
  
  /// Get user by ID.
  Future<UserEntry?> getUserById(String id) {
    return (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();
  }
  
  /// Get user by email.
  Future<UserEntry?> getUserByEmail(String email) {
    return (select(users)..where((u) => u.email.equals(email))).getSingleOrNull();
  }
  
  /// Insert a new user.
  Future<int> insertUser(UsersCompanion user) {
    return into(users).insert(user);
  }
  
  /// Update a user and increment sync_version.
  /// 
  /// Note: sync_version is incremented by reading current value first.
  Future<bool> updateUser(String id, UsersCompanion user) async {
    final current = await getUserById(id);
    if (current == null) return false;
    
    return (update(users)..where((u) => u.id.equals(id)))
        .write(user.copyWith(
          syncVersion: Value(current.syncVersion + 1),
          updatedAtTimestamp: Value(DateTime.now()),
        ))
        .then((rows) => rows > 0);
  }
  
  /// Soft delete a user.
  Future<bool> softDeleteUser(String id) {
    return (update(users)..where((u) => u.id.equals(id)))
        .write(UsersCompanion(
          isDeleted: const Value(true),
          deletedAtTimestamp: Value(DateTime.now()),
          updatedAtTimestamp: Value(DateTime.now()),
        ))
        .then((rows) => rows > 0);
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // Demo Data Operations
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Check if demo data exists.
  Future<bool> hasDemoData() async {
    final result = await (select(organizations)
          ..where((o) => o.isDemoData.equals(true))
          ..limit(1))
        .get();
    return result.isNotEmpty;
  }
  
  /// Delete all demo data (for migration to production).
  Future<void> clearDemoData() async {
    await (delete(users)..where((u) => u.isDemoData.equals(true))).go();
    await (delete(organizations)..where((o) => o.isDemoData.equals(true))).go();
  }
}

/// Opens the database connection with platform-appropriate executor.
///
/// Uses drift_flutter for web support via sqlite3.wasm.
QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'tkd_brackets_db',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
```

### 📄 `lib/core/database/database.dart` (Barrel File)

```dart
/// Barrel file for database layer.
/// Import this file to access all database functionality.
export 'app_database.dart';
export 'tables/tables.dart';
```

### 📄 `test/core/database/app_database_test.dart`

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:tkd_brackets/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // Use in-memory SQLite for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('AppDatabase', () {
    test('should create database successfully', () {
      expect(database, isNotNull);
      expect(database.schemaVersion, 1);
    });

    test('should have organizations table', () {
      expect(database.organizations, isNotNull);
    });

    test('should have users table', () {
      expect(database.users, isNotNull);
    });
  });

  group('Organizations CRUD', () {
    test('should insert and retrieve organization', () async {
      final orgId = 'test-org-id-123';
      
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: orgId,
          name: 'Test Dojang',
          slug: 'test-dojang',
        ),
      );

      final result = await database.getOrganizationById(orgId);

      expect(result, isNotNull);
      expect(result!.name, 'Test Dojang');
      expect(result.slug, 'test-dojang');
      expect(result.subscriptionTier, 'free');
      expect(result.isDeleted, false);
      expect(result.isDemoData, false);
    });

    test('should return null for non-existent organization', () async {
      final result = await database.getOrganizationById('non-existent');
      expect(result, isNull);
    });

    test('should get only active organizations', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'org-1',
          name: 'Active Org',
          slug: 'active-org',
        ),
      );
      
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'org-2',
          name: 'Deleted Org',
          slug: 'deleted-org',
          isDeleted: const Value(true),
        ),
      );

      final active = await database.getActiveOrganizations();

      expect(active.length, 1);
      expect(active.first.name, 'Active Org');
    });

    test('should soft delete organization', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'org-delete',
          name: 'To Delete',
          slug: 'to-delete',
        ),
      );

      final deleted = await database.softDeleteOrganization('org-delete');
      expect(deleted, true);

      final result = await database.getOrganizationById('org-delete');
      expect(result!.isDeleted, true);
      expect(result.deletedAtTimestamp, isNotNull);
    });

    test('should update organization', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'org-update',
          name: 'Original Name',
          slug: 'original-slug',
        ),
      );

      await database.updateOrganization(
        'org-update',
        const OrganizationsCompanion(
          name: Value('Updated Name'),
        ),
      );

      final updated = await database.getOrganizationById('org-update');
      expect(updated!.name, 'Updated Name');
    });

    test('should enforce default subscription limits', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'org-limits',
          name: 'Limits Test',
          slug: 'limits-test',
        ),
      );

      final org = await database.getOrganizationById('org-limits');
      
      expect(org!.maxTournamentsPerMonth, 2);
      expect(org.maxActiveBrackets, 3);
      expect(org.maxParticipantsPerBracket, 32);
      expect(org.maxScorers, 2);
    });
  });

  group('Users CRUD', () {
    late String testOrgId;

    setUp(() async {
      testOrgId = 'test-org-for-users';
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: testOrgId,
          name: 'Test Org',
          slug: 'test-org',
        ),
      );
    });

    test('should insert and retrieve user', () async {
      await database.insertUser(
        UsersCompanion.insert(
          id: 'user-123',
          organizationId: testOrgId,
          email: 'test@example.com',
          displayName: 'Test User',
        ),
      );

      final result = await database.getUserById('user-123');

      expect(result, isNotNull);
      expect(result!.email, 'test@example.com');
      expect(result.displayName, 'Test User');
      expect(result.role, 'viewer');
      expect(result.isActive, true);
    });

    test('should get user by email', () async {
      await database.insertUser(
        UsersCompanion.insert(
          id: 'user-email',
          organizationId: testOrgId,
          email: 'unique@example.com',
          displayName: 'Email User',
        ),
      );

      final result = await database.getUserByEmail('unique@example.com');
      expect(result, isNotNull);
      expect(result!.displayName, 'Email User');
    });

    test('should get users for organization', () async {
      await database.insertUser(
        UsersCompanion.insert(
          id: 'org-user-1',
          organizationId: testOrgId,
          email: 'user1@example.com',
          displayName: 'Alpha User',
        ),
      );
      await database.insertUser(
        UsersCompanion.insert(
          id: 'org-user-2',
          organizationId: testOrgId,
          email: 'user2@example.com',
          displayName: 'Beta User',
        ),
      );

      final users = await database.getUsersForOrganization(testOrgId);

      expect(users.length, 2);
      expect(users.first.displayName, 'Alpha User'); // Ordered by name
    });

    test('should soft delete user', () async {
      await database.insertUser(
        UsersCompanion.insert(
          id: 'user-del',
          organizationId: testOrgId,
          email: 'delete@example.com',
          displayName: 'Delete Me',
        ),
      );

      final deleted = await database.softDeleteUser('user-del');
      expect(deleted, true);

      final result = await database.getUserById('user-del');
      expect(result!.isDeleted, true);
    });

    test('should enforce unique email constraint', () async {
      await database.insertUser(
        UsersCompanion.insert(
          id: 'user-dup-1',
          organizationId: testOrgId,
          email: 'duplicate@example.com',
          displayName: 'First User',
        ),
      );

      expect(
        () => database.insertUser(
          UsersCompanion.insert(
            id: 'user-dup-2',
            organizationId: testOrgId,
            email: 'duplicate@example.com',
            displayName: 'Second User',
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('Demo Data Operations', () {
    test('should detect no demo data initially', () async {
      final hasDemo = await database.hasDemoData();
      expect(hasDemo, false);
    });

    test('should detect demo data when present', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'demo-org',
          name: 'Demo Dojang',
          slug: 'demo-dojang',
          isDemoData: const Value(true),
        ),
      );

      final hasDemo = await database.hasDemoData();
      expect(hasDemo, true);
    });

    test('should clear demo data', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'demo-org',
          name: 'Demo Dojang',
          slug: 'demo-dojang',
          isDemoData: const Value(true),
        ),
      );
      await database.insertUser(
        UsersCompanion.insert(
          id: 'demo-user',
          organizationId: 'demo-org',
          email: 'demo@example.com',
          displayName: 'Demo User',
          isDemoData: const Value(true),
        ),
      );

      await database.clearDemoData();

      final hasDemo = await database.hasDemoData();
      expect(hasDemo, false);
      
      final users = await database.getUsersForOrganization('demo-org');
      expect(users, isEmpty);
    });
  });

  group('Timestamp Columns', () {
    test('should set createdAtTimestamp on insert', () async {
      final before = DateTime.now();
      
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'ts-org',
          name: 'Timestamp Test',
          slug: 'ts-test',
        ),
      );
      
      final after = DateTime.now();
      final org = await database.getOrganizationById('ts-org');

      expect(org!.createdAtTimestamp.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(org.createdAtTimestamp.isBefore(after.add(const Duration(seconds: 1))), true);
    });
  });

  group('Sync Version', () {
    test('should have default sync_version of 1', () async {
      await database.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'sync-org',
          name: 'Sync Test',
          slug: 'sync-test',
        ),
      );

      final org = await database.getOrganizationById('sync-org');
      expect(org!.syncVersion, 1);
    });
  });
}
```

---

## Web Support Configuration

### sqlite3.wasm Deployment

**CRITICAL:** For web builds, ensure the following files are in `web/` directory:

1. The `drift_flutter` package handles wasm loading automatically
2. Assets are downloaded on first use from CDN (default behavior)
3. For production, consider bundling wasm locally

### DI Registration

The `AppDatabase` is automatically registered via `@lazySingleton`:

```dart
// After running build_runner, injection.config.dart will include:
// gh.lazySingleton<AppDatabase>(() => AppDatabase());
```

---

## Test Count Targets

| Test File                | Expected Tests | Focus                                    |
| ------------------------ | -------------- | ---------------------------------------- |
| `app_database_test.dart` | ~20 tests      | CRUD, soft delete, demo data, timestamps |

---

## Verification Commands

```bash
# From tkd_brackets directory
cd /Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets

# 1. Generate code
dart run build_runner build --delete-conflicting-outputs

# 2. Analyze
dart analyze

# 3. Run tests
flutter test

# 4. Build web
flutter build web
```

---

## References

- [Source: architecture.md#Database Schema Definitions] — Complete table schemas
- [Source: architecture.md#Common Schema Patterns] — Soft delete and sync patterns
- [Source: architecture.md#Starter Template Evaluation] — Drift configuration
- [Source: epics.md#Story 1.5] — Original acceptance criteria
- [Source: 1-4-error-handling-infrastructure.md] — Previous story patterns

---

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4 (Antigravity)

### Debug Log References

- Fixed recursive getter warnings in table check constraints by removing self-referential `.check()` calls
- Fixed import conflict in tests between drift's `isNotNull`/`isNull` and flutter_test's matchers
- Removed unnecessary sqlite3 import (SqliteException re-exported from drift/native.dart)
- Added library directives to barrel files to fix dangling doc comment warnings
- **[CODE REVIEW FIX]** Removed explicit `DriftWebOptions` that referenced non-existent local files; now uses CDN defaults
- **[CODE REVIEW FIX]** Wrapped `updateOrganization` and `updateUser` in `transaction()` for sync_version atomicity
- **[CODE REVIEW FIX]** Updated imports to use `tables/tables.dart` barrel file instead of individual table imports

### Completion Notes List

1. ✅ Created Drift database infrastructure with full offline-first support
2. ✅ Implemented `BaseSyncMixin` with sync_version, is_deleted, deleted_at_timestamp, is_demo_data columns
3. ✅ Implemented `BaseAuditMixin` with created_at_timestamp, updated_at_timestamp columns
4. ✅ Created Organizations table with all subscription limits and multi-tenant columns
5. ✅ Created Users table with RBAC role column and foreign key to Organizations
6. ✅ Configured `drift_flutter` for web platform with sqlite3.wasm support
7. ✅ Registered AppDatabase as `@lazySingleton` for DI
8. ✅ Created 28 comprehensive unit tests covering CRUD, soft delete, demo data, timestamps, sync version
9. ✅ All 101 project tests pass, zero analyzer issues, web build successful

### File List

**New Files:**
- `lib/core/database/app_database.dart` — Main database with CRUD operations
- `lib/core/database/app_database.g.dart` — Generated Drift code
- `lib/core/database/database.dart` — Barrel file
- `lib/core/database/tables/base_tables.dart` — BaseSyncMixin and BaseAuditMixin
- `lib/core/database/tables/organizations_table.dart` — Organizations table definition
- `lib/core/database/tables/users_table.dart` — Users table definition
- `lib/core/database/tables/tables.dart` — Tables barrel file
- `test/core/database/app_database_test.dart` — Unit tests (28 tests)

**Modified Files:**
- `lib/core/di/injection.config.dart` — Auto-generated DI registration for AppDatabase

---

## Change Log

| Date       | Change                                                                                     |
| ---------- | ------------------------------------------------------------------------------------------ |
| 2026-02-03 | Initial implementation of Drift database with Organizations/Users tables                   |
| 2026-02-03 | Added 28 unit tests for database CRUD, soft delete, sync version, demo data                |
| 2026-02-03 | All acceptance criteria verified, marked for review                                        |
| 2026-02-03 | **Code Review**: Fixed web config (CDN), added transaction atomicity, fixed barrel imports |
