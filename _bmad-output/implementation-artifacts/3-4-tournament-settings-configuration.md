# Story 3.4: Tournament Settings Configuration

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an organizer,
I want to configure tournament settings like federation type, venue, and rings,
so that divisions and scoring are automatically configured correctly (FR2).

## Acceptance Criteria

> **AC1:** `UpdateTournamentSettingsUseCase` extends `UseCase<TournamentEntity, UpdateTournamentSettingsParams>` in domain layer
>
> **AC2:** `UpdateTournamentSettingsParams` freezed class created with required `tournamentId` (String), optional `federationType` (FederationType?), `venueName` (String?), `venueAddress` (String?), `ringCount` (int?), `scheduledStartTime` (DateTime?), `scheduledEndTime` (DateTime?)
>
> **AC3:** Input validation rejects: ringCount < 1, ringCount > 20, invalid federation_type, venueName > 200 chars, venueAddress > 500 chars — returns `InputValidationFailure` with `fieldErrors` map
>
> **AC4:** Empty string `''` for optional String fields is treated as "remove this value" (set to null)
>
> **AC5:** Use case fetches tournament via `TournamentRepository.getTournamentById(tournamentId)` and returns `NotFoundFailure` if tournament doesn't exist
>
> **AC6:** Use case verifies current user has permission (Owner or Admin role) to modify tournament settings — returns `AuthorizationPermissionDeniedFailure` if not authorized
>
> **AC7:** Only fields explicitly provided (non-null in params) are updated. Fields not in params remain unchanged. Uses `copyWith()` to build updated entity.
>
> **AC8:** Delegates to `TournamentRepository.updateTournament()` to persist (local + remote sync handled by repo)
>
> **AC9:** Error cases propagated as `Either<Failure, TournamentEntity>` with appropriate failure types
>
> **AC10:** Unit tests verify: validation, tournament-not-found, unauthorized, successful update, error paths
>
> **AC11:** Exports added to `tournament.dart` barrel file
>
> **AC12:** `flutter analyze` passes with zero new errors

## Tasks / Subtasks

- [x] ### Task 1: Create `UpdateTournamentSettingsParams` — AC2, AC11

**File:** `lib/features/tournament/domain/usecases/update_tournament_settings_params.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_tournament_settings_params.freezed.dart';

/// Parameters for [UpdateTournamentSettingsUseCase].
///
/// [tournamentId] — Required ID of tournament to update
/// [federationType] — Optional: federation type (WT, ITF, ATA, custom)
/// [venueName] — Optional: venue name (empty string removes value)
/// [venueAddress] — Optional: venue address (empty string removes value)
/// [ringCount] — Optional: number of rings (1-20)
/// [scheduledStartTime] — Optional: tournament start time
/// [scheduledEndTime] — Optional: tournament end time
@freezed
class UpdateTournamentSettingsParams with _$UpdateTournamentSettingsParams {
  const factory UpdateTournamentSettingsParams({
    required String tournamentId,
    FederationType? federationType,
    String? venueName,
    String? venueAddress,
    int? ringCount,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
  }) = _UpdateTournamentSettingsParams;
}
```

---

- [x] ### Task 2: Create `UpdateTournamentSettingsUseCase` — AC1, AC3, AC4, AC5, AC6, AC7, AC8, AC9

**File:** `lib/features/tournament/domain/usecases/update_tournament_settings_usecase.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/update_tournament_settings_params.dart';

@injectable
class UpdateTournamentSettingsUseCase
    extends UseCase<TournamentEntity, UpdateTournamentSettingsParams> {
  UpdateTournamentSettingsUseCase(
    this._repository,
    this._authRepository,
  );

  final TournamentRepository _repository;
  final AuthRepository _authRepository;

  static const int minRingCount = 1;
  static const int maxRingCount = 20;
  static const int maxVenueNameLength = 200;
  static const int maxVenueAddressLength = 500;

  @override
  Future<Either<Failure, TournamentEntity>> call(
    UpdateTournamentSettingsParams params,
  ) async {
    // 1. Validate input
    final validationErrors = <String, String>{};

    if (params.ringCount != null) {
      if (params.ringCount! < minRingCount || params.ringCount! > maxRingCount) {
        validationErrors['ringCount'] = 'Ring count must be between $minRingCount and $maxRingCount';
      }
    }

    if (params.venueName != null && params.venueName!.length > maxVenueNameLength) {
      validationErrors['venueName'] = 'Venue name must be $maxVenueNameLength characters or less';
    }

    if (params.venueAddress != null && params.venueAddress!.length > maxVenueAddressLength) {
      validationErrors['venueAddress'] = 'Venue address must be $maxVenueAddressLength characters or less';
    }

    if (validationErrors.isNotEmpty) {
      return Left(InputValidationFailure(
        userFriendlyMessage: 'Please fix the validation errors',
        fieldErrors: validationErrors,
      ));
    }

    // 2. Fetch tournament
    final tournamentResult = await _repository.getTournamentById(params.tournamentId);
    final tournament = tournamentResult.fold(
      (failure) => null,
      (t) => t,
    );

    if (tournament == null) {
      return Left(NotFoundFailure(
        userFriendlyMessage: 'Tournament not found',
        technicalDetails: 'No tournament exists with ID: ${params.tournamentId}',
      ));
    }

    // 3. Check authorization (Owner or Admin can modify)
    final authResult = await _authRepository.getCurrentUser();
    final user = authResult.fold(
      (failure) => null,
      (u) => u,
    );

    if (user == null) {
      return const Left(AuthenticationFailure(
        userFriendlyMessage: 'You must be logged in to update tournament settings',
      ));
    }

    // Check role is Owner or Admin
    final canModify = user.role == UserRole.owner || user.role == UserRole.admin;
    if (!canModify) {
      return const Left(AuthorizationPermissionDeniedFailure(
        userFriendlyMessage: 'Only Owners and Admins can modify tournament settings',
      ));
    }

    // 4. Build updated entity using copyWith
    // Empty string for optional fields means "remove value"
    final updatedTournament = tournament.copyWith(
      federationType: params.federationType,
      venueName: params.venueName?.isEmpty == true ? null : params.venueName,
      venueAddress: params.venueAddress?.isEmpty == true ? null : params.venueAddress,
      numberOfRings: params.ringCount ?? tournament.numberOfRings,
      scheduledStartTime: params.scheduledStartTime,
      scheduledEndTime: params.scheduledEndTime,
    );

    // 5. Persist via repository
    return _repository.updateTournament(updatedTournament);
  }
}
```

**CRITICAL IMPLEMENTATION NOTES:**

1. **`@injectable` NOT `@LazySingleton`**: Use cases are `@injectable`. Repositories/datasources are `@LazySingleton`.

2. **Extends `UseCase<T, Params>`**: Follows base class pattern from `lib/core/usecases/use_case.dart`

3. **Freezed params class**: Uses `@freezed` with `part` directive for code generation

4. **`InputValidationFailure` with `fieldErrors`**: Returns validation errors in map format for form display

5. **`copyWith` for updates**: TournamentEntity is Freezed, so use `copyWith()` to create modified entity

6. **Empty string = remove value**: When `venueName: ''` is passed, treat as "remove this field" by setting to `null`

7. **Authorization check**: Verify user is Owner or Admin before allowing modifications

8. **Error types used**:
   - `InputValidationFailure` for validation errors
   - `NotFoundFailure` for missing tournament (create this if not in failures.dart, or use `ServerResponseFailure` with 404)
   - `AuthorizationPermissionDeniedFailure` for permission denied
   - `AuthenticationFailure` for not logged in

---

- [x] ### Task 3: Update Tournament Barrel File — AC11

**File:** `lib/features/tournament/tournament.dart`

Add exports in the `// Domain - Use Cases` section:

```dart
// Domain - Use Cases
export 'domain/usecases/update_tournament_settings_params.dart';
export 'domain/usecases/update_tournament_settings_usecase.dart';
```

---

- [x] ### Task 4: Run build_runner

```bash
cd tkd_brackets && dart run build_runner build --delete-conflicting-outputs
```

Generates:
- `update_tournament_settings_params.freezed.dart`
- Updates `injection.config.dart` (auto-registers `UpdateTournamentSettingsUseCase`)

---

- [x] ### Task 5: Run flutter analyze — AC12

```bash
cd tkd_brackets && flutter analyze
```

Must pass with zero new errors.

---

- [x] ### Task 6: Write Unit Tests — AC10

**File:** `test/features/tournament/domain/usecases/update_tournament_settings_usecase_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/update_tournament_settings_params.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/update_tournament_settings_usecase.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}
class FakeTournamentEntity extends Fake implements TournamentEntity {}
class FakeUserEntity extends Fake implements UserEntity {}

void main() {
  late UpdateTournamentSettingsUseCase useCase;
  late MockTournamentRepository mockRepository;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    registerFallbackValue(FakeTournamentEntity());
    registerFallbackValue(FakeUserEntity());
  });

  setUp(() {
    mockRepository = MockTournamentRepository();
    mockAuthRepository = MockAuthRepository();
    useCase = UpdateTournamentSettingsUseCase(mockRepository, mockAuthRepository);
  });

  final testTournament = TournamentEntity(
    id: 'tournament-123',
    organizationId: 'org-456',
    createdByUserId: 'user-123',
    name: 'Test Tournament',
    scheduledDate: DateTime(2026, 3, 15),
    federationType: FederationType.wt,
    status: TournamentStatus.draft,
    numberOfRings: 2,
    settingsJson: {},
    isTemplate: false,
    createdAt: DateTime(2024),
  );

  final testOwner = UserEntity(
    id: 'user-123',
    email: 'owner@example.com',
    displayName: 'Owner User',
    organizationId: 'org-456',
    role: UserRole.owner,
    isActive: true,
    createdAt: DateTime(2024),
  );

  group('UpdateTournamentSettingsUseCase', () {
    group('validation', () {
      test('returns InputValidationFailure for ringCount < 1', () async {
        final result = await useCase(UpdateTournamentSettingsParams(
          tournamentId: 'tournament-123',
          ringCount: 0,
        ));

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns InputValidationFailure for ringCount > 20', () async {
        final result = await useCase(UpdateTournamentSettingsParams(
          tournamentId: 'tournament-123',
          ringCount: 21,
        ));

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns InputValidationFailure for venueName > 200 chars', () async {
        final longName = 'A' * 201;
        final result = await useCase(UpdateTournamentSettingsParams(
          tournamentId: 'tournament-123',
          venueName: longName,
        ));

        expect(result.isLeft(), isTrue);
      });

      test('returns InputValidationFailure for venueAddress > 500 chars', () async {
        final longAddress = 'A' * 501;
        final result = await useCase(UpdateTournamentSettingsParams(
          tournamentId: 'tournament-123',
          venueAddress: longAddress,
        ));

        expect(result.isLeft(), isTrue);
      });
    });

    group('tournament not found', () {
      test('returns NotFoundFailure when tournament does not exist', () async {
        when(() => mockRepository.getTournamentById(any()))
            .thenAnswer((_) async => Left(NotFoundFailure(
                  userFriendlyMessage: 'Not found',
                )));

        final result = await useCase(UpdateTournamentSettingsParams(
          tournamentId: 'nonexistent',
          venueName: 'New Venue',
        ));

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('authorization', () {
      test('returns AuthenticationFailure when user not authenticated', () async {
        when(() => mockRepository.getTournamentById(any()))
            .thenAnswer((_) async => Right(testTournament));
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => const Left(AuthenticationFailure(
                  userFriendlyMessage: 'Not authenticated',
                )));

        final result = await useCase(UpdateTournamentSettingsParams(
          tournamentId: 'tournament-123',
          venueName: 'New Venue',
        ));

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns AuthorizationPermissionDeniedFailure for Viewer role', () async {
        final viewerUser = testOwner.copyWith(role: UserRole.viewer);
        when(() => mockRepository.getTournamentById(any()))
            .thenAnswer((_) async => Right(testTournament));
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(viewerUser));

        final result = await useCase(UpdateTournamentSettingsParams(
          tournamentId: 'tournament-123',
          venueName: 'New Venue',
        ));

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('successful update', () {
      test('updates tournament with new settings', () async {
        when(() => mockRepository.getTournamentById(any()))
            .thenAnswer((_) async => Right(testTournament));
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(testOwner));
        when(() => mockRepository.updateTournament(any()))
            .thenAnswer((_) async => Right(testTournament.copyWith(
                  venueName: 'New Venue',
                  federationType: FederationType.itf,
                )));

        final result = await useCase(UpdateTournamentSettingsParams(
          tournamentId: 'tournament-123',
          venueName: 'New Venue',
          federationType: FederationType.itf,
        ));

        expect(result.isRight(), isTrue);
        verify(() => mockRepository.updateTournament(any())).called(1);
      });

      test('empty string removes venueName value', () async {
        final tournamentWithVenue = testTournament.copyWith(venueName: 'Old Venue');
        when(() => mockRepository.getTournamentById(any()))
            .thenAnswer((_) async => Right(tournamentWithVenue));
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(testOwner));
        when(() => mockRepository.updateTournament(any()))
            .thenAnswer((_) async => Right(tournamentWithVenue.copyWith(venueName: null)));

        final result = await useCase(UpdateTournamentSettingsParams(
          tournamentId: 'tournament-123',
          venueName: '', // Empty = remove
        ));

        expect(result.isRight(), isTrue);
        final updatedTournament = result.getOrElse(() => testTournament);
        expect(updatedTournament.venueName, isNull);
      });
    });
  });
}
```

---

## Dev Notes

### What Already Exists (From Story 3.2, 3.3)

- **TournamentEntity:** `lib/features/tournament/domain/entities/tournament_entity.dart` — Has `FederationType`, `TournamentStatus` enums with fields: `federationType`, `venueName`, `venueAddress`, `numberOfRings`, `scheduledStartTime`, `scheduledEndTime`
- **TournamentRepository:** `lib/features/tournament/domain/repositories/tournament_repository.dart` — Has `getTournamentById(String)` and `updateTournament(TournamentEntity)` methods
- **CreateTournamentUseCase:** Pattern to follow from Story 3.3
- **Failures:** `lib/core/error/failures.dart` — Has `InputValidationFailure`, `AuthorizationPermissionDeniedFailure`, `NotFoundFailure`, `AuthenticationFailure`

### Key Patterns to Follow

1. **Use `@injectable`** — Not `@LazySingleton` (use cases are transient)
2. **Extend `UseCase<T, Params>`** — Import from `lib/core/usecases/use_case.dart`
3. **Freezed params** — Use `@freezed` with `part` directive, make all fields optional except tournamentId
4. **`InputValidationFailure`** — For form validation with `fieldErrors` map
5. **TournamentRepository** — Use `getTournamentById(id)` to fetch, verify exists, then `updateTournament()` to save
6. **`copyWith` for updates** — Use Freezed's `copyWith()` method to build updated entity

### Federation Type Enum Values

From TournamentEntity:
- `wt` — World Taekwondo
- `itf` — International Taekwondo Federation
- `ata` — American Taekwondo Association
- `custom` — Custom federation

### Validation Rules

| Field | Validation |
|-------|------------|
| `ringCount` | 1-20, integer only |
| `federationType` | Must be valid enum value |
| `venueName` | Max 200 characters |
| `venueAddress` | Max 500 characters |
| Empty string `''` | Treated as "remove this value" (set to null) |

### Error Handling Mapping

| Scenario | Failure Type |
|----------|--------------|
| Invalid input (ringCount, venueName length) | `InputValidationFailure` |
| Tournament not found | `NotFoundFailure` |
| User not authenticated | `AuthenticationFailure` |
| User not Owner/Admin | `AuthorizationPermissionDeniedFailure` |
| Repository update fails | Propagated from repository |

### What This Story Does NOT Include

- **Federation Template Registry** — That's Story 3.8 (Federation Template Registry)
- **Division Template Loading** — Happens after federationType is set, in later stories
- **Presentation layer** — No BLoC/events (separate story)
- **Ring Assignment Service** — That's Story 3.12
- **settingsJson updates** — Reserved for future use

### Testing Standards

- Use `mocktail` (NOT `mockito`)
- Register fallback values in `setUpAll()`
- Use `verify()` and `verifyInOrder()` for call verification
- Test validation, not-found, unauthorized, success, and error paths

### Project Structure Notes

- Location: `lib/features/tournament/domain/usecases/`
- Barrel file: `lib/features/tournament/tournament.dart`
- Tests: `test/features/tournament/domain/usecases/`

### References

- [Source: implementation-artifacts/3-2-tournament-entity-and-repository.md] — Entity, Repository
- [Source: implementation-artifacts/3-3-create-tournament-use-case.md] — Use case pattern to follow
- [Source: lib/features/tournament/domain/entities/tournament_entity.dart] — Entity with enums
- [Source: lib/features/tournament/domain/repositories/tournament_repository.dart] — Repository interface
- [Source: lib/core/usecases/use_case.dart] — Base UseCase class
- [Source: lib/core/error/failures.dart] — Failure types

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

- Implemented UpdateTournamentSettingsUseCase following the existing CreateTournamentUseCase pattern
- Used UserRepository (not AuthRepository) for getting current user as per codebase conventions
- Added NotFoundFailure to failures.dart for proper error handling
- Created 17 unit tests covering validation, authorization, success, and error paths
- All tasks/subtasks completed with tests passing

### File List

- `lib/core/error/failures.dart` - Added NotFoundFailure class
- `lib/features/tournament/domain/usecases/update_tournament_settings_params.dart` - New params class
- `lib/features/tournament/domain/usecases/update_tournament_settings_params.freezed.dart` - Generated
- `lib/features/tournament/domain/usecases/update_tournament_settings_usecase.dart` - New use case
- `lib/features/tournament/tournament.dart` - Added exports
- `test/features/tournament/domain/usecases/update_tournament_settings_usecase_test.dart` - Unit tests (17 tests)
