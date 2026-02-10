import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_state.dart';

class MockGetCurrentUserUseCase extends Mock
    implements GetCurrentUserUseCase {}

class MockSignOutUseCase extends Mock
    implements SignOutUseCase {}

class MockAuthRepository extends Mock
    implements AuthRepository {}

void main() {
  late MockGetCurrentUserUseCase
      mockGetCurrentUserUseCase;
  late MockSignOutUseCase mockSignOutUseCase;
  late MockAuthRepository mockAuthRepository;
  late StreamController<Either<Failure, UserEntity?>>
      authStateController;

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
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockGetCurrentUserUseCase =
        MockGetCurrentUserUseCase();
    mockSignOutUseCase = MockSignOutUseCase();
    mockAuthRepository = MockAuthRepository();
    authStateController = StreamController<
        Either<Failure, UserEntity?>>.broadcast();

    when(() => mockAuthRepository.authStateChanges)
        .thenAnswer(
      (_) => authStateController.stream,
    );
  });

  tearDown(() {
    authStateController.close();
  });

  AuthenticationBloc buildBloc() {
    return AuthenticationBloc(
      mockGetCurrentUserUseCase,
      mockSignOutUseCase,
      mockAuthRepository,
    );
  }

  group('AuthenticationBloc', () {
    test('initial state is AuthenticationInitial', () {
      final bloc = buildBloc();
      expect(
        bloc.state,
        const AuthenticationState.initial(),
      );
      bloc.close();
    });

    group('AuthenticationCheckRequested', () {
      blocTest<AuthenticationBloc,
          AuthenticationState>(
        'emits [checkInProgress, authenticated] '
        'when user exists',
        build: buildBloc,
        setUp: () {
          when(() => mockGetCurrentUserUseCase(any()))
              .thenAnswer(
            (_) async => Right(testUser),
          );
        },
        act: (bloc) => bloc.add(
          const AuthenticationEvent.checkRequested(),
        ),
        expect: () => [
          const AuthenticationState.checkInProgress(),
          AuthenticationState.authenticated(testUser),
        ],
      );

      blocTest<AuthenticationBloc,
          AuthenticationState>(
        'emits [checkInProgress, unauthenticated] '
        'when no user',
        build: buildBloc,
        setUp: () {
          when(() => mockGetCurrentUserUseCase(any()))
              .thenAnswer(
            (_) async => const Left(
              UserNotFoundFailure(
                technicalDetails: 'No session',
              ),
            ),
          );
        },
        act: (bloc) => bloc.add(
          const AuthenticationEvent.checkRequested(),
        ),
        expect: () => [
          const AuthenticationState.checkInProgress(),
          const AuthenticationState.unauthenticated(),
        ],
      );
    });

    group('AuthenticationUserChanged', () {
      blocTest<AuthenticationBloc,
          AuthenticationState>(
        'emits [authenticated] when user is not null',
        build: buildBloc,
        act: (bloc) => bloc.add(
          AuthenticationEvent.userChanged(testUser),
        ),
        expect: () => [
          AuthenticationState.authenticated(testUser),
        ],
      );

      blocTest<AuthenticationBloc,
          AuthenticationState>(
        'emits [unauthenticated] when user is null',
        build: buildBloc,
        act: (bloc) => bloc.add(
          const AuthenticationEvent.userChanged(null),
        ),
        expect: () => [
          const AuthenticationState.unauthenticated(),
        ],
      );
    });

    group('AuthenticationSignOutRequested', () {
      blocTest<AuthenticationBloc,
          AuthenticationState>(
        'emits [signOutInProgress, unauthenticated] '
        'on success',
        build: buildBloc,
        setUp: () {
          when(() => mockSignOutUseCase(any()))
              .thenAnswer(
            (_) async => const Right(unit),
          );
        },
        act: (bloc) => bloc.add(
          const AuthenticationEvent
              .signOutRequested(),
        ),
        expect: () => [
          const AuthenticationState
              .signOutInProgress(),
          const AuthenticationState.unauthenticated(),
        ],
      );

      blocTest<AuthenticationBloc,
          AuthenticationState>(
        'emits [signOutInProgress, failure] '
        'on error',
        build: buildBloc,
        setUp: () {
          when(() => mockSignOutUseCase(any()))
              .thenAnswer(
            (_) async => const Left(
              SignOutFailure(
                technicalDetails: 'Failed',
              ),
            ),
          );
        },
        act: (bloc) => bloc.add(
          const AuthenticationEvent
              .signOutRequested(),
        ),
        expect: () => [
          const AuthenticationState
              .signOutInProgress(),
          isA<AuthenticationFailure>(),
        ],
      );
    });

    group('auth state stream subscription', () {
      blocTest<AuthenticationBloc,
          AuthenticationState>(
        'reacts to auth state changes from stream',
        build: buildBloc,
        act: (bloc) async {
          authStateController.add(
            Right<Failure, UserEntity?>(testUser),
          );
          await Future<void>.delayed(
            const Duration(milliseconds: 100),
          );
        },
        expect: () => [
          AuthenticationState.authenticated(testUser),
        ],
      );

      blocTest<AuthenticationBloc,
          AuthenticationState>(
        'handles null user from stream '
        '(signed out)',
        build: buildBloc,
        act: (bloc) async {
          authStateController.add(
            const Right<Failure, UserEntity?>(null),
          );
          await Future<void>.delayed(
            const Duration(milliseconds: 100),
          );
        },
        expect: () => [
          const AuthenticationState.unauthenticated(),
        ],
      );

      blocTest<AuthenticationBloc,
          AuthenticationState>(
        'ignores stream errors silently',
        build: buildBloc,
        act: (bloc) async {
          authStateController.add(
            const Left<Failure, UserEntity?>(
              ServerConnectionFailure(
                technicalDetails: 'Stream error',
              ),
            ),
          );
          await Future<void>.delayed(
            const Duration(milliseconds: 100),
          );
        },
        expect: () => <AuthenticationState>[],
      );
    });

    test(
      'subscribes to authStateChanges during '
      'construction',
      () {
        buildBloc();
        verify(
          () => mockAuthRepository.authStateChanges,
        ).called(1);
      },
    );

    test('cancels stream subscription on close',
        () async {
      final bloc = buildBloc();
      await bloc.close();

      // After close, adding to stream should
      // not affect bloc
      authStateController.add(
        Right<Failure, UserEntity?>(testUser),
      );

      // No error thrown = subscription cancelled
      expect(bloc.isClosed, isTrue);
    });
  });
}
