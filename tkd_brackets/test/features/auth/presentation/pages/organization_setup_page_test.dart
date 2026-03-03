import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_state.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_state.dart';
import 'package:tkd_brackets/features/auth/presentation/pages/organization_setup_page.dart';

class MockAuthenticationBloc
    extends MockBloc<AuthenticationEvent, AuthenticationState>
    implements AuthenticationBloc {}

class MockOrganizationManagementBloc extends MockBloc<
        OrganizationManagementEvent, OrganizationManagementState>
    implements OrganizationManagementBloc {}

void main() {
  late MockAuthenticationBloc mockAuthenticationBloc;
  late MockOrganizationManagementBloc mockOrgBloc;

  setUp(() {
    mockAuthenticationBloc = MockAuthenticationBloc();
    mockOrgBloc = MockOrganizationManagementBloc();

    getIt.registerFactory<AuthenticationBloc>(() => mockAuthenticationBloc);
    getIt.registerFactory<OrganizationManagementBloc>(() => mockOrgBloc);

    when(() => mockAuthenticationBloc.state).thenReturn(
      AuthenticationAuthenticated(
        UserEntity(
          id: 'user1',
          email: 'test@example.com',
          displayName: 'Test User',
          organizationId: '',
          role: UserRole.admin,
          isActive: true,
          createdAt: DateTime(2023),
        ),
      ),
    );
    when(() => mockOrgBloc.state).thenReturn(const OrganizationManagementInitial());
  });

  tearDown(getIt.reset);

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthenticationBloc>.value(value: mockAuthenticationBloc),
          BlocProvider<OrganizationManagementBloc>.value(value: mockOrgBloc),
        ],
        child: const OrganizationSetupPage(),
      ),
    );
  }

  group('OrganizationSetupPage', () {
    testWidgets('renders create organization form', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Create Organization'), findsWidgets);
      expect(find.text('Organization Name'), findsOneWidget);
    });

    testWidgets('shows loading state when CreationInProgress', (tester) async {
      when(() => mockOrgBloc.state)
          .thenReturn(const OrganizationManagementCreationInProgress());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('dispatches CreationRequested on button press', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextField), 'My Org');
      await tester.tap(find.text('Create Organization'));
      await tester.pump();

      verify(() => mockOrgBloc.add(
            const OrganizationManagementEvent.organizationCreationRequested(
              name: 'My Org',
              userId: 'user1',
            ),
          )).called(1);
    });
  });
}
