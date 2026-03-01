# Story 5.10: Bye Assignment Algorithm

Status: completed

## Story

As an organizer,
I want byes to be fairly distributed when participant count is not a power of 2,
so that top-seeded athletes get byes appropriately (FR30).

## Acceptance Criteria

1. **AC1:** `ByeAssignmentService.assignByes()` calculates required byes: `(next_power_of_2) - N`
2. **AC2:** Byes are assigned to top seeds (seed 1 gets first bye, seed 2 second, etc.)
3. **AC3:** Bye positions are distributed across the bracket halves (not clustered in one half) using standard tournament seeding positions
4. **AC4:** `ByeAssignmentResult` includes `byeCount`, `bracketSize`, `totalRounds`, `byePlacements` (List\<ByePlacement>), and `byeSlots` (Set\<int>)
5. **AC5:** When N is already a power of 2, result has `byeCount == 0`, empty `byePlacements`, empty `byeSlots`
6. **AC6:** Performance: bye assignment for 128 participants completes in < 50ms
7. **AC7:** `ApplyByeAssignmentUseCase` validates inputs (divisionId, participant count, IDs, duplicates, bracket format) and delegates to `ByeAssignmentService`
8. **AC8:** Unit tests verify bye distribution for participant counts: 3, 5, 6, 7, 9, 15, 17, 33

## Tasks / Subtasks

- [x] Task 1: Create `ByePlacement` model (AC: #4)
  - [x] 1.1 Create `lib/core/algorithms/seeding/models/bye_placement.dart`
  - [x] 1.2 Immutable class: `participantId` (String?), `seedPosition` (int), `bracketSlot` (int), `byeSlot` (int)
  - [x] 1.3 Manual `==`, `hashCode`, `toString` overrides (no Equatable — match existing model pattern)
- [x] Task 2: Create `ByeAssignmentResult` model (AC: #1, #4, #5)
  - [x] 2.1 Create `lib/core/algorithms/seeding/models/bye_assignment_result.dart`
  - [x] 2.2 Fields: `byeCount` (int), `bracketSize` (int), `totalRounds` (int), `byePlacements` (List\<ByePlacement>), `byeSlots` (Set\<int>)
  - [x] 2.3 Manual `==` using `listEquals` for List and length + containsAll for Set (see model code below)
- [x] Task 3: Create `ByeAssignmentParams` (AC: #1)
  - [x] 3.1 Create `lib/core/algorithms/seeding/services/bye_assignment_params.dart`
  - [x] 3.2 Fields: `participantCount` (int, required), `seedOrder` (List\<String>?, optional)
- [x] Task 4: Create `ByeAssignmentService` — core algorithm (AC: #1, #2, #3, #5, #6)
  - [x] 4.1 Create `lib/core/algorithms/seeding/services/bye_assignment_service.dart`
  - [x] 4.2 `@injectable` with no constructor dependencies (pure algorithm)
  - [x] 4.3 Method: `Either<Failure, ByeAssignmentResult> assignByes(ByeAssignmentParams params)` — synchronous
  - [x] 4.4 Validate: `participantCount < 2` → `Left(ValidationFailure(...))`
  - [x] 4.5 Validate: `seedOrder != null && seedOrder.length != participantCount` → `Left(ValidationFailure(...))`
  - [x] 4.6 Implement `_buildSeedToSlotMap(int bracketSize)` — standard tournament seeding pattern (see algorithm section below)
  - [x] 4.7 Distribute byes by removing lowest virtual seeds from bracket (see worked example below)
- [x] Task 5: Create `ApplyByeAssignmentParams` (AC: #7)
  - [x] 5.1 Create `lib/core/algorithms/seeding/usecases/apply_bye_assignment_params.dart`
  - [x] 5.2 Fields: `divisionId` (String), `participants` (List\<SeedingParticipant>), `bracketFormat` (BracketFormat, default singleElimination)
- [x] Task 6: Create `ApplyByeAssignmentUseCase` (AC: #7)
  - [x] 6.1 Create `lib/core/algorithms/seeding/usecases/apply_bye_assignment_use_case.dart`
  - [x] 6.2 `@injectable`, extends `UseCase<ByeAssignmentResult, ApplyByeAssignmentParams>`
  - [x] 6.3 Constructor injection: `ByeAssignmentService`
  - [x] 6.4 Validation checks (5 checks — see use case section below)
  - [x] 6.5 Delegate to `_service.assignByes(...)` with constructed `ByeAssignmentParams`
- [x] Task 7: Write service tests (AC: #1, #2, #3, #5, #6, #8)
  - [x] 7.1 Create `test/core/algorithms/seeding/services/bye_assignment_service_test.dart`
  - [x] 7.2 Use REAL service instance (no mocks for service tests)
  - [x] 7.3 Minimum 11 test cases (see test skeleton below)
- [x] Task 8: Write use case tests (AC: #7)
  - [x] 8.1 Create `test/core/algorithms/seeding/usecases/apply_bye_assignment_use_case_test.dart`
  - [x] 8.2 Mock `ByeAssignmentService` using `mocktail`
  - [x] 8.3 `registerFallbackValue(const ByeAssignmentParams(participantCount: 2))` in `setUpAll`
  - [x] 8.4 Minimum 7 test cases (5 validation + 2 delegation)
- [x] Task 9: Run analysis and verify all tests pass
  - [x] 9.1 Run `dart analyze` — zero errors, zero warnings
  - [x] 9.2 Run all tests in `test/core/algorithms/seeding/` — all pass

## Dev Notes

### ⚠️ Scope Boundary: Pure Algorithm Only

This story implements the **pure bye assignment algorithm** — determining which seeds get byes and at which bracket positions.

**DO NOT** modify any existing files. The existing bracket generators (`SingleEliminationBracketGeneratorServiceImplementation`) already handle match record creation with `resultType = MatchResultType.bye` and bye advancement. This story creates a **reusable, optimized** algorithm that computes correct bye positions. Future stories may integrate this service into the bracket generators.

**This story is purely additive — 8 new files, 0 modified files.**

### Standard Bye Placement Algorithm

#### Core Concept

In standard tournament seeding (WT, ITF, tennis, boxing):
1. Calculate `bracketSize = nextPowerOf2(participantCount)` using bitLength: `1 << (n - 1).bitLength`
2. Calculate `numByes = bracketSize - participantCount`
3. Top `numByes` seeds receive byes (seed 1 first, seed 2 second, etc.)
4. Byes are placed where the "missing" lowest seeds would have been

The bracket uses **standard seeded positioning** — seed 1 faces the last seed, seed 2 faces second-to-last, etc. Byes appear where the missing lowest-ranked participants would have been placed. This naturally distributes them across the bracket.

#### The `_buildSeedToSlotMap` Algorithm

**⚠️ THIS IS THE ONLY ALGORITHM TO IMPLEMENT. Do NOT create alternative approaches.**

This method returns a `Map<int, int>` mapping each seed number (1-indexed) to its bracket slot (1-indexed).

Standard tournament bracket placement uses a recursive pattern:
- In a 2-slot bracket: seed 1 → slot 1, seed 2 → slot 2
- For larger brackets: interleave top and bottom halves so seed 1 faces seed N, seed 2 faces seed N-1, etc.

```dart
/// Builds a map from seed number (1-indexed) to bracket slot (1-indexed).
///
/// Standard tournament placement ensures:
/// - Seed 1 is at the top, Seed 2 at the bottom
/// - Each half mirrors so top seeds face bottom seeds
///
/// For bracketSize=8:
///   Seed 1 → Slot 1, Seed 8 → Slot 2
///   Seed 5 → Slot 3, Seed 4 → Slot 4
///   Seed 3 → Slot 5, Seed 6 → Slot 6
///   Seed 7 → Slot 7, Seed 2 → Slot 8
Map<int, int> _buildSeedToSlotMap(int bracketSize) {
  // Build the ordered list of seeds as they appear in bracket slots.
  // seedOrder[i] = seed number in slot (i+1).
  final seedOrder = _standardSeedOrder(bracketSize);

  // Invert: seed → slot
  final map = <int, int>{};
  for (var slot = 0; slot < seedOrder.length; slot++) {
    map[seedOrder[slot]] = slot + 1; // 1-indexed slots
  }
  return map;
}

/// Returns the standard seed ordering for bracket slots.
/// Index 0 = slot 1, index 1 = slot 2, etc.
///
/// Base case: bracketSize == 2 → [1, 2]
/// Recursive: for each pair of slots, place seed and its mirror.
List<int> _standardSeedOrder(int bracketSize) {
  if (bracketSize == 2) return [1, 2];

  final half = bracketSize ~/ 2;
  final halfOrder = _standardSeedOrder(half);

  final result = <int>[];
  for (final seed in halfOrder) {
    result.add(seed);                      // Upper half seed
    result.add(bracketSize + 1 - seed);    // Mirror (opponent)
  }
  return result;
}
```

#### Bye Assignment Logic

Once you have the seed-to-slot map:

```dart
Either<Failure, ByeAssignmentResult> assignByes(ByeAssignmentParams params) {
  final n = params.participantCount;

  // Validation
  if (n < 2) {
    return const Left(
      ValidationFailure(
        userFriendlyMessage: 'At least 2 participants required for bye assignment.',
      ),
    );
  }

  if (params.seedOrder != null && params.seedOrder!.length != n) {
    return const Left(
      ValidationFailure(
        userFriendlyMessage: 'Seed order length must match participant count.',
      ),
    );
  }

  // Calculate bracketSize using bitLength (matches seeding engine pattern)
  final totalRounds = (n - 1).bitLength;
  final bracketSize = 1 << totalRounds; // pow(2, totalRounds)
  final numByes = bracketSize - n;

  // Zero byes — return immediately
  if (numByes == 0) {
    return Right(ByeAssignmentResult(
      byeCount: 0,
      bracketSize: bracketSize,
      totalRounds: totalRounds,
      byePlacements: const [],
      byeSlots: const <int>{},  // ← MUST use <int>{} not {} (empty Map vs Set)
    ));
  }

  // Build seed → slot mapping
  final seedToSlot = _buildSeedToSlotMap(bracketSize);
  final byePlacements = <ByePlacement>[];
  final byeSlots = <int>{};

  // Missing seeds are the lowest-ranked: bracketSize, bracketSize-1, etc.
  // Their paired opponent (the top seed getting the bye) is: bracketSize+1 - missingSeed
  for (var byeIdx = 0; byeIdx < numByes; byeIdx++) {
    final missingSeed = bracketSize - byeIdx;           // e.g., 8, 7, 6...
    final byeSlot = seedToSlot[missingSeed]!;            // Where the missing seed WOULD be
    byeSlots.add(byeSlot);

    final pairedSeed = bracketSize + 1 - missingSeed;    // The top seed getting bye (1, 2, 3...)
    final participantSlot = seedToSlot[pairedSeed]!;     // Where the top seed sits

    final participantId = (params.seedOrder != null && byeIdx < params.seedOrder!.length)
        ? params.seedOrder![byeIdx]
        : null;

    byePlacements.add(ByePlacement(
      participantId: participantId,
      seedPosition: pairedSeed,
      bracketSlot: participantSlot,
      byeSlot: byeSlot,
    ));
  }

  return Right(ByeAssignmentResult(
    byeCount: numByes,
    bracketSize: bracketSize,
    totalRounds: totalRounds,
    byePlacements: byePlacements,
    byeSlots: byeSlots,
  ));
}
```

#### Worked Example: 5 Participants in 8-Bracket

```
bracketSize = 8, numByes = 3
totalRounds = 3

Standard seed order for 8 slots:
  Slot 1: Seed 1    Slot 2: Seed 8
  Slot 3: Seed 5    Slot 4: Seed 4
  Slot 5: Seed 3    Slot 6: Seed 6
  Slot 7: Seed 7    Slot 8: Seed 2

seedToSlot map = {1→1, 8→2, 5→3, 4→4, 3→5, 6→6, 7→7, 2→8}

Missing seeds (lowest): 8, 7, 6
  Bye 1: missingSeed=8, byeSlot=2,  pairedSeed=1, participantSlot=1
  Bye 2: missingSeed=7, byeSlot=7,  pairedSeed=2, participantSlot=8
  Bye 3: missingSeed=6, byeSlot=6,  pairedSeed=3, participantSlot=5

Result:
  byeCount = 3
  byeSlots = {2, 7, 6}
  Byes in top half (slots 1-4): slot 2 → 1 bye
  Byes in bottom half (slots 5-8): slots 6, 7 → 2 byes
  ✓ Distributed across halves (not all in one half)

  byePlacements = [
    ByePlacement(seed=1, slot=1, byeSlot=2),  // Seed 1 gets bye
    ByePlacement(seed=2, slot=8, byeSlot=7),  // Seed 2 gets bye
    ByePlacement(seed=3, slot=5, byeSlot=6),  // Seed 3 gets bye
  ]
```

#### Worked Example: 7 Participants in 8-Bracket

```
bracketSize = 8, numByes = 1

Missing seed: 8 → byeSlot = 2
Paired seed: 1 → participantSlot = 1

byePlacements = [ByePlacement(seed=1, slot=1, byeSlot=2)]
byeSlots = {2}
```

### Model Definitions

#### ByePlacement

```dart
// lib/core/algorithms/seeding/models/bye_placement.dart
import 'package:flutter/foundation.dart' show immutable;

/// Represents a single bye assignment: which participant gets a bye
/// and at which bracket position.
@immutable
class ByePlacement {
  /// Creates a [ByePlacement].
  const ByePlacement({
    this.participantId,
    required this.seedPosition,
    required this.bracketSlot,
    required this.byeSlot,
  });

  /// Participant ID receiving the bye. Null if [ByeAssignmentParams.seedOrder]
  /// was not provided.
  final String? participantId;

  /// Seed number of the participant receiving the bye (1 = top seed).
  final int seedPosition;

  /// Bracket slot (1-indexed) where the participant is placed.
  final int bracketSlot;

  /// Bracket slot (1-indexed) that is empty (the bye position).
  /// This slot is paired with [bracketSlot] in Round 1.
  final int byeSlot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ByePlacement &&
          runtimeType == other.runtimeType &&
          participantId == other.participantId &&
          seedPosition == other.seedPosition &&
          bracketSlot == other.bracketSlot &&
          byeSlot == other.byeSlot;

  @override
  int get hashCode =>
      Object.hash(participantId, seedPosition, bracketSlot, byeSlot);

  @override
  String toString() =>
      'ByePlacement(id: $participantId, seed: $seedPosition, '
      'slot: $bracketSlot, byeSlot: $byeSlot)';
}
```

#### ByeAssignmentResult

```dart
// lib/core/algorithms/seeding/models/bye_assignment_result.dart
import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:tkd_brackets/core/algorithms/seeding/models/bye_placement.dart';

/// Result of the bye assignment algorithm.
@immutable
class ByeAssignmentResult {
  /// Creates a [ByeAssignmentResult].
  const ByeAssignmentResult({
    required this.byeCount,
    required this.bracketSize,
    required this.totalRounds,
    required this.byePlacements,
    required this.byeSlots,
  });

  /// Total number of byes in this bracket.
  final int byeCount;

  /// Bracket size (next power of 2 >= participant count).
  final int bracketSize;

  /// Number of rounds in the bracket.
  final int totalRounds;

  /// Ordered list of bye placements (seed 1 first, then seed 2, etc.).
  final List<ByePlacement> byePlacements;

  /// Set of bracket slot numbers (1-indexed) that are bye positions.
  final Set<int> byeSlots;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ByeAssignmentResult &&
          runtimeType == other.runtimeType &&
          byeCount == other.byeCount &&
          bracketSize == other.bracketSize &&
          totalRounds == other.totalRounds &&
          listEquals(byePlacements, other.byePlacements) &&
          byeSlots.length == other.byeSlots.length &&
          byeSlots.containsAll(other.byeSlots);

  @override
  int get hashCode => Object.hash(
        byeCount,
        bracketSize,
        totalRounds,
        Object.hashAll(byePlacements),
        Object.hashAll(byeSlots),
      );

  @override
  String toString() =>
      'ByeAssignmentResult(byes: $byeCount, bracketSize: $bracketSize, '
      'rounds: $totalRounds)';
}
```

**⚠️ Set equality note:** Uses `length + containsAll` instead of `setEquals` because only `listEquals` is confirmed in the existing codebase's `foundation.dart` imports. This avoids potential import issues.

#### ByeAssignmentParams

```dart
// lib/core/algorithms/seeding/services/bye_assignment_params.dart
import 'package:flutter/foundation.dart' show immutable;

/// Parameters for the bye assignment algorithm.
@immutable
class ByeAssignmentParams {
  /// Creates [ByeAssignmentParams].
  ///
  /// [participantCount] must be >= 2.
  /// [seedOrder] if provided, must have length == [participantCount].
  const ByeAssignmentParams({
    required this.participantCount,
    this.seedOrder,
  });

  /// Total number of actual participants.
  final int participantCount;

  /// Optional ordered list of participant IDs, highest seed first.
  /// If provided, [ByePlacement.participantId] will be populated.
  /// Length MUST equal [participantCount] when provided.
  final List<String>? seedOrder;
}
```

#### ApplyByeAssignmentParams

```dart
// lib/core/algorithms/seeding/usecases/apply_bye_assignment_params.dart
import 'package:flutter/foundation.dart' show immutable;
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

/// Parameters for [ApplyByeAssignmentUseCase].
@immutable
class ApplyByeAssignmentParams {
  /// Creates [ApplyByeAssignmentParams].
  const ApplyByeAssignmentParams({
    required this.divisionId,
    required this.participants,
    this.bracketFormat = BracketFormat.singleElimination,
  });

  /// Division ID this bye assignment is for.
  final String divisionId;

  /// Participants in seed order (index 0 = top seed).
  final List<SeedingParticipant> participants;

  /// Bracket format. Must be singleElimination or doubleElimination.
  /// Round robin does not use byes.
  final BracketFormat bracketFormat;
}
```

### Use Case Implementation — Exact Pattern

Follow `ApplyDojangSeparationSeedingUseCase` (source: `lib/core/algorithms/seeding/usecases/apply_dojang_separation_seeding_use_case.dart`).

```dart
// lib/core/algorithms/seeding/usecases/apply_bye_assignment_use_case.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/bye_assignment_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/bye_assignment_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/bye_assignment_service.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_bye_assignment_params.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';

/// Use case that validates inputs and delegates to [ByeAssignmentService].
@injectable
class ApplyByeAssignmentUseCase
    extends UseCase<ByeAssignmentResult, ApplyByeAssignmentParams> {
  ApplyByeAssignmentUseCase(this._service);

  final ByeAssignmentService _service;

  @override
  Future<Either<Failure, ByeAssignmentResult>> call(
    ApplyByeAssignmentParams params,
  ) async {
    // 1. Validate divisionId
    if (params.divisionId.trim().isEmpty) {
      return const Left(
        ValidationFailure(userFriendlyMessage: 'Division ID is required.'),
      );
    }

    // 2. Validate minimum participants
    if (params.participants.length < 2) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage:
              'At least 2 participants are required for bye assignment.',
        ),
      );
    }

    // 3. Validate no empty participant IDs
    if (params.participants.any((p) => p.id.trim().isEmpty)) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Participant list contains empty IDs.',
        ),
      );
    }

    // 4. Validate no duplicate participant IDs
    final ids = params.participants.map((p) => p.id).toSet();
    if (ids.length != params.participants.length) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Duplicate participant IDs detected.',
        ),
      );
    }

    // 5. Validate bracket format (roundRobin has no byes)
    if (params.bracketFormat == BracketFormat.roundRobin) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage:
              'Round robin format does not support bye assignment.',
        ),
      );
    }

    // 6. Delegate to service
    return _service.assignByes(
      ByeAssignmentParams(
        participantCount: params.participants.length,
        seedOrder: params.participants.map((p) => p.id).toList(),
      ),
    );
  }
}
```

### Service Implementation — Complete Pattern

```dart
// lib/core/algorithms/seeding/services/bye_assignment_service.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/bye_assignment_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/bye_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/bye_assignment_params.dart';
import 'package:tkd_brackets/core/error/failures.dart';

/// Pure algorithm service for determining optimal bye positions
/// in elimination brackets.
///
/// Uses standard tournament seeding positions to distribute byes
/// across the bracket, ensuring top seeds receive byes and
/// bye positions are not clustered in one half.
@injectable
class ByeAssignmentService {
  /// Computes bye assignments for the given parameters.
  ///
  /// Returns [Right] with [ByeAssignmentResult] on success.
  /// Returns [Left] with [ValidationFailure] if params are invalid.
  ///
  /// This is a **synchronous** operation — no async needed.
  Either<Failure, ByeAssignmentResult> assignByes(
    ByeAssignmentParams params,
  ) {
    // ... full implementation from algorithm section above
    // See "Bye Assignment Logic" code block
  }

  /// Builds a map from seed number (1-indexed) to bracket slot (1-indexed).
  /// Uses standard tournament seeding pattern.
  Map<int, int> _buildSeedToSlotMap(int bracketSize) {
    // ... see "_buildSeedToSlotMap Algorithm" code block above
  }

  /// Returns standard seed ordering for bracket slots.
  /// Recursive: base case [1, 2], then interleave with mirrors.
  List<int> _standardSeedOrder(int bracketSize) {
    // ... see "_standardSeedOrder" code block above
  }
}
```

### Testing Patterns

**⚠️ CRITICAL rules from Stories 5.7-5.9:**
- Service tests: use **REAL** service instances — NO mocks
- Use case tests: **MOCK** the service using `mocktail`
- `registerFallbackValue` required in `setUpAll` for `any()`/`captureAny()`
- Extract result with `result.getOrElse((_) => throw Exception('unexpected'))`
- Check failure with `result.fold((f) => expect(f, isA<ValidationFailure>()), ...)`

#### Service Test Skeleton

```dart
// test/core/algorithms/seeding/services/bye_assignment_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/bye_assignment_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/bye_assignment_service.dart';
import 'package:tkd_brackets/core/error/failures.dart';

void main() {
  late ByeAssignmentService service;

  setUp(() {
    service = ByeAssignmentService();
  });

  ByeAssignmentResult _extract(Either result) =>
      result.getOrElse((_) => throw Exception('Expected Right, got Left'));

  group('ByeAssignmentService', () {
    group('validation', () {
      test('0 participants → Left(ValidationFailure)', () {
        final result = service.assignByes(
          const ByeAssignmentParams(participantCount: 0),
        );
        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<ValidationFailure>()),
          (_) => throw Exception('unexpected'),
        );
      });

      test('1 participant → Left(ValidationFailure)', () {
        final result = service.assignByes(
          const ByeAssignmentParams(participantCount: 1),
        );
        expect(result.isLeft(), isTrue);
      });

      test('seedOrder length mismatch → Left(ValidationFailure)', () {
        final result = service.assignByes(
          const ByeAssignmentParams(
            participantCount: 3,
            seedOrder: ['a', 'b'], // length 2 != 3
          ),
        );
        expect(result.isLeft(), isTrue);
      });
    });

    group('zero byes (power of 2)', () {
      test('2 participants → 0 byes, bracketSize 2', () {
        final r = _extract(service.assignByes(
          const ByeAssignmentParams(participantCount: 2),
        ));
        expect(r.byeCount, equals(0));
        expect(r.bracketSize, equals(2));
        expect(r.totalRounds, equals(1));
        expect(r.byePlacements, isEmpty);
        expect(r.byeSlots, isEmpty);
      });

      test('8 participants → 0 byes, bracketSize 8', () {
        final r = _extract(service.assignByes(
          const ByeAssignmentParams(participantCount: 8),
        ));
        expect(r.byeCount, equals(0));
        expect(r.bracketSize, equals(8));
        expect(r.totalRounds, equals(3));
        expect(r.byePlacements, isEmpty);
        expect(r.byeSlots, isEmpty);
      });
    });

    group('bye distribution', () {
      test('3 participants → 1 bye, seed 1 gets bye', () {
        final r = _extract(service.assignByes(
          const ByeAssignmentParams(participantCount: 3),
        ));
        expect(r.byeCount, equals(1));
        expect(r.bracketSize, equals(4));
        expect(r.totalRounds, equals(2));
        expect(r.byePlacements, hasLength(1));
        expect(r.byePlacements[0].seedPosition, equals(1));
      });

      test('5 participants → 3 byes distributed across halves', () {
        final r = _extract(service.assignByes(
          const ByeAssignmentParams(participantCount: 5),
        ));
        expect(r.byeCount, equals(3));
        expect(r.bracketSize, equals(8));
        // Verify distribution: byes should appear in multiple quarters
        final topHalf = r.byeSlots.where((s) => s <= 4).length;
        final bottomHalf = r.byeSlots.where((s) => s > 4).length;
        expect(topHalf, greaterThan(0), reason: 'At least 1 bye in top half');
        expect(bottomHalf, greaterThan(0), reason: 'At least 1 bye in bottom half');
      });

      test('7 participants → 1 bye', () {
        final r = _extract(service.assignByes(
          const ByeAssignmentParams(participantCount: 7),
        ));
        expect(r.byeCount, equals(1));
        expect(r.bracketSize, equals(8));
        expect(r.byePlacements[0].seedPosition, equals(1));
      });

      test('all bye seeds are top seeds (1, 2, 3, ...)', () {
        final r = _extract(service.assignByes(
          const ByeAssignmentParams(participantCount: 5),
        ));
        final seeds = r.byePlacements.map((p) => p.seedPosition).toList()..sort();
        expect(seeds, equals([1, 2, 3]));
      });
    });

    group('invariants for all sizes', () {
      test('bye slots and participant slots never overlap', () {
        for (final n in [3, 5, 6, 7, 9, 15, 17, 33]) {
          final r = _extract(service.assignByes(
            ByeAssignmentParams(participantCount: n),
          ));
          for (final p in r.byePlacements) {
            expect(p.bracketSlot, isNot(equals(p.byeSlot)),
                reason: 'n=$n: participant slot and bye slot must differ');
            expect(r.byeSlots.contains(p.byeSlot), isTrue,
                reason: 'n=$n: byeSlot must be in byeSlots set');
            expect(r.byeSlots.contains(p.bracketSlot), isFalse,
                reason: 'n=$n: participant slot must NOT be a bye slot');
          }
          // Verify byeCount matches
          expect(r.byeCount, equals(r.byePlacements.length),
              reason: 'n=$n: byeCount must equal byePlacements length');
          expect(r.byeCount, equals(r.byeSlots.length),
              reason: 'n=$n: byeCount must equal byeSlots size');
        }
      });
    });

    group('seedOrder', () {
      test('with seedOrder → participantIds populated', () {
        final r = _extract(service.assignByes(
          const ByeAssignmentParams(
            participantCount: 3,
            seedOrder: ['alice', 'bob', 'charlie'],
          ),
        ));
        expect(r.byePlacements[0].participantId, equals('alice'));
        expect(r.byePlacements[0].seedPosition, equals(1));
      });

      test('without seedOrder → participantIds null', () {
        final r = _extract(service.assignByes(
          const ByeAssignmentParams(participantCount: 3),
        ));
        expect(r.byePlacements[0].participantId, isNull);
      });
    });

    group('performance', () {
      test('128 participants completes in < 50ms', () {
        final sw = Stopwatch()..start();
        final result = service.assignByes(
          const ByeAssignmentParams(participantCount: 128),
        );
        sw.stop();
        expect(result.isRight(), isTrue);
        expect(sw.elapsedMilliseconds, lessThan(50));
      });
    });
  });
}
```

#### Use Case Test Skeleton

```dart
// test/core/algorithms/seeding/usecases/apply_bye_assignment_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/bye_assignment_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/bye_assignment_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/bye_assignment_service.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_bye_assignment_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_bye_assignment_use_case.dart';
import 'package:tkd_brackets/core/error/failures.dart';

class MockByeAssignmentService extends Mock implements ByeAssignmentService {}

void main() {
  late MockByeAssignmentService mockService;
  late ApplyByeAssignmentUseCase useCase;

  setUpAll(() {
    registerFallbackValue(const ByeAssignmentParams(participantCount: 2));
  });

  setUp(() {
    mockService = MockByeAssignmentService();
    useCase = ApplyByeAssignmentUseCase(mockService);
  });

  // Reusable test participants
  final participants = [
    const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
    const SeedingParticipant(id: 'p2', dojangName: 'Dragon'),
    const SeedingParticipant(id: 'p3', dojangName: 'Eagle'),
  ];

  group('Validation (no service calls)', () {
    test('empty divisionId → ValidationFailure', () async {
      final result = await useCase(ApplyByeAssignmentParams(
        divisionId: '',
        participants: participants,
      ));
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => throw Exception('unexpected'),
      );
      verifyNever(() => mockService.assignByes(any()));
    });

    test('< 2 participants → ValidationFailure', () async {
      final result = await useCase(ApplyByeAssignmentParams(
        divisionId: 'div1',
        participants: [
          const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
        ],
      ));
      expect(result.isLeft(), isTrue);
      verifyNever(() => mockService.assignByes(any()));
    });

    test('empty participant IDs → ValidationFailure', () async {
      final result = await useCase(ApplyByeAssignmentParams(
        divisionId: 'div1',
        participants: [
          const SeedingParticipant(id: '', dojangName: 'Tiger'),
          const SeedingParticipant(id: 'p2', dojangName: 'Dragon'),
        ],
      ));
      expect(result.isLeft(), isTrue);
      verifyNever(() => mockService.assignByes(any()));
    });

    test('duplicate participant IDs → ValidationFailure', () async {
      final result = await useCase(ApplyByeAssignmentParams(
        divisionId: 'div1',
        participants: [
          const SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
          const SeedingParticipant(id: 'p1', dojangName: 'Dragon'),
        ],
      ));
      expect(result.isLeft(), isTrue);
      verifyNever(() => mockService.assignByes(any()));
    });

    test('roundRobin format → ValidationFailure', () async {
      final result = await useCase(ApplyByeAssignmentParams(
        divisionId: 'div1',
        participants: participants,
        bracketFormat: BracketFormat.roundRobin,
      ));
      expect(result.isLeft(), isTrue);
      verifyNever(() => mockService.assignByes(any()));
    });
  });

  group('Delegation', () {
    test('valid params → delegates to service with correct ByeAssignmentParams', () async {
      const byeResult = ByeAssignmentResult(
        byeCount: 1,
        bracketSize: 4,
        totalRounds: 2,
        byePlacements: [],
        byeSlots: <int>{},  // ← explicit <int>{} for Set
      );
      when(() => mockService.assignByes(any()))
          .thenReturn(const Right(byeResult));

      final result = await useCase(ApplyByeAssignmentParams(
        divisionId: 'div1',
        participants: participants,
      ));

      expect(result.isRight(), isTrue);
      final captured = verify(() => mockService.assignByes(captureAny()))
          .captured
          .single as ByeAssignmentParams;
      expect(captured.participantCount, equals(3));
      expect(captured.seedOrder, equals(['p1', 'p2', 'p3']));
    });

    test('service failure is propagated', () async {
      when(() => mockService.assignByes(any())).thenReturn(
        const Left(ValidationFailure(userFriendlyMessage: 'Too few')),
      );

      final result = await useCase(ApplyByeAssignmentParams(
        divisionId: 'div1',
        participants: participants,
      ));
      expect(result.isLeft(), isTrue);
    });
  });
}
```

### ⚠️ Common LLM Mistakes — Prevention Rules

| #   | Mistake                                                       | Correct Approach                                                                                |
| --- | ------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| 1   | Using `const {}` for empty `Set<int>`                         | Use `const <int>{}` — bare `{}` creates an empty `Map`, not `Set`                               |
| 2   | Importing `package:meta/meta.dart`                            | Use `package:flutter/foundation.dart` show `immutable`                                          |
| 3   | Making `assignByes()` async                                   | It is **sync** — returns `Either` directly, NOT `Future`                                        |
| 4   | Using `@LazySingleton` on service                             | Use `@injectable` (no state to cache)                                                           |
| 5   | Adding `SeedingEngine` dependency                             | `ByeAssignmentService` is a **pure algorithm** — zero dependencies                              |
| 6   | Using `const Left(ValidationFailure(...))` with interpolation | `const` only works with literal strings — use `Left(ValidationFailure(...))` when interpolating |
| 7   | Using `Equatable` on new models                               | Existing models use manual `==`/`hashCode` — follow same pattern                                |
| 8   | Forgetting `registerFallbackValue` in UC tests                | Required for `any()`/`captureAny()` with mocktail                                               |
| 9   | Mocking the service in service tests                          | Service tests use **REAL** instances — only UC tests mock                                       |
| 10  | `setEquals` import                                            | Use `length + containsAll` for Set equality instead                                             |

### Key Differences from Previous Stories

| Aspect         | Stories 5.7-5.8 (Constraints) | Story 5.9 (Manual Override) | **Story 5.10 (Bye Assignment)** |
| -------------- | ----------------------------- | --------------------------- | ------------------------------- |
| Purpose        | Seeding separation            | User overrides              | **Bye position optimization**   |
| New constraint | DojangSeparation / Regional   | None                        | **None (not a constraint)**     |
| New service    | None                          | ManualSeedOverrideService   | **ByeAssignmentService**        |
| Service deps   | N/A                           | SeedingEngine               | **None (pure algorithm)**       |
| Engine changes | Created/extended              | Added pinnedSeeds           | **None**                        |
| Output type    | SeedingResult                 | SeedingResult               | **ByeAssignmentResult (NEW)**   |
| Sync/Async     | Sync                          | Sync service, async UC      | **Sync service, async UC**      |

### Performance Notes

- `bracketSize` calculation uses `int.bitLength` — O(1), same pattern as Stories 5.7/5.8
- `_standardSeedOrder` is O(bracketSize) — computed once per call
- `_buildSeedToSlotMap` is O(bracketSize) — computed once per call
- Total algorithm complexity: **O(bracketSize)** — well within 50ms for 128+ participants

### Previous Story Intelligence

Learnings from Stories 5.7-5.9 that impact this story:

1. **Service pattern**: `ByeAssignmentService` follows `ManualSeedOverrideService` pattern — `@injectable`, sync method, `Either<Failure, T>` return
2. **`services/` directory exists**: `lib/core/algorithms/seeding/services/` was created in Story 5.9 — reuse it
3. **Test pattern**: Use REAL service instances for service tests. Mock service for UC tests
4. **`registerFallbackValue` required** for `any()`/`captureAny()` in mocktail
5. **Bracket size calculation**: Use `1 << (n - 1).bitLength` — established pattern from `ConstraintSatisfyingSeedingEngine` line 45

### Git Intelligence

Recent commits on the seeding algorithm:
- `b578d00` — Story 5.9 (Manual seed override)
- `eed1a0a` — Story 5.8 (Regional separation seeding)
- `08a798c` — Story 5.7 (Dojang separation seeding algorithm)

All follow Clean Architecture pattern in `lib/core/algorithms/seeding/`.

### Project Structure Notes

**New Files (8 total):**
```
lib/core/algorithms/seeding/
├── models/
│   ├── bye_placement.dart              ← NEW
│   └── bye_assignment_result.dart      ← NEW
├── services/
│   ├── bye_assignment_params.dart      ← NEW (alongside existing manual_seed_override_params.dart)
│   └── bye_assignment_service.dart     ← NEW (alongside existing manual_seed_override_service.dart)
└── usecases/
    ├── apply_bye_assignment_params.dart ← NEW
    └── apply_bye_assignment_use_case.dart ← NEW

test/core/algorithms/seeding/
├── services/
│   └── bye_assignment_service_test.dart ← NEW
└── usecases/
    └── apply_bye_assignment_use_case_test.dart ← NEW
```

**Existing directories (all exist — no need to create):**
- `lib/core/algorithms/seeding/models/` — has `participant_placement.dart`, `seeding_participant.dart`, `seeding_result.dart`
- `lib/core/algorithms/seeding/services/` — has `manual_seed_override_params.dart`, `manual_seed_override_service.dart`
- `lib/core/algorithms/seeding/usecases/` — has `apply_dojang_separation_seeding_*`
- `test/core/algorithms/seeding/services/` — has existing test files
- `test/core/algorithms/seeding/usecases/` — has existing test files

**No modified files** — this story is purely additive.

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Story 5.10 section, lines 1849-1865]
- [Source: `_bmad-output/planning-artifacts/prd.md` — FR30: Bye optimization, line 894]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — ByeOptimizationConstraint section, line 1777; Phase 3 Bye Placement, line 1813]
- [Source: `lib/features/bracket/data/services/single_elimination_bracket_generator_service_implementation.dart` — Existing naive bye logic, lines 104-130]
- [Source: `lib/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart` — bracketSize calculation pattern, line 45]
- [Source: `lib/core/algorithms/seeding/services/manual_seed_override_service.dart` — Service pattern to follow]
- [Source: `lib/core/algorithms/seeding/services/manual_seed_override_params.dart` — Params pattern to follow]
- [Source: `lib/core/algorithms/seeding/usecases/apply_dojang_separation_seeding_use_case.dart` — Use case pattern to follow]
- [Source: `lib/core/usecases/use_case.dart` — UseCase base class definition]
- [Source: `lib/core/error/failures.dart` — ValidationFailure class, lines 90-105]

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

- All 9 tasks implemented and verified
- 0 analysis errors, 20/20 tests passing
- Purely additive: 8 new files, 0 modified files
- Code review: 2026-03-01

### File List

- `lib/core/algorithms/seeding/models/bye_placement.dart` — NEW
- `lib/core/algorithms/seeding/models/bye_assignment_result.dart` — NEW
- `lib/core/algorithms/seeding/services/bye_assignment_params.dart` — NEW
- `lib/core/algorithms/seeding/services/bye_assignment_service.dart` — NEW
- `lib/core/algorithms/seeding/usecases/apply_bye_assignment_params.dart` — NEW
- `lib/core/algorithms/seeding/usecases/apply_bye_assignment_use_case.dart` — NEW
- `test/core/algorithms/seeding/services/bye_assignment_service_test.dart` — NEW
- `test/core/algorithms/seeding/usecases/apply_bye_assignment_use_case_test.dart` — NEW
