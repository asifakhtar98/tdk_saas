import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/features/auth/domain/entities/invitation_entity.dart';
import 'package:tkd_brackets/features/auth/domain/entities/permission.dart';
import 'package:tkd_brackets/features/auth/domain/entities/rbac_permission_service.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_state.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_state.dart';
import 'package:tkd_brackets/features/auth/presentation/widgets/member_management_widget.dart';
import 'package:tkd_brackets/features/auth/presentation/widgets/invite_member_dialog.dart';

class MockAuthenticationBloc
    extends MockBloc<AuthenticationEvent, AuthenticationState>
    implements AuthenticationBloc {}

class MockOrganizationManagementBloc extends MockBloc<
        OrganizationManagementEvent, OrganizationManagementState>
    implements OrganizationManagementBloc {}

class MockRbacPermissionService extends Mock implements RbacPermissionService {}

void main() {
  late MockAuthenticationBloc mockAuthenticationBloc;
  late MockOrganizationManagementBloc mockOrgBloc;

  final testMembers = [
    UserEntity(
      id: 'owner1',
      email: 'owner@test.com',
      displayName: 'Owner User',
      organizationId: 'org1',
      role: UserRole.owner,
      isActive: true,
      createdAt: DateTime(2023),
    ),
    UserEntity(
      id: 'admin1',
      email: 'admin@test.com',
      displayName: 'Admin User',
      organizationId: 'org1',
      role: UserRole.admin,
      isActive: true,
      createdAt: DateTime(2023),
    ),
  ];

  final testInvitations = [
    InvitationEntity(
      id: 'invite1',
      email: 'invitee@test.com',
      role: UserRole.scorer,
      organizationId: 'org1',
      status: InvitationStatus.pending,
      invitedBy: 'owner1',
      token: 'token1',
      createdAt: DateTime(2023),
      expiresAt: DateTime(2024),
      updatedAt: DateTime(2023),
    ),
  ];

  setUpAll(() {
    registerFallbackValue(UserRole.viewer);
    registerFallbackValue(Permission.sendInvitations);
    registerFallbackValue(Permission.manageTeamMembers);
    registerFallbackValue(Permission.manageOrganization);
    // Needed for mocktail `any()` matchers in verify() calls
    registerFallbackValue(
      const MemberRemovalRequested(
        targetUserId: '',
        requestingUserId: '',
      ),
    );
    registerFallbackValue(
      const InvitationSendRequested(
        email: '',
        role: UserRole.viewer,
        organizationId: '',
        invitedByUserId: '',
      ),
    );
  });

  late RbacPermissionService rbacService;

  setUp(() {
    mockAuthenticationBloc = MockAuthenticationBloc();
    mockOrgBloc = MockOrganizationManagementBloc();
    rbacService = RbacPermissionService();

    when(() => mockAuthenticationBloc.state).thenReturn(
      AuthenticationState.authenticated(testMembers[0]),
    );
    when(() => mockOrgBloc.state).thenReturn(const OrganizationManagementInitial());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<AuthenticationBloc>.value(value: mockAuthenticationBloc),
            BlocProvider<OrganizationManagementBloc>.value(value: mockOrgBloc),
          ],
          child: MemberManagementWidget(
            organizationId: 'org1',
            members: testMembers,
            invitations: testInvitations,
            rbacPermissionService: rbacService,
          ),
        ),
      ),
    );
  }

  group('MemberManagementWidget', () {
    testWidgets('renders members and invitations list', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Team Members'), findsOneWidget);
      expect(find.text('Owner User'), findsOneWidget);
      expect(find.text('Admin User'), findsOneWidget);
      expect(find.text('invitee@test.com'), findsOneWidget);
    });

    testWidgets('shows invite dialog on button press', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final inviteButton = find.text('Invite Member');
      expect(inviteButton, findsOneWidget);
      await tester.tap(inviteButton);
      await tester.pumpAndSettle();

      expect(find.byType(InviteMemberDialog), findsOneWidget);
      expect(find.text('Invite Team Member'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'new@test.com');
      await tester.tap(find.text('Send Invitation'));
      await tester.pumpAndSettle();

      verify(() => mockOrgBloc.add(
            any(
              that: isA<InvitationSendRequested>().having(
                (e) => e.email,
                'email',
                'new@test.com',
              ),
            ),
          )).called(1);
    });

    testWidgets('dispatches memberRemovalRequested on delete press', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Admin User'), findsOneWidget);

      // Look for action menu for admin1
      final menuButton = find.byKey(const ValueKey('action_menu_admin1'));
      expect(menuButton, findsOneWidget); 
      
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      final removeButton = find.text('Remove Member');
      expect(removeButton, findsOneWidget);

      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      verify(() => mockOrgBloc.add(
            any(
              that: isA<MemberRemovalRequested>().having(
                (e) => e.targetUserId,
                'targetUserId',
                'admin1',
              ),
            ),
          )).called(1);
    });
  });
}
