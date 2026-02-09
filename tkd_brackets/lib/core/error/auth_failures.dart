import 'package:tkd_brackets/core/error/failures.dart';

/// Failure when magic link email fails to send.
class MagicLinkSendFailure extends Failure {
  const MagicLinkSendFailure({
    super.userFriendlyMessage = 'Unable to send magic link. Please try again.',
    super.technicalDetails,
  });
}

/// Failure when email validation fails.
class InvalidEmailFailure extends Failure {
  const InvalidEmailFailure({
    super.userFriendlyMessage = 'Please enter a valid email address.',
    super.technicalDetails,
  });
}

/// Failure when rate limit is exceeded.
class RateLimitExceededFailure extends Failure {
  const RateLimitExceededFailure({
    super.userFriendlyMessage =
        'Too many requests. Please wait a moment and try again.',
    super.technicalDetails,
  });
}

/// Failure when OTP/magic link token is invalid or malformed.
class InvalidTokenFailure extends Failure {
  const InvalidTokenFailure({
    super.userFriendlyMessage =
        'Invalid or malformed link. Please request a new one.',
    super.technicalDetails,
  });
}

/// Failure when magic link has expired (Supabase default: 1 hour).
class ExpiredTokenFailure extends Failure {
  const ExpiredTokenFailure({
    super.userFriendlyMessage =
        'This link has expired. Please request a new one.',
    super.technicalDetails,
  });
}

/// Failure when user account is not found.
class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure({
    super.userFriendlyMessage =
        'No account found with this email. Please sign up first.',
    super.technicalDetails,
  });
}

/// Failure when OTP verification fails.
class OtpVerificationFailure extends Failure {
  const OtpVerificationFailure({
    super.userFriendlyMessage = 'Verification failed. Please try again.',
    super.technicalDetails,
  });
}
