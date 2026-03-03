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
import 'package:tkd_brackets/features/auth/domain/usecases/verify_magic_link_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/verify_magic_link_use_case.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/sign_in_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/sign_in_state.dart';

class MockSignUpWithEmailUseCase extends Mock implements SignUpWithEmailUseCase {}

class MockSignInWithEmailUseCase extends Mock implements SignInWithEmailUseCase {}

class MockVerifyMagicLinkUseCase extends Mock implements VerifyMagicLinkUseCase {}

void main() {
  late MockSignUpWithEmailUseCase mockSignUpWithEmailUseCase;
  late MockSignInWithEmailUseCase mockSignInWithEmailUseCase;
  late MockVerifyMagicLinkUseCase mockVerifyMagicLinkUseCase;
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
    registerFallbackValue(const SignUpWithEmailParams(email: ''));
    registerFallbackValue(const SignInWithEmailParams(email: ''));
    registerFallbackValue(
      const VerifyMagicLinkParams(email: '', token: ''),
    );
  });

  setUp(() {
    mockSignUpWithEmailUseCase = MockSignUpWithEmailUseCase();
    mockSignInWithEmailUseCase = MockSignInWithEmailUseCase();
    mockVerifyMagicLinkUseCase = MockVerifyMagicLinkUseCase();
    signInBloc = SignInBloc(
      mockSignUpWithEmailUseCase,
      mockSignInWithEmailUseCase,
      mockVerifyMagicLinkUseCase,
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
        'emits [loadInProgress, magicLinkSent] when successful',
        build: () {
          when(() => mockSignUpWithEmailUseCase(any()))
              .thenAnswer((_) async => const Right(unit));
          return signInBloc;
        },
        act: (bloc) => bloc.add(const SignUpRequested(email: 'test@example.com')),
        expect: () => [
          const SignInState.loadInProgress(),
          const SignInState.magicLinkSent(email: 'test@example.com'),
        ],
      );

      blocTest<SignInBloc, SignInState>(
        'emits [loadInProgress, failure] when unsuccessful',
        build: () {
          when(() => mockSignUpWithEmailUseCase(any())).thenAnswer(
            (_) async => const Left(MagicLinkSendFailure(technicalDetails: 'fail')),
          );
          return signInBloc;
        },
        act: (bloc) => bloc.add(const SignUpRequested(email: 'test@example.com')),
        expect: () => [
          const SignInState.loadInProgress(),
          isA<SignInFailure>(),
        ],
      );
    });

    group('SignInRequested', () {
      blocTest<SignInBloc, SignInState>(
        'emits [loadInProgress, magicLinkSent] when successful',
        build: () {
          when(() => mockSignInWithEmailUseCase(any()))
              .thenAnswer((_) async => const Right(unit));
          return signInBloc;
        },
        act: (bloc) => bloc.add(const SignInRequested(email: 'test@example.com')),
        expect: () => [
          const SignInState.loadInProgress(),
          const SignInState.magicLinkSent(email: 'test@example.com'),
        ],
      );

      blocTest<SignInBloc, SignInState>(
        'emits [loadInProgress, failure] when unsuccessful',
        build: () {
          when(() => mockSignInWithEmailUseCase(any())).thenAnswer(
            (_) async => const Left(MagicLinkSendFailure(technicalDetails: 'fail')),
          );
          return signInBloc;
        },
        act: (bloc) => bloc.add(const SignInRequested(email: 'test@example.com')),
        expect: () => [
          const SignInState.loadInProgress(),
          isA<SignInFailure>(),
        ],
      );
    });

    group('MagicLinkVerificationRequested', () {
      blocTest<SignInBloc, SignInState>(
        'emits [verificationInProgress, success] when successful',
        build: () {
          when(() => mockVerifyMagicLinkUseCase(any()))
              .thenAnswer((_) async => Right(testUser));
          return signInBloc;
        },
        act: (bloc) => bloc.add(
          const MagicLinkVerificationRequested(
            email: 'test@example.com',
            token: 'valid-token',
          ),
        ),
        expect: () => [
          const SignInState.verificationInProgress(),
          SignInSuccess(testUser),
        ],
      );

      blocTest<SignInBloc, SignInState>(
        'emits [verificationInProgress, failure] when unsuccessful',
        build: () {
          when(() => mockVerifyMagicLinkUseCase(any())).thenAnswer(
            (_) async => const Left(InvalidTokenFailure(technicalDetails: 'fail')),
          );
          return signInBloc;
        },
        act: (bloc) => bloc.add(
          const MagicLinkVerificationRequested(
            email: 'test@example.com',
            token: 'invalid-token',
          ),
        ),
        expect: () => [
          const SignInState.verificationInProgress(),
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
