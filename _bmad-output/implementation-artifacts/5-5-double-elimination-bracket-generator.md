# Story 5.5: Double Elimination Bracket Generator

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an organizer,
I want the system to generate a double elimination bracket from a list of participants,
so that athletes get a second chance after one loss before being eliminated (FR21).

## Acceptance Criteria

1. **Given** a division has N participants (where N ≥ 2), **When** I generate a double elimination bracket, **Then** `DoubleEliminationBracketGeneratorService` creates TWO `BracketEntity` records: one with `bracketType = BracketType.winners` and one with `bracketType = BracketType.losers`, both sharing the same `divisionId`.

2. **Given** a double elimination bracket is generated, **When** the winners bracket is created, **Then** the winners bracket is a standard single elimination bracket with `ceil(log2(N))` rounds, and each match has `loserAdvancesToMatchId` set to route losers into the correct position in the losers bracket.

3. **Given** a double elimination bracket is generated, **When** the losers bracket is created, **Then** the losers bracket has the correct number of rounds: `2 * (ceil(log2(N)) - 1)` rounds. Each round alternates between "drop-down" rounds (where winners bracket losers enter) and "elimination" rounds (pure losers bracket matches).

4. **Given** the losers bracket is constructed, **When** losers from the winners bracket drop down, **Then** each winners bracket loser is routed to a specific losers bracket round and position via `loserAdvancesToMatchId`. Winners bracket round R losers enter losers bracket at the "drop-down" round `2 * (R - 1)` (for R ≥ 2). Round 1 losers enter losers bracket round 1 directly.

5. **Given** the grand finals are configured, **When** the bracket is generated, **Then** a grand finals match is created with `bracketId` set to the winners bracket ID, `roundNumber = winners bracket totalRounds + 1`, connecting the winners bracket champion (via `winnerAdvancesToMatchId` from the winners final) and the losers bracket champion (via `winnerAdvancesToMatchId` from the losers final).

6. **Given** a reset match is configured (`includeResetMatch = true`, default: `true`), **When** the bracket is generated, **Then** an additional reset match is created at `roundNumber = winners bracket totalRounds + 2`, with `loserAdvancesToMatchId` from the grand finals pointing to the reset match (activated only if the losers bracket champion wins the grand finals — bracket progression handles this logic in Story 6.8).

7. **Given** participants count N is NOT a power of 2, **When** the bracket is generated, **Then** bye matches in the winners bracket round 1 are created with `resultType = MatchResultType.bye`, `status = MatchStatus.completed`, and bye recipients are advanced to both the winners bracket round 2 AND the losers bracket receives no entry from that bye match position.

8. **Given** the generator is called, **When** bracket generation completes, **Then** both `BracketEntity` records and ALL `MatchEntity` records are persisted to the local database via the existing `BracketRepository` and `MatchRepository`.

9. **Given** any participant count from 2 to 64, **When** bracket generation is triggered, **Then** generation completes in < 500ms (NFR2).

10. **Given** the bracket is generated, **When** I inspect the result, **Then** the use case returns `Either<Failure, DoubleEliminationBracketGenerationResult>` where `DoubleEliminationBracketGenerationResult` contains the winners `BracketEntity`, losers `BracketEntity`, grand finals `MatchEntity`, optional reset `MatchEntity`, and the combined list of all `MatchEntity` records.

11. **Given** a division with fewer than 2 participants, **When** bracket generation is attempted, **Then** the use case returns `Left(ValidationFailure)` with a descriptive error message.

12. **Given** a bracket is generated, **When** I inspect its metadata, **Then** both brackets have `isFinalized = false`, `generatedAtTimestamp` set, and `bracketDataJson` contains `{'doubleElimination': true, 'participantCount': N, 'includeResetMatch': bool}`.

## Tasks / Subtasks

- [x] **Task 1: Create `DoubleEliminationBracketGenerationResult` value object** (AC: #10)
  - [x] 1.1: Create `lib/features/bracket/domain/entities/double_elimination_bracket_generation_result.dart` — a plain `@immutable` class (NOT Freezed) containing:
    - `final BracketEntity winnersBracket`
    - `final BracketEntity losersBracket`
    - `final MatchEntity grandFinalsMatch`
    - `final MatchEntity? resetMatch` (null if reset disabled)
    - `final List<MatchEntity> allMatches` (all matches across both brackets + grand finals + reset)
    Follow the `BracketGenerationResult` pattern from `lib/features/bracket/domain/entities/bracket_generation_result.dart`.
  - [x] 1.2: Export it from the barrel file `lib/features/bracket/bracket.dart`.

- [x] **Task 2: Create `GenerateDoubleEliminationBracketParams` class** (AC: #10, #11)
  - [x] 2.1: Create `lib/features/bracket/domain/usecases/generate_double_elimination_bracket_params.dart` — a plain `@immutable` class containing:
    - `final String divisionId`
    - `final List<String> participantIds`
    - `final bool includeResetMatch` (default: `true`)
    Follow the `GenerateSingleEliminationBracketParams` pattern.
  - [x] 2.2: Export from the barrel file.

- [x] **Task 3: Create `DoubleEliminationBracketGeneratorService`** (AC: #1, #2, #3, #4, #5, #6, #7)
  - [x] 3.1: Create `lib/features/bracket/domain/services/double_elimination_bracket_generator_service.dart` — abstract interface with a single method: `DoubleEliminationBracketGenerationResult generate({required String divisionId, required List<String> participantIds, required String winnersBracketId, required String losersBracketId, bool includeResetMatch = true})`.
  - [x] 3.2: Create `lib/features/bracket/data/services/double_elimination_bracket_generator_service_implementation.dart` — concrete implementation that receives `Uuid` via constructor injection.
  - [x] 3.3: Register as `@LazySingleton(as: DoubleEliminationBracketGeneratorService)` in DI.
  - [x] 3.4: Export both from the barrel file.

- [x] **Task 4: Create `GenerateDoubleEliminationBracketUseCase`** (AC: #8, #9, #10, #11, #12)
  - [x] 4.1: Create `lib/features/bracket/domain/usecases/generate_double_elimination_bracket_use_case.dart`.
  - [x] 4.2: **MUST** extend `UseCase<DoubleEliminationBracketGenerationResult, GenerateDoubleEliminationBracketParams>` from `lib/core/usecases/use_case.dart`.
  - [x] 4.3: Constructor receives: `DoubleEliminationBracketGeneratorService`, `BracketRepository`, `MatchRepository`, `Uuid` — all via DI injection.
  - [x] 4.4: Override `call(GenerateDoubleEliminationBracketParams params)` method.
  - [x] 4.5: Validate inputs (≥ 2 participants, no empty IDs).
  - [x] 4.6: Orchestrate: generate 2 bracket IDs via `_uuid.v4()` → call generator service → persist BOTH brackets (check Either result for each) → persist all matches (batch) → return result or propagate failure.
  - [x] 4.7: **CRITICAL**: Check `Either` results from ALL repository calls — if `Left`, propagate the failure immediately.
  - [x] 4.8: Register as `@injectable` in DI.
  - [x] 4.9: Export from the barrel file.

- [x] **Task 5: Update barrel file** (AC: all)
  - [x] 5.1: Add exactly 5 new exports to `lib/features/bracket/bracket.dart`:
    - `export 'data/services/double_elimination_bracket_generator_service_implementation.dart';`
    - `export 'domain/entities/double_elimination_bracket_generation_result.dart';`
    - `export 'domain/services/double_elimination_bracket_generator_service.dart';`
    - `export 'domain/usecases/generate_double_elimination_bracket_params.dart';`
    - `export 'domain/usecases/generate_double_elimination_bracket_use_case.dart';`
    That is 5 new exports. New total: **22 exports** (was 17).
  - [x] 5.2: Update `test/features/bracket/structure_test.dart` — change export count assertion from `17` to `22`, update test name from `'seventeen'` to `'twenty-two'`, update reason string.

- [x] **Task 6: Write unit tests for `DoubleEliminationBracketGeneratorService`** (AC: #1, #2, #3, #4, #5, #6, #7)
  - [x] 6.1: Create `test/features/bracket/data/services/double_elimination_bracket_generator_service_implementation_test.dart`.
  - [x] 6.2: Test winners bracket structure for 2, 3, 4, 5, 8, 16 participants.
  - [x] 6.3: Test losers bracket correct round count: `2 * (ceil(log2(N)) - 1)`.
  - [x] 6.4: Test cross-bracket routing: every winners bracket match has `loserAdvancesToMatchId` pointing to the correct losers bracket match.
  - [x] 6.5: Test losers bracket match tree linkage: winners advance through losers bracket correctly.
  - [x] 6.6: Test grand finals match creation and linkage from both brackets.
  - [x] 6.7: Test reset match creation when `includeResetMatch = true`.
  - [x] 6.8: Test no reset match when `includeResetMatch = false`.
  - [x] 6.9: Test bye handling in winners bracket with correct losers bracket implications.
  - [x] 6.10: Test edge case: exactly 2 participants (1 winners match, 1 losers round, 1 grand finals).
  - [x] 6.11: Test total match count correctness.
  - [x] 6.12: Test that both brackets have correct `bracketType` (winners/losers).

- [x] **Task 7: Write unit tests for `GenerateDoubleEliminationBracketUseCase`** (AC: #8, #10, #11, #12)
  - [x] 7.1: Create `test/features/bracket/domain/usecases/generate_double_elimination_bracket_use_case_test.dart`.
  - [x] 7.2: Test successful generation returns `Right(DoubleEliminationBracketGenerationResult)`.
  - [x] 7.3: Test validation failure for < 2 participants.
  - [x] 7.4: Test validation failure for empty participant IDs.
  - [x] 7.5: Test that both brackets and all matches are persisted.
  - [x] 7.6: Test failure propagation when first bracket creation fails.
  - [x] 7.7: Test failure propagation when second bracket creation fails.
  - [x] 7.8: Test failure propagation when match batch creation fails.

- [x] **Task 8: Run code generation and verify** (AC: all)
  - [x] 8.1: Run `dart run build_runner build --delete-conflicting-outputs`.
  - [x] 8.2: Run `dart analyze` and fix any issues.
  - [x] 8.3: Run all tests and ensure 100% pass rate.

## Dev Notes

### ⚠️ TOP 10 COMMON LLM MISTAKES — READ FIRST

1. **Forgetting to extend `UseCase<T, Params>`** — the use case MUST extend `UseCase<DoubleEliminationBracketGenerationResult, GenerateDoubleEliminationBracketParams>`, NOT be a standalone class
2. **Using `const Uuid()` instead of DI injection** — Uuid is `@lazySingleton` in `register_module.dart`; inject via constructor
3. **Ignoring `Either` results from `createBracket` calls** — there are THREE sequential persistence calls; ALL must check `Either` with `fold()` and propagate `Left`
4. **Using `log2(N)` or `log(N) / log(2)`** — Dart has no `log2()`; use `(log(N) / ln2).ceil()` with `import 'dart:math'`
5. **Routing bye match losers to losers bracket** — bye matches have `loserAdvancesToMatchId = null`; there IS no loser
6. **Forgetting `completedAtTimestamp` on bye matches** — byes are immediately completed, must set `completedAtTimestamp: DateTime.now()`
7. **Using `@injectable` for the service implementation** — MUST use `@LazySingleton(as: DoubleEliminationBracketGeneratorService)`
8. **Importing data-layer packages in domain service interface** — domain service imports ONLY domain entities
9. **Placing service implementation in `domain/services/`** — implementation goes in `data/services/`
10. **Generating match IDs during iteration** — generate ALL IDs upfront BEFORE linking advancement

### Architecture Overview

This story creates the **second bracket generator** in the bracket feature. It follows the EXACT same architectural pattern established by Story 5.4 (Single Elimination Bracket Generator). The key difference is that double elimination produces TWO bracket entities (winners + losers) plus grand finals and optional reset match.

**Layer Responsibilities (SAME as Story 5.4):**
- **Domain Service** (`DoubleEliminationBracketGeneratorService`): Pure bracket generation algorithm — NO database access, NO imports from data layer.
- **Use Case** (`GenerateDoubleEliminationBracketUseCase`): Orchestrates validation → generation → persistence. Uses repositories to persist data.
- **Data Service Implementation**: Implements the domain service interface. Can ONLY import from domain layer and Dart core.

### Critical Algorithm: Double Elimination Bracket Generation

Double elimination gives every participant a second chance. After losing once in the winners bracket, they drop to the losers bracket. A second loss eliminates them entirely.

**Structure Overview for N=8 participants (3 W rounds, 4 L rounds, + Grand Finals):**

```
WINNERS BRACKET                    LOSERS BRACKET
==================                 ==================

W-R1 (4 matches)                   L-R1 (2 matches): W-R1 losers play each other
  W-M1: P1 vs P8 ──winner──→       Two pairs of Round 1 losers face off
  W-M2: P4 vs P5 ──winner──→
  W-M3: P2 vs P7 ──winner──→      L-R2 (2 matches): L-R1 winners vs W-R2 losers
  W-M4: P3 vs P6 ──winner──→       W-R2 losers "drop down" into this round

W-R2 (2 matches)                   L-R3 (1 match): L-R2 winners play each other
  W-M5: W1 vs W2 ──winner──→       Pure losers bracket elimination
  W-M6: W3 vs W4 ──winner──→
                                   L-R4 (1 match): L-R3 winner vs W-R3 loser
W-R3 (1 match = Final)             W-R3 loser "drops down" here
  W-M7: W5 vs W6 ──winner──→ Grand Finals
                   ──loser───→ L-R4
                                   L-R4 winner ──winner──→ Grand Finals

GRAND FINALS
==================
GF: Winners champion vs Losers champion
  → If Winners champ wins → Tournament over
  → If Losers champ wins → Reset match (if enabled)

RESET MATCH (optional)
==================
Reset: Rematch (Winners champ has "life" advantage)
```

### Losers Bracket Round Structure — DETAILED RULES

⚠️ **CRITICAL: The losers bracket alternation pattern is the hardest part of this algorithm.**

For a winners bracket with `W` rounds (where `W = ceil(log2(N))`), the losers bracket has `L = 2 * (W - 1)` rounds.

**Round Types in Losers Bracket:**
- **Odd rounds (1, 3, 5...)**: "Elimination rounds" — matches between losers bracket survivors only. The match count halves each time.
- **Even rounds (2, 4, 6...)**: "Drop-down rounds" — losers bracket survivors face winners bracket losers who just dropped down.

**Exception for Round 1:** Losers bracket round 1 is filled by winners bracket round 1 losers. They pair up against each other. For N=8 (4 WB R1 matches → 4 losers), LB R1 has 2 matches.

**Losers Bracket Match Counts per Round (N=8, W=3, L=4):**
| LB Round | Type        | Matches | Source                             |
| -------- | ----------- | ------- | ---------------------------------- |
| L-R1     | Elimination | 2       | WB R1 losers pair up (4→2 matches) |
| L-R2     | Drop-down   | 2       | L-R1 winners vs WB R2 losers       |
| L-R3     | Elimination | 1       | L-R2 winners play each other       |
| L-R4     | Drop-down   | 1       | L-R3 winner vs WB R3 (final) loser |

**Losers Bracket Match Counts per Round (N=16, W=4, L=6):**
| LB Round | Type        | Matches | Source                             |
| -------- | ----------- | ------- | ---------------------------------- |
| L-R1     | Elimination | 4       | WB R1 losers pair up (8→4 matches) |
| L-R2     | Drop-down   | 4       | L-R1 winners vs WB R2 losers       |
| L-R3     | Elimination | 2       | L-R2 winners play each other       |
| L-R4     | Drop-down   | 2       | L-R3 winners vs WB R3 losers       |
| L-R5     | Elimination | 1       | L-R4 winners play each other       |
| L-R6     | Drop-down   | 1       | L-R5 winner vs WB R4 (final) loser |

**General Formula (for power-of-2 N with W winners rounds):**
- LB R1: `N/4` matches (WB R1 losers pair up)
- LB R2: `N/4` matches (L-R1 winners vs WB R2 losers)
- LB R(2k-1): `N / (2^(k+1))` matches for k=2,3,...  (elimination)
- LB R(2k): same count as previous round (drop-down)
- Last LB round always has 1 match

### Cross-Bracket Routing Rules

**⚠️ CRITICAL: `loserAdvancesToMatchId` routing from Winners to Losers bracket:**

| Winners Bracket Loser From | Drops Into Losers Bracket Round | Notes                               |
| -------------------------- | ------------------------------- | ----------------------------------- |
| WB Round 1 match losers    | LB Round 1                      | Pair up against each other          |
| WB Round 2 match losers    | LB Round 2                      | Face LB R1 winners                  |
| WB Round R (R≥3) losers    | LB Round `2*(R-1)`              | Face previous LB elimination winner |
| WB Final loser             | LB Final round                  | Face LB semifinal winner            |

**Drop-down Ordering (Mirroring for Fairness):**
- WB losers dropping into even-numbered LB rounds should be placed in REVERSE order to avoid creating lopsided brackets (top WB loser faces bottom LB survivor).

### Grand Finals & Reset Match

**Grand Finals:**
- Created as a separate match with `bracketId` = winners bracket ID.
- `roundNumber` = `totalRounds + 1` (one beyond the winners bracket final).
- `matchNumberInRound` = 1.
- Connected from: winners bracket final winner + losers bracket final winner.
- `winnerAdvancesToMatchId` = reset match ID (if reset enabled).
- `loserAdvancesToMatchId` = null (if losers bracket champ loses, tournament over).

**Reset Match (when `includeResetMatch = true`):**
- Created with `bracketId` = winners bracket ID.
- `roundNumber` = `totalRounds + 2`.
- `matchNumberInRound` = 1.
- `winnerAdvancesToMatchId` = null (tournament ends).
- This match is ONLY played if the losers bracket champion wins the grand finals (the bracket progression service in Story 6.8 handles this conditional logic — this story just CREATES the match slot).

### Total Match Count Formula

For N participants (power of 2), W = log2(N) winners rounds:
- **Winners bracket**: `N - 1` matches (same as single elimination)
- **Losers bracket**: `N - 2` matches
- **Grand finals**: 1 match
- **Reset match**: 0 or 1
- **Total**: `2N - 2 + (includeResetMatch ? 1 : 0)` matches

For non-power-of-2 N:
- bracketSize = next power of 2 ≥ N
- Winners bracket: `bracketSize - 1` matches (including byes)
- Losers bracket: `bracketSize - 2` matches (minus byes that don't produce real losers)
- Grand finals: 1, Reset: 0 or 1

**⚠️ NOTE:** Bye matches in WB Round 1 do NOT send a "loser" to the losers bracket. Their `loserAdvancesToMatchId` should be null. This means the corresponding LB Round 1 position receives a bye as well.

### Existing Entities — DO NOT MODIFY

These entities already exist and MUST NOT be changed:

**`BracketEntity`** (from Story 5.2) — see Story 5.4 Dev Notes for full definition. Key fields:
- `bracketType`: Use `BracketType.winners` for winners bracket, `BracketType.losers` for losers bracket.
- All other fields identical to single elimination usage.

**`MatchEntity`** (from Story 5.3) — see Story 5.4 Dev Notes for full definition. Key fields:
- `winnerAdvancesToMatchId`: Links winner to next match (in same or other bracket).
- `loserAdvancesToMatchId`: Links loser to losers bracket match (used extensively in double elimination).
- `bracketId`: Each match must have the correct bracket ID (winners vs losers).

**Enums** (from Story 5.3):
- `BracketType`: `winners`, `losers`, `pool`
- `MatchStatus`: `pending`, `ready`, `inProgress`, `completed`, `cancelled`
- `MatchResultType`: `points`, `knockout`, `disqualification`, `withdrawal`, `refereeDecision`, `bye`

### Existing `BracketGenerationResult` — DO NOT MODIFY

The existing `BracketGenerationResult` holds a single bracket + matches. DO NOT modify it. Create a NEW `DoubleEliminationBracketGenerationResult` class specifically for double elimination.

### Naming Conventions (Architecture Compliance)

| Item                    | Convention                                     | Example                                                                 |
| ----------------------- | ---------------------------------------------- | ----------------------------------------------------------------------- |
| Service interfaces      | Domain layer, `abstract interface class`       | `DoubleEliminationBracketGeneratorService`                              |
| Service implementations | Data layer, `@LazySingleton(as: Interface)`    | `DoubleEliminationBracketGeneratorServiceImplementation`                |
| Use cases               | Domain layer, `@injectable`                    | `GenerateDoubleEliminationBracketUseCase`                               |
| Value objects           | Domain layer, plain `@immutable` (NOT Freezed) | `DoubleEliminationBracketGenerationResult`                              |
| Params classes          | Domain layer, plain `@immutable` (NOT Freezed) | `GenerateDoubleEliminationBracketParams`                                |
| File names              | `snake_case`                                   | `double_elimination_bracket_generator_service.dart`                     |
| Test files              | Mirror source path + `_test.dart`              | `double_elimination_bracket_generator_service_implementation_test.dart` |

### DI Registration Pattern

**⚠️ CRITICAL: Follow EXACT patterns from Story 5.4:**

```dart
// Service (domain interface → data implementation):
@LazySingleton(as: DoubleEliminationBracketGeneratorService)
class DoubleEliminationBracketGeneratorServiceImplementation
    implements DoubleEliminationBracketGeneratorService {
  DoubleEliminationBracketGeneratorServiceImplementation(this._uuid);
  final Uuid _uuid;
  // ... implementation
}

// Use case:
@injectable
class GenerateDoubleEliminationBracketUseCase
    extends UseCase<DoubleEliminationBracketGenerationResult,
        GenerateDoubleEliminationBracketParams> {
  GenerateDoubleEliminationBracketUseCase(
    this._generatorService,
    this._bracketRepository,
    this._matchRepository,
    this._uuid,
  );

  final DoubleEliminationBracketGeneratorService _generatorService;
  final BracketRepository _bracketRepository;
  final MatchRepository _matchRepository;
  final Uuid _uuid;

  @override
  Future<Either<Failure, DoubleEliminationBracketGenerationResult>> call(
    GenerateDoubleEliminationBracketParams params,
  ) async {
    // 1. Validation (≥ 2 participants, no empty IDs)
    // 2. Generate two bracket IDs
    // 3. Call generator service (pure algorithm)
    // 4. Persist winners bracket (check Either)
    // 5. Persist losers bracket (check Either)
    // 6. Persist all matches (batch, check Either)
    // 7. Return result
  }
}
```

### Error Handling Pattern

**⚠️ CRITICAL: Must check Either results from ALL repository calls:**

```dart
@override
Future<Either<Failure, DoubleEliminationBracketGenerationResult>> call(
  GenerateDoubleEliminationBracketParams params,
) async {
  // 1. Validation
  if (params.participantIds.length < 2) {
    return const Left(ValidationFailure(
      userFriendlyMessage:
          'At least 2 participants are required '
          'to generate a bracket.',
    ));
  }

  if (params.participantIds.any((id) => id.trim().isEmpty)) {
    return const Left(ValidationFailure(
      userFriendlyMessage: 'Participant list contains empty IDs.',
    ));
  }

  // 2. Generate bracket IDs
  final winnersBracketId = _uuid.v4();
  final losersBracketId = _uuid.v4();

  // 3. Generate bracket structure (pure algorithm, no DB)
  final generationResult = _generatorService.generate(
    divisionId: params.divisionId,
    participantIds: params.participantIds,
    winnersBracketId: winnersBracketId,
    losersBracketId: losersBracketId,
    includeResetMatch: params.includeResetMatch,
  );

  // 4. Persist winners bracket — CHECK Either result!
  final winnersResult = await _bracketRepository.createBracket(
    generationResult.winnersBracket,
  );
  return winnersResult.fold(
    Left.new,
    (_) async {
      // 5. Persist losers bracket — CHECK Either result!
      final losersResult = await _bracketRepository.createBracket(
        generationResult.losersBracket,
      );
      return losersResult.fold(
        Left.new,
        (_) async {
          // 6. Persist all matches (batch) — CHECK Either result!
          final matchesResult = await _matchRepository.createMatches(
            generationResult.allMatches,
          );
          return matchesResult.fold(
            Left.new,
            (_) => Right(generationResult),
          );
        },
      );
    },
  );
}
```

### Algorithm Implementation Guide

**⚠️ CRITICAL: Step-by-step implementation for the generator service:**

```dart
@override
DoubleEliminationBracketGenerationResult generate({
  required String divisionId,
  required List<String> participantIds,
  required String winnersBracketId,
  required String losersBracketId,
  bool includeResetMatch = true,
}) {
  final n = participantIds.length;
  final wRounds = (log(n) / ln2).ceil();
  final bracketSize = pow(2, wRounds).toInt();
  final lRounds = 2 * (wRounds - 1);
  final now = DateTime.now();

  // Step 1: Calculate total matches and pre-generate all IDs
  final wMatches = bracketSize - 1;
  final lMatches = _calculateLosersMatchCount(bracketSize, wRounds);
  final grandFinalsCount = 1;
  final resetCount = includeResetMatch ? 1 : 0;
  final totalMatches = wMatches + lMatches + grandFinalsCount + resetCount;
  final matchIds = List.generate(totalMatches, (_) => _uuid.v4());

  // Step 2: Create winners bracket (same algorithm as single elim)
  // ... create BracketEntity with bracketType = BracketType.winners

  // Step 3: Create losers bracket entity
  // ... create BracketEntity with bracketType = BracketType.losers

  // Step 4: Build winners bracket match tree

  // Step 5: Build losers bracket match tree

  // Step 6: Link cross-bracket routing (WB losers → LB positions)

  // Step 7: Create grand finals match

  // Step 8: Create reset match (if enabled)

  // Step 9: Advance bye winners and handle bye implications for LB
}
```

**Calculating Losers Bracket Match Count:**

```dart
int _calculateLosersMatchCount(int bracketSize, int wRounds) {
  // LB has 2*(wRounds-1) rounds
  // R1: bracketSize/4 matches
  // R2: bracketSize/4 matches
  // R3: bracketSize/8 matches
  // R4: bracketSize/8 matches
  // ... pattern: pairs of rounds with halving count
  // Total = bracketSize - 2
  return bracketSize - 2;
}
```

### Exact File Skeletons — COPY THESE

**⚠️ CRITICAL: Use these exact file templates. Do NOT deviate from import paths, annotations, or constructor patterns.**

**File 1: `lib/features/bracket/domain/entities/double_elimination_bracket_generation_result.dart`**
```dart
import 'package:flutter/foundation.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';

/// Value object containing the results of a double elimination
/// bracket generation operation.
@immutable
class DoubleEliminationBracketGenerationResult {
  const DoubleEliminationBracketGenerationResult({
    required this.winnersBracket,
    required this.losersBracket,
    required this.grandFinalsMatch,
    required this.allMatches,
    this.resetMatch,
  });

  final BracketEntity winnersBracket;
  final BracketEntity losersBracket;
  final MatchEntity grandFinalsMatch;
  final MatchEntity? resetMatch;
  final List<MatchEntity> allMatches;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoubleEliminationBracketGenerationResult &&
          runtimeType == other.runtimeType &&
          winnersBracket == other.winnersBracket &&
          losersBracket == other.losersBracket &&
          grandFinalsMatch == other.grandFinalsMatch &&
          resetMatch == other.resetMatch &&
          listEquals(allMatches, other.allMatches);

  @override
  int get hashCode =>
      winnersBracket.hashCode ^
      losersBracket.hashCode ^
      grandFinalsMatch.hashCode ^
      resetMatch.hashCode ^
      allMatches.hashCode;
}
```

**File 2: `lib/features/bracket/domain/usecases/generate_double_elimination_bracket_params.dart`**
```dart
import 'package:flutter/foundation.dart' show immutable;

/// Parameters for generating a double elimination bracket.
@immutable
class GenerateDoubleEliminationBracketParams {
  const GenerateDoubleEliminationBracketParams({
    required this.divisionId,
    required this.participantIds,
    this.includeResetMatch = true,
  });

  final String divisionId;
  final List<String> participantIds;
  final bool includeResetMatch;
}
```

**File 3: `lib/features/bracket/domain/services/double_elimination_bracket_generator_service.dart`**
```dart
import 'package:tkd_brackets/features/bracket/domain/entities/double_elimination_bracket_generation_result.dart';

/// Domain service for generating double elimination brackets.
/// This service contains the pure algorithm — NO database access.
abstract interface class DoubleEliminationBracketGeneratorService {
  /// Generates a double elimination bracket structure.
  ///
  /// [divisionId] is the ID of the division this bracket belongs to.
  /// [participantIds] is the list of participant IDs to seed.
  /// [winnersBracketId] is the pre-generated ID for the winners bracket.
  /// [losersBracketId] is the pre-generated ID for the losers bracket.
  /// [includeResetMatch] whether to generate a reset match.
  DoubleEliminationBracketGenerationResult generate({
    required String divisionId,
    required List<String> participantIds,
    required String winnersBracketId,
    required String losersBracketId,
    bool includeResetMatch = true,
  });
}
```

**File 4: Service implementation** — see DI Registration Pattern section for the class skeleton. Exact imports:
```dart
import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/double_elimination_bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/services/double_elimination_bracket_generator_service.dart';
import 'package:uuid/uuid.dart';
```

**File 5: Use case** — see DI Registration Pattern section for the class skeleton. Exact imports:
```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/double_elimination_bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/services/double_elimination_bracket_generator_service.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_params.dart';
import 'package:uuid/uuid.dart';
```

### Exact BracketEntity Construction — Winners vs Losers

**⚠️ Both brackets share the same `divisionId` but differ in `bracketType` and `totalRounds`:**

```dart
// Winners bracket entity
final winnersBracket = BracketEntity(
  id: winnersBracketId,
  divisionId: divisionId,
  bracketType: BracketType.winners,
  totalRounds: wRounds,
  createdAtTimestamp: now,
  updatedAtTimestamp: now,
  generatedAtTimestamp: now,
  bracketDataJson: {
    'doubleElimination': true,
    'participantCount': n,
    'includeResetMatch': includeResetMatch,
  },
);

// Losers bracket entity
final losersBracket = BracketEntity(
  id: losersBracketId,
  divisionId: divisionId,
  bracketType: BracketType.losers,
  totalRounds: lRounds,
  createdAtTimestamp: now,
  updatedAtTimestamp: now,
  generatedAtTimestamp: now,
  bracketDataJson: {
    'doubleElimination': true,
    'participantCount': n,
    'includeResetMatch': includeResetMatch,
  },
);
```

### UUID Dependency

**`uuid` is ALREADY a dependency** in `pubspec.yaml` (line 51: `uuid: ^4.5.2`). Do NOT add it again.

**`Uuid` is ALREADY registered in DI** as `@lazySingleton` in `lib/core/di/register_module.dart`. Do NOT create a new instance.

**⚠️ CRITICAL: Always inject Uuid via constructor — NEVER use `const Uuid()` directly.**

### Participant Assignment Note

**IDENTICAL to Story 5.4:** This story generates the bracket STRUCTURE. Participants are assigned to winners bracket Round 1 slots (same seeding position pattern as single elimination). The seeding stories (5.7, 5.8) reorder participants before calling the generator.

- Bye matches in WB R1: solo participant in `participantRedId`, `participantBlueId` = null, `winnerId` = bye recipient.
- Non-bye WB R1 matches: `participantRedId` + `participantBlueId` from participant list in standard bracket order.
- **LB matches start EMPTY** (no `participantRedId`/`participantBlueId`). They get populated as the bracket progresses during live play.
- Grand finals and reset match start EMPTY.

### ⚠️ DETAILED LOSERS BRACKET BUILDING ALGORITHM

**This is the HARDEST part of the implementation. Follow this pseudocode EXACTLY:**

```dart
// STEP A: Calculate LB matches per round
// LB has lRounds = 2 * (wRounds - 1) rounds total.
// Match counts per round follow this pattern:
//
// For bracketSize=8 (wRounds=3, lRounds=4):
//   LB R1: bracketSize/4 = 2 matches
//   LB R2: bracketSize/4 = 2 matches (same as R1)
//   LB R3: bracketSize/8 = 1 match
//   LB R4: bracketSize/8 = 1 match (same as R3)
//
// General pattern: Rounds come in PAIRS with same match count.
//   Pair k (k=1,2,...,wRounds-1):
//     Round 2k-1: bracketSize / pow(2, k+1) matches
//     Round 2k:   bracketSize / pow(2, k+1) matches
//
// Code to calculate:
int _lbMatchesInRound(int lbRound, int bracketSize) {
  // Pair index (1-based): round 1,2→pair 1; round 3,4→pair 2; etc.
  final pairIndex = (lbRound + 1) ~/ 2;
  return bracketSize ~/ pow(2, pairIndex + 1);
}

// STEP B: Create all LB match slots (similar to WB pattern)
final lbMatchMap = <int, Map<int, MatchEntity>>{};
for (var r = 1; r <= lRounds; r++) {
  lbMatchMap[r] = {};
  final count = _lbMatchesInRound(r, bracketSize);
  for (var m = 1; m <= count; m++) {
    final matchId = matchIds[matchIdIdx++]; // from pre-generated pool
    lbMatchMap[r]![m] = MatchEntity(
      id: matchId,
      bracketId: losersBracketId, // ← LOSERS bracket ID!
      roundNumber: r,
      matchNumberInRound: m,
      createdAtTimestamp: now,
      updatedAtTimestamp: now,
      status: MatchStatus.pending,
    );
  }
}

// STEP C: Link intra-LB advancement (within losers bracket)
// Odd rounds (elimination): winner advances to NEXT round (even)
// Even rounds (drop-down): winner advances to NEXT round (odd)
// Last round: winner advances to Grand Finals (set later)
for (var r = 1; r < lRounds; r++) {
  final currentRoundMatches = lbMatchMap[r]!;
  final nextRoundMatches = lbMatchMap[r + 1]!;

  if (r.isOdd) {
    // Elimination round → next is drop-down (same count)
    // Each match winner goes to same-numbered match in next round
    for (var m = 1; m <= currentRoundMatches.length; m++) {
      lbMatchMap[r]![m] = lbMatchMap[r]![m]!.copyWith(
        winnerAdvancesToMatchId: nextRoundMatches[m]!.id,
      );
    }
  } else {
    // Drop-down round → next is elimination (half count)
    // Standard bracket advancement: match m feeds match ceil(m/2)
    for (var m = 1; m <= currentRoundMatches.length; m++) {
      final nextMatchNum = (m + 1) ~/ 2;
      lbMatchMap[r]![m] = lbMatchMap[r]![m]!.copyWith(
        winnerAdvancesToMatchId: nextRoundMatches[nextMatchNum]!.id,
      );
    }
  }
}

// STEP D: Cross-bracket routing (WB losers → LB positions)
// WB R1 losers → LB R1 (pair up: WB M1 loser + WB M2 loser → LB R1 M1)
// WB R2 losers → LB R2 (face LB R1 winners)
// WB R(k≥3) losers → LB R(2*(k-1)) (face previous LB elim winners)
//
// For WB Round 1 losers → LB Round 1:
for (var m = 1; m <= wbMatchMap[1]!.length; m++) {
  // WB match m's loser goes to LB R1 match ceil(m/2)
  final lbMatchNum = (m + 1) ~/ 2;
  final lbMatch = lbMatchMap[1]![lbMatchNum]!;
  // Only set loserAdvancesToMatchId if NOT a bye match
  if (wbMatchMap[1]![m]!.resultType != MatchResultType.bye) {
    wbMatchMap[1]![m] = wbMatchMap[1]![m]!.copyWith(
      loserAdvancesToMatchId: lbMatch.id,
    );
  }
}

// For WB Round R (R≥2) losers → LB Round 2*(R-1):
for (var wbRound = 2; wbRound <= wRounds; wbRound++) {
  final lbTargetRound = 2 * (wbRound - 1);
  final wbMatches = wbMatchMap[wbRound]!;
  final lbMatches = lbMatchMap[lbTargetRound]!;

  for (var m = 1; m <= wbMatches.length; m++) {
    // REVERSE order for fairness (top WB loser faces bottom LB survivor)
    final lbMatchNum = lbMatches.length - m + 1;
    wbMatchMap[wbRound]![m] = wbMatchMap[wbRound]![m]!.copyWith(
      loserAdvancesToMatchId: lbMatches[lbMatchNum]!.id,
    );
  }
}
```

### Worked Example: N=4 (Full Match Linkage)

**bracketSize=4, wRounds=2, lRounds=2**

| Match ID | Bracket | Round | #   | Red     | Blue    | Winner→ | Loser→ |
| -------- | ------- | ----- | --- | ------- | ------- | ------- | ------ |
| wm1      | Winners | 1     | 1   | P1      | P4      | wm3     | lm1    |
| wm2      | Winners | 1     | 2   | P2      | P3      | wm3     | lm1    |
| wm3      | Winners | 2     | 1   | W(wm1)  | W(wm2)  | gf      | lm2    |
| lm1      | Losers  | 1     | 1   | (empty) | (empty) | lm2     | null   |
| lm2      | Losers  | 2     | 1   | (empty) | (empty) | gf      | null   |
| gf       | Winners | 3     | 1   | (empty) | (empty) | reset   | null   |
| reset    | Winners | 4     | 1   | (empty) | (empty) | null    | null   |

**Key observations:**
- LB R1 M1 receives losers from WB R1 M1 and WB R1 M2
- LB R2 M1 receives LB R1 winner + WB R2 (final) loser
- GF receives WB champion + LB champion
- GF `loserAdvancesToMatchId` = null (losers bracket champ loses = done)
- GF `winnerAdvancesToMatchId` = reset match ID (if reset enabled)
- Total: 3 WB + 2 LB + 1 GF + 1 reset = 7 matches

### Exact Test Setup Patterns for Use Case

**⚠️ The double elim use case test MUST mock TWO `createBracket` calls. Follow this EXACT pattern:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/double_elimination_bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/services/double_elimination_bracket_generator_service.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_use_case.dart';
import 'package:uuid/uuid.dart';

class MockBracketRepository extends Mock
    implements BracketRepository {}

class MockMatchRepository extends Mock
    implements MatchRepository {}

class MockGeneratorService extends Mock
    implements DoubleEliminationBracketGeneratorService {}

class MockUuid extends Mock implements Uuid {}

void main() {
  late GenerateDoubleEliminationBracketUseCase useCase;
  late MockBracketRepository mockBracketRepository;
  late MockMatchRepository mockMatchRepository;
  late MockGeneratorService mockGeneratorService;
  late MockUuid mockUuid;

  setUp(() {
    mockBracketRepository = MockBracketRepository();
    mockMatchRepository = MockMatchRepository();
    mockGeneratorService = MockGeneratorService();
    mockUuid = MockUuid();

    useCase = GenerateDoubleEliminationBracketUseCase(
      mockGeneratorService,
      mockBracketRepository,
      mockMatchRepository,
      mockUuid,
    );

    // MUST return different UUIDs for winners vs losers bracket IDs
    var uuidCounter = 0;
    when(() => mockUuid.v4()).thenAnswer(
      (_) => 'test-uuid-${uuidCounter++}',
    );

    registerFallbackValue(BracketEntity(
      id: '',
      divisionId: '',
      bracketType: BracketType.winners,
      totalRounds: 0,
      createdAtTimestamp: DateTime.now(),
      updatedAtTimestamp: DateTime.now(),
    ));

    registerFallbackValue(<MatchEntity>[]);
  });

  // Test data setup
  final tNow = DateTime.now();
  final tWinnersBracket = BracketEntity(
    id: 'test-uuid-0',
    divisionId: 'div-1',
    bracketType: BracketType.winners,
    totalRounds: 2,
    createdAtTimestamp: tNow,
    updatedAtTimestamp: tNow,
  );
  final tLosersBracket = BracketEntity(
    id: 'test-uuid-1',
    divisionId: 'div-1',
    bracketType: BracketType.losers,
    totalRounds: 2,
    createdAtTimestamp: tNow,
    updatedAtTimestamp: tNow,
  );
  final tGrandFinals = MatchEntity(
    id: 'gf',
    bracketId: 'test-uuid-0',
    roundNumber: 3,
    matchNumberInRound: 1,
    createdAtTimestamp: tNow,
    updatedAtTimestamp: tNow,
  );
  final tMatches = <MatchEntity>[/* ... */];
  final tResult = DoubleEliminationBracketGenerationResult(
    winnersBracket: tWinnersBracket,
    losersBracket: tLosersBracket,
    grandFinalsMatch: tGrandFinals,
    allMatches: tMatches,
  );

  void stubSuccessful() {
    when(
      () => mockGeneratorService.generate(
        divisionId: any(named: 'divisionId'),
        participantIds: any(named: 'participantIds'),
        winnersBracketId: any(named: 'winnersBracketId'),
        losersBracketId: any(named: 'losersBracketId'),
        includeResetMatch: any(named: 'includeResetMatch'),
      ),
    ).thenReturn(tResult);

    // ⚠️ MUST handle TWO createBracket calls
    when(() => mockBracketRepository.createBracket(any()))
        .thenAnswer((_) async => Right(tWinnersBracket));

    when(() => mockMatchRepository.createMatches(any()))
        .thenAnswer((_) async => Right(tMatches));
  }

  // ⚠️ Testing SECOND bracket failure requires ordered stub:
  void stubSecondBracketFails() {
    stubSuccessful();
    var callCount = 0;
    when(() => mockBracketRepository.createBracket(any()))
        .thenAnswer((_) async {
      callCount++;
      if (callCount == 1) return Right(tWinnersBracket);
      return const Left(LocalCacheWriteFailure());
    });
  }
}
```

### Exact Test for Generator Service (Mock UUID Pattern)

```dart
// Same pattern as single elimination:
class MockUuid extends Mock implements Uuid {}

void main() {
  late DoubleEliminationBracketGeneratorServiceImplementation
      generator;
  late MockUuid mockUuid;
  var uuidCounter = 0;

  setUp(() {
    mockUuid = MockUuid();
    uuidCounter = 0;
    generator =
        DoubleEliminationBracketGeneratorServiceImplementation(
      mockUuid,
    );

    when(() => mockUuid.v4()).thenAnswer(
      (_) => 'match-${uuidCounter++}',
    );
  });

  List<String> makeParticipants(int count) =>
      List.generate(count, (i) => 'p${i + 1}');

  // ... tests follow the patterns listed in Testing Strategy
}
```

### Testing Strategy

**Generator Service Tests (pure algorithm, no mocks needed)** — see "Exact Test for Generator Service" section above for imports/setup. Then write tests from the Testing Strategy table in the original section.

**Use Case Tests (mock repositories)** — see "Exact Test Setup Patterns for Use Case" section above for complete mock setup, including the `stubSecondBracketFails` pattern.

**Use `mocktail` for mocking repositories** (already a dev dependency).

### Current Database State

- **Schema version**: 7 (NO CHANGE — no new tables or columns)
- **Barrel file exports**: Currently 17 (will increase to **22** after this story)
- **Existing services directory**: `domain/services/` and `data/services/` ALREADY exist from Story 5.4
- **No new directories needed** — all target directories already exist

### File Structure After This Story

```
lib/features/bracket/
├── bracket.dart                                         ← UPDATED barrel (22 exports)
├── data/
│   └── services/
│       ├── single_elimination_bracket_generator_service_implementation.dart  ← Unchanged
│       └── double_elimination_bracket_generator_service_implementation.dart  ← NEW
├── domain/
│   ├── entities/
│   │   ├── bracket_entity.dart                          ← Unchanged
│   │   ├── bracket_generation_result.dart               ← Unchanged
│   │   ├── double_elimination_bracket_generation_result.dart  ← NEW
│   │   └── match_entity.dart                            ← Unchanged
│   ├── services/
│   │   ├── single_elimination_bracket_generator_service.dart  ← Unchanged
│   │   └── double_elimination_bracket_generator_service.dart  ← NEW
│   └── usecases/
│       ├── generate_single_elimination_bracket_params.dart  ← Unchanged
│       ├── generate_single_elimination_bracket_use_case.dart  ← Unchanged
│       ├── generate_double_elimination_bracket_params.dart  ← NEW
│       └── generate_double_elimination_bracket_use_case.dart  ← NEW
└── ...

test/features/bracket/
├── structure_test.dart                                  ← UPDATED (22 export count)
├── data/
│   └── services/
│       ├── single_elimination_bracket_generator_service_implementation_test.dart  ← Unchanged
│       └── double_elimination_bracket_generator_service_implementation_test.dart  ← NEW
└── domain/
    └── usecases/
        ├── generate_single_elimination_bracket_use_case_test.dart  ← Unchanged
        └── generate_double_elimination_bracket_use_case_test.dart  ← NEW
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
export 'data/services/double_elimination_bracket_generator_service_implementation.dart';
export 'data/services/single_elimination_bracket_generator_service_implementation.dart';

// Domain exports
export 'domain/entities/bracket_entity.dart';
export 'domain/entities/bracket_generation_result.dart';
export 'domain/entities/double_elimination_bracket_generation_result.dart';
export 'domain/entities/match_entity.dart';
export 'domain/repositories/bracket_repository.dart';
export 'domain/repositories/match_repository.dart';
export 'domain/services/double_elimination_bracket_generator_service.dart';
export 'domain/services/single_elimination_bracket_generator_service.dart';
export 'domain/usecases/generate_double_elimination_bracket_params.dart';
export 'domain/usecases/generate_double_elimination_bracket_use_case.dart';
export 'domain/usecases/generate_single_elimination_bracket_params.dart';
export 'domain/usecases/generate_single_elimination_bracket_use_case.dart';

// Presentation exports
```

### Exact Structure Test Changes

In `test/features/bracket/structure_test.dart`:
```dart
// Change test name
test('barrel file should have twenty-two export statements', () {

// Change expected count
expect(
  matches.length,
  22,  // was 17
  reason: 'Barrel file should have twenty-two exports for bracket '
      '& match entity & repo + services + usecases',
);
```

### Detailed Test Plan — Required Test Cases

**Generator Service Tests (pure algorithm, no mocks needed):**
```dart
group('DoubleEliminationBracketGeneratorServiceImplementation', () {
  group('bracket structure', () {
    test('should create winners bracket with BracketType.winners', ...);
    test('should create losers bracket with BracketType.losers', ...);
    test('should create correct WB round count for 2 participants', ...);
    test('should create correct WB round count for 4 participants', ...);
    test('should create correct WB round count for 8 participants', ...);
    test('should create correct WB round count for 16 participants', ...);
    test('should create correct LB round count: 2*(W-1)', ...);
  });

  group('match tree linkage', () {
    test('should link WB winners to correct next WB match', ...);
    test('should link WB losers to correct LB match via loserAdvancesToMatchId', ...);
    test('should link LB winners to correct next LB match', ...);
    test('should have null winnerAdvancesToMatchId for WB final (points to GF)', ...);
    test('should have null winnerAdvancesToMatchId for LB final (points to GF)', ...);
  });

  group('cross-bracket routing', () {
    test('WB R1 losers should route to LB R1', ...);
    test('WB R2 losers should route to LB R2', ...);
    test('WB final loser should route to last LB round', ...);
    test('drop-down ordering should mirror for fairness', ...);
  });

  group('grand finals', () {
    test('should create grand finals match', ...);
    test('GF should connect WB champion and LB champion', ...);
    test('GF roundNumber should be wRounds + 1', ...);
  });

  group('reset match', () {
    test('should create reset match when includeResetMatch true', ...);
    test('should not create reset match when includeResetMatch false', ...);
    test('reset roundNumber should be wRounds + 2', ...);
  });

  group('bye handling', () {
    test('should handle byes in WB correctly for non-power-of-2', ...);
    test('bye WB matches should not route loser to LB', ...);
    test('total match count correct with byes', ...);
  });

  group('total match counts', () {
    test('2 participants: 1 WB + 0 LB + 1 GF = 2 (or 3 with reset)', ...);
    test('4 participants: 3 WB + 2 LB + 1 GF = 6 (or 7 with reset)', ...);
    test('8 participants: 7 WB + 6 LB + 1 GF = 14 (or 15 with reset)', ...);
    test('16 participants: 15 WB + 14 LB + 1 GF = 30 (or 31 with reset)', ...);
  });
});
```

**Use Case Tests (mock repositories):**
```dart
group('GenerateDoubleEliminationBracketUseCase', () {
  test('should return ValidationFailure for less than 2 participants', ...);
  test('should return ValidationFailure for empty participant IDs', ...);
  test('should persist BOTH brackets and matches on success', ...);
  test('should return DoubleEliminationBracketGenerationResult on success', ...);
  test('should return failure when winners bracket creation fails', ...);
  test('should return failure when losers bracket creation fails', ...);
  test('should return failure when match creation fails', ...);
});
```

**Use `mocktail` for mocking repositories** (already a dev dependency).

### Edge Case: 2 Participants

With N=2:
- W rounds = 1, L rounds = 0 (special case!)
- Winners bracket: 1 match (the final)
- Losers bracket: 0 rounds, 0 matches — **BUT** we still need a losers bracket entity with `totalRounds = 0`
- Grand finals: 1 match (WB winner vs WB loser — since LB is empty, the WB loser goes directly to grand finals)
- The WB final's `loserAdvancesToMatchId` points to the grand finals match (not LB)
- This is a degenerate case — effectively just 2-3 matches total

**Implementation approach for N=2:**
- `lRounds = 2 * (1 - 1) = 0` — losers bracket has 0 rounds
- Create losers bracket entity with `totalRounds = 0`
- Skip losers bracket match creation
- WB final loser routes directly to grand finals as `participantBlueId` (or equivalent — the bracket progression service handles this)
- Total: 1 WB match + 0 LB matches + 1 GF + (optional 1 reset) = 2 or 3 matches

### Edge Case: 3 Participants

With N=3:
- bracketSize = 4, W rounds = 2, L rounds = 2
- WB R1: 2 matches (1 bye, 1 real)
- WB R2: 1 match (WB final)
- LB R1: 1 match — but only the real WB R1 loser enters (bye winner has no opponent)
  - LB R1 has 1 match, but a participant only comes from the NON-bye WB R1 match loser
  - The bye position in LB R1 makes this match a bye as well
- LB R2: 1 match (LB R1 winner vs WB R2 loser)
- GF: 1 match
- Total: 3 WB + 2 LB + 1 GF + (optional reset) = 6 or 7

### Project Structure Notes

- All new files go into existing directories — NO new directories need to be created.
- This is a domain + data layer story only — NO presentation layer changes.
- NO database schema changes — existing `brackets` and `matches` tables handle both bracket types.
- The `bracketType` field on `BracketEntity` already supports `winners` and `losers` values.
- Grand finals and reset match use the winners bracket ID for their `bracketId` field.

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 5, Story 5.5 (lines 1752-1768)]
- [Source: `_bmad-output/planning-artifacts/prd.md` — FR21: Double elimination brackets]
- [Source: `_bmad-output/planning-artifacts/prd.md` — NFR: Bracket Generation < 500ms]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Matches table schema]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Brackets table schema]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Seeding Algorithm Architecture (lines 1720-1853)]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Use Case Pattern (lines 916-946)]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Naming Conventions (lines 948-966)]
- [Source: `_bmad-output/implementation-artifacts/5-4-single-elimination-bracket-generator.md` — Previous story: patterns, learnings, anti-patterns]
- [Source: `tkd_brackets/lib/features/bracket/domain/entities/bracket_entity.dart` — BracketEntity + BracketType enum (winners/losers/pool)]
- [Source: `tkd_brackets/lib/features/bracket/domain/entities/match_entity.dart` — MatchEntity with loserAdvancesToMatchId]
- [Source: `tkd_brackets/lib/features/bracket/domain/entities/bracket_generation_result.dart` — Existing result class (DO NOT MODIFY)]
- [Source: `tkd_brackets/lib/features/bracket/data/services/single_elimination_bracket_generator_service_implementation.dart` — Reference implementation pattern]
- [Source: `tkd_brackets/lib/features/bracket/domain/services/single_elimination_bracket_generator_service.dart` — Reference service interface pattern]
- [Source: `tkd_brackets/lib/features/bracket/domain/usecases/generate_single_elimination_bracket_use_case.dart` — Reference use case pattern]
- [Source: `tkd_brackets/lib/core/usecases/use_case.dart` — UseCase<T, Params> base class]
- [Source: `tkd_brackets/lib/core/di/register_module.dart` — Uuid @lazySingleton registration]
- [Source: `tkd_brackets/lib/core/error/failures.dart` — Failure hierarchy with ValidationFailure and BracketGenerationFailure]

---

## Anti-Patterns — WHAT NOT TO DO

| ❌ Don't Do This                                                | ✅ Do This Instead                                                                                           | Source                         |
| -------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------------------------------ |
| Modify `BracketGenerationResult` to hold two brackets          | **Create NEW `DoubleEliminationBracketGenerationResult`** with separate winnersBracket/losersBracket fields | Clean Architecture             |
| Create use case as standalone class without base               | **Extend `UseCase<DoubleEliminationBracketGenerationResult, GenerateDoubleEliminationBracketParams>`**      | `UseCase<T, Params>` contract  |
| Use `const Uuid()` or `Uuid()` directly in code                | **Inject `Uuid` via constructor** — it's `@lazySingleton` in `register_module.dart`                         | `SplitDivisionUseCase` pattern |
| Ignore `Either` results from ANY repository call               | **Always `fold()` or check** `Either` results — propagate `Left(Failure)` immediately                       | Error handling pattern         |
| Use `log2(N)` or `log(N) / log(2)` for round calculation       | Use `(log(N) / ln2).ceil()` — Dart has no `log2()`, use `ln2` constant from `dart:math`                     | Dart math API                  |
| Route bye match losers to losers bracket                       | **Bye matches have `loserAdvancesToMatchId = null`** — there IS no loser to route                           | Bye handling                   |
| Make generator service depend on repositories                  | Generator service is a PURE algorithm — no IO, no DB, no repos                                              | Single Responsibility          |
| Put grand finals/reset in losers bracket                       | Grand finals and reset match use **winners bracket ID** for `bracketId`                                     | Convention                     |
| Use `bracket_type = 'main'` or `'consolation'` string literals | Use `BracketType.winners` and `BracketType.losers` enum values                                              | Story 5.2 entities             |
| Create matches for WB and LB in separate batch calls           | Combine ALL matches (WB + LB + GF + reset) into **one batch** `createMatches()` call                        | Performance                    |
| Set `isFinalized = true`                                       | Keep `isFinalized = false` — finalization is Story 5.12                                                     | AC #12                         |
| Forget `generatedAtTimestamp`                                  | Set to `DateTime.now()` on both brackets                                                                    | AC #12                         |
| Forget `completedAtTimestamp` on bye matches                   | Set `completedAtTimestamp: DateTime.now()` on bye matches                                                   | Story 5.4 learning             |
| Use Freezed for result/params classes                          | Use plain `@immutable` class — no JSON/copyWith needed                                                      | `NoParams` pattern             |
| Use `@injectable` for the service implementation               | Use `@LazySingleton(as: DoubleEliminationBracketGeneratorService)`                                          | Service singleton pattern      |
| Generate match IDs as you iterate                              | Generate ALL match IDs upfront, THEN link advancement/routing                                               | Algorithm correctness          |
| Use `participant1Id`/`participant2Id`                          | Use `participantRedId`/`participantBlueId` — TKD red/blue corners                                           | Architecture schema            |
| Use `nextMatchId`                                              | Use `winnerAdvancesToMatchId` (and `loserAdvancesToMatchId`)                                                | Architecture schema            |
| Forget to set `createdAtTimestamp` / `updatedAtTimestamp`      | Set both to `DateTime.now()` on entity creation                                                             | Entity constructor             |
| Add `uuid` to `pubspec.yaml`                                   | Already there (`uuid: ^4.5.2`)                                                                              | pubspec.yaml                   |
| Import data-layer packages in domain service interface         | Domain service interface imports ONLY domain entities and Dart core                                         | Clean Architecture             |
| Place service implementation in `domain/services/`             | Implementation goes in `data/services/`, interface in `domain/services/`                                    | Clean Architecture             |
| Modify existing `BracketEntity` or `MatchEntity`               | NO entity changes — use existing entities as-is                                                             | Story scope                    |
| Skip batch insert for matches                                  | Use batch `createMatches()` — double elim can produce 30+ matches                                           | NFR performance                |
| Implement bracket progression logic (e.g., conditional reset)  | Progression is Story 6.8 — this story only creates the match SLOTS                                          | Story scope                    |
| Import `dart:math` but never use it                            | Only import `dart:math` in the service implementation — the use case does NOT need it                       | Story 5.4 code review          |
| Import `package:flutter/foundation.dart` in service impl       | Service impl only needs `dart:math`, `injectable`, domain entities, `uuid`                                  | Story 5.4 code review          |
| Use `unnecessary_lambdas` pattern (e.g., `(x) => foo(x)`)      | Use tear-off syntax: `Left.new` instead of `(f) => Left(f)` — Dart lint rule                                | Story 5.4 code review          |
| Lines longer than 80 characters                                | Break lines at 80 chars — project enforces `lines_longer_than_80_chars` lint rule                           | Story 5.4 code review          |
| Declare explicit local variable types                          | Use `var`/`final` — project enforces `omit_local_variable_types` lint rule                                  | Story 5.4 code review          |
| Pre-populate LB match participants                             | LB matches start with null participant IDs — they are filled during live tournament play                    | Bracket progression (6.8)      |

---

## Dev Agent Record

### Agent Model Used

Gemini 2.5 (Antigravity)

### Debug Log References

Code review performed on 2026-02-28.

### Senior Developer Review (AI)

**Reviewer:** Asak (via Antigravity) on 2026-02-28
**Outcome:** Approved with fixes applied

**Fixes Applied:**
- **H1 (CRITICAL):** Removed dangerous placeholder `MatchEntity` fallback with hardcoded `id: 'placeholder'`. Added `ArgumentError` guard for `n < 2` in service. Used non-null assertion for `grandFinalsMatch`.
- **M1:** Added test for LB intra-bracket advancement linkage.
- **M2:** Added test for AC#12 metadata (isFinalized, generatedAtTimestamp, bracketDataJson).
- **M3:** Added test for GF/reset roundNumber verification.
- **M4:** Added test for drop-down reverse ordering fairness.
- **M5:** Fixed barrel file export ordering to alphabetical per story spec.
- **L1:** Filled in Dev Agent Record metadata.

**Noted (not fixed):**
- **H2:** AC#6 text says `loserAdvancesToMatchId` from GF → reset, but Dev Notes say `winnerAdvancesToMatchId`. Implementation follows Dev Notes. Story 6.8 bracket progression will handle the conditional routing semantics. No code change needed — AC text is ambiguous about double elimination GF routing.
- **L2:** No explicit performance test for AC#9 (<500ms). Algorithm is O(N), trivially fast.
- **L3:** `pow()` returns `num` — cosmetic, bit-shifting alternative noted but not applied.

### Completion Notes List

- Second bracket generator in the bracket feature — follows identical architectural pattern to Story 5.4
- Double elimination is significantly more complex than single elimination due to cross-bracket routing
- The losers bracket alternation pattern (elimination vs drop-down rounds) must be implemented correctly
- Grand finals and reset match are separate constructs outside the normal bracket tree
- Bye handling in winners bracket has implications for losers bracket (no loser to route)
- All match IDs MUST be pre-generated before linking begins
- Generator service is a PURE FUNCTION — no database access, no side effects
- Use case persists: 2 brackets + all matches in batch
- `BracketType.losers` is already available in the enum from Story 5.2
- No schema version bump needed — all data fits existing `brackets` and `matches` tables
- 5 new barrel exports = exactly 22 total (was 17)
- No new directories needed — `domain/services/` and `data/services/` exist from Story 5.4
- **Dart has no `log2()`** — use `(log(N) / ln2).ceil()` with `import 'dart:math'`
- **Uuid MUST be DI-injected** from `register_module.dart`
- **Either results from repos MUST be checked** — use `fold()` to propagate failures
- **BracketGenerationResult is NOT modified** — new `DoubleEliminationBracketGenerationResult` created
- **LB matches start empty** — no participants assigned, filled during live play
- **Grand finals/reset match use winners bracket ID** for `bracketId`
- **Reset match is a slot** — conditional play is handled by bracket progression (Story 6.8)

### File List

**Created:**
- `lib/features/bracket/domain/entities/double_elimination_bracket_generation_result.dart` — `@immutable` value object
- `lib/features/bracket/domain/usecases/generate_double_elimination_bracket_params.dart` — `@immutable` params class
- `lib/features/bracket/domain/services/double_elimination_bracket_generator_service.dart` — Service interface
- `lib/features/bracket/data/services/double_elimination_bracket_generator_service_implementation.dart` — Service implementation
- `lib/features/bracket/domain/usecases/generate_double_elimination_bracket_use_case.dart` — Use case
- `test/features/bracket/data/services/double_elimination_bracket_generator_service_implementation_test.dart` — Generator tests
- `test/features/bracket/domain/usecases/generate_double_elimination_bracket_use_case_test.dart` — Use case tests

**Modified:**
- `lib/features/bracket/bracket.dart` — Add 5 new exports (total: 22)
- `test/features/bracket/structure_test.dart` — Update export count from 17 to 22

**NO generated Freezed files** — `DoubleEliminationBracketGenerationResult` and `Params` are plain `@immutable` classes.
