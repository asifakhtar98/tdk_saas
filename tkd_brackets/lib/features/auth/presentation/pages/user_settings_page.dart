import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_state.dart';

class UserSettingsPage extends StatelessWidget {
  const UserSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('User Settings'),
          ),
          body: state.maybeWhen(
            authenticated: (user) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // User Profile Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: user.avatarUrl != null
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.displayName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Chip(label: Text(user.role.value.toUpperCase())),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Account Settings Section
                Text(
                  'Account',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                const ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Profile'),
                  subtitle: Text('Change your display name and avatar'),
                  // Future: Implement edit flow
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.security),
                  title: Text('Security'),
                  subtitle: Text('Manage your authentication methods'),
                  // Future: Implement security settings
                ),
                const SizedBox(height: 48),

                // Session Management
                Text(
                  'Session',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title:
                      const Text('Sign Out', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('End your current session'),
                  onTap: () => _onSignOut(context),
                ),
              ],
            ),
            orElse: () => const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  void _onSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context
                  .read<AuthenticationBloc>()
                  .add(const AuthenticationEvent.signOutRequested());
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
