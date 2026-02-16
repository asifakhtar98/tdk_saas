# Story 3.3: Create Tournament Use Case

Status: done

## Epic: Epic 3 — Tournament & Division Management
## Story ID: 3.3
## Title: Create Tournament Use Case

---

## Story Description

**As an** organizer,
**I want** to create a new tournament with name, date, and description,
**So that** I can start setting up my event (FR1).

## Acceptance Criteria

> **AC1:** `CreateTournamentUseCase` extends `UseCase<TournamentEntity, CreateTournamentParams>` in domain layer
>
> **AC2:** `CreateTournamentParams` freezed class created with required `name` (String), `scheduledDate` (DateTime), optional `description` (String?)
>
> **AC3:** Input validation rejects: empty/whitespace-only name, name > 100 chars, scheduledDate < today, description > 1000 chars — returns `InputValidationFailure` with `fieldErrors`
>
> **AC4:** UUID generated using `uuid` package for tournament ID
>
> **AC5:** Tournament created with defaults: `status: draft`, `federationType: wt`, `numberOfRings: 1`, `isTemplate: false`, `settingsJson: {}`
>
> **AC6:** Use case gets current user's `organizationId` from authenticated session (via `AuthRepository` or `UserRepository`)
>
> **AC7:** Delegates to `TournamentRepository.createTournament()` to persist (local + remote sync handled by repo)
>
> **AC8:** Error cases propagated as `Either<Failure, TournamentEntity>`
>
> **AC9:** Unit tests verify: validation, successful creation, error paths
>
> **AC10:** Exports added to `tournament.dart` barrel file
>
> **AC11:** `flutter analyze` passes with zero new errors

---

## Tasks

- [x] ### Task 1: Create `CreateTournamentParams` — AC2, AC10

**File:** `lib/features/tournament/domain/usecases/create_tournament_params.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_tournament_params.freezed.dart';

/// Parameters for [CreateTournamentUseCase].
///
/// [name] — Tournament name (required, 1-100 chars)
/// [scheduledDate] — Date of tournament (required, must be >= today)
/// [description] — Optional description (max 1000 chars)
@freezed
class CreateTournamentParams with _$CreateTournamentParams {
  const factory CreateTournamentParams({
    required String name,
    required DateTime scheduledDate,
    String? description,
  }) = _CreateTournamentParams;
}
```

---

- [x] ### Task 2: Create `CreateTournamentUseCase` — AC1, AC3, AC4, AC5, AC6, AC7, AC8

**File:** `lib/features/tournament/domain/usecases/create_tournament_usecase.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/create_tournament_params.dart';
import 'package:uuid/uuid.dart';

@injectable
class CreateTournamentUseCase
    extends UseCase<TournamentEntity, CreateTournamentParams> {
  CreateTournamentUseCase(
    this._repository,
    this._authRepository,
  );

  final TournamentRepository _repository;
  final AuthRepository _authRepository;
  
  static const _uuid = Uuid();

  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 1000;

  @override
  Future<Either<Failure, TournamentEntity>> call(
    CreateTournamentParams params,
  ) async {
    // 1. Validate input
    final trimmedName = params.name.trim();
    final validationErrors = <String, String>{};
    
    if (trimmedName.isEmpty) {
      validationErrors['name'] = 'Name is required';
    } else if (trimmedName.length > maxNameLength) {
      validationErrors['name'] = 'Name must be $maxNameLength characters or less';
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final scheduledDate = DateTime(
      params.scheduledDate.year,
      params.scheduledDate.month,
      params.scheduledDate.day,
    );
    if (scheduledDate.isBefore(todayDate)) {
      validationErrors['scheduledDate'] = 'Tournament date cannot be in the past';
    }

    if (params.description != null && params.description!.length > maxDescriptionLength) {
      validationErrors['description'] = 'Description must be $maxDescriptionLength characters or less';
    }

    if (validationErrors.isNotEmpty) {
      return Left(InputValidationFailure(
        userFriendlyMessage: 'Please fix the validation errors',
        fieldErrors: validationErrors,
      ));
    }

    // 2. Verify authenticated user and get organization
    final authResult = await _authRepository.getCurrentUser();
    final user = authResult.fold(
      (failure) => null,
      (user) => user,
    );
    
    if (user == null || user.organizationId.isEmpty) {
      return const Left(AuthFailure(
        userFriendlyMessage: 'You must be logged in with an organization to create a tournament',
      ));
    }

    // 3. Generate UUID
    final tournamentId = _uuid.v4();

    // 4. Build entity with defaults
    final tournament = TournamentEntity(
      id: tournamentId,
      organizationId: user.organizationId,
      createdByUserId: user.id,
      name: trimmedName,
      scheduledDate: params.scheduledDate,
      description: params.description?.trim(),
      federationType: FederationType.wt,
      status: TournamentStatus.draft,
      numberOfRings: 1,
      isTemplate: false,
      settingsJson: {},
      createdAt: DateTime.now(),
    );

    // 5. Persist via repository
    return _repository.createTournament(tournament, user.organizationId);
  }
}
```

**CRITICAL IMPLEMENTATION NOTES:**

1. **`@injectable` NOT `@LazySingleton`**: Use cases are `@injectable`. Repositories/datasources are `@LazySingleton`.

2. **Extends `UseCase<T, Params>`**: Follows base class pattern from `lib/core/usecases/use_case.dart`

3. **Freezed params class**: Uses `@freezed` with `part` directive for code generation

4. **`InputValidationFailure` with `fieldErrors`**: Returns validation errors in map format for form display

5. **Auth verification**: Uses `AuthRepository.getCurrentUser()` to verify user has organization

6. **UUID via `uuid` package**: Already in pubspec.yaml - use `static const _uuid = Uuid()` then `_uuid.v4()`

7. **Default values match schema**: `status: draft`, `federationType: wt`, `numberOfRings: 1`, `isTemplate: false`

---

- [x] ### Task 3: Update Tournament Barrel File — AC10

**File:** `lib/features/tournament/tournament.dart`

Add exports in the `// Domain - Use Cases` section:

```dart
// Domain - Use Cases
export 'domain/usecases/create_tournament_params.dart';
export 'domain/usecases/create_tournament_usecase.dart';
```

---

- [x] ### Task 4: Run build_runner

```bash
cd tkd_brackets && dart run build_runner build --delete-conflicting-outputs
```

Generates:
- `create_tournament_params.freezed.dart`
- Updates `injection.config.dart` (auto-registers `CreateTournamentUseCase`)

---

- [x] ### Task 5: Run flutter analyze — AC11

```bash
cd tkd_brackets && flutter analyze
```

Must pass with zero new errors.

---

- [x] ### Task 6: Write Unit Tests — AC9

**File:** `test/features/tournament/domain/usecases/create_tournament_usecase_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/create_tournament_params.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/create_tournament_usecase.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}
class FakeTournamentEntity extends Fake implements TournamentEntity {}
class FakeUserEntity extends Fake implements UserEntity {}

void main() {
  late CreateTournamentUseCase useCase;
  late MockTournamentRepository mockRepository;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    registerFallbackValue(FakeTournamentEntity());
    registerFallbackValue(FakeUserEntity());
  });

  setUp(() {
    mockRepository = MockTournamentRepository();
    mockAuthRepository = MockAuthRepository();
    useCase = CreateTournamentUseCase(mockRepository, mockAuthRepository);
  });

  final testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    organizationId: 'org-456',
    role: UserRole.owner,
    isActive: true,
    createdAt: DateTime(2024),
  );

  group('CreateTournamentUseCase', () {
    group('validation', () {
      test('returns InputValidationFailure for empty name', () async {
        final result = await useCase(CreateTournamentParams(
          name: '',
          scheduledDate: DateTime.now().add(const Duration(days: 7)),
        ));

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns InputValidationFailure for past date', () async {
        final result = await useCase(CreateTournamentParams(
          name: 'Test Tournament',
          scheduledDate: DateTime.now().subtract(const Duration(days: 1)),
        ));

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns InputValidationFailure for name > 100 chars', () async {
        final longName = 'A' * 101;
        final result = await useCase(CreateTournamentParams(
          name: longName,
          scheduledDate: DateTime.now().add(const Duration(days: 7)),
        ));

        expect(result.isLeft(), isTrue);
      });
    });

    group('auth verification', () {
      test('returns AuthFailure when user not authenticated', () async {
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => const Left(AuthFailure(
                  userFriendlyMessage: 'Not authenticated',
                )));

        final result = await useCase(CreateTournamentParams(
          name: 'Test Tournament',
          scheduledDate: DateTime.now().add(const Duration(days: 7)),
        ));

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns AuthFailure when user has no organization', () async {
        final userNoOrg = testUser.copyWith(organizationId: '');
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(userNoOrg));

        final result = await useCase(CreateTournamentParams(
          name: 'Test Tournament',
          scheduledDate: DateTime.now().add(const Duration(days: 7)),
        ));

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('successful creation', () {
      test('creates tournament with correct defaults', () async {
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(testUser));

        when(() => mockRepository.createTournament(any(), any()))
            .thenAnswer((_) async => Right(TournamentEntity(
                  id: 'tournament-123',
                  organizationId: 'org-456',
                  createdByUserId: 'user-123',
                  name: 'Test Tournament',
                  scheduledDate: DateTime(2026, 3, 15),
                  federationType: FederationType.wt,
                  status: TournamentStatus.draft,
                  numberOfRings: 1,
                  isTemplate: false,
                  settingsJson: {},
                  createdAt: DateTime.now(),
                )));

        final result = await useCase(CreateTournamentParams(
          name: 'Test Tournament',
          scheduledDate: DateTime(2026, 3, 15),
        ));

        expect(result.isRight(), isTrue);
        verify(() => mockRepository.createTournament(any(), 'org-456')).called(1);
      });
    });
  });
}
```

---

## Dev Notes

### What Already Exists (From Story 3.2)

- **TournamentEntity:** `lib/features/tournament/domain/entities/tournament_entity.dart` — Has `FederationType`, `TournamentStatus` enums
- **TournamentRepository:** `lib/features/tournament/domain/repositories/tournament_repository.dart` — Has `createTournament(TournamentEntity, String)` method
- **TournamentRepositoryImplementation:** Handles local + remote sync

### Key Patterns to Follow

1. **Use `@injectable`** — Not `@LazySingleton` (use cases are transient)
2. **Extend `UseCase<T, Params>`** — Import from `lib/core/usecases/use_case.dart`
3. **Freezed params** — Use `@freezed` with `part` directive, no `.g.dart` needed
4. **UUID via `uuid` package** — Already in pubspec.yaml, use `static const _uuid = Uuid()`
5. **`InputValidationFailure`** — For form validation with `fieldErrors` map
6. **Auth via `AuthRepository`** — Verify user has organization before creating

### Default Values (Match Schema)

| Field | Default |
|-------|---------|
| `status` | `TournamentStatus.draft` |
| `federationType` | `FederationType.wt` |
| `numberOfRings` | `1` |
| `isTemplate` | `false` |
| `settingsJson` | `{}` |

### What This Story Does NOT Include

- **Tournament settings** — That's Story 3.4
- **Presentation layer** — No BLoC/events (separate story)
- **Division creation** — That's later stories

### Testing Standards

- Use `mocktail` (NOT `mockito`)
- Register fallback values in `setUpAll()`
- Use `verify()` and `verifyInOrder()` for call verification
- Test validation, auth, success, and error paths

### References

- [Source: implementation-artifacts/3-2-tournament-entity-and-repository.md] — Entity, Repository
- [Source: implementation-artifacts/2-7-create-organization-use-case.md] — Use case pattern to follow
- [Source: lib/features/tournament/domain/entities/tournament_entity.dart] — Entity with enums
- [Source: lib/features/tournament/domain/repositories/tournament_repository.dart] — Repository interface
- [Source: lib/core/usecases/use_case.dart] — Base UseCase class
- [Source: lib/core/error/failures.dart] — InputValidationFailure, AuthFailure

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes

**Implementation Summary:**
- Created `CreateTournamentParams` freezed class with name, scheduledDate, and optional description
- Created `CreateTournamentUseCase` extending `UseCase<TournamentEntity, CreateTournamentParams>`
- Implemented input validation for: empty/whitespace-only name, name > 100 chars, past scheduledDate, description > 1000 chars
- Used UserRepository.getCurrentUser() to verify authenticated user has organization
- Generated UUID using uuid package
- Created tournament with defaults: status=draft, federationType=wt, numberOfRings=1, isTemplate=false
- Added exports to tournament.dart barrel file
- Generated freezed code with build_runner
- All 10 unit tests pass covering validation, auth verification, and successful creation

**Tests Added:**
- Validation: empty name, whitespace-only name, past date, name > 100 chars, description > 1000 chars
- Auth: user not authenticated, user has no organization
- Success: creates tournament with correct defaults, trims whitespace

**Files Created:**
- lib/features/tournament/domain/usecases/create_tournament_params.dart
- lib/features/tournament/domain/usecases/create_tournament_usecase.dart
- lib/features/tournament/domain/usecases/create_tournament_params.freezed.dart (generated)
- test/features/tournament/domain/usecases/create_tournament_usecase_test.dart

**Files Updated:**
- lib/features/tournament/tournament.dart - Added use case exports

**AC Verification:**
- AC1: ✅ CreateTournamentUseCase extends UseCase
- AC2: ✅ CreateTournamentParams freezed class with required name, scheduledDate, optional description
- AC3: ✅ Input validation with fieldErrors
- AC4: ✅ UUID generated using uuid package
- AC5: ✅ Tournament defaults: status=draft, federationType=wt, numberOfRings=1, isTemplate=false
- AC6: ✅ Gets organizationId from authenticated user via UserRepository
- AC7: ✅ Delegates to TournamentRepository.createTournament()
- AC8: ✅ Error cases propagated as Either<Failure, TournamentEntity>
- AC9: ✅ Unit tests verify validation, successful creation, error paths
- AC10: ✅ Exports added to tournament.dart
- AC11: ✅ flutter analyze passes with zero new errors

### File List

**Created:**
- `lib/features/tournament/domain/usecases/create_tournament_params.dart`
- `lib/features/tournament/domain/usecases/create_tournament_usecase.dart`
- `lib/features/tournament/domain/usecases/create_tournament_params.freezed.dart` (generated)
- `test/features/tournament/domain/usecases/create_tournament_usecase_test.dart`

**Updated:**
- `lib/features/tournament/tournament.dart` — Added use case exports
- `lib/core/di/injection.config.dart` — Auto-regenerated by build_runner

---

## Change Log

- 2026-02-16: Implemented CreateTournamentUseCase with input validation, auth verification, and unit tests (10 tests). Status changed to "review".
- 2026-02-16: [AI-Review] Fixed line length issue, directive ordering, comment reference, updated AC5 documentation to match entity schema. Status changed to "done".

