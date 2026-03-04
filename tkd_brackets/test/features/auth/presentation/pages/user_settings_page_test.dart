import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_state.dart';
import 'package:tkd_brackets/features/auth/presentation/pages/user_settings_page.dart';

class MockAuthenticationBloc
    extends MockBloc<AuthenticationEvent, AuthenticationState>
    implements AuthenticationBloc {}

void main() {
  late MockAuthenticationBloc mockAuthBloc;

  final testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    organizationId: 'org-123',
    role: UserRole.owner,
    isActive: true,
    createdAt: DateTime(2026),
  );

  setUp(() {
    mockAuthBloc = MockAuthenticationBloc();
    when(() => mockAuthBloc.state)
        .thenReturn(AuthenticationAuthenticated(testUser));
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthenticationBloc>.value(
        value: mockAuthBloc,
        child: const UserSettingsPage(),
      ),
    );
  }

  group('UserSettingsPage', () {
    testWidgets('renders user display name and email', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('renders user role chip', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('OWNER'), findsOneWidget);
    });

    testWidgets('renders sign out list tile', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Scroll to bring Sign Out into view
      await tester.scrollUntilVisible(
        find.text('Sign Out'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('shows confirmation dialog on sign out tap', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Sign Out'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('dispatches sign out event on dialog confirm', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Sign Out'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      // Tap the dialog's "Sign Out" button
      final signOutButtons = find.text('Sign Out');
      await tester.tap(signOutButtons.last);
      await tester.pumpAndSettle();

      verify(() => mockAuthBloc
          .add(const AuthenticationEvent.signOutRequested())).called(1);
    });

    testWidgets('renders loading when unauthenticated', (tester) async {
      when(() => mockAuthBloc.state)
          .thenReturn(const AuthenticationState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
