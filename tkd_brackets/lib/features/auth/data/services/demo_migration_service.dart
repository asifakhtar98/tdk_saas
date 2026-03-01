import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/demo/demo_data_service.dart';
import 'package:tkd_brackets/core/sync/sync_service.dart';
import 'package:uuid/uuid.dart';

/// Service for migrating demo data to production.
///
/// Orchestrates the migration workflow when a user transitions from
/// demo mode to authenticated production mode. Handles UUID remapping,
/// referential integrity preservation, and atomic transaction safety.
abstract class DemoMigrationService {
  /// Returns true if demo data exists and can be migrated.
  Future<bool> hasDemoData();

  /// Migrates all demo data to production.
  ///
  /// [newOrganizationId] — The production organization ID that will
  /// replace the demo organization ID.
  ///
  /// Returns the count of entities migrated.
  /// Throws [DemoMigrationException] on failure.
  Future<int> migrateDemoData(String newOrganizationId);
}

/// Exception thrown when demo migration fails.
class DemoMigrationException implements Exception {
  DemoMigrationException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'DemoMigrationException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Implementation of [DemoMigrationService] using Drift database.
@LazySingleton(as: DemoMigrationService)
class DemoMigrationServiceImpl implements DemoMigrationService {
  DemoMigrationServiceImpl(this._db, this._demoDataService, this._syncService);

  final AppDatabase _db;
  final DemoDataService _demoDataService;
  final SyncService _syncService;

  final _uuid = const Uuid();

  @override
  Future<bool> hasDemoData() => _demoDataService.hasDemoData();

  @override
  Future<int> migrateDemoData(String newOrganizationId) async {
    // Check if demo data exists
    final hasData = await hasDemoData();
    if (!hasData) {
      throw DemoMigrationException('No demo data exists to migrate');
    }

    // Verify no production data exists (idempotency check)
    final hasProductionData = await _hasProductionData();
    if (hasProductionData) {
      throw DemoMigrationException(
        'Migration cannot proceed: production data already exists',
      );
    }

    // Perform migration within a single atomic transaction
    return _db.transaction(() async {
      var migratedCount = 0;

      // 1. Build UUID mapping for all demo entities
      final uuidMapping = await _buildUuidMapping();

      // 2. Get all demo entities
      final demoOrgs = await _getDemoOrganizations();
      final demoTournaments = await _getDemoTournaments();
      final demoDivisions = await _getDemoDivisions();
      final demoParticipants = await _getDemoParticipants();
      final demoInvitations = await _getDemoInvitations();
      final demoUsers = await _getDemoUsers();

      // 3. DELETE in reverse dependency order (children first)
      // This avoids FK constraint violations during deletion
      for (final participant in demoParticipants) {
        await (_db.delete(
          _db.participants,
        )..where((p) => p.id.equals(participant.id))).go();
      }
      for (final division in demoDivisions) {
        await (_db.delete(
          _db.divisions,
        )..where((d) => d.id.equals(division.id))).go();
      }
      for (final tournament in demoTournaments) {
        await (_db.delete(
          _db.tournaments,
        )..where((t) => t.id.equals(tournament.id))).go();
      }
      for (final invitation in demoInvitations) {
        await (_db.delete(
          _db.invitations,
        )..where((i) => i.id.equals(invitation.id))).go();
      }
      for (final user in demoUsers) {
        await (_db.delete(_db.users)..where((u) => u.id.equals(user.id))).go();
      }
      for (final org in demoOrgs) {
        await (_db.delete(
          _db.organizations,
        )..where((o) => o.id.equals(org.id))).go();
      }

      // 4. INSERT new records in dependency order (parents first)
      // Order: organizations -> users -> tournaments -> divisions -> participants -> invitations
      for (final org in demoOrgs) {
        await _insertOrganization(org, newOrganizationId);
        migratedCount++;
      }
      for (final user in demoUsers) {
        final newId = uuidMapping[user.id]!;
        await _insertMigratedUser(
          user,
          newId,
          newOrganizationId,
          isActive: false,
        );
        migratedCount++;
      }
      for (final tournament in demoTournaments) {
        final newId = uuidMapping[tournament.id]!;
        final newCreatedById = tournament.createdByUserId != null
            ? uuidMapping[tournament.createdByUserId]
            : null;
        await _insertMigratedTournament(
          tournament,
          newId,
          newOrganizationId,
          newCreatedById,
        );
        migratedCount++;
      }
      for (final division in demoDivisions) {
        final newId = uuidMapping[division.id]!;
        final newTournamentId = uuidMapping[division.tournamentId]!;
        await _insertMigratedDivision(division, newId, newTournamentId);
        migratedCount++;
      }
      for (final participant in demoParticipants) {
        final newId = uuidMapping[participant.id]!;
        final newDivisionId = uuidMapping[participant.divisionId]!;
        await _insertMigratedParticipant(participant, newId, newDivisionId);
        migratedCount++;
      }
      for (final invitation in demoInvitations) {
        final newId = uuidMapping[invitation.id]!;
        await _insertMigratedInvitation(invitation, newId, newOrganizationId);
        migratedCount++;
      }

      // 5. Queue all migrated entities for sync
      await _queueMigratedEntitiesForSync(
        organizations: demoOrgs.map((o) => uuidMapping[o.id]!).toList(),
        tournaments: demoTournaments.map((t) => uuidMapping[t.id]!).toList(),
        divisions: demoDivisions.map((d) => uuidMapping[d.id]!).toList(),
        participants: demoParticipants.map((p) => uuidMapping[p.id]!).toList(),
        invitations: demoInvitations.map((i) => uuidMapping[i.id]!).toList(),
        users: demoUsers.map((u) => uuidMapping[u.id]!).toList(),
      );

      return migratedCount;
    });
  }

  /// Checks if any production (non-demo) data exists.
  Future<bool> _hasProductionData() async {
    final prodOrgs =
        await (_db.select(_db.organizations)
              ..where((o) => o.isDemoData.equals(false))
              ..where((o) => o.isDeleted.equals(false))
              ..limit(1))
            .get();
    return prodOrgs.isNotEmpty;
  }

  /// Builds a mapping from old demo UUIDs to new production UUIDs.
  Future<Map<String, String>> _buildUuidMapping() async {
    final mapping = <String, String>{};

    // Map organizations
    final orgs = await _getDemoOrganizations();
    for (final org in orgs) {
      mapping[org.id] = _uuid.v4();
    }

    // Map tournaments
    final tournaments = await _getDemoTournaments();
    for (final tournament in tournaments) {
      mapping[tournament.id] = _uuid.v4();
    }

    // Map divisions
    final divisions = await _getDemoDivisions();
    for (final division in divisions) {
      mapping[division.id] = _uuid.v4();
    }

    // Map participants
    final participants = await _getDemoParticipants();
    for (final participant in participants) {
      mapping[participant.id] = _uuid.v4();
    }

    // Map invitations
    final invitations = await _getDemoInvitations();
    for (final invitation in invitations) {
      mapping[invitation.id] = _uuid.v4();
    }

    // Map users
    final users = await _getDemoUsers();
    for (final user in users) {
      mapping[user.id] = _uuid.v4();
    }

    return mapping;
  }

  /// Gets all demo organizations.
  Future<List<OrganizationEntry>> _getDemoOrganizations() async {
    return (_db.select(_db.organizations)
          ..where((o) => o.isDemoData.equals(true))
          ..where((o) => o.isDeleted.equals(false)))
        .get();
  }

  /// Gets all demo tournaments.
  Future<List<TournamentEntry>> _getDemoTournaments() async {
    return (_db.select(_db.tournaments)
          ..where((t) => t.isDemoData.equals(true))
          ..where((t) => t.isDeleted.equals(false)))
        .get();
  }

  /// Gets all demo divisions.
  Future<List<DivisionEntry>> _getDemoDivisions() async {
    return (_db.select(_db.divisions)
          ..where((d) => d.isDemoData.equals(true))
          ..where((d) => d.isDeleted.equals(false)))
        .get();
  }

  /// Gets all demo participants.
  Future<List<ParticipantEntry>> _getDemoParticipants() async {
    return (_db.select(_db.participants)
          ..where((p) => p.isDemoData.equals(true))
          ..where((p) => p.isDeleted.equals(false)))
        .get();
  }

  /// Gets all demo invitations.
  Future<List<InvitationEntry>> _getDemoInvitations() async {
    return (_db.select(_db.invitations)
          ..where((i) => i.isDemoData.equals(true))
          ..where((i) => i.isDeleted.equals(false)))
        .get();
  }

  /// Gets all demo users.
  Future<List<UserEntry>> _getDemoUsers() async {
    return (_db.select(_db.users)
          ..where((u) => u.isDemoData.equals(true))
          ..where((u) => u.isDeleted.equals(false)))
        .get();
  }

  /// Inserts new production organization.
  Future<void> _insertOrganization(
    OrganizationEntry org,
    String newOrganizationId,
  ) async {
    await _db.insertOrganization(
      OrganizationsCompanion(
        id: Value(newOrganizationId),
        name: Value(org.name),
        slug: Value(org.slug),
        subscriptionTier: Value(org.subscriptionTier),
        subscriptionStatus: Value(org.subscriptionStatus),
        maxTournamentsPerMonth: Value(org.maxTournamentsPerMonth),
        maxActiveBrackets: Value(org.maxActiveBrackets),
        maxParticipantsPerBracket: Value(org.maxParticipantsPerBracket),
        maxParticipantsPerTournament: Value(org.maxParticipantsPerTournament),
        maxScorers: Value(org.maxScorers),
        isActive: Value(org.isActive),
        isDemoData: const Value(false),
        syncVersion: Value(org.syncVersion + 1),
        isDeleted: Value(org.isDeleted),
        deletedAtTimestamp: Value(org.deletedAtTimestamp),
        createdAtTimestamp: Value(org.createdAtTimestamp),
        updatedAtTimestamp: Value(DateTime.now()),
      ),
    );
  }

  /// Inserts migrated tournament with new IDs and flags.
  Future<void> _insertMigratedTournament(
    TournamentEntry tournament,
    String newId,
    String newOrganizationId,
    String? newCreatedByUserId,
  ) async {
    // Insert new tournament
    await _db.insertTournament(
      TournamentsCompanion(
        id: Value(newId),
        organizationId: Value(newOrganizationId),
        createdByUserId: newCreatedByUserId != null
            ? Value(newCreatedByUserId)
            : Value(tournament.createdByUserId),
        name: Value(tournament.name),
        description: Value(tournament.description),
        venueName: Value(tournament.venueName),
        venueAddress: Value(tournament.venueAddress),
        scheduledDate: Value(tournament.scheduledDate),
        scheduledStartTime: Value(tournament.scheduledStartTime),
        scheduledEndTime: Value(tournament.scheduledEndTime),
        federationType: Value(tournament.federationType),
        status: Value(tournament.status),
        isTemplate: Value(tournament.isTemplate),
        templateId: Value(tournament.templateId),
        numberOfRings: Value(tournament.numberOfRings),
        settingsJson: Value(tournament.settingsJson),
        isDemoData: const Value(false),
        syncVersion: Value(tournament.syncVersion + 1),
        isDeleted: Value(tournament.isDeleted),
        deletedAtTimestamp: Value(tournament.deletedAtTimestamp),
        createdAtTimestamp: Value(tournament.createdAtTimestamp),
        updatedAtTimestamp: Value(DateTime.now()),
      ),
    );
  }

  /// Inserts migrated division with new IDs and flags.
  Future<void> _insertMigratedDivision(
    DivisionEntry division,
    String newId,
    String newTournamentId,
  ) async {
    // Insert new division
    await _db.insertDivision(
      DivisionsCompanion(
        id: Value(newId),
        tournamentId: Value(newTournamentId),
        name: Value(division.name),
        category: Value(division.category),
        gender: Value(division.gender),
        ageMin: Value(division.ageMin),
        ageMax: Value(division.ageMax),
        weightMinKg: Value(division.weightMinKg),
        weightMaxKg: Value(division.weightMaxKg),
        beltRankMin: Value(division.beltRankMin),
        beltRankMax: Value(division.beltRankMax),
        bracketFormat: Value(division.bracketFormat),
        assignedRingNumber: Value(division.assignedRingNumber),
        isCombined: Value(division.isCombined),
        displayOrder: Value(division.displayOrder),
        status: Value(division.status),
        isDemoData: const Value(false),
        syncVersion: Value(division.syncVersion + 1),
        isDeleted: Value(division.isDeleted),
        deletedAtTimestamp: Value(division.deletedAtTimestamp),
        createdAtTimestamp: Value(division.createdAtTimestamp),
        updatedAtTimestamp: Value(DateTime.now()),
      ),
    );
  }

  /// Inserts migrated participant with new IDs and flags.
  Future<void> _insertMigratedParticipant(
    ParticipantEntry participant,
    String newId,
    String newDivisionId,
  ) async {
    await _db
        .into(_db.participants)
        .insert(
          ParticipantsCompanion(
            id: Value(newId),
            divisionId: Value(newDivisionId),
            firstName: Value(participant.firstName),
            lastName: Value(participant.lastName),
            dateOfBirth: Value(participant.dateOfBirth),
            gender: Value(participant.gender),
            weightKg: Value(participant.weightKg),
            schoolOrDojangName: Value(participant.schoolOrDojangName),
            beltRank: Value(participant.beltRank),
            seedNumber: Value(participant.seedNumber),
            registrationNumber: Value(participant.registrationNumber),
            isBye: Value(participant.isBye),
            checkInStatus: Value(participant.checkInStatus),
            checkInAtTimestamp: Value(participant.checkInAtTimestamp),
            photoUrl: Value(participant.photoUrl),
            notes: Value(participant.notes),
            isDemoData: const Value(false),
            syncVersion: Value(participant.syncVersion + 1),
            isDeleted: Value(participant.isDeleted),
            deletedAtTimestamp: Value(participant.deletedAtTimestamp),
            createdAtTimestamp: Value(participant.createdAtTimestamp),
            updatedAtTimestamp: Value(DateTime.now()),
          ),
        );
  }

  /// Inserts migrated invitation with new IDs and flags.
  Future<void> _insertMigratedInvitation(
    InvitationEntry invitation,
    String newId,
    String newOrganizationId,
  ) async {
    await _db
        .into(_db.invitations)
        .insert(
          InvitationsCompanion(
            id: Value(newId),
            organizationId: Value(newOrganizationId),
            email: Value(invitation.email),
            role: Value(invitation.role),
            invitedBy: Value(invitation.invitedBy),
            status: Value(invitation.status),
            token: Value(invitation.token),
            expiresAt: Value(invitation.expiresAt),
            isDemoData: const Value(false),
            syncVersion: Value(invitation.syncVersion + 1),
            isDeleted: Value(invitation.isDeleted),
            deletedAtTimestamp: Value(invitation.deletedAtTimestamp),
            createdAtTimestamp: Value(invitation.createdAtTimestamp),
            updatedAtTimestamp: Value(DateTime.now()),
          ),
        );
  }

  /// Inserts migrated user with new IDs, flags, and inactive status.
  Future<void> _insertMigratedUser(
    UserEntry user,
    String newId,
    String newOrganizationId, {
    bool? isActive,
  }) async {
    // Must delete first due to UNIQUE constraint on email
    await (_db.delete(_db.users)..where((u) => u.id.equals(user.id))).go();

    await _db.insertUser(
      UsersCompanion(
        id: Value(newId),
        organizationId: Value(newOrganizationId),
        email: Value(user.email),
        displayName: Value(user.displayName),
        role: Value(user.role),
        avatarUrl: Value(user.avatarUrl),
        isActive: isActive != null ? Value(isActive) : Value(user.isActive),
        lastSignInAtTimestamp: Value(user.lastSignInAtTimestamp),
        isDemoData: const Value(false),
        syncVersion: Value(user.syncVersion + 1),
        isDeleted: Value(user.isDeleted),
        deletedAtTimestamp: Value(user.deletedAtTimestamp),
        createdAtTimestamp: Value(user.createdAtTimestamp),
        updatedAtTimestamp: Value(DateTime.now()),
      ),
    );
  }

  /// Queues all migrated entities for sync.
  Future<void> _queueMigratedEntitiesForSync({
    required List<String> organizations,
    required List<String> tournaments,
    required List<String> divisions,
    required List<String> participants,
    required List<String> invitations,
    required List<String> users,
  }) async {
    // Queue organizations
    for (final id in organizations) {
      _syncService.queueForSync(
        tableName: 'organizations',
        recordId: id,
        operation: 'update',
      );
    }

    // Queue users
    for (final id in users) {
      _syncService.queueForSync(
        tableName: 'users',
        recordId: id,
        operation: 'update',
      );
    }

    // Note: Other tables (tournaments, divisions, participants, invitations)
    // may not be in the syncable tables list yet, but we queue them anyway
    // for when they are added to sync support.
    for (final id in tournaments) {
      _syncService.queueForSync(
        tableName: 'tournaments',
        recordId: id,
        operation: 'update',
      );
    }

    for (final id in divisions) {
      _syncService.queueForSync(
        tableName: 'divisions',
        recordId: id,
        operation: 'update',
      );
    }

    for (final id in participants) {
      _syncService.queueForSync(
        tableName: 'participants',
        recordId: id,
        operation: 'update',
      );
    }

    for (final id in invitations) {
      _syncService.queueForSync(
        tableName: 'invitations',
        recordId: id,
        operation: 'update',
      );
    }
  }
}
