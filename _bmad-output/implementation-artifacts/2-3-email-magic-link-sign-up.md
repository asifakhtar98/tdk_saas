# Story 2.3: Email Magic Link Sign Up

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

**As a** new user,
**I want** to sign up using email magic link (OTP),
**So that** I can create an account without remembering a password (FR51).

## Acceptance Criteria

- [x] **AC1**: `SignUpWithEmailUseCase` exists in `domain/usecases/` and sends magic link via Supabase Auth
- [x] **AC2**: `SupabaseAuthDatasource` (new) handles the `signInWithOtp()` call with `shouldCreateUser: true`
- [x] **AC3**: Error cases are handled: invalid email, rate limit, network error
- [x] **AC4**: `Either<Failure, Unit>` is returned for success/failure
- [x] **AC5**: Unit tests verify magic link request flow (mocked Supabase)
- [x] **AC6**: `flutter analyze` passes with zero errors for auth feature
- [x] **AC7**: `dart run build_runner build` completes successfully

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

| Story                        | Provides                                                         |
| ---------------------------- | ---------------------------------------------------------------- |
| 2.1 Auth Feature Structure   | Feature directory structure, `UseCase<T, Params>` base class     |
| 2.2 User Entity & Repository | `UserEntity`, `UserRepository`, `UserRemoteDatasource` for users |
| 1.6 Supabase Client          | `SupabaseClient` instance registered in DI                       |
| 1.4 Error Handling           | `Failure` hierarchy in `core/error/failures.dart`                |

### Downstream (Enables)

- Story 2.4: Email Magic Link Sign In (consumes `SupabaseAuthDatasource`)
- Story 2.5: Auth State Management (AuthBloc) (consumes auth use cases)
- Story 2.7-2.10: Organization and user management features

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

### Failure Classes (`lib/core/error/failures.dart`)

```dart
// Available failures to use:
ServerConnectionFailure   // Network errors - no internet
ServerResponseFailure     // API errors (with statusCode)
InputValidationFailure    // Validation errors (with fieldErrors map)
```

### Supabase Client (via DI)

```dart
// Access via: getIt<SupabaseClient>()
// Already registered in lib/core/di/register_module.dart
```

### User Remote Datasource (`lib/features/auth/data/datasources/user_remote_datasource.dart`)

```dart
// Access to current auth user and auth state changes:
User? get currentAuthUser => _supabase.auth.currentUser;
Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
```

---

## Tasks

### Task 1: Create SignUpWithEmailParams (Domain Layer)

**File:** `lib/features/auth/domain/usecases/sign_up_with_email_params.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_up_with_email_params.freezed.dart';

/// Parameters for the SignUpWithEmailUseCase.
@freezed
class SignUpWithEmailParams with _$SignUpWithEmailParams {
  const factory SignUpWithEmailParams({
    required String email,
  }) = _SignUpWithEmailParams;
}
```

> **⚠️ NOTE:** Use `class` NOT `abstract class` - this is the project's freezed pattern (see `UserEntity`).

---

### Task 2: Create SupabaseAuthDatasource (Data Layer)

**File:** `lib/features/auth/data/datasources/supabase_auth_datasource.dart`

This is a **new datasource** specifically for Supabase Auth operations (OTP, sessions). It is separate from `UserRemoteDatasource` which handles user profile data.

```dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Datasource for Supabase Auth operations.
///
/// Handles authentication flows: magic link (OTP), session management.
/// Separate from [UserRemoteDatasource] which handles user profile data.
abstract class SupabaseAuthDatasource {
  /// Send magic link (OTP) to email for sign-up/sign-in.
  ///
  /// [email] - User's email address.
  /// [shouldCreateUser] - If true, creates account if email not found.
  ///                       Set to true for sign-up, false for sign-in only.
  /// [redirectTo] - Optional redirect URL for web apps after magic link click.
  ///                Required for web deployment. Should be app's callback URL.
  ///
  /// Supabase rate limits: 3 emails per email per 60 seconds.
  Future<void> sendMagicLink({
    required String email,
    required bool shouldCreateUser,
    String? redirectTo,
  });

  /// Verify OTP from magic link or email code.
  /// Returns the authenticated session.
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
  });

  /// Get the currently authenticated user.
  /// Returns null if no active session.
  User? get currentUser;

  /// Stream of auth state changes.
  Stream<AuthState> get onAuthStateChange;

  /// Sign out the current user.
  Future<void> signOut();
}

@LazySingleton(as: SupabaseAuthDatasource)
class SupabaseAuthDatasourceImplementation implements SupabaseAuthDatasource {
  SupabaseAuthDatasourceImplementation(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<void> sendMagicLink({
    required String email,
    required bool shouldCreateUser,
    String? redirectTo,
  }) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      shouldCreateUser: shouldCreateUser,
      emailRedirectTo: redirectTo, // Required for web apps
    );
  }

  @override
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    return await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: type,
    );
  }

  @override
  User? get currentUser => _supabase.auth.currentUser;

  @override
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
```

---

### Task 3: Create AuthFailure Classes (Extend Failures)

**File:** `lib/core/error/auth_failures.dart`

```dart
import 'package:tkd_brackets/core/error/failures.dart';

/// Failure when magic link email fails to send.
class MagicLinkSendFailure extends Failure {
  const MagicLinkSendFailure({
    super.userFriendlyMessage = 'Unable to send magic link. Please try again.',
    super.technicalDetails,
  });
}

/// Failure when email validation fails.
class InvalidEmailFailure extends Failure {
  const InvalidEmailFailure({
    super.userFriendlyMessage = 'Please enter a valid email address.',
    super.technicalDetails,
  });
}

/// Failure when rate limit is exceeded.
class RateLimitExceededFailure extends Failure {
  const RateLimitExceededFailure({
    super.userFriendlyMessage =
        'Too many requests. Please wait a moment and try again.',
    super.technicalDetails,
  });
}
```

**Also create barrel file:** `lib/core/error/error.dart`

```dart
/// Core error types barrel file.
export 'auth_failures.dart';
export 'failures.dart';
```

> **⚠️ IMPORTANT:** Create this barrel file to match project conventions. Then import from `core/error/error.dart` in the use case.

---

### Task 4: Create SignUpWithEmailUseCase (Domain Layer)

**File:** `lib/features/auth/domain/usecases/sign_up_with_email_use_case.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_up_with_email_params.dart';

/// Use case to send magic link for new user sign-up.
///
/// This use case:
/// 1. Validates the email format
/// 2. Sends a magic link via Supabase Auth
/// 3. Returns success/failure
///
/// The user will receive an email with a magic link.
/// When clicked, the link completes sign-up (Story 2.4).
@injectable
class SignUpWithEmailUseCase extends UseCase<Unit, SignUpWithEmailParams> {
  SignUpWithEmailUseCase(this._authDatasource);

  final SupabaseAuthDatasource _authDatasource;

  // Email regex pattern (RFC 5322 simplified)
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  Future<Either<Failure, Unit>> call(SignUpWithEmailParams params) async {
    // Validate email format
    final email = params.email.trim().toLowerCase();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      return const Left(
        InvalidEmailFailure(
          technicalDetails: 'Email failed regex validation',
        ),
      );
    }

    try {
      await _authDatasource.sendMagicLink(
        email: email,
        shouldCreateUser: true, // Create user if not exists (sign-up)
      );
      return const Right(unit);
    } on AuthException catch (e) {
      // Handle Supabase Auth errors
      if (e.message.contains('rate limit') ||
          e.message.contains('too many requests')) {
        return Left(
          RateLimitExceededFailure(
            technicalDetails: 'Supabase rate limit: ${e.message}',
          ),
        );
      }
      return Left(
        MagicLinkSendFailure(
          technicalDetails: 'AuthException: ${e.message}',
        ),
      );
    } on Exception catch (e) {
      // Network or other errors
      return Left(
        ServerConnectionFailure(
          technicalDetails: 'Exception: $e',
        ),
      );
    }
  }
}
```

---

### Task 5: Update Auth Feature Barrel File

**File:** `lib/features/auth/auth.dart`

Add exports for the new files:

```dart
/// Authentication feature - exports public APIs.

// Domain - Entities
export 'domain/entities/user_entity.dart';

// Domain - Repositories
export 'domain/repositories/user_repository.dart';

// Domain - Use Cases
export 'domain/usecases/sign_up_with_email_params.dart';
export 'domain/usecases/sign_up_with_email_use_case.dart';

// Data - Datasources (for DI visibility)
export 'data/datasources/supabase_auth_datasource.dart';
export 'data/datasources/user_local_datasource.dart';
export 'data/datasources/user_remote_datasource.dart';

// Data - Repositories
export 'data/repositories/user_repository_implementation.dart';
```

---

### Task 6: Write Unit Tests

**Run tests from:** `tkd_brackets/` directory

**File:** `test/features/auth/data/datasources/supabase_auth_datasource_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/features/auth/data/datasources/supabase_auth_datasource.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late SupabaseAuthDatasourceImplementation datasource;

  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(OtpType.magiclink);
  });

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    datasource = SupabaseAuthDatasourceImplementation(mockSupabase);
  });

  group('SupabaseAuthDatasource', () {
    group('sendMagicLink', () {
      test('calls signInWithOtp with correct parameters for sign-up', () async {
        // Arrange
        when(
          () => mockAuth.signInWithOtp(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
            emailRedirectTo: any(named: 'emailRedirectTo'),
          ),
        ).thenAnswer((_) async => const AuthResponse());

        // Act
        await datasource.sendMagicLink(
          email: 'test@example.com',
          shouldCreateUser: true,
        );

        // Assert
        verify(
          () => mockAuth.signInWithOtp(
            email: 'test@example.com',
            shouldCreateUser: true,
            emailRedirectTo: null,
          ),
        ).called(1);
      });

      test('calls signInWithOtp with shouldCreateUser false for sign-in', () async {
        // Arrange
        when(
          () => mockAuth.signInWithOtp(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
            emailRedirectTo: any(named: 'emailRedirectTo'),
          ),
        ).thenAnswer((_) async => const AuthResponse());

        // Act
        await datasource.sendMagicLink(
          email: 'existing@example.com',
          shouldCreateUser: false,
        );

        // Assert
        verify(
          () => mockAuth.signInWithOtp(
            email: 'existing@example.com',
            shouldCreateUser: false,
            emailRedirectTo: null,
          ),
        ).called(1);
      });

      test('rethrows AuthException on failure', () async {
        // Arrange
        when(
          () => mockAuth.signInWithOtp(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
            emailRedirectTo: any(named: 'emailRedirectTo'),
          ),
        ).thenThrow(const AuthException('Rate limit exceeded'));

        // Act & Assert
        expect(
          () => datasource.sendMagicLink(
            email: 'test@example.com',
            shouldCreateUser: true,
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('passes redirectTo parameter for web apps', () async {
        // Arrange
        const redirectUrl = 'https://app.example.com/auth/callback';
        when(
          () => mockAuth.signInWithOtp(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
            emailRedirectTo: any(named: 'emailRedirectTo'),
          ),
        ).thenAnswer((_) async => const AuthResponse());

        // Act
        await datasource.sendMagicLink(
          email: 'test@example.com',
          shouldCreateUser: true,
          redirectTo: redirectUrl,
        );

        // Assert
        verify(
          () => mockAuth.signInWithOtp(
            email: 'test@example.com',
            shouldCreateUser: true,
            emailRedirectTo: redirectUrl,
          ),
        ).called(1);
      });
    });

    group('currentUser', () {
      test('returns current user from Supabase auth', () {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(null);

        // Act
        final result = datasource.currentUser;

        // Assert
        expect(result, isNull);
        verify(() => mockAuth.currentUser).called(1);
      });
    });

    group('signOut', () {
      test('calls signOut on Supabase auth', () async {
        // Arrange
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        // Act
        await datasource.signOut();

        // Assert
        verify(() => mockAuth.signOut()).called(1);
      });
    });

    group('verifyOtp', () {
      test('calls auth.verifyOTP with correct parameters', () async {
        // Arrange
        when(
          () => mockAuth.verifyOTP(
            email: any(named: 'email'),
            token: any(named: 'token'),
            type: any(named: 'type'),
          ),
        ).thenAnswer((_) async => const AuthResponse());

        // Act
        await datasource.verifyOtp(
          email: 'test@example.com',
          token: '123456',
          type: OtpType.magiclink,
        );

        // Assert
        verify(
          () => mockAuth.verifyOTP(
            email: 'test@example.com',
            token: '123456',
            type: OtpType.magiclink,
          ),
        ).called(1);
      });
    });
  });
}
```

**File:** `test/features/auth/domain/usecases/sign_up_with_email_use_case_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_up_with_email_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_up_with_email_use_case.dart';

class MockSupabaseAuthDatasource extends Mock
    implements SupabaseAuthDatasource {}

void main() {
  late MockSupabaseAuthDatasource mockAuthDatasource;
  late SignUpWithEmailUseCase useCase;

  setUp(() {
    mockAuthDatasource = MockSupabaseAuthDatasource();
    useCase = SignUpWithEmailUseCase(mockAuthDatasource);
  });

  group('SignUpWithEmailUseCase', () {
    const validEmail = 'test@example.com';
    const invalidEmail = 'invalid-email';
    const emptyEmail = '';

    group('email validation', () {
      test('returns InvalidEmailFailure for empty email', () async {
        // Act
        final result = await useCase(
          const SignUpWithEmailParams(email: emptyEmail),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InvalidEmailFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockAuthDatasource);
      });

      test('returns InvalidEmailFailure for invalid email format', () async {
        // Act
        final result = await useCase(
          const SignUpWithEmailParams(email: invalidEmail),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InvalidEmailFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockAuthDatasource);
      });

      test('returns InvalidEmailFailure for email without domain', () async {
        // Act
        final result = await useCase(
          const SignUpWithEmailParams(email: 'user@'),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InvalidEmailFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('trims and lowercases email before validation', () async {
        // Arrange
        when(
          () => mockAuthDatasource.sendMagicLink(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
          ),
        ).thenAnswer((_) async {});

        // Act
        await useCase(
          const SignUpWithEmailParams(email: '  TEST@EXAMPLE.COM  '),
        );

        // Assert
        verify(
          () => mockAuthDatasource.sendMagicLink(
            email: 'test@example.com',
            shouldCreateUser: true,
          ),
        ).called(1);
      });
    });

    group('successful magic link send', () {
      test('returns Right(unit) on successful magic link send', () async {
        // Arrange
        when(
          () => mockAuthDatasource.sendMagicLink(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
          ),
        ).thenAnswer((_) async {});

        // Act
        final result = await useCase(
          const SignUpWithEmailParams(email: validEmail),
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (value) => expect(value, unit),
        );
        verify(
          () => mockAuthDatasource.sendMagicLink(
            email: validEmail,
            shouldCreateUser: true,
          ),
        ).called(1);
      });
    });

    group('error handling', () {
      test('returns RateLimitExceededFailure for rate limit error', () async {
        // Arrange
        when(
          () => mockAuthDatasource.sendMagicLink(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
          ),
        ).thenThrow(const AuthException('rate limit exceeded'));

        // Act
        final result = await useCase(
          const SignUpWithEmailParams(email: validEmail),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<RateLimitExceededFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns RateLimitExceededFailure for too many requests error', () async {
        // Arrange
        when(
          () => mockAuthDatasource.sendMagicLink(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
          ),
        ).thenThrow(const AuthException('too many requests'));

        // Act
        final result = await useCase(
          const SignUpWithEmailParams(email: validEmail),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<RateLimitExceededFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns MagicLinkSendFailure for other AuthException', () async {
        // Arrange
        when(
          () => mockAuthDatasource.sendMagicLink(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
          ),
        ).thenThrow(const AuthException('Unknown auth error'));

        // Act
        final result = await useCase(
          const SignUpWithEmailParams(email: validEmail),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<MagicLinkSendFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns ServerConnectionFailure for network error', () async {
        // Arrange
        when(
          () => mockAuthDatasource.sendMagicLink(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
          ),
        ).thenThrow(Exception('No internet connection'));

        // Act
        final result = await useCase(
          const SignUpWithEmailParams(email: validEmail),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ServerConnectionFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });
  });
}
```

---

### Task 7: Integration Verification

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

### Supabase Auth Magic Link Flow

1. **Sign-Up Request** (This Story):
   - User enters email
   - `SignUpWithEmailUseCase` sends OTP via `signInWithOtp(shouldCreateUser: true)`
   - Supabase sends email with magic link

2. **Magic Link Click** (Story 2.4):
   - User clicks link → opens app with token
   - `verifyOTP()` completes authentication
   - User profile is created/fetched

### Supabase Rate Limits

| Limit Type               | Value            |
| ------------------------ | ---------------- |
| Emails per email address | 3 per 60 seconds |
| OTP per email address    | 5 per 5 minutes  |

### Error Handling Strategy

| Supabase Error            | Mapped Failure             |
| ------------------------- | -------------------------- |
| `rate limit exceeded`     | `RateLimitExceededFailure` |
| `too many requests`       | `RateLimitExceededFailure` |
| Other `AuthException`     | `MagicLinkSendFailure`     |
| Network/other `Exception` | `ServerConnectionFailure`  |

### Architecture Notes

- **Separation of Concerns**: `SupabaseAuthDatasource` handles auth operations, `UserRemoteDatasource` handles user profile CRUD
- **Domain Independence**: Use case validates email, knows nothing about Supabase internals
- **Error Mapping**: Data layer exceptions mapped to domain failures

### Common Mistakes to Avoid

| ❌ Don't                              | ✅ Do                                        |
| ------------------------------------ | ------------------------------------------- |
| Call Supabase directly from use case | Use `SupabaseAuthDatasource` abstraction    |
| Return raw `AuthException`           | Map to domain `Failure` types               |
| Use `signIn()` for sign-up           | Use `signInWithOtp(shouldCreateUser: true)` |
| Skip email validation                | Validate before network call                |
| Import from other features           | Only import from `core/`                    |

---

## Checklist

### Pre-Implementation
- [x] Verify Story 2.2 is complete (User Entity & Repository)
- [x] Review `lib/core/error/failures.dart` for existing failures
- [x] Check Supabase Auth docs for `signInWithOtp` parameters

### Implementation
- [x] Task 1: Create `SignUpWithEmailParams` with freezed
- [x] Task 2: Create `SupabaseAuthDatasource` interface and implementation
- [x] Task 3: Create auth failure classes (`MagicLinkSendFailure`, etc.)
- [x] Task 4: Create `SignUpWithEmailUseCase`
- [x] Task 5: Update auth barrel file with exports
- [x] Task 6: Write unit tests (datasource + use case)
- [x] Task 7: Run build_runner, analyze, and tests

### Post-Implementation
- [x] `flutter analyze` - zero errors in auth feature
- [x] `flutter test test/features/auth/` - all pass (65 tests)
- [x] `flutter build web --release -t lib/main_development.dart` - succeeds
- [x] Update story status to `review`

---

## Architecture References

| Document          | Relevant Sections                                                 |
| ----------------- | ----------------------------------------------------------------- |
| `architecture.md` | Auth Feature (1012-1042), Failures (780-840), Use Cases (844-871) |
| `epics.md`        | Story 2.3 (966-981), Epic 2 Overview (915-1119)                   |
| Story 2.2         | `UserRemoteDatasource` pattern, model conventions                 |

---

## File Manifest

### New Files to Create

| File                                                                       | Purpose                 |
| -------------------------------------------------------------------------- | ----------------------- |
| `lib/features/auth/domain/usecases/sign_up_with_email_params.dart`         | Use case parameters     |
| `lib/features/auth/domain/usecases/sign_up_with_email_use_case.dart`       | Domain use case         |
| `lib/features/auth/data/datasources/supabase_auth_datasource.dart`         | Auth data source        |
| `lib/core/error/auth_failures.dart`                                        | Auth-specific failures  |
| `lib/core/error/error.dart`                                                | Error barrel file (new) |
| `test/features/auth/data/datasources/supabase_auth_datasource_test.dart`   | Datasource tests        |
| `test/features/auth/domain/usecases/sign_up_with_email_use_case_test.dart` | Use case tests          |

### Files to Modify

| File                          | Modification              |
| ----------------------------- | ------------------------- |
| `lib/features/auth/auth.dart` | Add exports for new files |

---

## Agent Record

| Field        | Value                                 |
| ------------ | ------------------------------------- |
| Created By   | create-story workflow                 |
| Created At   | 2026-02-09                            |
| Source Epic  | Epic 2: Authentication & Organization |
| Story Points | 3                                     |

---

## Dev Agent Record

### Implementation Date
2026-02-09

### Completion Notes
- Created `SignUpWithEmailParams` freezed class for use case parameters
- Implemented `SupabaseAuthDatasource` with interface + implementation for auth operations (magic link, OTP verification, sign out)
- Created auth-specific failure classes: `MagicLinkSendFailure`, `InvalidEmailFailure`, `RateLimitExceededFailure`
- Created `error.dart` barrel file for core error exports
- Implemented `SignUpWithEmailUseCase` with email validation and proper error handling
- Updated auth barrel file with all new exports (sorted alphabetically per project conventions)
- Created comprehensive unit tests
- All 75 auth feature tests pass
- Flutter analyze: zero errors in auth feature
- Web build succeeds

### File List

**New Files Created:**
- `lib/features/auth/domain/repositories/auth_repository.dart`
- `lib/features/auth/domain/usecases/sign_up_with_email_params.dart`
- `lib/features/auth/domain/usecases/sign_up_with_email_params.freezed.dart` (generated)
- `lib/features/auth/domain/usecases/sign_up_with_email_use_case.dart`
- `lib/features/auth/data/repositories/auth_repository_implementation.dart`
- `lib/features/auth/data/datasources/supabase_auth_datasource.dart`
- `lib/core/error/auth_failures.dart`
- `lib/core/error/error.dart`
- `test/features/auth/data/datasources/supabase_auth_datasource_test.dart`
- `test/features/auth/data/repositories/auth_repository_implementation_test.dart`
- `test/features/auth/domain/usecases/sign_up_with_email_use_case_test.dart`

**Files Modified:**
- `lib/features/auth/auth.dart` (added exports for new files)
- `lib/core/di/injection.config.dart` (auto-generated - new DI registrations)

### Change Log
- 2026-02-09: Story implemented - all acceptance criteria met, ready for code review
- 2026-02-09: Code review completed - fixed architecture violations

---

## Senior Developer Review (AI)

### Review Date
2026-02-09

### Issues Found & Fixed

#### 🔴 HIGH Severity (Fixed)

1. **Architecture Violation - Use Case Depended on Data Layer**
   - **Issue:** `SignUpWithEmailUseCase` directly imported `SupabaseAuthDatasource` from data layer
   - **Fix:** Created `AuthRepository` interface in domain layer, `AuthRepositoryImplementation` in data layer
   - **Files:** `domain/repositories/auth_repository.dart`, `data/repositories/auth_repository_implementation.dart`

2. **Supabase Import in Domain Layer**
   - **Issue:** Domain layer had `import 'package:supabase_flutter/supabase_flutter.dart'`
   - **Fix:** Moved all Supabase-specific exception handling to `AuthRepositoryImplementation`
   - **File:** `domain/usecases/sign_up_with_email_use_case.dart`

#### 🟡 MEDIUM Severity (Fixed / Noted)

3. **Missing Test for onAuthStateChange**
   - **Issue:** Datasource test didn't test `onAuthStateChange` stream
   - **Fix:** Added test case
   - **File:** `test/features/auth/data/datasources/supabase_auth_datasource_test.dart`

4. **Duplicate Auth Properties in UserRemoteDatasource**
   - **Status:** Noted for future refactoring - `currentAuthUser` and `authStateChanges` exist in both datasources
   - **Recommendation:** Remove from `UserRemoteDatasource` in future story

#### 🟢 LOW Severity (Fixed)

5. **Missing DocString on Implementation Class**
   - **Fix:** Added doc comments to `SupabaseAuthDatasourceImplementation`

6. **Inconsistent async/await Usage**
   - **Fix:** Made `verifyOtp` consistent with other methods

### Test Results After Review
- Auth feature tests: 75 passed (up from 65)
- Flutter analyze (auth feature): 0 issues
- Added 10 new tests for `AuthRepositoryImplementation`

### Reviewer
Code Review Workflow (AI)
