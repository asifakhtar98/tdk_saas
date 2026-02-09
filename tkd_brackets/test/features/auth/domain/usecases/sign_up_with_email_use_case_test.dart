import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_up_with_email_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_up_with_email_use_case.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late SignUpWithEmailUseCase useCase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = SignUpWithEmailUseCase(mockAuthRepository);
  });

  group('SignUpWithEmailUseCase', () {
    const validEmail = 'test@example.com';
    const invalidEmail = 'invalid-email';
    const emptyEmail = '';

    group('email validation', () {
      test('returns InvalidEmailFailure for empty email', () async {
        // Act
        final result = await useCase(
          const SignUpWithEmailParams(email: emptyEmail),
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
          const SignUpWithEmailParams(email: invalidEmail),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InvalidEmailFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockAuthRepository);
      });

      test('returns InvalidEmailFailure for email without domain', () async {
        // Act
        final result = await useCase(
          const SignUpWithEmailParams(email: 'user@'),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InvalidEmailFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('trims and lowercases email before validation', () async {
        // Arrange
        when(
          () => mockAuthRepository.sendSignUpMagicLink(
            email: any(named: 'email'),
          ),
        ).thenAnswer((_) async => const Right(unit));

        // Act
        await useCase(
          const SignUpWithEmailParams(email: '  TEST@EXAMPLE.COM  '),
        );

        // Assert
        verify(
          () => mockAuthRepository.sendSignUpMagicLink(
            email: 'test@example.com',
          ),
        ).called(1);
      });
    });

    group('successful magic link send', () {
      test('returns Right(unit) on successful magic link send', () async {
        // Arrange
        when(
          () => mockAuthRepository.sendSignUpMagicLink(
            email: any(named: 'email'),
          ),
        ).thenAnswer((_) async => const Right(unit));

        // Act
        final result = await useCase(
          const SignUpWithEmailParams(email: validEmail),
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (value) => expect(value, unit),
        );
        verify(
          () => mockAuthRepository.sendSignUpMagicLink(
            email: validEmail,
          ),
        ).called(1);
      });
    });

    group('error handling', () {
      test('returns RateLimitExceededFailure from repository', () async {
        // Arrange
        when(
          () => mockAuthRepository.sendSignUpMagicLink(
            email: any(named: 'email'),
          ),
        ).thenAnswer(
          (_) async => const Left(RateLimitExceededFailure()),
        );

        // Act
        final result = await useCase(
          const SignUpWithEmailParams(email: validEmail),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<RateLimitExceededFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns MagicLinkSendFailure from repository', () async {
        // Arrange
        when(
          () => mockAuthRepository.sendSignUpMagicLink(
            email: any(named: 'email'),
          ),
        ).thenAnswer(
          (_) async => const Left(MagicLinkSendFailure()),
        );

        // Act
        final result = await useCase(
          const SignUpWithEmailParams(email: validEmail),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<MagicLinkSendFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns ServerConnectionFailure from repository', () async {
        // Arrange
        when(
          () => mockAuthRepository.sendSignUpMagicLink(
            email: any(named: 'email'),
          ),
        ).thenAnswer(
          (_) async => const Left(ServerConnectionFailure()),
        );

        // Act
        final result = await useCase(
          const SignUpWithEmailParams(email: validEmail),
        );

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
