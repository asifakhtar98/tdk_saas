import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String userFriendlyMessage;
  final String? technicalDetails;
  
  const Failure({
    required this.message,
    this.userFriendlyMessage = 'An error occurred',
    this.technicalDetails,
  });

  @override
  List<Object?> get props => [message, userFriendlyMessage, technicalDetails];
}

class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Server Error',
    super.userFriendlyMessage = 'A server error occurred',
    super.technicalDetails,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Cache Error',
    super.userFriendlyMessage = 'A cache error occurred',
    super.technicalDetails,
  });
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({
    super.message = 'Database Error',
    super.userFriendlyMessage = 'A database error occurred',
    super.technicalDetails,
  });
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'Validation Error',
    super.userFriendlyMessage = 'Validation failed',
    super.technicalDetails,
  });
}
