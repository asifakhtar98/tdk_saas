import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_up_with_email_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_up_with_email_use_case.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockUserEntity extends Mock implements UserEntity {}

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
          const SignUpWithEmailParams(email: emptyEmail, password: 'password123'),
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
          const SignUpWithEmailParams(email: invalidEmail, password: 'password123'),
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
          const SignUpWithEmailParams(email: 'user@', password: 'password123'),
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
        final mockUser = MockUserEntity();
        when(
          () => mockAuthRepository.signUpWithEmailPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(mockUser));

        // Act
        await useCase(
          const SignUpWithEmailParams(email: '  TEST@EXAMPLE.COM  ', password: 'password123'),
        );

        // Assert
        verify(
          () =>
              mockAuthRepository.signUpWithEmailPassword(email: 'test@example.com', password: 'password123'),
        ).called(1);
      });
    });

    group('successful sign up', () {
      test('returns Right(UserEntity) on successful sign up', () async {
        // Arrange
        final mockUser = MockUserEntity();
        when(
          () => mockAuthRepository.signUpWithEmailPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(mockUser));

        // Act
        final result = await useCase(
          const SignUpWithEmailParams(email: validEmail, password: 'password123'),
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (value) => expect(value, mockUser),
        );
        verify(
          () => mockAuthRepository.signUpWithEmailPassword(email: validEmail, password: 'password123'),
        ).called(1);
      });
    });

    group('error handling', () {
      test('returns RateLimitExceededFailure from repository', () async {
        // Arrange
        when(
          () => mockAuthRepository.signUpWithEmailPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Left(RateLimitExceededFailure()));

        // Act
        final result = await useCase(
          const SignUpWithEmailParams(email: validEmail, password: 'password123'),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<RateLimitExceededFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns AuthFailure from repository', () async {
        // Arrange
        when(
          () => mockAuthRepository.signUpWithEmailPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Left(AuthFailure()));

        // Act
        final result = await useCase(
          const SignUpWithEmailParams(email: validEmail, password: 'password123'),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns ServerConnectionFailure from repository', () async {
        // Arrange
        when(
          () => mockAuthRepository.signUpWithEmailPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Left(ServerConnectionFailure()));

        // Act
        final result = await useCase(
          const SignUpWithEmailParams(email: validEmail, password: 'password123'),
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
