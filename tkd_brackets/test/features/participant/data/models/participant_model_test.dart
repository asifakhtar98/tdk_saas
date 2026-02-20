import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/participant/data/models/participant_model.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';

void main() {
  group('ParticipantModel', () {
    final testDateTime = DateTime(2026, 1, 15, 10, 30);

    group('fromJson', () {
      test('should parse JSON with snake_case keys', () {
        final json = {
          'id': 'test-id',
          'division_id': 'division-1',
          'first_name': 'John',
          'last_name': 'Doe',
          'date_of_birth': '2010-05-15T00:00:00.000',
          'gender': 'male',
          'weight_kg': 65.5,
          'school_or_dojang_name': 'Test Dojang',
          'belt_rank': 'black 1dan',
          'seed_number': 1,
          'registration_number': 'REG-001',
          'is_bye': false,
          'check_in_status': 'pending',
          'check_in_at_timestamp': null,
          'photo_url': 'https://example.com/photo.jpg',
          'notes': 'Test notes',
          'sync_version': 1,
          'is_deleted': false,
          'deleted_at_timestamp': null,
          'is_demo_data': false,
          'created_at_timestamp': '2026-01-15T10:30:00.000',
          'updated_at_timestamp': '2026-01-15T10:30:00.000',
        };

        final model = ParticipantModel.fromJson(json);

        expect(model.id, 'test-id');
        expect(model.divisionId, 'division-1');
        expect(model.firstName, 'John');
        expect(model.lastName, 'Doe');
        expect(model.gender, 'male');
        expect(model.weightKg, 65.5);
        expect(model.schoolOrDojangName, 'Test Dojang');
        expect(model.seedNumber, 1);
        expect(model.registrationNumber, 'REG-001');
        expect(model.isBye, false);
        expect(model.checkInStatus, 'pending');
        expect(model.syncVersion, 1);
        expect(model.isDeleted, false);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'test-id',
          'division_id': 'division-1',
          'first_name': 'John',
          'last_name': 'Doe',
          'gender': null,
          'weight_kg': null,
          'school_or_dojang_name': null,
          'seed_number': null,
          'check_in_status': 'pending',
          'sync_version': 1,
          'is_deleted': false,
          'is_demo_data': false,
          'created_at_timestamp': '2026-01-15T10:30:00.000',
          'updated_at_timestamp': '2026-01-15T10:30:00.000',
        };

        final model = ParticipantModel.fromJson(json);

        expect(model.gender, isNull);
        expect(model.weightKg, isNull);
        expect(model.schoolOrDojangName, isNull);
        expect(model.seedNumber, isNull);
      });
    });

    group('toJson', () {
      test('should serialize to snake_case keys', () {
        final model = ParticipantModel(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Doe',
          gender: 'male',
          weightKg: 65.5,
          schoolOrDojangName: 'Test Dojang',
          seedNumber: 1,
          checkInStatus: 'pending',
          syncVersion: 1,
          isDeleted: false,
          isDemoData: false,
          createdAtTimestamp: testDateTime,
          updatedAtTimestamp: testDateTime,
        );

        final json = model.toJson();

        expect(json['id'], 'test-id');
        expect(json['division_id'], 'division-1');
        expect(json['first_name'], 'John');
        expect(json['last_name'], 'Doe');
        expect(json['gender'], 'male');
        expect(json['weight_kg'], 65.5);
        expect(json['school_or_dojang_name'], 'Test Dojang');
        expect(json['seed_number'], 1);
        expect(json['check_in_status'], 'pending');
        expect(json['sync_version'], 1);
      });
    });

    group('fromDriftEntry', () {
      test('should convert Drift entry to model', () {
        final entry = ParticipantEntry(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Doe',
          dateOfBirth: DateTime(2010, 5, 15),
          gender: 'male',
          weightKg: 65.5,
          schoolOrDojangName: 'Test Dojang',
          beltRank: 'black 1dan',
          seedNumber: 1,
          registrationNumber: 'REG-001',
          isBye: false,
          checkInStatus: 'pending',
          checkInAtTimestamp: null,
          photoUrl: 'https://example.com/photo.jpg',
          notes: 'Test notes',
          syncVersion: 1,
          isDeleted: false,
          deletedAtTimestamp: null,
          isDemoData: false,
          createdAtTimestamp: testDateTime,
          updatedAtTimestamp: testDateTime,
        );

        final model = ParticipantModel.fromDriftEntry(entry);

        expect(model.id, entry.id);
        expect(model.divisionId, entry.divisionId);
        expect(model.firstName, entry.firstName);
        expect(model.lastName, entry.lastName);
        expect(model.dateOfBirth, entry.dateOfBirth);
        expect(model.gender, entry.gender);
        expect(model.weightKg, entry.weightKg);
        expect(model.schoolOrDojangName, entry.schoolOrDojangName);
        expect(model.beltRank, entry.beltRank);
        expect(model.seedNumber, entry.seedNumber);
        expect(model.registrationNumber, entry.registrationNumber);
        expect(model.isBye, entry.isBye);
        expect(model.checkInStatus, entry.checkInStatus);
        expect(model.syncVersion, entry.syncVersion);
      });

      test('should handle null nullable fields from Drift', () {
        final entry = ParticipantEntry(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Doe',
          dateOfBirth: null,
          gender: null,
          weightKg: null,
          schoolOrDojangName: null,
          beltRank: null,
          seedNumber: null,
          registrationNumber: null,
          isBye: false,
          checkInStatus: 'pending',
          checkInAtTimestamp: null,
          photoUrl: null,
          notes: null,
          syncVersion: 1,
          isDeleted: false,
          deletedAtTimestamp: null,
          isDemoData: false,
          createdAtTimestamp: testDateTime,
          updatedAtTimestamp: testDateTime,
        );

        final model = ParticipantModel.fromDriftEntry(entry);

        expect(model.gender, isNull);
        expect(model.dateOfBirth, isNull);
        expect(model.weightKg, isNull);
        expect(model.schoolOrDojangName, isNull);
      });
    });

    group('convertToEntity', () {
      test('should convert model to entity', () {
        final model = ParticipantModel(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Doe',
          dateOfBirth: DateTime(2010, 5, 15),
          gender: 'male',
          weightKg: 65.5,
          schoolOrDojangName: 'Test Dojang',
          beltRank: 'black 1dan',
          seedNumber: 1,
          registrationNumber: 'REG-001',
          isBye: false,
          checkInStatus: 'checked_in',
          checkInAtTimestamp: testDateTime,
          photoUrl: 'https://example.com/photo.jpg',
          notes: 'Test notes',
          syncVersion: 1,
          isDeleted: false,
          deletedAtTimestamp: null,
          isDemoData: false,
          createdAtTimestamp: testDateTime,
          updatedAtTimestamp: testDateTime,
        );

        final entity = model.convertToEntity();

        expect(entity.id, model.id);
        expect(entity.divisionId, model.divisionId);
        expect(entity.firstName, model.firstName);
        expect(entity.lastName, model.lastName);
        expect(entity.gender, Gender.male);
        expect(entity.weightKg, model.weightKg);
        expect(entity.schoolOrDojangName, model.schoolOrDojangName);
        expect(entity.checkInStatus, ParticipantStatus.checkedIn);
      });

      test('should handle null gender correctly', () {
        final model = ParticipantModel(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Doe',
          gender: null,
          checkInStatus: 'pending',
          syncVersion: 1,
          isDeleted: false,
          isDemoData: false,
          createdAtTimestamp: testDateTime,
          updatedAtTimestamp: testDateTime,
        );

        final entity = model.convertToEntity();

        expect(entity.gender, isNull);
      });

      test('should parse checkInStatus correctly', () {
        final model = ParticipantModel(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Doe',
          checkInStatus: 'no_show',
          syncVersion: 1,
          isDeleted: false,
          isDemoData: false,
          createdAtTimestamp: testDateTime,
          updatedAtTimestamp: testDateTime,
        );

        final entity = model.convertToEntity();

        expect(entity.checkInStatus, ParticipantStatus.noShow);
      });
    });

    group('convertFromEntity', () {
      test('should convert entity to model', () {
        final entity = ParticipantEntity(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Doe',
          dateOfBirth: DateTime(2010, 5, 15),
          gender: Gender.female,
          weightKg: 65.5,
          schoolOrDojangName: 'Test Dojang',
          beltRank: 'black 1dan',
          seedNumber: 1,
          registrationNumber: 'REG-001',
          isBye: false,
          checkInStatus: ParticipantStatus.withdrawn,
          photoUrl: 'https://example.com/photo.jpg',
          notes: 'Test notes',
          syncVersion: 2,
          isDeleted: false,
          isDemoData: false,
          createdAtTimestamp: testDateTime,
          updatedAtTimestamp: testDateTime,
        );

        final model = ParticipantModel.convertFromEntity(entity);

        expect(model.id, entity.id);
        expect(model.divisionId, entity.divisionId);
        expect(model.firstName, entity.firstName);
        expect(model.lastName, entity.lastName);
        expect(model.gender, 'female');
        expect(model.weightKg, entity.weightKg);
        expect(model.checkInStatus, 'withdrawn');
      });
    });

    group('toDriftCompanion', () {
      test('should create valid Drift companion', () {
        final model = ParticipantModel(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Doe',
          dateOfBirth: DateTime(2010, 5, 15),
          gender: 'male',
          weightKg: 65.5,
          schoolOrDojangName: 'Test Dojang',
          beltRank: 'black 1dan',
          seedNumber: 1,
          registrationNumber: 'REG-001',
          isBye: false,
          checkInStatus: 'pending',
          checkInAtTimestamp: null,
          photoUrl: null,
          notes: null,
          syncVersion: 1,
          isDeleted: false,
          deletedAtTimestamp: null,
          isDemoData: false,
          createdAtTimestamp: testDateTime,
          updatedAtTimestamp: testDateTime,
        );

        final companion = model.toDriftCompanion();

        expect(companion.id.value, model.id);
        expect(companion.divisionId.value, model.divisionId);
        expect(companion.firstName.value, model.firstName);
        expect(companion.lastName.value, model.lastName);
        expect(companion.gender.value, model.gender);
        expect(companion.weightKg.value, model.weightKg);
      });

      test('should handle null optional fields in companion', () {
        final model = ParticipantModel(
          id: 'test-id',
          divisionId: 'division-1',
          firstName: 'John',
          lastName: 'Doe',
          checkInStatus: 'pending',
          syncVersion: 1,
          isDeleted: false,
          isDemoData: false,
          createdAtTimestamp: testDateTime,
          updatedAtTimestamp: testDateTime,
        );

        final companion = model.toDriftCompanion();

        expect(companion.gender.value, isNull);
        expect(companion.dateOfBirth.value, isNull);
        expect(companion.weightKg.value, isNull);
      });
    });
  });
}
