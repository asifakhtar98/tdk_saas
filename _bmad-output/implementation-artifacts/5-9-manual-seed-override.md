# Story 5.9: Manual Seed Override

Status: completed
Assignee: Asak
Story ID: 5.9
FRs: FR29 (Manual seed override with drag-and-drop)
Epic: 5 — Bracket Generation & Seeding
Previous Story: 5.8 — Regional Separation Seeding (completed)

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an organizer,
I want to manually override automatic seeding by swapping, pinning, or re-seeding around fixed positions,
so that I can place specific athletes in specific positions when automatic seeding doesn't match my needs (FR29).

## Acceptance Criteria

1. **ManualSeedOverrideService**: A service exists at `lib/core/algorithms/seeding/services/manual_seed_override_service.dart`. It is `@injectable` and accepts a `SeedingEngine` via DI. It provides three core operations: swap, pin, and re-seed-around-pins.
2. **Swap Operation**: `swapParticipants({required currentResult, required participantIdA, required participantIdB, required participants, required constraints, required bracketSize})` swaps the `seedPosition` (and `bracketSlot`) of two participants in an existing `SeedingResult`. Creates **new** `ParticipantPlacement` objects (immutable — do NOT mutate originals). Returns `Either<Failure, SeedingResult>` with re-validated constraint status. Validation: both IDs exist, IDs are not the same.
3. **Pin Operation**: `pinParticipant({required currentPins, required participantId, required seedPosition, required bracketSize})` adds/updates a pin in a `Map<String, int>` (participantId → seedPosition). Returns `Either<Failure, Map<String, int>>` with a **new** Map copy (do NOT mutate `currentPins`). Validation: participantId must not be empty, seedPosition must be ≥ 1 and ≤ bracketSize, no two participants can be pinned to the same seed position. **Note:** Unpinning = simply remove the key from the Map; no separate service method needed.
4. **Re-Seed Around Pins**: `reseedAroundPins(params)` takes `ManualSeedOverrideParams` containing participants, pins, constraints, and bracketFormat. It calls the `SeedingEngine.generateSeeding()` but with pinned participants pre-placed at their fixed positions and only the unpinned participants subjected to the constraint-satisfying backtracking algorithm. Returns `Either<Failure, SeedingResult>`.
5. **Engine Enhancement — Pinned Seeds Support**: The `SeedingEngine.generateSeeding()` method gains an optional `pinnedSeeds` parameter (`Map<String, int>?`). The `ConstraintSatisfyingSeedingEngine` implementation respects pinned seeds by: (a) pre-placeing pinned participants at their specified positions before backtracking, (b) excluding pinned seed positions from the available pool, (c) only running constraint satisfaction on unpinned participants. Pinned participants are included in constraint checks but never moved.
6. **Constraint Validation of Manual Placements**: After any swap operation, the service uses `constraint.countViolations()` to count violations (NOT `SeedingEngine.validateSeeding()` — because we need the COUNT for `SeedingResult.constraintViolationCount`, and `validateSeeding()` only returns pass/fail). For re-seed, the engine handles validation internally. If violations exist, the result is still `Right(SeedingResult)` but with `isFullySatisfied = false`, `constraintViolationCount > 0`, and `warnings` listing the violation details. The user is informed but not blocked.
7. **ManualSeedOverrideParams**: An `@immutable` params class at `lib/core/algorithms/seeding/services/manual_seed_override_params.dart` containing: `participants` (List<SeedingParticipant>), `pinnedSeeds` (Map<String, int>), `constraints` (List<SeedingConstraint>), `bracketFormat` (BracketFormat), `randomSeed` (int?).
8. **Use Case**: `ApplyManualSeedOverrideUseCase` at `lib/core/algorithms/seeding/usecases/apply_manual_seed_override_use_case.dart`. It is `@injectable`, extends `UseCase<SeedingResult, ApplyManualSeedOverrideParams>`, delegates to `ManualSeedOverrideService.reseedAroundPins()`. Validates: non-empty divisionId, ≥ 2 participants, no empty IDs, no empty dojangNames, no duplicate IDs, pinned seed positions are valid (1..bracketSize), no duplicate pinned positions, pinned participant IDs exist in participant list.
9. **ApplyManualSeedOverrideParams**: `@immutable` params class at `lib/core/algorithms/seeding/usecases/apply_manual_seed_override_params.dart` containing: `divisionId`, `participants`, `pinnedSeeds`, `constraints`, `bracketFormat`, `enableDojangSeparation`, `dojangMinimumRoundsSeparation`, `regionalMinimumRoundsSeparation`, `enableRegionalSeparation`, `randomSeed`.
10. **Edge Cases**: (a) All participants pinned → `_buildPinnedOnlyResult()` called, no engine invocation, just validate and return. (b) No participants pinned (empty map `{}`) → equivalent to normal seeding (engine runs normally). (c) Pinned participant has same dojang as neighbor → constraint violation warning but not blocked. (d) Pin position exceeds bracketSize → `ValidationFailure` (in use case validation). (e) Duplicate pin positions → `ValidationFailure`. (f) Pinned participantId not in participants list → `ValidationFailure`. (g) 1 participant → use case returns `ValidationFailure` (< 2 participants). (h) All same dojang with pins → early-exit random path respects pins.
11. **Performance**: Manual seed override operations (swap, pin, re-seed) complete in < 100ms for 64 participants (NFR2 — tighter than bracket generation since this is user-initiated). Use `Stopwatch()..start()` pattern (see existing engine test line 126).
12. **Unit Tests**: Tests verify: (a) swap — two participants exchange positions (new `ParticipantPlacement` objects created), (b) swap — invalid participantId returns `ValidationFailure`, (c) swap — same participant for both → `ValidationFailure`, (d) pin — adds participant to pin map (returns new Map), (e) pin — duplicate position returns `ValidationFailure`, (f) pin — empty participantId returns `ValidationFailure`, (g) pin — position < 1 returns `ValidationFailure`, (h) pin — position > bracketSize returns `ValidationFailure`, (i) re-seed around pins — pinned participants stay at exact positions, (j) re-seed — unpinned participants satisfy constraints, (k) re-seed — all pinned → returns placements as-is with validation, (l) re-seed — no pins → equivalent to normal seeding, (m) re-seed — constraint violations produce warnings not errors (`isFullySatisfied = false`), (n) use case validation — all 8 validation checks (empty divisionId, < 2 participants, empty IDs, empty dojangNames, duplicate IDs, pin out of range, duplicate pins, pinned ID not found), (o) use case — successful delegation with correct params, (p) use case — constraint construction (dojang + regional when both enabled, regional-only when dojang disabled), (q) use case — SeedingFailure propagated from service, (r) engine pinned seeds — backtracking respects pinned positions, (s) performance < 100ms for 64 participants.

## Tasks / Subtasks

- [x] Task 1: Enhance SeedingEngine with Pinned Seeds Support (AC: #5)
    - [x] Open `lib/core/algorithms/seeding/seeding_engine.dart`
    - [x] Add optional `pinnedSeeds` parameter to `generateSeeding()` — `Map<String, int>? pinnedSeeds`
    - [x] Open `lib/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart`
    - [x] Modify `generateSeeding()` to accept `pinnedSeeds` parameter
    - [x] In `generateSeeding()`, before backtracking: pre-place pinned participants, exclude their seed positions from available pool
    - [x] Modify `_backtrack()` to skip pinned participants (they're already placed)
    - [x] Ensure pinned participants are included in constraint checks during backtracking (their placements are in `currentPlacements`)
    - [x] Run existing tests: `cd tkd_brackets && dart test test/core/algorithms/seeding/` — ALL must pass unchanged (backward compatible since `pinnedSeeds` is optional/nullable)
- [x] Task 2: Create ManualSeedOverrideParams (AC: #7)
    - [x] Create `lib/core/algorithms/seeding/services/manual_seed_override_params.dart` — see skeleton in Dev Notes
- [x] Task 3: Implement ManualSeedOverrideService (AC: #1, #2, #3, #4, #6)
    - [x] Create `lib/core/algorithms/seeding/services/manual_seed_override_service.dart` — see skeleton in Dev Notes
    - [x] Implement `swapParticipants()` — validate both IDs exist, swap seedPosition and bracketSlot, re-validate constraints
    - [x] Implement `pinParticipant()` — validate inputs, add/update pin map
    - [x] Implement `reseedAroundPins()` — construct constraints, call engine with pinnedSeeds, return result
    - [x] Add `@injectable` annotation
- [x] Task 4: Create ApplyManualSeedOverrideParams (AC: #9)
    - [x] Create `lib/core/algorithms/seeding/usecases/apply_manual_seed_override_params.dart` — see skeleton
- [x] Task 5: Implement ApplyManualSeedOverrideUseCase (AC: #8)
    - [x] Create `lib/core/algorithms/seeding/usecases/apply_manual_seed_override_use_case.dart` — see skeleton
    - [x] Implement validation checks (8 checks — see Dev Notes)
    - [x] Build constraints list based on params (dojang + regional, configurable)
    - [x] Delegate to `ManualSeedOverrideService.reseedAroundPins()`
- [x] Task 6: Write Unit Tests for Engine Pinned Seeds (AC: #12n)
    - [x] Create `test/core/algorithms/seeding/constraint_satisfying_seeding_engine_pinned_test.dart`
    - [x] Test: pinned participants stay at their fixed positions
    - [x] Test: unpinned participants are assigned via backtracking
    - [x] Test: constraint checking includes pinned participants
    - [x] Test: all participants pinned → returns exact placement
    - [x] Test: no pins → same as regular seeding (backward compat)
    - [x] Test: pinned seed excluded from available pool for unpinned
- [x] Task 7: Write Unit Tests for ManualSeedOverrideService (AC: #12a-k)
    - [x] Create `test/core/algorithms/seeding/services/manual_seed_override_service_test.dart`
    - [x] Test: swap — two participants exchange positions
    - [x] Test: swap — invalid participantId → `ValidationFailure`
    - [x] Test: swap — same participant ID for both → `ValidationFailure`
    - [x] Test: pin — adds to pin map correctly
    - [x] Test: pin — duplicate position → `ValidationFailure`
    - [x] Test: pin — empty participantId → `ValidationFailure`
    - [x] Test: pin — position < 1 → `ValidationFailure`
    - [x] Test: pin — position > bracketSize → `ValidationFailure`
    - [x] Test: reseedAroundPins — pinned participants stay fixed
    - [x] Test: reseedAroundPins — unpinned satisfy constraints
    - [x] Test: reseedAroundPins — all pinned returns as-is
    - [x] Test: reseedAroundPins — no pins equivalent to normal seeding
    - [x] Test: reseedAroundPins — constraint violations produce warnings
    - [x] Test: performance — 64 participants < 100ms
- [x] Task 8: Write Unit Tests for Use Case (AC: #12l, #12m)
    - [x] Create `test/core/algorithms/seeding/usecases/apply_manual_seed_override_use_case_test.dart`
    - [x] Test: validation — empty divisionId → `ValidationFailure`
    - [x] Test: validation — < 2 participants → `ValidationFailure`
    - [x] Test: validation — empty participant IDs → `ValidationFailure`
    - [x] Test: validation — empty dojangNames → `ValidationFailure`
    - [x] Test: validation — duplicate IDs → `ValidationFailure`
    - [x] Test: validation — pin position out of range → `ValidationFailure`
    - [x] Test: validation — duplicate pin positions → `ValidationFailure`
    - [x] Test: validation — pinned ID not in participants → `ValidationFailure`
    - [x] Test: successful delegation to service with correct params
    - [x] Test: constraint construction — dojang + regional when enabled
    - [x] Test: constraint construction — regional-only when dojang disabled
- [x] Task 9: Quality Assurance (AC: #11)
    - [x] Run `cd tkd_brackets && dart run build_runner build --delete-conflicting-outputs` — verify injectable config regenerates
    - [x] Run `cd tkd_brackets && dart analyze` — zero errors/warnings
    - [x] Run `cd tkd_brackets && flutter test` — ALL project tests pass

## Dev Notes

### Architecture Context

This story **extends** the seeding algorithm infrastructure created in Stories 5.7 and 5.8. All new files live in `lib/core/algorithms/seeding/` — the same core subsystem.

**⚠️ CRITICAL: This is NOT a bracket feature service.** All files go in `lib/core/algorithms/seeding/`, NOT in `lib/features/bracket/`. The seeding engine is a core algorithm used across multiple bracket types.

The `SeedingStrategy.manual` enum value already exists in `seeding_strategy.dart` — it was defined in Story 5.7 with the description "User-defined positions with constraint validation." This story implements the functionality behind that strategy.

### DI Registration Pattern

- **ManualSeedOverrideService**: `@injectable` — takes `SeedingEngine` as constructor parameter (auto-resolved by DI)
- **ApplyManualSeedOverrideUseCase**: `@injectable` — takes `ManualSeedOverrideService` as constructor parameter
- **No `register_module.dart` changes** — injectable auto-discovers via annotations
- After completing implementation, run `dart run build_runner build --delete-conflicting-outputs` to regenerate `injection.config.dart`

### How Pinned Seeds Work in the Engine

The key change to `ConstraintSatisfyingSeedingEngine.generateSeeding()` is minimal:

1. **Pre-place pinned participants**: Before the backtracking loop, iterate the `pinnedSeeds` map. For each pinned participant, find them in the `ordered` list, set `positions[index] = pinnedSeedPosition`, and add the seed to `usedSeeds`.
2. **Skip pinned in backtracking**: In `_backtrack()`, if `positions[participantIndex]` is already set (pinned), skip to next index: `if (positions[participantIndex] != null) return _backtrack(participantIndex + 1, ...)`.
3. **Include in constraint checks**: Pinned participants' placements are already in `currentPlacements` since we build it from all indices 0..participantIndex. No change needed — they're automatically included.

**This is backward compatible** because `pinnedSeeds` defaults to `null` and the code only activates when it's non-null and non-empty.

### SeedingEngine Modification (EXACT DIFF)

**File**: `lib/core/algorithms/seeding/seeding_engine.dart`

```diff
  Either<Failure, SeedingResult> generateSeeding({
    required List<SeedingParticipant> participants,
    required SeedingStrategy strategy,
    required List<SeedingConstraint> constraints,
    required BracketFormat bracketFormat,
    int? randomSeed,
+   Map<String, int>? pinnedSeeds,
  });
```

**File**: `lib/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart`

```diff
  @override
  Either<Failure, SeedingResult> generateSeeding({
    required List<SeedingParticipant> participants,
    required SeedingStrategy strategy,
    required List<SeedingConstraint> constraints,
    required BracketFormat bracketFormat,
    int? randomSeed,
+   Map<String, int>? pinnedSeeds,
  }) {
    final n = participants.length;
    // ... existing code ...

    // 4. Flatten groups into placement order (largest dojang first)
    final ordered = _flattenGroupsLargestFirst(groups, rng);

+   // 4b. Pre-place pinned participants
+   final positions = List<int?>.filled(n, null);
+   final usedSeeds = <int>{};
+   if (pinnedSeeds != null && pinnedSeeds.isNotEmpty) {
+     for (final entry in pinnedSeeds.entries) {
+       final idx = ordered.indexWhere((p) => p.id == entry.key);
+       if (idx >= 0 && entry.value >= 1 && entry.value <= bracketSize) {
+         positions[idx] = entry.value;
+         usedSeeds.add(entry.value);
+       }
+     }
+   }

-   // 5. Attempt backtracking placement
-   final positions = List<int?>.filled(n, null);
-   final usedSeeds = <int>{};
+   // 5. Attempt backtracking placement (skipping pre-placed)
    // ... rest of backtracking code ...
```

And in `_backtrack()`:

```diff
  bool _backtrack({
    // ... params ...
  }) {
    if (participantIndex == ordered.length) return true;
    if (context.iterations >= context.maxIterations) return false;
    context.iterations++;

+   // Skip pinned participants — already pre-placed
+   if (positions[participantIndex] != null) {
+     return _backtrack(
+       participantIndex: participantIndex + 1,
+       ordered: ordered,
+       positions: positions,
+       usedSeeds: usedSeeds,
+       constraints: constraints,
+       allParticipants: allParticipants,
+       bracketSize: bracketSize,
+       context: context,
+     );
+   }
+
    // Try all possible seed positions ...
```

**⚠️ CRITICAL: Fallback Paths Must Also Handle Pinned Seeds**

The `_buildRandomResult()` and `_fallbackMinimizeViolations()` methods also need pinned-seed awareness:

**`_buildRandomResult()`** (called when all same dojang): Instead of shuffling ALL participants, keep pinned participants at their fixed positions. Only shuffle unpinned participants into the remaining seed slots.

```diff
  Either<Failure, SeedingResult> _buildRandomResult(
    List<SeedingParticipant> participants,
    int bracketSize,
    int effectiveSeed,
    Random rng,
-   List<SeedingConstraint> constraints, {
+   List<SeedingConstraint> constraints,
+   Map<String, int>? pinnedSeeds, {
    required String warning,
  }) {
-   final shuffled = List<SeedingParticipant>.from(participants)..shuffle(rng);
    final placements = <ParticipantPlacement>[];
-   for (var i = 0; i < shuffled.length; i++) {
-     placements.add(
-       ParticipantPlacement(
-         participantId: shuffled[i].id,
-         seedPosition: i + 1,
-         bracketSlot: i + 1,
-       ),
-     );
+   final usedSeeds = <int>{};
+
+   // 1. Place pinned participants first
+   if (pinnedSeeds != null) {
+     for (final entry in pinnedSeeds.entries) {
+       placements.add(
+         ParticipantPlacement(
+           participantId: entry.key,
+           seedPosition: entry.value,
+           bracketSlot: entry.value,
+         ),
+       );
+       usedSeeds.add(entry.value);
+     }
+   }
+
+   // 2. Shuffle unpinned participants into remaining slots
+   final unpinned = participants
+       .where((p) => pinnedSeeds == null || !pinnedSeeds.containsKey(p.id))
+       .toList()..shuffle(rng);
+   final availableSeeds = <int>[];
+   for (var i = 1; i <= participants.length; i++) {
+     if (!usedSeeds.contains(i)) availableSeeds.add(i);
    }
+   for (var i = 0; i < unpinned.length; i++) {
+     placements.add(
+       ParticipantPlacement(
+         participantId: unpinned[i].id,
+         seedPosition: availableSeeds[i],
+         bracketSlot: availableSeeds[i],
+       ),
+     );
+   }
```

**`_fallbackMinimizeViolations()`** (called when backtracking exhausts iterations): Keep pinned participants at fixed positions, only permute unpinned participants across remaining slots. Must also accept `pinnedSeeds`.

```diff
  Either<Failure, SeedingResult> _fallbackMinimizeViolations({
    required List<SeedingParticipant> participants,
    required List<SeedingConstraint> constraints,
    required int bracketSize,
    required int effectiveSeed,
    required Random rng,
+   Map<String, int>? pinnedSeeds,
  }) {
-   // Try 100 random permutations and pick the best one
    List<ParticipantPlacement>? bestPlacements;
    var minViolations = double.maxFinite.toInt();

+   // Identify pinned vs unpinned participants
+   final pinnedIds = pinnedSeeds?.keys.toSet() ?? <String>{};
+   final unpinned = participants.where((p) => !pinnedIds.contains(p.id)).toList();
+   final pinnedPlacements = <ParticipantPlacement>[];
+   final usedByPinned = <int>{};
+   if (pinnedSeeds != null) {
+     for (final entry in pinnedSeeds.entries) {
+       pinnedPlacements.add(
+         ParticipantPlacement(
+           participantId: entry.key,
+           seedPosition: entry.value,
+           bracketSlot: entry.value,
+         ),
+       );
+       usedByPinned.add(entry.value);
+     }
+   }
+   final availableSeeds = <int>[
+     for (var i = 1; i <= bracketSize; i++)
+       if (!usedByPinned.contains(i)) i,
+   ];

    for (var i = 0; i < 100; i++) {
-     final shuffled = List<SeedingParticipant>.from(participants)
+     final shuffled = List<SeedingParticipant>.from(unpinned)
        ..shuffle(rng);
-     final currentPlacements = <ParticipantPlacement>[];
+     final currentPlacements = List<ParticipantPlacement>.from(pinnedPlacements);
      for (var j = 0; j < shuffled.length; j++) {
        currentPlacements.add(
          ParticipantPlacement(
            participantId: shuffled[j].id,
-           seedPosition: j + 1,
-           bracketSlot: j + 1,
+           seedPosition: availableSeeds[j],
+           bracketSlot: availableSeeds[j],
          ),
        );
      }
      // ... rest of violation counting unchanged ...
    }
```

**⚠️ CRITICAL: Call-Site Updates in `generateSeeding()`**

The `generateSeeding()` method calls both helpers — you MUST pass `pinnedSeeds` through:

```diff
    // Line ~53: Early-exit for all same dojang
    if (uniqueDojangs.length <= 1) {
      return _buildRandomResult(
        participants,
        bracketSize,
        effectiveSeed,
        rng,
        constraints,
+       pinnedSeeds: pinnedSeeds,
        warning: 'All participants are from the same dojang. '
            'Random seeding applied — separation not possible.',
      );
    }

    // ... backtracking code ...

    // Line ~109: Fallback when backtracking fails
    return _fallbackMinimizeViolations(
      participants: participants,
      constraints: constraints,
      bracketSize: bracketSize,
      effectiveSeed: effectiveSeed,
      rng: rng,
+     pinnedSeeds: pinnedSeeds,
    );
```

### Backward Compatibility Guarantee

**Why existing tests pass unchanged after adding `pinnedSeeds`:**

1. `pinnedSeeds` is `Map<String, int>?` — **nullable and optional**, defaults to `null`
2. All existing code calls `generateSeeding()` WITHOUT `pinnedSeeds` → it passes `null`
3. The engine checks `if (pinnedSeeds != null && pinnedSeeds.isNotEmpty)` — with `null`, the pinning logic is skipped entirely
4. **Existing test mocks** using `MockSeedingEngine extends Mock implements SeedingEngine {}` auto-inherit the new parameter. The `when()` stubs that don't constrain `pinnedSeeds` will match any value (including `null`)
5. **Existing `verify()` calls** that don't include `pinnedSeeds` will still match because mocktail's verify tolerates unspecified optional parameters

**Verification command (run AFTER Task 1, BEFORE any other task):**
```bash
cd tkd_brackets && dart test test/core/algorithms/seeding/
```
All existing tests must pass with zero changes.

### File Skeletons

#### 1. `lib/core/algorithms/seeding/services/manual_seed_override_params.dart`

```dart
import 'package:flutter/foundation.dart' show immutable;
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/seeding_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

/// Parameters for the re-seed-around-pins operation.
@immutable
class ManualSeedOverrideParams {
  const ManualSeedOverrideParams({
    required this.participants,
    required this.constraints,
    this.pinnedSeeds = const {},
    this.bracketFormat = BracketFormat.singleElimination,
    this.randomSeed,
  });

  /// All participants in the division.
  final List<SeedingParticipant> participants;

  /// Map of participantId → fixed seed position.
  /// These participants will NOT be moved during re-seeding.
  final Map<String, int> pinnedSeeds;

  /// Constraints to apply during re-seeding.
  final List<SeedingConstraint> constraints;

  /// Bracket format affects meeting-round calculations.
  final BracketFormat bracketFormat;

  /// Optional random seed for reproducibility.
  final int? randomSeed;
}
```

#### 2. `lib/core/algorithms/seeding/services/manual_seed_override_service.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/seeding_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/manual_seed_override_params.dart';
import 'package:tkd_brackets/core/error/failures.dart';

/// Service for manual seed override operations: swap, pin, and re-seed.
///
/// All operations return [Either<Failure, T>] for consistent error handling.
/// Constraint violations after manual changes produce warnings, not errors —
/// the organizer is informed but not blocked.
@injectable
class ManualSeedOverrideService {
  ManualSeedOverrideService(this._seedingEngine);

  final SeedingEngine _seedingEngine;

  /// Swaps the seed positions of two participants in an existing seeding result.
  ///
  /// Returns updated [SeedingResult] with swapped positions and re-validated
  /// constraint status.
  Either<Failure, SeedingResult> swapParticipants({
    required SeedingResult currentResult,
    required String participantIdA,
    required String participantIdB,
    required List<SeedingParticipant> participants,
    required List<SeedingConstraint> constraints,
    required int bracketSize,
  }) {
    if (participantIdA == participantIdB) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Cannot swap a participant with themselves.',
        ),
      );
    }

    final indexA = currentResult.placements.indexWhere(
      (p) => p.participantId == participantIdA,
    );
    final indexB = currentResult.placements.indexWhere(
      (p) => p.participantId == participantIdB,
    );

    if (indexA < 0) {
      return Left(
        ValidationFailure(
          userFriendlyMessage:
              'Participant $participantIdA not found in current seeding.',
        ),
      );
    }
    if (indexB < 0) {
      return Left(
        ValidationFailure(
          userFriendlyMessage:
              'Participant $participantIdB not found in current seeding.',
        ),
      );
    }

    // Create new placements with swapped positions
    final newPlacements = List<ParticipantPlacement>.from(
      currentResult.placements,
    );
    final placementA = newPlacements[indexA];
    final placementB = newPlacements[indexB];

    newPlacements[indexA] = ParticipantPlacement(
      participantId: placementA.participantId,
      seedPosition: placementB.seedPosition,
      bracketSlot: placementB.bracketSlot,
    );
    newPlacements[indexB] = ParticipantPlacement(
      participantId: placementB.participantId,
      seedPosition: placementA.seedPosition,
      bracketSlot: placementA.bracketSlot,
    );

    // Re-validate constraints
    final warnings = <String>[];
    var violationCount = 0;
    for (final constraint in constraints) {
      final violations = constraint.countViolations(
        placements: newPlacements,
        participants: participants,
        bracketSize: bracketSize,
      );
      violationCount += violations;
    }

    if (violationCount > 0) {
      warnings.add(
        'Manual swap caused $violationCount constraint violation(s). '
        'Review seeding before locking bracket.',
      );
    }

    return Right(
      SeedingResult(
        placements: newPlacements,
        appliedConstraints: currentResult.appliedConstraints,
        randomSeed: currentResult.randomSeed,
        warnings: warnings,
        constraintViolationCount: violationCount,
        isFullySatisfied: violationCount == 0,
      ),
    );
  }

  /// Adds or updates a pin in the pin map.
  ///
  /// Returns updated pin map or failure if validation fails.
  Either<Failure, Map<String, int>> pinParticipant({
    required Map<String, int> currentPins,
    required String participantId,
    required int seedPosition,
    required int bracketSize,
  }) {
    if (participantId.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Participant ID is required for pinning.',
        ),
      );
    }

    if (seedPosition < 1 || seedPosition > bracketSize) {
      return Left(
        ValidationFailure(
          userFriendlyMessage:
              'Seed position must be between 1 and $bracketSize.',
        ),
      );
    }

    // Check for duplicate positions (another participant pinned here)
    for (final entry in currentPins.entries) {
      if (entry.key != participantId && entry.value == seedPosition) {
        return Left(
          ValidationFailure(
            userFriendlyMessage:
                'Seed position $seedPosition is already pinned to '
                'participant ${entry.key}.',
          ),
        );
      }
    }

    final newPins = Map<String, int>.from(currentPins);
    newPins[participantId] = seedPosition;
    return Right(newPins);
  }

  /// Re-seeds unpinned participants around pinned positions.
  ///
  /// Pinned participants stay at their fixed positions.
  /// Unpinned participants are re-seeded using the constraint-satisfying
  /// engine with pinned positions excluded from the available pool.
  Either<Failure, SeedingResult> reseedAroundPins(
    ManualSeedOverrideParams params,
  ) {
    // If all participants are pinned, just build and validate result
    if (params.pinnedSeeds.length >= params.participants.length) {
      return _buildPinnedOnlyResult(params);
    }

    // Delegate to engine with pinnedSeeds
    return _seedingEngine.generateSeeding(
      participants: params.participants,
      strategy: SeedingStrategy.manual,
      constraints: params.constraints,
      bracketFormat: params.bracketFormat,
      randomSeed: params.randomSeed,
      pinnedSeeds: params.pinnedSeeds,
    );
  }

  /// Builds result when all participants are pinned (no re-seeding needed).
  Either<Failure, SeedingResult> _buildPinnedOnlyResult(
    ManualSeedOverrideParams params,
  ) {
    final placements = <ParticipantPlacement>[];
    for (final p in params.participants) {
      final seed = params.pinnedSeeds[p.id];
      if (seed == null) continue;
      placements.add(
        ParticipantPlacement(
          participantId: p.id,
          seedPosition: seed,
          bracketSlot: seed,
        ),
      );
    }

    placements.sort((a, b) => a.seedPosition.compareTo(b.seedPosition));

    // Compute bracket size for constraint validation
    final n = params.participants.length;
    final bracketSize = n <= 1 ? n : 1 << (n - 1).bitLength;

    // Validate constraints
    var violationCount = 0;
    final warnings = <String>[];
    for (final constraint in params.constraints) {
      violationCount += constraint.countViolations(
        placements: placements,
        participants: params.participants,
        bracketSize: bracketSize,
      );
    }

    if (violationCount > 0) {
      warnings.add(
        'All participants are pinned. $violationCount constraint violation(s) '
        'detected. Review pinned positions.',
      );
    }

    return Right(
      SeedingResult(
        placements: placements,
        appliedConstraints: params.constraints.map((c) => c.name).toList(),
        randomSeed: params.randomSeed ?? 0,
        warnings: warnings,
        constraintViolationCount: violationCount,
        isFullySatisfied: violationCount == 0,
      ),
    );
  }
}
```

#### 3. `lib/core/algorithms/seeding/usecases/apply_manual_seed_override_params.dart`

```dart
import 'package:flutter/foundation.dart' show immutable;
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

/// Parameters for the manual seed override use case.
@immutable
class ApplyManualSeedOverrideParams {
  const ApplyManualSeedOverrideParams({
    required this.divisionId,
    required this.participants,
    this.pinnedSeeds = const {},
    this.enableDojangSeparation = true,
    this.dojangMinimumRoundsSeparation = 2,
    this.enableRegionalSeparation = true,
    this.regionalMinimumRoundsSeparation = 1,
    this.bracketFormat = BracketFormat.singleElimination,
    this.randomSeed,
  });

  /// The division ID for context.
  final String divisionId;

  /// All participants with dojang names and optional region names.
  final List<SeedingParticipant> participants;

  /// Map of participantId → fixed seed position.
  final Map<String, int> pinnedSeeds;

  /// Whether to apply dojang separation constraint.
  final bool enableDojangSeparation;

  /// Minimum rounds of separation for same-dojang athletes.
  final int dojangMinimumRoundsSeparation;

  /// Whether to apply regional separation constraint.
  final bool enableRegionalSeparation;

  /// Minimum rounds of separation for same-region athletes.
  final int regionalMinimumRoundsSeparation;

  /// Bracket format affects meeting-round calculations.
  final BracketFormat bracketFormat;

  /// Optional random seed for reproducibility.
  final int? randomSeed;
}
```

#### 4. `lib/core/algorithms/seeding/usecases/apply_manual_seed_override_use_case.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/dojang_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/regional_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/seeding_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/manual_seed_override_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/manual_seed_override_service.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_manual_seed_override_params.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';

/// Use case that applies manual seed override with optional constraint
/// enforcement.
///
/// Validates input, constructs constraint list, and delegates to
/// [ManualSeedOverrideService.reseedAroundPins].
@injectable
class ApplyManualSeedOverrideUseCase
    extends UseCase<SeedingResult, ApplyManualSeedOverrideParams> {
  ApplyManualSeedOverrideUseCase(this._service);

  final ManualSeedOverrideService _service;

  @override
  Future<Either<Failure, SeedingResult>> call(
    ApplyManualSeedOverrideParams params,
  ) async {
    // 1. Validation
    if (params.divisionId.trim().isEmpty) {
      return const Left(
        ValidationFailure(userFriendlyMessage: 'Division ID is required.'),
      );
    }

    if (params.participants.length < 2) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage:
              'At least 2 participants are required for seeding.',
        ),
      );
    }

    if (params.participants.any((p) => p.id.trim().isEmpty)) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Participant list contains empty IDs.',
        ),
      );
    }

    if (params.participants.any((p) => p.dojangName.trim().isEmpty)) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage:
              'All participants must have a dojang name for seeding.',
        ),
      );
    }

    // Check for duplicate participant IDs
    final ids = params.participants.map((p) => p.id).toSet();
    if (ids.length != params.participants.length) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Duplicate participant IDs detected.',
        ),
      );
    }

    // Validate pinned seeds
    if (params.pinnedSeeds.isNotEmpty) {
      // Compute bracket size for validation
      final n = params.participants.length;
      final bracketSize = n <= 1 ? n : 1 << (n - 1).bitLength;

      // Check pin positions are in range
      for (final entry in params.pinnedSeeds.entries) {
        if (entry.value < 1 || entry.value > bracketSize) {
          return Left(
            ValidationFailure(
              userFriendlyMessage:
                  'Pinned seed position ${entry.value} is out of range '
                  '(1-$bracketSize).',
            ),
          );
        }
      }

      // Check for duplicate pin positions
      final pinPositions = params.pinnedSeeds.values.toSet();
      if (pinPositions.length != params.pinnedSeeds.length) {
        return const Left(
          ValidationFailure(
            userFriendlyMessage:
                'Multiple participants pinned to the same seed position.',
          ),
        );
      }

      // Check pinned IDs exist in participant list
      for (final pinnedId in params.pinnedSeeds.keys) {
        if (!ids.contains(pinnedId)) {
          return Left(
            ValidationFailure(
              userFriendlyMessage:
                  'Pinned participant $pinnedId not found in participant list.',
            ),
          );
        }
      }
    }

    // 2. Build constraint list — dojang FIRST (higher priority)
    final constraints = <SeedingConstraint>[];

    if (params.enableDojangSeparation) {
      constraints.add(
        DojangSeparationConstraint(
          minimumRoundsSeparation: params.dojangMinimumRoundsSeparation,
        ),
      );
    }

    if (params.enableRegionalSeparation) {
      constraints.add(
        RegionalSeparationConstraint(
          minimumRoundsSeparation: params.regionalMinimumRoundsSeparation,
        ),
      );
    }

    // 3. Delegate to service
    return _service.reseedAroundPins(
      ManualSeedOverrideParams(
        participants: params.participants,
        pinnedSeeds: params.pinnedSeeds,
        constraints: constraints,
        bracketFormat: params.bracketFormat,
        randomSeed: params.randomSeed,
      ),
    );
  }
}
```

### Scope Boundary: Persistence is Out of Scope

**⚠️ IMPORTANT:** The epics acceptance criteria mentions "changes update `seed_data` JSONB in bracket." This story implements the **domain algorithm layer only** — the pure seeding logic for swap, pin, and re-seed operations.

Persistence of manual seed overrides into the bracket entity's `bracketDataJson` field is the responsibility of the **calling bracket generation feature layer** (a future story or the existing bracket generation use cases). This matches the pattern from Stories 5.7 and 5.8 which also implement pure algorithms without touching the bracket entity.

### Key Differences from Previous Stories

| Aspect              | Story 5.7/5.8 (Auto Seeding)           | **Story 5.9 (Manual Override)**                             |
| ------------------- | -------------------------------------- | ----------------------------------------------------------- |
| User interaction    | Fully automatic                        | **User-driven: swap, pin, re-seed**                         |
| Engine changes      | Created/extended the engine            | **Adds optional `pinnedSeeds` parameter**                   |
| New service layer   | Use cases only                         | **ManualSeedOverrideService + use case**                    |
| Constraint handling | Violations = degraded result           | **Violations = warnings (user informed, not blocked)**      |
| Strategy            | `SeedingStrategy.random`               | **`SeedingStrategy.manual`**                                |
| New files           | Constraint + use case + params + tests | **Service + service params + use case + params + tests**    |
| Modified files      | None / `seeding_participant.dart`      | **`seeding_engine.dart` + `constraint_satisfying_...dart`** |

### Testing Patterns — Complete Test Skeletons

**⚠️ CRITICAL: Follow existing test patterns from Stories 5.7/5.8. Use real `ConstraintSatisfyingSeedingEngine` instances, NOT mocks, for engine tests. Use mocks only for service/use-case tests where you mock the service/engine.**

#### Test File Structure

```
test/core/algorithms/seeding/
├── constraint_satisfying_seeding_engine_pinned_test.dart  ← NEW
├── services/
│   └── manual_seed_override_service_test.dart             ← NEW (create services/ dir)
└── usecases/
    └── apply_manual_seed_override_use_case_test.dart      ← NEW
```

#### 1. Engine Pinned Seeds Test Skeleton

```dart
// test/core/algorithms/seeding/constraint_satisfying_seeding_engine_pinned_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/dojang_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';

void main() {
  late ConstraintSatisfyingSeedingEngine engine;

  setUp(() {
    engine = ConstraintSatisfyingSeedingEngine();
  });

  group('ConstraintSatisfyingSeedingEngine - Pinned Seeds', () {
    test('pinned participants stay at exact fixed positions', () {
      final participants = [
        const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
        const SeedingParticipant(id: 'p2', dojangName: 'Dragon'),
        const SeedingParticipant(id: 'p3', dojangName: 'Eagle'),
        const SeedingParticipant(id: 'p4', dojangName: 'Phoenix'),
      ];

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.manual,
        constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 1)],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
        pinnedSeeds: {'p1': 3, 'p4': 1},  // Pin p1 to seed 3, p4 to seed 1
      );

      expect(result.isRight(), isTrue);
      final seeding = result.getOrElse((_) => throw Exception('unexpected'));
      // Verify pinned positions are exactly as specified
      final p1Placement = seeding.placements.firstWhere(
        (p) => p.participantId == 'p1',
      );
      final p4Placement = seeding.placements.firstWhere(
        (p) => p.participantId == 'p4',
      );
      expect(p1Placement.seedPosition, equals(3));
      expect(p4Placement.seedPosition, equals(1));
    });

    test('no pins — same as regular seeding (backward compat)', () {
      final participants = [
        const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
        const SeedingParticipant(id: 'p2', dojangName: 'Dragon'),
      ];

      final withoutPins = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 1)],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
        // pinnedSeeds: not passed — defaults to null
      );

      final withEmptyPins = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 1)],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
        pinnedSeeds: {},  // Empty map — should behave identically
      );

      expect(withoutPins.isRight(), isTrue);
      expect(withEmptyPins.isRight(), isTrue);
    });

    test('all participants pinned — returns exact positions', () {
      // Engine should place all at their pinned positions
      // and do no backtracking
      // ... test implementation
    });

    test('pinned seed position excluded from unpinned pool', () {
      // Ensure unpinned participants never land on
      // a seed position that's already pinned
      // ... test implementation
    });

    test('performance — 64 participants with pins < 100ms', () {
      final participants = List.generate(
        64,
        (i) => SeedingParticipant(id: 'p$i', dojangName: 'Dojang${i % 8}'),
      );

      final pinnedSeeds = {'p0': 1, 'p7': 8, 'p15': 32};

      final stopwatch = Stopwatch()..start();
      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.manual,
        constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 1)],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
        pinnedSeeds: pinnedSeeds,
      );
      stopwatch.stop();

      expect(result.isRight(), isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
```

#### 2. Service Test Skeleton

```dart
// test/core/algorithms/seeding/services/manual_seed_override_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/dojang_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/manual_seed_override_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/manual_seed_override_service.dart';
import 'package:tkd_brackets/core/error/failures.dart';

// NOTE: Use REAL engine instance, NOT a mock. The engine is a pure algorithm.
void main() {
  late ManualSeedOverrideService service;
  late ConstraintSatisfyingSeedingEngine engine;

  setUp(() {
    engine = ConstraintSatisfyingSeedingEngine();
    service = ManualSeedOverrideService(engine);
  });

  group('swapParticipants', () {
    final participants = [
      const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
      const SeedingParticipant(id: 'p2', dojangName: 'Dragon'),
    ];

    test('swaps two participants — new positions exchanged', () {
      const currentResult = SeedingResult(
        placements: [
          ParticipantPlacement(participantId: 'p1', seedPosition: 1, bracketSlot: 1),
          ParticipantPlacement(participantId: 'p2', seedPosition: 2, bracketSlot: 2),
        ],
        appliedConstraints: ['dojang_separation'],
        randomSeed: 42,
        isFullySatisfied: true,
      );

      final result = service.swapParticipants(
        currentResult: currentResult,
        participantIdA: 'p1',
        participantIdB: 'p2',
        participants: participants,
        constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 1)],
        bracketSize: 2,
      );

      expect(result.isRight(), isTrue);
      final swapped = result.getOrElse((_) => throw Exception('unexpected'));
      final p1 = swapped.placements.firstWhere((p) => p.participantId == 'p1');
      final p2 = swapped.placements.firstWhere((p) => p.participantId == 'p2');
      expect(p1.seedPosition, equals(2));  // Was 1, now 2
      expect(p2.seedPosition, equals(1));  // Was 2, now 1
    });

    test('invalid participant ID — returns ValidationFailure', () {
      // Use participantId that doesn't exist in placements
      // result.fold((failure) => expect(failure, isA<ValidationFailure>()), ...);
    });

    test('same participant for both — returns ValidationFailure', () {
      // participantIdA == participantIdB
    });

    test('swap causing constraint violation — returns Right with warnings', () {
      // Swap same-dojang athletes into adjacent seeds
      // expect(result.isRight(), isTrue);
      // expect(seeding.isFullySatisfied, isFalse);
      // expect(seeding.warnings, isNotEmpty);
      // expect(seeding.constraintViolationCount, greaterThan(0));
    });
  });

  group('pinParticipant', () {
    test('adds participant to pin map', () {
      final result = service.pinParticipant(
        currentPins: const {},
        participantId: 'p1',
        seedPosition: 3,
        bracketSize: 8,
      );

      expect(result.isRight(), isTrue);
      final pins = result.getOrElse((_) => throw Exception('unexpected'));
      expect(pins, equals({'p1': 3}));
    });

    test('empty participantId — returns ValidationFailure', () {
      final result = service.pinParticipant(
        currentPins: const {},
        participantId: '  ',  // Whitespace-only — trimmed to empty
        seedPosition: 1,
        bracketSize: 8,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => throw Exception('unexpected'),
      );
    });

    // ... more pin tests
  });

  group('reseedAroundPins', () {
    test('pinned participants stay fixed, unpinned obey constraints', () {
      // Use ManualSeedOverrideParams with pinnedSeeds
      // Verify pinned positions are exact
      // Verify unpinned positions satisfy constraints
    });

    test('all pinned — returns placements as-is with constraint check', () {
      // params.pinnedSeeds.length >= params.participants.length
      // Should call _buildPinnedOnlyResult
    });

    // Performance test
    test('64 participants with pins — completes in < 100ms', () {
      final participants = List.generate(
        64,
        (i) => SeedingParticipant(
          id: 'p$i',
          dojangName: 'Dojang${i % 8}',
          regionName: 'Region${i % 4}',
        ),
      );

      final pinnedSeeds = {'p0': 1, 'p7': 8, 'p15': 32, 'p31': 64};

      final stopwatch = Stopwatch()..start();
      final result = service.reseedAroundPins(
        ManualSeedOverrideParams(
          participants: participants,
          pinnedSeeds: pinnedSeeds,
          constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 1)],
          bracketFormat: BracketFormat.singleElimination,
          randomSeed: 42,
        ),
      );
      stopwatch.stop();

      expect(result.isRight(), isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
```

#### 3. Use Case Test Skeleton

**⚠️ IMPORTANT: Mock the SERVICE (not the engine) for use case tests. This is different from the 5.7/5.8 pattern where you mock the engine.**

```dart
// test/core/algorithms/seeding/usecases/apply_manual_seed_override_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/dojang_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/regional_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/manual_seed_override_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/manual_seed_override_service.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_manual_seed_override_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_manual_seed_override_use_case.dart';
import 'package:tkd_brackets/core/error/failures.dart';

class MockManualSeedOverrideService extends Mock
    implements ManualSeedOverrideService {}

void main() {
  late MockManualSeedOverrideService mockService;
  late ApplyManualSeedOverrideUseCase useCase;

  // ⚠️ CRITICAL: Register fallback values for types used with `any()`/`captureAny()`
  setUpAll(() {
    registerFallbackValue(
      ManualSeedOverrideParams(
        participants: const [],
        constraints: const [],
      ),
    );
  });

  setUp(() {
    mockService = MockManualSeedOverrideService();
    useCase = ApplyManualSeedOverrideUseCase(mockService);
  });

  group('ApplyManualSeedOverrideUseCase', () {
    const divisionId = 'div1';
    final participants = [
      const SeedingParticipant(id: 'p1', dojangName: 'Tiger', regionName: 'North'),
      const SeedingParticipant(id: 'p2', dojangName: 'Dragon', regionName: 'South'),
    ];

    // --- Validation tests (8 checks) ---
    test('empty divisionId → ValidationFailure', () async {
      final params = ApplyManualSeedOverrideParams(
        divisionId: '',
        participants: participants,
      );

      final result = await useCase(params);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => throw Exception('unexpected'),
      );
    });

    test('< 2 participants → ValidationFailure', () async {
      final params = ApplyManualSeedOverrideParams(
        divisionId: divisionId,
        participants: [participants[0]],
      );

      final result = await useCase(params);
      expect(result.isLeft(), isTrue);
    });

    test('pin position out of range → ValidationFailure', () async {
      final params = ApplyManualSeedOverrideParams(
        divisionId: divisionId,
        participants: participants,
        pinnedSeeds: const {'p1': 99},  // bracketSize = 2, so 99 is out of range
      );

      final result = await useCase(params);
      expect(result.isLeft(), isTrue);
    });

    test('pinned ID not in participant list → ValidationFailure', () async {
      final params = ApplyManualSeedOverrideParams(
        divisionId: divisionId,
        participants: participants,
        pinnedSeeds: const {'nonexistent': 1},
      );

      final result = await useCase(params);
      expect(result.isLeft(), isTrue);
    });

    // ... Add remaining validation tests (empty IDs, empty dojangNames, duplicate IDs, duplicate pins)

    // --- Delegation tests ---
    test('delegates to service with correct ManualSeedOverrideParams', () async {
      final params = ApplyManualSeedOverrideParams(
        divisionId: divisionId,
        participants: participants,
        pinnedSeeds: const {'p1': 1},
        randomSeed: 42,
      );

      const seedingResult = SeedingResult(
        placements: [],
        appliedConstraints: ['dojang_separation', 'regional_separation'],
        isFullySatisfied: true,
        randomSeed: 42,
      );

      when(() => mockService.reseedAroundPins(any()))
          .thenReturn(const Right(seedingResult));

      final result = await useCase(params);

      expect(result.isRight(), isTrue);

      // ⚠️ Verify the captured ManualSeedOverrideParams
      final captured = verify(
        () => mockService.reseedAroundPins(captureAny()),
      ).captured.single as ManualSeedOverrideParams;

      expect(captured.participants, equals(participants));
      expect(captured.pinnedSeeds, equals({'p1': 1}));
      expect(captured.randomSeed, equals(42));
      // Verify constraints: dojang FIRST, then regional (both enabled by default)
      expect(captured.constraints, hasLength(2));
      expect(captured.constraints[0], isA<DojangSeparationConstraint>());
      expect(captured.constraints[1], isA<RegionalSeparationConstraint>());
    });

    test('regional-only when dojang disabled', () async {
      final params = ApplyManualSeedOverrideParams(
        divisionId: divisionId,
        participants: participants,
        enableDojangSeparation: false,
      );

      when(() => mockService.reseedAroundPins(any()))
          .thenReturn(const Right(SeedingResult(
            placements: [],
            appliedConstraints: [],
            isFullySatisfied: true,
            randomSeed: 0,
          )));

      await useCase(params);

      final captured = verify(
        () => mockService.reseedAroundPins(captureAny()),
      ).captured.single as ManualSeedOverrideParams;

      expect(captured.constraints, hasLength(1));
      expect(captured.constraints[0], isA<RegionalSeparationConstraint>());
    });

    test('SeedingFailure propagated from service', () async {
      final params = ApplyManualSeedOverrideParams(
        divisionId: divisionId,
        participants: participants,
      );

      when(() => mockService.reseedAroundPins(any()))
          .thenReturn(const Left(SeedingFailure(
            userFriendlyMessage: 'Engine failed',
          )));

      final result = await useCase(params);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<SeedingFailure>()),
        (_) => throw Exception('unexpected'),
      );
    });
  });
}
```

#### Mocktail Pattern Notes

**`registerFallbackValue` is REQUIRED** for any type used with `any()`, `captureAny()`, or `any(named: 'param')`. Without it, mocktail throws at runtime. The fallback value is only used for matching — it doesn't affect test behavior.

**`const` keyword**: You CANNOT use `const` on `Left(ValidationFailure(...))` when the message contains string interpolation (`$variable`). Use `const` only when all values are compile-time constants. The file skeletons correctly handle this — follow the pattern exactly.

**`getOrElse` pattern**: To extract from `Either`, use `result.getOrElse((_) => throw Exception('unexpected'))` — this is the established pattern in all existing engine tests.

**`result.fold` pattern**: For checking failure type:
```dart
result.fold(
  (failure) => expect(failure, isA<ValidationFailure>()),
  (_) => throw Exception('unexpected'),
);
```

### Previous Story Intelligence (5.8)

**Learnings from Story 5.8 that impact this story:**

1. **`SeedingParticipant` already has `regionName`** — no model changes needed
2. **`ConstraintSatisfyingSeedingEngine` supports multiple constraints natively** — the pinned seeds feature leverages this
3. **`DojangSeparationConstraint.earliestMeetingRound()` is a static method** — reusable by all constraints
4. **The engine's early-exit path** (all same dojang → random shuffle) should still work with pinned seeds — pinned participants in the shuffle are respected
5. **Test patterns**: Use `SeedingParticipant(id: 'p1', dojangName: 'Tiger', regionName: 'North')` with the full constructor
6. **Both constraints in list**: Dojang FIRST, then Regional — same order applies for manual override
7. **`ValidationFailure` is the standard failure type** for input validation — matches `core/error/failures.dart`

### Immutability & Pattern Rules

**⚠️ These are common LLM mistakes — follow exactly:**

1. **`SeedingResult` and `ParticipantPlacement` are `@immutable`** — never mutate. Always create new instances.
2. **`pinParticipant` must return a new `Map`** — `Map<String, int>.from(currentPins)` then modify. Do NOT mutate `currentPins`.
3. **`swapParticipants` must create new `ParticipantPlacement` objects** — `ParticipantPlacement(participantId: ..., seedPosition: ..., bracketSlot: ...)`. Do NOT modify fields on existing placements.
4. **`const` rules**:
   - ✅ Use `const Left(ValidationFailure(userFriendlyMessage: 'Fixed message.'))` when message is a string literal
   - ❌ Cannot use `const Left(ValidationFailure(userFriendlyMessage: 'Position $value is invalid.'))` — string interpolation prevents const
5. **Sync vs Async**:
   - `ManualSeedOverrideService` methods are **synchronous** — return `Either<Failure, T>` directly (not `Future`)
   - `ApplyManualSeedOverrideUseCase.call()` is **async** — returns `Future<Either<Failure, SeedingResult>>` (required by `UseCase` base class). But internally wraps the sync service call directly.
6. **`reseedAroundPins` wrapping**: The use case calls `_service.reseedAroundPins(...)` which returns `Either<Failure, SeedingResult>` (sync). The `async` method just awaits nothing — return the sync result directly. See existing pattern in `ApplyRegionalSeparationSeedingUseCase` line 90: `return _seedingEngine.generateSeeding(...)`.
7. **`bracketSlot` in `ParticipantPlacement`**: The default value for `bracketSlot` is `seedPosition` (from the constructor). When swapping, you MUST explicitly set both `seedPosition` AND `bracketSlot` to the swapped values. Check the `ParticipantPlacement` constructor in `models/participant_placement.dart`.

### Git Intelligence

Recent commits show:
- `s5.8` — Regional separation seeding (latest)
- `s5.7` — Dojang separation seeding algorithm
- `s5.6` — Round robin bracket generator

All follow the same Clean Architecture pattern in `lib/core/algorithms/seeding/`.

### Project Structure Notes

- New files are placed in `lib/core/algorithms/seeding/services/` (new subdirectory) and `lib/core/algorithms/seeding/usecases/` (existing)
- This introduces the first `services/` subdirectory under `seeding/` — create the directory if it doesn't exist
- Test directories mirror source: `test/core/algorithms/seeding/services/` (new) and `test/core/algorithms/seeding/usecases/` (existing)

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Story 5.9 section, lines 1829-1846]
- [Source: `_bmad-output/planning-artifacts/prd.md` — FR29: Manual seed override]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Seeding Algorithm Architecture, lines 1720-1853]
- [Source: `lib/core/algorithms/seeding/seeding_strategy.dart` — `SeedingStrategy.manual` already defined]
- [Source: `lib/core/algorithms/seeding/seeding_engine.dart` — Abstract contract to extend]
- [Source: `lib/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart` — Implementation to modify]
- [Source: `_bmad-output/implementation-artifacts/5-8-regional-separation-seeding.md` — Previous story patterns]
- [Source: `lib/core/algorithms/seeding/usecases/apply_dojang_separation_seeding_use_case.dart` — Use case pattern to follow]

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

- Code review identified 5 MEDIUM and 3 LOW issues; all MEDIUM fixed, 2 LOW fixed (L2 force-unwrap, plus missing tests)
- 4 new test cases added during review: SeedingFailure propagation, both-constraints-enabled, no-pins equivalence, constraint-violation-as-warning

### File List

**Modified Files:**
- `lib/core/algorithms/seeding/seeding_engine.dart` — Added optional `pinnedSeeds` parameter to `generateSeeding()`
- `lib/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart` — Pinned seeds pre-placement, backtracking skip, fallback/random path support

**New Files:**
- `lib/core/algorithms/seeding/services/manual_seed_override_params.dart` — @immutable params class for re-seed operation
- `lib/core/algorithms/seeding/services/manual_seed_override_service.dart` — @injectable service: swap, pin, reseedAroundPins
- `lib/core/algorithms/seeding/usecases/apply_manual_seed_override_params.dart` — @immutable use case params
- `lib/core/algorithms/seeding/usecases/apply_manual_seed_override_use_case.dart` — @injectable use case with 8 validations

**Test Files:**
- `test/core/algorithms/seeding/constraint_satisfying_seeding_engine_pinned_test.dart` — Engine pinned seeds tests (7 tests)
- `test/core/algorithms/seeding/services/manual_seed_override_service_test.dart` — Service tests: swap, pin, reseed (16 tests)
- `test/core/algorithms/seeding/usecases/apply_manual_seed_override_use_case_test.dart` — Use case validation + delegation tests (12 tests)
