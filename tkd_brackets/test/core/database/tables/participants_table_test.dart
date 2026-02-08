import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/database/app_database.dart';

void main() {
  late AppDatabase database;
  late String testOrgId;
  late String testTournamentId;
  late String testDivisionId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    testOrgId = 'test-org-for-participants';
    testTournamentId = 'test-tournament-for-participants';
    testDivisionId = 'test-division-for-participants';

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
        scheduledDate: DateTime.now(),
      ),
    );

    // Create prerequisite division
    await database.insertDivision(
      DivisionsCompanion.insert(
        id: testDivisionId,
        tournamentId: testTournamentId,
        name: 'Test Division',
        gender: 'male',
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('Participants Table', () {
    test('should insert and retrieve participant', () async {
      const participantId = 'participant-123';

      await database.insertParticipant(
        ParticipantsCompanion.insert(
          id: participantId,
          divisionId: testDivisionId,
          firstName: 'Min-jun',
          lastName: 'Kim',
        ),
      );

      final result = await database.getParticipantById(participantId);

      expect(result, isNotNull);
      expect(result!.firstName, 'Min-jun');
      expect(result.lastName, 'Kim');
      expect(result.divisionId, testDivisionId);
    });

    test('should have correct default values', () async {
      const participantId = 'participant-defaults';

      await database.insertParticipant(
        ParticipantsCompanion.insert(
          id: participantId,
          divisionId: testDivisionId,
          firstName: 'Test',
          lastName: 'User',
        ),
      );

      final result = await database.getParticipantById(participantId);

      expect(result!.isBye, false);
      expect(result.checkInStatus, 'pending');
      expect(result.isDeleted, false);
      expect(result.isDemoData, false);
    });

    test('should support nullable fields', () async {
      const participantId = 'participant-nullable';

      await database.insertParticipant(
        ParticipantsCompanion.insert(
          id: participantId,
          divisionId: testDivisionId,
          firstName: 'Nullable',
          lastName: 'Test',
        ),
      );

      final result = await database.getParticipantById(participantId);

      expect(result!.dateOfBirth, isNull);
      expect(result.gender, isNull);
      expect(result.weightKg, isNull);
      expect(result.schoolOrDojangName, isNull);
      expect(result.beltRank, isNull);
      expect(result.seedNumber, isNull);
      expect(result.registrationNumber, isNull);
      expect(result.checkInAtTimestamp, isNull);
      expect(result.photoUrl, isNull);
      expect(result.notes, isNull);
    });

    test('should store schoolOrDojangName (critical for dojang separation)',
        () async {
      const participantId = 'participant-dojang';

      await database.insertParticipant(
        ParticipantsCompanion.insert(
          id: participantId,
          divisionId: testDivisionId,
          firstName: 'Dojang',
          lastName: 'Test',
          schoolOrDojangName: const Value('Dragon Martial Arts'),
        ),
      );

      final result = await database.getParticipantById(participantId);

      expect(result!.schoolOrDojangName, 'Dragon Martial Arts');
    });

    test('should store all athletic data', () async {
      const participantId = 'participant-athletic';
      final dateOfBirth = DateTime(2012, 5, 15);

      await database.insertParticipant(
        ParticipantsCompanion.insert(
          id: participantId,
          divisionId: testDivisionId,
          firstName: 'Athlete',
          lastName: 'Test',
          dateOfBirth: Value(dateOfBirth),
          gender: const Value('male'),
          weightKg: const Value(42.5),
          beltRank: const Value('black 1dan'),
          seedNumber: const Value(1),
        ),
      );

      final result = await database.getParticipantById(participantId);

      expect(result!.dateOfBirth, dateOfBirth);
      expect(result.gender, 'male');
      expect(result.weightKg, 42.5);
      expect(result.beltRank, 'black 1dan');
      expect(result.seedNumber, 1);
    });

    test('should get participants for division', () async {
      await database.insertParticipant(
        ParticipantsCompanion.insert(
          id: 'division-participant-1',
          divisionId: testDivisionId,
          firstName: 'Beta',
          lastName: 'User',
          seedNumber: const Value(2),
        ),
      );
      await database.insertParticipant(
        ParticipantsCompanion.insert(
          id: 'division-participant-2',
          divisionId: testDivisionId,
          firstName: 'Alpha',
          lastName: 'User',
          seedNumber: const Value(1),
        ),
      );

      final participants =
          await database.getParticipantsForDivision(testDivisionId);

      expect(participants, hasLength(2));
      // Ordered by seedNumber ASC, then lastName ASC
      expect(participants.first.firstName, 'Alpha');
    });

    test('should soft delete participant', () async {
      const participantId = 'participant-delete';

      await database.insertParticipant(
        ParticipantsCompanion.insert(
          id: participantId,
          divisionId: testDivisionId,
          firstName: 'Delete',
          lastName: 'Me',
        ),
      );

      final deleted = await database.softDeleteParticipant(participantId);
      expect(deleted, true);

      final result = await database.getParticipantById(participantId);
      expect(result!.isDeleted, true);
      expect(result.deletedAtTimestamp, isNotNull);
    });

    test('should not include soft deleted in active list', () async {
      await database.insertParticipant(
        ParticipantsCompanion.insert(
          id: 'active-participant',
          divisionId: testDivisionId,
          firstName: 'Active',
          lastName: 'User',
        ),
      );
      await database.insertParticipant(
        ParticipantsCompanion.insert(
          id: 'deleted-participant',
          divisionId: testDivisionId,
          firstName: 'Deleted',
          lastName: 'User',
          isDeleted: const Value(true),
        ),
      );

      final participants =
          await database.getParticipantsForDivision(testDivisionId);

      expect(participants, hasLength(1));
      expect(participants.first.firstName, 'Active');
    });

    test('should update participant and increment sync_version', () async {
      const participantId = 'participant-update';

      await database.insertParticipant(
        ParticipantsCompanion.insert(
          id: participantId,
          divisionId: testDivisionId,
          firstName: 'Original',
          lastName: 'Name',
        ),
      );

      await database.updateParticipant(
        participantId,
        const ParticipantsCompanion(
          firstName: Value('Updated'),
        ),
      );

      final updated = await database.getParticipantById(participantId);
      expect(updated!.firstName, 'Updated');
      expect(updated.syncVersion, 2);
    });

    test('should include BaseSyncMixin fields', () async {
      const participantId = 'participant-sync-mixin';

      await database.insertParticipant(
        ParticipantsCompanion.insert(
          id: participantId,
          divisionId: testDivisionId,
          firstName: 'Sync',
          lastName: 'Mixin',
          isDemoData: const Value(true),
        ),
      );

      final result = await database.getParticipantById(participantId);

      expect(result!.syncVersion, 1);
      expect(result.isDeleted, false);
      expect(result.deletedAtTimestamp, isNull);
      expect(result.isDemoData, true);
    });

    test('should include BaseAuditMixin fields', () async {
      const participantId = 'participant-audit-mixin';
      final before = DateTime.now();

      await database.insertParticipant(
        ParticipantsCompanion.insert(
          id: participantId,
          divisionId: testDivisionId,
          firstName: 'Audit',
          lastName: 'Mixin',
        ),
      );

      final after = DateTime.now();
      final result = await database.getParticipantById(participantId);

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

    test('should return null for non-existent participant', () async {
      final result = await database.getParticipantById('non-existent');
      expect(result, isNull);
    });

    test('should support bye participants', () async {
      const participantId = 'participant-bye';

      await database.insertParticipant(
        ParticipantsCompanion.insert(
          id: participantId,
          divisionId: testDivisionId,
          firstName: 'BYE',
          lastName: '',
          isBye: const Value(true),
        ),
      );

      final result = await database.getParticipantById(participantId);

      expect(result!.isBye, true);
    });

    test('should support all check-in status values', () async {
      final statuses = ['pending', 'checked_in', 'no_show', 'withdrawn'];

      for (var i = 0; i < statuses.length; i++) {
        final status = statuses[i];
        final participantId = 'participant-status-$i';

        await database.insertParticipant(
          ParticipantsCompanion.insert(
            id: participantId,
            divisionId: testDivisionId,
            firstName: 'Status',
            lastName: status,
            checkInStatus: Value(status),
          ),
        );

        final result = await database.getParticipantById(participantId);
        expect(result!.checkInStatus, status);
      }
    });

    test('should store check-in timestamp', () async {
      const participantId = 'participant-checkin-time';
      final checkInTime = DateTime.now();

      await database.insertParticipant(
        ParticipantsCompanion.insert(
          id: participantId,
          divisionId: testDivisionId,
          firstName: 'Checked',
          lastName: 'In',
          checkInStatus: const Value('checked_in'),
          checkInAtTimestamp: Value(checkInTime),
        ),
      );

      final result = await database.getParticipantById(participantId);

      expect(result!.checkInStatus, 'checked_in');
      expect(result.checkInAtTimestamp, isNotNull);
    });
  });
}
