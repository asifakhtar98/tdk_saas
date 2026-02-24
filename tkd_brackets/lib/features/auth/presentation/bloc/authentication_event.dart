import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

part 'authentication_event.freezed.dart';

/// Events for the AuthenticationBloc.
///
/// Naming follows architecture convention:
/// `{Feature}{Action}Requested`
@freezed
class AuthenticationEvent with _$AuthenticationEvent {
  /// Check if user has an existing session (app startup).
  const factory AuthenticationEvent.checkRequested() =
      AuthenticationCheckRequested;

  /// **INTERNAL EVENT — DO NOT DISPATCH FROM UI.**
  ///
  /// User authenticated externally (from auth state stream).
  /// Only dispatched by the BLoC's own stream subscription.
  /// UI widgets should NEVER add this event directly.
  const factory AuthenticationEvent.userChanged(UserEntity? user) =
      AuthenticationUserChanged;

  /// User requested sign out.
  const factory AuthenticationEvent.signOutRequested() =
      AuthenticationSignOutRequested;
}
