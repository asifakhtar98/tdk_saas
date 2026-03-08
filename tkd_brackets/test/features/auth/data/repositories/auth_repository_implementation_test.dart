import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:tkd_brackets/features/auth/data/datasources/user_local_datasource.dart';
import 'package:tkd_brackets/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:tkd_brackets/features/auth/data/models/user_model.dart';
import 'package:tkd_brackets/features/auth/data/repositories/auth_repository_implementation.dart';

class MockSupabaseAuthDatasource extends Mock
    implements SupabaseAuthDatasource {}

class MockUserRemoteDatasource extends Mock implements UserRemoteDatasource {}

class MockUserLocalDatasource extends Mock implements UserLocalDatasource {}

class MockUser extends Mock implements User {}

class MockAuthResponse extends Mock implements AuthResponse {}

void main() {
  late MockSupabaseAuthDatasource mockAuthDatasource;
  late MockUserRemoteDatasource mockUserRemoteDatasource;
  late MockUserLocalDatasource mockUserLocalDatasource;
  late AuthRepositoryImplementation repository;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(OtpType.magiclink);
    registerFallbackValue(
      UserModel(
        id: 'fallback-id',
        email: 'fallback@example.com',
        displayName: 'Fallback',
        organizationId: '',
        role: 'owner',
        isActive: true,
        createdAtTimestamp: DateTime.now(),
        updatedAtTimestamp: DateTime.now(),
        syncVersion: 1,
        isDeleted: false,
        isDemoData: false,
      ),
    );
  });

  setUp(() {
    mockAuthDatasource = MockSupabaseAuthDatasource();
    mockUserRemoteDatasource = MockUserRemoteDatasource();
    mockUserLocalDatasource = MockUserLocalDatasource();
    repository = AuthRepositoryImplementation(
      mockAuthDatasource,
      mockUserRemoteDatasource,
      mockUserLocalDatasource,
    );
  });

  final testUserModel = UserModel(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    organizationId: 'org-123',
    role: 'owner',
    isActive: true,
    createdAtTimestamp: DateTime.now(),
    updatedAtTimestamp: DateTime.now(),
    syncVersion: 1,
    isDeleted: false,
    isDemoData: false,
    lastSignInAtTimestamp: DateTime.now(),
  );

  group('AuthRepositoryImplementation', () {
    group('signUpWithEmailPassword', () {
      const testEmail = 'test@example.com';
      const testPassword = 'password123';

      test('returns UserEntity and creates new profile on success', () async {
        // Arrange
        final mockUser = MockUser();
        final mockAuthResponse = MockAuthResponse();
        when(() => mockUser.id).thenReturn('new-user-123');
        when(() => mockUser.email).thenReturn(testEmail);
        when(() => mockAuthResponse.user).thenReturn(mockUser);

        when(
          () => mockAuthDatasource.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => mockAuthResponse);

        // User doesn't exist in database
        when(
          () => mockUserRemoteDatasource.getUserById(any()),
        ).thenAnswer((_) async => null);

        // Create user
        when(
          () => mockUserRemoteDatasource.insertUser(any()),
        ).thenAnswer((_) async => testUserModel.copyWith(id: 'new-user-123'));

        // Local cache doesn't have user
        when(
          () => mockUserLocalDatasource.getUserById(any()),
        ).thenAnswer((_) async => null);

        when(
          () => mockUserLocalDatasource.insertUser(any()),
        ).thenAnswer((_) async {});

        // Act
        final result = await repository.signUpWithEmailPassword(
            email: testEmail, password: testPassword);

        // Assert
        expect(result.isRight(), isTrue);
        verify(
          () => mockAuthDatasource.signUp(
            email: testEmail,
            password: testPassword,
          ),
        ).called(1);
        verify(() => mockUserRemoteDatasource.insertUser(any())).called(1);
        verify(() => mockUserLocalDatasource.insertUser(any())).called(1);
      });

      test('returns AuthFailure when signUp fails', () async {
        // Arrange
        when(
          () => mockAuthDatasource.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthException('Signup failed'));

        // Act
        final result = await repository.signUpWithEmailPassword(
            email: testEmail, password: testPassword);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('signInWithEmailPassword', () {
      const testEmail = 'test@example.com';
      const testPassword = 'password123';

      test('returns UserEntity with updated lastSignInAt on success', () async {
        // Arrange
        final mockUser = MockUser();
        final mockAuthResponse = MockAuthResponse();
        when(() => mockUser.id).thenReturn('user-123');
        when(() => mockUser.email).thenReturn(testEmail);
        when(() => mockAuthResponse.user).thenReturn(mockUser);

        when(
          () => mockAuthDatasource.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => mockAuthResponse);

        when(
          () => mockUserRemoteDatasource.getUserById(any()),
        ).thenAnswer((_) async => testUserModel);

        when(
          () => mockUserRemoteDatasource.updateUser(any()),
        ).thenAnswer((_) async => testUserModel);

        when(
          () => mockUserLocalDatasource.getUserById(any()),
        ).thenAnswer((_) async => testUserModel);

        when(
          () => mockUserLocalDatasource.updateUser(any()),
        ).thenAnswer((_) async {});

        // Act
        final result = await repository.signInWithEmailPassword(
            email: testEmail, password: testPassword);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (user) {
          expect(user.id, equals('user-123'));
          expect(user.email, equals(testEmail));
        });
        verify(() => mockUserRemoteDatasource.updateUser(any())).called(1);
        verify(() => mockUserLocalDatasource.updateUser(any())).called(1);
      });

      test('returns AuthFailure on AuthException', () async {
        // Arrange
        when(
          () => mockAuthDatasource.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthException('User not found'));

        // Act
        final result = await repository.signInWithEmailPassword(
            email: testEmail, password: testPassword);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('signOut', () {
      test('returns Right(unit) on successful sign out', () async {
        // Arrange
        when(() => mockAuthDatasource.signOut()).thenAnswer((_) async {});

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result, const Right<Failure, Unit>(unit));
        verify(() => mockAuthDatasource.signOut()).called(1);
      });

      test('returns failure on AuthException', () async {
        // Arrange
        when(
          () => mockAuthDatasource.signOut(),
        ).thenThrow(const AuthException('Sign out failed'));

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<SignOutFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns ServerConnectionFailure for network error', () async {
        // Arrange
        when(
          () => mockAuthDatasource.signOut(),
        ).thenThrow(Exception('Network error'));

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ServerConnectionFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('getCurrentAuthenticatedUser', () {
      test('returns UserEntity from local cache when available', () async {
        // Arrange
        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('user-123');
        when(() => mockAuthDatasource.currentUser).thenReturn(mockUser);
        when(
          () => mockUserLocalDatasource.getUserById(any()),
        ).thenAnswer((_) async => testUserModel);

        // Act
        final result = await repository.getCurrentAuthenticatedUser();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (user) => expect(user.id, equals('user-123')),
        );
        verifyNever(() => mockUserRemoteDatasource.getUserById(any()));
      });

      test('fetches from remote and caches when not in local cache', () async {
        // Arrange
        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('user-123');
        when(() => mockAuthDatasource.currentUser).thenReturn(mockUser);
        when(
          () => mockUserLocalDatasource.getUserById(any()),
        ).thenAnswer((_) async => null);
        when(
          () => mockUserRemoteDatasource.getUserById(any()),
        ).thenAnswer((_) async => testUserModel);
        when(
          () => mockUserLocalDatasource.insertUser(any()),
        ).thenAnswer((_) async {});

        // Act
        final result = await repository.getCurrentAuthenticatedUser();

        // Assert
        expect(result.isRight(), isTrue);
        verify(
          () => mockUserRemoteDatasource.getUserById('user-123'),
        ).called(1);
        verify(() => mockUserLocalDatasource.insertUser(any())).called(1);
      });

      test(
        'returns UserNotFoundFailure when no authenticated session',
        () async {
          // Arrange
          when(() => mockAuthDatasource.currentUser).thenReturn(null);

          // Act
          final result = await repository.getCurrentAuthenticatedUser();

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<UserNotFoundFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );

      test(
        'returns UserNotFoundFailure when user profile not in database',
        () async {
          // Arrange
          final mockUser = MockUser();
          when(() => mockUser.id).thenReturn('user-123');
          when(() => mockAuthDatasource.currentUser).thenReturn(mockUser);
          when(
            () => mockUserLocalDatasource.getUserById(any()),
          ).thenAnswer((_) async => null);
          when(
            () => mockUserRemoteDatasource.getUserById(any()),
          ).thenAnswer((_) async => null);

          // Act
          final result = await repository.getCurrentAuthenticatedUser();

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<UserNotFoundFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );
    });

    group('authStateChanges', () {
      test('emits null when user signs out', () async {
        // Arrange
        final controller = StreamController<AuthState>();
        when(
          () => mockAuthDatasource.onAuthStateChange,
        ).thenAnswer((_) => controller.stream);

        // Act
        final stream = repository.authStateChanges;

        // Add a signed-out state (no session)
        controller.add(const AuthState(AuthChangeEvent.signedOut, null));

        // Assert
        expect(stream, emits(isA<Right<Failure, void>>()));

        // Cleanup
        await controller.close();
      });
    });
  });
}
