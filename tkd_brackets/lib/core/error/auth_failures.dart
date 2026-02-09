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
