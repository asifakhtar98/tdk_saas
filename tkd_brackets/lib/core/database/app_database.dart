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
@DriftDatabase(tables: [
  Organizations,
  Users,
  SyncQueueTable,
  Tournaments,
  Divisions,
  Participants,
])
class AppDatabase extends _$AppDatabase {
  /// Creates database with platform-appropriate connection.
  ///
  /// For testing, inject a custom [QueryExecutor] instead.
  AppDatabase() : super(_openConnection());

  /// Constructor for testing with custom executor.
  @visibleForTesting
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

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
        // Version 3: Add tournament-related tables for demo mode
        if (from < 3) {
          await m.createTable(tournaments);
          await m.createTable(divisions);
          await m.createTable(participants);
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

  /// Get all active users (for testing).
  Future<List<UserEntry>> getActiveUsers() {
    return (select(users)..where((u) => u.isDeleted.equals(false))).get();
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
  // Tournaments CRUD
  // ─────────────────────────────────────────────────────────────────────────

  /// Get all active tournaments for an organization.
  Future<List<TournamentEntry>> getTournamentsForOrganization(
      String organizationId) {
    return (select(tournaments)
          ..where((t) => t.organizationId.equals(organizationId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.scheduledDate)]))
        .get();
  }

  /// Get tournament by ID.
  Future<TournamentEntry?> getTournamentById(String id) {
    return (select(tournaments)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new tournament.
  Future<int> insertTournament(TournamentsCompanion tournament) {
    return into(tournaments).insert(tournament);
  }

  /// Update a tournament and increment sync_version.
  Future<bool> updateTournament(
      String id, TournamentsCompanion tournament) async {
    return transaction(() async {
      final current = await getTournamentById(id);
      if (current == null) return false;

      final rows =
          await (update(tournaments)..where((t) => t.id.equals(id))).write(
        tournament.copyWith(
          syncVersion: Value(current.syncVersion + 1),
          updatedAtTimestamp: Value(DateTime.now()),
        ),
      );
      return rows > 0;
    });
  }

  /// Soft delete a tournament.
  Future<bool> softDeleteTournament(String id) {
    return (update(tournaments)..where((t) => t.id.equals(id)))
        .write(TournamentsCompanion(
          isDeleted: const Value(true),
          deletedAtTimestamp: Value(DateTime.now()),
          updatedAtTimestamp: Value(DateTime.now()),
        ))
        .then((rows) => rows > 0);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Divisions CRUD
  // ─────────────────────────────────────────────────────────────────────────

  /// Get all active divisions for a tournament.
  Future<List<DivisionEntry>> getDivisionsForTournament(String tournamentId) {
    return (select(divisions)
          ..where((d) => d.tournamentId.equals(tournamentId))
          ..where((d) => d.isDeleted.equals(false))
          ..orderBy([(d) => OrderingTerm.asc(d.displayOrder)]))
        .get();
  }

  /// Get division by ID.
  Future<DivisionEntry?> getDivisionById(String id) {
    return (select(divisions)..where((d) => d.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new division.
  Future<int> insertDivision(DivisionsCompanion division) {
    return into(divisions).insert(division);
  }

  /// Update a division and increment sync_version.
  Future<bool> updateDivision(String id, DivisionsCompanion division) async {
    return transaction(() async {
      final current = await getDivisionById(id);
      if (current == null) return false;

      final rows =
          await (update(divisions)..where((d) => d.id.equals(id))).write(
        division.copyWith(
          syncVersion: Value(current.syncVersion + 1),
          updatedAtTimestamp: Value(DateTime.now()),
        ),
      );
      return rows > 0;
    });
  }

  /// Soft delete a division.
  Future<bool> softDeleteDivision(String id) {
    return (update(divisions)..where((d) => d.id.equals(id)))
        .write(DivisionsCompanion(
          isDeleted: const Value(true),
          deletedAtTimestamp: Value(DateTime.now()),
          updatedAtTimestamp: Value(DateTime.now()),
        ))
        .then((rows) => rows > 0);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Participants CRUD
  // ─────────────────────────────────────────────────────────────────────────

  /// Get all active participants for a division.
  Future<List<ParticipantEntry>> getParticipantsForDivision(String divisionId) {
    return (select(participants)
          ..where((p) => p.divisionId.equals(divisionId))
          ..where((p) => p.isDeleted.equals(false))
          ..orderBy([
            (p) => OrderingTerm.asc(p.seedNumber),
            (p) => OrderingTerm.asc(p.lastName),
          ]))
        .get();
  }

  /// Get participant by ID.
  Future<ParticipantEntry?> getParticipantById(String id) {
    return (select(participants)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new participant.
  Future<int> insertParticipant(ParticipantsCompanion participant) {
    return into(participants).insert(participant);
  }

  /// Update a participant and increment sync_version.
  Future<bool> updateParticipant(
      String id, ParticipantsCompanion participant) async {
    return transaction(() async {
      final current = await getParticipantById(id);
      if (current == null) return false;

      final rows =
          await (update(participants)..where((p) => p.id.equals(id))).write(
        participant.copyWith(
          syncVersion: Value(current.syncVersion + 1),
          updatedAtTimestamp: Value(DateTime.now()),
        ),
      );
      return rows > 0;
    });
  }

  /// Soft delete a participant.
  Future<bool> softDeleteParticipant(String id) {
    return (update(participants)..where((p) => p.id.equals(id)))
        .write(ParticipantsCompanion(
          isDeleted: const Value(true),
          deletedAtTimestamp: Value(DateTime.now()),
          updatedAtTimestamp: Value(DateTime.now()),
        ))
        .then((rows) => rows > 0);
  }

  /// Get all active tournaments (for testing).
  Future<List<TournamentEntry>> getActiveTournaments() {
    return (select(tournaments)..where((t) => t.isDeleted.equals(false))).get();
  }

  /// Get all active divisions (for testing).
  Future<List<DivisionEntry>> getActiveDivisions() {
    return (select(divisions)..where((d) => d.isDeleted.equals(false))).get();
  }

  /// Get all active participants (for testing).
  Future<List<ParticipantEntry>> getActiveParticipants() {
    return (select(participants)..where((p) => p.isDeleted.equals(false)))
        .get();
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
  /// Deletes in reverse FK order to respect constraints.
  Future<void> clearDemoData() async {
    await (delete(participants)..where((p) => p.isDemoData.equals(true))).go();
    await (delete(divisions)..where((d) => d.isDemoData.equals(true))).go();
    await (delete(tournaments)..where((t) => t.isDemoData.equals(true))).go();
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
      driftWorker: Uri.parse('drift_worker.dart.js'),
    ),
  );
}
