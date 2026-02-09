import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_in_with_email_params.dart';

/// Use case to send magic link for existing user sign-in.
///
/// This use case:
/// 1. Validates the email format
/// 2. Delegates to AuthRepository to send the magic link
/// 3. Returns success/failure
///
/// The user will receive an email with a magic link.
/// When clicked, use VerifyMagicLinkUseCase to complete sign-in.
///
/// Note: Unlike SignUpWithEmailUseCase, this will fail if the user
/// doesn't exist (shouldCreateUser: false).
@injectable
class SignInWithEmailUseCase extends UseCase<Unit, SignInWithEmailParams> {
  SignInWithEmailUseCase(this._authRepository);

  final AuthRepository _authRepository;

  // Email regex pattern (RFC 5322 simplified)
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  Future<Either<Failure, Unit>> call(SignInWithEmailParams params) async {
    // Validate email format
    final email = params.email.trim().toLowerCase();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      return const Left(
        InvalidEmailFailure(
          technicalDetails: 'Email failed regex validation',
        ),
      );
    }

    // Delegate to repository (which handles infrastructure concerns)
    return _authRepository.sendSignInMagicLink(email: email);
  }
}
