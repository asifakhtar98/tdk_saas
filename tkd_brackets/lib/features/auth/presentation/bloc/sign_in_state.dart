import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

part 'sign_in_state.freezed.dart';

@freezed
class SignInState with _$SignInState {
  const factory SignInState.initial() = SignInInitial;

  const factory SignInState.loadInProgress() = SignInLoadInProgress;

  const factory SignInState.success(UserEntity user) = SignInSuccess;

  const factory SignInState.failure(Failure failure) = SignInFailure;
}
