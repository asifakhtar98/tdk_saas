import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_in_with_email_params.freezed.dart';

/// Parameters for the email sign-in use case.
@freezed
class SignInWithEmailParams with _$SignInWithEmailParams {
  const factory SignInWithEmailParams({required String email}) =
      _SignInWithEmailParams;
}
