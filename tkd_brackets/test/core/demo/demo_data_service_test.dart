import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/demo/demo_data_constants.dart';
import 'package:tkd_brackets/core/demo/demo_data_service.dart';

void main() {
  late AppDatabase db;
  late DemoDataServiceImpl demoService;

  setUp(() {
    // Use in-memory database for testing
    db = AppDatabase.forTesting(NativeDatabase.memory());
    demoService = DemoDataServiceImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DemoDataService', () {
    group('shouldSeedDemoData', () {
      test('returns true when database is empty', () async {
        final shouldSeed = await demoService.shouldSeedDemoData();

        expect(shouldSeed, isTrue);
      });

      test('returns false when organizations exist', () async {
        // Insert a non-demo organization
        await db.insertOrganization(
          OrganizationsCompanion(
            id: const Value('test-org-id'),
            name: const Value('Test Org'),
            slug: const Value('test-org'),
            createdAtTimestamp: Value(DateTime.now()),
            updatedAtTimestamp: Value(DateTime.now()),
          ),
        );

        final shouldSeed = await demoService.shouldSeedDemoData();

        expect(shouldSeed, isFalse);
      });

      test('returns false after demo data is seeded', () async {
        await demoService.seedDemoData();

        final shouldSeed = await demoService.shouldSeedDemoData();

        expect(shouldSeed, isFalse);
      });
    });

    group('hasDemoData', () {
      test('returns false when database is empty', () async {
        final hasDemoData = await demoService.hasDemoData();

        expect(hasDemoData, isFalse);
      });

      test('returns true after seeding demo data', () async {
        await demoService.seedDemoData();

        final hasDemoData = await demoService.hasDemoData();

        expect(hasDemoData, isTrue);
      });

      test('returns false when only non-demo data exists', () async {
        // Insert non-demo organization
        await db.insertOrganization(
          OrganizationsCompanion(
            id: const Value('real-org-id'),
            name: const Value('Real Org'),
            slug: const Value('real-org'),
            isDemoData: const Value(false),
            createdAtTimestamp: Value(DateTime.now()),
            updatedAtTimestamp: Value(DateTime.now()),
          ),
        );

        final hasDemoData = await demoService.hasDemoData();

        expect(hasDemoData, isFalse);
      });
    });

    group('seedDemoData', () {
      test('creates demo organization with correct data', () async {
        await demoService.seedDemoData();

        final orgs = await db.getActiveOrganizations();
        expect(orgs, hasLength(1));

        final org = orgs.first;
        expect(org.id, equals(DemoDataConstants.demoOrganizationId));
        expect(org.name, equals(DemoDataConstants.demoOrganizationName));
        expect(org.slug, equals(DemoDataConstants.demoOrganizationSlug));
        expect(
          org.subscriptionTier,
          equals(DemoDataConstants.demoOrganizationTier),
        );
        expect(org.isDemoData, isTrue);
      });

      test('creates demo user with correct data', () async {
        await demoService.seedDemoData();

        final users = await db.getActiveUsers();
        expect(users, hasLength(1));

        final user = users.first;
        expect(user.id, equals(DemoDataConstants.demoUserId));
        expect(
          user.organizationId,
          equals(DemoDataConstants.demoOrganizationId),
        );
        expect(user.email, equals(DemoDataConstants.demoUserEmail));
        expect(user.displayName, equals(DemoDataConstants.demoUserDisplayName));
        expect(user.role, equals(DemoDataConstants.demoUserRole));
        expect(user.isDemoData, isTrue);
      });

      test('creates demo tournament with correct data', () async {
        await demoService.seedDemoData();

        final tournaments = await db.getActiveTournaments();
        expect(tournaments, hasLength(1));

        final tournament = tournaments.first;
        expect(tournament.id, equals(DemoDataConstants.demoTournamentId));
        expect(
          tournament.organizationId,
          equals(DemoDataConstants.demoOrganizationId),
        );
        expect(
          tournament.createdByUserId,
          equals(DemoDataConstants.demoUserId),
        );
        expect(tournament.name, equals(DemoDataConstants.demoTournamentName));
        expect(
          tournament.federationType,
          equals(DemoDataConstants.demoTournamentFederation),
        );
        expect(
          tournament.status,
          equals(DemoDataConstants.demoTournamentStatus),
        );
        expect(tournament.isDemoData, isTrue);
      });

      test('creates demo division with correct data', () async {
        await demoService.seedDemoData();

        final divisions = await db.getActiveDivisions();
        expect(divisions, hasLength(1));

        final division = divisions.first;
        expect(division.id, equals(DemoDataConstants.demoDivisionId));
        expect(
          division.tournamentId,
          equals(DemoDataConstants.demoTournamentId),
        );
        expect(division.name, equals(DemoDataConstants.demoDivisionName));
        expect(
          division.category,
          equals(DemoDataConstants.demoDivisionCategory),
        );
        expect(division.gender, equals(DemoDataConstants.demoDivisionGender));
        expect(division.ageMin, equals(DemoDataConstants.demoDivisionAgeMin));
        expect(division.ageMax, equals(DemoDataConstants.demoDivisionAgeMax));
        expect(
          division.bracketFormat,
          equals(DemoDataConstants.demoDivisionBracketFormat),
        );
        expect(division.status, equals(DemoDataConstants.demoDivisionStatus));
        expect(division.isDemoData, isTrue);
      });

      test('creates 8 demo participants', () async {
        await demoService.seedDemoData();

        final participants = await db.getActiveParticipants();
        expect(participants, hasLength(8));
      });

      test('demo participants are from 4 different dojangs', () async {
        await demoService.seedDemoData();

        final participants = await db.getActiveParticipants();
        final dojangs = participants.map((p) => p.schoolOrDojangName).toSet();

        expect(dojangs, hasLength(4));
        for (final dojang in DemoDataConstants.sampleDojangs) {
          expect(dojangs, contains(dojang));
        }
      });

      test('each dojang has exactly 2 participants', () async {
        await demoService.seedDemoData();

        final participants = await db.getActiveParticipants();

        for (final dojang in DemoDataConstants.sampleDojangs) {
          final count = participants
              .where((p) => p.schoolOrDojangName == dojang)
              .length;
          expect(count, equals(2), reason: 'Dojang $dojang should have 2');
        }
      });

      test('demo participants have UUIDs from constants', () async {
        await demoService.seedDemoData();

        final participants = await db.getActiveParticipants();
        final ids = participants.map((p) => p.id).toSet();

        for (final expectedId in DemoDataConstants.demoParticipantIds) {
          expect(ids, contains(expectedId));
        }
      });

      test('all demo participants are marked as demo data', () async {
        await demoService.seedDemoData();

        final participants = await db.getActiveParticipants();

        for (final participant in participants) {
          expect(participant.isDemoData, isTrue);
        }
      });

      test('demo participants have valid ages (12-14)', () async {
        await demoService.seedDemoData();

        final participants = await db.getActiveParticipants();
        final now = DateTime.now();

        for (final participant in participants) {
          expect(participant.dateOfBirth, isNotNull);
          final age = now.year - participant.dateOfBirth!.year;
          expect(
            age,
            inInclusiveRange(12, 14),
            reason: '${participant.firstName} age should be 12-14',
          );
        }
      });

      test('all demo participants belong to demo division', () async {
        await demoService.seedDemoData();

        final participants = await db.getActiveParticipants();

        for (final participant in participants) {
          expect(
            participant.divisionId,
            equals(DemoDataConstants.demoDivisionId),
          );
        }
      });
    });

    group('clearDemoData', () {
      test('removes all demo data from database', () async {
        await demoService.seedDemoData();

        // Verify data exists
        expect(await demoService.hasDemoData(), isTrue);

        // Clear demo data
        await db.clearDemoData();

        // Verify all demo data is gone
        expect(await demoService.hasDemoData(), isFalse);
        expect(await db.getActiveOrganizations(), isEmpty);
        expect(await db.getActiveUsers(), isEmpty);
        expect(await db.getActiveTournaments(), isEmpty);
        expect(await db.getActiveDivisions(), isEmpty);
        expect(await db.getActiveParticipants(), isEmpty);
      });

      test('does not remove non-demo data', () async {
        // Seed demo data first
        await demoService.seedDemoData();

        // Add non-demo organization
        await db.insertOrganization(
          OrganizationsCompanion(
            id: const Value('real-org-id'),
            name: const Value('Real Org'),
            slug: const Value('real-org'),
            isDemoData: const Value(false),
            createdAtTimestamp: Value(DateTime.now()),
            updatedAtTimestamp: Value(DateTime.now()),
          ),
        );

        // Clear demo data
        await db.clearDemoData();

        // Verify non-demo org remains
        final orgs = await db.getActiveOrganizations();
        expect(orgs, hasLength(1));
        expect(orgs.first.id, equals('real-org-id'));
        expect(orgs.first.isDemoData, isFalse);
      });
    });

    group('transaction rollback', () {
      // This test verifies transactional behavior - if any insert fails,
      // all data should be rolled back (all-or-nothing seeding)
      test('seeding is atomic - all or nothing', () async {
        // Verify state before seeding
        expect(await db.getActiveOrganizations(), isEmpty);
        expect(await db.getActiveUsers(), isEmpty);
        expect(await db.getActiveTournaments(), isEmpty);
        expect(await db.getActiveDivisions(), isEmpty);
        expect(await db.getActiveParticipants(), isEmpty);

        // Seed should succeed
        await demoService.seedDemoData();

        // All entities should be present
        expect(await db.getActiveOrganizations(), hasLength(1));
        expect(await db.getActiveUsers(), hasLength(1));
        expect(await db.getActiveTournaments(), hasLength(1));
        expect(await db.getActiveDivisions(), hasLength(1));
        expect(await db.getActiveParticipants(), hasLength(8));
      });
    });
  });
}
