import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/invitation_entity.dart';
import 'package:tkd_brackets/features/auth/domain/entities/organization_entity.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

part 'organization_management_state.freezed.dart';

@freezed
class OrganizationManagementState with _$OrganizationManagementState {
  const factory OrganizationManagementState.initial() =
      OrganizationManagementInitial;

  const factory OrganizationManagementState.loadInProgress() =
      OrganizationManagementLoadInProgress;

  const factory OrganizationManagementState.loadSuccess({
    required OrganizationEntity organization,
    required List<UserEntity> members,
    required List<InvitationEntity> invitations,
  }) = OrganizationManagementLoadSuccess;

  const factory OrganizationManagementState.creationInProgress() =
      OrganizationManagementCreationInProgress;

  const factory OrganizationManagementState.creationSuccess(
    OrganizationEntity organization,
  ) = OrganizationManagementCreationSuccess;

  const factory OrganizationManagementState.operationSuccess(String message) =
      OrganizationManagementOperationSuccess;

  const factory OrganizationManagementState.failure(Failure failure) =
      OrganizationManagementFailure;
}
