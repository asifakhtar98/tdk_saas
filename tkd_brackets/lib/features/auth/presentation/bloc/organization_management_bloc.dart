import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_event.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/invitation_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/organization_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/create_organization_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/create_organization_use_case.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/remove_organization_member_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/remove_organization_member_use_case.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/send_invitation_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/send_invitation_use_case.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/update_user_role_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/update_user_role_use_case.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_state.dart';

@injectable
class OrganizationManagementBloc
    extends Bloc<OrganizationManagementEvent, OrganizationManagementState> {
  OrganizationManagementBloc(
    this._createOrganizationUseCase,
    this._organizationRepository,
    this._userRepository,
    this._invitationRepository,
    this._sendInvitationUseCase,
    this._updateUserRoleUseCase,
    this._removeOrganizationMemberUseCase,
  ) : super(const OrganizationManagementState.initial()) {
    on<OrganizationCreationRequested>(_onCreationRequested);
    on<OrganizationLoadRequested>(_onLoadRequested);
    on<InvitationSendRequested>(_onInvitationSendRequested);
    on<MemberRoleUpdateRequested>(_onMemberRoleUpdateRequested);
    on<MemberRemovalRequested>(_onMemberRemovalRequested);
    on<OrganizationUpdateRequested>(_onUpdateRequested);
  }

  final CreateOrganizationUseCase _createOrganizationUseCase;
  final OrganizationRepository _organizationRepository;
  final UserRepository _userRepository;
  final InvitationRepository _invitationRepository;
  final SendInvitationUseCase _sendInvitationUseCase;
  final UpdateUserRoleUseCase _updateUserRoleUseCase;
  final RemoveOrganizationMemberUseCase _removeOrganizationMemberUseCase;

  String? _currentOrganizationId;

  Future<void> _onCreationRequested(
    OrganizationCreationRequested event,
    Emitter<OrganizationManagementState> emit,
  ) async {
    emit(const OrganizationManagementState.creationInProgress());
    final result = await _createOrganizationUseCase(
      CreateOrganizationParams(name: event.name, userId: event.userId),
    );
    result.fold(
      (failure) => emit(OrganizationManagementState.failure(failure)),
      (org) {
        _currentOrganizationId = org.id;
        getIt<AuthenticationBloc>().add(const AuthenticationEvent.checkRequested());
        emit(OrganizationManagementState.creationSuccess(org));
      },
    );
  }

  Future<void> _onLoadRequested(
    OrganizationLoadRequested event,
    Emitter<OrganizationManagementState> emit,
  ) async {
    _currentOrganizationId = event.organizationId;
    emit(const OrganizationManagementState.loadInProgress());

    final orgResult =
        await _organizationRepository.getOrganizationById(event.organizationId);

    await orgResult.fold(
      (failure) async => emit(OrganizationManagementState.failure(failure)),
      (org) async {
        final membersResult =
            await _userRepository.getUsersForOrganization(event.organizationId);

        await membersResult.fold(
          (failure) async => emit(OrganizationManagementState.failure(failure)),
          (members) async {
            final invitesResult = await _invitationRepository
                .getPendingInvitationsForOrganization(event.organizationId);

            await invitesResult.fold(
              (failure) async =>
                  emit(OrganizationManagementState.failure(failure)),
              (invites) async => emit(OrganizationManagementState.loadSuccess(
                organization: org,
                members: members,
                invitations: invites,
              )),
            );
          },
        );
      },
    );
  }

  Future<void> _onInvitationSendRequested(
    InvitationSendRequested event,
    Emitter<OrganizationManagementState> emit,
  ) async {
    emit(const OrganizationManagementState.loadInProgress());
    final result = await _sendInvitationUseCase(
      SendInvitationParams(
        email: event.email,
        organizationId: event.organizationId,
        role: event.role,
        invitedByUserId: event.invitedByUserId,
      ),
    );
    result.fold(
      (failure) => emit(OrganizationManagementState.failure(failure)),
      (_) {
        emit(const OrganizationManagementState.operationSuccess(
            'Invitation sent successfully'));
        add(OrganizationManagementEvent.organizationLoadRequested(
            organizationId: event.organizationId));
      },
    );
  }

  Future<void> _onMemberRoleUpdateRequested(
    MemberRoleUpdateRequested event,
    Emitter<OrganizationManagementState> emit,
  ) async {
    emit(const OrganizationManagementState.loadInProgress());
    final result = await _updateUserRoleUseCase(
      UpdateUserRoleParams(
        targetUserId: event.targetUserId,
        newRole: event.newRole,
        requestingUserId: event.requestingUserId,
      ),
    );
    result.fold(
      (failure) => emit(OrganizationManagementState.failure(failure)),
      (_) {
        emit(const OrganizationManagementState.operationSuccess(
            'Member role updated successfully'));
        if (_currentOrganizationId != null) {
          add(OrganizationManagementEvent.organizationLoadRequested(
              organizationId: _currentOrganizationId!));
        }
      },
    );
  }

  Future<void> _onMemberRemovalRequested(
    MemberRemovalRequested event,
    Emitter<OrganizationManagementState> emit,
  ) async {
    emit(const OrganizationManagementState.loadInProgress());
    final result = await _removeOrganizationMemberUseCase(
      RemoveOrganizationMemberParams(
        targetUserId: event.targetUserId,
        requestingUserId: event.requestingUserId,
      ),
    );
    result.fold(
      (failure) => emit(OrganizationManagementState.failure(failure)),
      (_) {
        emit(const OrganizationManagementState.operationSuccess(
            'Member removed successfully'));
        if (_currentOrganizationId != null) {
          add(OrganizationManagementEvent.organizationLoadRequested(
              organizationId: _currentOrganizationId!));
        }
      },
    );
  }

  Future<void> _onUpdateRequested(
    OrganizationUpdateRequested event,
    Emitter<OrganizationManagementState> emit,
  ) async {
    emit(const OrganizationManagementState.loadInProgress());

    // Fetch existing entity first
    final oldOrgResult = await _organizationRepository.getOrganizationById(event.organizationId);

    await oldOrgResult.fold(
      (failure) async => emit(OrganizationManagementState.failure(failure)),
      (oldOrg) async {
        final updatedOrg = oldOrg.copyWith(name: event.name);
        final result = await _organizationRepository.updateOrganization(updatedOrg);

        result.fold(
          (failure) => emit(OrganizationManagementState.failure(failure)),
          (newOrg) {
            emit(const OrganizationManagementState.operationSuccess('Organization updated successfully'));
            add(OrganizationManagementEvent.organizationLoadRequested(
                organizationId: event.organizationId));
          },
        );
      },
    );
  }
}
