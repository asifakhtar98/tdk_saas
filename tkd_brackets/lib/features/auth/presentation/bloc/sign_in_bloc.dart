import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_in_with_email_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_in_with_email_use_case.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_up_with_email_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_up_with_email_use_case.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/sign_in_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/sign_in_state.dart';

@injectable
class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc(
    this._signUpWithEmailUseCase,
    this._signInWithEmailUseCase,
  ) : super(const SignInState.initial()) {
    on<SignUpRequested>(_onSignUpRequested);
    on<SignInRequested>(_onSignInRequested);
    on<FormReset>(_onFormReset);
  }

  final SignUpWithEmailUseCase _signUpWithEmailUseCase;
  final SignInWithEmailUseCase _signInWithEmailUseCase;

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<SignInState> emit,
  ) async {
    emit(const SignInState.loadInProgress());
    final result = await _signUpWithEmailUseCase(
      SignUpWithEmailParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) => emit(SignInState.failure(failure)),
      (user) => emit(SignInState.success(user)),
    );
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<SignInState> emit,
  ) async {
    emit(const SignInState.loadInProgress());
    final result = await _signInWithEmailUseCase(
      SignInWithEmailParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) => emit(SignInState.failure(failure)),
      (user) => emit(SignInState.success(user)),
    );
  }

  void _onFormReset(
    FormReset event,
    Emitter<SignInState> emit,
  ) {
    emit(const SignInState.initial());
  }
}
