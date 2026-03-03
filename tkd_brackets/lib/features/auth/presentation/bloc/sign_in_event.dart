import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_in_event.freezed.dart';

@freezed
class SignInEvent with _$SignInEvent {
  const factory SignInEvent.signUpRequested({required String email}) =
      SignUpRequested;

  const factory SignInEvent.signInRequested({required String email}) =
      SignInRequested;

  const factory SignInEvent.magicLinkVerificationRequested({
    required String email,
    required String token,
  }) = MagicLinkVerificationRequested;

  const factory SignInEvent.formReset() = FormReset;
}
