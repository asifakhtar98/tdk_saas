import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tkd_brackets/features/auth/domain/entities/invitation_entity.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_state.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_state.dart';

import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/features/auth/domain/entities/permission.dart';
import 'package:tkd_brackets/features/auth/domain/entities/rbac_permission_service.dart';
import 'package:tkd_brackets/features/auth/presentation/widgets/invite_member_dialog.dart';

class MemberManagementWidget extends StatelessWidget {
  final String organizationId;
  final List<UserEntity> members;
  final List<InvitationEntity> invitations;

  /// Optionally inject for testing; defaults to getIt lookup.
  final RbacPermissionService? rbacPermissionService;

  const MemberManagementWidget({
    required this.organizationId,
    required this.members,
    required this.invitations,
    this.rbacPermissionService,
    super.key,
  });

  RbacPermissionService get _rbac =>
      rbacPermissionService ?? getIt<RbacPermissionService>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rbac = _rbac;

    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, state) {
        final userRole = state.maybeWhen(
          authenticated: (user) => user.role,
          orElse: () => UserRole.viewer,
        );

        final canInvite = rbac.canPerform(userRole, Permission.sendInvitations);
        final canManageMembers =
            rbac.canPerform(userRole, Permission.manageTeamMembers);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Team Members',
                    style: theme.textTheme.headlineSmall,
                  ),
                  if (canInvite)
                    FilledButton.icon(
                      onPressed: () => _showInviteDialog(context),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Invite Member'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (members.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('No members found.')),
                  ),
                )
              else
                Column(
                  children: members.map((member) {
                    final isOwner = member.role == UserRole.owner;
                    final authenticatedUserId = state.maybeWhen(
                      authenticated: (u) => u.id,
                      orElse: () => '',
                    );

                    return Card(
                      key: ValueKey('member_item_${member.id}'),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(member.displayName),
                        subtitle: Text(member.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(member.role.value.toUpperCase()),
                              backgroundColor: isOwner
                                  ? theme.colorScheme.primaryContainer
                                  : null,
                            ),
                            if (canManageMembers && !isOwner) ...[
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                key: ValueKey('action_menu_${member.id}'),
                                icon: const Icon(Icons.more_vert),
                                onSelected: (action) {
                                  if (action == 'remove') {
                                    context
                                        .read<OrganizationManagementBloc>()
                                        .add(
                                          OrganizationManagementEvent
                                              .memberRemovalRequested(
                                            targetUserId: member.id,
                                            requestingUserId:
                                                authenticatedUserId,
                                          ),
                                        );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'remove',
                                    child: Text('Remove Member'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const Divider(height: 48),
              Text(
                'Pending Invitations',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (invitations.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('No pending invitations.')),
                  ),
                )
              else
                Column(
                  children: invitations.map((invitation) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.mail_outline),
                        title: Text(invitation.email),
                        subtitle: Text(
                            'Role: ${invitation.role.value.toUpperCase()}'),
                        trailing: Chip(
                          label: Text(invitation.status
                              .toString()
                              .split('.')
                              .last
                              .toUpperCase()),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showInviteDialog(BuildContext context) {
    final requestingUserId =
        context.read<AuthenticationBloc>().state.maybeWhen(
              authenticated: (user) => user.id,
              orElse: () => '',
            );

    if (requestingUserId.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<OrganizationManagementBloc>(),
        child: BlocConsumer<OrganizationManagementBloc,
            OrganizationManagementState>(
          listener: (context, state) {
            if (state is OrganizationManagementOperationSuccess) {
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            return InviteMemberDialog(
              isLoading: state is OrganizationManagementLoadInProgress,
              onInvite: (email, role) {
                context.read<OrganizationManagementBloc>().add(
                      OrganizationManagementEvent.invitationSendRequested(
                        email: email,
                        role: role,
                        organizationId: organizationId,
                        invitedByUserId: requestingUserId,
                      ),
                    );
              },
            );
          },
        ),
      ),
    );
  }
}
