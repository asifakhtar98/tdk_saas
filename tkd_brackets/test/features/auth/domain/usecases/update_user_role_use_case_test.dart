import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/update_user_role_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/update_user_role_use_case.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeUserEntity extends Fake implements UserEntity {}

void main() {
  late UpdateUserRoleUseCase useCase;
  late MockUserRepository mockUserRepository;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    registerFallbackValue(FakeUserEntity());
  });

  setUp(() {
    mockUserRepository = MockUserRepository();
    mockAuthRepository = MockAuthRepository();
    useCase = UpdateUserRoleUseCase(
      mockUserRepository,
      mockAuthRepository,
    );
  });

  // Fixtures
  final ownerUser = UserEntity(
    id: 'owner-123',
    email: 'owner@example.com',
    displayName: 'Owner',
    organizationId: 'org-1',
    role: UserRole.owner,
    isActive: true,
    createdAt: DateTime(2024),
  );

  final targetUser = UserEntity(
    id: 'target-456',
    email: 'target@example.com',
    displayName: 'Target User',
    organizationId: 'org-1',
    role: UserRole.viewer,
    isActive: true,
    createdAt: DateTime(2024),
  );

  final adminUser = UserEntity(
    id: 'admin-789',
    email: 'admin@example.com',
    displayName: 'Admin User',
    organizationId: 'org-1',
    role: UserRole.admin,
    isActive: true,
    createdAt: DateTime(2024),
  );

  group('UpdateUserRoleUseCase', () {
    test(
      'successfully changes user role when requester is Owner',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );
        when(
          () => mockUserRepository
              .getUserById('owner-123'),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );
        when(
          () => mockUserRepository
              .getUserById('target-456'),
        ).thenAnswer(
          (_) async => Right(targetUser),
        );
        when(
          () => mockUserRepository.updateUser(any()),
        ).thenAnswer((invocation) async {
          final user = invocation.positionalArguments
              .first as UserEntity;
          return Right(user);
        });

        final result = await useCase(
          const UpdateUserRoleParams(
            targetUserId: 'target-456',
            newRole: UserRole.scorer,
            requestingUserId: 'owner-123',
          ),
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (updatedUser) {
            expect(updatedUser.role, UserRole.scorer);
            expect(updatedUser.id, 'target-456');
          },
        );
        verify(
          () => mockUserRepository.updateUser(any()),
        ).called(1);
      },
    );

    test(
      'returns AuthenticationFailure when auth user does '
      'not match requestingUserId',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => Right(adminUser),
        );

        final result = await useCase(
          const UpdateUserRoleParams(
            targetUserId: 'target-456',
            newRole: UserRole.scorer,
            requestingUserId: 'owner-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            isA<AuthenticationFailure>(),
          ),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockUserRepository);
      },
    );

    test(
      'returns AuthorizationPermissionDeniedFailure when '
      'requester is not Owner',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => Right(adminUser),
        );
        when(
          () => mockUserRepository
              .getUserById('admin-789'),
        ).thenAnswer(
          (_) async => Right(adminUser),
        );

        final result = await useCase(
          const UpdateUserRoleParams(
            targetUserId: 'target-456',
            newRole: UserRole.scorer,
            requestingUserId: 'admin-789',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            isA<AuthorizationPermissionDeniedFailure>(),
          ),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      'returns InputValidationFailure when trying to '
      'change own role',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );
        when(
          () => mockUserRepository
              .getUserById('owner-123'),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );

        final result = await useCase(
          const UpdateUserRoleParams(
            targetUserId: 'owner-123',
            newRole: UserRole.admin,
            requestingUserId: 'owner-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            isA<InputValidationFailure>(),
          ),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      'returns InputValidationFailure when trying to '
      'assign Owner role',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );
        when(
          () => mockUserRepository
              .getUserById('owner-123'),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );

        final result = await useCase(
          const UpdateUserRoleParams(
            targetUserId: 'target-456',
            newRole: UserRole.owner,
            requestingUserId: 'owner-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            isA<InputValidationFailure>(),
          ),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      'returns InputValidationFailure when target user has no organization',
      () async {
        final orphanedUser = targetUser.copyWith(organizationId: '');
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(ownerUser));
        when(
          () => mockUserRepository.getUserById('owner-123'),
        ).thenAnswer((_) async => Right(ownerUser));
        when(
          () => mockUserRepository.getUserById('target-456'),
        ).thenAnswer((_) async => Right(orphanedUser));

        final result = await useCase(
          const UpdateUserRoleParams(
            targetUserId: 'target-456',
            newRole: UserRole.scorer,
            requestingUserId: 'owner-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      'returns AuthorizationPermissionDeniedFailure when organization ID mismatch',
      () async {
        final otherOrgUser = targetUser.copyWith(organizationId: 'other-org');
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(ownerUser));
        when(
          () => mockUserRepository.getUserById('owner-123'),
        ).thenAnswer((_) async => Right(ownerUser));
        when(
          () => mockUserRepository.getUserById('target-456'),
        ).thenAnswer((_) async => Right(otherOrgUser));

        final result = await useCase(
          const UpdateUserRoleParams(
            targetUserId: 'target-456',
            newRole: UserRole.scorer,
            requestingUserId: 'owner-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) =>
              expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      'propagates repository failure when updateUser fails',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );
        when(
          () => mockUserRepository
              .getUserById('owner-123'),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );
        when(
          () => mockUserRepository
              .getUserById('target-456'),
        ).thenAnswer(
          (_) async => Right(targetUser),
        );
        when(
          () => mockUserRepository.updateUser(any()),
        ).thenAnswer(
          (_) async => const Left(
            ServerConnectionFailure(),
          ),
        );

        final result = await useCase(
          const UpdateUserRoleParams(
            targetUserId: 'target-456',
            newRole: UserRole.scorer,
            requestingUserId: 'owner-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            isA<ServerConnectionFailure>(),
          ),
          (_) => fail('Expected Left'),
        );
      },
    );
  });
}
