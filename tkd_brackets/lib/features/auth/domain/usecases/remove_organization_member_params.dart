import 'package:freezed_annotation/freezed_annotation.dart';

part 'remove_organization_member_params.freezed.dart';

/// Parameters for the RemoveOrganizationMemberUseCase.
///
/// [targetUserId] — The user to remove from the
/// organization.
/// [requestingUserId] — The authenticated user performing
/// the removal (must be Owner).
@freezed
class RemoveOrganizationMemberParams
    with _$RemoveOrganizationMemberParams {
  const factory RemoveOrganizationMemberParams({
    /// The ID of the user being removed from the organization.
    required String targetUserId,

    /// The ID of the authenticated user making the request.
    required String requestingUserId,
  }) = _RemoveOrganizationMemberParams;
}
