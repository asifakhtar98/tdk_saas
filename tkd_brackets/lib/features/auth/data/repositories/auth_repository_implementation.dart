import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';

/// Implementation of [AuthRepository] using Supabase Auth.
///
/// This class handles all Supabase-specific error mapping, keeping
/// the domain layer clean from infrastructure concerns.
@LazySingleton(as: AuthRepository)
class AuthRepositoryImplementation implements AuthRepository {
  AuthRepositoryImplementation(this._authDatasource);

  final SupabaseAuthDatasource _authDatasource;

  @override
  Future<Either<Failure, Unit>> sendSignUpMagicLink({
    required String email,
  }) async {
    try {
      await _authDatasource.sendMagicLink(
        email: email,
        shouldCreateUser: true,
      );
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } on Exception catch (e) {
      return Left(
        ServerConnectionFailure(
          technicalDetails: 'Exception: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> sendSignInMagicLink({
    required String email,
  }) async {
    try {
      await _authDatasource.sendMagicLink(
        email: email,
        shouldCreateUser: false,
      );
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } on Exception catch (e) {
      return Left(
        ServerConnectionFailure(
          technicalDetails: 'Exception: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _authDatasource.signOut();
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } on Exception catch (e) {
      return Left(
        ServerConnectionFailure(
          technicalDetails: 'Exception: $e',
        ),
      );
    }
  }

  /// Maps Supabase AuthException to domain Failure types.
  Failure _mapAuthException(AuthException e) {
    if (e.message.contains('rate limit') ||
        e.message.contains('too many requests')) {
      return RateLimitExceededFailure(
        technicalDetails: 'Supabase rate limit: ${e.message}',
      );
    }
    return MagicLinkSendFailure(
      technicalDetails: 'AuthException: ${e.message}',
    );
  }
}
