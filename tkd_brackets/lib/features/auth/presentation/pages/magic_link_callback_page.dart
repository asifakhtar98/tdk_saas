import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/sign_in_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/sign_in_state.dart';

class MagicLinkCallbackPage extends StatefulWidget {
  final String email;
  final String token;

  const MagicLinkCallbackPage({
    required this.email, required this.token, super.key,
  });

  @override
  State<MagicLinkCallbackPage> createState() => _MagicLinkCallbackPageState();
}

class _MagicLinkCallbackPageState extends State<MagicLinkCallbackPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SignInBloc>()
        ..add(SignInEvent.magicLinkVerificationRequested(
          email: widget.email,
          token: widget.token,
        )),
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: BlocBuilder<SignInBloc, SignInState>(
                builder: (context, state) {
                  if (state is SignInFailure) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Verification failed',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.failure.userFriendlyMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            // In a real app, you'd navigate back to the auth page.
                            // The router will handle the redirection if the state changes.
                          },
                          child: const Text('Back to Sign In'),
                        ),
                      ],
                    );
                  }

                  if (state is SignInSuccess) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 64, color: Colors.green),
                        const SizedBox(height: 16),
                        Text(
                          'Successfully verified',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Redirecting you to the dashboard...',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  }

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        'Verifying link...',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please wait while we confirm your identity.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
