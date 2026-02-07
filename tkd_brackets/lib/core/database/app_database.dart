import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/tables/tables.dart';

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
@DriftDatabase(tables: [Organizations, Users, SyncQueueTable])
class AppDatabase extends _$AppDatabase {
  /// Creates database with platform-appropriate connection.
  ///
  /// For testing, inject a custom [QueryExecutor] instead.
  AppDatabase() : super(_openConnection());

  /// Constructor for testing with custom executor.
  @visibleForTesting
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Version 2: Add sync_queue table for pending sync operations
        if (from < 2) {
          await m.createTable(syncQueueTable);
        }
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
  /// Uses a transaction to ensure atomicity of the read-modify-write
  /// operation for sync_version increment.
  Future<bool> updateOrganization(
      String id, OrganizationsCompanion org) async {
    return transaction(() async {
      final current = await getOrganizationById(id);
      if (current == null) return false;

      final rows = await (update(organizations)..where((o) => o.id.equals(id)))
          .write(org.copyWith(
            syncVersion: Value(current.syncVersion + 1),
            updatedAtTimestamp: Value(DateTime.now()),
          ));
      return rows > 0;
    });
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
    return (select(users)..where((u) => u.email.equals(email)))
        .getSingleOrNull();
  }

  /// Insert a new user.
  Future<int> insertUser(UsersCompanion user) {
    return into(users).insert(user);
  }

  /// Update a user and increment sync_version.
  ///
  /// Uses a transaction to ensure atomicity of the read-modify-write
  /// operation for sync_version increment.
  Future<bool> updateUser(String id, UsersCompanion user) async {
    return transaction(() async {
      final current = await getUserById(id);
      if (current == null) return false;

      final rows = await (update(users)..where((u) => u.id.equals(id)))
          .write(user.copyWith(
            syncVersion: Value(current.syncVersion + 1),
            updatedAtTimestamp: Value(DateTime.now()),
          ));
      return rows > 0;
    });
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
    await (delete(organizations)..where((o) => o.isDemoData.equals(true)))
        .go();
  }
}

/// Opens the database connection with platform-appropriate executor.
///
/// Uses drift_flutter for web support via sqlite3.wasm.
QueryExecutor _openConnection() {
  // Uses drift_flutter's default CDN behavior for web assets.
  // sqlite3.wasm and drift_worker.js are automatically loaded from CDN.
  return driftDatabase(name: 'tkd_brackets_db');
}
