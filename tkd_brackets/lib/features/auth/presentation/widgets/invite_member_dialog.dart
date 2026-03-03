import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

/// Modal dialog for inviting new members to the organization.
///
/// Implements AC5 from Story 2.11.
class InviteMemberDialog extends StatefulWidget {
  final void Function(String email, UserRole role) onInvite;
  final bool isLoading;

  const InviteMemberDialog({
    required this.onInvite,
    this.isLoading = false,
    super.key,
  });

  @override
  State<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<InviteMemberDialog> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite Team Member'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Invite a new member to join your organization. They will receive an email invitation.',
                ),
                const SizedBox(height: 24),
                FormBuilderTextField(
                  name: 'email',
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'colleague@example.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.email(),
                  ]),
                ),
                const SizedBox(height: 16),
                FormBuilderDropdown<UserRole>(
                  name: 'role',
                  initialValue: UserRole.viewer,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: [
                    UserRole.admin,
                    UserRole.scorer,
                    UserRole.viewer,
                  ]
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role.value.toUpperCase()),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: widget.isLoading ? null : _onSubmit,
          child: widget.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Send Invitation'),
        ),
      ],
    );
  }

  void _onSubmit() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final email = _formKey.currentState?.value['email'] as String;
      final role = _formKey.currentState?.value['role'] as UserRole;
      widget.onInvite(email, role);
    }
  }
}
