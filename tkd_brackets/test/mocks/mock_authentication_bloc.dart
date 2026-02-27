import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_state.dart';

/// Mock for AuthenticationBloc using mocktail.
///
/// Shared mock for use across all tests requiring
/// AuthenticationBloc (router tests, widget tests, etc.).
class MockAuthenticationBloc extends Mock implements AuthenticationBloc {
  final _stateController = StreamController<AuthenticationState>.broadcast();

  AuthenticationState _state = const AuthenticationState.initial();

  @override
  AuthenticationState get state => _state;

  @override
  Stream<AuthenticationState> get stream => _stateController.stream;

  @override
  Future<void> close() async {
    await _stateController.close();
  }

  /// Simulate a state transition for testing.
  void emitState(AuthenticationState newState) {
    _state = newState;
    _stateController.add(newState);
  }
}

/// Creates a configured mock AuthenticationBloc with
/// sensible defaults.
///
/// Returns the mock with initial state set. Use
/// [MockAuthenticationBloc.emitState] to change state during tests.
///
/// Example usage:
/// ```dart
/// late MockAuthenticationBloc mockAuthBloc;
///
/// setUp(() {
///   mockAuthBloc = createMockAuthenticationBloc();
///   GetIt.instance.registerSingleton<AuthenticationBloc>(
///     mockAuthBloc,
///   );
/// });
/// ```
MockAuthenticationBloc createMockAuthenticationBloc({
  AuthenticationState initialState = const AuthenticationState.initial(),
}) {
  final mock = MockAuthenticationBloc()
    .._state = initialState;

  when(() => mock.isClosed).thenReturn(false);

  return mock;
}
