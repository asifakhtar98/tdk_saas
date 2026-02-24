// Test file for UserRepositoryImplementation - tests offline-first logic.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/auth/data/datasources/user_local_datasource.dart';
import 'package:tkd_brackets/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:tkd_brackets/features/auth/data/models/user_model.dart';
import 'package:tkd_brackets/features/auth/data/repositories/user_repository_implementation.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

class MockUserLocalDatasource extends Mock implements UserLocalDatasource {}

class MockUserRemoteDatasource extends Mock implements UserRemoteDatasource {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class FakeUserModel extends Fake implements UserModel {}

void main() {
  late UserRepositoryImplementation repository;
  late MockUserLocalDatasource mockLocalDatasource;
  late MockUserRemoteDatasource mockRemoteDatasource;
  late MockConnectivityService mockConnectivityService;

  final testModel = UserModel(
    id: 'test-id',
    email: 'test@example.com',
    displayName: 'Test User',
    organizationId: 'org-1',
    role: 'viewer',
    isActive: true,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
    syncVersion: 1,
    isDeleted: false,
    isDemoData: false,
  );

  setUpAll(() {
    registerFallbackValue(FakeUserModel());
  });

  setUp(() {
    mockLocalDatasource = MockUserLocalDatasource();
    mockRemoteDatasource = MockUserRemoteDatasource();
    mockConnectivityService = MockConnectivityService();
    repository = UserRepositoryImplementation(
      mockLocalDatasource,
      mockRemoteDatasource,
      mockConnectivityService,
    );
  });

  group('getUserById', () {
    test('returns user from local datasource when available', () async {
      when(
        () => mockLocalDatasource.getUserById('test-id'),
      ).thenAnswer((_) async => testModel);

      final result = await repository.getUserById('test-id');

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right'),
        (user) => expect(user.id, 'test-id'),
      );
      verifyNever(() => mockRemoteDatasource.getUserById(any()));
    });

    test('fetches from remote when local not found and online', () async {
      when(
        () => mockLocalDatasource.getUserById('test-id'),
      ).thenAnswer((_) async => null);
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => true);
      when(
        () => mockRemoteDatasource.getUserById('test-id'),
      ).thenAnswer((_) async => testModel);
      when(
        () => mockLocalDatasource.insertUser(any()),
      ).thenAnswer((_) async {});

      final result = await repository.getUserById('test-id');

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.insertUser(testModel)).called(1);
    });

    test('returns failure when user not found locally and offline', () async {
      when(
        () => mockLocalDatasource.getUserById('test-id'),
      ).thenAnswer((_) async => null);
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => false);

      final result = await repository.getUserById('test-id');

      expect(result.isLeft(), true);
    });

    test('returns failure when user not found in both sources', () async {
      when(
        () => mockLocalDatasource.getUserById('test-id'),
      ).thenAnswer((_) async => null);
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => true);
      when(
        () => mockRemoteDatasource.getUserById('test-id'),
      ).thenAnswer((_) async => null);

      final result = await repository.getUserById('test-id');

      expect(result.isLeft(), true);
    });
  });

  group('getUserByEmail', () {
    test('returns user from local datasource when available', () async {
      when(
        () => mockLocalDatasource.getUserByEmail('test@example.com'),
      ).thenAnswer((_) async => testModel);

      final result = await repository.getUserByEmail('test@example.com');

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right'),
        (user) => expect(user.email, 'test@example.com'),
      );
    });

    test('fetches from remote when local not found and online', () async {
      when(
        () => mockLocalDatasource.getUserByEmail('test@example.com'),
      ).thenAnswer((_) async => null);
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => true);
      when(
        () => mockRemoteDatasource.getUserByEmail('test@example.com'),
      ).thenAnswer((_) async => testModel);
      when(
        () => mockLocalDatasource.insertUser(any()),
      ).thenAnswer((_) async {});

      final result = await repository.getUserByEmail('test@example.com');

      expect(result.isRight(), true);
    });
  });

  group('createUser', () {
    test('saves locally first then syncs to remote', () async {
      when(
        () => mockLocalDatasource.insertUser(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => true);
      when(
        () => mockRemoteDatasource.insertUser(any()),
      ).thenAnswer((_) async => testModel);

      final entity = testModel.convertToEntity();
      final result = await repository.createUser(entity);

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.insertUser(any())).called(1);
      verify(() => mockRemoteDatasource.insertUser(any())).called(1);
    });

    test('succeeds with local only when offline', () async {
      when(
        () => mockLocalDatasource.insertUser(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => false);

      final entity = testModel.convertToEntity();
      final result = await repository.createUser(entity);

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.insertUser(any())).called(1);
      verifyNever(() => mockRemoteDatasource.insertUser(any()));
    });
  });

  group('updateUser', () {
    test('updates locally and syncs to remote when online', () async {
      when(
        () => mockLocalDatasource.getUserById('test-id'),
      ).thenAnswer((_) async => testModel);
      when(
        () => mockLocalDatasource.updateUser(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => true);
      when(
        () => mockRemoteDatasource.updateUser(any()),
      ).thenAnswer((_) async => testModel);

      final entity = testModel.convertToEntity();
      final result = await repository.updateUser(entity);

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.updateUser(any())).called(1);
      verify(() => mockRemoteDatasource.updateUser(any())).called(1);
    });

    test('increments sync version on update', () async {
      when(
        () => mockLocalDatasource.getUserById('test-id'),
      ).thenAnswer((_) async => testModel);
      when(
        () => mockLocalDatasource.updateUser(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => false);

      final entity = testModel.convertToEntity();
      await repository.updateUser(entity);

      final captured =
          verify(
                () => mockLocalDatasource.updateUser(captureAny()),
              ).captured.first
              as UserModel;
      expect(captured.syncVersion, 2);
    });
  });

  group('deleteUser', () {
    test('deletes locally and syncs to remote when online', () async {
      when(
        () => mockLocalDatasource.deleteUser('test-id'),
      ).thenAnswer((_) async {});
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => true);
      when(
        () => mockRemoteDatasource.deleteUser('test-id'),
      ).thenAnswer((_) async {});

      final result = await repository.deleteUser('test-id');

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.deleteUser('test-id')).called(1);
      verify(() => mockRemoteDatasource.deleteUser('test-id')).called(1);
    });

    test('succeeds with local only when offline', () async {
      when(
        () => mockLocalDatasource.deleteUser('test-id'),
      ).thenAnswer((_) async {});
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => false);

      final result = await repository.deleteUser('test-id');

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.deleteUser('test-id')).called(1);
      verifyNever(() => mockRemoteDatasource.deleteUser(any()));
    });
  });

  group('getUsersForOrganization', () {
    test('returns users from local when offline', () async {
      when(
        () => mockLocalDatasource.getUsersForOrganization('org-1'),
      ).thenAnswer((_) async => [testModel]);
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => false);

      final result = await repository.getUsersForOrganization('org-1');

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right'),
        (users) => expect(users.length, 1),
      );
    });

    test('syncs from remote when online', () async {
      when(
        () => mockLocalDatasource.getUsersForOrganization('org-1'),
      ).thenAnswer((_) async => []);
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => true);
      when(
        () => mockRemoteDatasource.getUsersForOrganization('org-1'),
      ).thenAnswer((_) async => [testModel]);
      when(
        () => mockLocalDatasource.getUserById(any()),
      ).thenAnswer((_) async => null);
      when(
        () => mockLocalDatasource.insertUser(any()),
      ).thenAnswer((_) async {});

      final result = await repository.getUsersForOrganization('org-1');

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right'),
        (users) => expect(users.length, 1),
      );
    });
  });

  group('getCurrentUser', () {
    const mockUser = User(
      id: 'test-id',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2024-01-01T00:00:00.000Z',
    );

    test(
      'returns user from local when auth user exists and local has data',
      () async {
        when(() => mockRemoteDatasource.currentAuthUser).thenReturn(mockUser);
        when(
          () => mockLocalDatasource.getUserById('test-id'),
        ).thenAnswer((_) async => testModel);

        final result = await repository.getCurrentUser();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right'),
          (user) => expect(user.id, 'test-id'),
        );
      },
    );

    test('returns failure when no auth user', () async {
      when(() => mockRemoteDatasource.currentAuthUser).thenReturn(null);

      final result = await repository.getCurrentUser();

      expect(result.isLeft(), true);
    });

    test('fetches from remote when local returns null', () async {
      when(() => mockRemoteDatasource.currentAuthUser).thenReturn(mockUser);
      when(
        () => mockLocalDatasource.getUserById('test-id'),
      ).thenAnswer((_) async => null);
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => true);
      when(
        () => mockRemoteDatasource.getUserById('test-id'),
      ).thenAnswer((_) async => testModel);
      when(
        () => mockLocalDatasource.insertUser(any()),
      ).thenAnswer((_) async {});

      final result = await repository.getCurrentUser();

      expect(result.isRight(), true);
    });
  });

  group('watchCurrentUser', () {
    test('emits Right with user entity when session has user', () async {
      const mockUser = User(
        id: 'test-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2024-01-01T00:00:00.000Z',
      );
      final mockSession = Session(
        accessToken: 'token',
        tokenType: 'bearer',
        user: mockUser,
      );
      final authState = AuthState(AuthChangeEvent.signedIn, mockSession);

      when(
        () => mockRemoteDatasource.authStateChanges,
      ).thenAnswer((_) => Stream.value(authState));
      when(
        () => mockLocalDatasource.getUserById('test-id'),
      ).thenAnswer((_) async => testModel);

      final stream = repository.watchCurrentUser();

      await expectLater(
        stream.take(1),
        emits(isA<Right<dynamic, UserEntity>>()),
      );
    });

    test('emits Left with failure when no session', () async {
      const authState = AuthState(AuthChangeEvent.signedOut, null);

      when(
        () => mockRemoteDatasource.authStateChanges,
      ).thenAnswer((_) => Stream.value(authState));

      final stream = repository.watchCurrentUser();

      await expectLater(
        stream.take(1),
        emits(isA<Left<dynamic, UserEntity>>()),
      );
    });
  });
}
