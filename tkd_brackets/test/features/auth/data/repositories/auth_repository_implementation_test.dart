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
    group('sendSignUpMagicLink', () {
      const testEmail = 'test@example.com';

      test('returns Right(unit) on successful magic link send', () async {
        // Arrange
        when(
          () => mockAuthDatasource.sendMagicLink(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
          ),
        ).thenAnswer((_) async {});

        // Act
        final result = await repository.sendSignUpMagicLink(email: testEmail);

        // Assert
        expect(result, const Right<Failure, Unit>(unit));
        verify(
          () => mockAuthDatasource.sendMagicLink(
            email: testEmail,
            shouldCreateUser: true,
          ),
        ).called(1);
      });

      test('returns RateLimitExceededFailure for rate limit error', () async {
        // Arrange
        when(
          () => mockAuthDatasource.sendMagicLink(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
          ),
        ).thenThrow(const AuthException('rate limit exceeded'));

        // Act
        final result = await repository.sendSignUpMagicLink(email: testEmail);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<RateLimitExceededFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test(
        'returns RateLimitExceededFailure for too many requests error',
        () async {
          // Arrange
          when(
            () => mockAuthDatasource.sendMagicLink(
              email: any(named: 'email'),
              shouldCreateUser: any(named: 'shouldCreateUser'),
            ),
          ).thenThrow(const AuthException('too many requests'));

          // Act
          final result = await repository.sendSignUpMagicLink(email: testEmail);

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<RateLimitExceededFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );

      test('returns MagicLinkSendFailure for other AuthException', () async {
        // Arrange
        when(
          () => mockAuthDatasource.sendMagicLink(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
          ),
        ).thenThrow(const AuthException('Unknown auth error'));

        // Act
        final result = await repository.sendSignUpMagicLink(email: testEmail);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<MagicLinkSendFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns ServerConnectionFailure for network error', () async {
        // Arrange
        when(
          () => mockAuthDatasource.sendMagicLink(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
          ),
        ).thenThrow(Exception('No internet connection'));

        // Act
        final result = await repository.sendSignUpMagicLink(email: testEmail);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ServerConnectionFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('sendSignInMagicLink', () {
      const testEmail = 'existing@example.com';

      test('returns Right(unit) on successful magic link send', () async {
        // Arrange
        when(
          () => mockAuthDatasource.sendMagicLink(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
          ),
        ).thenAnswer((_) async {});

        // Act
        final result = await repository.sendSignInMagicLink(email: testEmail);

        // Assert
        expect(result, const Right<Failure, Unit>(unit));
        verify(
          () => mockAuthDatasource.sendMagicLink(
            email: testEmail,
            shouldCreateUser: false,
          ),
        ).called(1);
      });

      test('returns failure on AuthException', () async {
        // Arrange
        when(
          () => mockAuthDatasource.sendMagicLink(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
          ),
        ).thenThrow(const AuthException('User not found'));

        // Act
        final result = await repository.sendSignInMagicLink(email: testEmail);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<MagicLinkSendFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('verifyMagicLinkOtp', () {
      const testEmail = 'test@example.com';
      const testToken = '123456';

      test(
          'returns UserEntity for existing user with updated lastSignInAt',
          () async {
        // Arrange
        final mockUser = MockUser();
        final mockAuthResponse = MockAuthResponse();
        when(() => mockUser.id).thenReturn('user-123');
        when(() => mockUser.email).thenReturn(testEmail);
        when(() => mockUser.userMetadata).thenReturn(null);
        when(() => mockAuthResponse.user).thenReturn(mockUser);

        when(
          () => mockAuthDatasource.verifyOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
            type: any(named: 'type'),
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
        final result = await repository.verifyMagicLinkOtp(
          email: testEmail,
          token: testToken,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (user) {
            expect(user.id, equals('user-123'));
            expect(user.email, equals(testEmail));
          },
        );
        verify(() => mockUserRemoteDatasource.updateUser(any())).called(1);
        verify(() => mockUserLocalDatasource.updateUser(any())).called(1);
      });

      test('creates new user profile for first-time sign-in', () async {
        // Arrange
        final mockUser = MockUser();
        final mockAuthResponse = MockAuthResponse();
        when(() => mockUser.id).thenReturn('new-user-123');
        when(() => mockUser.email).thenReturn(testEmail);
        when(() => mockUser.userMetadata)
            .thenReturn({'display_name': 'New User'});
        when(() => mockAuthResponse.user).thenReturn(mockUser);

        when(
          () => mockAuthDatasource.verifyOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
            type: any(named: 'type'),
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
        final result = await repository.verifyMagicLinkOtp(
          email: testEmail,
          token: testToken,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockUserRemoteDatasource.insertUser(any())).called(1);
        verify(() => mockUserLocalDatasource.insertUser(any())).called(1);
        verifyNever(() => mockUserRemoteDatasource.updateUser(any()));
      });

      test('returns OtpVerificationFailure when AuthResponse.user is null',
          () async {
        // Arrange
        final mockAuthResponse = MockAuthResponse();
        when(() => mockAuthResponse.user).thenReturn(null);

        when(
          () => mockAuthDatasource.verifyOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
            type: any(named: 'type'),
          ),
        ).thenAnswer((_) async => mockAuthResponse);

        // Act
        final result = await repository.verifyMagicLinkOtp(
          email: testEmail,
          token: testToken,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<OtpVerificationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns ExpiredTokenFailure for expired token error', () async {
        // Arrange
        when(
          () => mockAuthDatasource.verifyOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
            type: any(named: 'type'),
          ),
        ).thenThrow(const AuthException('Token expired'));

        // Act
        final result = await repository.verifyMagicLinkOtp(
          email: testEmail,
          token: testToken,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ExpiredTokenFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns InvalidTokenFailure for invalid token error', () async {
        // Arrange
        when(
          () => mockAuthDatasource.verifyOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
            type: any(named: 'type'),
          ),
        ).thenThrow(const AuthException('Token invalid'));

        // Act
        final result = await repository.verifyMagicLinkOtp(
          email: testEmail,
          token: testToken,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InvalidTokenFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns RateLimitExceededFailure for rate limit error', () async {
        // Arrange
        when(
          () => mockAuthDatasource.verifyOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
            type: any(named: 'type'),
          ),
        ).thenThrow(const AuthException('rate limit exceeded'));

        // Act
        final result = await repository.verifyMagicLinkOtp(
          email: testEmail,
          token: testToken,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<RateLimitExceededFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns ServerConnectionFailure for general exceptions', () async {
        // Arrange
        final mockUser = MockUser();
        final mockAuthResponse = MockAuthResponse();
        when(() => mockUser.id).thenReturn('user-123');
        when(() => mockAuthResponse.user).thenReturn(mockUser);

        when(
          () => mockAuthDatasource.verifyOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
            type: any(named: 'type'),
          ),
        ).thenAnswer((_) async => mockAuthResponse);

        when(
          () => mockUserRemoteDatasource.getUserById(any()),
        ).thenThrow(Exception('Database error'));

        // Act
        final result = await repository.verifyMagicLinkOtp(
          email: testEmail,
          token: testToken,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ServerConnectionFailure>()),
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
          (failure) => expect(failure, isA<MagicLinkSendFailure>()),
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

      test('returns UserNotFoundFailure when no authenticated session',
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
      });

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
      });
    });

    group('authStateChanges', () {
      test('emits null when user signs out', () async {
        // Arrange
        final controller = StreamController<AuthState>();
        when(() => mockAuthDatasource.onAuthStateChange)
            .thenAnswer((_) => controller.stream);

        // Act
        final stream = repository.authStateChanges;

        // Add a signed-out state (no session)
        controller.add(AuthState(AuthChangeEvent.signedOut, null));

        // Assert
        expect(
          stream,
          emits(isA<Right<Failure, void>>()),
        );

        // Cleanup
        await controller.close();
      });
    });
  });
}
