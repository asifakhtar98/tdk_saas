import 'package:flutter/foundation.dart' show immutable;
import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';

/// Abstract base class for all use cases in Clean Architecture.
///
/// Use cases encapsulate a single business action and return
/// [Either<Failure, T>] for functional error handling:
/// - [Left<Failure>] when the operation fails
/// - [Right<T>] when the operation succeeds
///
/// ## Type Parameters
///
/// - [T]: The success return type (e.g., `UserEntity`, `List<Tournament>`)
/// - [Params]: The input parameters type. Use [NoParams] when no input needed.
///
/// ## Example
///
/// ```dart
/// @injectable
/// class GetUserByIdUseCase extends UseCase<UserEntity, String> {
///   final UserRepository _repository;
///
///   GetUserByIdUseCase(this._repository);
///
///   @override
///   Future<Either<Failure, UserEntity>> call(String userId) async {
///     return _repository.getUserById(userId);
///   }
/// }
/// ```
///
/// For use cases with multiple parameters, create a params class:
///
/// ```dart
/// class CreateTournamentParams {
///   final String name;
///   final DateTime date;
///   const CreateTournamentParams({required this.name, required this.date});
/// }
/// ```
abstract class UseCase<T, Params> {
  /// Executes the use case with the given [params].
  ///
  /// Returns [Either<Failure, T>] where:
  /// - [Left] contains a [Failure] describing what went wrong
  /// - [Right] contains the success value of type [T]
  Future<Either<Failure, T>> call(Params params);
}

/// Marker class for use cases that require no input parameters.
///
/// ## Example
///
/// ```dart
/// class GetCurrentUserUseCase extends UseCase<UserEntity, NoParams> {
///   @override
///   Future<Either<Failure, UserEntity>> call(NoParams params) async {
///     return _authRepository.getCurrentUser();
///   }
/// }
///
/// // Usage:
/// final result = await getCurrentUserUseCase(const NoParams());
/// ```
@immutable
class NoParams {
  /// Creates a [NoParams] instance.
  const NoParams();
}
