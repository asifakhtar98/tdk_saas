import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/auth/data/datasources/user_local_datasource.dart';
import 'package:tkd_brackets/features/auth/data/models/user_model.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

class FakeUsersCompanion extends Fake implements UsersCompanion {}

void main() {
  late UserLocalDatasourceImplementation datasource;
  late MockAppDatabase mockDatabase;

  setUpAll(() {
    registerFallbackValue(FakeUsersCompanion());
  });

  final testUserEntry = UserEntry(
    id: 'test-id',
    email: 'test@example.com',
    displayName: 'Test User',
    organizationId: 'org-1',
    role: 'viewer',
    avatarUrl: null,
    isActive: true,
    lastSignInAtTimestamp: null,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
    syncVersion: 1,
    isDeleted: false,
    deletedAtTimestamp: null,
    isDemoData: false,
  );

  setUp(() {
    mockDatabase = MockAppDatabase();
    datasource = UserLocalDatasourceImplementation(mockDatabase);
  });

  group('UserLocalDatasource', () {
    group('getUserById', () {
      test('returns UserModel when user exists', () async {
        when(() => mockDatabase.getUserById('test-id'))
            .thenAnswer((_) async => testUserEntry);

        final result = await datasource.getUserById('test-id');

        expect(result, isNotNull);
        expect(result!.id, 'test-id');
        expect(result.email, 'test@example.com');
        verify(() => mockDatabase.getUserById('test-id')).called(1);
      });

      test('returns null when user does not exist', () async {
        when(() => mockDatabase.getUserById('nonexistent'))
            .thenAnswer((_) async => null);

        final result = await datasource.getUserById('nonexistent');

        expect(result, isNull);
      });
    });

    group('getUserByEmail', () {
      test('returns UserModel when user exists', () async {
        when(() => mockDatabase.getUserByEmail('test@example.com'))
            .thenAnswer((_) async => testUserEntry);

        final result = await datasource.getUserByEmail('test@example.com');

        expect(result, isNotNull);
        expect(result!.email, 'test@example.com');
      });

      test('returns null when user does not exist', () async {
        when(() => mockDatabase.getUserByEmail('nonexistent@example.com'))
            .thenAnswer((_) async => null);

        final result =
            await datasource.getUserByEmail('nonexistent@example.com');

        expect(result, isNull);
      });
    });

    group('getUsersForOrganization', () {
      test('returns list of UserModels', () async {
        when(() => mockDatabase.getUsersForOrganization('org-1'))
            .thenAnswer((_) async => [testUserEntry]);

        final result = await datasource.getUsersForOrganization('org-1');

        expect(result.length, 1);
        expect(result.first.organizationId, 'org-1');
      });

      test('returns empty list when no users exist', () async {
        when(() => mockDatabase.getUsersForOrganization('empty-org'))
            .thenAnswer((_) async => []);

        final result = await datasource.getUsersForOrganization('empty-org');

        expect(result, isEmpty);
      });
    });

    group('insertUser', () {
      test('calls database insertUser with companion', () async {
        final model = UserModel.fromDriftEntry(testUserEntry);
        when(() => mockDatabase.insertUser(any())).thenAnswer((_) async => 1);

        await datasource.insertUser(model);

        verify(() => mockDatabase.insertUser(any())).called(1);
      });
    });

    group('updateUser', () {
      test('calls database updateUser with id and companion', () async {
        final model = UserModel.fromDriftEntry(testUserEntry);
        when(() => mockDatabase.updateUser(any(), any()))
            .thenAnswer((_) async => true);

        await datasource.updateUser(model);

        verify(() => mockDatabase.updateUser('test-id', any())).called(1);
      });
    });

    group('deleteUser', () {
      test('calls database softDeleteUser', () async {
        when(() => mockDatabase.softDeleteUser('test-id'))
            .thenAnswer((_) async => true);

        await datasource.deleteUser('test-id');

        verify(() => mockDatabase.softDeleteUser('test-id')).called(1);
      });
    });
  });
}
