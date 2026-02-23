# Story 4.9: Auto-Assignment Algorithm

Status: done

**Created:** 2026-02-23

**Epic:** 4 - Participant Management

**FRs Covered:** FR16 (System auto-assigns participants to appropriate divisions based on criteria)

**Dependencies:** Story 4.7 (Participant Status Management) - COMPLETE | Story 4.2 (Participant Entity) - COMPLETE | Epic 3 (Division Entity) - COMPLETE

---

## TL;DR — Critical Facts

**CURRENT STATE:**
- ✅ `lib/features/participant/domain/entities/participant_entity.dart` — ParticipantEntity with `age` computed getter, `gender`, `weightKg`, `beltRank`, `schoolOrDojangName`
- ✅ `lib/features/division/domain/entities/division_entity.dart` — DivisionEntity with `ageMin`, `ageMax`, `weightMinKg`, `weightMaxKg`, `beltRankMin`, `beltRankMax`, `gender` (DivisionGender enum)
- ✅ `lib/features/division/domain/entities/belt_rank.dart` — BeltRank enum with `order` property for comparison
- ✅ `lib/features/participant/domain/repositories/participant_repository.dart` — `createParticipantsBatch()` for bulk insert
- ✅ `lib/features/division/domain/repositories/division_repository.dart` — `getDivisionsForTournament()`, `getParticipantsForDivision()`
- ❌ `AutoAssignmentService` — **DOES NOT EXIST** — Create in this story
- ❌ `AutoAssignParticipantsUseCase` — **DOES NOT EXIST** — Create in this story
- ❌ `AutoAssignmentResult` — **DOES NOT EXIST** — Create result type
- ❌ `AutoAssignmentMatch` — **DOES NOT EXIST** — Create match result type

**TARGET STATE:** Create auto-assignment service that matches participants to divisions based on age, belt, weight, and gender criteria. Returns matched assignments and unmatched participants for manual review.

**FILES TO CREATE:**
| File | Type | Description |
|------|------|-------------|
| `lib/features/participant/domain/services/auto_assignment_service.dart` | Service | Core matching algorithm |
| `lib/features/participant/domain/usecases/auto_assign_participants_usecase.dart` | Use case | Orchestrate auto-assignment |
| `lib/features/participant/domain/usecases/auto_assignment_result.dart` | Result type | Success/unmatched results |
| `lib/features/participant/domain/usecases/auto_assignment_match.dart` | Data class | Single match result |

**FILES TO MODIFY:**
| File | Change |
|------|--------|
| `lib/features/participant/domain/usecases/usecases.dart` | Export new use case and types |

**KEY PREVIOUS STORY LESSONS — APPLY ALL:**
1. Use `@injectable` for use cases and services (NOT `@lazySingleton`)
2. Inject existing repositories — don't re-implement persistence
3. Use `Either<Failure, T>` pattern for all return types
4. Run `dart run build_runner build --delete-conflicting-outputs` after ANY generated file changes
5. Keep domain layer pure — no Drift, Supabase, or Flutter dependencies
6. Use `freezed` for result types with proper imports (`package:freezed_annotation/freezed_annotation.dart`)
7. **Authorization pattern from Story 4.3 (MANDATORY):** Get user → Get tournament → Compare org IDs before any assignment
8. **Services directory EXISTS:** `lib/features/participant/domain/services/` already contains `csv_parser_service.dart`, `duplicate_detection_service.dart`, etc.
9. **All 4 repositories required for authorization:** `ParticipantRepository`, `DivisionRepository`, `TournamentRepository`, `UserRepository`

---

## Story

**As an** organizer,
**I want** the system to auto-assign participants to matching divisions,
**So that** I save time on large tournaments (FR16).

---

## Acceptance Criteria

- [ ] **AC1:** `AutoAssignmentMatch` freezed class created:
  ```dart
  @freezed
  class AutoAssignmentMatch with _$AutoAssignmentMatch {
    const factory AutoAssignmentMatch({
      required String participantId,
      required String divisionId,
      required String participantName,
      required String divisionName,
      required int matchScore, // Number of criteria matched (0-4)
      required Map<String, bool> criteriaMatched, // {'age': true, 'belt': true, ...}
    }) = _AutoAssignmentMatch;
  }
  ```

- [ ] **AC2:** `AutoAssignmentResult` freezed class created:
  ```dart
  @freezed
  class AutoAssignmentResult with _$AutoAssignmentResult {
    const factory AutoAssignmentResult({
      required List<AutoAssignmentMatch> matchedAssignments,
      required List<UnmatchedParticipant> unmatchedParticipants,
      required int totalParticipantsProcessed,
      required int totalDivisionsEvaluated,
    }) = _AutoAssignmentResult;
  }
  
  @freezed
  class UnmatchedParticipant with _$UnmatchedParticipant {
    const factory UnmatchedParticipant({
      required String participantId,
      required String participantName,
      required String reason, // Why no match found
    }) = _UnmatchedParticipant;
  }
  ```

- [ ] **AC3:** `AutoAssignmentService` created with `@injectable`:
  - Method: `AutoAssignmentMatch? evaluateMatch(ParticipantEntity participant, DivisionEntity division)`
  - Method: `String determineUnmatchedReason(ParticipantEntity participant, List<DivisionEntity> divisions)`
  - Returns `null` if no match, otherwise returns match with criteria details
  - Matching logic:
    - **Age:** `participant.age` within `[division.ageMin, division.ageMax]` (null bounds = no limit)
    - **Gender:** `participant.gender` matches `division.gender` OR division is `mixed`
    - **Weight:** `participant.weightKg` within `[division.weightMinKg, division.weightMaxKg]` (null bounds = no limit)
    - **Belt:** `participant.beltRank` within `[division.beltRankMin, division.beltRankMax]` using BeltRank.order comparison

- [ ] **AC4:** Belt rank comparison logic:
  - Use `BeltRank.fromString()` to parse participant's `beltRank`
  - Use `BeltRank.fromString()` to parse division's `beltRankMin`/`beltRankMax`
  - Compare using `.order` property
  - If belt strings don't parse, attempt string comparison as fallback

- [ ] **AC5:** `AutoAssignParticipantsUseCase` created with `@injectable`:
  - **Inject ALL 4 repositories:** `ParticipantRepository`, `DivisionRepository`, `TournamentRepository`, `UserRepository`
  - Method: `Future<Either<Failure, AutoAssignmentResult>> call({required String tournamentId, required List<String> participantIds, bool dryRun = false})`
  - **AUTHORIZATION FLOW (MANDATORY - same as Story 4.3):**
    1. Get current user via `UserRepository.getCurrentUser()` → extract `organizationId`
    2. Get tournament via `TournamentRepository.getTournamentById(tournamentId)`
    3. Compare `tournament.organizationId` with user's `organizationId`
    4. If mismatch → return `Left(AuthorizationPermissionDeniedFailure(...))`
  - Loads all divisions for tournament via `DivisionRepository.getDivisionsForTournament(tournamentId)`
  - **EXCLUDE divisions with status `in_progress` or `completed`** — only `setup` and `ready` divisions eligible
  - Loads participants by ID via `ParticipantRepository.getParticipantById()`
  - Evaluates each participant against all eligible divisions
  - **Best match selection:** Division with highest `matchScore` wins; tie-breaker: first matching division
  - **Handle already-assigned participants:** If participant already has a `divisionId`, reassign to new division (update the assignment)
  - If `dryRun = false`: Updates each participant's `divisionId` via `updateParticipant()`
  - If `dryRun = true`: Returns results without persisting

- [ ] **AC6:** Unmatched participant reasons:
  - "No divisions exist in tournament"
  - "No divisions available for assignment" (all divisions are in_progress/completed)
  - "No divisions with matching gender criteria"
  - "No divisions with matching age range"
  - "No divisions with matching belt rank"
  - "No divisions with matching weight class"
  - "No suitable division found" (fallback when individual criteria pass but combination fails)
  - "Participant not found" (participant ID invalid)

- [ ] **AC7:** Error handling:
  - **User not logged in or no organization** → return `Left(AuthorizationPermissionDeniedFailure(userFriendlyMessage: 'You must be logged in with an organization'))`
  - **Tournament not found** → return `Left(NotFoundFailure(userFriendlyMessage: 'Tournament not found'))`
  - **Tournament not in user's organization** → return `Left(AuthorizationPermissionDeniedFailure(userFriendlyMessage: 'You do not have permission to access this tournament'))`
  - **No divisions in tournament** → return `Right(AutoAssignmentResult)` with all participants unmatched (reason: "No divisions exist in tournament")
  - **No ELIGIBLE divisions (all are in_progress/completed)** → return `Right(AutoAssignmentResult)` with all participants unmatched (reason: "No divisions available for assignment")
  - **Participant not found** → skip participant, continue with others (include in unmatched with reason "Participant not found")
  - **No participants provided** → return `Right(AutoAssignmentResult)` with empty lists

- [ ] **AC8:** Unit tests verify:
  - Match evaluation: age, gender, weight, belt criteria
  - Gender matching: male division rejects female, mixed accepts all
  - Belt rank ordering: black > red > blue > green > orange > yellow > white
  - Best match selection: participant matches multiple divisions, highest score wins
  - Tie-breaking: when scores equal, first matching division wins
  - Unmatched participant: no valid division exists
  - Dry run mode: no database writes
  - Actual assignment: participant's divisionId updated
  - Edge cases: null age, null weight, division with no constraints
  - Empty tournament/divisions/participants handling
  - Authorization: tournament not in user's organization returns error
  - Division status filtering: in_progress/completed divisions excluded
  - Participant already assigned: reassigned to new division (not skipped)
  - Participant not found: skipped with appropriate unmatched reason

- [ ] **AC9:** Division status filtering:
  - Divisions with `status == DivisionStatus.inProgress` are EXCLUDED from matching
  - Divisions with `status == DivisionStatus.completed` are EXCLUDED from matching
  - Only `setup` and `ready` divisions are eligible for auto-assignment

- [ ] **AC10:** `flutter analyze` passes with zero new errors

- [ ] **AC11:** `dart run build_runner build --delete-conflicting-outputs` succeeds

- [ ] **AC12:** All participant tests pass: `flutter test test/features/participant/`

- [ ] **AC13:** Services barrel file updated if it exists: `lib/features/participant/domain/services/services.dart`

---

## Tasks / Subtasks

### Task 1: Create AutoAssignmentMatch Data Class (AC: #1)

- [x] 1.1: Create `lib/features/participant/domain/usecases/auto_assignment_match.dart`
- [x] 1.2: Add freezed imports and annotations
- [x] 1.3: Define `AutoAssignmentMatch` with all required fields
- [x] 1.4: Add `part 'auto_assignment_match.freezed.dart';`

### Task 2: Create AutoAssignmentResult Data Class (AC: #2)

- [x] 2.1: Create `lib/features/participant/domain/usecases/auto_assignment_result.dart`
- [x] 2.2: Add freezed imports and annotations
- [x] 2.3: Define `AutoAssignmentResult` and `UnmatchedParticipant`
- [x] 2.4: Add `part 'auto_assignment_result.freezed.dart';`

### Task 3: Create AutoAssignmentService (AC: #3, #4)

- [x] 3.1: Create `lib/features/participant/domain/services/auto_assignment_service.dart`
- [x] 3.2: Add imports
- [x] 3.3: Add `@injectable` annotation
- [x] 3.4: Implement `evaluateMatch()` method
- [x] 3.5: Implement `_checkAgeMatch()` helper
- [x] 3.6: Implement `_checkGenderMatch()` helper
- [x] 3.7: Implement `_checkWeightMatch()` helper
- [x] 3.8: Implement `_checkBeltMatch()` helper with BeltRank.order comparison

### Task 4: Create AutoAssignParticipantsUseCase (AC: #5, #6, #7, #9)

- [x] 4.1: Create `lib/features/participant/domain/usecases/auto_assign_participants_usecase.dart`
- [x] 4.2: Add imports (fpdart, injectable, failures, ALL 4 repositories, services, result types)
- [x] 4.3: Add `@injectable` annotation
- [x] 4.4: Inject ALL 4 repositories: `ParticipantRepository`, `DivisionRepository`, `TournamentRepository`, `UserRepository`
- [x] 4.5: Inject `AutoAssignmentService`
- [x] 4.6: Implement authorization flow: Get user → Get tournament → Compare org IDs
- [x] 4.7: Load divisions for tournament via `DivisionRepository.getDivisionsForTournament(tournamentId)`
- [x] 4.8: Filter divisions by status: exclude `in_progress` and `completed`
- [x] 4.9: Load participants by ID via `ParticipantRepository.getParticipantById()`
- [x] 4.10: Evaluate each participant against all eligible divisions
- [x] 4.11: Select best match (highest matchScore, tie-breaker: first match)
- [x] 4.12: Build UnmatchedParticipant with appropriate reason via `AutoAssignmentService.determineUnmatchedReason()`
- [x] 4.13: If not dryRun, update participant divisionId via `updateParticipant()`
- [x] 4.14: Increment `syncVersion` and set `updatedAtTimestamp` on all updates

### Task 5: Update Barrel Files (AC: #13)

- [x] 5.1: Open `lib/features/participant/domain/usecases/usecases.dart`
- [x] 5.2: Add exports
- [x] 5.3: Check if `lib/features/participant/domain/services/services.dart` exists
- [x] 5.4: Add export: `export 'auto_assignment_service.dart';`

### Task 6: Run Build Runner (AC: #10)

- [x] 6.1: Run `dart run build_runner build --delete-conflicting-outputs`
- [x] 6.2: Verify generated files created

### Task 7: Create Unit Tests (AC: #8)

- [x] 7.1: Create `test/features/participant/domain/services/auto_assignment_service_test.dart`
- [x] 7.2: Create `test/features/participant/domain/usecases/auto_assign_participants_usecase_test.dart`
- [x] 7.3: Test all match criteria (age, gender, weight, belt)
- [x] 7.4: Test gender matching (male/female/mixed)
- [x] 7.5: Test belt rank ordering
- [x] 7.6: Test best match selection
- [x] 7.7: Test unmatched participant scenarios
- [x] 7.8: Test dry run vs actual assignment
- [x] 7.9: Test edge cases

### Task 8: Verify Project Integrity (AC: #9, #11)

- [x] 8.1: Run `flutter analyze` — zero new issues
- [x] 8.2: Run all participant tests: `flutter test test/features/participant/` — all pass

---

## Dev Notes

### ⚠️ CRITICAL: Files That DO NOT Need Changes

| File | Why No Change |
|------|---------------|
| `participant_entity.dart` | Already has all fields needed (age computed, gender, weightKg, beltRank) |
| `division_entity.dart` | Already has all constraint fields (ageMin/Max, weightMinKg/MaxKg, beltRankMin/Max, gender) |
| `belt_rank.dart` | Already has `order` property for comparison |
| `participant_repository.dart` | Already has `getParticipantById()`, `updateParticipant()`, `createParticipantsBatch()` |
| `division_repository.dart` | Already has `getDivisionsForTournament()` |

### Matching Algorithm Logic

```dart
// In auto_assignment_service.dart
AutoAssignmentMatch? evaluateMatch(
  ParticipantEntity participant,
  DivisionEntity division,
) {
  final criteriaMatched = <String, bool>{};
  int matchScore = 0;

  // Check age
  if (_checkAgeMatch(participant, division)) {
    criteriaMatched['age'] = true;
    matchScore++;
  } else {
    criteriaMatched['age'] = false;
    return null; // Age mismatch = no match
  }

  // Check gender
  if (_checkGenderMatch(participant, division)) {
    criteriaMatched['gender'] = true;
    matchScore++;
  } else {
    criteriaMatched['gender'] = false;
    return null; // Gender mismatch = no match
  }

  // Check weight (optional - null means no constraint)
  if (_checkWeightMatch(participant, division)) {
    criteriaMatched['weight'] = true;
    matchScore++;
  } else if (division.weightMinKg != null || division.weightMaxKg != null) {
    criteriaMatched['weight'] = false;
    return null; // Weight constraint exists but mismatch
  }

  // Check belt (optional)
  if (_checkBeltMatch(participant, division)) {
    criteriaMatched['belt'] = true;
    matchScore++;
  } else if (division.beltRankMin != null || division.beltRankMax != null) {
    criteriaMatched['belt'] = false;
    return null; // Belt constraint exists but mismatch
  }

  return AutoAssignmentMatch(
    participantId: participant.id,
    divisionId: division.id,
    participantName: '${participant.firstName} ${participant.lastName}',
    divisionName: division.name,
    matchScore: matchScore,
    criteriaMatched: criteriaMatched,
  );
}

bool _checkAgeMatch(ParticipantEntity p, DivisionEntity d) {
  final age = p.age;
  if (age == null) return true; // No age = always matches
  if (d.ageMin != null && age < d.ageMin!) return false;
  if (d.ageMax != null && age > d.ageMax!) return false;
  return true;
}

bool _checkGenderMatch(ParticipantEntity p, DivisionEntity d) {
  if (d.gender == DivisionGender.mixed) return true;
  if (p.gender == null) return true; // No gender = always matches
  return p.gender!.value == d.gender.value;
}

bool _checkWeightMatch(ParticipantEntity p, DivisionEntity d) {
  if (p.weightKg == null) return true; // No weight = always matches
  if (d.weightMinKg != null && p.weightKg! < d.weightMinKg!) return false;
  if (d.weightMaxKg != null && p.weightKg! > d.weightMaxKg!) return false;
  return true;
}

bool _checkBeltMatch(ParticipantEntity p, DivisionEntity d) {
  if (p.beltRank == null || p.beltRank!.isEmpty) return true;
  if ((d.beltRankMin == null || d.beltRankMin!.isEmpty) &&
      (d.beltRankMax == null || d.beltRankMax!.isEmpty)) return true;

  final participantBelt = BeltRank.fromString(p.beltRank!);
  if (participantBelt == null) return true; // Unknown belt = always matches

  if (d.beltRankMin != null && d.beltRankMin!.isNotEmpty) {
    final minBelt = BeltRank.fromString(d.beltRankMin!);
    if (minBelt != null && participantBelt.order < minBelt.order) return false;
  }

  if (d.beltRankMax != null && d.beltRankMax!.isNotEmpty) {
    final maxBelt = BeltRank.fromString(d.beltRankMax!);
    if (maxBelt != null && participantBelt.order > maxBelt.order) return false;
  }

  return true;
}
```

### Unmatched Reason Logic

```dart
String _determineUnmatchedReason(
  ParticipantEntity participant,
  List<DivisionEntity> divisions,
) {
  if (divisions.isEmpty) {
    return 'No divisions exist in tournament';
  }

  final hasMatchingGender = divisions.any(
    (d) => d.gender == DivisionGender.mixed ||
           (participant.gender != null && d.gender.value == participant.gender!.value),
  );
  if (!hasMatchingGender) {
    return 'No divisions with matching gender criteria';
  }

  final hasMatchingAge = divisions.any((d) {
    final age = participant.age;
    if (age == null) return true;
    if (d.ageMin != null && age < d.ageMin!) return false;
    if (d.ageMax != null && age > d.ageMax!) return false;
    return true;
  });
  if (!hasMatchingAge) {
    return 'No divisions with matching age range';
  }

  final hasMatchingWeight = divisions.any((d) {
    if (participant.weightKg == null) return true;
    if (d.weightMinKg != null && participant.weightKg! < d.weightMinKg!) return false;
    if (d.weightMaxKg != null && participant.weightKg! > d.weightMaxKg!) return false;
    return true;
  });
  if (!hasMatchingWeight) {
    return 'No divisions with matching weight class';
  }

  final hasMatchingBelt = divisions.any((d) {
    if (participant.beltRank == null || participant.beltRank!.isEmpty) return true;
    if ((d.beltRankMin == null || d.beltRankMin!.isEmpty) &&
        (d.beltRankMax == null || d.beltRankMax!.isEmpty)) return true;
    // Belt comparison logic here...
    return true;
  });
  if (!hasMatchingBelt) {
    return 'No divisions with matching belt rank';
  }

  return 'No suitable division found';
}
```

### Complete Use Case Implementation

```dart
// lib/features/participant/domain/usecases/auto_assign_participants_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/participant/domain/services/auto_assignment_service.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/auto_assignment_match.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/auto_assignment_result.dart';

@injectable
class AutoAssignParticipantsUseCase {
  AutoAssignParticipantsUseCase(
    this._participantRepository,
    this._divisionRepository,
    this._tournamentRepository,
    this._userRepository,
    this._autoAssignmentService,
  );

  final ParticipantRepository _participantRepository;
  final DivisionRepository _divisionRepository;
  final TournamentRepository _tournamentRepository;
  final UserRepository _userRepository;
  final AutoAssignmentService _autoAssignmentService;

  Future<Either<Failure, AutoAssignmentResult>> call({
    required String tournamentId,
    required List<String> participantIds,
    bool dryRun = false,
  }) async {
    // Step 1: Authorization - verify user has access to tournament
    final userResult = await _userRepository.getCurrentUser();
    final user = userResult.fold((failure) => null, (user) => user);

    if (user == null || user.organizationId.isEmpty) {
      return const Left(AuthorizationPermissionDeniedFailure(
        userFriendlyMessage: 'You must be logged in with an organization',
      ));
    }

    final tournamentResult = await _tournamentRepository.getTournamentById(tournamentId);
    final tournament = tournamentResult.fold((failure) => null, (t) => t);

    if (tournament == null) {
      return const Left(NotFoundFailure(
        userFriendlyMessage: 'Tournament not found',
      ));
    }

    if (tournament.organizationId != user.organizationId) {
      return const Left(AuthorizationPermissionDeniedFailure(
        userFriendlyMessage: 'You do not have permission to access this tournament',
      ));
    }

    // Step 2: Load divisions (exclude in_progress and completed)
    final divisionsResult = await _divisionRepository.getDivisionsForTournament(tournamentId);
    final allDivisions = divisionsResult.fold((failure) => <DivisionEntity>[], (d) => d);

    final eligibleDivisions = allDivisions
        .where((d) => d.status == DivisionStatus.setup || d.status == DivisionStatus.ready)
        .toList();

    if (eligibleDivisions.isEmpty) {
      final unmatched = participantIds.map((id) => UnmatchedParticipant(
        participantId: id,
        participantName: 'Unknown',
        reason: allDivisions.isEmpty
            ? 'No divisions exist in tournament'
            : 'No divisions available for assignment',
      )).toList();

      return Right(AutoAssignmentResult(
        matchedAssignments: [],
        unmatchedParticipants: unmatched,
        totalParticipantsProcessed: participantIds.length,
        totalDivisionsEvaluated: 0,
      ));
    }

    // Step 3: Process each participant
    final matchedAssignments = <AutoAssignmentMatch>[];
    final unmatchedParticipants = <UnmatchedParticipant>[];

    for (final participantId in participantIds) {
      final participantResult = await _participantRepository.getParticipantById(participantId);

      await participantResult.fold(
        (failure) async {
          unmatchedParticipants.add(UnmatchedParticipant(
            participantId: participantId,
            participantName: 'Unknown',
            reason: 'Participant not found',
          ));
        },
        (participant) async {
          // Find best matching division
          AutoAssignmentMatch? bestMatch;
          for (final division in eligibleDivisions) {
            final match = _autoAssignmentService.evaluateMatch(participant, division);
            if (match != null) {
              if (bestMatch == null || match.matchScore > bestMatch.matchScore) {
                bestMatch = match;
              }
            }
          }

          if (bestMatch != null) {
            matchedAssignments.add(bestMatch);

            // Persist if not dry run
            if (!dryRun) {
              final updatedParticipant = participant.copyWith(
                divisionId: bestMatch.divisionId,
                syncVersion: participant.syncVersion + 1,
                updatedAtTimestamp: DateTime.now(),
              );
              await _participantRepository.updateParticipant(updatedParticipant);
            }
          } else {
            unmatchedParticipants.add(UnmatchedParticipant(
              participantId: participant.id,
              participantName: '${participant.firstName} ${participant.lastName}',
              reason: _autoAssignmentService.determineUnmatchedReason(participant, eligibleDivisions),
            ));
          }
        },
      );
    }

    return Right(AutoAssignmentResult(
      matchedAssignments: matchedAssignments,
      unmatchedParticipants: unmatchedParticipants,
      totalParticipantsProcessed: participantIds.length,
      totalDivisionsEvaluated: eligibleDivisions.length,
    ));
  }
}
```

### Import Statements

```dart
// auto_assignment_match.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auto_assignment_match.freezed.dart';

@freezed
class AutoAssignmentMatch with _$AutoAssignmentMatch {
  // ... implementation
}

// auto_assignment_result.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auto_assignment_result.freezed.dart';

@freezed
class AutoAssignmentResult with _$AutoAssignmentResult {
  // ... implementation
}

@freezed
class UnmatchedParticipant with _$UnmatchedParticipant {
  // ... implementation
}

// auto_assignment_service.dart
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/entities/belt_rank.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/auto_assignment_match.dart';

// auto_assign_participants_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/participant/domain/services/auto_assignment_service.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/auto_assignment_match.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/auto_assignment_result.dart';
```

---

## Anti-Patterns — WHAT NOT TO DO

| ❌ Don't Do This | ✅ Do This Instead | Why |
|-----------------|---------------------|-----|
| Create new repository methods | Use existing `getDivisionsForTournament()`, `getParticipantById()` | Avoid repository bloat |
| Use `@lazySingleton` for use case | Use `@injectable` | Use cases are transient |
| Skip belt rank comparison | Use `BeltRank.order` for proper ordering | "black" > "white" semantically |
| Treat null constraints as mismatches | Null constraints = no restriction | Division with no weight limit matches all weights |
| Auto-assign to multiple divisions | Select single best match | One participant = one division assignment |
| Ignore dryRun flag | Check flag before persisting | Preview mode is critical UX feature |
| Skip authorization check | Verify tournament belongs to user's org | Prevent cross-org data access |
| Assign to in_progress divisions | Filter out non-setup/ready divisions | Prevents mid-competition changes |
| Skip UserRepository injection | Inject all 4 repositories | Authorization requires user context |
| Return exception on participant not found | Skip and add to unmatched list | Partial success is valid |
| Use `AuthFailure` for org permission | Use `AuthorizationPermissionDeniedFailure` | Correct failure type |
| Forget to increment syncVersion | Always do `syncVersion: participant.syncVersion + 1` | Offline sync requires version tracking |
| Forget to update updatedAtTimestamp | Always set `updatedAtTimestamp: DateTime.now()` | Audit trail requirement |
| Use BeltRank.fromString without null check | Check `BeltRank.fromString() != null` first | Invalid belt strings are possible |
| Inject only 2-3 repositories | Inject ALL 4: Participant, Division, Tournament, User | Authorization requires full chain |
| Create service in wrong directory | Place in `lib/features/participant/domain/services/` | Services directory already exists |
| Forget to add services barrel export | Check/update `services.dart` if it exists | Maintains consistent exports |
| Skip Task 1 verification | Run verification tasks BEFORE creating files | Prevents assumptions about existing code |
| Use `AuthFailure` for auth errors | Use `AuthorizationPermissionDeniedFailure` | Correct failure type per Story 4.3 |

---

## File Structure After This Story

```
lib/features/participant/
├── participant.dart
├── domain/
│   ├── entities/
│   │   └── participant_entity.dart              ← USE ONLY
│   ├── repositories/
│   │   └── participant_repository.dart          ← USE ONLY
│   ├── services/
│   │   ├── services.dart                        ← CREATE/MODIFY (barrel file)
│   │   ├── auto_assignment_service.dart         ← NEW
│   │   ├── csv_parser_service.dart              ← EXISTING
│   │   ├── duplicate_detection_service.dart     ← EXISTING
│   │   └── ...                                  ← Other existing services
│   └── usecases/
│       ├── usecases.dart                        ← MODIFIED (add 3 exports)
│       ├── auto_assignment_match.dart           ← NEW
│       ├── auto_assignment_match.freezed.dart   ← GENERATED
│       ├── auto_assignment_result.dart          ← NEW
│       ├── auto_assignment_result.freezed.dart  ← GENERATED
│       └── auto_assign_participants_usecase.dart ← NEW
├── data/
│   └── ...                                      ← USE ONLY
└── presentation/                                ← Empty (Story 4.12)
```

---

## References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 4, Story 4.9]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Clean Architecture, Authorization Pattern]
- [Source: `_bmad-output/implementation-artifacts/4-3-manual-participant-entry.md` — Authorization flow pattern, 4-repository injection]
- [Source: `_bmad-output/implementation-artifacts/4-6-bulk-import-with-validation.md` — Batch processing pattern, preview/result types]
- [Source: `tkd_brackets/lib/features/participant/domain/entities/participant_entity.dart` — Entity definition]
- [Source: `tkd_brackets/lib/features/division/domain/entities/division_entity.dart` — Division constraints]
- [Source: `tkd_brackets/lib/features/division/domain/entities/belt_rank.dart` — BeltRank enum with order property]
- [Source: `tkd_brackets/lib/features/participant/domain/repositories/participant_repository.dart` — Repository interface]
- [Source: `tkd_brackets/lib/features/division/domain/repositories/division_repository.dart` — DivisionRepository]
- [Source: `tkd_brackets/lib/features/tournament/domain/repositories/tournament_repository.dart` — TournamentRepository]
- [Source: `tkd_brackets/lib/features/auth/domain/repositories/user_repository.dart` — UserRepository]
- [Source: `tkd_brackets/lib/core/error/failures.dart` — Failure types]
- [Source: `tkd_brackets/lib/features/participant/domain/services/` — Existing services directory]

---

## Dev Agent Record

### Agent Model Used
{{agent_model_name_version}}

### Debug Log References

N/A

### Completion Notes List

- Implemented AutoAssignmentMatch data class with participant/division matching details
- Implemented AutoAssignmentResult with AutoAssignmentResult and UnmatchedParticipant
- Implemented AutoAssignmentService with evaluateMatch() for age/gender/weight/belt criteria matching
- Implemented AutoAssignParticipantsUseCase with authorization, division filtering, and best match selection
- Added barrel file exports to usecases.dart and services.dart
- All 54 tests pass (36 for AutoAssignmentService, 18 for AutoAssignParticipantsUseCase)

### File List

**New Files:**
- `lib/features/participant/domain/usecases/auto_assignment_match.dart`
- `lib/features/participant/domain/usecases/auto_assignment_result.dart`
- `lib/features/participant/domain/usecases/auto_assign_participants_usecase.dart`
- `lib/features/participant/domain/services/auto_assignment_service.dart`
- `test/features/participant/domain/services/auto_assignment_service_test.dart`
- `test/features/participant/domain/usecases/auto_assign_participants_usecase_test.dart`

**Generated Files (via build_runner):**
- `lib/features/participant/domain/usecases/auto_assignment_match.freezed.dart`
- `lib/features/participant/domain/usecases/auto_assignment_result.freezed.dart`

**Modified Files:**
- `lib/features/participant/domain/usecases/usecases.dart`
- `lib/features/participant/domain/services/services.dart`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

---

## Senior Developer Review (AI)

**Reviewer:** AI Code Review
**Date:** 2026-02-23
**Outcome:** ✅ Approved (after fixes)

### Issues Found and Fixed

| # | Severity | Issue | Resolution |
|---|----------|-------|------------|
| 1 | HIGH | Story file contained duplicated content (File Structure, References sections) | Removed duplicate sections |
| 2 | HIGH | Story had two "File List" sections (one completed, one placeholder) | Removed placeholder section |
| 3 | HIGH | AC6 missing unmatched reasons used in implementation | Updated AC6 to include all 8 reasons |
| 4 | MEDIUM | Division loading failure silently swallowed (treated as empty list) | Now properly propagates failure as Left |
| 5 | MEDIUM | No test for division repository failure | Added test case |
| 6 | MEDIUM | .freezed.dart files listed as "New Files" | Separated into "Generated Files" section |
| 7 | LOW | Missing code comments explaining null = "matches all" behavior | Added doc comments to all check methods |

### Test Results
- 55 tests pass (36 service + 19 use case)
- All participant tests pass (237 total)

### Code Quality Notes
- Follows established patterns from previous stories
- Proper authorization flow with 4-repository injection
- Clean separation between service (matching logic) and use case (orchestration)
- Good test coverage including edge cases
