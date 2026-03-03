import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/create_organization_use_case.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/organization_management_state.dart';

class OrganizationSetupPage extends StatefulWidget {
  const OrganizationSetupPage({super.key});

  @override
  State<OrganizationSetupPage> createState() => _OrganizationSetupPageState();
}

class _OrganizationSetupPageState extends State<OrganizationSetupPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  String _currentSlug = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider(
      create: (context) => getIt<OrganizationManagementBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Setup Your Organization'),
          automaticallyImplyLeading: false,
        ),
        body: BlocConsumer<OrganizationManagementBloc, OrganizationManagementState>(
          listener: (context, state) {
            if (state is OrganizationManagementFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.failure.userFriendlyMessage),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.business,
                          size: 80, color: theme.colorScheme.primary),
                      const SizedBox(height: 24),
                      Text(
                        'Almost there!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Provide a name for your organization to begin managing tournaments.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      FormBuilder(
                        key: _formKey,
                        onChanged: () {
                          if (_formKey.currentState?.saveAndValidate(
                                  focusOnInvalid: false) ??
                              false) {
                            final name = _formKey
                                .currentState?.value['organizationName'] as String;
                            setState(() {
                              _currentSlug =
                                  CreateOrganizationUseCase.generateSlug(name);
                            });
                          } else {
                            setState(() {
                              _currentSlug = '';
                            });
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FormBuilderTextField(
                              name: 'organizationName',
                              decoration: const InputDecoration(
                                labelText: 'Organization Name',
                                hintText: 'e.g., Dragon Martial Arts Academy',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.corporate_fare),
                              ),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.minLength(2),
                              ]),
                            ),
                            if (_currentSlug.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Text(
                                  'Slug: $_currentSlug',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: state is OrganizationManagementCreationInProgress
                            ? null
                            : () => _onSubmit(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: state is OrganizationManagementCreationInProgress
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create Organization'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onSubmit(BuildContext context) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final name = _formKey.currentState?.value['organizationName'] as String;
      final authState = context.read<AuthenticationBloc>().state;

      authState.maybeWhen(
        authenticated: (user) {
          context.read<OrganizationManagementBloc>().add(
                OrganizationManagementEvent.organizationCreationRequested(
                  name: name,
                  userId: user.id,
                ),
              );
        },
        orElse: () {
          // In practice, this shouldn't happen because of guards.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please sign in again.')),
          );
        },
      );
    }
  }
}
