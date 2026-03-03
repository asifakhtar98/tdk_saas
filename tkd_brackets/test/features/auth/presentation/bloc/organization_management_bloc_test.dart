import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/features/auth/domain/entities/invitation_entity.dart';
import 'package:tkd_brackets/features/auth/domain/entities/organization_entity.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/invitation_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/organization_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/create_organization_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/create_organization_use_case.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/remove_organization_member_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/remove_organization_member_use_case.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/send_invitation_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/send_invitation_use_case.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/update_user_role_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/update_user_role_use_case.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_state.dart';

class MockCreateOrganizationUseCase extends Mock
    implements CreateOrganizationUseCase {}

class MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockInvitationRepository extends Mock implements InvitationRepository {}

class MockSendInvitationUseCase extends Mock implements SendInvitationUseCase {}

class MockUpdateUserRoleUseCase extends Mock implements UpdateUserRoleUseCase {}

class MockRemoveOrganizationMemberUseCase extends Mock
    implements RemoveOrganizationMemberUseCase {}

void main() {
  late MockCreateOrganizationUseCase mockCreateOrganizationUseCase;
  late MockOrganizationRepository mockOrganizationRepository;
  late MockUserRepository mockUserRepository;
  late MockInvitationRepository mockInvitationRepository;
  late MockSendInvitationUseCase mockSendInvitationUseCase;
  late MockUpdateUserRoleUseCase mockUpdateUserRoleUseCase;
  late MockRemoveOrganizationMemberUseCase mockRemoveOrganizationMemberUseCase;
  late OrganizationManagementBloc organizationManagementBloc;

  final testOrg = OrganizationEntity(
    id: 'org-123',
    name: 'Test Org',
    slug: 'test-org',
    subscriptionTier: SubscriptionTier.free,
    subscriptionStatus: SubscriptionStatus.active,
    maxTournamentsPerMonth: 3,
    maxActiveBrackets: 5,
    maxParticipantsPerBracket: 32,
    maxParticipantsPerTournament: 200,
    maxScorers: 10,
    isActive: true,
    createdAt: DateTime(2026),
  );

  final testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    organizationId: 'org-123',
    role: UserRole.owner,
    isActive: true,
    createdAt: DateTime(2026),
  );

  final testInvitation = InvitationEntity(
    id: 'invite-123',
    organizationId: 'org-123',
    email: 'invited@example.com',
    role: UserRole.admin,
    invitedBy: 'user-123',
    status: InvitationStatus.pending,
    token: 'token-123',
    expiresAt: DateTime(2026),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  setUpAll(() {
    registerFallbackValue(testOrg);
    registerFallbackValue(
        const CreateOrganizationParams(name: '', userId: ''));
    registerFallbackValue(const SendInvitationParams(
        email: '',
        organizationId: '',
        role: UserRole.viewer,
        invitedByUserId: ''));
    registerFallbackValue(const UpdateUserRoleParams(
        targetUserId: '', newRole: UserRole.viewer, requestingUserId: ''));
    registerFallbackValue(const RemoveOrganizationMemberParams(
        targetUserId: '', requestingUserId: ''));
  });

  setUp(() {
    mockCreateOrganizationUseCase = MockCreateOrganizationUseCase();
    mockOrganizationRepository = MockOrganizationRepository();
    mockUserRepository = MockUserRepository();
    mockInvitationRepository = MockInvitationRepository();
    mockSendInvitationUseCase = MockSendInvitationUseCase();
    mockUpdateUserRoleUseCase = MockUpdateUserRoleUseCase();
    mockRemoveOrganizationMemberUseCase = MockRemoveOrganizationMemberUseCase();

    organizationManagementBloc = OrganizationManagementBloc(
      mockCreateOrganizationUseCase,
      mockOrganizationRepository,
      mockUserRepository,
      mockInvitationRepository,
      mockSendInvitationUseCase,
      mockUpdateUserRoleUseCase,
      mockRemoveOrganizationMemberUseCase,
    );
  });

  tearDown(() {
    organizationManagementBloc.close();
  });

  group('OrganizationManagementBloc', () {
    test('initial state is OrganizationManagementInitial', () {
      expect(organizationManagementBloc.state,
          const OrganizationManagementState.initial());
    });

    group('OrganizationCreationRequested', () {
      blocTest<OrganizationManagementBloc, OrganizationManagementState>(
        'emits [creationInProgress, creationSuccess] when successful',
        build: () {
          when(() => mockCreateOrganizationUseCase(any()))
              .thenAnswer((_) async => Right(testOrg));
          return organizationManagementBloc;
        },
        act: (bloc) => bloc.add(const OrganizationCreationRequested(
            name: 'Test Org', userId: 'user-123')),
        expect: () => [
          const OrganizationManagementState.creationInProgress(),
          OrganizationManagementState.creationSuccess(testOrg),
        ],
      );
    });

    group('OrganizationLoadRequested', () {
      blocTest<OrganizationManagementBloc, OrganizationManagementState>(
        'emits [loadInProgress, loadSuccess] when successful',
        build: () {
          when(() => mockOrganizationRepository.getOrganizationById(any()))
              .thenAnswer((_) async => Right(testOrg));
          when(() => mockUserRepository.getUsersForOrganization(any()))
              .thenAnswer((_) async => Right([testUser]));
          when(() => mockInvitationRepository
                  .getPendingInvitationsForOrganization(any()))
              .thenAnswer((_) async => Right([testInvitation]));
          return organizationManagementBloc;
        },
        act: (bloc) => bloc.add(
            const OrganizationLoadRequested(organizationId: 'org-123')),
        expect: () => [
          const OrganizationManagementState.loadInProgress(),
          OrganizationManagementLoadSuccess(
            organization: testOrg,
            members: [testUser],
            invitations: [testInvitation],
          ),
        ],
      );
    });

    group('InvitationSendRequested', () {
      blocTest<OrganizationManagementBloc, OrganizationManagementState>(
        'emits [loadInProgress, operationSuccess, loadInProgress, loadSuccess] when successful',
        build: () {
          when(() => mockSendInvitationUseCase(any()))
              .thenAnswer((_) async => Right(testInvitation));
          when(() => mockOrganizationRepository.getOrganizationById(any()))
              .thenAnswer((_) async => Right(testOrg));
          when(() => mockUserRepository.getUsersForOrganization(any()))
              .thenAnswer((_) async => Right([testUser]));
          when(() => mockInvitationRepository
                  .getPendingInvitationsForOrganization(any()))
              .thenAnswer((_) async => Right([testInvitation]));
          return organizationManagementBloc;
        },
        act: (bloc) => bloc.add(const InvitationSendRequested(
          email: 'invited@example.com',
          role: UserRole.admin,
          organizationId: 'org-123',
          invitedByUserId: 'user-123',
        )),
        expect: () => [
          const OrganizationManagementState.loadInProgress(),
          const OrganizationManagementState.operationSuccess(
              'Invitation sent successfully'),
          const OrganizationManagementState.loadInProgress(),
          OrganizationManagementLoadSuccess(
            organization: testOrg,
            members: [testUser],
            invitations: [testInvitation],
          ),
        ],
      );
    });
    group('MemberRoleUpdateRequested', () {
      blocTest<OrganizationManagementBloc, OrganizationManagementState>(
        'emits [loadInProgress, operationSuccess] when successful',
        build: () {
          when(() => mockUpdateUserRoleUseCase(any()))
              .thenAnswer((_) async => Right(testUser));
          return organizationManagementBloc;
        },
        act: (bloc) => bloc.add(const MemberRoleUpdateRequested(
          targetUserId: 'user-456',
          newRole: UserRole.admin,
          requestingUserId: 'user-123',
        )),
        expect: () => [
          const OrganizationManagementState.loadInProgress(),
          const OrganizationManagementState.operationSuccess(
              'Member role updated successfully'),
        ],
      );
    });

    group('MemberRemovalRequested', () {
      blocTest<OrganizationManagementBloc, OrganizationManagementState>(
        'emits [loadInProgress, operationSuccess] when successful',
        build: () {
          when(() => mockRemoveOrganizationMemberUseCase(any()))
              .thenAnswer((_) async => const Right(unit));
          return organizationManagementBloc;
        },
        act: (bloc) => bloc.add(const MemberRemovalRequested(
          targetUserId: 'user-456',
          requestingUserId: 'user-123',
        )),
        expect: () => [
          const OrganizationManagementState.loadInProgress(),
          const OrganizationManagementState.operationSuccess(
              'Member removed successfully'),
        ],
      );
    });

    group('OrganizationUpdateRequested', () {
      blocTest<OrganizationManagementBloc, OrganizationManagementState>(
        'emits [loadInProgress, operationSuccess, loadInProgress, loadSuccess] when successful',
        build: () {
          when(() => mockOrganizationRepository.getOrganizationById(any()))
              .thenAnswer((_) async => Right(testOrg));
          when(() => mockOrganizationRepository.updateOrganization(any()))
              .thenAnswer((_) async => Right(testOrg));
          when(() => mockUserRepository.getUsersForOrganization(any()))
              .thenAnswer((_) async => Right([testUser]));
          when(() => mockInvitationRepository
                  .getPendingInvitationsForOrganization(any()))
              .thenAnswer((_) async => Right([testInvitation]));
          return organizationManagementBloc;
        },
        act: (bloc) => bloc.add(const OrganizationUpdateRequested(
            organizationId: 'org-123', name: 'Updated Name')),
        expect: () => [
          const OrganizationManagementState.loadInProgress(),
          const OrganizationManagementState.operationSuccess(
              'Organization updated successfully'),
          const OrganizationManagementState.loadInProgress(),
          OrganizationManagementLoadSuccess(
            organization: testOrg,
            members: [testUser],
            invitations: [testInvitation],
          ),
        ],
        verify: (_) {
          verify(() => mockOrganizationRepository.updateOrganization(
                any(
                  that: isA<OrganizationEntity>().having(
                    (o) => o.name,
                    'name',
                    'Updated Name',
                  ),
                ),
              )).called(1);
        },
      );
    });
  });
}
