import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

part 'send_invitation_params.freezed.dart';

/// Parameters for SendInvitationUseCase.
@freezed
class SendInvitationParams with _$SendInvitationParams {
  const factory SendInvitationParams({
    /// Email of the user to invite.
    required String email,

    /// Organization to invite the user to.
    required String organizationId,

    /// Role to assign on acceptance.
    required UserRole role,

    /// ID of the user sending the invitation (for auth check).
    required String invitedByUserId,
  }) = _SendInvitationParams;
}
