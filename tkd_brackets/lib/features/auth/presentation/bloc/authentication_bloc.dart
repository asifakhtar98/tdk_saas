import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_state.dart';

/// BLoC managing global authentication state.
///
/// This is a singleton BLoC that:
/// 1. Checks for existing sessions on startup
/// 2. Listens to auth state changes from Supabase
/// 3. Handles sign-out requests
///
/// Registered as [lazySingleton] because auth state is
/// global and shared across the entire app.
@lazySingleton
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc(
    this._getCurrentUserUseCase,
    this._signOutUseCase,
    this._authRepository,
  ) : super(const AuthenticationState.initial()) {
    on<AuthenticationCheckRequested>(_onCheckRequested);
    on<AuthenticationUserChanged>(_onUserChanged);
    on<AuthenticationSignOutRequested>(_onSignOutRequested);

    // Subscribe to auth state changes stream
    _authStateSubscription = _authRepository.authStateChanges.listen((either) {
      either.fold(
        // Stream errors are deliberately ignored to
        // prevent transient auth state disruptions
        // (e.g., brief network blips). The last known
        // auth state is preserved until a definitive
        // change arrives. This avoids unexpected
        // redirects or UI flicker from temporary
        // connectivity issues.
        (_) {},
        (user) => add(AuthenticationUserChanged(user)),
      );
    });
  }

  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final SignOutUseCase _signOutUseCase;
  final AuthRepository _authRepository;

  StreamSubscription<Either<Failure, UserEntity?>>? _authStateSubscription;

  Future<void> _onCheckRequested(
    AuthenticationCheckRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationState.checkInProgress());

    final result = await _getCurrentUserUseCase(const NoParams());

    result.fold(
      (failure) => emit(const AuthenticationState.unauthenticated()),
      (user) => emit(AuthenticationState.authenticated(user)),
    );
  }

  Future<void> _onUserChanged(
    AuthenticationUserChanged event,
    Emitter<AuthenticationState> emit,
  ) async {
    final user = event.user;
    if (user != null) {
      emit(AuthenticationState.authenticated(user));
    } else {
      emit(const AuthenticationState.unauthenticated());
    }
  }

  Future<void> _onSignOutRequested(
    AuthenticationSignOutRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationState.signOutInProgress());

    final result = await _signOutUseCase(const NoParams());

    result.fold(
      (failure) => emit(AuthenticationState.failure(failure)),
      (_) => emit(const AuthenticationState.unauthenticated()),
    );
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
