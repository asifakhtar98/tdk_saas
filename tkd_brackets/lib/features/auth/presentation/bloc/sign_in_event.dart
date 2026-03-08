import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_in_event.freezed.dart';

@freezed
class SignInEvent with _$SignInEvent {
  const factory SignInEvent.signUpRequested({
    required String email,
    required String password,
  }) = SignUpRequested;

  const factory SignInEvent.signInRequested({
    required String email,
    required String password,
  }) = SignInRequested;

  const factory SignInEvent.formReset() = FormReset;
}
