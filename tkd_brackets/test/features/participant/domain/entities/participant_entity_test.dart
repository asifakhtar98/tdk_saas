import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';

void main() {
  group('ParticipantEntity', () {
    group('creation', () {
      test('should create entity with all required fields', () {
        final now = DateTime.now();
        final entity = ParticipantEntity(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Doe',
          createdAtTimestamp: now,
          updatedAtTimestamp: now,
        );

        expect(entity.id, 'test-id');
        expect(entity.divisionId, 'division-1');
        expect(entity.firstName, 'John');
        expect(entity.lastName, 'Doe');
      });

      test('should have correct default values', () {
        final now = DateTime.now();
        final entity = ParticipantEntity(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Doe',
          createdAtTimestamp: now,
          updatedAtTimestamp: now,
        );

        expect(entity.isBye, false);
        expect(entity.checkInStatus, ParticipantStatus.pending);
        expect(entity.syncVersion, 1);
        expect(entity.isDeleted, false);
        expect(entity.isDemoData, false);
      });

      test('should create entity with optional fields', () {
        final now = DateTime.now();
        final dob = DateTime(2010, 5, 15);
        final entity = ParticipantEntity(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Doe',
          dateOfBirth: dob,
          gender: Gender.male,
          weightKg: 65.5,
          schoolOrDojangName: 'Test Dojang',
          beltRank: 'black 1dan',
          seedNumber: 1,
          registrationNumber: 'REG-001',
          isBye: false,
          checkInStatus: ParticipantStatus.checkedIn,
          checkInAtTimestamp: now,
          photoUrl: 'https://example.com/photo.jpg',
          notes: 'Test notes',
          syncVersion: 1,
          isDeleted: false,
          deletedAtTimestamp: null,
          isDemoData: false,
          createdAtTimestamp: now,
          updatedAtTimestamp: now,
        );

        expect(entity.dateOfBirth, dob);
        expect(entity.gender, Gender.male);
        expect(entity.weightKg, 65.5);
        expect(entity.schoolOrDojangName, 'Test Dojang');
        expect(entity.beltRank, 'black 1dan');
        expect(entity.seedNumber, 1);
        expect(entity.registrationNumber, 'REG-001');
        expect(entity.checkInStatus, ParticipantStatus.checkedIn);
      });
    });

    group('equality', () {
      test('same fields should be equal', () {
        final now = DateTime.now();
        final entity1 = ParticipantEntity(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Doe',
          createdAtTimestamp: now,
          updatedAtTimestamp: now,
        );
        final entity2 = ParticipantEntity(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Doe',
          createdAtTimestamp: now,
          updatedAtTimestamp: now,
        );

        expect(entity1, equals(entity2));
      });

      test('different field should not be equal', () {
        final now = DateTime.now();
        final entity1 = ParticipantEntity(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Doe',
          createdAtTimestamp: now,
          updatedAtTimestamp: now,
        );
        final entity2 = ParticipantEntity(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'Jane',
          lastName: 'Doe',
          createdAtTimestamp: now,
          updatedAtTimestamp: now,
        );

        expect(entity1, isNot(equals(entity2)));
      });
    });

    group('computed age getter', () {
      test('should calculate age from dateOfBirth', () {
        final now = DateTime.now();
        final dob = DateTime(now.year - 10, 1, 1);
        final entity = ParticipantEntity(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Doe',
          dateOfBirth: dob,
          createdAtTimestamp: now,
          updatedAtTimestamp: now,
        );

        expect(entity.age, 10);
      });

      test('should return null if dateOfBirth is null', () {
        final now = DateTime.now();
        final entity = ParticipantEntity(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Doe',
          createdAtTimestamp: now,
          updatedAtTimestamp: now,
        );

        expect(entity.age, isNull);
      });

      test('should account for birthday not yet passed this year', () {
        final now = DateTime(2026, 3, 1);
        final dob = DateTime(2015, 6, 1);
        final entity = ParticipantEntity(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Doe',
          dateOfBirth: dob,
          createdAtTimestamp: now,
          updatedAtTimestamp: now,
        );

        expect(entity.age, 10);
      });
    });
  });

  group('ParticipantStatus', () {
    test('fromString should parse pending', () {
      expect(
        ParticipantStatus.fromString('pending'),
        ParticipantStatus.pending,
      );
    });

    test('fromString should parse checked_in', () {
      expect(
        ParticipantStatus.fromString('checked_in'),
        ParticipantStatus.checkedIn,
      );
    });

    test('fromString should parse no_show', () {
      expect(ParticipantStatus.fromString('no_show'), ParticipantStatus.noShow);
    });

    test('fromString should parse withdrawn', () {
      expect(
        ParticipantStatus.fromString('withdrawn'),
        ParticipantStatus.withdrawn,
      );
    });

    test('fromString should default to pending for unknown value', () {
      expect(
        ParticipantStatus.fromString('unknown'),
        ParticipantStatus.pending,
      );
    });

    test('enum values should have correct string values', () {
      expect(ParticipantStatus.pending.value, 'pending');
      expect(ParticipantStatus.checkedIn.value, 'checked_in');
      expect(ParticipantStatus.noShow.value, 'no_show');
      expect(ParticipantStatus.withdrawn.value, 'withdrawn');
    });
  });

  group('Gender', () {
    test('fromString should parse male', () {
      expect(Gender.fromString('male'), Gender.male);
    });

    test('fromString should parse female', () {
      expect(Gender.fromString('female'), Gender.female);
    });

    test('fromString should default to male for unknown value', () {
      expect(Gender.fromString('unknown'), Gender.male);
    });

    test('enum values should have correct string values', () {
      expect(Gender.male.value, 'male');
      expect(Gender.female.value, 'female');
    });
  });
}
