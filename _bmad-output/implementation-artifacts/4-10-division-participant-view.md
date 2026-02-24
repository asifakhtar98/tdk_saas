# Story 4.10: Division Participant View

Status: done

**Created:** 2026-02-23

**Epic:** 4 - Participant Management

**FRs Covered:** FR20 (View all participants assigned to a division with roster verification before bracket generation)

**Dependencies:** Story 4.8 (Assign Participants to Divisions) - COMPLETE | Story 4.9 (Auto-Assignment Algorithm) - COMPLETE | Story 4.2 (Participant Entity) - COMPLETE | Epic 3 (Division Entity) - COMPLETE

---

## TL;DR — Critical Facts

**CURRENT STATE:**
- ✅ `lib/features/participant/domain/entities/participant_entity.dart` — ParticipantEntity (freezed) with fields: `id`, `divisionId`, `firstName`, `lastName`, `dateOfBirth`, `gender`, `weightKg`, `schoolOrDojangName`, `beltRank`, `seedNumber` (nullable int), `registrationNumber`, `isBye`, `checkInStatus`, `checkInAtTimestamp`, `dqReason`, `photoUrl`, `notes`, `syncVersion`, `isDeleted`, `deletedAtTimestamp`, `isDemoData`, `createdAtTimestamp`, `updatedAtTimestamp`. Has computed `age` getter. Uses `ParticipantStatus` enum and `Gender` enum.
- ✅ `lib/features/division/domain/entities/division_entity.dart` — DivisionEntity (freezed) with fields: `id`, `tournamentId`, `name`, `category` (DivisionCategory enum), `gender` (DivisionGender enum), `ageMin`, `ageMax`, `weightMinKg`, `weightMaxKg`, `beltRankMin`, `beltRankMax`, `bracketFormat` (BracketFormat enum), `assignedRingNumber`, `isCombined`, `displayOrder`, `status` (DivisionStatus enum: setup/ready/inProgress/completed), `isDeleted`, `deletedAtTimestamp`, `isDemoData`, `isCustom`, `createdAtTimestamp`, `updatedAtTimestamp`, `syncVersion`
- ✅ `lib/features/participant/domain/repositories/participant_repository.dart` — Abstract class with:
  - `getParticipantsForDivision(String divisionId)` → `Future<Either<Failure, List<ParticipantEntity>>>`
  - `getParticipantById(String id)` → `Future<Either<Failure, ParticipantEntity>>`
  - `updateParticipant(ParticipantEntity participant)` → `Future<Either<Failure, ParticipantEntity>>`
  - `createParticipant(ParticipantEntity)`, `deleteParticipant(String)`, `createParticipantsBatch(List<ParticipantEntity>)`
- ✅ `lib/features/division/domain/repositories/division_repository.dart` — Abstract class with:
  - `getDivisionById(String id)` → `Future<Either<Failure, DivisionEntity>>`
  - `getParticipantsForDivision(String divisionId)` → `Future<Either<Failure, List<ParticipantEntry>>>` ← ⚠️ Returns **Drift** `ParticipantEntry`, NOT domain entity!
- ✅ `lib/features/tournament/domain/repositories/tournament_repository.dart` — `getTournamentById(String id)` → `Future<Either<Failure, TournamentEntity>>`
- ✅ `lib/features/auth/domain/repositories/user_repository.dart` — `getCurrentUser()` → `Future<Either<Failure, UserEntity>>`
- ✅ `lib/features/auth/domain/entities/user_entity.dart` — UserEntity (freezed) with fields: `id`, `email`, `displayName`, `organizationId`, `role` (UserRole enum: owner/admin/scorer/viewer), `isActive`, `createdAt`, `avatarUrl`, `lastSignInAt`
- ✅ `lib/features/tournament/domain/entities/tournament_entity.dart` — TournamentEntity (freezed) with fields: `id`, `organizationId`, `createdByUserId`, `name`, `scheduledDate` (nullable DateTime), `federationType` (FederationType enum: wt/itf/ata/custom), `status` (TournamentStatus enum), `description`, `venueName`, `venueAddress`, `scheduledStartTime`, `scheduledEndTime`, `templateId`, `numberOfRings`, `settingsJson` (Map<String, dynamic>), `isTemplate`, `createdAt`, `updatedAtTimestamp`, `completedAtTimestamp`, `isDeleted`, `deletedAtTimestamp`, `syncVersion`
- ✅ `lib/core/database/app_database.dart` — `getParticipantsForDivision()` DB query orders by `seedNumber ASC, lastName ASC`
- ✅ `lib/core/usecases/use_case.dart` — `UseCase<T, Params>` base class with `Future<Either<Failure, T>> call(Params params)`
- ✅ `lib/core/error/failures.dart` — Contains: `Failure` (abstract base), `InputValidationFailure` (with `fieldErrors: Map<String, String>`), `NotFoundFailure`, `AuthorizationPermissionDeniedFailure`, `AuthenticationFailure`, `LocalCacheAccessFailure`, `LocalCacheWriteFailure`, `ValidationFailure`, `ServerConnectionFailure`, `ServerResponseFailure`
- ❌ `DivisionParticipantView` — **DOES NOT EXIST** — Create composite result type
- ❌ `GetDivisionParticipantsUseCase` — **DOES NOT EXIST** — Create in this story
- ❌ `UpdateSeedPositionsUseCase` — **DOES NOT EXIST** — Create in this story

**TARGET STATE:** Create a composite view model combining division info + participant list, a query use case that returns it, and a reordering use case for manual seeding. These prepare the roster for bracket generation verification.

**FILES TO CREATE:**
| File                                                                                    | Type       | Description                                                                                                                                                                       |
| --------------------------------------------------------------------------------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/features/participant/domain/usecases/division_participant_view.dart`               | Data class | Freezed composite result: division + participants + count                                                                                                                         |
| `lib/features/participant/domain/usecases/get_division_participants_usecase.dart`       | Use case   | Query division participants with auth & validation                                                                                                                                |
| `lib/features/participant/domain/usecases/update_seed_positions_usecase.dart`           | Use case   | Reorder use case — the `UpdateSeedPositionsParams` freezed class goes IN THIS SAME FILE (following pattern from `create_participant_params.dart` being separate but simpler here) |
| `test/features/participant/domain/usecases/get_division_participants_usecase_test.dart` | Test       | Unit tests for GetDivisionParticipantsUseCase                                                                                                                                     |
| `test/features/participant/domain/usecases/update_seed_positions_usecase_test.dart`     | Test       | Unit tests for UpdateSeedPositionsUseCase                                                                                                                                         |

**FILES TO MODIFY:**
| File                                                     | Change                                                                                                                  |
| -------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `lib/features/participant/domain/usecases/usecases.dart` | Export `division_participant_view.dart`, `get_division_participants_usecase.dart`, `update_seed_positions_usecase.dart` |

**KEY PREVIOUS STORY LESSONS — APPLY ALL:**
1. Use `@injectable` for use cases (NOT `@lazySingleton` — that's for repository implementations only)
2. Inject existing repositories — don't re-implement persistence or create new repository methods
3. Use `Either<Failure, T>` pattern from `package:fpdart/fpdart.dart` for ALL return types
4. Run `dart run build_runner build --delete-conflicting-outputs` after ANY freezed file changes
5. Keep domain layer pure — NO Drift imports, NO Supabase imports, NO Flutter UI imports in domain use cases
6. Use `freezed` for data classes: `import 'package:freezed_annotation/freezed_annotation.dart'` and `part '<filename>.freezed.dart'`
7. **Authorization pattern (MANDATORY for EVERY use case, even read-only):** Get user → Get division → Get tournament (via `division.tournamentId`) → Compare `tournament.organizationId` with `user.organizationId`
8. **All 4 repositories required for authorization:** `ParticipantRepository`, `DivisionRepository`, `TournamentRepository`, `UserRepository`
9. **Division status check pattern (from Story 4.8):** Only allow MODIFICATION when `division.status == DivisionStatus.setup || division.status == DivisionStatus.ready`. READ operations (GetDivisionParticipantsUseCase) do NOT need this check.
10. **NotFoundFailure for missing entities** — NOT `LocalCacheAccessFailure` (lesson from Story 4.2 code review)
11. **Use `copyWith()` for immutable entity updates** — do NOT manually construct new entities
12. **Increment `syncVersion` in use case entity updates** — `participant.syncVersion + 1`. Note: the repository implementation ALSO increments syncVersion internally. This double-increment is the ESTABLISHED PATTERN across all use cases (see: `assign_to_division_usecase.dart:122`, `disqualify_participant_usecase.dart:36`, `mark_no_show_usecase.dart:23`). DO NOT "optimize" by removing the use case increment.
13. **Update `updatedAtTimestamp` in use case entity updates** — `DateTime.now()`
14. **Testing uses `mocktail` package** — NOT `mockito`. NO `@GenerateMocks` annotation. Mocks are manual: `class MockFoo extends Mock implements Foo {}`
15. **Testing requires `registerFallbackValue`** — When using `any()` matcher with entity-typed arguments, register a fallback: `class FakeParticipantEntity extends Fake implements ParticipantEntity {}` in `setUpAll()`. Create fakes: `class FakeParticipantEntity extends Fake implements ParticipantEntity {}`

---

## Story

**As an** organizer,
**I want** to view all participants assigned to a division,
**So that** I can verify the roster before generating brackets (FR20).

---

## Acceptance Criteria

### AC1: DivisionParticipantView Freezed Class

- [x] **AC1.1:** `DivisionParticipantView` freezed class created at `lib/features/participant/domain/usecases/division_participant_view.dart`:
  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';
  import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
  import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';

  part 'division_participant_view.freezed.dart';

  /// Composite view model combining division metadata with its participant roster.
  ///
  /// Used by [GetDivisionParticipantsUseCase] to return all information
  /// needed for roster verification before bracket generation.
  @freezed
  class DivisionParticipantView with _$DivisionParticipantView {
    const factory DivisionParticipantView({
      /// The division being viewed.
      required DivisionEntity division,

      /// Ordered list of participants in this division.
      /// Sorted by seedNumber ASC, then lastName ASC (matching DB query).
      required List<ParticipantEntity> participants,

      /// Total count of participants (convenience field, equals participants.length).
      required int participantCount,
    }) = _DivisionParticipantView;
  }
  ```
| 2026-02-24 | Story 4.10 | Implemented `DivisionParticipantView`, `GetDivisionParticipantsUseCase`, and `UpdateSeedPositionsUseCase`. All unit tests passed (272/272 in feature). |
| 2026-02-24 | Story 4.10 | Fixed `syncVersion` double-increment pattern and updated barrel file. |
- [x] **AC1.2:** `part 'division_participant_view.freezed.dart'` directive present — this is REQUIRED for freezed code gen
- [x] **AC1.3:** Code generation runs without errors: `dart run build_runner build --delete-conflicting-outputs`

### AC2: GetDivisionParticipantsUseCase

- [x] **AC2.1:** `GetDivisionParticipantsUseCase` created at `lib/features/participant/domain/usecases/get_division_participants_usecase.dart`
- [x] **AC2.2:** Class annotated with `@injectable` — NOT `@lazySingleton`
- [x] **AC2.3:** Constructor injects exactly 4 repositories in this exact order:
  ```dart
  import 'package:fpdart/fpdart.dart';
  import 'package:injectable/injectable.dart';
  import 'package:tkd_brackets/core/error/failures.dart';
  import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
  import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
  import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
  import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
  import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
  import 'package:tkd_brackets/features/participant/domain/usecases/division_participant_view.dart';
  import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

  @injectable
  class GetDivisionParticipantsUseCase {
    GetDivisionParticipantsUseCase(
      this._participantRepository,
      this._divisionRepository,
      this._tournamentRepository,
      this._userRepository,
    );

    final ParticipantRepository _participantRepository;
    final DivisionRepository _divisionRepository;
    final TournamentRepository _tournamentRepository;
    final UserRepository _userRepository;
  ```
- [x] **AC2.4:** `call(String divisionId)` method signature: `Future<Either<Failure, DivisionParticipantView>> call(String divisionId) async { ... }`
- [x] **AC2.5:** Validation FIRST: Returns `InputValidationFailure` if `divisionId` is empty:
  ```dart
  if (divisionId.isEmpty) {
    return const Left(
      InputValidationFailure(
        userFriendlyMessage: 'Division ID is required',
        fieldErrors: {'divisionId': 'Division ID cannot be empty'},
      ),
    );
  }
  ```
- [x] **AC2.6:** Auth check sequence (copy EXACTLY from `AssignToDivisionUseCase` pattern):
  ```dart
  // Step 1: Get current user
  final userResult = await _userRepository.getCurrentUser();
  final user = userResult.fold((failure) => null, (user) => user);
  if (user == null || user.organizationId.isEmpty) {
    return const Left(
      AuthorizationPermissionDeniedFailure(
        userFriendlyMessage:
            'You must be logged in with an organization to view division participants',
      ),
    );
  }

  // Step 2: Get division
  final divisionResult = await _divisionRepository.getDivisionById(divisionId);
  final division = divisionResult.fold((failure) => null, (d) => d);
  if (division == null) {
    return const Left(
      NotFoundFailure(userFriendlyMessage: 'Division not found'),
    );
  }

  // Step 3: Get tournament for org verification
  final tournamentResult = await _tournamentRepository.getTournamentById(
    division.tournamentId,
  );
  final tournament = tournamentResult.fold((failure) => null, (t) => t);
  if (tournament == null) {
    return const Left(
      NotFoundFailure(userFriendlyMessage: 'Tournament not found'),
    );
  }

  // Step 4: Verify org ownership
  if (tournament.organizationId != user.organizationId) {
    return const Left(
      AuthorizationPermissionDeniedFailure(
        userFriendlyMessage:
            'You do not have permission to view participants in this division',
      ),
    );
  }
  ```
- [x] **AC2.7:** After auth passes, fetch participants via **`_participantRepository.getParticipantsForDivision(divisionId)`**:
  ```dart
  // Step 5: Fetch participants — use ParticipantRepository (returns domain entities)
  // DO NOT use _divisionRepository.getParticipantsForDivision() — that returns Drift ParticipantEntry, not domain ParticipantEntity
  final participantsResult = await _participantRepository.getParticipantsForDivision(divisionId);

  return participantsResult.fold(
    (failure) => Left(failure),
    (participants) => Right(
      DivisionParticipantView(
        division: division,
        participants: participants,
        participantCount: participants.length,
      ),
    ),
  );
  ```
- [x] **AC2.8:** NO division status check on this read-only use case — organizers must be able to view participants at ANY stage (setup, ready, inProgress, completed)

### AC3: UpdateSeedPositionsUseCase

- [x] **AC3.1:** `UpdateSeedPositionsUseCase` created at `lib/features/participant/domain/usecases/update_seed_positions_usecase.dart`
- [x] **AC3.2:** Class annotated with `@injectable`
- [x] **AC3.3:** Constructor injects exactly 4 repositories (same as GetDivisionParticipantsUseCase)
- [x] **AC3.4:** `UpdateSeedPositionsParams` freezed class defined **IN THE SAME FILE** (above the use case class):
  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';
  import 'package:fpdart/fpdart.dart';
  import 'package:injectable/injectable.dart';
  import 'package:tkd_brackets/core/error/failures.dart';
  import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
  import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
  import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
  import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
  import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
  import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

  part 'update_seed_positions_usecase.freezed.dart';

  @freezed
  class UpdateSeedPositionsParams with _$UpdateSeedPositionsParams {
    const factory UpdateSeedPositionsParams({
      /// The division whose participants are being reordered.
      required String divisionId,

      /// Ordered list of participant IDs in the desired seed order.
      /// Position 0 → seedNumber 1, Position 1 → seedNumber 2, etc.
      /// This list may be a SUBSET of all participants in the division —
      /// only the listed participants get new seed numbers.
      required List<String> participantIdsInOrder,
    }) = _UpdateSeedPositionsParams;
  }
  ```
- [x] **AC3.5:** `call(UpdateSeedPositionsParams params)` method returns `Future<Either<Failure, List<ParticipantEntity>>>`
- [x] **AC3.6:** Validation checks executed BEFORE auth (fail fast on bad input):
  ```dart
  if (params.divisionId.isEmpty) {
    return const Left(
      InputValidationFailure(
        userFriendlyMessage: 'Division ID is required',
        fieldErrors: {'divisionId': 'Division ID cannot be empty'},
      ),
    );
  }

  if (params.participantIdsInOrder.isEmpty) {
    return const Left(
      InputValidationFailure(
        userFriendlyMessage: 'Participant list is required for reordering',
        fieldErrors: {'participantIdsInOrder': 'List cannot be empty'},
      ),
    );
  }

  // Check for duplicate IDs using Set comparison
  if (params.participantIdsInOrder.toSet().length != params.participantIdsInOrder.length) {
    return const Left(
      InputValidationFailure(
        userFriendlyMessage: 'Duplicate participant IDs are not allowed',
        fieldErrors: {'participantIdsInOrder': 'Contains duplicate IDs'},
      ),
    );
  }
  ```
- [x] **AC3.7:** Auth check (SAME pattern as AC2.6 — exact same code)
- [x] **AC3.8:** Division status check (write operation — REQUIRED):
  ```dart
  if (division.status != DivisionStatus.setup &&
      division.status != DivisionStatus.ready) {
    return const Left(
      InputValidationFailure(
        userFriendlyMessage:
            'Cannot reorder participants in a division that is in progress or completed',
        fieldErrors: {
          'divisionId': 'Division is not accepting modifications',
        },
      ),
    );
  }
  ```
- [x] **AC3.9:** For each participant ID in order, process sequentially:
  ```dart
  final updatedParticipants = <ParticipantEntity>[];

  for (int i = 0; i < params.participantIdsInOrder.length; i++) {
    final participantId = params.participantIdsInOrder[i];

    // Fetch participant
    final participantResult = await _participantRepository.getParticipantById(participantId);
    final participant = participantResult.fold((failure) => null, (p) => p);

    if (participant == null) {
      return Left(
        NotFoundFailure(
          userFriendlyMessage: 'Participant not found: $participantId',
        ),
      );
    }

    // Verify participant belongs to this division
    if (participant.divisionId != params.divisionId) {
      return Left(
        InputValidationFailure(
          userFriendlyMessage:
              'Participant ${participant.firstName} ${participant.lastName} '
              'does not belong to this division',
          fieldErrors: {
            'participantId': 'Participant $participantId belongs to division ${participant.divisionId}',
          },
        ),
      );
    }

    // Update seed position using copyWith pattern
    final updatedParticipant = participant.copyWith(
      seedNumber: i + 1, // 1-based seed numbering
      syncVersion: participant.syncVersion + 1, // MUST increment (established pattern)
      updatedAtTimestamp: DateTime.now(), // MUST update timestamp
    );

    // Persist the update
    final updateResult = await _participantRepository.updateParticipant(updatedParticipant);

    // Propagate repository failures immediately
    final savedParticipant = updateResult.fold((failure) => null, (p) => p);
    if (savedParticipant == null) {
      return updateResult.fold(
        (failure) => Left(failure),
        (_) => throw StateError('Unreachable'),
      );
    }

    updatedParticipants.add(savedParticipant);
  }

  return Right(updatedParticipants);
  ```
- [x] **AC3.10:** Return the list of all successfully updated `ParticipantEntity` objects wrapped in `Right()`

### AC4: Barrel File Updated

- [x] **AC4.1:** `lib/features/participant/domain/usecases/usecases.dart` — add these 3 lines (alphabetical order, matching existing pattern):
  ```dart
  export 'division_participant_view.dart';
  export 'get_division_participants_usecase.dart';
  export 'update_seed_positions_usecase.dart';
  ```

### AC5: Unit Tests — GetDivisionParticipantsUseCase

- [x] **AC5.1:** Test file at `test/features/participant/domain/usecases/get_division_participants_usecase_test.dart`
- [x] **AC5.2:** Uses `package:mocktail/mocktail.dart` — NOT mockito. Mocks defined as:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:fpdart/fpdart.dart';
  import 'package:mocktail/mocktail.dart';
  import 'package:tkd_brackets/core/error/failures.dart';
  import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
  import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
  import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
  import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
  import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
  import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
  import 'package:tkd_brackets/features/participant/domain/usecases/division_participant_view.dart';
  import 'package:tkd_brackets/features/participant/domain/usecases/get_division_participants_usecase.dart';
  import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
  import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

  // ── Mocks (mocktail pattern — NO @GenerateMocks) ──
  class MockParticipantRepository extends Mock implements ParticipantRepository {}
  class MockDivisionRepository extends Mock implements DivisionRepository {}
  class MockTournamentRepository extends Mock implements TournamentRepository {}
  class MockUserRepository extends Mock implements UserRepository {}

  // ── No Fakes needed for this use case (no any() matchers on entity-typed params) ──
  ```
- [x] **AC5.3:** Test setup with `setupSuccessMocks()` helper:
  ```dart
  void main() {
    late GetDivisionParticipantsUseCase useCase;
    late MockParticipantRepository mockParticipantRepo;
    late MockDivisionRepository mockDivisionRepo;
    late MockTournamentRepository mockTournamentRepo;
    late MockUserRepository mockUserRepo;

    setUp(() {
      mockParticipantRepo = MockParticipantRepository();
      mockDivisionRepo = MockDivisionRepository();
      mockTournamentRepo = MockTournamentRepository();
      mockUserRepo = MockUserRepository();
      useCase = GetDivisionParticipantsUseCase(
        mockParticipantRepo,
        mockDivisionRepo,
        mockTournamentRepo,
        mockUserRepo,
      );
    });

    // ── Test entity factories (ALL required fields provided) ──

    final tUser = UserEntity(
      id: 'user-id',
      email: 'test@example.com',
      displayName: 'Test User',
      organizationId: 'org-id',
      role: UserRole.owner,
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
    );

    final tTournament = TournamentEntity(
      id: 'tournament-id',
      organizationId: 'org-id',       // ← MUST match tUser.organizationId for success
      createdByUserId: 'user-id',
      name: 'Test Tournament',
      scheduledDate: DateTime(2024, 6, 1),
      federationType: FederationType.wt,
      status: TournamentStatus.active,
      numberOfRings: 2,
      isTemplate: false,
      settingsJson: const {},
      createdAt: DateTime(2024, 1, 1),
      updatedAtTimestamp: DateTime(2024, 1, 1),
    );

    final tDivision = DivisionEntity(
      id: 'division-id',
      tournamentId: 'tournament-id',   // ← links to tTournament.id
      name: 'Test Division',
      category: DivisionCategory.sparring,
      gender: DivisionGender.male,
      bracketFormat: BracketFormat.singleElimination,
      status: DivisionStatus.setup,
      syncVersion: 1,
      createdAtTimestamp: DateTime(2024, 1, 1),
      updatedAtTimestamp: DateTime(2024, 1, 1),
    );

    final tParticipant1 = ParticipantEntity(
      id: 'p1',
      divisionId: 'division-id',       // ← MUST match tDivision.id
      firstName: 'Alice',
      lastName: 'Kim',
      schoolOrDojangName: 'Seoul Dojang',
      seedNumber: 1,
      createdAtTimestamp: DateTime(2024, 1, 1),
      updatedAtTimestamp: DateTime(2024, 1, 1),
    );

    final tParticipant2 = ParticipantEntity(
      id: 'p2',
      divisionId: 'division-id',
      firstName: 'Bob',
      lastName: 'Lee',
      schoolOrDojangName: 'Busan Dojang',
      seedNumber: 2,
      createdAtTimestamp: DateTime(2024, 1, 1),
      updatedAtTimestamp: DateTime(2024, 1, 1),
    );

    void setupSuccessMocks({List<ParticipantEntity>? participants}) {
      when(() => mockUserRepo.getCurrentUser())
          .thenAnswer((_) async => Right(tUser));
      when(() => mockDivisionRepo.getDivisionById('division-id'))
          .thenAnswer((_) async => Right(tDivision));
      when(() => mockTournamentRepo.getTournamentById('tournament-id'))
          .thenAnswer((_) async => Right(tTournament));
      when(() => mockParticipantRepo.getParticipantsForDivision('division-id'))
          .thenAnswer((_) async => Right(participants ?? [tParticipant1, tParticipant2]));
    }

    // ... test groups follow
  }
  ```
- [x] **AC5.4:** Test: returns participants and division info for valid division — verify `result.isRight()`, `view.division == tDivision`, `view.participants.length == 2`, `view.participantCount == 2`
- [x] **AC5.5:** Test: returns empty list when division has no participants — pass `participants: []` to `setupSuccessMocks`, verify `view.participants.isEmpty`, `view.participantCount == 0`
- [x] **AC5.6:** Test: returns `InputValidationFailure` for empty divisionId — call `useCase('')`, verify `result.isLeft()` and failure `isA<InputValidationFailure>()`
- [x] **AC5.7:** Test: returns `AuthorizationPermissionDeniedFailure` when user not logged in — mock `getCurrentUser()` to return `Left(AuthenticationFailure(...))`, verify `isA<AuthorizationPermissionDeniedFailure>()`
- [x] **AC5.8:** Test: returns `AuthorizationPermissionDeniedFailure` when user has empty organizationId — mock to return `Right(tUser.copyWith(organizationId: ''))`, verify failure
- [x] **AC5.9:** Test: returns `NotFoundFailure` when division not found — mock `getDivisionById` to return `Left(NotFoundFailure())`
- [x] **AC5.10:** Test: returns `NotFoundFailure` when tournament not found — mock `getTournamentById` to return `Left(NotFoundFailure())`
- [x] **AC5.11:** Test: returns `AuthorizationPermissionDeniedFailure` when user org doesn't match tournament org — mock tournament with `organizationId: 'other-org'`
- [x] **AC5.12:** Test: `participantCount` equals `participants.length` — already verified in AC5.4 but worth explicit assertion
- [x] **AC5.13:** Test: propagates repository failure from `getParticipantsForDivision` — mock to return `Left(LocalCacheAccessFailure())`, verify the same failure propagates

### AC6: Unit Tests — UpdateSeedPositionsUseCase

- [x] **AC6.1:** Test file at `test/features/participant/domain/usecases/update_seed_positions_usecase_test.dart`
- [x] **AC6.2:** Uses `package:mocktail/mocktail.dart`. Mock + Fake declarations:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:fpdart/fpdart.dart';
  import 'package:mocktail/mocktail.dart';
  import 'package:tkd_brackets/core/error/failures.dart';
  import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
  import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
  import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
  import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
  import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
  import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
  import 'package:tkd_brackets/features/participant/domain/usecases/update_seed_positions_usecase.dart';
  import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
  import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

  class MockParticipantRepository extends Mock implements ParticipantRepository {}
  class MockDivisionRepository extends Mock implements DivisionRepository {}
  class MockTournamentRepository extends Mock implements TournamentRepository {}
  class MockUserRepository extends Mock implements UserRepository {}

  // ⚠️ REQUIRED: updateParticipant(any()) uses `any()` matcher with ParticipantEntity type
  class FakeParticipantEntity extends Fake implements ParticipantEntity {}
  ```
- [x] **AC6.3:** `setUpAll` registers fallback value:
  ```dart
  setUpAll(() {
    registerFallbackValue(FakeParticipantEntity());
  });
  ```
- [x] **AC6.4:** Test entity factories — same as AC5.3 pattern, plus division variants:
  ```dart
  final tDivisionSetup = DivisionEntity(
    id: 'division-id',
    tournamentId: 'tournament-id',
    name: 'Test Division',
    category: DivisionCategory.sparring,
    gender: DivisionGender.male,
    bracketFormat: BracketFormat.singleElimination,
    status: DivisionStatus.setup,
    syncVersion: 1,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  final tDivisionReady = tDivisionSetup.copyWith(status: DivisionStatus.ready);
  final tDivisionInProgress = tDivisionSetup.copyWith(status: DivisionStatus.inProgress);
  final tDivisionCompleted = tDivisionSetup.copyWith(status: DivisionStatus.completed);
  ```
- [x] **AC6.5:** `setupSuccessMocks` helper — must mock `getParticipantById` for EACH participant ID:
  ```dart
  void setupSuccessMocks({DivisionEntity? division}) {
    when(() => mockUserRepo.getCurrentUser())
        .thenAnswer((_) async => Right(tUser));
    when(() => mockDivisionRepo.getDivisionById('division-id'))
        .thenAnswer((_) async => Right(division ?? tDivisionSetup));
    when(() => mockTournamentRepo.getTournamentById('tournament-id'))
        .thenAnswer((_) async => Right(tTournament));
    // Mock getParticipantById for each participant
    when(() => mockParticipantRepo.getParticipantById('p1'))
        .thenAnswer((_) async => Right(tParticipant1));
    when(() => mockParticipantRepo.getParticipantById('p2'))
        .thenAnswer((_) async => Right(tParticipant2));
    when(() => mockParticipantRepo.getParticipantById('p3'))
        .thenAnswer((_) async => Right(tParticipant3));
    // Mock updateParticipant to return the participant it receives
    when(() => mockParticipantRepo.updateParticipant(any())).thenAnswer(
      (invocation) async {
        final participant = invocation.positionalArguments.first as ParticipantEntity;
        return Right(participant);
      },
    );
  }
  ```
- [x] **AC6.6:** Test: successfully reorders 3 participants — call with `['p3', 'p1', 'p2']`, verify result is `Right`, verify `result[0].seedNumber == 1`, `result[1].seedNumber == 2`, `result[2].seedNumber == 3`, verify `updateParticipant` called 3 times
- [x] **AC6.7:** Test: returns `InputValidationFailure` for empty divisionId
- [x] **AC6.8:** Test: returns `InputValidationFailure` for empty participantIdsInOrder list
- [x] **AC6.9:** Test: returns `InputValidationFailure` for duplicate participant IDs in list — e.g. `['p1', 'p1']`
- [x] **AC6.10:** Test: returns `AuthorizationPermissionDeniedFailure` when user not logged in
- [x] **AC6.11:** Test: returns `NotFoundFailure` when division not found
- [x] **AC6.12:** Test: returns `AuthorizationPermissionDeniedFailure` when user org doesn't match
- [x] **AC6.13:** Test: returns `InputValidationFailure` when division status is `inProgress` — pass `division: tDivisionInProgress`
- [x] **AC6.14:** Test: returns `InputValidationFailure` when division status is `completed` — pass `division: tDivisionCompleted`
- [x] **AC6.15:** Test: allows reordering when division status is `setup`
- [x] **AC6.16:** Test: allows reordering when division status is `ready` — pass `division: tDivisionReady`
- [x] **AC6.17:** Test: returns `NotFoundFailure` when a participant ID doesn't exist — mock `getParticipantById('p999')` to return `Left(NotFoundFailure())`
- [x] **AC6.18:** Test: returns `InputValidationFailure` when participant doesn't belong to specified division — create participant with `divisionId: 'other-division'`
- [x] **AC6.19:** Test: each updated participant has `seedNumber` matching position + 1 — capture args from `updateParticipant` calls
- [x] **AC6.20:** Test: each updated participant has incremented `syncVersion`
- [x] **AC6.21:** Test: propagates repository failure from `updateParticipant` — mock to return `Left(LocalCacheWriteFailure(...))`

### AC7: Build Verification

- [x] **AC7.1:** `dart run build_runner build --delete-conflicting-outputs` completes without errors
- [x] **AC7.2:** `dart analyze` shows no errors in modified/created files
- [x] **AC7.3:** All new tests pass: `flutter test test/features/participant/domain/usecases/get_division_participants_usecase_test.dart test/features/participant/domain/usecases/update_seed_positions_usecase_test.dart`
- [x] **AC7.4:** All existing tests still pass: `flutter test test/features/participant/` (no regressions)

---

## Dev Notes

### ⚠️ CRITICAL: Which Repository for Participant Retrieval?

**Use `ParticipantRepository.getParticipantsForDivision()`. NEVER use `DivisionRepository.getParticipantsForDivision()`.**

The division repository's method returns `List<ParticipantEntry>` (Drift data class from `app_database.g.dart`), while the participant repository's method returns `List<ParticipantEntity>` (domain entity from `participant_entity.dart`). **Domain use cases MUST work with domain entities only** — NEVER import or reference Drift data classes.

```
✅ ParticipantRepository.getParticipantsForDivision(divisionId)
   → Either<Failure, List<ParticipantEntity>>  [DOMAIN ENTITY — correct]

❌ DivisionRepository.getParticipantsForDivision(divisionId)
   → Either<Failure, List<ParticipantEntry>>   [DRIFT DATA CLASS — WRONG for domain layer]
```

If you import `ParticipantEntry` in the use case, you are violating Clean Architecture. The imports in use case files should NEVER include `package:tkd_brackets/core/database/app_database.dart`.

### ⚠️ CRITICAL: Mock Library is `mocktail` — NOT `mockito`

The ENTIRE project uses `package:mocktail/mocktail.dart` for testing. This means:
- **NO** `@GenerateMocks` annotation — that's a `mockito` feature
- **NO** `import 'package:mockito/mockito.dart'`
- **NO** `import 'package:mockito/annotations.dart'`
- **NO** need to run `build_runner` for mock generation (mocktail mocks are manual)

Instead, use this pattern (verified from `assign_to_division_usecase_test.dart`):
```dart
// Manual mock declarations (top of test file, outside main())
class MockParticipantRepository extends Mock implements ParticipantRepository {}
class MockDivisionRepository extends Mock implements DivisionRepository {}
class MockTournamentRepository extends Mock implements TournamentRepository {}
class MockUserRepository extends Mock implements UserRepository {}

// Fake declarations — ONLY needed when using any() matcher with entity-typed params
class FakeParticipantEntity extends Fake implements ParticipantEntity {}

void main() {
  // In setUpAll — register fallback values for any() matchers
  setUpAll(() {
    registerFallbackValue(FakeParticipantEntity());
  });
}
```

**When is `FakeParticipantEntity` needed?**
- `UpdateSeedPositionsUseCase` test: YES — because `updateParticipant(any())` uses `any()` matcher with `ParticipantEntity` type
- `GetDivisionParticipantsUseCase` test: NO — no `any()` matchers needed (all arguments are strings)

### ⚠️ CRITICAL: syncVersion Double-Increment Pattern

The `ParticipantRepositoryImplementation.updateParticipant()` method **internally increments syncVersion** (see line 123 of `participant_repository_implementation.dart`):
```dart
final newSyncVersion = (existing?.syncVersion ?? 0) + 1;
```

However, ALL existing use cases ALSO increment syncVersion before calling the repository:
```dart
final updatedParticipant = participant.copyWith(
  syncVersion: participant.syncVersion + 1,  // Use case increment
  ...
);
return _participantRepository.updateParticipant(updatedParticipant);
// Repository ALSO increments internally → effective double-increment
```

This is the **ESTABLISHED PATTERN** across:
- `assign_to_division_usecase.dart:122`
- `auto_assign_participants_usecase.dart:152`
- `disqualify_participant_usecase.dart:36`
- `mark_no_show_usecase.dart:23`
- `update_participant_status_usecase.dart:110`

**DO NOT "optimize" by removing the use case-level increment.** Follow the established pattern exactly.

### Architecture: Why No Junction Table?

The current architecture uses a **direct FK approach** — each `ParticipantEntity` has a `divisionId` field pointing to a single division. There is no `division_participants` junction table. A participant is "assigned" to a division by setting its `divisionId`. This was decided in Story 4.8.

**DO NOT create a junction table, junction entity, or junction model.** Use the existing `divisionId` field on `ParticipantEntity`.

### Seeding Order: DB Query Already Handles Sorting

The `AppDatabase.getParticipantsForDivision()` method already orders results by:
```dart
..orderBy([
  (p) => OrderingTerm.asc(p.seedNumber),    // Seeded participants first
  (p) => OrderingTerm.asc(p.lastName),       // Then alphabetical by last name
])
```

In SQLite, `NULL` values sort **after** non-NULL in ascending order. So participants with `seedNumber = null` appear after seeded participants. The `UpdateSeedPositionsUseCase` assigns sequential seed numbers starting from 1 (1-based, not 0-based).

### Partial Reseeding

The `UpdateSeedPositionsUseCase` accepts a list that may be a **subset** of all participants in the division. Only the listed participants get new seed numbers. Participants not in the list retain their existing `seedNumber` (possibly null). This is intentional — organizers may want to seed only the top N participants.

### Entity Constructor Required Fields Reference

When creating test entities, ALL required fields MUST be provided. Here are the exact constructors:

**UserEntity** (from `user_entity.dart`):
```dart
UserEntity(
  id: 'user-id',
  email: 'test@example.com',
  displayName: 'Test User',
  organizationId: 'org-id',
  role: UserRole.owner,
  isActive: true,
  createdAt: DateTime(2024, 1, 1),
)
```

**TournamentEntity** (from `tournament_entity.dart`):
```dart
TournamentEntity(
  id: 'tournament-id',
  organizationId: 'org-id',
  createdByUserId: 'user-id',
  name: 'Test Tournament',
  scheduledDate: DateTime(2024, 6, 1),  // nullable but provide for tests
  federationType: FederationType.wt,
  status: TournamentStatus.active,
  numberOfRings: 2,
  isTemplate: false,
  settingsJson: const {},
  createdAt: DateTime(2024, 1, 1),
  updatedAtTimestamp: DateTime(2024, 1, 1),
)
```

**DivisionEntity** (from `division_entity.dart`):
```dart
DivisionEntity(
  id: 'division-id',
  tournamentId: 'tournament-id',
  name: 'Test Division',
  category: DivisionCategory.sparring,
  gender: DivisionGender.male,
  bracketFormat: BracketFormat.singleElimination,
  status: DivisionStatus.setup,
  syncVersion: 1,
  createdAtTimestamp: DateTime(2024, 1, 1),
  updatedAtTimestamp: DateTime(2024, 1, 1),
)
```

**ParticipantEntity** (from `participant_entity.dart`):
```dart
ParticipantEntity(
  id: 'participant-1',
  divisionId: 'division-id',
  firstName: 'Alice',
  lastName: 'Kim',
  schoolOrDojangName: 'Seoul Dojang',
  seedNumber: 1,                         // nullable — null = unseeded
  createdAtTimestamp: DateTime(2024, 1, 1),
  updatedAtTimestamp: DateTime(2024, 1, 1),
)
```

### Import Paths — Full Package Paths ONLY

Use full package imports, never relative. Here is the complete set of imports you will need across the files in this story:

**Use case files:**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/division_participant_view.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
```

**Test files:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';  // ← NOT mockito
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
```

---

## Project Structure Reference

```
lib/features/participant/domain/usecases/
├── assign_to_division_usecase.dart          # ← PATTERN REFERENCE: auth + status checks + updateParticipant
├── auto_assign_participants_usecase.dart     # ← PATTERN REFERENCE: service-based + multi-repository
├── auto_assignment_match.dart
├── auto_assignment_match.freezed.dart
├── auto_assignment_result.dart
├── auto_assignment_result.freezed.dart
├── bulk_import_preview.dart
├── bulk_import_preview.freezed.dart
├── bulk_import_preview_row.dart
├── bulk_import_preview_row.freezed.dart
├── bulk_import_result.dart
├── bulk_import_result.freezed.dart
├── bulk_import_row_status.dart
├── bulk_import_usecase.dart
├── create_participant_params.dart           # ← PATTERN REFERENCE: freezed params in separate file
├── create_participant_params.freezed.dart
├── create_participant_usecase.dart
├── disqualify_participant_usecase.dart
├── division_participant_view.dart           # ← NEW (this story)
├── division_participant_view.freezed.dart   # ← GENERATED (this story) — after build_runner
├── get_division_participants_usecase.dart   # ← NEW (this story)
├── mark_no_show_usecase.dart
├── update_participant_status_usecase.dart
├── update_seed_positions_usecase.dart       # ← NEW (this story) — includes UpdateSeedPositionsParams
├── update_seed_positions_usecase.freezed.dart  # ← GENERATED (this story) — after build_runner
└── usecases.dart                           # ← MODIFY (add 3 exports)
```

**Test structure:**
```
test/features/participant/domain/usecases/
├── assign_to_division_usecase_test.dart              # ← PATTERN REFERENCE: most relevant existing test
├── auto_assign_participants_usecase_test.dart
├── bulk_import_usecase_test.dart
├── create_participant_usecase_test.dart
├── disqualify_participant_usecase_test.dart
├── get_division_participants_usecase_test.dart        # ← NEW (this story)
├── mark_no_show_usecase_test.dart
├── update_participant_status_usecase_test.dart
└── update_seed_positions_usecase_test.dart            # ← NEW (this story)
```

---

## Anti-Patterns — DO NOT DO THESE

| ❌ Don't                                                               | ✅ Do Instead                                                                                             |
| --------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Import `ParticipantEntry` (Drift class) in use case                   | Import `ParticipantEntity` (domain entity)                                                               |
| Use `DivisionRepository.getParticipantsForDivision()`                 | Use `ParticipantRepository.getParticipantsForDivision()`                                                 |
| Use `@GenerateMocks` from `package:mockito`                           | Use manual mocks with `mocktail`: `class MockFoo extends Mock implements Foo {}`                         |
| Import `package:mockito/mockito.dart` in tests                        | Import `package:mocktail/mocktail.dart`                                                                  |
| Annotate use cases with `@lazySingleton`                              | Annotate with `@injectable`                                                                              |
| Skip auth check for "read-only" operations                            | Always include full auth chain even for queries                                                          |
| Create new repository methods                                         | Use existing: `getParticipantsForDivision`, `getDivisionById`, `getParticipantById`, `updateParticipant` |
| Manually construct entities                                           | Use `entity.copyWith(...)` for updates                                                                   |
| Use `LocalCacheAccessFailure` for not-found                           | Use `NotFoundFailure`                                                                                    |
| Use relative import paths                                             | Use `package:tkd_brackets/...` paths                                                                     |
| Forget `part '*.freezed.dart'` directive                              | Always include for `@freezed` classes                                                                    |
| Skip `syncVersion` increment at use case level                        | Always increment: `syncVersion: participant.syncVersion + 1` (even though repo also increments)          |
| Skip `updatedAtTimestamp` on updates                                  | Always set: `updatedAtTimestamp: DateTime.now()`                                                         |
| Forget to run build_runner after freezed changes                      | Run `dart run build_runner build --delete-conflicting-outputs`                                           |
| Use `any()` matcher without `registerFallbackValue`                   | Register fakes in `setUpAll`: `registerFallbackValue(FakeEntity())`                                      |
| Forget to create `FakeParticipantEntity` in test                      | Add `class FakeParticipantEntity extends Fake implements ParticipantEntity {}`                           |
| Create a junction table or entity                                     | Use existing `divisionId` FK on `ParticipantEntity`                                                      |
| Add division status check to read-only GetDivisionParticipantsUseCase | Only check status on write operations (UpdateSeedPositionsUseCase)                                       |

---

## Implementation Order

1. **Create `division_participant_view.dart`** — Freezed composite data class (see AC1 for complete code)
2. **Run `build_runner`** — `dart run build_runner build --delete-conflicting-outputs` — generates `division_participant_view.freezed.dart`
3. **Create `get_division_participants_usecase.dart`** — Query use case with auth chain (see AC2 for complete code)
4. **Create `update_seed_positions_usecase.dart`** — Reorder use case with `UpdateSeedPositionsParams` in same file (see AC3 for complete code). Has `part 'update_seed_positions_usecase.freezed.dart'` for the params class.
5. **Run `build_runner`** — generates `update_seed_positions_usecase.freezed.dart`
6. **Update `usecases.dart`** — Add 3 new export lines (see AC4)
7. **Create `get_division_participants_usecase_test.dart`** — NO build_runner needed for tests (mocktail = manual mocks)
8. **Create `update_seed_positions_usecase_test.dart`** — Include `FakeParticipantEntity` and `registerFallbackValue`
9. **Run tests** — `flutter test test/features/participant/domain/usecases/get_division_participants_usecase_test.dart test/features/participant/domain/usecases/update_seed_positions_usecase_test.dart`
10. **Run all participant tests** — `flutter test test/features/participant/` (verify no regressions)
11. **Run `dart analyze`** — Verify no errors

---

## References

- **Story 4.8** `assign_to_division_usecase.dart` (129 lines) — PRIMARY pattern reference: auth chain, division status check, `copyWith` + `syncVersion` increment, `updateParticipant` call
- **Story 4.8** `assign_to_division_usecase_test.dart` (586 lines) — PRIMARY test pattern reference: mocktail mocks, `setupSuccessMocks()` helper, `FakeParticipantEntity`, `registerFallbackValue`, division status variants, org mismatch test
- **Story 4.9** `auto_assignment_result.dart` — Freezed composite result type pattern
- `lib/core/usecases/use_case.dart` — Base `UseCase<T, Params>` class
- `lib/core/error/failures.dart` — Failure types: `InputValidationFailure(fieldErrors:)`, `NotFoundFailure`, `AuthorizationPermissionDeniedFailure`, `LocalCacheWriteFailure`
- `lib/features/participant/data/repositories/participant_repository_implementation.dart` — Shows syncVersion is also incremented at repo level (line 123)

---

## Agent Record

- **Agent:** Antigravity (Google Deepmind)
- **Created:** 2026-02-23
- **Updated:** 2026-02-24 — Implemented `DivisionParticipantView`, `GetDivisionParticipantsUseCase`, and `UpdateSeedPositionsUseCase`. All unit tests passed (272/272 in feature). Fixed `syncVersion` double-increment pattern and updated barrel file.
- **Code Review:** 2026-02-24 — Adversarial review found 12 issues (5 HIGH, 2 MEDIUM, 5 LOW). All fixed: added 6 missing tests (AC6.10, AC6.11, AC6.12, AC6.14, AC6.15, AC6.16), removed 2 unused imports, applied `dart fix` for import ordering/lambdas/style issues. All 278 participant tests pass (was 272). 0 analyzer warnings. Mark as `done`.
- **Artifacts analyzed:** epics.md (Story 4.10 section), architecture.md, ux-design-specification.md, Story 4.8 (code + test), Story 4.9 (code), participant_entity.dart, division_entity.dart, user_entity.dart, tournament_entity.dart, participant_repository.dart, participant_repository_implementation.dart (syncVersion behavior), division_repository.dart, participants_table.dart, app_database.dart (getParticipantsForDivision query), participant_local_datasource.dart, use_case.dart, failures.dart, assign_to_division_usecase.dart, assign_to_division_usecase_test.dart, usecases.dart barrel file
- **Key decisions:**
  1. Use `ParticipantRepository` (not `DivisionRepository`) for participant retrieval — domain entities only in use cases
  2. `DivisionParticipantView` as composite result type (division + participants + count) — matches epic AC exactly
  3. `UpdateSeedPositionsUseCase` with ordered ID list — sequential 1-based seed numbers, supports partial reseeding
  4. Auth check required even for read-only `GetDivisionParticipantsUseCase` — defense in depth for multi-tenant security
  5. Division status check only on write operation (`UpdateSeedPositionsUseCase`), not on read (`GetDivisionParticipantsUseCase`) — organizers should be able to VIEW participants at any stage
  6. `UpdateSeedPositionsParams` goes in same file as use case (simpler than separate file for 2-field class)
  7. Test library is `mocktail` (NOT mockito with @GenerateMocks) — verified from ALL existing test files
  8. syncVersion double-increment is intentional established pattern — document to prevent "optimization" removal
