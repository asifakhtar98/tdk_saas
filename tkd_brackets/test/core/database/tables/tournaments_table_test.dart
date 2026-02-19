import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/database/app_database.dart';

void main() {
  late AppDatabase database;
  late String testOrgId;
  late String testUserId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    testOrgId = 'test-org-for-tournaments';
    testUserId = 'test-user-for-tournaments';

    // Create prerequisite organization
    await database.insertOrganization(
      OrganizationsCompanion.insert(
        id: testOrgId,
        name: 'Test Org',
        slug: 'test-org',
      ),
    );

    // Create prerequisite user
    await database.insertUser(
      UsersCompanion.insert(
        id: testUserId,
        organizationId: testOrgId,
        email: 'test@example.com',
        displayName: 'Test User',
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('Tournaments Table', () {
    test('should insert and retrieve tournament', () async {
      const tournamentId = 'tournament-123';
      final scheduledDate = DateTime(2026, 6, 15);

      await database.insertTournament(
        TournamentsCompanion.insert(
          id: tournamentId,
          organizationId: testOrgId,
          name: 'Spring Championship',
          scheduledDate: Value(scheduledDate),
        ),
      );

      final result = await database.getTournamentById(tournamentId);

      expect(result, isNotNull);
      expect(result!.name, 'Spring Championship');
      expect(result.organizationId, testOrgId);
      expect(result.scheduledDate, scheduledDate);
    });

    test('should have correct default values', () async {
      const tournamentId = 'tournament-defaults';

      await database.insertTournament(
        TournamentsCompanion.insert(
          id: tournamentId,
          organizationId: testOrgId,
          name: 'Default Test',
          scheduledDate: Value(DateTime.now()),
        ),
      );

      final result = await database.getTournamentById(tournamentId);

      expect(result!.federationType, 'wt');
      expect(result.status, 'draft');
      expect(result.isTemplate, false);
      expect(result.numberOfRings, 1);
      expect(result.settingsJson, '{}');
      expect(result.isDeleted, false);
      expect(result.isDemoData, false);
    });

    test('should support nullable fields', () async {
      const tournamentId = 'tournament-nullable';

      await database.insertTournament(
        TournamentsCompanion.insert(
          id: tournamentId,
          organizationId: testOrgId,
          name: 'Nullable Test',
          scheduledDate: Value(DateTime.now()),
        ),
      );

      final result = await database.getTournamentById(tournamentId);

      expect(result!.createdByUserId, isNull);
      expect(result.description, isNull);
      expect(result.venueName, isNull);
      expect(result.venueAddress, isNull);
      expect(result.scheduledStartTime, isNull);
      expect(result.scheduledEndTime, isNull);
      expect(result.templateId, isNull);
    });

    test('should store createdByUserId foreign key', () async {
      const tournamentId = 'tournament-with-user';

      await database.insertTournament(
        TournamentsCompanion.insert(
          id: tournamentId,
          organizationId: testOrgId,
          createdByUserId: Value(testUserId),
          name: 'Created By User Test',
          scheduledDate: Value(DateTime.now()),
        ),
      );

      final result = await database.getTournamentById(tournamentId);

      expect(result!.createdByUserId, testUserId);
    });

    test('should get tournaments for organization', () async {
      await database.insertTournament(
        TournamentsCompanion.insert(
          id: 'org-tournament-1',
          organizationId: testOrgId,
          name: 'Tournament 1',
          scheduledDate: Value(DateTime(2026, 3, 1)),
        ),
      );
      await database.insertTournament(
        TournamentsCompanion.insert(
          id: 'org-tournament-2',
          organizationId: testOrgId,
          name: 'Tournament 2',
          scheduledDate: Value(DateTime(2026, 6, 1)),
        ),
      );

      final tournaments = await database.getTournamentsForOrganization(
        testOrgId,
      );

      expect(tournaments, hasLength(2));
      // Ordered by scheduledDate DESC
      expect(tournaments.first.name, 'Tournament 2');
    });

    test('should soft delete tournament', () async {
      const tournamentId = 'tournament-delete';

      await database.insertTournament(
        TournamentsCompanion.insert(
          id: tournamentId,
          organizationId: testOrgId,
          name: 'To Delete',
          scheduledDate: Value(DateTime.now()),
        ),
      );

      final deleted = await database.softDeleteTournament(tournamentId);
      expect(deleted, true);

      final result = await database.getTournamentById(tournamentId);
      expect(result!.isDeleted, true);
      expect(result.deletedAtTimestamp, isNotNull);
    });

    test('should not include soft deleted in active list', () async {
      await database.insertTournament(
        TournamentsCompanion.insert(
          id: 'active-tournament',
          organizationId: testOrgId,
          name: 'Active',
          scheduledDate: Value(DateTime.now()),
        ),
      );
      await database.insertTournament(
        TournamentsCompanion.insert(
          id: 'deleted-tournament',
          organizationId: testOrgId,
          name: 'Deleted',
          scheduledDate: Value(DateTime.now()),
          isDeleted: const Value(true),
        ),
      );

      final tournaments = await database.getTournamentsForOrganization(
        testOrgId,
      );

      expect(tournaments, hasLength(1));
      expect(tournaments.first.name, 'Active');
    });

    test('should update tournament and increment sync_version', () async {
      const tournamentId = 'tournament-update';

      await database.insertTournament(
        TournamentsCompanion.insert(
          id: tournamentId,
          organizationId: testOrgId,
          name: 'Original Name',
          scheduledDate: Value(DateTime.now()),
        ),
      );

      await database.updateTournament(
        tournamentId,
        const TournamentsCompanion(name: Value('Updated Name')),
      );

      final updated = await database.getTournamentById(tournamentId);
      expect(updated!.name, 'Updated Name');
      expect(updated.syncVersion, 2);
    });

    test('should include BaseSyncMixin fields', () async {
      const tournamentId = 'tournament-sync-mixin';

      await database.insertTournament(
        TournamentsCompanion.insert(
          id: tournamentId,
          organizationId: testOrgId,
          name: 'Sync Mixin Test',
          scheduledDate: Value(DateTime.now()),
          isDemoData: const Value(true),
        ),
      );

      final result = await database.getTournamentById(tournamentId);

      expect(result!.syncVersion, 1);
      expect(result.isDeleted, false);
      expect(result.deletedAtTimestamp, isNull);
      expect(result.isDemoData, true);
    });

    test('should include BaseAuditMixin fields', () async {
      const tournamentId = 'tournament-audit-mixin';
      final before = DateTime.now();

      await database.insertTournament(
        TournamentsCompanion.insert(
          id: tournamentId,
          organizationId: testOrgId,
          name: 'Audit Mixin Test',
          scheduledDate: Value(DateTime.now()),
        ),
      );

      final after = DateTime.now();
      final result = await database.getTournamentById(tournamentId);

      expect(
        result!.createdAtTimestamp.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        true,
      );
      expect(
        result.createdAtTimestamp.isBefore(
          after.add(const Duration(seconds: 1)),
        ),
        true,
      );
    });

    test('should return null for non-existent tournament', () async {
      final result = await database.getTournamentById('non-existent');
      expect(result, isNull);
    });
  });
}
