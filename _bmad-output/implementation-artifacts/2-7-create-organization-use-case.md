# Story 2.7: Create Organization Use Case

## Epic: Epic 2 — Authentication & Organization
## Story ID: 2.7
## Title: Create Organization Use Case
## Status: done

---

## Story Description

**As a** newly registered user,
**I want** to create my organization after signing up,
**So that** I can start managing tournaments for my dojang (FR53).

## Acceptance Criteria

> **AC1:** `CreateOrganizationUseCase` is implemented in the domain layer as `UseCase<OrganizationEntity, CreateOrganizationParams>`
>
> **AC2:** `CreateOrganizationParams` freezed class is created with required `name` (String) and `userId` (String) fields
>
> **AC3:** Organization name validation rejects empty, whitespace-only, names exceeding 255 characters, and names with no alphanumeric characters (empty slug) — returns `InputValidationFailure`
>
> **AC4:** Slug is auto-generated from organization name: lowercase, spaces replaced with hyphens, special characters removed, consecutive hyphens collapsed
>
> **AC5:** UUID is generated for the organization ID using the `uuid` package
>
> **AC6:** Organization is created with free-tier defaults: `subscriptionTier: free`, `subscriptionStatus: active`, `isActive: true`, and all default limit values
>
> **AC7:** Use case delegates to `OrganizationRepository.createOrganization()` to persist the organization (local + remote sync handled by repo)
>
> **AC8:** After organization creation, use case updates the current user's `organizationId` and `role` (set to `owner`) via `UserRepository.updateUser()`
>
> **AC9:** Error cases are handled: repository failures are propagated as `Either<Failure, OrganizationEntity>`
>
> **AC10:** Unit tests verify: successful creation flow, name validation, slug generation, user role assignment, and error propagation
>
> **AC11:** `CreateOrganizationParams` and `CreateOrganizationUseCase` exports are added to `auth.dart` barrel file
>
> **AC12:** `flutter analyze` passes with zero new errors
>
> **AC13:** `build_runner` generates code successfully for the new params class

---

## Tasks

### Task 1: Create `CreateOrganizationParams` — AC2, AC13

**File:** `lib/features/auth/domain/usecases/create_organization_params.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_organization_params.freezed.dart';

/// Parameters for the [CreateOrganizationUseCase].
///
/// [name] — The display name for the organization (e.g., "Dragon Martial Arts").
/// [userId] — The authenticated user's ID who is creating the organization.
@freezed
class CreateOrganizationParams
    with _$CreateOrganizationParams {
  const factory CreateOrganizationParams({
    /// Organization display name.
    required String name,

    /// The ID of the user creating the organization.
    required String userId,
  }) = _CreateOrganizationParams;
}
```

---

### Task 2: Create `CreateOrganizationUseCase` — AC1, AC3, AC4, AC5, AC6, AC7, AC8, AC9

**File:** `lib/features/auth/domain/usecases/create_organization_use_case.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/organization_entity.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/organization_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/create_organization_params.dart';
import 'package:uuid/uuid.dart';

/// Use case to create a new organization for a newly registered
/// user.
///
/// This use case:
/// 1. Validates the organization name
/// 2. Generates a URL-safe slug from the name
/// 3. Creates the organization with free-tier defaults
/// 4. Persists via [OrganizationRepository]
/// 5. Updates the user's organizationId and role to 'owner'
///    via [UserRepository]
@injectable
class CreateOrganizationUseCase
    extends UseCase<OrganizationEntity,
        CreateOrganizationParams> {
  CreateOrganizationUseCase(
    this._organizationRepository,
    this._userRepository,
  );

  final OrganizationRepository _organizationRepository;
  final UserRepository _userRepository;

  /// Maximum allowed length for organization name.
  static const int maxNameLength = 255;

  static const _uuid = Uuid();

  @override
  Future<Either<Failure, OrganizationEntity>> call(
    CreateOrganizationParams params,
  ) async {
    // 1. Validate organization name
    final trimmedName = params.name.trim();
    if (trimmedName.isEmpty) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage:
              'Organization name cannot be empty.',
          fieldErrors: {'name': 'Name is required'},
        ),
      );
    }

    if (trimmedName.length > maxNameLength) {
      return Left(
        InputValidationFailure(
          userFriendlyMessage:
              'Organization name is too long '
              '(max $maxNameLength characters).',
          fieldErrors: {
            'name':
                'Name must be $maxNameLength characters '
                'or less',
          },
        ),
      );
    }

    // 2. Generate slug from name
    final slug = generateSlug(trimmedName);
    if (slug.isEmpty) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage:
              'Organization name must contain at least '
              'one letter or number.',
          fieldErrors: {
            'name':
                'Name must contain alphanumeric characters',
          },
        ),
      );
    }

    // 3. Generate UUID for organization
    final orgId = _uuid.v4();

    // 4. Build entity with free-tier defaults
    final organization = OrganizationEntity(
      id: orgId,
      name: trimmedName,
      slug: slug,
      subscriptionTier: SubscriptionTier.free,
      subscriptionStatus: SubscriptionStatus.active,
      maxTournamentsPerMonth: 2,
      maxActiveBrackets: 3,
      maxParticipantsPerBracket: 32,
      maxParticipantsPerTournament: 100,
      maxScorers: 2,
      isActive: true,
      createdAt: DateTime.now(),
    );

    // 5. Persist organization via repository
    final createResult = await _organizationRepository
        .createOrganization(organization);

    return createResult.fold(
      Left.new,
      (createdOrg) async {
        // 6. Fetch and update the user's organizationId
        //    and role to 'owner'
        final userResult = await _userRepository
            .getUserById(params.userId);

        return userResult.fold(
          Left.new,
          (user) async {
            final updatedUser = user.copyWith(
              organizationId: createdOrg.id,
              role: UserRole.owner,
            );
            final updateResult =
                await _userRepository
                    .updateUser(updatedUser);

            return updateResult.fold(
              Left.new,
              (_) => Right(createdOrg),
            );
          },
        );
      },
    );
  }

  /// Generate a URL-safe slug from an organization name.
  ///
  /// Rules:
  /// - Convert to lowercase
  /// - Replace spaces and underscores with hyphens
  /// - Remove all non-alphanumeric, non-hyphen characters
  /// - Collapse consecutive hyphens into one
  /// - Trim leading/trailing hyphens
  ///
  /// Example: "Dragon Martial Arts!" → "dragon-martial-arts"
  @visibleForTesting
  static String generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_]+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9-]'), '')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
```

**CRITICAL IMPLEMENTATION NOTES:**

1. **`@injectable` NOT `@LazySingleton`**: Use cases are `@injectable` (new instance per call). Only repositories and datasources are `@LazySingleton`.

2. **Two Repository Dependencies**: This use case needs BOTH `OrganizationRepository` and `UserRepository`. The DI container already has both registered as `@LazySingleton`.

3. **Slug Generation is a static method**: Making it `static` allows direct unit testing without instantiating the use case.

4. **Free-tier defaults match the Supabase schema defaults**: `maxTournamentsPerMonth: 2`, `maxActiveBrackets: 3`, `maxParticipantsPerBracket: 32`, `maxParticipantsPerTournament: 100`, `maxScorers: 2`. These MUST match the SQL `DEFAULT` values in the organizations table.

5. **UUID generation**: Use the `uuid` package which is already in `pubspec.yaml` dependencies. A `static const _uuid = Uuid()` is defined at the class level for reuse. Always use `v4()` for random UUIDs.

6. **The nested `fold` pattern**: When the organization creation succeeds, we need to fetch the user and update them. Each step can fail, so we chain `fold` calls. This is the first multi-step use case in this codebase. Dart's `FutureOr` inference handles the mixing of sync `Left.new` and async callbacks in `fold` branches.

7. **User `copyWith`**: `UserEntity` is a freezed class, so `copyWith` is auto-generated. We update `organizationId` and `role` fields.

---

### Task 3: Update Auth Barrel File — AC11

**File:** `lib/features/auth/auth.dart`

**Add these exports** in the `// Domain - Use Cases` section, maintaining alphabetical order:

```dart
// Domain - Use Cases (add these two)
export 'domain/usecases/create_organization_params.dart';
export 'domain/usecases/create_organization_use_case.dart';
```

**Expected location — insert BEFORE `get_current_user_use_case.dart`:**

```dart
// Domain - Use Cases
export 'domain/usecases/create_organization_params.dart';
export 'domain/usecases/create_organization_use_case.dart';
export 'domain/usecases/get_current_user_use_case.dart';
export 'domain/usecases/sign_in_with_email_params.dart';
// ... rest of use case exports
```

---

### Task 4: Run build_runner — AC13

```bash
cd tkd_brackets && dart run build_runner build --delete-conflicting-outputs
```

This generates:
- `create_organization_params.freezed.dart`
- Updated `injection.config.dart` (auto-registers `CreateOrganizationUseCase` as injectable)

---

### Task 5: Run flutter analyze — AC12

```bash
cd tkd_brackets && flutter analyze
```

Must pass with zero new errors from the code in this story. Pre-existing info/warning issues are acceptable.

---

### Task 5b: Run full test suite — Regression check

```bash
cd tkd_brackets && flutter test
```

All existing tests (544+) must continue to pass. Zero new failures allowed. This verifies barrel file exports and DI registration don't break existing code.

---

### Task 6: Write Unit Tests — AC10

#### Test File: `test/features/auth/domain/usecases/create_organization_use_case_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/organization_entity.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/organization_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/create_organization_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/create_organization_use_case.dart';

class MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class MockUserRepository extends Mock
    implements UserRepository {}

class FakeOrganizationEntity extends Fake
    implements OrganizationEntity {}

class FakeUserEntity extends Fake
    implements UserEntity {}

void main() {
  late CreateOrganizationUseCase useCase;
  late MockOrganizationRepository
      mockOrganizationRepository;
  late MockUserRepository mockUserRepository;

  setUpAll(() {
    registerFallbackValue(FakeOrganizationEntity());
    registerFallbackValue(FakeUserEntity());
  });

  setUp(() {
    mockOrganizationRepository =
        MockOrganizationRepository();
    mockUserRepository = MockUserRepository();
    useCase = CreateOrganizationUseCase(
      mockOrganizationRepository,
      mockUserRepository,
    );
  });

  // Test user fixture
  final testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    organizationId: '',
    role: UserRole.viewer,
    isActive: true,
    createdAt: DateTime(2024),
  );

  group('CreateOrganizationUseCase', () {
    group('name validation', () {
      test(
        'returns InputValidationFailure for empty name',
        () async {
          final result = await useCase(
            const CreateOrganizationParams(
              name: '',
              userId: 'user-123',
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(
              failure,
              isA<InputValidationFailure>(),
            ),
            (_) => fail('Expected Left'),
          );
          verifyZeroInteractions(
            mockOrganizationRepository,
          );
          verifyZeroInteractions(mockUserRepository);
        },
      );

      test(
        'returns InputValidationFailure for '
        'whitespace-only name',
        () async {
          final result = await useCase(
            const CreateOrganizationParams(
              name: '   ',
              userId: 'user-123',
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(
              failure,
              isA<InputValidationFailure>(),
            ),
            (_) => fail('Expected Left'),
          );
          verifyZeroInteractions(
            mockOrganizationRepository,
          );
        },
      );

      test(
        'returns InputValidationFailure for name '
        'exceeding 255 characters',
        () async {
          final longName = 'A' * 256;
          final result = await useCase(
            CreateOrganizationParams(
              name: longName,
              userId: 'user-123',
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(
              failure,
              isA<InputValidationFailure>(),
            ),
            (_) => fail('Expected Left'),
          );
          verifyZeroInteractions(
            mockOrganizationRepository,
          );
        },
      );

      test(
        'accepts name with exactly 255 characters',
        () async {
          final exactName = 'A' * 255;
          when(
            () => mockOrganizationRepository
                .createOrganization(any()),
          ).thenAnswer(
            (_) async => Right(
              OrganizationEntity(
                id: 'org-1',
                name: exactName,
                slug: 'a' * 255,
                subscriptionTier: SubscriptionTier.free,
                subscriptionStatus:
                    SubscriptionStatus.active,
                maxTournamentsPerMonth: 2,
                maxActiveBrackets: 3,
                maxParticipantsPerBracket: 32,
                maxParticipantsPerTournament: 100,
                maxScorers: 2,
                isActive: true,
                createdAt: DateTime(2024),
              ),
            ),
          );
          when(
            () => mockUserRepository
                .getUserById('user-123'),
          ).thenAnswer(
            (_) async => Right(testUser),
          );
          when(
            () => mockUserRepository.updateUser(any()),
          ).thenAnswer(
            (_) async => Right(testUser),
          );

          final result = await useCase(
            CreateOrganizationParams(
              name: exactName,
              userId: 'user-123',
            ),
          );

          expect(result.isRight(), isTrue);
          verify(
            () => mockOrganizationRepository
                .createOrganization(any()),
          ).called(1);
        },
      );

      test(
        'trims whitespace from name before processing',
        () async {
          late OrganizationEntity capturedOrg;
          when(
            () => mockOrganizationRepository
                .createOrganization(any()),
          ).thenAnswer((invocation) async {
            capturedOrg = invocation.positionalArguments
                .first as OrganizationEntity;
            return Right(capturedOrg);
          });
          when(
            () => mockUserRepository
                .getUserById('user-123'),
          ).thenAnswer(
            (_) async => Right(testUser),
          );
          when(
            () => mockUserRepository.updateUser(any()),
          ).thenAnswer(
            (_) async => Right(testUser),
          );

          await useCase(
            const CreateOrganizationParams(
              name: '  Dragon Dojang  ',
              userId: 'user-123',
            ),
          );

          expect(capturedOrg.name, 'Dragon Dojang');
        },
      );

      test(
        'returns InputValidationFailure for name with '
        'no alphanumeric characters',
        () async {
          final result = await useCase(
            const CreateOrganizationParams(
              name: '!!!@#\$%',
              userId: 'user-123',
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(
              failure,
              isA<InputValidationFailure>(),
            ),
            (_) => fail('Expected Left'),
          );
          verifyZeroInteractions(
            mockOrganizationRepository,
          );
        },
      );
    });

    group('slug generation', () {
      test(
        'generates lowercase hyphenated slug',
        () {
          expect(
            CreateOrganizationUseCase.generateSlug(
              'Dragon Martial Arts',
            ),
            'dragon-martial-arts',
          );
        },
      );

      test(
        'removes special characters',
        () {
          expect(
            CreateOrganizationUseCase.generateSlug(
              "Dragon's Dojang!",
            ),
            'dragons-dojang',
          );
        },
      );

      test(
        'collapses consecutive hyphens',
        () {
          expect(
            CreateOrganizationUseCase.generateSlug(
              'Dragon  --  Dojang',
            ),
            'dragon-dojang',
          );
        },
      );

      test(
        'trims leading and trailing hyphens',
        () {
          expect(
            CreateOrganizationUseCase.generateSlug(
              '-Dragon Dojang-',
            ),
            'dragon-dojang',
          );
        },
      );

      test(
        'handles underscores by converting to hyphens',
        () {
          expect(
            CreateOrganizationUseCase.generateSlug(
              'Dragon_Dojang',
            ),
            'dragon-dojang',
          );
        },
      );

      test('handles unicode/accents by removing', () {
        expect(
          CreateOrganizationUseCase.generateSlug(
            'Café Dojang',
          ),
          'caf-dojang',
        );
      });

      test('handles single word', () {
        expect(
          CreateOrganizationUseCase.generateSlug(
            'DRAGONS',
          ),
          'dragons',
        );
      });

      test('handles mixed whitespace', () {
        expect(
          CreateOrganizationUseCase.generateSlug(
            "Dragon\tDojang\nAcademy",
          ),
          'dragon-dojang-academy',
        );
      });

      test(
        'returns empty string for all-special-characters',
        () {
          expect(
            CreateOrganizationUseCase.generateSlug(
              '!!!@#\$%',
            ),
            '',
          );
        },
      );
    });

    group('successful organization creation', () {
      test(
        'creates organization and updates user role '
        'to owner',
        () async {
          late OrganizationEntity capturedOrg;
          late UserEntity capturedUser;

          when(
            () => mockOrganizationRepository
                .createOrganization(any()),
          ).thenAnswer((invocation) async {
            capturedOrg = invocation.positionalArguments
                .first as OrganizationEntity;
            return Right(capturedOrg);
          });

          when(
            () => mockUserRepository
                .getUserById('user-123'),
          ).thenAnswer(
            (_) async => Right(testUser),
          );

          when(
            () => mockUserRepository.updateUser(any()),
          ).thenAnswer((invocation) async {
            capturedUser = invocation
                .positionalArguments
                .first as UserEntity;
            return Right(capturedUser);
          });

          final result = await useCase(
            const CreateOrganizationParams(
              name: 'Dragon Martial Arts',
              userId: 'user-123',
            ),
          );

          // Verify organization was created correctly
          expect(result.isRight(), isTrue);
          result.fold(
            (_) => fail('Expected Right'),
            (org) {
              expect(org.name, 'Dragon Martial Arts');
              expect(
                org.slug,
                'dragon-martial-arts',
              );
              expect(
                org.subscriptionTier,
                SubscriptionTier.free,
              );
              expect(
                org.subscriptionStatus,
                SubscriptionStatus.active,
              );
              expect(org.isActive, isTrue);
              expect(org.maxTournamentsPerMonth, 2);
              expect(org.maxActiveBrackets, 3);
              expect(
                org.maxParticipantsPerBracket,
                32,
              );
              expect(
                org.maxParticipantsPerTournament,
                100,
              );
              expect(org.maxScorers, 2);
              expect(org.id, isNotEmpty);
            },
          );

          // Verify user was updated with owner role
          expect(
            capturedUser.organizationId,
            capturedOrg.id,
          );
          expect(capturedUser.role, UserRole.owner);

          // Verify call order
          verifyInOrder([
            () => mockOrganizationRepository
                .createOrganization(any()),
            () => mockUserRepository
                .getUserById('user-123'),
            () => mockUserRepository.updateUser(any()),
          ]);
        },
      );

      test(
        'generates a valid UUID for the organization ID',
        () async {
          late OrganizationEntity capturedOrg;

          when(
            () => mockOrganizationRepository
                .createOrganization(any()),
          ).thenAnswer((invocation) async {
            capturedOrg = invocation.positionalArguments
                .first as OrganizationEntity;
            return Right(capturedOrg);
          });
          when(
            () => mockUserRepository
                .getUserById('user-123'),
          ).thenAnswer(
            (_) async => Right(testUser),
          );
          when(
            () => mockUserRepository.updateUser(any()),
          ).thenAnswer(
            (_) async => Right(testUser),
          );

          await useCase(
            const CreateOrganizationParams(
              name: 'Test Org',
              userId: 'user-123',
            ),
          );

          // UUID v4 format:
          // 8-4-4-4-12 hex chars
          expect(
            capturedOrg.id,
            matches(RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-'
              r'4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
              r'[0-9a-f]{12}$',
            )),
          );
        },
      );
    });

    group('error handling', () {
      final testOrg = OrganizationEntity(
        id: 'org-1',
        name: 'Dragon Dojang',
        slug: 'dragon-dojang',
        subscriptionTier: SubscriptionTier.free,
        subscriptionStatus:
            SubscriptionStatus.active,
        maxTournamentsPerMonth: 2,
        maxActiveBrackets: 3,
        maxParticipantsPerBracket: 32,
        maxParticipantsPerTournament: 100,
        maxScorers: 2,
        isActive: true,
        createdAt: DateTime(2024),
      );

      test(
        'returns failure when organization repository '
        'fails',
        () async {
          when(
            () => mockOrganizationRepository
                .createOrganization(any()),
          ).thenAnswer(
            (_) async => const Left(
              LocalCacheWriteFailure(
                userFriendlyMessage:
                    'Failed to create organization.',
              ),
            ),
          );

          final result = await useCase(
            const CreateOrganizationParams(
              name: 'Dragon Dojang',
              userId: 'user-123',
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(
              failure,
              isA<LocalCacheWriteFailure>(),
            ),
            (_) => fail('Expected Left'),
          );
          // User should NOT be updated if org
          // creation failed
          verifyNever(
            () => mockUserRepository
                .getUserById(any()),
          );
          verifyNever(
            () => mockUserRepository
                .updateUser(any()),
          );
        },
      );

      test(
        'returns failure when getUserById fails after '
        'org creation',
        () async {
          when(
            () => mockOrganizationRepository
                .createOrganization(any()),
          ).thenAnswer(
            (_) async => Right(testOrg),
          );
          when(
            () => mockUserRepository
                .getUserById('user-123'),
          ).thenAnswer(
            (_) async => const Left(
              LocalCacheAccessFailure(
                userFriendlyMessage: 'User not found.',
              ),
            ),
          );

          final result = await useCase(
            const CreateOrganizationParams(
              name: 'Dragon Dojang',
              userId: 'user-123',
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(
              failure,
              isA<LocalCacheAccessFailure>(),
            ),
            (_) => fail('Expected Left'),
          );
          verifyNever(
            () => mockUserRepository
                .updateUser(any()),
          );
        },
      );

      test(
        'returns failure when updateUser fails after '
        'org creation',
        () async {
          when(
            () => mockOrganizationRepository
                .createOrganization(any()),
          ).thenAnswer(
            (_) async => Right(testOrg),
          );
          when(
            () => mockUserRepository
                .getUserById('user-123'),
          ).thenAnswer(
            (_) async => Right(testUser),
          );
          when(
            () => mockUserRepository.updateUser(any()),
          ).thenAnswer(
            (_) async => const Left(
              LocalCacheWriteFailure(
                userFriendlyMessage:
                    'Failed to update user.',
              ),
            ),
          );

          final result = await useCase(
            const CreateOrganizationParams(
              name: 'Dragon Dojang',
              userId: 'user-123',
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(
              failure,
              isA<LocalCacheWriteFailure>(),
            ),
            (_) => fail('Expected Left'),
          );
        },
      );
    });
  });
}
```

---

## Dev Notes

### Key Patterns to Follow

1. **This use case follows the same pattern as `SignUpWithEmailUseCase`** — validate inputs, delegate to repository, return `Either<Failure, T>`. The key difference is that it uses TWO repositories (`OrganizationRepository` + `UserRepository`) and has a multi-step operation.

2. **Use `@injectable` for use cases**, NOT `@LazySingleton`. All existing use cases in the project use `@injectable`. Repositories and datasources use `@LazySingleton`.

3. **Params classes use `@freezed`** and have a `part` directive for the generated `.freezed.dart` file. They do NOT need `@JsonSerializable` or `.g.dart`.

4. **Organization lives in the `auth` feature**, NOT a separate feature folder. All organization-related code is under `lib/features/auth/`.

5. **The slug generation logic is a `static` method** to make it directly testable without mocking dependencies.

### Dependency Notes

- **`uuid` package** — Already in `pubspec.yaml`. Import `package:uuid/uuid.dart` and use `const Uuid()` then `.v4()`.
- **`fpdart`** — Already in `pubspec.yaml`. Used for `Either`, `Left`, `Right`, `Unit`, `unit`.
- **`injectable`** — Already in `pubspec.yaml`. Used for `@injectable` annotation.
- **`freezed_annotation`** — Already in `pubspec.yaml`. Used for `@freezed` on the params class.

### Free-Tier Default Values (Source of Truth: Supabase Schema)

These values MUST match the SQL `DEFAULT` clauses in the `organizations` table:

| Field                             | Default    |
| --------------------------------- | ---------- |
| `subscription_tier`               | `'free'`   |
| `subscription_status`             | `'active'` |
| `max_tournaments_per_month`       | `2`        |
| `max_active_brackets`             | `3`        |
| `max_participants_per_bracket`    | `32`       |
| `max_participants_per_tournament` | `100`      |
| `max_scorers`                     | `2`        |
| `is_active`                       | `true`     |

### Slug Generation Rules

1. Convert to lowercase
2. Replace whitespace and underscores with hyphens
3. Remove all non-alphanumeric, non-hyphen characters
4. Collapse consecutive hyphens into one
5. Trim leading/trailing hyphens

### What This Story Does NOT Include

- **Duplicate slug handling**: The AC says "duplicate name" errors are handled, but this is handled at the **database level** (Supabase `UNIQUE` constraint on `slug`, Drift `unique()` constraint). The repository will throw an exception which is caught and returned as a `Left(Failure)`. No additional logic is needed in the use case.
- **Presentation layer**: No BLoC events/states for organization creation (that would be a separate story).
- **RLS policies**: Already configured in Supabase for the `organizations` table.

### Known Limitation: Partial Failure on Multi-Step Create

If organization creation succeeds (step 1) but user update fails (steps 2-3), the organization persists without an owner linked. This is acceptable for MVP — the user can retry, and the duplicate slug constraint prevents duplicate organizations. A future cleanup mechanism can handle orphaned records if needed.

### Epics vs. Actual Implementation Discrepancy

**The epics file says "user is automatically assigned as Owner role"**. In the actual schema, there is no `owner_id` field on the `organizations` table. Instead, the user's `role` field in the `users` table is set to `'owner'`, and their `organization_id` is set to the new organization's ID. This is the correct implementation per the actual schema.

### Project Structure Notes

Files created/modified by this story:
```
lib/features/auth/
├── domain/
│   └── usecases/
│       ├── create_organization_params.dart        ← NEW
│       └── create_organization_use_case.dart       ← NEW
└── auth.dart                                       ← MODIFIED (add exports)

test/features/auth/
└── domain/
    └── usecases/
        └── create_organization_use_case_test.dart  ← NEW
```

### Testing Standards

- Use `mocktail` for mocking (NOT `mockito`)
- Register fallback values in `setUpAll()` for Fake classes
- Use `verify()` and `verifyInOrder()` to ensure correct method call order
- Use `verifyNever()` to confirm methods are NOT called on error paths
- Use `verifyZeroInteractions()` when validation should prevent any repo calls
- Test both success and failure paths
- Capture arguments with `captureAny()` to verify entity field values

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Story 2.7 definition]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Organizations schema, naming conventions, Clean Architecture rules]
- [Source: `lib/features/auth/domain/usecases/sign_up_with_email_use_case.dart` — Use case pattern reference]
- [Source: `lib/features/auth/domain/usecases/sign_up_with_email_params.dart` — Params class pattern reference]
- [Source: `lib/features/auth/domain/entities/organization_entity.dart` — Organization entity definition]
- [Source: `lib/features/auth/domain/repositories/organization_repository.dart` — Organization repository interface]
- [Source: `lib/features/auth/domain/repositories/user_repository.dart` — User repository interface (for updateUser)]
- [Source: `lib/features/auth/domain/entities/user_entity.dart` — User entity definition (organizationId, role fields)]
- [Source: `lib/core/usecases/use_case.dart` — Base UseCase<T, Params> class]
- [Source: `lib/core/error/failures.dart` — Failure hierarchy (InputValidationFailure)]
- [Source: `test/features/auth/domain/usecases/sign_up_with_email_use_case_test.dart` — Test pattern reference]

---

## Dev Agent Record

### Agent Model Used
minimax/minimax-m2.5

### Debug Log References
N/A - Implementation completed in single session

### Completion Notes List
- Task 1: Created `CreateOrganizationParams` freezed class with name and userId fields
- Task 2: Created `CreateOrganizationUseCase` with name validation, slug generation, UUID creation, free-tier defaults, and user role assignment
- Task 3: Updated auth.dart barrel file with exports for both new files
- Task 4: Ran build_runner - generated freezed code and updated injection.config.dart
- Task 5: Ran flutter analyze - passed with zero new errors (only info-level suggestions)
- Task 5b: Ran full test suite - 544+ tests passed with no regressions
- Task 6: Created comprehensive unit tests - 20 tests covering validation, slug generation, success flow, and error handling

All acceptance criteria satisfied:
- AC1: UseCase implemented ✓
- AC2: CreateOrganizationParams freezed class created ✓
- AC3: Name validation implemented (empty, whitespace, 255 char limit, no alphanumeric) ✓
- AC4: Slug auto-generated from name ✓
- AC5: UUID generated using uuid package ✓
- AC6: Free-tier defaults set correctly ✓
- AC7: Delegates to OrganizationRepository ✓
- AC8: Updates user organizationId and role to owner ✓
- AC9: Error propagation via Either<Failure, OrganizationEntity> ✓
- AC10: Unit tests verify all flows ✓
- AC11: Exports added to auth.dart barrel file ✓
- AC12: flutter analyze passes with zero errors ✓
- AC13: build_runner generates code successfully ✓

### Code Review Fixes Applied
- **Security Validation:** Injected `AuthRepository` to verify that `CreateOrganizationParams.userId` matches the currently authenticated user. Added `AuthenticationFailure` for mismatch.
- **Data Integrity:** Injected `ErrorReportingService` to log critical errors ("Orphaned Organization") if user update fails after organization creation.
- **Error Handling:** Added `AuthenticationFailure` and `AuthorizationPermissionDeniedFailure` with technical details support to `failures.dart`.
- **Testing:** Updated unit tests to mock new dependencies and verify security and error logging scenarios.

### Code Review #2 Fixes Applied (2026-02-15)
- **M2 (cascade):** Used Dart cascade operator (`..`) for consecutive `_errorReportingService` calls.
- **M3 (const):** Added `const` to `Left(InputValidationFailure(...))` for name-too-long validation.
- **L1 (import):** Replaced `package:meta/meta.dart` with `package:flutter/foundation.dart show visibleForTesting` to match codebase pattern and fix `depend_on_referenced_packages` lint.
- **L2 (raw strings):** Removed unnecessary `r` prefix from regex patterns without backslash escapes.
- **L5 (test gap):** Added `verifyZeroInteractions(mockErrorReportingService)` to getUserById failure test to verify error reporter is NOT invoked on non-orphan failures.
- **Line length:** Broke long critical error message string to comply with 80-char limit.
- **Import ordering:** Sorted `flutter` import before `fpdart` to fix `directives_ordering` lint.
- **Result:** `flutter analyze` now shows **0 issues** (down from 10 info-level). All 22 tests pass.

### File List

**New Files:**
- `lib/features/auth/domain/usecases/create_organization_params.dart`
- `lib/features/auth/domain/usecases/create_organization_use_case.dart`
- `test/features/auth/domain/usecases/create_organization_use_case_test.dart`

**Modified Files:**
- `lib/features/auth/auth.dart` — Added create organization exports
