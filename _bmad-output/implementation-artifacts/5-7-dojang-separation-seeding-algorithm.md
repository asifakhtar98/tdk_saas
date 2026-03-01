# Story 5.7: Dojang Separation Seeding Algorithm

Status: completed
Assignee: Asak
Story ID: 5.7
<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an organizer,
I want athletes from the same dojang to be seeded apart,
so that teammates don't face each other early in the bracket.

## Acceptance Criteria

1. **Seeding Engine Infrastructure**: A `SeedingEngine` abstract contract exists in `lib/core/algorithms/seeding/seeding_engine.dart` that defines the `generateSeeding()` method signature, accepting participants, strategy, constraints, and bracket format.
2. **Constraint System**: A `SeedingConstraint` abstract base class exists in `lib/core/algorithms/seeding/constraints/seeding_constraint.dart` with `isSatisfied(List<ParticipantPlacement> placements)` and `violationMessage` methods.
3. **Dojang Separation Constraint**: `DojangSeparationConstraint` in `lib/core/algorithms/seeding/constraints/dojang_separation_constraint.dart` validates that same-dojang athletes cannot meet until a specified round (configurable: e.g., semis = 2, quarters = 3). Default: `minimumRoundsSeparation = 2`.
4. **Constraint-Satisfaction Engine**: `ConstraintSatisfyingSeedingEngine` in `lib/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart` implements `SeedingEngine` using backtracking with position swapping.
5. **Graceful Fallback**: If perfect separation is impossible (e.g., too many athletes from one dojang), the engine minimizes early same-dojang matchups and includes a warning in the result rather than failing.
6. **Edge Cases**: The algorithm handles: (a) all athletes from same school → random seeding with notification, (b) 3+ athletes from same school → best-effort, (c) bracket size < constraint window → reduced strictness.
7. **Result Model**: `SeedingResult` contains the ordered list of `ParticipantPlacement` objects (participantId + seedPosition + bracketSlot), applied constraint names, and the random seed used for reproducibility.
8. **Use Case**: `ApplyDojangSeparationSeedingUseCase` takes a `divisionId` and list of participant IDs with their dojang names, runs the seeding engine with the `DojangSeparationConstraint`, and returns `Either<Failure, SeedingResult>`.
9. **Performance**: Seeding generation completes in < 500ms for up to 64 participants (NFR2).
10. **Unit Tests**: Tests verify separation for: 2 dojangs evenly split, 3+ dojangs with varied sizes, single dojang (fallback), impossible constraints (graceful degradation), various bracket sizes (4, 8, 16, 32 participants).

## Tasks / Subtasks

- [x] Task 1: Initialize Seeding Module Models (AC: #1, #2, #3, #6)
    - [x] Create `lib/core/algorithms/seeding/models/participant_placement.dart`
    - [x] Create `lib/core/algorithms/seeding/models/seeding_participant.dart` (Adapter model)
    - [x] Create `lib/core/algorithms/seeding/models/seeding_result.dart`
    - [x] Create `lib/core/algorithms/seeding/seeding_strategy.dart` (Enum)
    - [x] Create `lib/core/algorithms/seeding/bracket_format.dart` (Enum)
- [x] Task 2: Implement Base Seeding Contracts (AC: #4, #8)
    - [x] Create `lib/core/algorithms/seeding/seeding_engine.dart` (Abstract contract)
    - [x] Create `lib/core/algorithms/seeding/constraints/seeding_constraint.dart` (Abstract base class)
- [x] Task 3: Implement DojangSeparationConstraint (AC: #4, #5, #7)
    - [x] Create `lib/core/algorithms/seeding/constraints/dojang_separation_constraint.dart`
    - [x] Implement meeting round calculation using bit-length logic.
- [x] Task 4: Implement ConstraintSatisfyingSeedingEngine (AC: #4, #5, #6)
    - [x] Create `lib/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart`
    - [x] Implement Phase 1: Group participants by dojang
    - [x] Implement Phase 2: Constraint-satisfying slot assignment with backtracking
    - [x] Implement Phase 3: Fallback — minimize violations if perfect satisfaction is impossible
    - [x] Implement edge case: all athletes same dojang → random + notification
    - [x] Implement edge case: bracket size < constraint window → reduced strictness
    - [x] Register with DI: `@LazySingleton(as: SeedingEngine)`
- [x] Task 5: Implement Seeding Use Case (AC: #8, #9)
    - [x] Add `SeedingFailure` to `lib/core/error/failures.dart`
    - [x] Create `lib/core/algorithms/seeding/usecases/apply_dojang_separation_seeding_params.dart`
    - [x] Create `lib/core/algorithms/seeding/usecases/apply_dojang_separation_seeding_use_case.dart`
    - [x] Implement input validation logic.
    - [x] Register with DI: `@injectable`
- [x] Task 6: Testing & Quality Assurance (AC: #10)
    - [x] Write Unit Tests for `DojangSeparationConstraint`
    - [x] Write Unit Tests for `ConstraintSatisfyingSeedingEngine`
    - [x] Write Unit Tests for `ApplyDojangSeparationSeedingUseCase`
    - [x] Run `dart analyze` and ensure zero errors.
    - [x] Run `dart format .`
    - [x] Verify all project tests pass.

## Dev Notes

### Architecture Context

This story creates the **seeding algorithm infrastructure** in `lib/core/algorithms/seeding/`. This is a **core subsystem**, not a feature-level service, because the seeding engine is used across multiple bracket types (single elimination, double elimination, round robin). The architecture explicitly specifies this location.

**⚠️ CRITICAL: This is NOT a bracket feature service.** Unlike Stories 5.4-5.6 which created services in `lib/features/bracket/data/services/`, this story creates a new core algorithm subsystem in `lib/core/algorithms/seeding/`. Do NOT create files in the bracket feature directory.

### DI Registration Pattern

- **Engine**: `@LazySingleton(as: SeedingEngine)` — same pattern as `SingleEliminationBracketGeneratorServiceImplementation` uses `@LazySingleton(as: SingleEliminationBracketGeneratorService)`
- **Use Case**: `@injectable` — same pattern as `GenerateSingleEliminationBracketUseCase`
- **No `register_module.dart` changes needed** — injectable auto-discovers via annotations

### Algorithm: Constraint-Satisfaction with Backtracking

The dojang separation seeding algorithm works as follows:

**Core Concept:** Given N participants with dojang labels, assign seed positions 1..N such that athletes from the same dojang are maximally separated in the bracket tree.

**How bracket tree separation works:** In a single elimination bracket with positions 1..N:
- Seeds 1 and 2 meet in the final (last round)
- Seeds 1&2 vs 3&4 meet in the semifinals
- Seeds {1,2,3,4} vs {5,6,7,8} meet in the quarterfinals
- General rule: seeds in positions `i` and `j` first meet in round `ceil(log2(max(i,j)))` for power-of-2 brackets

**Algorithm Phases:**

1. **Phase 1 — Group:** Group all participants by `schoolOrDojangName` (case-insensitive). Sort groups by size (largest first) for best constraint propagation.

2. **Phase 2 — Assign with Backtracking:**
   - Start with an empty assignment of N positions
   - Place participants from the largest dojang group first
   - For each participant, try each available position
   - Check if placing at this position satisfies the constraint:
     - Would any same-dojang athlete already placed meet this athlete before round `minimumRoundsSeparation`?
   - If constraint violated → try next position (backtrack)
   - If no position works → mark constraint as relaxed, use best-effort position

3. **Phase 3 — Fallback:**
   - If backtracking cannot fully satisfy constraints (e.g., 5 athletes from one dojang in an 8-person bracket), minimize violations
   - Count violations for each candidate arrangement
   - Pick the arrangement with the fewest/latest violations
   - Include `constraintViolations` list and `warnings` in `SeedingResult`

**Meeting Round Calculation (XOR Bit Method):**

For single elimination with bracket size `S` (power of 2), two seeds `a` and `b` (1-indexed) first meet in a specific round determined by their bit representation. This is the **definitive implementation** — use the `int.bitLength` property (Dart built-in) instead of `log()` for precision:

```dart
/// Calculates the earliest round two seeds can meet.
/// Seeds are 1-indexed. bracketSize must be a power of 2.
/// Returns 1 for Round 1, totalRounds for the Final.
static int earliestMeetingRound(
  int seedA,
  int seedB,
  int bracketSize,
  int totalRounds,
) {
  // Convert to 0-indexed
  final a = seedA - 1;
  final b = seedB - 1;
  if (a == b) return 0; // Same position

  final xor = a ^ b;
  // int.bitLength gives position of the highest set bit
  // e.g., 1.bitLength = 1, 2.bitLength = 2, 7.bitLength = 3
  final msb = xor.bitLength;
  return totalRounds - msb + 1;
}
```

**Why XOR works:** Two seeds share a "subgroup" in the bracket tree based on their binary representation. `a ^ b` isolates the bits where they differ. The highest differing bit tells us the round level where their bracket tree paths diverge. Example with 8-person bracket (3 rounds):
- Seeds 1 & 2 (0-indexed: 0 & 1): XOR = `01`, bitLength = 1 → round 3 (final) ✓
- Seeds 1 & 3 (0-indexed: 0 & 2): XOR = `10`, bitLength = 2 → round 2 (semifinal) ✓  
- Seeds 1 & 5 (0-indexed: 0 & 4): XOR = `100`, bitLength = 3 → round 1 ✓

### Participant Data for Seeding

The seeding engine needs participant IDs and their dojang names. Rather than taking full `ParticipantEntity` objects (which would create a dependency from `core` to a feature), the use case should pass lightweight data:

```dart
/// Lightweight participant data for seeding algorithms.
/// This avoids coupling core/algorithms to feature/participant.
class SeedingParticipant {
  const SeedingParticipant({
    required this.id,
    required this.dojangName,
  });
  
  final String id;
  final String dojangName;
}
```

This is placed in `lib/core/algorithms/seeding/models/seeding_participant.dart`.

**⚠️ The architecture spec shows `List<ParticipantEntity>` in the `SeedingEngine` contract. However, to maintain Clean Architecture layer rules (core MUST NOT depend on features), we use `SeedingParticipant` instead. The use case maps `ParticipantEntity` → `SeedingParticipant` before calling the engine.**

### File Skeletons

#### 1. `lib/core/algorithms/seeding/models/participant_placement.dart`

```dart
import 'package:flutter/foundation.dart' show immutable;

/// Represents the assigned position of a participant in a seeded bracket.
@immutable
class ParticipantPlacement {
  const ParticipantPlacement({
    required this.participantId,
    required this.seedPosition,
    this.bracketSlot,
  });

  /// The participant's unique ID.
  final String participantId;

  /// The seed position (1-indexed, 1 = top seed).
  final int seedPosition;

  /// The physical bracket slot position (1-indexed).
  /// May differ from seedPosition if bracket has byes.
  final int? bracketSlot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticipantPlacement &&
          runtimeType == other.runtimeType &&
          participantId == other.participantId &&
          seedPosition == other.seedPosition &&
          bracketSlot == other.bracketSlot;

  @override
  int get hashCode =>
      participantId.hashCode ^ seedPosition.hashCode ^ bracketSlot.hashCode;

  @override
  String toString() =>
      'ParticipantPlacement(id: $participantId, seed: $seedPosition, slot: $bracketSlot)';
}
```

#### 2. `lib/core/algorithms/seeding/models/seeding_participant.dart`

```dart
import 'package:flutter/foundation.dart' show immutable;

/// Lightweight participant data for seeding algorithms.
///
/// This avoids coupling core/algorithms to feature/participant entities.
/// The calling use case maps from ParticipantEntity to this type.
@immutable
class SeedingParticipant {
  const SeedingParticipant({
    required this.id,
    required this.dojangName,
  });

  /// Unique participant ID.
  final String id;

  /// School or dojang name — used for separation constraints.
  final String dojangName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeedingParticipant &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          dojangName == other.dojangName;

  @override
  int get hashCode => id.hashCode ^ dojangName.hashCode;
}
```

#### 3. `lib/core/algorithms/seeding/models/seeding_result.dart`

```dart
import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';

/// The output of a seeding algorithm execution.
@immutable
class SeedingResult {
  const SeedingResult({
    required this.placements,
    required this.appliedConstraints,
    required this.randomSeed,
    this.warnings = const [],
    this.constraintViolationCount = 0,
    this.isFullySatisfied = true,
  });

  /// Ordered list of participant placements (by seed position).
  final List<ParticipantPlacement> placements;

  /// Names of constraints that were applied.
  final List<String> appliedConstraints;

  /// Random seed used for reproducibility.
  final int randomSeed;

  /// Warnings about constraint relaxation or edge cases.
  final List<String> warnings;

  /// Number of constraint violations (0 = perfectly satisfied).
  final int constraintViolationCount;

  /// Whether all constraints were fully satisfied.
  final bool isFullySatisfied;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeedingResult &&
          runtimeType == other.runtimeType &&
          randomSeed == other.randomSeed &&
          constraintViolationCount == other.constraintViolationCount &&
          isFullySatisfied == other.isFullySatisfied &&
          listEquals(placements, other.placements) &&
          listEquals(appliedConstraints, other.appliedConstraints) &&
          listEquals(warnings, other.warnings);

  @override
  int get hashCode =>
      Object.hash(
        randomSeed,
        constraintViolationCount,
        isFullySatisfied,
        Object.hashAll(placements),
        Object.hashAll(appliedConstraints),
      );
}
```

#### 4. `lib/core/algorithms/seeding/seeding_strategy.dart`

```dart
/// Seeding strategy types available for bracket generation.
enum SeedingStrategy {
  /// Random placement with constraint satisfaction.
  random('random'),

  /// Based on external ranking points (imported).
  ranked('ranked'),

  /// Based on historical win rates within the system.
  performanceBased('performance_based'),

  /// User-defined positions with constraint validation.
  manual('manual');

  const SeedingStrategy(this.value);
  final String value;
}
```

#### 5. `lib/core/algorithms/seeding/bracket_format.dart`

```dart
/// Bracket format types that affect seeding calculations.
///
/// The bracket format determines how meeting-round calculations work:
/// - Single elimination: standard binary tree
/// - Double elimination: winners + losers bracket trees
/// - Round robin: all-play-all (separation still relevant for scheduling)
enum BracketFormat {
  singleElimination('single_elimination'),
  doubleElimination('double_elimination'),
  roundRobin('round_robin');

  const BracketFormat(this.value);
  final String value;
}
```

#### 6. `lib/core/algorithms/seeding/seeding_engine.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/seeding_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';
import 'package:tkd_brackets/core/error/failures.dart';

/// Abstract contract for seeding algorithms.
///
/// Implementations generate optimal participant placement for brackets
/// while satisfying separation constraints (dojang, regional, etc.).
abstract class SeedingEngine {
  /// Generates optimal participant placement for a bracket.
  ///
  /// Returns [Left(SeedingFailure)] if a critical error occurs.
  /// Returns [Right(SeedingResult)] on success — even if constraints
  /// could not be fully satisfied (check [SeedingResult.isFullySatisfied]).
  Either<Failure, SeedingResult> generateSeeding({
    required List<SeedingParticipant> participants,
    required SeedingStrategy strategy,
    required List<SeedingConstraint> constraints,
    required BracketFormat bracketFormat,
    int? randomSeed,
  });

  /// Validates that a proposed seeding satisfies all constraints.
  ///
  /// Returns [Left(SeedingFailure)] with violation details if any
  /// constraint is not satisfied.
  /// Returns [Right(unit)] if all constraints are satisfied.
  ///
  /// ⚠️ `participants` is required because `SeedingConstraint.isSatisfied()`
  /// needs participant data (e.g., dojang names) for constraint checks.
  /// `bracketSize` is needed for meeting-round calculations.
  Either<Failure, Unit> validateSeeding({
    required List<ParticipantPlacement> placements,
    required List<SeedingParticipant> participants,
    required List<SeedingConstraint> constraints,
    required BracketFormat bracketFormat,
    required int bracketSize,
  });
}
```

#### 7. `lib/core/algorithms/seeding/constraints/seeding_constraint.dart`

```dart
import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

/// Base class for seeding constraints that the seeding engine must
/// attempt to satisfy.
abstract class SeedingConstraint {
  /// Human-readable name of this constraint.
  String get name;

  /// Checks whether the given placements satisfy this constraint.
  ///
  /// [placements] is the current (possibly partial) list of assignments.
  /// [participants] provides the full participant data (for dojang lookup).
  /// [bracketSize] is the total number of slots in the bracket (power of 2).
  bool isSatisfied({
    required List<ParticipantPlacement> placements,
    required List<SeedingParticipant> participants,
    required int bracketSize,
  });

  /// Returns a human-readable message explaining why the constraint
  /// is violated (used in warnings).
  String get violationMessage;

  /// Counts the number of violations in the given placement.
  /// Used for best-effort fallback scoring.
  int countViolations({
    required List<ParticipantPlacement> placements,
    required List<SeedingParticipant> participants,
    required int bracketSize,
  });
}
```

#### 8. `lib/core/algorithms/seeding/constraints/dojang_separation_constraint.dart`

```dart
import 'package:tkd_brackets/core/algorithms/seeding/constraints/seeding_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

/// Constraint ensuring same-dojang athletes do not meet
/// before a specified round in the bracket.
///
/// [minimumRoundsSeparation] = 2 means same-dojang athletes
/// should not meet in Round 1 or Round 2 (i.e., earliest meeting
/// should be semifinals or later in an 8-person bracket).
class DojangSeparationConstraint extends SeedingConstraint {
  DojangSeparationConstraint({this.minimumRoundsSeparation = 2});

  /// Minimum number of rounds before same-dojang athletes can meet.
  /// Default: 2 (cannot meet in Round 1 or Round 2).
  final int minimumRoundsSeparation;

  @override
  String get name => 'dojang_separation';

  @override
  String get violationMessage =>
      'Same-dojang athletes are meeting before round $minimumRoundsSeparation';

  @override
  bool isSatisfied({
    required List<ParticipantPlacement> placements,
    required List<SeedingParticipant> participants,
    required int bracketSize,
  }) {
    return countViolations(
          placements: placements,
          participants: participants,
          bracketSize: bracketSize,
        ) ==
        0;
  }

  @override
  int countViolations({
    required List<ParticipantPlacement> placements,
    required List<SeedingParticipant> participants,
    required int bracketSize,
  }) {
    // Build a map from participantId to dojang name
    final dojangMap = <String, String>{};
    for (final p in participants) {
      dojangMap[p.id] = p.dojangName.toLowerCase().trim();
    }

    var violations = 0;
    // Use bitLength for integer-precise totalRounds calculation.
    // bracketSize is always power of 2, so (bracketSize-1).bitLength == log2(bracketSize).
    // Example: bracketSize=8 → (7).bitLength = 3 → totalRounds = 3 ✓
    final totalRounds = (bracketSize - 1).bitLength;

    // Check all pairs of placed participants
    for (var i = 0; i < placements.length; i++) {
      for (var j = i + 1; j < placements.length; j++) {
        final a = placements[i];
        final b = placements[j];

        final dojangA = dojangMap[a.participantId];
        final dojangB = dojangMap[b.participantId];

        // Skip if different dojangs
        if (dojangA != dojangB) continue;

        // Calculate earliest meeting round
        final meetingRound = earliestMeetingRound(
          a.seedPosition,
          b.seedPosition,
          bracketSize,
          totalRounds,
        );

        // Violation if they meet before the minimum round
        if (meetingRound <= minimumRoundsSeparation) {
          violations++;
        }
      }
    }

    return violations;
  }

  /// Calculates the earliest round two seeds can meet in a
  /// single elimination bracket.
  ///
  /// Seeds are 1-indexed. bracketSize must be a power of 2.
  /// Returns 1 for Round 1 (first round), totalRounds for the Final.
  ///
  /// Uses XOR + bitLength for O(1) integer-precise calculation.
  /// See algorithm explanation in Dev Notes.
  static int earliestMeetingRound(
    int seedA,
    int seedB,
    int bracketSize,
    int totalRounds,
  ) {
    // Convert to 0-indexed
    final a = seedA - 1;
    final b = seedB - 1;

    if (a == b) return 0; // Same position

    final xor = a ^ b;
    // int.bitLength gives position of the highest set bit
    final msb = xor.bitLength;
    return totalRounds - msb + 1;
  }
}
```

#### 9. `lib/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart`

This file contains the main backtracking algorithm. **The skeleton below includes private helper method signatures that MUST be implemented:**

```dart
import 'dart:math';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/seeding_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';
import 'package:tkd_brackets/core/error/failures.dart';

/// Constraint-satisfying seeding engine using backtracking.
///
/// Attempts to find a participant arrangement that satisfies
/// all constraints. Falls back to best-effort placement when
/// perfect satisfaction is impossible.
@LazySingleton(as: SeedingEngine)
class ConstraintSatisfyingSeedingEngine implements SeedingEngine {
  /// Max backtracking iterations before switching to fallback.
  /// Prevents infinite loops on pathological inputs.
  static const int _maxIterations = 10000;

  @override
  Either<Failure, SeedingResult> generateSeeding({
    required List<SeedingParticipant> participants,
    required SeedingStrategy strategy,
    required List<SeedingConstraint> constraints,
    required BracketFormat bracketFormat,
    int? randomSeed,
  }) {
    final n = participants.length;
    if (n == 0) {
      return const Left(SeedingFailure(
        userFriendlyMessage: 'No participants provided for seeding.',
      ));
    }

    // 1. Compute bracket size (next power of 2 >= n)
    //    Use bitLength for integer precision (no floating-point errors).
    //    Example: n=5 → (5-1).bitLength = 3 → bracketSize = 8
    final bracketSize = n <= 1 ? n : 1 << (n - 1).bitLength;
    final effectiveSeed = randomSeed ?? DateTime.now().microsecondsSinceEpoch;
    final rng = Random(effectiveSeed);

    // 2. Check edge case: all same dojang → shuffle randomly, return with warning
    final uniqueDojangs = participants
        .map((p) => p.dojangName.toLowerCase().trim())
        .toSet();
    if (uniqueDojangs.length <= 1) {
      return _buildRandomResult(
        participants, bracketSize, effectiveSeed, rng, constraints,
        warning: 'All participants are from the same dojang. '
            'Random seeding applied — separation not possible.',
      );
    }

    // 3. Group participants by dojang (case-insensitive, trimmed)
    //    Sort groups largest-first for better constraint propagation.
    final groups = _groupByDojang(participants);

    // 4. Flatten groups into placement order (largest dojang first)
    final ordered = _flattenGroupsLargestFirst(groups, rng);

    // 5. Attempt backtracking placement
    final positions = List<int?>.filled(n, null); // positions[i] = seed for participant i
    final usedSeeds = <int>{}; // track which seed positions (1..bracketSize) are used
    var iterations = 0;

    final success = _backtrack(
      participantIndex: 0,
      ordered: ordered,
      positions: positions,
      usedSeeds: usedSeeds,
      constraints: constraints,
      allParticipants: participants,
      bracketSize: bracketSize,
      iterations: iterations,
      maxIterations: _maxIterations,
    );

    // 6. If backtracking succeeded → build result
    if (success) {
      return _buildResult(
        ordered: ordered,
        positions: positions,
        effectiveSeed: effectiveSeed,
        constraints: constraints,
        participants: participants,
        bracketSize: bracketSize,
        isFullySatisfied: true,
      );
    }

    // 7. Fallback: minimize violations with randomized attempts
    //    Try multiple random permutations, score each by violation count,
    //    keep the one with lowest violations.
    return _fallbackMinimizeViolations(
      participants: participants,
      constraints: constraints,
      bracketSize: bracketSize,
      effectiveSeed: effectiveSeed,
      rng: rng,
    );
  }

  @override
  Either<Failure, Unit> validateSeeding({
    required List<ParticipantPlacement> placements,
    required List<SeedingParticipant> participants,
    required List<SeedingConstraint> constraints,
    required BracketFormat bracketFormat,
    required int bracketSize,
  }) {
    final violatedConstraints = <String>[];
    for (final constraint in constraints) {
      if (!constraint.isSatisfied(
        placements: placements,
        participants: participants,
        bracketSize: bracketSize,
      )) {
        violatedConstraints.add(constraint.name);
      }
    }
    if (violatedConstraints.isNotEmpty) {
      return Left(SeedingFailure(
        userFriendlyMessage: 'Seeding violates constraints: '
            '${violatedConstraints.join(', ')}',
        constraintViolations: violatedConstraints,
      ));
    }
    return const Right(unit);
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIVATE HELPERS — all methods below must be implemented
  // ═══════════════════════════════════════════════════════════════

  /// Groups participants by dojang name (case-insensitive, trimmed).
  /// Returns Map<normalizedDojangName, List<SeedingParticipant>>.
  Map<String, List<SeedingParticipant>> _groupByDojang(
    List<SeedingParticipant> participants,
  ) { /* ... */ }

  /// Flattens grouped participants: largest group first, shuffled within groups.
  /// Returns ordered list to process during backtracking.
  List<SeedingParticipant> _flattenGroupsLargestFirst(
    Map<String, List<SeedingParticipant>> groups,
    Random rng,
  ) { /* ... */ }

  /// Recursive backtracking: tries to place participant at index
  /// [participantIndex] into an available seed position.
  /// Returns true if all participants placed satisfying constraints.
  /// Increments iteration counter; returns false if max exceeded.
  bool _backtrack({
    required int participantIndex,
    required List<SeedingParticipant> ordered,
    required List<int?> positions,
    required Set<int> usedSeeds,
    required List<SeedingConstraint> constraints,
    required List<SeedingParticipant> allParticipants,
    required int bracketSize,
    required int iterations,
    required int maxIterations,
  }) { /* ... */ }

  /// Builds SeedingResult for random fallback (all same dojang case).
  Either<Failure, SeedingResult> _buildRandomResult(
    List<SeedingParticipant> participants,
    int bracketSize,
    int effectiveSeed,
    Random rng,
    List<SeedingConstraint> constraints, {
    required String warning,
  }) { /* ... */ }

  /// Builds final SeedingResult from successful placement.
  Either<Failure, SeedingResult> _buildResult({
    required List<SeedingParticipant> ordered,
    required List<int?> positions,
    required int effectiveSeed,
    required List<SeedingConstraint> constraints,
    required List<SeedingParticipant> participants,
    required int bracketSize,
    required bool isFullySatisfied,
    List<String> warnings = const [],
    int constraintViolationCount = 0,
  }) { /* ... */ }

  /// Fallback: tries N random permutations, scores each by total
  /// constraint violations, returns the best result with warnings.
  Either<Failure, SeedingResult> _fallbackMinimizeViolations({
    required List<SeedingParticipant> participants,
    required List<SeedingConstraint> constraints,
    required int bracketSize,
    required int effectiveSeed,
    required Random rng,
  }) { /* ... */ }
}
```

⚠️ **CRITICAL Implementation Notes:**

1. **BracketSize calculation**: Use `1 << (n - 1).bitLength` for integer precision. Do NOT use `pow(2, (log(n) / ln2).ceil()).toInt()` — floating-point `log` can produce off-by-one errors for exact powers of 2. The `bitLength` approach is used in Dart's own `BigInt` implementation and is always correct.

2. **Deterministic randomness**: Use `Random(randomSeed)` constructor. When `randomSeed` is null, use `DateTime.now().microsecondsSinceEpoch` and store the actual seed in `SeedingResult.randomSeed` for reproducibility.

3. **Max iteration safety**: When `_backtrack` exceeds `_maxIterations`, it returns `false`. This triggers `_fallbackMinimizeViolations()`, NOT a `SeedingFailure`. The fallback tries ~100 random permutations, scores each with `constraint.countViolations()`, and returns the best one with `isFullySatisfied = false` and `warnings` listing the relaxed constraints.

4. **Seed positions are 1-indexed**: `seedPosition = 1` is the top seed. The `ParticipantPlacement.bracketSlot` should equal `seedPosition` for this story (no bye handling needed — that's Story 5.10).

5. **Engine is synchronous**: The `generateSeeding()` method returns `Either` directly (not `Future`). This is correct — it's a pure CPU computation with no I/O. The use case wraps it in `Future` because `UseCase.call()` is async.

#### 10. `lib/core/algorithms/seeding/usecases/apply_dojang_separation_seeding_params.dart`

```dart
import 'package:flutter/foundation.dart' show immutable;
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

/// Parameters for applying dojang separation seeding.
@immutable
class ApplyDojangSeparationSeedingParams {
  const ApplyDojangSeparationSeedingParams({
    required this.divisionId,
    required this.participants,
    this.minimumRoundsSeparation = 2,
    this.bracketFormat = BracketFormat.singleElimination,
    this.randomSeed,
  });

  /// The division ID for context.
  final String divisionId;

  /// Participants with their dojang names.
  final List<SeedingParticipant> participants;

  /// Minimum rounds of separation for same-dojang athletes.
  /// Default: 2 (cannot meet in Round 1 or 2).
  final int minimumRoundsSeparation;

  /// Bracket format affects meeting-round calculations.
  /// Default: singleElimination (most common for TKD tournaments).
  final BracketFormat bracketFormat;

  /// Optional random seed for reproducibility in testing.
  final int? randomSeed;
}
```

#### 11. `lib/core/algorithms/seeding/usecases/apply_dojang_separation_seeding_use_case.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/dojang_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_dojang_separation_seeding_params.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';

/// Use case that applies dojang separation seeding to a set of
/// participants for a division.
///
/// Validates input, constructs the DojangSeparationConstraint,
/// and delegates to the SeedingEngine for the actual algorithm.
@injectable
class ApplyDojangSeparationSeedingUseCase
    extends UseCase<SeedingResult, ApplyDojangSeparationSeedingParams> {
  ApplyDojangSeparationSeedingUseCase(this._seedingEngine);

  final SeedingEngine _seedingEngine;

  @override
  Future<Either<Failure, SeedingResult>> call(
    ApplyDojangSeparationSeedingParams params,
  ) async {
    // 1. Validation — all checks return early with Left(ValidationFailure)
    if (params.divisionId.trim().isEmpty) {
      return const Left(ValidationFailure(
        userFriendlyMessage: 'Division ID is required.',
      ));
    }

    if (params.participants.length < 2) {
      return const Left(ValidationFailure(
        userFriendlyMessage:
            'At least 2 participants are required for seeding.',
      ));
    }

    if (params.participants.any((p) => p.id.trim().isEmpty)) {
      return const Left(ValidationFailure(
        userFriendlyMessage: 'Participant list contains empty IDs.',
      ));
    }

    if (params.participants.any((p) => p.dojangName.trim().isEmpty)) {
      return const Left(ValidationFailure(
        userFriendlyMessage:
            'All participants must have a dojang name for '
            'dojang separation seeding.',
      ));
    }

    // Check for duplicate participant IDs
    final ids = params.participants.map((p) => p.id).toSet();
    if (ids.length != params.participants.length) {
      return const Left(ValidationFailure(
        userFriendlyMessage: 'Duplicate participant IDs detected.',
      ));
    }

    // 2. Create constraint
    final constraint = DojangSeparationConstraint(
      minimumRoundsSeparation: params.minimumRoundsSeparation,
    );

    // 3. Run seeding engine (synchronous — no await needed)
    return _seedingEngine.generateSeeding(
      participants: params.participants,
      strategy: SeedingStrategy.random,
      constraints: [constraint],
      bracketFormat: params.bracketFormat,
      randomSeed: params.randomSeed,
    );
  }
}
```

### SeedingFailure Addition to `lib/core/error/failures.dart`

Add after the existing `BracketGenerationFailure` class:

```diff
 class BracketGenerationFailure extends Failure {
   const BracketGenerationFailure({
     required super.userFriendlyMessage,
     super.technicalDetails,
   });
 }
+
+// ═══════════════════════════════════════════════════════════════════════════
+// Seeding Failures
+// ═══════════════════════════════════════════════════════════════════════════
+
+/// Failure during seeding algorithm execution.
+class SeedingFailure extends Failure {
+  const SeedingFailure({
+    required super.userFriendlyMessage,
+    super.technicalDetails,
+    this.constraintViolations = const [],
+  });
+
+  /// List of constraint names that were violated.
+  final List<String> constraintViolations;
+
+  @override
+  List<Object?> get props => [
+        userFriendlyMessage,
+        technicalDetails,
+        constraintViolations,
+      ];
+}
```

### Key Differences from Previous Stories (5.4-5.6)

| Aspect       | Stories 5.4-5.6 (Bracket Generators)     | **Story 5.7 (Seeding Algorithm)**                   |
| ------------ | ---------------------------------------- | --------------------------------------------------- |
| Location     | `lib/features/bracket/data/services/`    | **`lib/core/algorithms/seeding/`**                  |
| Pattern      | Service Interface → Implementation       | **Engine Interface → Implementation + Constraints** |
| DI           | `@LazySingleton(as: Service)`            | **`@LazySingleton(as: SeedingEngine)`**             |
| Persistence  | Use case persists bracket+matches        | **No persistence — returns SeedingResult only**     |
| Dependencies | Uuid, BracketRepository, MatchRepository | **No repositories — pure algorithm**                |
| Input        | `List<String>` participantIds            | **`List<SeedingParticipant>`**                      |
| Output       | `BracketGenerationResult`                | **`SeedingResult`**                                 |
| Barrel file  | `bracket.dart`                           | **No barrel file needed (core, not feature)**       |

### Testing Patterns

**Engine tests (Task 9)** — No mocks needed (pure algorithm). Direct instantiation:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/dojang_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';

void main() {
  late ConstraintSatisfyingSeedingEngine engine;

  setUp(() {
    engine = ConstraintSatisfyingSeedingEngine();
  });

  /// Helper: creates participants with specified dojang distribution.
  /// Example: {'Tiger': 3, 'Dragon': 5} → 8 participants
  List<SeedingParticipant> makeParticipantsWithDojangs(
    Map<String, int> dojangCounts,
  ) {
    final participants = <SeedingParticipant>[];
    var counter = 1;
    for (final entry in dojangCounts.entries) {
      for (var i = 0; i < entry.value; i++) {
        participants.add(SeedingParticipant(
          id: 'p$counter',
          dojangName: entry.key,
        ));
        counter++;
      }
    }
    return participants;
  }

  /// Helper: verifies that the seeding result satisfies the constraint.
  void verifySeparation(
    List<ParticipantPlacement> placements,
    List<SeedingParticipant> participants,
    int bracketSize,
  ) {
    final constraint = DojangSeparationConstraint();
    expect(
      constraint.isSatisfied(
        placements: placements,
        participants: participants,
        bracketSize: bracketSize,
      ),
      isTrue,
      reason: 'Dojang separation constraint should be satisfied',
    );
  }

  group('ConstraintSatisfyingSeedingEngine', () {
    test('4 participants, 2 dojangs — perfect separation', () {
      final participants = makeParticipantsWithDojangs({
        'Tiger Dojang': 2,
        'Dragon Dojang': 2,
      });

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint()],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42, // deterministic
      );

      expect(result.isRight(), isTrue);
      final seeding = result.getOrElse((_) => throw 'unexpected');
      expect(seeding.placements.length, 4);
      expect(seeding.isFullySatisfied, isTrue);

      // Verify constraint is satisfied on the output
      verifySeparation(seeding.placements, participants, 4);
    });

    test('single dojang — fallback with warning', () {
      final participants = makeParticipantsWithDojangs({
        'Tiger Dojang': 8,
      });

      final result = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint()],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 42,
      );

      expect(result.isRight(), isTrue);
      final seeding = result.getOrElse((_) => throw 'unexpected');
      expect(seeding.placements.length, 8); // all placed
      expect(seeding.isFullySatisfied, isFalse);
      expect(seeding.warnings, isNotEmpty);
    });

    test('deterministic output — same randomSeed same result', () {
      final participants = makeParticipantsWithDojangs({
        'Tiger': 4, 'Dragon': 4,
      });
      final r1 = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint()],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 123,
      );
      final r2 = engine.generateSeeding(
        participants: participants,
        strategy: SeedingStrategy.random,
        constraints: [DojangSeparationConstraint()],
        bracketFormat: BracketFormat.singleElimination,
        randomSeed: 123,
      );
      expect(r1, equals(r2));
    });

    // ... add remaining tests per Task 9 subtasks
  });
}
```

**Use case tests (Task 10)** — Mock `SeedingEngine` with `mocktail`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/dojang_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_dojang_separation_seeding_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_dojang_separation_seeding_use_case.dart';
import 'package:tkd_brackets/core/error/failures.dart';

class MockSeedingEngine extends Mock implements SeedingEngine {}

void main() {
  late MockSeedingEngine mockEngine;
  late ApplyDojangSeparationSeedingUseCase useCase;

  setUp(() {
    mockEngine = MockSeedingEngine();
    useCase = ApplyDojangSeparationSeedingUseCase(mockEngine);
  });

  // Register fallback values for mocktail matchers on types used with `any()`
  setUpAll(() {
    registerFallbackValue(<SeedingParticipant>[]);
    registerFallbackValue(SeedingStrategy.random);
    registerFallbackValue(<DojangSeparationConstraint>[]);
    registerFallbackValue(BracketFormat.singleElimination);
  });

  group('validation', () {
    test('returns ValidationFailure when fewer than 2 participants', () async {
      final result = await useCase.call(
        ApplyDojangSeparationSeedingParams(
          divisionId: 'div-1',
          participants: [const SeedingParticipant(id: 'p1', dojangName: 'Tiger')],
        ),
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Expected Left'),
      );
      // Verify engine was NOT called (validation short-circuits)
      verifyNever(() => mockEngine.generateSeeding(
        participants: any(named: 'participants'),
        strategy: any(named: 'strategy'),
        constraints: any(named: 'constraints'),
        bracketFormat: any(named: 'bracketFormat'),
      ));
    });

    // ... add remaining validation tests per Task 10 subtasks
  });

  group('successful seeding', () {
    test('delegates to engine and returns result', () async {
      final participants = [
        const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
        const SeedingParticipant(id: 'p2', dojangName: 'Dragon'),
      ];
      final expectedResult = SeedingResult(
        placements: [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(participantId: 'p2', seedPosition: 2),
        ],
        appliedConstraints: ['dojang_separation'],
        randomSeed: 42,
      );

      when(() => mockEngine.generateSeeding(
        participants: any(named: 'participants'),
        strategy: any(named: 'strategy'),
        constraints: any(named: 'constraints'),
        bracketFormat: any(named: 'bracketFormat'),
        randomSeed: any(named: 'randomSeed'),
      )).thenReturn(Right(expectedResult));

      final result = await useCase.call(
        ApplyDojangSeparationSeedingParams(
          divisionId: 'div-1',
          participants: participants,
          randomSeed: 42,
        ),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (seeding) => expect(seeding, equals(expectedResult)),
      );
    });
  });
}
```

**Constraint tests (Task 5.3)** — Direct testing of `earliestMeetingRound` and `isSatisfied`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/dojang_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

void main() {
  group('DojangSeparationConstraint', () {
    group('earliestMeetingRound', () {
      // 8-person bracket: 3 rounds
      test('seeds 1 & 2 meet in round 3 (final)', () {
        expect(
          DojangSeparationConstraint.earliestMeetingRound(1, 2, 8, 3),
          3,
        );
      });

      test('seeds 1 & 3 meet in round 2 (semifinal)', () {
        expect(
          DojangSeparationConstraint.earliestMeetingRound(1, 3, 8, 3),
          2,
        );
      });

      test('seeds 1 & 5 meet in round 1 (quarterfinal)', () {
        expect(
          DojangSeparationConstraint.earliestMeetingRound(1, 5, 8, 3),
          1,
        );
      });
    });

    group('isSatisfied', () {
      test('returns true when same-dojang athletes are separated', () {
        final constraint = DojangSeparationConstraint(minimumRoundsSeparation: 2);
        // In 8-person bracket: seeds 1 & 2 meet in round 3 (> 2) ✓
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(participantId: 'p2', seedPosition: 2),
        ];
        final participants = [
          const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
          const SeedingParticipant(id: 'p2', dojangName: 'Tiger'),
        ];
        expect(
          constraint.isSatisfied(
            placements: placements,
            participants: participants,
            bracketSize: 8,
          ),
          isTrue,
        );
      });

      test('returns false when same-dojang athletes meet too early', () {
        final constraint = DojangSeparationConstraint(minimumRoundsSeparation: 2);
        // In 8-person bracket: seeds 1 & 5 meet in round 1 (<= 2) ✗
        final placements = [
          const ParticipantPlacement(participantId: 'p1', seedPosition: 1),
          const ParticipantPlacement(participantId: 'p2', seedPosition: 5),
        ];
        final participants = [
          const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
          const SeedingParticipant(id: 'p2', dojangName: 'Tiger'),
        ];
        expect(
          constraint.isSatisfied(
            placements: placements,
            participants: participants,
            bracketSize: 8,
          ),
          isFalse,
        );
      });
    });
  });
}
```

### ParticipantEntity.schoolOrDojangName

The `ParticipantEntity` already has a `schoolOrDojangName` field (line 37 of `participant_entity.dart`). The use case caller maps this to `SeedingParticipant.dojangName`. **No entity changes needed.**

### Import Pattern

Files in `lib/core/algorithms/seeding/` should use absolute imports:

```dart
import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';
```

NOT relative imports like `import '../models/participant_placement.dart'`.

### Directory Structure (All New Files)

```
lib/core/algorithms/seeding/
├── bracket_format.dart                      # BracketFormat enum
├── constraint_satisfying_seeding_engine.dart # @LazySingleton implementation
├── constraints/
│   ├── dojang_separation_constraint.dart     # DojangSeparationConstraint
│   └── seeding_constraint.dart               # Abstract base class
├── models/
│   ├── participant_placement.dart            # ParticipantPlacement value object
│   ├── seeding_participant.dart              # SeedingParticipant input model
│   └── seeding_result.dart                   # SeedingResult output model
├── seeding_engine.dart                       # Abstract SeedingEngine contract
├── seeding_strategy.dart                     # SeedingStrategy enum
└── usecases/
    ├── apply_dojang_separation_seeding_params.dart    # Params
    └── apply_dojang_separation_seeding_use_case.dart  # @injectable UseCase
```

```
test/core/algorithms/seeding/
├── constraint_satisfying_seeding_engine_test.dart
├── constraints/
│   └── dojang_separation_constraint_test.dart
└── usecases/
    └── apply_dojang_separation_seeding_use_case_test.dart
```

**Files to modify (1 file):**

| #   | File Path                      | Change                     |
| --- | ------------------------------ | -------------------------- |
| 1   | `lib/core/error/failures.dart` | Add `SeedingFailure` class |

**No other files need modification:**
- No `pubspec.yaml` changes (no new dependencies)
- No database schema changes
- No barrel file changes (`bracket.dart`) — seeding is in core, not bracket feature
- No `register_module.dart` changes — injectable auto-discovers annotations
- No structure test changes — structure tests are per-feature, not per-core-module

### Project Structure Notes

- **Location**: `lib/core/algorithms/seeding/` — matches architecture specification exactly
- **Clean Architecture Compliance**: Core algorithms have NO dependencies on feature layers. `SeedingParticipant` is defined in core, preventing import of `ParticipantEntity` from the participant feature.
- **DI Registration**: `@LazySingleton` for engine, `@injectable` for use case — consistent with all prior stories.
- **Naming**: All files use `snake_case`, classes use `PascalCase` per project conventions.

### ⚠️ Common Pitfalls to Avoid

1. **DO NOT import `ParticipantEntity`** in any file under `lib/core/algorithms/seeding/`. This violates Clean Architecture (core→feature dependency). Use `SeedingParticipant` exclusively.

2. **DO NOT create files in `lib/features/bracket/`**. The seeding engine is a core algorithm, not a bracket feature service. All files go in `lib/core/algorithms/seeding/`.

3. **DO NOT use `log()` from `dart:math` for round/size calculations.** Floating-point math produces precision errors for exact powers of 2 (e.g., `log(8)/ln2` can return `2.9999...`). Use `int.bitLength` instead:
   - `totalRounds = (bracketSize - 1).bitLength`
   - `bracketSize = 1 << (n - 1).bitLength`

4. **DO NOT make `generateSeeding()` async.** It is a pure synchronous computation. The `UseCase.call()` wrapper is `async` for API consistency, but the engine itself must be synchronous.

5. **DO NOT create a barrel file** (e.g., `seeding.dart`). Core algorithm modules don't use barrel exports — each file is imported individually with absolute paths.

6. **DO NOT forget to make `SeedingResult.placements` part of `==`/`hashCode`.** Without it, two results with different placements but same random seed compare as equal → false-positive tests.

7. **DO NOT forget `@LazySingleton(as: SeedingEngine)` annotation.** Without it, injectable won't  register the engine and DI will fail at runtime. This is the most commonly missed annotation.

8. **DO NOT use `pow(2, x).toInt()` for bracket size.** `pow()` returns `num`, which loses int precision at large values. Use `1 << x` (bit shift) for power-of-2 calculations.

### Self-Verification Checklist (Run Before Marking Done)

Before marking any task complete, verify:

- [ ] Every file in `lib/core/algorithms/seeding/` uses ONLY absolute imports (`package:tkd_brackets/...`)
- [ ] No file in the seeding directory imports anything from `lib/features/`
- [ ] `SeedingEngine` abstract class has both `generateSeeding()` and `validateSeeding()` methods
- [ ] `ConstraintSatisfyingSeedingEngine` has `@LazySingleton(as: SeedingEngine)` annotation
- [ ] `ApplyDojangSeparationSeedingUseCase` has `@injectable` annotation
- [ ] `SeedingFailure` class is added to `lib/core/error/failures.dart` with proper `props` override
- [ ] All `ParticipantPlacement` objects use 1-indexed `seedPosition`
- [ ] `SeedingResult.==` checks `placements`, `appliedConstraints`, and `warnings` using `listEquals`
- [ ] Engine tests use deterministic `randomSeed` parameter for reproducibility
- [ ] Use case tests verify validation short-circuits (engine not called on invalid input)
- [ ] `dart analyze` returns zero errors AND zero warnings
- [ ] ALL project tests pass (not just new ones)

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 5.7] — Requirements (FR25: dojang separation seeding)
- [Source: _bmad-output/planning-artifacts/prd.md#FR25] — "System applies dojang separation seeding automatically"
- [Source: _bmad-output/planning-artifacts/architecture.md#Seeding Algorithm Architecture] — Contract, directory structure, algorithm approach
- [Source: _bmad-output/planning-artifacts/architecture.md#Clean Architecture Layer Dependency Rules] — Core cannot depend on features
- [Source: _bmad-output/planning-artifacts/architecture.md#Naming Patterns] — File and class naming conventions
- [Source: lib/features/participant/domain/entities/participant_entity.dart#L37] — `schoolOrDojangName` field
- [Source: lib/features/bracket/data/services/single_elimination_bracket_generator_service_implementation.dart] — Power-of-2 bracket size calculation pattern
- [Source: lib/core/usecases/use_case.dart] — Base UseCase class
- [Source: lib/core/error/failures.dart] — Failure hierarchy (ValidationFailure, BracketGenerationFailure)
- [Source: lib/core/di/register_module.dart] — DI module pattern (no changes needed)
- [Source: _bmad-output/implementation-artifacts/5-6-round-robin-bracket-generator.md] — Previous story patterns and learnings
- [Source: test/features/bracket/data/services/single_elimination_bracket_generator_service_implementation_test.dart] — Test pattern reference

## Dev Agent Record

### Agent Model Used

Gemini (Antigravity) — Code Review Pass

### Debug Log References

N/A

### Completion Notes List

- All 11 source files created in `lib/core/algorithms/seeding/`
- `SeedingFailure` added to `lib/core/error/failures.dart`
- 3 test files created in `test/core/algorithms/seeding/`
- DI annotation `@LazySingleton(as: SeedingEngine)` confirmed on `ConstraintSatisfyingSeedingEngine`
- DI annotation `@injectable` confirmed on `ApplyDojangSeparationSeedingUseCase`
- All tests pass (32 tests). `dart analyze` returns 0 issues.

### File List

**New Files:**
| #   | File Path                                                                                  | Purpose                                       |
| --- | ------------------------------------------------------------------------------------------ | --------------------------------------------- |
| 1   | `lib/core/algorithms/seeding/models/participant_placement.dart`                            | ParticipantPlacement value object             |
| 2   | `lib/core/algorithms/seeding/models/seeding_participant.dart`                              | Lightweight participant adapter model         |
| 3   | `lib/core/algorithms/seeding/models/seeding_result.dart`                                   | SeedingResult output model                    |
| 4   | `lib/core/algorithms/seeding/seeding_strategy.dart`                                        | SeedingStrategy enum                          |
| 5   | `lib/core/algorithms/seeding/bracket_format.dart`                                          | BracketFormat enum                            |
| 6   | `lib/core/algorithms/seeding/seeding_engine.dart`                                          | Abstract SeedingEngine contract               |
| 7   | `lib/core/algorithms/seeding/constraints/seeding_constraint.dart`                          | Abstract SeedingConstraint base class         |
| 8   | `lib/core/algorithms/seeding/constraints/dojang_separation_constraint.dart`                | DojangSeparationConstraint with XOR+bitLength |
| 9   | `lib/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart`                    | Backtracking engine implementation            |
| 10  | `lib/core/algorithms/seeding/usecases/apply_dojang_separation_seeding_params.dart`         | Use case params                               |
| 11  | `lib/core/algorithms/seeding/usecases/apply_dojang_separation_seeding_use_case.dart`       | Use case with validation                      |
| 12  | `test/core/algorithms/seeding/constraints/dojang_separation_constraint_test.dart`          | Constraint unit tests                         |
| 13  | `test/core/algorithms/seeding/constraint_satisfying_seeding_engine_test.dart`              | Engine unit tests                             |
| 14  | `test/core/algorithms/seeding/usecases/apply_dojang_separation_seeding_use_case_test.dart` | Use case unit tests                           |

**Modified Files:**
| #   | File Path                      | Change                       |
| --- | ------------------------------ | ---------------------------- |
| 1   | `lib/core/error/failures.dart` | Added `SeedingFailure` class |

## Change Log

| Date       | Change                                                                                                                                                                                                                                                                                             | Author               |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- |
| 2026-03-01 | Story implementation completed — all tasks done                                                                                                                                                                                                                                                    | Dev Agent            |
| 2026-03-01 | Code review: fixed lint (prefer_adjacent_string_concatenation, no_adjacent_strings_in_list), added validateSeeding tests, 0-participant edge case test, default sep=2 test, countViolations tests, verifyNever in use case tests, added _BacktrackContext doc comment. Populated Dev Agent Record. | Antigravity (Review) |
