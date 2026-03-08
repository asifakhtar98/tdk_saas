import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_in_with_email_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_in_with_email_use_case.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_up_with_email_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_up_with_email_use_case.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/sign_in_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/sign_in_state.dart';

class MockSignUpWithEmailUseCase extends Mock implements SignUpWithEmailUseCase {}

class MockSignInWithEmailUseCase extends Mock implements SignInWithEmailUseCase {}

void main() {
  late MockSignUpWithEmailUseCase mockSignUpWithEmailUseCase;
  late MockSignInWithEmailUseCase mockSignInWithEmailUseCase;
  late SignInBloc signInBloc;

  final testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    organizationId: 'org-123',
    role: UserRole.owner,
    isActive: true,
    createdAt: DateTime(2026),
  );

  setUpAll(() {
    registerFallbackValue(const SignUpWithEmailParams(email: '', password: ''));
    registerFallbackValue(const SignInWithEmailParams(email: '', password: ''));
  });

  setUp(() {
    mockSignUpWithEmailUseCase = MockSignUpWithEmailUseCase();
    mockSignInWithEmailUseCase = MockSignInWithEmailUseCase();
    signInBloc = SignInBloc(
      mockSignUpWithEmailUseCase,
      mockSignInWithEmailUseCase,
    );
  });

  tearDown(() {
    signInBloc.close();
  });

  group('SignInBloc', () {
    test('initial state is SignInInitial', () {
      expect(signInBloc.state, const SignInState.initial());
    });

    group('SignUpRequested', () {
      blocTest<SignInBloc, SignInState>(
        'emits [loadInProgress, success] when successful',
        build: () {
          when(() => mockSignUpWithEmailUseCase(any()))
              .thenAnswer((_) async => Right(testUser));
          return signInBloc;
        },
        act: (bloc) => bloc.add(const SignUpRequested(email: 'test@example.com', password: 'password123')),
        expect: () => [
          const SignInState.loadInProgress(),
          SignInSuccess(testUser),
        ],
      );

      blocTest<SignInBloc, SignInState>(
        'emits [loadInProgress, failure] when unsuccessful',
        build: () {
          when(() => mockSignUpWithEmailUseCase(any())).thenAnswer(
            (_) async => const Left(AuthFailure(technicalDetails: 'fail')),
          );
          return signInBloc;
        },
        act: (bloc) => bloc.add(const SignUpRequested(email: 'test@example.com', password: 'password123')),
        expect: () => [
          const SignInState.loadInProgress(),
          isA<SignInFailure>(),
        ],
      );
    });

    group('SignInRequested', () {
      blocTest<SignInBloc, SignInState>(
        'emits [loadInProgress, success] when successful',
        build: () {
          when(() => mockSignInWithEmailUseCase(any()))
              .thenAnswer((_) async => Right(testUser));
          return signInBloc;
        },
        act: (bloc) => bloc.add(const SignInRequested(email: 'test@example.com', password: 'password123')),
        expect: () => [
          const SignInState.loadInProgress(),
          SignInSuccess(testUser),
        ],
      );

      blocTest<SignInBloc, SignInState>(
        'emits [loadInProgress, failure] when unsuccessful',
        build: () {
          when(() => mockSignInWithEmailUseCase(any())).thenAnswer(
            (_) async => const Left(AuthFailure(technicalDetails: 'fail')),
          );
          return signInBloc;
        },
        act: (bloc) => bloc.add(const SignInRequested(email: 'test@example.com', password: 'password123')),
        expect: () => [
          const SignInState.loadInProgress(),
          isA<SignInFailure>(),
        ],
      );
    });

    group('FormReset', () {
      blocTest<SignInBloc, SignInState>(
        'emits [initial] on FormReset',
        build: () => signInBloc,
        act: (bloc) => bloc.add(const FormReset()),
        expect: () => [const SignInState.initial()],
      );
    });
  });
}
