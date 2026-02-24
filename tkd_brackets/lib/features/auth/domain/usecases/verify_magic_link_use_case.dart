import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/verify_magic_link_params.dart';

/// Use case to verify magic link OTP and complete sign-in.
///
/// This use case:
/// 1. Validates the input parameters
/// 2. Delegates to AuthRepository for OTP verification
/// 3. Returns the authenticated user on success
///
/// The repository handles:
/// - OTP verification with Supabase
/// - Session establishment
/// - User profile fetching
/// - Local caching
/// - lastSignInAt update
@injectable
class VerifyMagicLinkUseCase
    extends UseCase<UserEntity, VerifyMagicLinkParams> {
  VerifyMagicLinkUseCase(this._authRepository);

  final AuthRepository _authRepository;

  // Email regex pattern (RFC 5322 simplified)
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  Future<Either<Failure, UserEntity>> call(VerifyMagicLinkParams params) async {
    // Validate email format
    final email = params.email.trim().toLowerCase();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      return const Left(
        InvalidEmailFailure(technicalDetails: 'Email failed regex validation'),
      );
    }

    // Validate token is not empty
    final token = params.token.trim();
    if (token.isEmpty) {
      return const Left(
        InvalidTokenFailure(technicalDetails: 'Token is empty'),
      );
    }

    // Delegate to repository
    return _authRepository.verifyMagicLinkOtp(email: email, token: token);
  }
}
