/// Core use case infrastructure for Clean Architecture.
///
/// This library exports the base `UseCase` abstract class and `NoParams`
/// helper for implementing business logic use cases.
///
/// All use cases should extend `UseCase<T, Params>` and return
/// `Either<Failure, T>` for functional error handling.
library;

export 'use_case.dart';
