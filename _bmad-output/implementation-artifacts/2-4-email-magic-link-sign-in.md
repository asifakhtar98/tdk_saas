# Story 2.4: Email Magic Link Sign In

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

**As a** returning user,
**I want** to sign in using email magic link,
**So that** I can access my account securely (FR52).

## Acceptance Criteria

- [x] **AC1**: `SignInWithEmailUseCase` exists in `domain/usecases/` and verifies OTP via `AuthRepository`
- [x] **AC2**: User session is established and persisted after successful OTP verification
- [x] **AC3**: User profile is fetched from Supabase and cached locally in Drift database
- [x] **AC4**: Error cases are handled: expired link, invalid token, user not found, network error
- [x] **AC5**: `Either<Failure, UserEntity>` is returned (success returns the authenticated user)
- [x] **AC6**: Unit tests verify sign-in flow (mocked Supabase)
- [x] **AC7**: `flutter analyze` passes with zero errors for auth feature
- [x] **AC8**: `dart run build_runner build` completes successfully

---

## Project Context

> **⚠️ CRITICAL: All paths are relative to `tkd_brackets/`**
> 
> Project root: `/Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/`
> 
> When creating files, always work within `tkd_brackets/lib/`

---

## Dependencies

### Upstream (Required) ✅

| Story                        | Provides                                                              |
| ---------------------------- | --------------------------------------------------------------------- |
| 2.1 Auth Feature Structure   | Feature directory structure, `UseCase<T, Params>` base class          |
| 2.2 User Entity & Repository | `UserEntity`, `UserRepository`, `UserModel`, local/remote datasources |
| 2.3 Email Magic Link Sign Up | `SupabaseAuthDatasource`, `AuthRepository`, auth failure classes      |
| 1.6 Supabase Client          | `SupabaseClient` instance registered in DI                            |
| 1.4 Error Handling           | `Failure` hierarchy in `core/error/failures.dart`                     |

### Downstream (Enables)

- Story 2.5: Auth State Management (AuthBloc) - consumes sign-in use case
- Story 2.6-2.10: Organization management features

---

## ⚠️ CRITICAL: What Already Exists

> **DO NOT recreate these - they are implemented and working!**

### UseCase Base Class (`lib/core/usecases/use_case.dart`)

```dart
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

class NoParams {
  const NoParams();
}
```

### Auth Repository Interface (`lib/features/auth/domain/repositories/auth_repository.dart`)

```dart
abstract class AuthRepository {
  Future<Either<Failure, Unit>> sendSignUpMagicLink({required String email});
  Future<Either<Failure, Unit>> sendSignInMagicLink({required String email});
  Future<Either<Failure, Unit>> signOut();
}
```

### SupabaseAuthDatasource (`lib/features/auth/data/datasources/supabase_auth_datasource.dart`)

```dart
abstract class SupabaseAuthDatasource {
  Future<void> sendMagicLink({
    required String email,
    required bool shouldCreateUser,
    String? redirectTo,
  });
  
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
  });
  
  User? get currentUser;
  Stream<AuthState> get onAuthStateChange;
  Future<void> signOut();
}
```

### Auth Failure Classes (`lib/core/error/auth_failures.dart`)

```dart
class MagicLinkSendFailure extends Failure { ... }
class InvalidEmailFailure extends Failure { ... }
class RateLimitExceededFailure extends Failure { ... }
```

### User Repository Interface (`lib/features/auth/domain/repositories/user_repository.dart`)

```dart
abstract class UserRepository {
  Future<Either<Failure, UserEntity>> getUserById(String id);
  Future<Either<Failure, UserEntity>> getCurrentUser();
  Future<Either<Failure, UserEntity>> createUser(UserEntity user);
  Future<Either<Failure, UserEntity>> updateUser(UserEntity user);
  // ... other methods
}
```

### User Entity (`lib/features/auth/domain/entities/user_entity.dart`)

```dart
@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String email,
    required String displayName,
    required String organizationId,
    required UserRole role,
    required bool isActive,
    required DateTime createdAt,
    String? avatarUrl,
    DateTime? lastLoginAt,
  }) = _UserEntity;
}
```

---

## ⚠️ CRITICAL: Architecture Constraints

> **These MUST be followed to prevent code review issues!**

### 1. Domain Layer Independence

**❌ NEVER import from data layer in domain usecases:**
```dart
// ❌ WRONG - Violates Clean Architecture
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/features/auth/data/datasources/supabase_auth_datasource.dart';

// ✅ CORRECT - Domain depends only on domain interfaces
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
```

### 2. Repository Pattern

All Supabase/infrastructure operations MUST go through repository. The use case only knows about repository interfaces.

```dart
// ✅ CORRECT pattern from Story 2.3
@injectable
class SignUpWithEmailUseCase extends UseCase<Unit, SignUpWithEmailParams> {
  SignUpWithEmailUseCase(this._authRepository);
  final AuthRepository _authRepository;  // Domain interface!
  
  @override
  Future<Either<Failure, Unit>> call(SignUpWithEmailParams params) async {
    // Validation here
    return _authRepository.sendSignUpMagicLink(email: email);
  }
}
```

### 3. Exception Handling Location

- **Data Layer (Repository Implementation)**: Catches Supabase exceptions, maps to domain Failures
- **Domain Layer (Use Case)**: Only validates input, calls repository, returns Either

---

## Tasks

### Task 1: Add New Failure Classes

**File:** `lib/core/error/auth_failures.dart`

Add the following failure classes for sign-in error cases:

```dart
/// Failure when OTP/magic link token is invalid or malformed.
class InvalidTokenFailure extends Failure {
  const InvalidTokenFailure({
    super.userFriendlyMessage = 'Invalid or malformed link. Please request a new one.',
    super.technicalDetails,
  });
}

/// Failure when magic link has expired (Supabase default: 1 hour).
class ExpiredTokenFailure extends Failure {
  const ExpiredTokenFailure({
    super.userFriendlyMessage = 'This link has expired. Please request a new one.',
    super.technicalDetails,
  });
}

/// Failure when user account is not found.
class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure({
    super.userFriendlyMessage = 'No account found with this email. Please sign up first.',
    super.technicalDetails,
  });
}

/// Failure when OTP verification fails.
class OtpVerificationFailure extends Failure {
  const OtpVerificationFailure({
    super.userFriendlyMessage = 'Verification failed. Please try again.',
    super.technicalDetails,
  });
}
```

---

### Task 2: Extend AuthRepository Interface (Domain Layer)

**File:** `lib/features/auth/domain/repositories/auth_repository.dart`

Add the new method for OTP verification:

```dart
import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

/// Repository interface for authentication operations.
///
/// This is the domain layer contract for auth flows.
/// The data layer provides the concrete implementation.
///
/// Note: This is separate from UserRepository which handles
/// user profile CRUD operations. This repository handles
/// authentication flows (magic link, sessions, etc.).
abstract class AuthRepository {
  /// Send magic link (OTP) to email for sign-up.
  ///
  /// Creates a new user if the email doesn't exist.
  ///
  /// Returns:
  /// - [Right(Unit)] on success - email sent
  /// - [Left(Failure)] on error (invalid email, rate limit, network)
  Future<Either<Failure, Unit>> sendSignUpMagicLink({
    required String email,
  });

  /// Send magic link (OTP) to email for sign-in.
  ///
  /// Only works for existing users.
  ///
  /// Returns:
  /// - [Right(Unit)] on success - email sent
  /// - [Left(Failure)] on error (user not found, rate limit, network)
  Future<Either<Failure, Unit>> sendSignInMagicLink({
    required String email,
  });

  /// Verify OTP token from magic link.
  ///
  /// This completes the sign-in flow:
  /// 1. Validates the OTP with Supabase
  /// 2. Establishes the user session
  /// 3. Fetches user profile from Supabase
  /// 4. Caches user locally
  /// 5. Updates lastLoginAt
  ///
  /// Returns:
  /// - [Right(UserEntity)] on success - authenticated user
  /// - [Left(Failure)] on error (expired, invalid, network)
  Future<Either<Failure, UserEntity>> verifyMagicLinkOtp({
    required String email,
    required String token,
  });

  /// Sign out the current user.
  ///
  /// Returns:
  /// - [Right(Unit)] on success
  /// - [Left(Failure)] on error
  Future<Either<Failure, Unit>> signOut();

  /// Get the currently authenticated user.
  ///
  /// Returns:
  /// - [Right(UserEntity)] if authenticated
  /// - [Left(Failure)] if not authenticated or error
  Future<Either<Failure, UserEntity>> getCurrentAuthenticatedUser();

  /// Stream of authentication state changes.
  ///
  /// Emits [Right(UserEntity)] when signed in, [Left(Failure)] when signed out.
  Stream<Either<Failure, UserEntity?>> get authStateChanges;
}
```

> **⚠️ NOTE:** The import of `user_entity.dart` is necessary here since the method returns `UserEntity`. This is the **domain entity**, not the data model, so it's allowed in the domain layer.

---

### Task 3: Implement AuthRepository Extension (Data Layer)

**File:** `lib/features/auth/data/repositories/auth_repository_implementation.dart`

> **⚠️ CRITICAL IMPLEMENTATION NOTES:**
> 1. `getUserById()` returns `UserModel?` (nullable) - must handle null case
> 2. Use `insertUser()` or `updateUser()` - there is NO `saveUser()` method
> 3. Field name is `lastSignInAtTimestamp` NOT `lastLoginAt`
> 4. For first-time sign-in (from sign-up flow), user may not exist in `users` table yet

Update to implement the new methods. **Only showing NEW/MODIFIED methods** - existing methods from Story 2.3 remain unchanged:

```dart
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

  // ... existing sendSignUpMagicLink, sendSignInMagicLink, signOut methods unchanged ...

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
            technicalDetails: 'AuthResponse.user is null after OTP verification',
          ),
        );
      }

      // Step 3: Fetch or create user profile from Supabase (users table)
      // NOTE: getUserById returns UserModel? (nullable)
      UserModel? existingUser = await _userRemoteDatasource.getUserById(
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
      final localUser = await _userLocalDatasource.getUserById(supabaseUser.id);
      if (localUser != null) {
        return Right(localUser.convertToEntity());
      }

      // Fallback to remote - NOTE: returns UserModel? (nullable)
      final remoteUser = await _userRemoteDatasource.getUserById(supabaseUser.id);
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
          // User authenticated but no profile yet - this is valid during sign-up
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

  // ... existing _mapAuthException method unchanged ...

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
```

> **⚠️ CRITICAL CHANGES FROM ORIGINAL:**
> 1. `getUserById()` returns `UserModel?` - added null checks throughout
> 2. Uses `insertUser()` / `updateUser()` instead of non-existent `saveUser()`
> 3. Uses `lastSignInAtTimestamp` field (correct name from UserModel)
> 4. Added first-time user creation logic for sign-up→sign-in flow
> 5. Constructor takes 3 dependencies - DI will auto-inject

---

### Task 4: Create SignInWithEmailParams (Domain Layer)

**File:** `lib/features/auth/domain/usecases/sign_in_with_email_params.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_in_with_email_params.freezed.dart';

/// Parameters for the email sign-in use cases.
///
/// Used by both [SignInWithEmailUseCase] (send magic link)
/// and [VerifyMagicLinkUseCase] (verify token).
@freezed
class SignInWithEmailParams with _$SignInWithEmailParams {
  const factory SignInWithEmailParams({
    required String email,
  }) = _SignInWithEmailParams;
}
```

---

### Task 5: Create VerifyMagicLinkParams (Domain Layer)

**File:** `lib/features/auth/domain/usecases/verify_magic_link_params.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'verify_magic_link_params.freezed.dart';

/// Parameters for verifying a magic link OTP.
@freezed
class VerifyMagicLinkParams with _$VerifyMagicLinkParams {
  const factory VerifyMagicLinkParams({
    /// The email address the magic link was sent to.
    required String email,
    
    /// The OTP token from the magic link URL.
    required String token,
  }) = _VerifyMagicLinkParams;
}
```

---

### Task 6: Create SignInWithEmailUseCase (Domain Layer)

**File:** `lib/features/auth/domain/usecases/sign_in_with_email_use_case.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_in_with_email_params.dart';

/// Use case to send magic link for existing user sign-in.
///
/// This use case:
/// 1. Validates the email format
/// 2. Delegates to [AuthRepository] to send the magic link
/// 3. Returns success/failure
///
/// The user will receive an email with a magic link.
/// When clicked, use [VerifyMagicLinkUseCase] to complete sign-in.
///
/// Note: Unlike [SignUpWithEmailUseCase], this will fail if the user
/// doesn't exist (shouldCreateUser: false).
@injectable
class SignInWithEmailUseCase extends UseCase<Unit, SignInWithEmailParams> {
  SignInWithEmailUseCase(this._authRepository);

  final AuthRepository _authRepository;

  // Email regex pattern (RFC 5322 simplified)
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  Future<Either<Failure, Unit>> call(SignInWithEmailParams params) async {
    // Validate email format
    final email = params.email.trim().toLowerCase();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      return const Left(
        InvalidEmailFailure(
          technicalDetails: 'Email failed regex validation',
        ),
      );
    }

    // Delegate to repository (which handles infrastructure concerns)
    return _authRepository.sendSignInMagicLink(email: email);
  }
}
```

---

### Task 7: Create VerifyMagicLinkUseCase (Domain Layer)

**File:** `lib/features/auth/domain/usecases/verify_magic_link_use_case.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/verify_magic_link_params.dart';

/// Use case to verify magic link OTP and complete sign-in.
///
/// This use case:
/// 1. Validates the input parameters
/// 2. Delegates to [AuthRepository] for OTP verification
/// 3. Returns the authenticated user on success
///
/// The repository handles:
/// - OTP verification with Supabase
/// - Session establishment
/// - User profile fetching
/// - Local caching
/// - lastLoginAt update
@injectable
class VerifyMagicLinkUseCase extends UseCase<UserEntity, VerifyMagicLinkParams> {
  VerifyMagicLinkUseCase(this._authRepository);

  final AuthRepository _authRepository;

  // Email regex pattern (RFC 5322 simplified)
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  Future<Either<Failure, UserEntity>> call(VerifyMagicLinkParams params) async {
    // Validate email format
    final email = params.email.trim().toLowerCase();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      return const Left(
        InvalidEmailFailure(
          technicalDetails: 'Email failed regex validation',
        ),
      );
    }

    // Validate token is not empty
    final token = params.token.trim();
    if (token.isEmpty) {
      return const Left(
        InvalidTokenFailure(
          technicalDetails: 'Token is empty',
        ),
      );
    }

    // Delegate to repository
    return _authRepository.verifyMagicLinkOtp(
      email: email,
      token: token,
    );
  }
}
```

---

### Task 8: Update Auth Feature Barrel File

**File:** `lib/features/auth/auth.dart`

Add exports for the new files (keep alphabetical order):

```dart
/// Authentication feature - exports public APIs.
library;

// Data - Datasources (for DI visibility)
export 'data/datasources/supabase_auth_datasource.dart';
export 'data/datasources/user_local_datasource.dart';
export 'data/datasources/user_remote_datasource.dart';

// Data - Models
export 'data/models/user_model.dart';

// Data - Repositories
export 'data/repositories/auth_repository_implementation.dart';
export 'data/repositories/user_repository_implementation.dart';

// Domain - Entities
export 'domain/entities/user_entity.dart';

// Domain - Repositories
export 'domain/repositories/auth_repository.dart';
export 'domain/repositories/user_repository.dart';

// Domain - Use Cases
export 'domain/usecases/sign_in_with_email_params.dart';
export 'domain/usecases/sign_in_with_email_use_case.dart';
export 'domain/usecases/sign_up_with_email_params.dart';
export 'domain/usecases/sign_up_with_email_use_case.dart';
export 'domain/usecases/verify_magic_link_params.dart';
export 'domain/usecases/verify_magic_link_use_case.dart';
```

---

### Task 9: Write Unit Tests for Use Cases

**File:** `test/features/auth/domain/usecases/sign_in_with_email_use_case_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_in_with_email_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_in_with_email_use_case.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late SignInWithEmailUseCase useCase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = SignInWithEmailUseCase(mockAuthRepository);
  });

  group('SignInWithEmailUseCase', () {
    const validEmail = 'test@example.com';
    const invalidEmail = 'invalid-email';
    const emptyEmail = '';

    group('email validation', () {
      test('returns InvalidEmailFailure for empty email', () async {
        // Act
        final result = await useCase(
          const SignInWithEmailParams(email: emptyEmail),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InvalidEmailFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockAuthRepository);
      });

      test('returns InvalidEmailFailure for invalid email format', () async {
        // Act
        final result = await useCase(
          const SignInWithEmailParams(email: invalidEmail),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InvalidEmailFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockAuthRepository);
      });

      test('trims and lowercases email before validation', () async {
        // Arrange
        when(
          () => mockAuthRepository.sendSignInMagicLink(
            email: any(named: 'email'),
          ),
        ).thenAnswer((_) async => const Right(unit));

        // Act
        await useCase(
          const SignInWithEmailParams(email: '  TEST@EXAMPLE.COM  '),
        );

        // Assert
        verify(
          () => mockAuthRepository.sendSignInMagicLink(
            email: 'test@example.com',
          ),
        ).called(1);
      });
    });

    group('successful magic link send', () {
      test('returns Right(unit) on successful magic link send', () async {
        // Arrange
        when(
          () => mockAuthRepository.sendSignInMagicLink(
            email: any(named: 'email'),
          ),
        ).thenAnswer((_) async => const Right(unit));

        // Act
        final result = await useCase(
          const SignInWithEmailParams(email: validEmail),
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (value) => expect(value, unit),
        );
        verify(
          () => mockAuthRepository.sendSignInMagicLink(
            email: validEmail,
          ),
        ).called(1);
      });
    });

    group('error handling', () {
      test('returns UserNotFoundFailure when user does not exist', () async {
        // Arrange
        when(
          () => mockAuthRepository.sendSignInMagicLink(
            email: any(named: 'email'),
          ),
        ).thenAnswer(
          (_) async => const Left(
            UserNotFoundFailure(technicalDetails: 'User not found'),
          ),
        );

        // Act
        final result = await useCase(
          const SignInWithEmailParams(email: validEmail),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<UserNotFoundFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns RateLimitExceededFailure for rate limit error', () async {
        // Arrange
        when(
          () => mockAuthRepository.sendSignInMagicLink(
            email: any(named: 'email'),
          ),
        ).thenAnswer(
          (_) async => const Left(
            RateLimitExceededFailure(technicalDetails: 'Rate limit'),
          ),
        );

        // Act
        final result = await useCase(
          const SignInWithEmailParams(email: validEmail),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<RateLimitExceededFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });
  });
}
```

**File:** `test/features/auth/domain/usecases/verify_magic_link_use_case_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/verify_magic_link_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/verify_magic_link_use_case.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late VerifyMagicLinkUseCase useCase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = VerifyMagicLinkUseCase(mockAuthRepository);
  });

  final testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    organizationId: 'org-123',
    role: UserRole.owner,
    isActive: true,
    createdAt: DateTime.now(),
    lastLoginAt: DateTime.now(),
  );

  group('VerifyMagicLinkUseCase', () {
    const validEmail = 'test@example.com';
    const validToken = '123456';
    const invalidEmail = 'invalid-email';
    const emptyEmail = '';
    const emptyToken = '';

    group('validation', () {
      test('returns InvalidEmailFailure for empty email', () async {
        // Act
        final result = await useCase(
          const VerifyMagicLinkParams(email: emptyEmail, token: validToken),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InvalidEmailFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockAuthRepository);
      });

      test('returns InvalidEmailFailure for invalid email format', () async {
        // Act
        final result = await useCase(
          const VerifyMagicLinkParams(email: invalidEmail, token: validToken),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InvalidEmailFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockAuthRepository);
      });

      test('returns InvalidTokenFailure for empty token', () async {
        // Act
        final result = await useCase(
          const VerifyMagicLinkParams(email: validEmail, token: emptyToken),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InvalidTokenFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockAuthRepository);
      });

      test('trims email and token before processing', () async {
        // Arrange
        when(
          () => mockAuthRepository.verifyMagicLinkOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        // Act
        await useCase(
          const VerifyMagicLinkParams(
            email: '  TEST@EXAMPLE.COM  ',
            token: '  123456  ',
          ),
        );

        // Assert
        verify(
          () => mockAuthRepository.verifyMagicLinkOtp(
            email: 'test@example.com',
            token: '123456',
          ),
        ).called(1);
      });
    });

    group('successful verification', () {
      test('returns Right(UserEntity) on successful verification', () async {
        // Arrange
        when(
          () => mockAuthRepository.verifyMagicLinkOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        // Act
        final result = await useCase(
          const VerifyMagicLinkParams(email: validEmail, token: validToken),
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (user) {
            expect(user.id, equals(testUser.id));
            expect(user.email, equals(testUser.email));
          },
        );
      });
    });

    group('error handling', () {
      test('returns ExpiredTokenFailure for expired token', () async {
        // Arrange
        when(
          () => mockAuthRepository.verifyMagicLinkOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
          ),
        ).thenAnswer(
          (_) async => const Left(
            ExpiredTokenFailure(technicalDetails: 'Token expired'),
          ),
        );

        // Act
        final result = await useCase(
          const VerifyMagicLinkParams(email: validEmail, token: validToken),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ExpiredTokenFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns InvalidTokenFailure for invalid token', () async {
        // Arrange
        when(
          () => mockAuthRepository.verifyMagicLinkOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
          ),
        ).thenAnswer(
          (_) async => const Left(
            InvalidTokenFailure(technicalDetails: 'Invalid token'),
          ),
        );

        // Act
        final result = await useCase(
          const VerifyMagicLinkParams(email: validEmail, token: validToken),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InvalidTokenFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns OtpVerificationFailure for general verification error', () async {
        // Arrange
        when(
          () => mockAuthRepository.verifyMagicLinkOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
          ),
        ).thenAnswer(
          (_) async => const Left(
            OtpVerificationFailure(technicalDetails: 'Verification failed'),
          ),
        );

        // Act
        final result = await useCase(
          const VerifyMagicLinkParams(email: validEmail, token: validToken),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<OtpVerificationFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });
  });
}
```

---

### Task 10: Write Unit Tests for Repository Implementation

**File:** `test/features/auth/data/repositories/auth_repository_implementation_test.dart`

> **⚠️ CRITICAL:** This is a complete test file with proper setup. The existing test file needs these mock classes added and tests for the new methods.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:tkd_brackets/features/auth/data/datasources/user_local_datasource.dart';
import 'package:tkd_brackets/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:tkd_brackets/features/auth/data/models/user_model.dart';
import 'package:tkd_brackets/features/auth/data/repositories/auth_repository_implementation.dart';

// Mock classes
class MockSupabaseAuthDatasource extends Mock implements SupabaseAuthDatasource {}
class MockUserRemoteDatasource extends Mock implements UserRemoteDatasource {}
class MockUserLocalDatasource extends Mock implements UserLocalDatasource {}

// Fake classes for mocktail registration
class FakeUserModel extends Fake implements UserModel {}

void main() {
  late MockSupabaseAuthDatasource mockAuthDatasource;
  late MockUserRemoteDatasource mockUserRemoteDatasource;
  late MockUserLocalDatasource mockUserLocalDatasource;
  late AuthRepositoryImplementation repository;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeUserModel());
    registerFallbackValue(OtpType.magiclink);
  });

  setUp(() {
    mockAuthDatasource = MockSupabaseAuthDatasource();
    mockUserRemoteDatasource = MockUserRemoteDatasource();
    mockUserLocalDatasource = MockUserLocalDatasource();
    repository = AuthRepositoryImplementation(
      mockAuthDatasource,
      mockUserRemoteDatasource,
      mockUserLocalDatasource,
    );
  });

  // ... existing tests for sendSignUpMagicLink, sendSignInMagicLink, signOut ...

  group('verifyMagicLinkOtp', () {
    const testEmail = 'test@example.com';
    const testToken = '123456';
    
    // Create mock user for Supabase response
    late User mockSupabaseUser;
    late AuthResponse mockAuthResponse;
    
    setUp(() {
      mockSupabaseUser = User(
        id: 'user-123',
        appMetadata: {},
        userMetadata: {'display_name': 'Test User'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: testEmail,
      );
      mockAuthResponse = AuthResponse(user: mockSupabaseUser, session: null);
    });
    
    // NOTE: UserModel uses lastSignInAtTimestamp, NOT lastLoginAt
    final testUserModel = UserModel(
      id: 'user-123',
      email: testEmail,
      displayName: 'Test User',
      organizationId: 'org-123',
      role: 'owner',
      isActive: true,
      createdAtTimestamp: DateTime.now(),
      updatedAtTimestamp: DateTime.now(),
      syncVersion: 1,
      isDeleted: false,
      isDemoData: false,
      lastSignInAtTimestamp: null, // CORRECT field name
    );

    test('returns UserEntity on successful OTP verification (existing user)', () async {
      // Arrange
      when(
        () => mockAuthDatasource.verifyOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => mockAuthResponse);
      
      // getUserById returns UserModel? - existing user case
      when(
        () => mockUserRemoteDatasource.getUserById(any()),
      ).thenAnswer((_) async => testUserModel);
      
      when(
        () => mockUserRemoteDatasource.updateUser(any()),
      ).thenAnswer((_) async => testUserModel);
      
      // getUserById for local returns null (not cached yet)
      when(
        () => mockUserLocalDatasource.getUserById(any()),
      ).thenAnswer((_) async => null);
      
      // NOTE: Use insertUser, NOT saveUser (saveUser doesn't exist!)
      when(
        () => mockUserLocalDatasource.insertUser(any()),
      ).thenAnswer((_) async {});

      // Act
      final result = await repository.verifyMagicLinkOtp(
        email: testEmail,
        token: testToken,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (user) {
          expect(user.id, equals('user-123'));
          expect(user.email, equals(testEmail));
        },
      );
      
      // Verify updateUser was called (existing user)
      verify(() => mockUserRemoteDatasource.updateUser(any())).called(1);
      // Verify insertUser was called for local cache
      verify(() => mockUserLocalDatasource.insertUser(any())).called(1);
    });

    test('creates new user on first sign-in (from sign-up flow)', () async {
      // Arrange
      when(
        () => mockAuthDatasource.verifyOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => mockAuthResponse);
      
      // getUserById returns null - first-time user!
      when(
        () => mockUserRemoteDatasource.getUserById(any()),
      ).thenAnswer((_) async => null);
      
      // insertUser is called to create the new user
      when(
        () => mockUserRemoteDatasource.insertUser(any()),
      ).thenAnswer((_) async => testUserModel);
      
      when(
        () => mockUserLocalDatasource.getUserById(any()),
      ).thenAnswer((_) async => null);
      
      when(
        () => mockUserLocalDatasource.insertUser(any()),
      ).thenAnswer((_) async {});

      // Act
      final result = await repository.verifyMagicLinkOtp(
        email: testEmail,
        token: testToken,
      );

      // Assert
      expect(result.isRight(), isTrue);
      
      // Verify insertUser was called for remote (new user)
      verify(() => mockUserRemoteDatasource.insertUser(any())).called(1);
      // Verify updateUser was NOT called
      verifyNever(() => mockUserRemoteDatasource.updateUser(any()));
    });

    test('updates local cache if user already exists locally', () async {
      // Arrange
      when(
        () => mockAuthDatasource.verifyOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => mockAuthResponse);
      
      when(
        () => mockUserRemoteDatasource.getUserById(any()),
      ).thenAnswer((_) async => testUserModel);
      
      when(
        () => mockUserRemoteDatasource.updateUser(any()),
      ).thenAnswer((_) async => testUserModel);
      
      // User exists locally
      when(
        () => mockUserLocalDatasource.getUserById(any()),
      ).thenAnswer((_) async => testUserModel);
      
      // updateUser should be called, not insertUser
      when(
        () => mockUserLocalDatasource.updateUser(any()),
      ).thenAnswer((_) async {});

      // Act
      await repository.verifyMagicLinkOtp(
        email: testEmail,
        token: testToken,
      );

      // Assert: updateUser called for local, not insertUser
      verify(() => mockUserLocalDatasource.updateUser(any())).called(1);
      verifyNever(() => mockUserLocalDatasource.insertUser(any()));
    });

    test('returns OtpVerificationFailure when AuthResponse.user is null', () async {
      // Arrange
      when(
        () => mockAuthDatasource.verifyOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => const AuthResponse());

      // Act
      final result = await repository.verifyMagicLinkOtp(
        email: testEmail,
        token: testToken,
      );

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<OtpVerificationFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns ExpiredTokenFailure for expired OTP', () async {
      // Arrange
      when(
        () => mockAuthDatasource.verifyOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
          type: any(named: 'type'),
        ),
      ).thenThrow(const AuthException('Token has expired'));

      // Act
      final result = await repository.verifyMagicLinkOtp(
        email: testEmail,
        token: testToken,
      );

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ExpiredTokenFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns InvalidTokenFailure for invalid OTP', () async {
      // Arrange
      when(
        () => mockAuthDatasource.verifyOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
          type: any(named: 'type'),
        ),
      ).thenThrow(const AuthException('Invalid OTP'));

      // Act
      final result = await repository.verifyMagicLinkOtp(
        email: testEmail,
        token: testToken,
      );

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<InvalidTokenFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns ServerConnectionFailure for network error', () async {
      // Arrange
      when(
        () => mockAuthDatasource.verifyOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
          type: any(named: 'type'),
        ),
      ).thenThrow(Exception('Network error'));

      // Act
      final result = await repository.verifyMagicLinkOtp(
        email: testEmail,
        token: testToken,
      );

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerConnectionFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('getCurrentAuthenticatedUser', () {
    test('returns UserNotFoundFailure when no session exists', () async {
      // Arrange
      when(() => mockAuthDatasource.currentUser).thenReturn(null);

      // Act
      final result = await repository.getCurrentAuthenticatedUser();

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UserNotFoundFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns UserEntity from local cache when available', () async {
      // Arrange
      final mockUser = User(
        id: 'user-123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      
      final localUserModel = UserModel(
        id: 'user-123',
        email: 'test@example.com',
        displayName: 'Test User',
        organizationId: 'org-123',
        role: 'owner',
        isActive: true,
        createdAtTimestamp: DateTime.now(),
        updatedAtTimestamp: DateTime.now(),
        syncVersion: 1,
        isDeleted: false,
        isDemoData: false,
      );
      
      when(() => mockAuthDatasource.currentUser).thenReturn(mockUser);
      when(
        () => mockUserLocalDatasource.getUserById(any()),
      ).thenAnswer((_) async => localUserModel);

      // Act
      final result = await repository.getCurrentAuthenticatedUser();

      // Assert
      expect(result.isRight(), isTrue);
      // Remote should NOT be called when local cache exists
      verifyNever(() => mockUserRemoteDatasource.getUserById(any()));
    });

    test('fetches from remote and caches when not in local', () async {
      // Arrange
      final mockUser = User(
        id: 'user-123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      
      final remoteUserModel = UserModel(
        id: 'user-123',
        email: 'test@example.com',
        displayName: 'Test User',
        organizationId: 'org-123',
        role: 'owner',
        isActive: true,
        createdAtTimestamp: DateTime.now(),
        updatedAtTimestamp: DateTime.now(),
        syncVersion: 1,
        isDeleted: false,
        isDemoData: false,
      );
      
      when(() => mockAuthDatasource.currentUser).thenReturn(mockUser);
      when(
        () => mockUserLocalDatasource.getUserById(any()),
      ).thenAnswer((_) async => null);
      when(
        () => mockUserRemoteDatasource.getUserById(any()),
      ).thenAnswer((_) async => remoteUserModel);
      when(
        () => mockUserLocalDatasource.insertUser(any()),
      ).thenAnswer((_) async {});

      // Act
      final result = await repository.getCurrentAuthenticatedUser();

      // Assert
      expect(result.isRight(), isTrue);
      verify(() => mockUserRemoteDatasource.getUserById(any())).called(1);
      verify(() => mockUserLocalDatasource.insertUser(any())).called(1);
    });

    test('returns UserNotFoundFailure when user not in database', () async {
      // Arrange
      final mockUser = User(
        id: 'user-123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      
      when(() => mockAuthDatasource.currentUser).thenReturn(mockUser);
      when(
        () => mockUserLocalDatasource.getUserById(any()),
      ).thenAnswer((_) async => null);
      // Remote also returns null
      when(
        () => mockUserRemoteDatasource.getUserById(any()),
      ).thenAnswer((_) async => null);

      // Act
      final result = await repository.getCurrentAuthenticatedUser();

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UserNotFoundFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
```

> **⚠️ CRITICAL TEST FIXES:**
> 1. Uses `insertUser()` / `updateUser()` instead of non-existent `saveUser()`
> 2. Uses `lastSignInAtTimestamp` field (correct name from UserModel)
> 3. Added test for first-time user creation (from sign-up flow)
> 4. Added test for getUserById returning null from remote
> 5. Complete mock setup with all required classes

---

### Task 11: Integration Verification

```bash
# From tkd_brackets/ directory:

# Generate freezed/injectable code
dart run build_runner build --delete-conflicting-outputs

# Run static analysis
flutter analyze

# Run auth tests
flutter test test/features/auth/

# Optionally build to verify no runtime issues
flutter build web --release -t lib/main_development.dart
```

All must pass with zero errors.

---

## Dev Notes

### Magic Link Verification Flow

1. **Send Magic Link** (Story 2.3 - Sign Up, This Story - Sign In):
   - User enters email
   - `SignInWithEmailUseCase` delegates to repository
   - Repository calls `sendMagicLink(shouldCreateUser: false)`
   - Supabase sends email with magic link

2. **Magic Link Click** (This Story):
   - User clicks link → app receives token
   - `VerifyMagicLinkUseCase` validates input
   - Repository calls `verifyOtp()` with Supabase
   - Session established, user profile fetched
   - User cached locally, `lastLoginAt` updated

### Supabase OTP Verification

| Parameter    | Value                     |
| ------------ | ------------------------- |
| Token Type   | `OtpType.magiclink`       |
| Token Expiry | 1 hour (Supabase default) |
| Max Attempts | 3 per token               |

### Error Mapping Reference

| Supabase Error            | Domain Failure             |
| ------------------------- | -------------------------- |
| `expired` / `otp expired` | `ExpiredTokenFailure`      |
| `invalid` / `otp invalid` | `InvalidTokenFailure`      |
| `user not found`          | `UserNotFoundFailure`      |
| `rate limit` / `too many` | `RateLimitExceededFailure` |
| Other `AuthException`     | `OtpVerificationFailure`   |
| Network/other `Exception` | `ServerConnectionFailure`  |

### Architecture Notes

- **Repository Pattern Extended**: `AuthRepository` now handles complete auth flow
- **Domain Independence**: Use cases depend only on repository interfaces
- **Error Mapping Location**: All Supabase-specific error mapping in `AuthRepositoryImplementation`
- **User Caching**: Session user is cached locally for offline access

### Files Modified vs Created

| Type         | File                                                                                  |
| ------------ | ------------------------------------------------------------------------------------- |
| **Modified** | `lib/core/error/auth_failures.dart` (add new failures)                                |
| **Modified** | `lib/features/auth/domain/repositories/auth_repository.dart` (add method)             |
| **Modified** | `lib/features/auth/data/repositories/auth_repository_implementation.dart` (implement) |
| **Modified** | `lib/features/auth/auth.dart` (add exports)                                           |
| **Created**  | `lib/features/auth/domain/usecases/sign_in_with_email_params.dart`                    |
| **Created**  | `lib/features/auth/domain/usecases/sign_in_with_email_use_case.dart`                  |
| **Created**  | `lib/features/auth/domain/usecases/verify_magic_link_params.dart`                     |
| **Created**  | `lib/features/auth/domain/usecases/verify_magic_link_use_case.dart`                   |
| **Created**  | Unit test files (see below)                                                           |

### ⚠️ CRITICAL Implementation Warnings

> **These are the most common issues that can cause runtime failures!**

1. **Nullable Returns from Datasources:**
   - `getUserById()` returns `UserModel?` (nullable) - ALWAYS check for null
   - Don't assume user exists in `users` table after OTP verification

2. **Correct Method Names:**
   - Use `insertUser()` or `updateUser()` - there is NO `saveUser()` method
   - Check if user exists locally before deciding which to call

3. **Correct Field Names:**
   - Field is `lastSignInAtTimestamp` NOT `lastLoginAt`
   - Field is `createdAtTimestamp` NOT `createdAt`
   - Field is `updatedAtTimestamp` NOT `updatedAt`

4. **First-Time Sign-In Flow:**
   - When user clicks magic link from sign-up, their profile may NOT exist in `users` table yet
   - Must check for null and create profile if needed using data from Supabase auth

### Future Optimization: Shared Email Validator

> **Note:** Email regex is duplicated in `SignInWithEmailUseCase` and `VerifyMagicLinkUseCase`.
> Consider extracting to a shared validator in future cleanup:

```dart
// lib/core/validators/email_validator.dart
class EmailValidator {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  static bool isValid(String email) => _emailRegex.hasMatch(email.trim());
}
```

### Common Mistakes to Avoid

| ❌ Don't                       | ✅ Do                                |
| ----------------------------- | ----------------------------------- |
| Import Supabase in use case   | Only import domain interfaces       |
| Call datasource from use case | Call repository from use case       |
| Return raw exceptions         | Map to domain Failure types         |
| Skip email/token validation   | Validate before calling repository  |
| Forget to cache user locally  | Cache after successful verification |
| Forget to update lastLoginAt  | Update before caching               |

---

## Checklist

### Pre-Implementation
- [ ] Verify Story 2.3 is complete (Email Magic Link Sign Up)
- [ ] Review existing `auth_failures.dart` for failure classes
- [ ] Check `AuthRepository` interface for existing methods
- [ ] Review `SupabaseAuthDatasource` for `verifyOtp` method signature

### Implementation
- [ ] Task 1: Add new failure classes to `auth_failures.dart`
- [ ] Task 2: Extend `AuthRepository` interface with `verifyMagicLinkOtp`
- [ ] Task 3: Implement `verifyMagicLinkOtp` in `AuthRepositoryImplementation`
- [ ] Task 4: Create `SignInWithEmailParams` with freezed
- [ ] Task 5: Create `VerifyMagicLinkParams` with freezed
- [ ] Task 6: Create `SignInWithEmailUseCase`
- [ ] Task 7: Create `VerifyMagicLinkUseCase`
- [ ] Task 8: Update auth barrel file with exports
- [ ] Task 9: Write use case unit tests
- [ ] Task 10: Update repository implementation tests
- [ ] Task 11: Run build_runner, analyze, and tests

### Post-Implementation
- [ ] `flutter analyze` - zero errors in auth feature
- [ ] `flutter test test/features/auth/` - all pass
- [ ] `flutter build web --release -t lib/main_development.dart` - succeeds
- [ ] Update story status to `done` (after code review)

---

## Architecture References

| Document          | Relevant Sections                                                                   |
| ----------------- | ----------------------------------------------------------------------------------- |
| `architecture.md` | Auth Feature (1069-1100), Failures (812-898), Use Cases (900-929), Naming (932-983) |
| `epics.md`        | Story 2.4 (984-998), Epic 2 Overview (915-1119)                                     |
| Story 2.3         | `SupabaseAuthDatasource`, `AuthRepository` patterns                                 |
| Story 2.2         | `UserModel`, `UserRepository`, local/remote datasource patterns                     |

---

## File Manifest

### New Files to Create

| File                                                                       | Purpose                  |
| -------------------------------------------------------------------------- | ------------------------ |
| `lib/features/auth/domain/usecases/sign_in_with_email_params.dart`         | Sign-in params           |
| `lib/features/auth/domain/usecases/sign_in_with_email_use_case.dart`       | Send magic link use case |
| `lib/features/auth/domain/usecases/verify_magic_link_params.dart`          | Verify params            |
| `lib/features/auth/domain/usecases/verify_magic_link_use_case.dart`        | Verify OTP use case      |
| `test/features/auth/domain/usecases/sign_in_with_email_use_case_test.dart` | Sign-in tests            |
| `test/features/auth/domain/usecases/verify_magic_link_use_case_test.dart`  | Verify tests             |

### Files to Modify

| File                                                                            | Modification              |
| ------------------------------------------------------------------------------- | ------------------------- |
| `lib/core/error/auth_failures.dart`                                             | Add new failure classes   |
| `lib/features/auth/domain/repositories/auth_repository.dart`                    | Add new methods           |
| `lib/features/auth/data/repositories/auth_repository_implementation.dart`       | Implement new methods     |
| `lib/features/auth/auth.dart`                                                   | Add exports for new files |
| `test/features/auth/data/repositories/auth_repository_implementation_test.dart` | Add tests for new method  |

---

## Agent Record

| Field        | Value                                 |
| ------------ | ------------------------------------- |
| Created By   | create-story workflow                 |
| Created At   | 2026-02-09                            |
| Source Epic  | Epic 2: Authentication & Organization |
| Story Points | 5                                     |

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List

### Change Log
