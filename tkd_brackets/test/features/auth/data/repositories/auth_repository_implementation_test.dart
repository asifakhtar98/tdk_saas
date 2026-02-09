import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:tkd_brackets/features/auth/data/repositories/auth_repository_implementation.dart';

class MockSupabaseAuthDatasource extends Mock
    implements SupabaseAuthDatasource {}

void main() {
  late MockSupabaseAuthDatasource mockDatasource;
  late AuthRepositoryImplementation repository;

  setUp(() {
    mockDatasource = MockSupabaseAuthDatasource();
    repository = AuthRepositoryImplementation(mockDatasource);
  });

  group('AuthRepositoryImplementation', () {
    group('sendSignUpMagicLink', () {
      const testEmail = 'test@example.com';

      test('returns Right(unit) on successful magic link send', () async {
        // Arrange
        when(
          () => mockDatasource.sendMagicLink(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
          ),
        ).thenAnswer((_) async {});

        // Act
        final result = await repository.sendSignUpMagicLink(email: testEmail);

        // Assert
        expect(result, const Right<Failure, Unit>(unit));
        verify(
          () => mockDatasource.sendMagicLink(
            email: testEmail,
            shouldCreateUser: true,
          ),
        ).called(1);
      });

      test('returns RateLimitExceededFailure for rate limit error', () async {
        // Arrange
        when(
          () => mockDatasource.sendMagicLink(
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
            () => mockDatasource.sendMagicLink(
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
          () => mockDatasource.sendMagicLink(
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
          () => mockDatasource.sendMagicLink(
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
          () => mockDatasource.sendMagicLink(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
          ),
        ).thenAnswer((_) async {});

        // Act
        final result = await repository.sendSignInMagicLink(email: testEmail);

        // Assert
        expect(result, const Right<Failure, Unit>(unit));
        verify(
          () => mockDatasource.sendMagicLink(
            email: testEmail,
            shouldCreateUser: false,
          ),
        ).called(1);
      });

      test('returns failure on AuthException', () async {
        // Arrange
        when(
          () => mockDatasource.sendMagicLink(
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

    group('signOut', () {
      test('returns Right(unit) on successful sign out', () async {
        // Arrange
        when(() => mockDatasource.signOut()).thenAnswer((_) async {});

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result, const Right<Failure, Unit>(unit));
        verify(() => mockDatasource.signOut()).called(1);
      });

      test('returns failure on AuthException', () async {
        // Arrange
        when(
          () => mockDatasource.signOut(),
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
          () => mockDatasource.signOut(),
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
  });
}
