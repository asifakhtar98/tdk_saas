import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:tkd_brackets/features/auth/data/datasources/user_local_datasource.dart';
import 'package:tkd_brackets/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:tkd_brackets/features/auth/data/models/user_model.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';

/// Implementation of [AuthRepository] using Supabase Auth.
///
/// This class handles all Supabase-specific error mapping, keeping
/// the domain layer clean from infrastructure concerns.
@LazySingleton(as: AuthRepository)
class AuthRepositoryImplementation implements AuthRepository {
  AuthRepositoryImplementation(
    this._authDatasource,
    this._userRemoteDatasource,
    this._userLocalDatasource,
  );

  final SupabaseAuthDatasource _authDatasource;
  final UserRemoteDatasource _userRemoteDatasource;
  final UserLocalDatasource _userLocalDatasource;

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
  Future<Either<Failure, UserEntity>> verifyMagicLinkOtp({
    required String email,
    required String token,
  }) async {
    try {
      // Step 1: Verify OTP with Supabase
      final authResponse = await _authDatasource.verifyOtp(
        email: email,
        token: token,
        type: OtpType.magiclink,
      );

      // Step 2: Validate we got a user back
      final supabaseUser = authResponse.user;
      if (supabaseUser == null) {
        return const Left(
          OtpVerificationFailure(
            technicalDetails:
                'AuthResponse.user is null after OTP verification',
          ),
        );
      }

      // Step 3: Fetch or create user profile from Supabase (users table)
      // NOTE: getUserById returns UserModel? (nullable)
      final existingUser = await _userRemoteDatasource.getUserById(
        supabaseUser.id,
      );

      UserModel userModel;
      if (existingUser == null) {
        // First-time sign-in: Create user profile from Supabase auth data
        // This happens when user clicked magic link from sign-up flow
        final now = DateTime.now();
        final newUser = UserModel(
          id: supabaseUser.id,
          email: supabaseUser.email ?? email,
          displayName: supabaseUser.userMetadata?['display_name'] as String? ??
              email.split('@').first,
          organizationId: '', // Will be set in Story 2.7 (Create Organization)
          role: 'owner', // Default role for new users
          isActive: true,
          createdAtTimestamp: now,
          updatedAtTimestamp: now,
          syncVersion: 1,
          isDeleted: false,
          isDemoData: false,
          lastSignInAtTimestamp: now,
        );
        userModel = await _userRemoteDatasource.insertUser(newUser);
      } else {
        // Existing user: Update lastSignInAtTimestamp
        // NOTE: Field is lastSignInAtTimestamp, NOT lastLoginAt
        userModel = existingUser.copyWith(
          lastSignInAtTimestamp: DateTime.now(),
          updatedAtTimestamp: DateTime.now(),
        );
        await _userRemoteDatasource.updateUser(userModel);
      }

      // Step 4: Cache user locally
      // Check if user exists locally first
      final localUser = await _userLocalDatasource.getUserById(userModel.id);
      if (localUser != null) {
        await _userLocalDatasource.updateUser(userModel);
      } else {
        await _userLocalDatasource.insertUser(userModel);
      }

      // Step 5: Return the user entity
      return Right(userModel.convertToEntity());
    } on AuthException catch (e) {
      return Left(_mapAuthExceptionForOtp(e));
    } on Exception catch (e) {
      return Left(
        ServerConnectionFailure(
          technicalDetails: 'Exception during OTP verification: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentAuthenticatedUser() async {
    try {
      final supabaseUser = _authDatasource.currentUser;
      if (supabaseUser == null) {
        return const Left(
          UserNotFoundFailure(
            technicalDetails: 'No authenticated user in session',
          ),
        );
      }

      // Try local cache first
      final localUser =
          await _userLocalDatasource.getUserById(supabaseUser.id);
      if (localUser != null) {
        return Right(localUser.convertToEntity());
      }

      // Fallback to remote - NOTE: returns UserModel? (nullable)
      final remoteUser =
          await _userRemoteDatasource.getUserById(supabaseUser.id);
      if (remoteUser == null) {
        return const Left(
          UserNotFoundFailure(
            technicalDetails: 'User profile not found in database',
          ),
        );
      }

      // Cache locally for future use
      await _userLocalDatasource.insertUser(remoteUser);
      return Right(remoteUser.convertToEntity());
    } on Exception catch (e) {
      return Left(
        ServerConnectionFailure(
          technicalDetails: 'Exception: $e',
        ),
      );
    }
  }

  @override
  Stream<Either<Failure, UserEntity?>> get authStateChanges {
    return _authDatasource.onAuthStateChange.asyncMap((authState) async {
      final user = authState.session?.user;
      if (user == null) {
        return const Right<Failure, UserEntity?>(null);
      }

      try {
        // NOTE: returns UserModel? (nullable)
        final userModel = await _userRemoteDatasource.getUserById(user.id);
        if (userModel == null) {
          // User authenticated but no profile yet - valid during sign-up
          return const Right<Failure, UserEntity?>(null);
        }
        return Right<Failure, UserEntity?>(userModel.convertToEntity());
      } on Exception catch (e) {
        return Left<Failure, UserEntity?>(
          ServerConnectionFailure(
            technicalDetails: 'Exception: $e',
          ),
        );
      }
    });
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

  /// Maps Supabase AuthException to domain Failure types for OTP verification.
  Failure _mapAuthExceptionForOtp(AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('expired') || message.contains('otp expired')) {
      return ExpiredTokenFailure(
        technicalDetails: 'Supabase error: ${e.message}',
      );
    }
    if (message.contains('invalid') || message.contains('otp invalid')) {
      return InvalidTokenFailure(
        technicalDetails: 'Supabase error: ${e.message}',
      );
    }
    if (message.contains('user not found')) {
      return UserNotFoundFailure(
        technicalDetails: 'Supabase error: ${e.message}',
      );
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return RateLimitExceededFailure(
        technicalDetails: 'Supabase error: ${e.message}',
      );
    }
    return OtpVerificationFailure(
      technicalDetails: 'AuthException: ${e.message}',
    );
  }
}
