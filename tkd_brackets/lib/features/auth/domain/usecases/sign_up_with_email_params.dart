import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_up_with_email_params.freezed.dart';

/// Parameters for the SignUpWithEmailUseCase.
@freezed
class SignUpWithEmailParams with _$SignUpWithEmailParams {
  const factory SignUpWithEmailParams({required String email}) =
      _SignUpWithEmailParams;
}
