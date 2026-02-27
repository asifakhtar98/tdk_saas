# Story 5.4: Single Elimination Bracket Generator

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an organizer,
I want the system to generate a single elimination bracket from a list of participants,
so that I have the standard knockout format for sparring divisions (FR20).

## Acceptance Criteria

1. **Given** a division has N participants (where N ≥ 2), **When** I generate a single elimination bracket, **Then** `SingleEliminationBracketGeneratorService` creates a `BracketEntity` with `bracketType = BracketType.winners` and the correct number of rounds: `ceil(log2(N))`.

2. **Given** a bracket is being generated, **When** match records are created, **Then** `MatchEntity` records form a proper binary tree where each winner advances to the correct next match via `winnerAdvancesToMatchId`.

3. **Given** participants count N is NOT a power of 2, **When** the bracket is generated, **Then** bye matches are created in round 1 with `resultType = MatchResultType.bye`, `status = MatchStatus.completed`, and the bye recipient is automatically advanced (their ID placed in the correct slot of their `winnerAdvancesToMatchId` match).

4. **Given** byes are needed, **When** distributing byes, **Then** byes are spread evenly across round 1 (distributed to the top of the bracket first, not clustered), so top-seeded participants receive byes when participant seeding is later applied.

5. **Given** a division has a 3rd-place match configured (via `bracketDataJson` configuration), **When** the bracket is generated, **Then** a 3rd-place match is created where the two semifinal losers are routed via `loserAdvancesToMatchId`.

6. **Given** the generator is called, **When** bracket generation completes, **Then** both the `BracketEntity` and all `MatchEntity` records are persisted to the local database via the existing `BracketRepository` and `MatchRepository`.

7. **Given** any participant count from 2 to 64, **When** bracket generation is triggered, **Then** generation completes in < 500ms (NFR2 — "All bracket operations < 500ms").

8. **Given** the bracket is generated, **When** I inspect the result, **Then** the bracket's `totalRounds` field equals `ceil(log2(N))`, `generatedAtTimestamp` is set, and `isFinalized` remains `false` (finalization happens in Story 5.12).

9. **Given** a valid division, **When** bracket generation is invoked, **Then** the use case returns `Either<Failure, BracketGenerationResult>` where `BracketGenerationResult` contains the created `BracketEntity` and the list of `MatchEntity` records.

10. **Given** a division with fewer than 2 participants, **When** bracket generation is attempted, **Then** the use case returns `Left(ValidationFailure)` with a descriptive error message.

## Tasks / Subtasks

- [x] **Task 1: Create `BracketGenerationResult` value object** (AC: #9)
  - [x] 1.1: Create `lib/features/bracket/domain/entities/bracket_generation_result.dart` — a plain `@immutable` class (NOT Freezed) containing `final BracketEntity bracket` and `final List<MatchEntity> matches` fields with a `const` constructor. This class does NOT need JSON serialization or copyWith, so Freezed is overkill. Follow the `NoParams` pattern from `lib/core/usecases/use_case.dart`.
  - [x] 1.2: Export it from the barrel file `lib/features/bracket/bracket.dart`.

- [x] **Task 1b: Create `GenerateSingleEliminationBracketParams` class** (AC: #9, #10)
  - [x] 1b.1: Create `lib/features/bracket/domain/usecases/generate_single_elimination_bracket_params.dart` — a plain `@immutable` class containing `final String divisionId`, `final List<String> participantIds`, and `final bool includeThirdPlaceMatch` (default: `false`) with a `const` constructor.
  - [x] 1b.2: Export it from the barrel file.

- [x] **Task 2: Create `BracketGenerationFailure` failure class** (AC: #10)
  - [x] 2.1: Add `BracketGenerationFailure` to `lib/core/error/failures.dart` extending `Failure` with `userFriendlyMessage` and `technicalDetails`.

- [x] **Task 3: Create `SingleEliminationBracketGeneratorService`** (AC: #1, #2, #3, #4, #5)
  - [x] 3.1: Create `lib/features/bracket/domain/services/single_elimination_bracket_generator_service.dart` — abstract interface with a single method: `BracketGenerationResult generate({required String divisionId, required List<String> participantIds, required String bracketId, bool includeThirdPlaceMatch = false})`.
  - [x] 3.2: Create `lib/features/bracket/data/services/single_elimination_bracket_generator_service_implementation.dart` — concrete implementation that receives `Uuid` via constructor injection (registered in DI via `register_module.dart`).
  - [x] 3.3: Register as `@LazySingleton(as: SingleEliminationBracketGeneratorService)` in DI.
  - [x] 3.4: Create the directories `lib/features/bracket/domain/services/` and `lib/features/bracket/data/services/` — these do NOT exist yet.
  - [x] 3.5: Export both from the barrel file.

- [x] **Task 4: Create `GenerateSingleEliminationBracketUseCase`** (AC: #6, #7, #8, #9, #10)
  - [x] 4.1: Create `lib/features/bracket/domain/usecases/generate_single_elimination_bracket_use_case.dart`.
  - [x] 4.2: **MUST** extend `UseCase<BracketGenerationResult, GenerateSingleEliminationBracketParams>` from `lib/core/usecases/use_case.dart`. Import it.
  - [x] 4.3: Constructor receives: `SingleEliminationBracketGeneratorService`, `BracketRepository`, `MatchRepository`, `Uuid` — all via DI injection. The `Uuid` is already registered as `@lazySingleton` in `lib/core/di/register_module.dart`.
  - [x] 4.4: Override `call(GenerateSingleEliminationBracketParams params)` method.
  - [x] 4.5: Validate inputs (≥ 2 participants, no empty IDs in list).
  - [x] 4.6: Orchestrate: generate bracket ID via `_uuid.v4()` → create BracketEntity → call generator service → persist bracket (check Either result) → persist all matches (check Either result) → return result or propagate failure.
  - [x] 4.7: **CRITICAL**: Check `Either` results from repository calls — if `Left`, propagate the failure immediately. DO NOT ignore.
  - [x] 4.8: Register as `@injectable` in DI.
  - [x] 4.9: Export from the barrel file.

- [x] **Task 5: Add batch insert method to `MatchLocalDatasource`** (AC: #6, #7)
  - [x] 5.1: Add `Future<void> insertMatches(List<MatchModel> matches)` to the abstract class and implementation.
  - [x] 5.2: Add corresponding `insertMatches(List<MatchesCompanion> matches)` to `AppDatabase` using `batch((b) => b.insertAll(matches, companions))`.
  - [x] 5.3: Add `Future<Either<Failure, List<MatchEntity>>> createMatches(List<MatchEntity> matches)` to `MatchRepository` interface and implementation.

- [x] **Task 6: Update barrel file** (AC: all)
  - [x] 6.1: Add exactly 5 new exports to `lib/features/bracket/bracket.dart` — organized under existing section comments. New total: **17 exports** (was 12).
  - [x] 6.2: Update `test/features/bracket/structure_test.dart` — change export count assertion from `12` to `17`, update test name from `'twelve'` to `'seventeen'`, update reason string.

- [x] **Task 7: Write unit tests for `SingleEliminationBracketGeneratorService`** (AC: #1, #2, #3, #4, #5)
  - [x] 7.1: Create `test/features/bracket/data/services/single_elimination_bracket_generator_service_implementation_test.dart`.
  - [x] 7.2: Test bracket structure for 2, 3, 4, 5, 7, 8, 16, 32, 64 participants.
  - [x] 7.3: Test correct round count calculation.
  - [x] 7.4: Test match tree linkage (every match's `winnerAdvancesToMatchId` correctly set).
  - [x] 7.5: Test bye distribution: correct count, even spread, bye matches properly marked.
  - [x] 7.6: Test 3rd-place match creation with semifinal loser routing.
  - [x] 7.7: Test edge case: exactly 2 participants (1 match, 1 round, no byes).
  - [x] 7.8: Test that final match has `winnerAdvancesToMatchId = null`.

- [x] **Task 8: Write unit tests for `GenerateSingleEliminationBracketUseCase`** (AC: #6, #9, #10)
  - [x] 8.1: Create `test/features/bracket/domain/usecases/generate_single_elimination_bracket_use_case_test.dart`.
  - [x] 8.2: Test successful generation returns `Right(BracketGenerationResult)`.
  - [x] 8.3: Test validation failure for < 2 participants.
  - [x] 8.4: Test validation failure for empty participant IDs.
  - [x] 8.5: Test that bracket and matches are persisted.

- [x] **Task 9: Run code generation and verify** (AC: all)
  - [x] 9.1: Run `dart run build_runner build --delete-conflicting-outputs`.
  - [x] 9.2: Run `dart analyze` and fix any issues.
  - [x] 9.3: Run all tests and ensure 100% pass rate.

## Dev Notes

### Architecture Overview

This story creates the **first use case** in the bracket feature's `domain/usecases/` directory. Previous stories (5.1, 5.2, 5.3) established the feature structure, bracket entity/repository, and match entity/repository respectively. This story builds on all of them.

**Layer Responsibilities:**
- **Domain Service** (`SingleEliminationBracketGeneratorService`): Pure bracket generation algorithm — takes participant count and config, returns bracket + match structures. NO database access. NO imports from data layer.
- **Use Case** (`GenerateSingleEliminationBracketUseCase`): Orchestrates validation → generation → persistence. Uses repositories to persist data.
- **Data Service Implementation**: Implements the domain service interface. Can ONLY import from domain layer and Dart core.

### Critical Algorithm: Single Elimination Bracket Generation

The core algorithm must produce a **proper binary tree** of matches:

```
For N=8 participants (3 rounds):

Round 1 (Quarterfinals)        Round 2 (Semifinals)       Round 3 (Final)
┌─────────────────────┐
│ Match 1: P1 vs P8   │──winner──→┌──────────────────┐
└─────────────────────┘           │ Match 5: W1 vs W2│──winner──→┌──────────────┐
┌─────────────────────┐           └──────────────────┘           │ Match 7: W5  │
│ Match 2: P4 vs P5   │──winner──→                               │     vs W6    │
└─────────────────────┘                                          └──────────────┘
┌─────────────────────┐           ┌──────────────────┐
│ Match 3: P2 vs P7   │──winner──→│ Match 6: W3 vs W4│──winner──→
└─────────────────────┘           └──────────────────┘
┌─────────────────────┐
│ Match 4: P3 vs P6   │──winner──→
└─────────────────────┘
```

**Key Algorithm Steps:**
1. Calculate `totalRounds = ceil(log2(N))` — e.g., 8 participants → 3 rounds, 5 participants → 3 rounds.
2. Calculate `bracketSize = pow(2, totalRounds)` — the nearest power of 2 ≥ N — e.g., 5 participants → bracketSize 8.
3. Calculate `byeCount = bracketSize - N` — e.g., 5 participants → 3 byes.
4. Generate all match slots for a complete bracket of `bracketSize` participants.
5. Distribute byes in round 1 — assign bye matches to top seed positions.
6. Link `winnerAdvancesToMatchId` for every match (winner of match 1 goes to match 5, etc.).
7. Optionally create a 3rd-place match linked from semifinal losers via `loserAdvancesToMatchId`.

**Bye Distribution Strategy:**
- Byes go to the **highest-seeded positions** (positions 1, 2, 3, ... counting from top of bracket).
- In a bye match, only one participant is assigned (e.g., `participantRedId` is set, `participantBlueId` is null).
- The bye match is immediately marked `status = MatchStatus.completed`, `resultType = MatchResultType.bye`, `completedAtTimestamp = DateTime.now()`, and the solo participant's ID is set as `winnerId`.
- The winner is then placed in the appropriate slot of the next-round match.

**⚠️ CRITICAL: Match ID Generation:**
- Use `_uuid.v4()` for all match IDs. `Uuid` is DI-injected (already registered as `@lazySingleton` in `lib/core/di/register_module.dart`). Do NOT use `const Uuid()` — always inject via constructor.
- All match IDs must be generated BEFORE linking `winnerAdvancesToMatchId` / `loserAdvancesToMatchId`, because you need to know the target match IDs.

**⚠️ CRITICAL: Round and Match Numbering:**
- `roundNumber`: 1-indexed. Round 1 = first round (most matches). Final round = `totalRounds`.
- `matchNumberInRound`: 1-indexed. Within each round, matches are numbered sequentially from top to bottom.
- Round R has `bracketSize / pow(2, R)` matches. E.g., for bracketSize=8: Round 1 has 4 matches, Round 2 has 2, Round 3 has 1.

**⚠️ CRITICAL: Total Match Count:**
- Without 3rd-place match: `bracketSize - 1` total matches (e.g., 8-participant bracket = 7 matches)
- With 3rd-place match: `bracketSize` total matches (e.g., 8-participant bracket = 8 matches)

**⚠️ CRITICAL: Dart log2 Calculation:**
- Dart has NO `log2()` function. Use `import 'dart:math';` then calculate: `(log(N) / ln2).ceil()`
- `ln2` is a constant from `dart:math` = `0.6931471805599453`
- Example: `(log(5) / ln2).ceil()` = `(1.609 / 0.693).ceil()` = `2.322.ceil()` = `3`
- Do NOT use `log(N) / log(2)` — use the `ln2` constant for precision

### 3rd-Place Match Logic

When configured:
- Create an EXTRA match (not part of the regular bracket tree).
- `roundNumber` = `totalRounds` (same round as the final).
- `matchNumberInRound` = 2 (the final is match 1, 3rd-place is match 2).
- Two semifinal matches (Round `totalRounds - 1`) should have their `loserAdvancesToMatchId` set to the 3rd-place match ID.
- The 3rd-place match does NOT have `winnerAdvancesToMatchId` (no further advancement).

**3rd-Place Configuration:**
- Pass a `bool includeThirdPlaceMatch` parameter (default: `false`) to the generator service.
- Only valid when `totalRounds >= 2` (need at least semifinals + finals for a 3rd-place match).

### Existing Entities — DO NOT MODIFY

These entities already exist and MUST NOT be changed:

**`BracketEntity`** (from Story 5.2):
```dart
const factory BracketEntity({
  required String id,
  required String divisionId,
  required BracketType bracketType,    // Use BracketType.winners
  required int totalRounds,
  required DateTime createdAtTimestamp,
  required DateTime updatedAtTimestamp,
  String? poolIdentifier,              // null for single elimination
  @Default(false) bool isFinalized,    // false — finalized in Story 5.12
  DateTime? generatedAtTimestamp,       // SET to DateTime.now()
  DateTime? finalizedAtTimestamp,       // null
  Map<String, dynamic>? bracketDataJson, // optional metadata
  @Default(1) int syncVersion,
  @Default(false) bool isDeleted,
  DateTime? deletedAtTimestamp,
  @Default(false) bool isDemoData,
}) = _BracketEntity;
```

**`MatchEntity`** (from Story 5.3):
```dart
const factory MatchEntity({
  required String id,
  required String bracketId,
  required int roundNumber,
  required int matchNumberInRound,
  required DateTime createdAtTimestamp,
  required DateTime updatedAtTimestamp,
  String? participantRedId,              // null until seeding assigns
  String? participantBlueId,             // null until seeding assigns
  String? winnerId,                      // set for bye matches
  String? winnerAdvancesToMatchId,       // links to next-round match
  String? loserAdvancesToMatchId,        // used for 3rd-place match
  int? scheduledRingNumber,
  DateTime? scheduledTime,
  @Default(MatchStatus.pending) MatchStatus status,  // pending for normal, completed for byes
  MatchResultType? resultType,           // null for normal, bye for bye matches
  String? notes,
  DateTime? startedAtTimestamp,
  DateTime? completedAtTimestamp,
  @Default(1) int syncVersion,
  @Default(false) bool isDeleted,
  DateTime? deletedAtTimestamp,
  @Default(false) bool isDemoData,
}) = _MatchEntity;
```

**Enums** (from Story 5.3):
- `BracketType`: `winners`, `losers`, `pool`
- `MatchStatus`: `pending`, `ready`, `inProgress`, `completed`, `cancelled`
- `MatchResultType`: `points`, `knockout`, `disqualification`, `withdrawal`, `refereeDecision`, `bye`

### Existing Repository Interfaces — Extend These

**`BracketRepository`** — already has: `createBracket(BracketEntity bracket) → Either<Failure, BracketEntity>`

**`MatchRepository`** — already has: `createMatch(MatchEntity match) → Either<Failure, MatchEntity>`. **Add** `createMatches(List<MatchEntity> matches) → Either<Failure, List<MatchEntity>>` for batch insertion (performance optimization for N matches).

### Naming Conventions (Architecture Compliance)

| Item                    | Convention                                  | Example                                                                 |
| ----------------------- | ------------------------------------------- | ----------------------------------------------------------------------- |
| Service interfaces      | Domain layer, `abstract class`              | `SingleEliminationBracketGeneratorService`                              |
| Service implementations | Data layer, `@LazySingleton(as: Interface)` | `SingleEliminationBracketGeneratorServiceImplementation`                |
| Use cases               | Domain layer, `@injectable`                 | `GenerateSingleEliminationBracketUseCase`                               |
| Value objects           | Domain layer, Freezed                       | `BracketGenerationResult`                                               |
| File names              | `snake_case`                                | `single_elimination_bracket_generator_service.dart`                     |
| Test files              | Mirror source path + `_test.dart`           | `single_elimination_bracket_generator_service_implementation_test.dart` |

### DI Registration Pattern

**⚠️ CRITICAL: Follow EXACT patterns from existing codebase:**

```dart
// Service (domain interface → data implementation):
// File: lib/features/bracket/data/services/single_elimination_bracket_generator_service_implementation.dart
@LazySingleton(as: SingleEliminationBracketGeneratorService)
class SingleEliminationBracketGeneratorServiceImplementation
    implements SingleEliminationBracketGeneratorService {
  SingleEliminationBracketGeneratorServiceImplementation(this._uuid);
  final Uuid _uuid;
  // ... implementation
}

// Use case (MUST extend UseCase<T, Params> base class):
// File: lib/features/bracket/domain/usecases/generate_single_elimination_bracket_use_case.dart
// Reference: lib/features/division/domain/usecases/split_division_usecase.dart
@injectable
class GenerateSingleEliminationBracketUseCase
    extends UseCase<BracketGenerationResult, GenerateSingleEliminationBracketParams> {
  GenerateSingleEliminationBracketUseCase(
    this._generatorService,
    this._bracketRepository,
    this._matchRepository,
    this._uuid,
  );

  final SingleEliminationBracketGeneratorService _generatorService;
  final BracketRepository _bracketRepository;
  final MatchRepository _matchRepository;
  final Uuid _uuid;

  @override
  Future<Either<Failure, BracketGenerationResult>> call(
    GenerateSingleEliminationBracketParams params,
  ) async {
    // ... implementation
  }
}
```

**Required imports in use case file:**
```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/services/single_elimination_bracket_generator_service.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_single_elimination_bracket_params.dart';
```

### Error Handling Pattern

**⚠️ CRITICAL: Must check Either results from repository calls — do NOT ignore them!**

```dart
// Use case returns Either<Failure, BracketGenerationResult>
@override
Future<Either<Failure, BracketGenerationResult>> call(
  GenerateSingleEliminationBracketParams params,
) async {
  // 1. Validation
  if (params.participantIds.length < 2) {
    return const Left(ValidationFailure(
      userFriendlyMessage: 'At least 2 participants are required to generate a bracket.',
    ));
  }

  // 2. Generate bracket ID
  final bracketId = _uuid.v4();
  final now = DateTime.now();

  // 3. Create BracketEntity
  final bracket = BracketEntity(
    id: bracketId,
    divisionId: params.divisionId,
    bracketType: BracketType.winners,
    totalRounds: (log(params.participantIds.length) / ln2).ceil(),
    createdAtTimestamp: now,
    updatedAtTimestamp: now,
    generatedAtTimestamp: now,
    isFinalized: false,  // Story 5.12
    bracketDataJson: {
      'includeThirdPlaceMatch': params.includeThirdPlaceMatch,
      'participantCount': params.participantIds.length,
    },
  );

  // 4. Generate match structure (pure algorithm, no DB)
  final generationResult = _generatorService.generate(
    divisionId: params.divisionId,
    participantIds: params.participantIds,
    bracketId: bracketId,
    includeThirdPlaceMatch: params.includeThirdPlaceMatch,
  );

  // 5. Persist bracket — CHECK Either result!
  final bracketResult = await _bracketRepository.createBracket(bracket);
  return bracketResult.fold(
    Left.new,  // Propagate failure
    (_) async {
      // 6. Persist matches (batch) — CHECK Either result!
      final matchesResult = await _matchRepository.createMatches(
        generationResult.matches,
      );
      return matchesResult.fold(
        Left.new,  // Propagate failure
        (_) => Right(BracketGenerationResult(
          bracket: bracket,
          matches: generationResult.matches,
        )),
      );
    },
  );
}
```

### Batch Insert Implementation for AppDatabase

```dart
// In AppDatabase — add this method:
Future<void> insertMatches(List<MatchesCompanion> matchList) async {
  await batch((b) {
    b.insertAll(matches, matchList);
  });
}
```

```dart
// In MatchLocalDatasource interface — add:
Future<void> insertMatches(List<MatchModel> matchList);

// In MatchLocalDatasourceImplementation — add:
@override
Future<void> insertMatches(List<MatchModel> matchList) async {
  await _database.insertMatches(
    matchList.map((m) => m.toDriftCompanion()).toList(),
  );
}
```

```dart
// In MatchRepository interface — add:
Future<Either<Failure, List<MatchEntity>>> createMatches(
  List<MatchEntity> matches,
);

// In MatchRepositoryImplementation — add:
// ⚠️ LOCAL-ONLY: No remote sync for batch insert (remote datasource has no batch method)
@override
Future<Either<Failure, List<MatchEntity>>> createMatches(
  List<MatchEntity> matchEntities,
) async {
  try {
    final models = matchEntities
        .map(MatchModel.convertFromEntity)
        .toList();
    await _localDatasource.insertMatches(models);
    return Right(matchEntities);
  } on Exception catch (e) {
    return Left(LocalCacheWriteFailure(
      technicalDetails: 'Failed to create matches in batch: $e',
    ));
  }
}
```

### Exact Barrel File Content After This Story

```dart
/// Bracket feature - exports public APIs.
library;

// Data exports
export 'data/datasources/bracket_local_datasource.dart';
export 'data/datasources/bracket_remote_datasource.dart';
export 'data/datasources/match_local_datasource.dart';
export 'data/datasources/match_remote_datasource.dart';
export 'data/models/bracket_model.dart';
export 'data/models/match_model.dart';
export 'data/repositories/bracket_repository_implementation.dart';
export 'data/repositories/match_repository_implementation.dart';
export 'data/services/single_elimination_bracket_generator_service_implementation.dart';

// Domain exports
export 'domain/entities/bracket_entity.dart';
export 'domain/entities/bracket_generation_result.dart';
export 'domain/entities/match_entity.dart';
export 'domain/repositories/bracket_repository.dart';
export 'domain/repositories/match_repository.dart';
export 'domain/services/single_elimination_bracket_generator_service.dart';
export 'domain/usecases/generate_single_elimination_bracket_params.dart';
export 'domain/usecases/generate_single_elimination_bracket_use_case.dart';

// Presentation exports
```

### Exact Structure Test Changes

In `test/features/bracket/structure_test.dart`:
```dart
// Line 57: Change test name
test('barrel file should have seventeen export statements', () {

// Line 65: Change expected count
expect(
  matches.length,
  17,  // was 12
  reason: 'Barrel file should have seventeen exports for bracket & match entity & repo + services + usecases',
);
```

### UUID Dependency

**`uuid` is ALREADY a dependency** in `pubspec.yaml` (line 51: `uuid: ^4.5.2`). Do NOT add it again.

**`Uuid` is ALREADY registered in DI** as `@lazySingleton` in `lib/core/di/register_module.dart`. Do NOT create a new instance.

**⚠️ CRITICAL: Always inject Uuid via constructor — NEVER use `const Uuid()` directly:**
```dart
// ✅ CORRECT — DI-injected
class SingleEliminationBracketGeneratorServiceImplementation
    implements SingleEliminationBracketGeneratorService {
  SingleEliminationBracketGeneratorServiceImplementation(this._uuid);
  final Uuid _uuid;

  @override
  BracketGenerationResult generate({...}) {
    // Calculate total matches
    final totalRounds = (log(participantIds.length) / ln2).ceil();
    final bracketSize = pow(2, totalRounds).toInt();
    final totalMatches = bracketSize - 1 + (includeThirdPlaceMatch ? 1 : 0);
    final now = DateTime.now();

    // Generate ALL match IDs upfront BEFORE linking
    final matchIds = List.generate(totalMatches, (_) => _uuid.v4());
    // ... then create MatchEntity objects using these pre-generated IDs
  }
}

// ❌ WRONG — bypasses DI, not testable
const _uuid = Uuid();
```

**Reference pattern:** `lib/features/division/domain/usecases/split_division_usecase.dart` line 17: `SplitDivisionUseCase(this._divisionRepository, this._uuid);`

### Participant Assignment Note

**IMPORTANT:** This story generates the bracket STRUCTURE (bracket + match slots). Participants are NOT assigned to specific match slots in this story — that happens in Stories 5.7 (Dojang Separation Seeding), 5.8 (Regional Separation), and 5.10 (Bye Assignment). 

However, the `participantIds` list IS used to:
1. Determine `N` (participant count) for bracket sizing.
2. Pre-assign participants to bye matches where the slot has only one participant (the bye recipient is placed in `participantRedId`, `participantBlueId` is null, `winnerId` = bye recipient).

For non-bye matches in round 1, `participantRedId` and `participantBlueId` should be populated from the `participantIds` list in order (position 1 vs position `bracketSize`, position 2 vs position `bracketSize - 1`, etc. — standard bracket seeding positions). This enables the later seeding stories to simply reorder the `participantIds` list before calling the generator.

### Current Database State

- **Schema version**: 7 (NO CHANGE — no new tables or columns added by this story)
- **Barrel file exports**: Currently 12 (will increase to **17** after this story)
- **`domain/usecases/` directory**: Currently has only `.gitkeep` — this story adds the first use case
- **`domain/services/` directory**: Does NOT exist yet — create it
- **`data/services/` directory**: Does NOT exist yet — create it
- **`uuid` dependency**: Already in `pubspec.yaml` (line 51: `uuid: ^4.5.2`)
- **`Uuid` DI registration**: Already in `lib/core/di/register_module.dart` as `@lazySingleton`

### File Structure After This Story

```
lib/features/bracket/
├── bracket.dart                                         ← UPDATED barrel (17 exports)
├── README.md                                            ← Unchanged
├── data/
│   ├── datasources/
│   │   ├── bracket_local_datasource.dart                ← Unchanged
│   │   ├── bracket_remote_datasource.dart               ← Unchanged
│   │   ├── match_local_datasource.dart                  ← MODIFIED (add insertMatches)
│   │   └── match_remote_datasource.dart                 ← Unchanged
│   ├── models/
│   │   ├── bracket_model.dart                           ← Unchanged
│   │   ├── match_model.dart                             ← Unchanged
│   │   └── ...freezed/g files                           ← Unchanged
│   ├── repositories/
│   │   ├── bracket_repository_implementation.dart        ← Unchanged
│   │   └── match_repository_implementation.dart          ← MODIFIED (add createMatches)
│   └── services/                                        ← NEW DIRECTORY
│       └── single_elimination_bracket_generator_service_implementation.dart  ← NEW
├── domain/
│   ├── entities/
│   │   ├── bracket_entity.dart                          ← Unchanged
│   │   ├── bracket_generation_result.dart               ← NEW (@immutable, NOT Freezed)
│   │   └── match_entity.dart                            ← Unchanged
│   ├── repositories/
│   │   ├── bracket_repository.dart                      ← Unchanged
│   │   └── match_repository.dart                        ← MODIFIED (add createMatches)
│   ├── services/                                        ← NEW DIRECTORY
│   │   └── single_elimination_bracket_generator_service.dart  ← NEW
│   └── usecases/
│       ├── generate_single_elimination_bracket_params.dart  ← NEW
│       └── generate_single_elimination_bracket_use_case.dart  ← NEW
└── presentation/                                        ← Empty (Story 5.13)

test/features/bracket/
├── structure_test.dart                                  ← UPDATED (17 export count)
├── data/
│   └── services/
│       └── single_elimination_bracket_generator_service_implementation_test.dart  ← NEW
└── domain/
    └── usecases/
        └── generate_single_elimination_bracket_use_case_test.dart  ← NEW
```

### Testing Strategy

**Generator Service Tests (pure algorithm, no mocks needed):**
```dart
group('SingleEliminationBracketGeneratorServiceImplementation', () {
  group('bracket structure', () {
    test('should create 1 round for 2 participants', ...);
    test('should create 2 rounds for 3 participants', ...);
    test('should create 2 rounds for 4 participants', ...);
    test('should create 3 rounds for 5 participants', ...);
    test('should create 3 rounds for 7 participants', ...);
    test('should create 3 rounds for 8 participants', ...);
    test('should create 4 rounds for 16 participants', ...);
    test('should create 5 rounds for 32 participants', ...);
    test('should create 6 rounds for 64 participants', ...);
  });
  
  group('match tree linkage', () {
    test('should link all winners to correct next match', ...);
    test('should have null winnerAdvancesToMatchId for final match', ...);
    test('should have correct match count: bracketSize - 1', ...);
  });
  
  group('bye handling', () {
    test('should create 0 byes for power-of-2 participants', ...);
    test('should create correct bye count: bracketSize - N', ...);
    test('should mark bye matches as completed with resultType bye', ...);
    test('should set winnerId on bye matches', ...);
    test('should distribute byes evenly from top of bracket', ...);
  });
  
  group('3rd-place match', () {
    test('should create 3rd-place match when configured', ...);
    test('should link semifinal losers to 3rd-place match', ...);
    test('should not create 3rd-place match by default', ...);
    test('should not create 3rd-place match for 2-participant bracket', ...);
  });
});
```

**Use Case Tests (mock repositories):**
```dart
group('GenerateSingleEliminationBracketUseCase', () {
  test('should return ValidationFailure for less than 2 participants', ...);
  test('should return ValidationFailure for empty participant IDs', ...);
  test('should persist bracket and matches on success', ...);
  test('should return BracketGenerationResult on success', ...);
  test('should return failure when bracket creation fails', ...);
  test('should return failure when match creation fails', ...);
});
```

**Use `mocktail` for mocking repositories** (already a dev dependency).

### Project Structure Notes

- The service lives in `data/services/` (implementation) and `domain/services/` (interface) — this follows existing project patterns for services that don't need persistence but have complex logic.
- Use cases go in `domain/usecases/` — this is the first use case in the bracket feature, but the pattern exists in the architecture doc.
- The `BracketGenerationResult` value object goes in `domain/entities/` alongside other domain objects.
- **No presentation layer changes** — UI comes in Story 5.13.
- **No database schema changes** — uses existing tables and CRUD methods.

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 5, Story 5.4 (lines 1732-1748)]
- [Source: `_bmad-output/planning-artifacts/prd.md` — FR20: Single elimination brackets (line 884)]
- [Source: `_bmad-output/planning-artifacts/prd.md` — NFR: Bracket Generation < 500ms (line 1002)]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Matches table schema (lines 1488-1521)]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Brackets table schema (lines 1463-1486)]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Seeding Algorithm Architecture (lines 1720-1853)]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Use Case Pattern (lines 916-946)]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Naming Conventions (lines 948-966)]
- [Source: `_bmad-output/implementation-artifacts/5-3-match-entity-and-repository.md` — Match entity fields, model pattern]
- [Source: `_bmad-output/implementation-artifacts/5-3-match-entity-and-repository.md` — Anti-patterns table (lines 1350-1374)]
- [Source: `tkd_brackets/lib/features/bracket/domain/entities/bracket_entity.dart` — BracketEntity + BracketType enum]
- [Source: `tkd_brackets/lib/features/bracket/domain/entities/match_entity.dart` — MatchEntity + MatchStatus + MatchResultType enums]
- [Source: `tkd_brackets/lib/features/bracket/domain/repositories/bracket_repository.dart` — BracketRepository interface]
- [Source: `tkd_brackets/lib/features/bracket/domain/repositories/match_repository.dart` — MatchRepository interface]
- [Source: `tkd_brackets/lib/core/usecases/use_case.dart` — UseCase<T, Params> base class that ALL use cases MUST extend]
- [Source: `tkd_brackets/lib/features/division/domain/usecases/split_division_usecase.dart` — REFERENCE PATTERN: existing use case with Uuid DI injection]
- [Source: `tkd_brackets/lib/core/di/register_module.dart` — Uuid @lazySingleton registration (line 28-29)]
- [Source: `tkd_brackets/lib/core/database/tables/base_tables.dart` — BaseAuditMixin: createdAtTimestamp and updatedAtTimestamp have DB defaults]
- [Source: `tkd_brackets/lib/core/error/failures.dart` — Failure hierarchy with ValidationFailure]

---

## Anti-Patterns — WHAT NOT TO DO

| ❌ Don't Do This                                                                   | ✅ Do This Instead                                                                                                            | Source                         |
| --------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ------------------------------ |
| Create use case as standalone class without base                                  | **Extend `UseCase<BracketGenerationResult, GenerateSingleEliminationBracketParams>`** from `lib/core/usecases/use_case.dart` | `SplitDivisionUseCase` pattern |
| Use `const Uuid()` or `Uuid()` directly in code                                   | **Inject `Uuid` via constructor** — it's `@lazySingleton` in `register_module.dart`                                          | `SplitDivisionUseCase` line 17 |
| Use named parameters in `call()` method                                           | Override `call(GenerateSingleEliminationBracketParams params)` — single positional param                                     | `UseCase<T, Params>` contract  |
| Ignore `Either` results from repository calls                                     | **Always `fold()` or check** `Either` results — propagate `Left(Failure)` immediately                                        | Error handling pattern         |
| Use `log2(N)` or `log(N) / log(2)` for round calculation                          | Use `(log(N) / ln2).ceil()` — Dart has no `log2()`, use `ln2` constant from `dart:math`                                      | Dart math API                  |
| Forget `completedAtTimestamp` on bye matches                                      | Set `completedAtTimestamp: DateTime.now()` on bye matches (they're immediately completed)                                    | AC #3                          |
| Use Freezed for `BracketGenerationResult`                                         | Use plain `@immutable` class — no JSON/copyWith needed, avoid unnecessary code gen                                           | `NoParams` pattern             |
| Import `drift`, `supabase`, or any data-layer package in domain service interface | Domain service interface imports ONLY domain entities and Dart core                                                          | Clean Architecture             |
| Use `@injectable` for the service implementation                                  | Use `@LazySingleton(as: SingleEliminationBracketGeneratorService)` — services are singletons                                 | Bracket pattern                |
| Create a new Drift table or modify schema                                         | NO schema changes — use existing `brackets` and `matches` tables                                                             | Story scope                    |
| Place service implementation in `domain/services/`                                | Implementation goes in `data/services/`, interface in `domain/services/`                                                     | Clean Architecture             |
| Return raw `List<MatchEntity>` from use case                                      | Return `Either<Failure, BracketGenerationResult>` wrapping bracket + matches                                                 | Use case pattern               |
| Generate match IDs as you iterate                                                 | Generate ALL match IDs upfront, THEN link `winnerAdvancesToMatchId`                                                          | Algorithm correctness          |
| Use `result_type = 'bye'` string literal in domain code                           | Use `MatchResultType.bye` enum value                                                                                         | Story 5.3 entities             |
| Use `status = 'completed'` string literal                                         | Use `MatchStatus.completed` enum value                                                                                       | Story 5.3 entities             |
| Use `bracket_type = 'winners'` string literal                                     | Use `BracketType.winners` enum value                                                                                         | Story 5.2 entities             |
| Add `isBye` field to MatchEntity                                                  | Byes use `resultType = MatchResultType.bye` — NO dedicated `isBye` field                                                     | Architecture schema            |
| Use `participant1Id`/`participant2Id`                                             | Use `participantRedId`/`participantBlueId` — TKD red/blue corners                                                            | Architecture schema            |
| Use `nextMatchId`                                                                 | Use `winnerAdvancesToMatchId`                                                                                                | Architecture schema            |
| Store `MatchStatus`/`MatchResultType` as strings in domain                        | Domain uses enum types; only models (data layer) use strings                                                                 | Clean Architecture             |
| Access database directly from use case                                            | Use case calls repositories only                                                                                             | Clean Architecture             |
| Forget to set `generatedAtTimestamp` on the bracket                               | Set to `DateTime.now()` when creating the bracket                                                                            | AC #8                          |
| Set `isFinalized = true` on the bracket                                           | Keep `isFinalized = false` — finalization is Story 5.12                                                                      | AC #8                          |
| Make generator service depend on repositories                                     | Generator service is a PURE algorithm — no IO, no DB, no repos                                                               | Single Responsibility          |
| Skip batch insert for matches                                                     | Use batch insert (`insertMatches`) for performance — N can be up to 63 matches                                               | NFR                            |
| Forget `// ignore_for_file: invalid_annotation_target` on Freezed files           | Required for `@JsonKey` in Freezed constructors (NOT needed for `BracketGenerationResult`)                                   | Story 5.3 pattern              |
| Use `MatchesCompanion()` default constructor for insert                           | Use `MatchesCompanion.insert()` which knows required vs optional fields                                                      | Drift convention               |
| Forget `createdAtTimestamp`/`updatedAtTimestamp` when creating entities           | Set both to `DateTime.now()` — entity constructor REQUIRES them even though DB has defaults                                  | Entity constructor             |
| Add `uuid` to `pubspec.yaml`                                                      | Already there (line 51: `uuid: ^4.5.2`) — do NOT duplicate                                                                   | pubspec.yaml                   |
| Try remote sync in batch `createMatches`                                          | Batch createMatches is LOCAL-ONLY — skip remote sync (remote datasource has no batch method)                                 | Remote stub pattern            |

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### File List

**Created:**
- `lib/features/bracket/domain/entities/bracket_generation_result.dart` — `@immutable` value object (NOT Freezed)
- `lib/features/bracket/domain/usecases/generate_single_elimination_bracket_params.dart` — `@immutable` params class
- `lib/features/bracket/domain/services/single_elimination_bracket_generator_service.dart` — Service interface
- `lib/features/bracket/data/services/single_elimination_bracket_generator_service_implementation.dart` — Service implementation
- `lib/features/bracket/domain/usecases/generate_single_elimination_bracket_use_case.dart` — Use case
- `test/features/bracket/data/services/single_elimination_bracket_generator_service_implementation_test.dart` — Generator tests
- `test/features/bracket/domain/usecases/generate_single_elimination_bracket_use_case_test.dart` — Use case tests

**Modified:**
- `lib/core/error/failures.dart` — Add `BracketGenerationFailure`
- `lib/core/database/app_database.dart` — Add `insertMatches` batch method
- `lib/features/bracket/data/datasources/match_local_datasource.dart` — Add `insertMatches` method
- `lib/features/bracket/domain/repositories/match_repository.dart` — Add `createMatches` method
- `lib/features/bracket/data/repositories/match_repository_implementation.dart` — Add `createMatches` implementation (local-only, skip remote sync for batch)
- `lib/features/bracket/bracket.dart` — Add 5 new exports (total: 17)
- `test/features/bracket/structure_test.dart` — Update export count from 12 to 17

**NO generated Freezed files** — `BracketGenerationResult` and `Params` are plain `@immutable` classes.

### Completion Notes List

- This is the first algorithmic story in the bracket feature — no UI, pure domain + data layer logic
- The generator service is designed as a PURE FUNCTION (no side effects) for easy testing
- Batch insert is critical for performance — 64-participant bracket = 63 matches + optional 3rd-place = 64 inserts
- Participant slot assignment follows standard bracket seeding positions (1 vs N, 2 vs N-1, etc.)
- 3rd-place match is optional and NOT generated by default — only when explicitly requested
- No schema version bump needed — all data fits existing tables
- Cross-verified all field names against architecture schema and Story 5.3's implemented code
- **UseCase MUST extend base class** `UseCase<T, Params>` from `lib/core/usecases/use_case.dart` — verified against `SplitDivisionUseCase`
- **Uuid MUST be DI-injected** — it's `@lazySingleton` in `register_module.dart`, never use `const Uuid()`
- **Either results from repos MUST be checked** — use `fold()` to propagate failures
- **Dart has no `log2()`** — use `(log(N) / ln2).ceil()` with `import 'dart:math'`
- **BracketGenerationResult is `@immutable`, NOT Freezed** — avoids unnecessary code generation
- **Batch `createMatches` is LOCAL-ONLY** — remote datasource has no batch insert method
- **Bye matches need `completedAtTimestamp`** — they're immediately completed
- **`uuid` already exists** in `pubspec.yaml` (^4.5.2) — do NOT add again
- **5 new barrel exports** = exactly 17 total (was 12)
- **Two new directories** need creating: `domain/services/` and `data/services/`

### Change Log

- 2026-02-27: Story created — ready for implementation
- 2026-02-27: Validation pass — 6 critical fixes applied (UseCase base class, Uuid DI, Either checking, exact barrel count, completedAtTimestamp on byes, dart:math log2), 31 anti-patterns now documented
- 2026-02-27: Code review — Fixed 12 issues: removed unused imports (dart:math, meta), fixed all lint warnings (directives_ordering, lines_longer_than_80_chars, omit_local_variable_types, unnecessary_lambdas, depend_on_referenced_packages), expanded generator tests from 4→20+ and use case tests from 3→6, marked all tasks [x], deterministic UUID mock in tests

