import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/get_current_user_use_case.dart';

class MockAuthRepository extends Mock
    implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late GetCurrentUserUseCase useCase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = GetCurrentUserUseCase(mockAuthRepository);
  });

  final testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    organizationId: 'org-123',
    role: UserRole.owner,
    isActive: true,
    createdAt: DateTime(2026),
  );

  group('GetCurrentUserUseCase', () {
    test(
      'returns Right(UserEntity) when user is '
      'authenticated',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(testUser));

        final result =
            await useCase(const NoParams());

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (user) =>
              expect(user.id, equals('user-123')),
        );
        verify(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).called(1);
      },
    );

    test(
      'returns Left(Failure) when no user '
      'authenticated',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => const Left(
            UserNotFoundFailure(
              technicalDetails: 'No session',
            ),
          ),
        );

        final result =
            await useCase(const NoParams());

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            isA<UserNotFoundFailure>(),
          ),
          (_) => fail('Expected Left'),
        );
      },
    );
  });
}
