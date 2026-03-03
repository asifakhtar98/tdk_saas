import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/di/injection.dart';
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
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthenticationBloc>.value(value: mockAuthenticationBloc),
          BlocProvider<SignInBloc>.value(value: mockSignInBloc),
        ],
        child: const AuthPage(),
      ),
    );
  }

  group('AuthPage', () {
    testWidgets('renders Sign In form initially', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Sign in'), findsWidgets); // Header
      expect(find.text('Email Address'), findsOneWidget); // Label
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

    testWidgets('shows success view when SignInMagicLinkSent', (tester) async {
      when(() => mockSignInBloc.state)
          .thenReturn(const SignInMagicLinkSent(email: 'test@example.com'));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Check your email'), findsOneWidget);
      expect(find.textContaining('test@example.com'), findsOneWidget);
    });

    testWidgets('shows error snackbar on SignInFailure', (tester) async {
      whenListen(
        mockSignInBloc,
        Stream.fromIterable([
          const SignInFailure(MagicLinkSendFailure()),
        ]),
        initialState: const SignInInitial(),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Unable to send magic link. Please try again.'), findsOneWidget);
    });
  });
}
