import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/verify_magic_link_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/verify_magic_link_use_case.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late VerifyMagicLinkUseCase useCase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = VerifyMagicLinkUseCase(mockAuthRepository);
  });

  final testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    organizationId: 'org-123',
    role: UserRole.owner,
    isActive: true,
    createdAt: DateTime.now(),
    lastSignInAt: DateTime.now(),
  );

  group('VerifyMagicLinkUseCase', () {
    const validEmail = 'test@example.com';
    const validToken = '123456';
    const invalidEmail = 'invalid-email';
    const emptyEmail = '';
    const emptyToken = '';

    group('validation', () {
      test('returns InvalidEmailFailure for empty email', () async {
        // Act
        final result = await useCase(
          const VerifyMagicLinkParams(email: emptyEmail, token: validToken),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InvalidEmailFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockAuthRepository);
      });

      test('returns InvalidEmailFailure for invalid email format', () async {
        // Act
        final result = await useCase(
          const VerifyMagicLinkParams(email: invalidEmail, token: validToken),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InvalidEmailFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockAuthRepository);
      });

      test('returns InvalidTokenFailure for empty token', () async {
        // Act
        final result = await useCase(
          const VerifyMagicLinkParams(email: validEmail, token: emptyToken),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InvalidTokenFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockAuthRepository);
      });

      test('returns InvalidTokenFailure for whitespace-only token', () async {
        // Act
        final result = await useCase(
          const VerifyMagicLinkParams(email: validEmail, token: '   '),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InvalidTokenFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockAuthRepository);
      });

      test('trims email and token before processing', () async {
        // Arrange
        when(
          () => mockAuthRepository.verifyMagicLinkOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        // Act
        await useCase(
          const VerifyMagicLinkParams(
            email: '  TEST@EXAMPLE.COM  ',
            token: '  123456  ',
          ),
        );

        // Assert
        verify(
          () => mockAuthRepository.verifyMagicLinkOtp(
            email: 'test@example.com',
            token: '123456',
          ),
        ).called(1);
      });
    });

    group('successful verification', () {
      test('returns Right(UserEntity) on successful verification', () async {
        // Arrange
        when(
          () => mockAuthRepository.verifyMagicLinkOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        // Act
        final result = await useCase(
          const VerifyMagicLinkParams(email: validEmail, token: validToken),
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (user) {
          expect(user.id, equals(testUser.id));
          expect(user.email, equals(testUser.email));
        });
      });
    });

    group('error handling', () {
      test('returns ExpiredTokenFailure for expired token', () async {
        // Arrange
        when(
          () => mockAuthRepository.verifyMagicLinkOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
          ),
        ).thenAnswer(
          (_) async => const Left(
            ExpiredTokenFailure(technicalDetails: 'Token expired'),
          ),
        );

        // Act
        final result = await useCase(
          const VerifyMagicLinkParams(email: validEmail, token: validToken),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ExpiredTokenFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns InvalidTokenFailure for invalid token', () async {
        // Arrange
        when(
          () => mockAuthRepository.verifyMagicLinkOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
          ),
        ).thenAnswer(
          (_) async => const Left(
            InvalidTokenFailure(technicalDetails: 'Invalid token'),
          ),
        );

        // Act
        final result = await useCase(
          const VerifyMagicLinkParams(email: validEmail, token: validToken),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InvalidTokenFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test(
        'returns OtpVerificationFailure for general verification error',
        () async {
          // Arrange
          when(
            () => mockAuthRepository.verifyMagicLinkOtp(
              email: any(named: 'email'),
              token: any(named: 'token'),
            ),
          ).thenAnswer(
            (_) async => const Left(
              OtpVerificationFailure(technicalDetails: 'Verification failed'),
            ),
          );

          // Act
          final result = await useCase(
            const VerifyMagicLinkParams(email: validEmail, token: validToken),
          );

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<OtpVerificationFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );
    });
  });
}
