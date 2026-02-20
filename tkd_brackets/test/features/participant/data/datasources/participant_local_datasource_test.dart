import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/participant/data/datasources/participant_local_datasource.dart';
import 'package:tkd_brackets/features/participant/data/models/participant_model.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late ParticipantLocalDatasourceImplementation datasource;
  late MockAppDatabase mockDatabase;

  final testDateTime = DateTime(2026, 1, 15, 10, 30);

  setUpAll(() {
    registerFallbackValue(const ParticipantsCompanion());
  });

  setUp(() {
    mockDatabase = MockAppDatabase();
    datasource = ParticipantLocalDatasourceImplementation(mockDatabase);
  });

  group('getParticipantsForDivision', () {
    test('should return empty list when database returns empty', () async {
      when(
        () => mockDatabase.getParticipantsForDivision('division-1'),
      ).thenAnswer((_) async => []);

      final result = await datasource.getParticipantsForDivision('division-1');

      expect(result, isEmpty);
      verify(
        () => mockDatabase.getParticipantsForDivision('division-1'),
      ).called(1);
    });

    test(
      'should return list of models when database returns entries',
      () async {
        final entries = [
          ParticipantEntry(
            id: 'id-1',
            divisionId: 'division-1',
            firstName: 'John',
            lastName: 'Doe',
            dateOfBirth: null,
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
          ),
        ];

        when(
          () => mockDatabase.getParticipantsForDivision('division-1'),
        ).thenAnswer((_) async => entries);

        final result = await datasource.getParticipantsForDivision(
          'division-1',
        );

        expect(result.length, 1);
        expect(result.first.id, 'id-1');
        expect(result.first.firstName, 'John');
        verify(
          () => mockDatabase.getParticipantsForDivision('division-1'),
        ).called(1);
      },
    );
  });

  group('getParticipantById', () {
    test('should return null when database returns null', () async {
      when(
        () => mockDatabase.getParticipantById('unknown-id'),
      ).thenAnswer((_) async => null);

      final result = await datasource.getParticipantById('unknown-id');

      expect(result, isNull);
      verify(() => mockDatabase.getParticipantById('unknown-id')).called(1);
    });

    test('should return model when database returns entry', () async {
      final entry = ParticipantEntry(
        id: 'id-1',
        divisionId: 'division-1',
        firstName: 'John',
        lastName: 'Doe',
        dateOfBirth: null,
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

      when(
        () => mockDatabase.getParticipantById('id-1'),
      ).thenAnswer((_) async => entry);

      final result = await datasource.getParticipantById('id-1');

      expect(result, isNotNull);
      expect(result!.id, 'id-1');
      expect(result.firstName, 'John');
      verify(() => mockDatabase.getParticipantById('id-1')).called(1);
    });
  });

  group('deleteParticipant', () {
    test('should delete participant successfully', () async {
      when(
        () => mockDatabase.softDeleteParticipant('id-1'),
      ).thenAnswer((_) async => true);

      await datasource.deleteParticipant('id-1');

      verify(() => mockDatabase.softDeleteParticipant('id-1')).called(1);
    });
  });

  group('insertParticipant', () {
    test('should insert participant successfully', () async {
      final model = ParticipantModel(
        id: 'id-1',
        divisionId: 'division-1',
        firstName: 'John',
        lastName: 'Doe',
        dateOfBirth: testDateTime,
        checkInStatus: 'pending',
        syncVersion: 1,
        isDeleted: false,
        isDemoData: false,
        createdAtTimestamp: testDateTime,
        updatedAtTimestamp: testDateTime,
      );

      when(
        () => mockDatabase.insertParticipant(any()),
      ).thenAnswer((_) async => 1);

      await datasource.insertParticipant(model);

      verify(() => mockDatabase.insertParticipant(any())).called(1);
    });
  });

  group('updateParticipant', () {
    test('should update participant successfully', () async {
      final model = ParticipantModel(
        id: 'id-1',
        divisionId: 'division-1',
        firstName: 'John',
        lastName: 'Doe',
        dateOfBirth: testDateTime,
        checkInStatus: 'pending',
        syncVersion: 1,
        isDeleted: false,
        isDemoData: false,
        createdAtTimestamp: testDateTime,
        updatedAtTimestamp: testDateTime,
      );

      when(
        () => mockDatabase.updateParticipant(model.id, any()),
      ).thenAnswer((_) async => true);

      await datasource.updateParticipant(model);

      verify(() => mockDatabase.updateParticipant(model.id, any())).called(1);
    });
  });
}
