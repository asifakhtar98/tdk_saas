import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_state.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/sign_in_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/sign_in_state.dart';
import 'package:tkd_brackets/features/auth/presentation/pages/auth_page.dart';

class MockAuthenticationBloc
    extends MockBloc<AuthenticationEvent, AuthenticationState>
    implements AuthenticationBloc {}

class MockSignInBloc extends MockBloc<SignInEvent, SignInState>
    implements SignInBloc {}

void main() {
  late MockAuthenticationBloc mockAuthenticationBloc;
  late MockSignInBloc mockSignInBloc;

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
    mockAuthenticationBloc = MockAuthenticationBloc();
    mockSignInBloc = MockSignInBloc();

    getIt.registerFactory<AuthenticationBloc>(() => mockAuthenticationBloc);
    getIt.registerFactory<SignInBloc>(() => mockSignInBloc);

    when(() => mockAuthenticationBloc.state)
        .thenReturn(const AuthenticationState.initial());
    when(() => mockSignInBloc.state).thenReturn(const SignInInitial());
  });

  tearDown(getIt.reset);

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<AuthenticationBloc>.value(value: mockAuthenticationBloc),
            BlocProvider<SignInBloc>.value(value: mockSignInBloc),
          ],
          child: const AuthPage(),
        ),
      ),
    );
  }

  group('AuthPage', () {
    testWidgets('renders Sign In form initially', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Sign in'), findsWidgets); // Header
      expect(find.text('Email Address'), findsOneWidget); // Label
      expect(find.text('Password'), findsOneWidget); // Label
      expect(find.text('Sign In'), findsWidgets); // Button
    });

    testWidgets('toggles between Sign In and Sign Up', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Already have an account? Sign In'), findsOneWidget);
    });

    testWidgets('shows loading state when SignInLoadInProgress', (tester) async {
      when(() => mockSignInBloc.state).thenReturn(const SignInLoadInProgress());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows success view when SignInSuccess', (tester) async {
      when(() => mockSignInBloc.state)
          .thenReturn(SignInSuccess(testUser));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Sign in successful!'), findsOneWidget);
    });

    testWidgets('shows error snackbar on SignInFailure', (tester) async {
      whenListen(
        mockSignInBloc,
        Stream.fromIterable([
          const SignInFailure(AuthFailure()),
        ]),
        initialState: const SignInInitial(),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Authentication failed. Please try again.'), findsOneWidget);
    });
  });
}
