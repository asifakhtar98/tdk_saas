import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/database/app_database.dart';

void main() {
  late AppDatabase database;
  late String testOrgId;
  late String testTournamentId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    testOrgId = 'test-org-for-divisions';
    testTournamentId = 'test-tournament-for-divisions';

    // Create prerequisite organization
    await database.insertOrganization(
      OrganizationsCompanion.insert(
        id: testOrgId,
        name: 'Test Org',
        slug: 'test-org',
      ),
    );

    // Create prerequisite tournament
    await database.insertTournament(
      TournamentsCompanion.insert(
        id: testTournamentId,
        organizationId: testOrgId,
        name: 'Test Tournament',
        scheduledDate: Value(DateTime.now()),
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('Divisions Table', () {
    test('should insert and retrieve division', () async {
      const divisionId = 'division-123';

      await database.insertDivision(
        DivisionsCompanion.insert(
          id: divisionId,
          tournamentId: testTournamentId,
          name: 'Cadets -45kg Male',
          gender: 'male',
        ),
      );

      final result = await database.getDivisionById(divisionId);

      expect(result, isNotNull);
      expect(result!.name, 'Cadets -45kg Male');
      expect(result.tournamentId, testTournamentId);
      expect(result.gender, 'male');
    });

    test('should have correct default values', () async {
      const divisionId = 'division-defaults';

      await database.insertDivision(
        DivisionsCompanion.insert(
          id: divisionId,
          tournamentId: testTournamentId,
          name: 'Default Test',
          gender: 'male',
        ),
      );

      final result = await database.getDivisionById(divisionId);

      expect(result!.category, 'sparring');
      expect(result.bracketFormat, 'single_elimination');
      expect(result.isCombined, false);
      expect(result.displayOrder, 0);
      expect(result.status, 'setup');
      expect(result.isDeleted, false);
      expect(result.isDemoData, false);
    });

    test('should support nullable fields', () async {
      const divisionId = 'division-nullable';

      await database.insertDivision(
        DivisionsCompanion.insert(
          id: divisionId,
          tournamentId: testTournamentId,
          name: 'Nullable Test',
          gender: 'female',
        ),
      );

      final result = await database.getDivisionById(divisionId);

      expect(result!.ageMin, isNull);
      expect(result.ageMax, isNull);
      expect(result.weightMinKg, isNull);
      expect(result.weightMaxKg, isNull);
      expect(result.beltRankMin, isNull);
      expect(result.beltRankMax, isNull);
      expect(result.assignedRingNumber, isNull);
    });

    test('should store age and weight ranges', () async {
      const divisionId = 'division-ranges';

      await database.insertDivision(
        DivisionsCompanion.insert(
          id: divisionId,
          tournamentId: testTournamentId,
          name: 'Range Test',
          gender: 'male',
          ageMin: const Value(12),
          ageMax: const Value(14),
          weightMinKg: const Value(0),
          weightMaxKg: const Value(45),
        ),
      );

      final result = await database.getDivisionById(divisionId);

      expect(result!.ageMin, 12);
      expect(result.ageMax, 14);
      expect(result.weightMinKg, 0);
      expect(result.weightMaxKg, 45);
    });

    test('should store belt rank ranges', () async {
      const divisionId = 'division-belt-ranks';

      await database.insertDivision(
        DivisionsCompanion.insert(
          id: divisionId,
          tournamentId: testTournamentId,
          name: 'Belt Rank Test',
          gender: 'mixed',
          beltRankMin: const Value('red'),
          beltRankMax: const Value('black 1dan'),
        ),
      );

      final result = await database.getDivisionById(divisionId);

      expect(result!.beltRankMin, 'red');
      expect(result.beltRankMax, 'black 1dan');
    });

    test('should get divisions for tournament', () async {
      await database.insertDivision(
        DivisionsCompanion.insert(
          id: 'tournament-division-1',
          tournamentId: testTournamentId,
          name: 'Division 1',
          gender: 'male',
          displayOrder: const Value(1),
        ),
      );
      await database.insertDivision(
        DivisionsCompanion.insert(
          id: 'tournament-division-2',
          tournamentId: testTournamentId,
          name: 'Division 2',
          gender: 'female',
          displayOrder: const Value(0),
        ),
      );

      final divisions = await database.getDivisionsForTournament(
        testTournamentId,
      );

      expect(divisions, hasLength(2));
      // Ordered by displayOrder ASC
      expect(divisions.first.name, 'Division 2');
    });

    test('should soft delete division', () async {
      const divisionId = 'division-delete';

      await database.insertDivision(
        DivisionsCompanion.insert(
          id: divisionId,
          tournamentId: testTournamentId,
          name: 'To Delete',
          gender: 'male',
        ),
      );

      final deleted = await database.softDeleteDivision(divisionId);
      expect(deleted, true);

      final result = await database.getDivisionById(divisionId);
      expect(result!.isDeleted, true);
      expect(result.deletedAtTimestamp, isNotNull);
    });

    test('should not include soft deleted in active list', () async {
      await database.insertDivision(
        DivisionsCompanion.insert(
          id: 'active-division',
          tournamentId: testTournamentId,
          name: 'Active',
          gender: 'male',
        ),
      );
      await database.insertDivision(
        DivisionsCompanion.insert(
          id: 'deleted-division',
          tournamentId: testTournamentId,
          name: 'Deleted',
          gender: 'male',
          isDeleted: const Value(true),
        ),
      );

      final divisions = await database.getDivisionsForTournament(
        testTournamentId,
      );

      expect(divisions, hasLength(1));
      expect(divisions.first.name, 'Active');
    });

    test('should update division and increment sync_version', () async {
      const divisionId = 'division-update';

      await database.insertDivision(
        DivisionsCompanion.insert(
          id: divisionId,
          tournamentId: testTournamentId,
          name: 'Original Name',
          gender: 'male',
        ),
      );

      await database.updateDivision(
        divisionId,
        const DivisionsCompanion(name: Value('Updated Name')),
      );

      final updated = await database.getDivisionById(divisionId);
      expect(updated!.name, 'Updated Name');
      expect(updated.syncVersion, 2);
    });

    test('should include BaseSyncMixin fields', () async {
      const divisionId = 'division-sync-mixin';

      await database.insertDivision(
        DivisionsCompanion.insert(
          id: divisionId,
          tournamentId: testTournamentId,
          name: 'Sync Mixin Test',
          gender: 'male',
          isDemoData: const Value(true),
        ),
      );

      final result = await database.getDivisionById(divisionId);

      expect(result!.syncVersion, 1);
      expect(result.isDeleted, false);
      expect(result.deletedAtTimestamp, isNull);
      expect(result.isDemoData, true);
    });

    test('should include BaseAuditMixin fields', () async {
      const divisionId = 'division-audit-mixin';
      final before = DateTime.now();

      await database.insertDivision(
        DivisionsCompanion.insert(
          id: divisionId,
          tournamentId: testTournamentId,
          name: 'Audit Mixin Test',
          gender: 'male',
        ),
      );

      final after = DateTime.now();
      final result = await database.getDivisionById(divisionId);

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

    test('should return null for non-existent division', () async {
      final result = await database.getDivisionById('non-existent');
      expect(result, isNull);
    });

    test('should support all category values', () async {
      final categories = ['sparring', 'poomsae', 'breaking', 'demo_team'];

      for (var i = 0; i < categories.length; i++) {
        final category = categories[i];
        final divisionId = 'division-category-$i';

        await database.insertDivision(
          DivisionsCompanion.insert(
            id: divisionId,
            tournamentId: testTournamentId,
            name: 'Category $category',
            gender: 'male',
            category: Value(category),
          ),
        );

        final result = await database.getDivisionById(divisionId);
        expect(result!.category, category);
      }
    });

    test('should support all bracket format values', () async {
      final formats = [
        'single_elimination',
        'double_elimination',
        'round_robin',
        'pool_play',
      ];

      for (var i = 0; i < formats.length; i++) {
        final format = formats[i];
        final divisionId = 'division-format-$i';

        await database.insertDivision(
          DivisionsCompanion.insert(
            id: divisionId,
            tournamentId: testTournamentId,
            name: 'Format $format',
            gender: 'male',
            bracketFormat: Value(format),
          ),
        );

        final result = await database.getDivisionById(divisionId);
        expect(result!.bracketFormat, format);
      }
    });
  });
}
