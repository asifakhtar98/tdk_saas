import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

part 'update_user_role_params.freezed.dart';

/// Parameters for the UpdateUserRoleUseCase.
///
/// [targetUserId] — The user whose role will be changed.
/// [newRole] — The new role to assign.
/// [requestingUserId] — The authenticated user performing
/// the change (must be Owner).
@freezed
class UpdateUserRoleParams with _$UpdateUserRoleParams {
  const factory UpdateUserRoleParams({
    /// The ID of the user whose role is being changed.
    required String targetUserId,

    /// The new role to assign to the target user.
    required UserRole newRole,

    /// The ID of the authenticated user making the request.
    required String requestingUserId,
  }) = _UpdateUserRoleParams;
}
