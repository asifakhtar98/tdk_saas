import 'package:freezed_annotation/freezed_annotation.dart';

part 'verify_magic_link_params.freezed.dart';

/// Parameters for verifying a magic link OTP.
@freezed
class VerifyMagicLinkParams with _$VerifyMagicLinkParams {
  const factory VerifyMagicLinkParams({
    /// The email address the magic link was sent to.
    required String email,

    /// The OTP token from the magic link URL.
    required String token,
  }) = _VerifyMagicLinkParams;
}
