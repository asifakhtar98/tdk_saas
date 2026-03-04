import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_state.dart';
import 'package:tkd_brackets/features/auth/presentation/widgets/member_management_widget.dart';

import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/entities/permission.dart';
import 'package:tkd_brackets/features/auth/domain/entities/rbac_permission_service.dart';

class OrganizationDashboardPage extends StatefulWidget {
  const OrganizationDashboardPage({super.key});

  @override
  State<OrganizationDashboardPage> createState() =>
      _OrganizationDashboardPageState();
}

class _OrganizationDashboardPageState extends State<OrganizationDashboardPage> {
  final _rbac = getIt<RbacPermissionService>();

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<AuthenticationBloc>().state.maybeWhen(
          authenticated: (user) => user.role,
          orElse: () => UserRole.viewer,
        );

    final canManageOrg = _rbac.canPerform(userRole, Permission.manageOrganization);

    return BlocProvider(
      create: (context) {
        final bloc = getIt<OrganizationManagementBloc>();
        final authSharedState = context.read<AuthenticationBloc>().state;
        authSharedState.maybeWhen(
          authenticated: (user) {
            if (user.organizationId.isNotEmpty) {
              bloc.add(OrganizationManagementEvent.organizationLoadRequested(
                organizationId: user.organizationId,
              ));
            }
          },
          orElse: () {},
        );
        return bloc;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Organization Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _onRefresh(context),
            ),
          ],
        ),
        body: BlocConsumer<OrganizationManagementBloc, OrganizationManagementState>(
          listener: (context, state) {
            if (state is OrganizationManagementFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.failure.userFriendlyMessage),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
            if (state is OrganizationManagementOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            return state.maybeWhen(
              loadSuccess: (org, members, invitations) => SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Organization Header
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Icon(Icons.business,
                                size: 64, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          org.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium,
                                        ),
                                      ),
                                      if (canManageOrg)
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () =>
                                              _showRenameDialog(context, org.id, org.name),
                                          tooltip: 'Rename Organization',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Plan: ${org.subscriptionTier.value.toUpperCase()}',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: ${org.subscriptionStatus.value.toUpperCase()}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Member Management Section
                    MemberManagementWidget(
                      organizationId: org.id,
                      members: members,
                      invitations: invitations,
                    ),
                  ],
                ),
              ),
              failure: (failure) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Error loading organization details'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _onRefresh(context),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              orElse: () => const Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }

  void _onRefresh(BuildContext context) {
    final authState = context.read<AuthenticationBloc>().state;
    authState.maybeWhen(
      authenticated: (user) {
        if (user.organizationId.isNotEmpty) {
          context.read<OrganizationManagementBloc>().add(
                OrganizationManagementEvent.organizationLoadRequested(
                  organizationId: user.organizationId,
                ),
              );
        }
      },
      orElse: () {},
    );
  }

  void _showRenameDialog(
      BuildContext context, String orgId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog<void>(
      context: context,
      builder: (diagContext) => AlertDialog(
        title: const Text('Rename Organization'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Organization Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(diagContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                context.read<OrganizationManagementBloc>().add(
                      OrganizationManagementEvent.organizationUpdateRequested(
                        organizationId: orgId,
                        name: newName,
                      ),
                    );
              }
              Navigator.pop(diagContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
