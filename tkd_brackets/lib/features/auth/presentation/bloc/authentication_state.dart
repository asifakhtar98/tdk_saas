import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

part 'authentication_state.freezed.dart';

/// States for the AuthenticationBloc.
///
/// Naming follows architecture convention:
/// `{Feature}{Status}`
@freezed
class AuthenticationState with _$AuthenticationState {
  /// Initial state before any auth check.
  const factory AuthenticationState.initial() = AuthenticationInitial;

  /// Auth check is in progress (loading).
  const factory AuthenticationState.checkInProgress() =
      AuthenticationCheckInProgress;

  /// User is authenticated.
  const factory AuthenticationState.authenticated(UserEntity user) =
      AuthenticationAuthenticated;

  /// User is not authenticated.
  const factory AuthenticationState.unauthenticated() =
      AuthenticationUnauthenticated;

  /// Sign-out is in progress.
  const factory AuthenticationState.signOutInProgress() =
      AuthenticationSignOutInProgress;

  /// Authentication operation failed.
  const factory AuthenticationState.failure(Failure failure) =
      AuthenticationFailure;
}
