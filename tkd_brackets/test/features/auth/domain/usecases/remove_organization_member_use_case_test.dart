import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/remove_organization_member_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/remove_organization_member_use_case.dart';

import 'package:tkd_brackets/features/auth/domain/entities/permission.dart';
import 'package:tkd_brackets/features/auth/domain/entities/rbac_permission_service.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockRbacPermissionService extends Mock implements RbacPermissionService {}

class FakeUserEntity extends Fake implements UserEntity {}

void main() {
  late RemoveOrganizationMemberUseCase useCase;
  late MockUserRepository mockUserRepository;
  late MockAuthRepository mockAuthRepository;
  late MockRbacPermissionService mockRbac;

  setUpAll(() {
    registerFallbackValue(FakeUserEntity());
    registerFallbackValue(UserRole.viewer);
    registerFallbackValue(Permission.manageTeamMembers);
  });

  setUp(() {
    mockUserRepository = MockUserRepository();
    mockAuthRepository = MockAuthRepository();
    mockRbac = MockRbacPermissionService();
    useCase = RemoveOrganizationMemberUseCase(
      mockUserRepository,
      mockAuthRepository,
      mockRbac,
    );

    // Default RBAC mock to avoid null errors
    when(() => mockRbac.assertPermission(any(), any()))
        .thenReturn(const Right(unit));
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
    role: UserRole.scorer,
    isActive: true,
    createdAt: DateTime(2024),
  );

  final scorerUser = UserEntity(
    id: 'scorer-321',
    email: 'scorer@example.com',
    displayName: 'Scorer User',
    organizationId: 'org-1',
    role: UserRole.scorer,
    isActive: true,
    createdAt: DateTime(2024),
  );

  group('RemoveOrganizationMemberUseCase', () {
    test('successfully removes user from organization', () async {
      when(
        () => mockAuthRepository.getCurrentAuthenticatedUser(),
      ).thenAnswer((_) async => Right(ownerUser));
      when(
        () => mockUserRepository.getUserById('owner-123'),
      ).thenAnswer((_) async => Right(ownerUser));
      when(
        () => mockRbac.assertPermission(any(), any()),
      ).thenReturn(const Right(unit));
      when(
        () => mockUserRepository.getUserById('target-456'),
      ).thenAnswer((_) async => Right(targetUser));

      late UserEntity capturedUser;
      when(() => mockUserRepository.updateUser(any())).thenAnswer((
        invocation,
      ) async {
        capturedUser = invocation.positionalArguments.first as UserEntity;
        return Right(capturedUser);
      });

      final result = await useCase(
        const RemoveOrganizationMemberParams(
          targetUserId: 'target-456',
          requestingUserId: 'owner-123',
        ),
      );

      expect(result.isRight(), isTrue);

      // Verify user was cleared
      expect(capturedUser.organizationId, '');
      expect(capturedUser.role, UserRole.viewer);
      expect(capturedUser.id, 'target-456');

      verify(() => mockUserRepository.updateUser(any())).called(1);
    });

    test('returns AuthenticationFailure when auth user '
        'does not match requestingUserId', () async {
      when(
        () => mockAuthRepository.getCurrentAuthenticatedUser(),
      ).thenAnswer((_) async => Right(scorerUser));

      final result = await useCase(
        const RemoveOrganizationMemberParams(
          targetUserId: 'target-456',
          requestingUserId: 'owner-123',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<AuthenticationFailure>()),
        (_) => fail('Expected Left'),
      );
      verifyZeroInteractions(mockUserRepository);
    });

    test('returns AuthorizationPermissionDeniedFailure '
        'when requester does not have permission', () async {
      when(
        () => mockAuthRepository.getCurrentAuthenticatedUser(),
      ).thenAnswer((_) async => Right(scorerUser));
      when(
        () => mockUserRepository.getUserById('scorer-321'),
      ).thenAnswer((_) async => Right(scorerUser));
      when(
        () => mockRbac.assertPermission(any(), any()),
      ).thenReturn(const Left(AuthorizationPermissionDeniedFailure()));

      final result = await useCase(
        const RemoveOrganizationMemberParams(
          targetUserId: 'target-456',
          requestingUserId: 'scorer-321',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) =>
            expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns InputValidationFailure when trying to '
        'remove self', () async {
      when(
        () => mockAuthRepository.getCurrentAuthenticatedUser(),
      ).thenAnswer((_) async => Right(ownerUser));
      when(
        () => mockUserRepository.getUserById('owner-123'),
      ).thenAnswer((_) async => Right(ownerUser));

      final result = await useCase(
        const RemoveOrganizationMemberParams(
          targetUserId: 'owner-123',
          requestingUserId: 'owner-123',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<InputValidationFailure>()),
        (_) => fail('Expected Left'),
      );
    });

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
          const RemoveOrganizationMemberParams(
            targetUserId: 'target-456',
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
          const RemoveOrganizationMemberParams(
            targetUserId: 'target-456',
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

    test('propagates repository failure when updateUser fails', () async {
      when(
        () => mockAuthRepository.getCurrentAuthenticatedUser(),
      ).thenAnswer((_) async => Right(ownerUser));
      when(
        () => mockUserRepository.getUserById('owner-123'),
      ).thenAnswer((_) async => Right(ownerUser));
      when(
        () => mockUserRepository.getUserById('target-456'),
      ).thenAnswer((_) async => Right(targetUser));
      when(
        () => mockUserRepository.updateUser(any()),
      ).thenAnswer((_) async => const Left(ServerConnectionFailure()));

      final result = await useCase(
        const RemoveOrganizationMemberParams(
          targetUserId: 'target-456',
          requestingUserId: 'owner-123',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerConnectionFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
