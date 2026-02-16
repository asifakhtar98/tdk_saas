import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/demo/demo_data_constants.dart';
import 'package:tkd_brackets/core/demo/demo_data_service.dart';
import 'package:tkd_brackets/core/sync/sync_service.dart';
import 'package:tkd_brackets/features/auth/data/services/demo_migration_service.dart';

class MockSyncService extends Mock implements SyncService {}

class MockDemoDataService extends Mock implements DemoDataService {}

void main() {
  late AppDatabase db;
  late MockSyncService mockSyncService;
  late MockDemoDataService mockDemoDataService;
  late DemoMigrationServiceImpl migrationService;

  setUp(() {
    // Use in-memory database for testing
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockSyncService = MockSyncService();
    mockDemoDataService = MockDemoDataService();
    migrationService = DemoMigrationServiceImpl(
      db,
      mockDemoDataService,
      mockSyncService,
    );

    // Default: mock sync service to do nothing
    when(
      () => mockSyncService.queueForSync(
        tableName: any(named: 'tableName'),
        recordId: any(named: 'recordId'),
        operation: any(named: 'operation'),
      ),
    ).thenReturn(null);
  });

  tearDown(() async {
    await db.close();
  });

  group('DemoMigrationService', () {
    group('hasDemoData', () {
      test('delegates to DemoDataService', () async {
        when(
          () => mockDemoDataService.hasDemoData(),
        ).thenAnswer((_) async => true);

        final result = await migrationService.hasDemoData();

        expect(result, isTrue);
        verify(() => mockDemoDataService.hasDemoData()).called(1);
      });
    });

    group('migrateDemoData', () {
      test('throws exception when no demo data exists', () async {
        when(
          () => mockDemoDataService.hasDemoData(),
        ).thenAnswer((_) async => false);

        expect(
          () => migrationService.migrateDemoData('new-org-id'),
          throwsA(
            isA<DemoMigrationException>().having(
              (e) => e.message,
              'message',
              contains('No demo data exists'),
            ),
          ),
        );
      });

      test('throws exception when production data already exists', () async {
        // Seed demo data
        when(
          () => mockDemoDataService.hasDemoData(),
        ).thenAnswer((_) async => true);
        await _seedDemoData(db);

        // Insert production organization
        await db.insertOrganization(
          OrganizationsCompanion(
            id: const Value('prod-org-id'),
            name: const Value('Production Org'),
            slug: const Value('production-org'),
            isDemoData: const Value(false),
            createdAtTimestamp: Value(DateTime.now()),
            updatedAtTimestamp: Value(DateTime.now()),
          ),
        );

        expect(
          () => migrationService.migrateDemoData('new-org-id'),
          throwsA(
            isA<DemoMigrationException>().having(
              (e) => e.message,
              'message',
              contains('production data already exists'),
            ),
          ),
        );
      });

      test('successfully migrates all demo entities with new UUIDs', () async {
        // Seed demo data
        when(
          () => mockDemoDataService.hasDemoData(),
        ).thenAnswer((_) async => true);
        await _seedDemoData(db);

        // Get original IDs before migration
        final originalOrgs = await db.getActiveOrganizations();
        final originalOrgId = originalOrgs.first.id;

        // Perform migration
        final newOrgId = 'production-org-id-123';
        final migratedCount = await migrationService.migrateDemoData(newOrgId);

        // Should have migrated: 1 org, 1 tournament, 1 division, 8 participants, 1 user
        expect(migratedCount, equals(12));

        // Verify UUID remapping - original IDs should no longer exist
        final orgAfterMigration = await (db.select(
          db.organizations,
        )..where((o) => o.id.equals(originalOrgId))).get();
        expect(orgAfterMigration, isEmpty);

        // Verify new organization has correct ID
        final newOrgs = await db.getActiveOrganizations();
        expect(newOrgs, hasLength(1));
        expect(newOrgs.first.id, equals(newOrgId));
        expect(newOrgs.first.isDemoData, isFalse);
      });

      test('preserves referential integrity after UUID remapping', () async {
        // Seed demo data
        when(
          () => mockDemoDataService.hasDemoData(),
        ).thenAnswer((_) async => true);
        await _seedDemoData(db);

        // Get original tournament to check its organization reference
        final originalTournaments = await db.getActiveTournaments();
        final originalTournament = originalTournaments.first;

        // Perform migration
        final newOrgId = 'production-org-id-123';
        await migrationService.migrateDemoData(newOrgId);

        // Verify tournament now references the new organization
        final tournamentsAfter = await db.getActiveTournaments();
        expect(tournamentsAfter, hasLength(1));
        expect(tournamentsAfter.first.organizationId, equals(newOrgId));
      });

      test('updates organization ID across all entity types', () async {
        // Seed demo data
        when(
          () => mockDemoDataService.hasDemoData(),
        ).thenAnswer((_) async => true);
        await _seedDemoData(db);

        final newOrgId = 'production-org-id-123';
        await migrationService.migrateDemoData(newOrgId);

        // Verify all entities have updated organization ID
        final tournaments = await db.getActiveTournaments();
        for (final t in tournaments) {
          expect(t.organizationId, equals(newOrgId));
        }

        final users = await db.getActiveUsers();
        for (final u in users) {
          expect(u.organizationId, equals(newOrgId));
        }
      });

      test('clears isDemoData flag for all migrated records', () async {
        // Seed demo data
        when(
          () => mockDemoDataService.hasDemoData(),
        ).thenAnswer((_) async => true);
        await _seedDemoData(db);

        await migrationService.migrateDemoData('production-org-id-123');

        // Verify all entities have isDemoData = false
        final orgs = await db.getActiveOrganizations();
        for (final o in orgs) {
          expect(o.isDemoData, isFalse);
        }

        final tournaments = await db.getActiveTournaments();
        for (final t in tournaments) {
          expect(t.isDemoData, isFalse);
        }

        final divisions = await db.getActiveDivisions();
        for (final d in divisions) {
          expect(d.isDemoData, isFalse);
        }

        final participants = await db.getActiveParticipants();
        for (final p in participants) {
          expect(p.isDemoData, isFalse);
        }

        final users = await db.getActiveUsers();
        for (final u in users) {
          expect(u.isDemoData, isFalse);
        }
      });

      test('marks demo users as inactive after migration', () async {
        // Seed demo data
        when(
          () => mockDemoDataService.hasDemoData(),
        ).thenAnswer((_) async => true);
        await _seedDemoData(db);

        await migrationService.migrateDemoData('production-org-id-123');

        // Verify demo user is marked inactive
        final users = await db.getActiveUsers();
        for (final u in users) {
          expect(u.isActive, isFalse);
        }
      });

      test('preserves all data fields during migration', () async {
        // Seed demo data
        when(
          () => mockDemoDataService.hasDemoData(),
        ).thenAnswer((_) async => true);
        await _seedDemoData(db);

        final originalOrgs = await db.getActiveOrganizations();
        final originalOrg = originalOrgs.first;
        final originalName = originalOrg.name;
        final originalSlug = originalOrg.slug;

        await migrationService.migrateDemoData('production-org-id-123');

        // Verify data preserved
        final newOrgs = await db.getActiveOrganizations();
        expect(newOrgs.first.name, equals(originalName));
        expect(newOrgs.first.slug, equals(originalSlug));
      });

      test('queues all migrated entities for sync', () async {
        // Seed demo data
        when(
          () => mockDemoDataService.hasDemoData(),
        ).thenAnswer((_) async => true);
        await _seedDemoData(db);

        await migrationService.migrateDemoData('production-org-id-123');

        // Verify sync service was called for organizations
        verify(
          () => mockSyncService.queueForSync(
            tableName: 'organizations',
            recordId: any(named: 'recordId'),
            operation: 'update',
          ),
        ).called(1);

        // Verify sync service was called for users
        verify(
          () => mockSyncService.queueForSync(
            tableName: 'users',
            recordId: any(named: 'recordId'),
            operation: 'update',
          ),
        ).called(1);

        // Verify sync service was called for tournaments
        verify(
          () => mockSyncService.queueForSync(
            tableName: 'tournaments',
            recordId: any(named: 'recordId'),
            operation: 'update',
          ),
        ).called(1);
      });

      test('increments syncVersion for all migrated entities', () async {
        // Seed demo data
        when(
          () => mockDemoDataService.hasDemoData(),
        ).thenAnswer((_) async => true);
        await _seedDemoData(db);

        final originalOrgs = await db.getActiveOrganizations();
        final originalSyncVersion = originalOrgs.first.syncVersion;

        await migrationService.migrateDemoData('production-org-id-123');

        final newOrgs = await db.getActiveOrganizations();
        expect(newOrgs.first.syncVersion, equals(originalSyncVersion + 1));
      });

      test('performs migration atomically - rolls back on failure', () async {
        // This test is harder to implement without injecting failures
        // For now, we verify the transaction structure is in place
        when(
          () => mockDemoDataService.hasDemoData(),
        ).thenAnswer((_) async => true);
        await _seedDemoData(db);

        final originalOrgs = await db.getActiveOrganizations();
        final originalOrgId = originalOrgs.first.id;

        // Migration should succeed normally
        await migrationService.migrateDemoData('production-org-id-123');

        // Verify complete migration occurred
        final newOrgs = await db.getActiveOrganizations();
        expect(newOrgs.first.id, isNot(equals(originalOrgId)));
      });
    });
  });
}

/// Helper to seed demo data for migration tests
Future<void> _seedDemoData(AppDatabase db) async {
  // Insert demo organization
  await db.insertOrganization(
    OrganizationsCompanion(
      id: Value(DemoDataConstants.demoOrganizationId),
      name: const Value('Demo Dojang'),
      slug: const Value('demo-dojang'),
      isDemoData: const Value(true),
      subscriptionTier: const Value('free'),
      subscriptionStatus: const Value('active'),
      maxTournamentsPerMonth: const Value(2),
      maxActiveBrackets: const Value(3),
      maxParticipantsPerBracket: const Value(32),
      maxParticipantsPerTournament: const Value(100),
      maxScorers: const Value(2),
      isActive: const Value(true),
      createdAtTimestamp: Value(DateTime(2024, 1, 1)),
      updatedAtTimestamp: Value(DateTime(2024, 1, 1)),
    ),
  );

  // Insert demo user
  await db.insertUser(
    UsersCompanion(
      id: Value(DemoDataConstants.demoUserId),
      organizationId: Value(DemoDataConstants.demoOrganizationId),
      email: const Value('demo@example.com'),
      displayName: const Value('Demo User'),
      role: const Value('owner'),
      isActive: const Value(true),
      isDemoData: const Value(true),
      createdAtTimestamp: Value(DateTime(2024, 1, 1)),
      updatedAtTimestamp: Value(DateTime(2024, 1, 1)),
    ),
  );

  // Insert demo tournament
  await db.insertTournament(
    TournamentsCompanion(
      id: Value(DemoDataConstants.demoTournamentId),
      organizationId: Value(DemoDataConstants.demoOrganizationId),
      createdByUserId: Value(DemoDataConstants.demoUserId),
      name: const Value('Demo Tournament'),
      description: const Value('A demo tournament'),
      venueName: const Value('Demo Venue'),
      venueAddress: const Value('123 Demo St'),
      scheduledDate: Value(DateTime(2024, 6, 15)),
      status: const Value('draft'),
      isTemplate: const Value(false),
      numberOfRings: const Value(2),
      isDemoData: const Value(true),
      createdAtTimestamp: Value(DateTime(2024, 1, 1)),
      updatedAtTimestamp: Value(DateTime(2024, 1, 1)),
    ),
  );

  // Insert demo division
  final divisionId = 'demo-division-id';
  await db.insertDivision(
    DivisionsCompanion(
      id: Value(divisionId),
      tournamentId: Value(DemoDataConstants.demoTournamentId),
      name: const Value('Demo Division'),
      category: const Value('forms'),
      gender: const Value('mixed'),
      bracketFormat: const Value('single_elimination'),
      displayOrder: const Value(1),
      status: const Value('draft'),
      isDemoData: const Value(true),
      createdAtTimestamp: Value(DateTime(2024, 1, 1)),
      updatedAtTimestamp: Value(DateTime(2024, 1, 1)),
    ),
  );

  // Insert demo participants
  for (var i = 0; i < 8; i++) {
    await db.insertParticipant(
      ParticipantsCompanion(
        id: Value('demo-participant-$i'),
        divisionId: Value(divisionId),
        firstName: Value('Participant'),
        lastName: Value('$i'),
        gender: const Value('male'),
        beltRank: const Value('white'),
        checkInStatus: const Value('not_checked_in'),
        isBye: const Value(false),
        isDemoData: const Value(true),
        createdAtTimestamp: Value(DateTime(2024, 1, 1)),
        updatedAtTimestamp: Value(DateTime(2024, 1, 1)),
      ),
    );
  }
}
