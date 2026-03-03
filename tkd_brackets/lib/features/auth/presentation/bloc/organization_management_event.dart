import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

part 'organization_management_event.freezed.dart';

@freezed
class OrganizationManagementEvent with _$OrganizationManagementEvent {
  const factory OrganizationManagementEvent.organizationCreationRequested({
    required String name,
    required String userId,
  }) = OrganizationCreationRequested;

  const factory OrganizationManagementEvent.organizationLoadRequested({
    required String organizationId,
  }) = OrganizationLoadRequested;

  const factory OrganizationManagementEvent.invitationSendRequested({
    required String email,
    required UserRole role,
    required String organizationId,
    required String invitedByUserId,
  }) = InvitationSendRequested;

  const factory OrganizationManagementEvent.memberRoleUpdateRequested({
    required String targetUserId,
    required UserRole newRole,
    required String requestingUserId,
  }) = MemberRoleUpdateRequested;

  const factory OrganizationManagementEvent.memberRemovalRequested({
    required String targetUserId,
    required String requestingUserId,
  }) = MemberRemovalRequested;

  const factory OrganizationManagementEvent.organizationUpdateRequested({
    required String organizationId,
    required String name,
  }) = OrganizationUpdateRequested;
}
