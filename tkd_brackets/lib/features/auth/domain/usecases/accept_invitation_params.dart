import 'package:freezed_annotation/freezed_annotation.dart';

part 'accept_invitation_params.freezed.dart';

/// Parameters for AcceptInvitationUseCase.
@freezed
class AcceptInvitationParams with _$AcceptInvitationParams {
  const factory AcceptInvitationParams({
    /// The invitation token from the magic link.
    required String token,

    /// The authenticated user's ID accepting the invitation.
    required String userId,
  }) = _AcceptInvitationParams;
}
