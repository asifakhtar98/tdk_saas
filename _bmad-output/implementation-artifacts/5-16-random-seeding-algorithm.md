# Story 5.16: Random Seeding Algorithm (Cryptographic Fairness)

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an organizer,
I want to apply a cryptographically fair random seeding to a bracket,
so that seeding is unbiased and verifiably fair (FR27).

## Acceptance Criteria

1. **AC1:** `ApplyRandomSeedingParams` exists at `lib/core/algorithms/seeding/usecases/apply_random_seeding_params.dart` with fields: `divisionId` (String), `participants` (List\<SeedingParticipant\>), `bracketFormat` (BracketFormat, default `singleElimination`), `randomSeed` (int?, optional — for reproducibility/testing). Follows the exact same PODO pattern as `ApplyDojangSeparationSeedingParams`.
2. **AC2:** `ApplyRandomSeedingUseCase` exists at `lib/core/algorithms/seeding/usecases/apply_random_seeding_use_case.dart`. It extends `UseCase<SeedingResult, ApplyRandomSeedingParams>`, is annotated `@injectable`, validates inputs, generates a cryptographically secure seed via `Random.secure().nextInt(1 << 31)` when `params.randomSeed` is null, passes an **empty constraints list** to `SeedingEngine.generateSeeding()`, and uses `SeedingStrategy.random`.
3. **AC3:** The generated `randomSeed` is stored in the returned `SeedingResult.randomSeed` field — the existing engine already does this. Re-supplying that same seed value to the use case reproduces the exact same bracket ordering.
4. **AC4:** Input validation matches the pattern of `ApplyDojangSeparationSeedingUseCase`: empty `divisionId` → `ValidationFailure`; `< 2 participants` → `ValidationFailure`; empty participant ID → `ValidationFailure`; duplicate participant IDs → `ValidationFailure`.
5. **AC5:** Unit tests for `ApplyRandomSeedingUseCase` verify: correct delegation to `SeedingEngine` with empty constraints and `SeedingStrategy.random`; all four validation failures (empty divisionId, < 2 participants, empty ID, duplicates); `SeedingEngine` error propagation; that when `randomSeed` is null, a secure seed is generated and passed to the engine.
6. **AC6:** An integration-level test verifies reproducibility: calling the use case twice with the same seed produces identical `SeedingResult.placements` ordering.

## Tasks / Subtasks

- [x] Task 1: Create `ApplyRandomSeedingParams` (AC: #1)
  - [x] 1.1 Create `lib/core/algorithms/seeding/usecases/apply_random_seeding_params.dart`
  - [x] 1.2 Define:
    ```dart
    import 'package:flutter/foundation.dart' show immutable;
    import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

    /// Parameters for applying cryptographically fair random seeding.
    @immutable
    class ApplyRandomSeedingParams {
      const ApplyRandomSeedingParams({
        required this.divisionId,
        required this.participants,
        this.bracketFormat = BracketFormat.singleElimination,
        this.randomSeed,
      });

      /// The division ID for context.
      final String divisionId;

      /// Participants to seed. Only `id` is used; dojang/region are irrelevant
      /// for pure random seeding (no separation constraints).
      final List<SeedingParticipant> participants;

      /// Bracket format affects meeting-round calculations inside the engine.
      /// Default: singleElimination (most common for TKD tournaments).
      final BracketFormat bracketFormat;

      /// Optional random seed for reproducibility.
      /// If null, a cryptographically secure seed is generated via
      /// `Random.secure().nextInt(1 << 31)`.
      final int? randomSeed;
    }
    ```

- [x] Task 2: Create `ApplyRandomSeedingUseCase` (AC: #2, #3, #4)
  - [x] 2.1 Create `lib/core/algorithms/seeding/usecases/apply_random_seeding_use_case.dart`
  - [x] 2.2 Define:
    ```dart
    import 'dart:math';

    import 'package:fpdart/fpdart.dart';
    import 'package:injectable/injectable.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/seeding_engine.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_random_seeding_params.dart';
    import 'package:tkd_brackets/core/error/failures.dart';
    import 'package:tkd_brackets/core/usecases/use_case.dart';

    /// Use case that applies cryptographically fair random seeding
    /// to a set of participants for a division (FR27).
    ///
    /// Uses [Random.secure()] to generate a verifiable seed when none
    /// is provided. The seed is stored in [SeedingResult.randomSeed]
    /// so that the same bracket ordering can be reproduced later.
    ///
    /// Unlike dojang/regional separation use cases, this passes an
    /// **empty constraints list** — producing a purely random placement.
    @injectable
    class ApplyRandomSeedingUseCase
        extends UseCase<SeedingResult, ApplyRandomSeedingParams> {
      ApplyRandomSeedingUseCase(this._seedingEngine);

      final SeedingEngine _seedingEngine;

      @override
      Future<Either<Failure, SeedingResult>> call(
        ApplyRandomSeedingParams params,
      ) async {
        // 1. Validation — same checks as other seeding use cases
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

        // Check for duplicate participant IDs
        final ids = params.participants.map((p) => p.id).toSet();
        if (ids.length != params.participants.length) {
          return const Left(
            ValidationFailure(
              userFriendlyMessage: 'Duplicate participant IDs detected.',
            ),
          );
        }

        // 2. Generate cryptographically secure seed if none provided (FR27)
        final effectiveSeed =
            params.randomSeed ?? Random.secure().nextInt(1 << 31);

        // 3. Run seeding engine with NO constraints — pure random placement
        return _seedingEngine.generateSeeding(
          participants: params.participants,
          strategy: SeedingStrategy.random,
          constraints: const [],
          bracketFormat: params.bracketFormat,
          randomSeed: effectiveSeed,
        );
      }
    }
    ```
  - [x] 2.3 **IMPORTANT**: The use case deliberately does NOT validate dojang names. For random seeding, participants don't need dojang data — only `id` is required. This differs from `ApplyDojangSeparationSeedingUseCase` which validates `dojangName` is non-empty.

- [x] Task 3: Write `ApplyRandomSeedingUseCase` unit tests (AC: #5, #6)
  - [x] 3.1 Create `test/core/algorithms/seeding/usecases/apply_random_seeding_use_case_test.dart`
  - [x] 3.2 The COMPLETE test file below is copy-pasteable. Follow the exact test pattern of `apply_dojang_separation_seeding_use_case_test.dart`:
    ```dart
    import 'package:flutter_test/flutter_test.dart';
    import 'package:fpdart/fpdart.dart';
    import 'package:mocktail/mocktail.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/seeding_engine.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_random_seeding_params.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_random_seeding_use_case.dart';
    import 'package:tkd_brackets/core/error/failures.dart';

    class MockSeedingEngine extends Mock implements SeedingEngine {}

    void main() {
      late MockSeedingEngine mockEngine;
      late ApplyRandomSeedingUseCase useCase;

      setUpAll(() {
        registerFallbackValue(BracketFormat.singleElimination);
        registerFallbackValue(SeedingStrategy.random);
        // CRITICAL: Must register List<SeedingConstraint> fallback
        // because the constraints param uses any(named: 'constraints')
        registerFallbackValue(<SeedingConstraint>[]);
      });

      setUp(() {
        mockEngine = MockSeedingEngine();
        useCase = ApplyRandomSeedingUseCase(mockEngine);
      });

      final tParticipants = [
        const SeedingParticipant(id: 'p1', dojangName: 'A'),
        const SeedingParticipant(id: 'p2', dojangName: 'B'),
        const SeedingParticipant(id: 'p3', dojangName: 'C'),
        const SeedingParticipant(id: 'p4', dojangName: 'D'),
      ];

      final tParams = ApplyRandomSeedingParams(
        divisionId: 'div1',
        participants: tParticipants,
        randomSeed: 42,
      );

      const tSeedingResult = SeedingResult(
        placements: [],
        appliedConstraints: [],
        randomSeed: 42,
      );

      group('ApplyRandomSeedingUseCase', () {
        test(
          'should call engine with empty constraints and SeedingStrategy.random',
          () async {
            // arrange
            when(
              () => mockEngine.generateSeeding(
                participants: any(named: 'participants'),
                strategy: any(named: 'strategy'),
                constraints: any(named: 'constraints'),
                bracketFormat: any(named: 'bracketFormat'),
                randomSeed: any(named: 'randomSeed'),
              ),
            ).thenReturn(const Right<Failure, SeedingResult>(tSeedingResult));

            // act
            final result = await useCase(tParams);

            // assert
            expect(result, const Right<Failure, SeedingResult>(tSeedingResult));
            verify(
              () => mockEngine.generateSeeding(
                participants: tParticipants,
                strategy: SeedingStrategy.random,
                constraints: [],
                bracketFormat: BracketFormat.singleElimination,
                randomSeed: 42,
              ),
            ).called(1);
          },
        );

        test(
          'should return ValidationFailure when divisionId is empty',
          () async {
            // act
            final result = await useCase(
              ApplyRandomSeedingParams(
                divisionId: '',
                participants: tParticipants,
              ),
            );

            // assert
            expect(result.isLeft(), isTrue);
            result.fold(
              (failure) => expect(failure, isA<ValidationFailure>()),
              (_) => fail('should fail'),
            );
            verifyNever(
              () => mockEngine.generateSeeding(
                participants: any(named: 'participants'),
                strategy: any(named: 'strategy'),
                constraints: any(named: 'constraints'),
                bracketFormat: any(named: 'bracketFormat'),
              ),
            );
          },
        );

        test(
          'should return ValidationFailure when less than 2 participants',
          () async {
            // act
            final result = await useCase(
              ApplyRandomSeedingParams(
                divisionId: 'div1',
                participants: [tParticipants.first],
              ),
            );

            // assert
            expect(result.isLeft(), isTrue);
          },
        );

        test(
          'should return ValidationFailure when participant ID is empty',
          () async {
            // act
            final result = await useCase(
              const ApplyRandomSeedingParams(
                divisionId: 'div1',
                participants: [
                  SeedingParticipant(id: '', dojangName: 'A'),
                  SeedingParticipant(id: 'p2', dojangName: 'B'),
                ],
              ),
            );

            // assert
            expect(result.isLeft(), isTrue);
          },
        );

        test(
          'should return ValidationFailure when duplicate IDs present',
          () async {
            // act
            final result = await useCase(
              const ApplyRandomSeedingParams(
                divisionId: 'div1',
                participants: [
                  SeedingParticipant(id: 'p1', dojangName: 'A'),
                  SeedingParticipant(id: 'p1', dojangName: 'B'),
                ],
              ),
            );

            // assert
            expect(result.isLeft(), isTrue);
          },
        );

        test('should return SeedingFailure when engine fails', () async {
          // arrange
          const failure = SeedingFailure(userFriendlyMessage: 'Engine error');
          when(
            () => mockEngine.generateSeeding(
              participants: any(named: 'participants'),
              strategy: any(named: 'strategy'),
              constraints: any(named: 'constraints'),
              bracketFormat: any(named: 'bracketFormat'),
              randomSeed: any(named: 'randomSeed'),
            ),
          ).thenReturn(const Left(failure));

          // act
          final result = await useCase(tParams);

          // assert
          expect(result, const Left<Failure, SeedingResult>(failure));
        });

        test(
          'should generate a secure seed when randomSeed is null',
          () async {
            // arrange
            when(
              () => mockEngine.generateSeeding(
                participants: any(named: 'participants'),
                strategy: any(named: 'strategy'),
                constraints: any(named: 'constraints'),
                bracketFormat: any(named: 'bracketFormat'),
                randomSeed: any(named: 'randomSeed'),
              ),
            ).thenReturn(const Right<Failure, SeedingResult>(tSeedingResult));

            // act — pass null randomSeed to trigger Random.secure()
            await useCase(
              ApplyRandomSeedingParams(
                divisionId: 'div1',
                participants: tParticipants,
                // randomSeed: null — intentionally omitted
              ),
            );

            // assert — engine MUST have been called with a non-null seed
            final captured = verify(
              () => mockEngine.generateSeeding(
                participants: any(named: 'participants'),
                strategy: any(named: 'strategy'),
                constraints: any(named: 'constraints'),
                bracketFormat: any(named: 'bracketFormat'),
                randomSeed: captureAny(named: 'randomSeed'),
              ),
            ).captured;

            expect(captured.single, isNotNull);
            expect(captured.single, isA<int>());
          },
        );

        test(
          'should NOT validate dojang names (differs from dojang use case)',
          () async {
            // arrange — participants with EMPTY dojangName
            final emptyDojangParticipants = [
              const SeedingParticipant(id: 'p1', dojangName: ''),
              const SeedingParticipant(id: 'p2', dojangName: ''),
            ];

            when(
              () => mockEngine.generateSeeding(
                participants: any(named: 'participants'),
                strategy: any(named: 'strategy'),
                constraints: any(named: 'constraints'),
                bracketFormat: any(named: 'bracketFormat'),
                randomSeed: any(named: 'randomSeed'),
              ),
            ).thenReturn(const Right<Failure, SeedingResult>(tSeedingResult));

            // act — empty dojangName should NOT cause validation failure
            final result = await useCase(
              ApplyRandomSeedingParams(
                divisionId: 'div1',
                participants: emptyDojangParticipants,
                randomSeed: 42,
              ),
            );

            // assert — engine IS called (no validation failure)
            expect(result.isRight(), isTrue);
            verify(
              () => mockEngine.generateSeeding(
                participants: any(named: 'participants'),
                strategy: any(named: 'strategy'),
                constraints: any(named: 'constraints'),
                bracketFormat: any(named: 'bracketFormat'),
                randomSeed: any(named: 'randomSeed'),
              ),
            ).called(1);
          },
        );
      });

      group('Reproducibility (integration)', () {
        test('same seed produces identical placements', () async {
          // Use REAL engine — not mock
          final realEngine = ConstraintSatisfyingSeedingEngine();
          final realUseCase = ApplyRandomSeedingUseCase(realEngine);

          final params = ApplyRandomSeedingParams(
            divisionId: 'div1',
            participants: tParticipants,
            randomSeed: 12345,
          );

          final result1 = await realUseCase(params);
          final result2 = await realUseCase(params);

          // fpdart ^1.1.1 getOrElse signature: (L) => R
          final placements1 =
              result1.getOrElse((_) => throw Exception('Expected Right')).placements;
          final placements2 =
              result2.getOrElse((_) => throw Exception('Expected Right')).placements;

          expect(placements1, equals(placements2));
        });

        test('different seeds produce different placements', () async {
          final realEngine = ConstraintSatisfyingSeedingEngine();
          final realUseCase = ApplyRandomSeedingUseCase(realEngine);

          // Use 8 participants to make collision near-impossible
          final manyParticipants = List.generate(
            8,
            (i) => SeedingParticipant(
              id: 'p$i',
              dojangName: 'School$i',
            ),
          );

          final result1 = await realUseCase(
            ApplyRandomSeedingParams(
              divisionId: 'div1',
              participants: manyParticipants,
              randomSeed: 111,
            ),
          );
          final result2 = await realUseCase(
            ApplyRandomSeedingParams(
              divisionId: 'div1',
              participants: manyParticipants,
              randomSeed: 222,
            ),
          );

          final p1 = result1.getOrElse((_) => throw Exception('fail'));
          final p2 = result2.getOrElse((_) => throw Exception('fail'));

          // At least one placement should differ
          final ids1 = p1.placements.map((p) => p.participantId).toList();
          final ids2 = p2.placements.map((p) => p.participantId).toList();
          expect(ids1, isNot(equals(ids2)));
        });
      });
    }
    ```
  - [x] 3.3 **CRITICAL import for SeedingConstraint type registration**: The existing dojang test does NOT import `SeedingConstraint` because mocktail infers it from the engine mock signature. However, if `registerFallbackValue(<SeedingConstraint>[])` fails to compile, add: `import 'package:tkd_brackets/core/algorithms/seeding/constraints/seeding_constraint.dart';`

- [x] Task 4: Run `build_runner` to regenerate DI config (AC: all)
  - [x] 4.1 Run: `dart run build_runner build --delete-conflicting-outputs`
  - [x] 4.2 Verify that `lib/core/di/injection.config.dart` now contains `ApplyRandomSeedingUseCase` registration
  - [x] 4.3 The new use case injects `SeedingEngine` which is already registered as `ConstraintSatisfyingSeedingEngine` — no new dependency types

- [x] Task 5: Run `dart analyze` and all seeding tests (AC: all)
  - [x] 5.1 Run `dart analyze` — zero errors, zero warnings
  - [x] 5.2 Run new tests: `flutter test test/core/algorithms/seeding/usecases/apply_random_seeding_use_case_test.dart` — all pass
  - [x] 5.3 Run all existing seeding tests: `flutter test test/core/algorithms/seeding/` — no regressions
  - [x] 5.4 Run full project tests: `flutter test` — no regressions across entire project

## Dev Notes

### ⚠️ Scope Boundary: Random Seeding Use Case Only

This story creates a **thin use case** that delegates to the **existing** `ConstraintSatisfyingSeedingEngine`. The engine already supports:
- `int? randomSeed` parameter
- `SeedingStrategy.random`
- Empty constraints list (produces pure random shuffling)
- Storing `randomSeed` in `SeedingResult` for reproducibility

**This story does NOT:**
- Modify `SeedingEngine` or `ConstraintSatisfyingSeedingEngine` — they already handle everything
- Create a new "RandomSeedingService" or "RandomSeedingStrategy" class — the engine's `random` strategy with empty constraints IS random seeding
- Add any UI components — seeding UI is wired in the bracket generation flow
- Add any new DI registrations beyond the `@injectable` on the use case (auto-registered by `build_runner`)

### ⚠️ Cryptographic Fairness: `Random.secure()` for Seed Generation

The FR27 requirement is for **cryptographic fairness in seed generation**, NOT for cryptographic randomness in the shuffling algorithm. Here's why:

1. `Random.secure()` generates a cryptographically unpredictable seed integer
2. That seed is then passed to `Random(seed)` inside the engine for deterministic, reproducible shuffling
3. `Random(seed)` is a PRNG (pseudo-random) — perfectly fine for shuffling fairness once the initial seed is cryptographically unpredictable
4. The stored seed enables **reproducibility**: same seed → same bracket every time
5. The stored seed enables **verifiability**: tournament officials can audit the seed used

**Key implementation detail:**
```dart
final effectiveSeed = params.randomSeed ?? Random.secure().nextInt(1 << 31);
```
- `1 << 31` = `2147483648` — the maximum for `nextInt()` in Dart (exclusive upper bound)
- `Random.secure()` uses the OS-level CSPRNG (e.g., `/dev/urandom` on Linux, `CryptGenRandom` on Windows)
- The returned int is stored in `SeedingResult.randomSeed` for later verification

### ⚠️ No Dojang Validation Required

Unlike `ApplyDojangSeparationSeedingUseCase` which validates `dojangName` is non-empty (because it's needed for separation constraints), random seeding does NOT require dojang data. The validation checks are:
- ✅ `divisionId` non-empty
- ✅ `participants.length >= 2`
- ✅ No empty participant IDs
- ✅ No duplicate participant IDs
- ❌ dojangName validation — NOT checked (dojang is irrelevant for random placement)

### ⚠️ Empty Constraints List — Engine Behavior Details

The critical difference between random seeding and dojang/regional seeding:
```dart
// Random seeding (THIS story):
constraints: const [],  // No constraints — pure random

// Dojang separation (Story 5.7):
constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 2)],

// Regional separation (Story 5.8):
constraints: [DojangSeparationConstraint(...), RegionalSeparationConstraint(...)],
```

**Engine flow with empty constraints:**
1. Engine receives `constraints: []`, `randomSeed: effectiveSeed`
2. Creates `Random(effectiveSeed)` for deterministic shuffling
3. **Edge case (line 49-65 of engine):** If all participants have the same `dojangName` (including empty string), the engine takes the `_buildRandomResult` fast-path which adds a warning `'All participants are from the same dojang...'` and sets `isFullySatisfied: false`. This is cosmetic — the shuffle is still correctly random.
4. **Normal path:** Engine groups by dojang → flattens → runs `_backtrack`. With zero constraints, `_checkConstraints` always returns `true`. Backtracking trivially succeeds on the first attempt.
5. Result: `SeedingResult` with `isFullySatisfied: true`, `constraintViolationCount: 0`, empty `warnings`, and `randomSeed: effectiveSeed`.

**⚠️ GOTCHA for integration tests:** If your test participants ALL have the same `dojangName`, the engine takes the `_buildRandomResult` fast-path and returns `isFullySatisfied: false` with a warning. The test fixtures in Task 3 use DIFFERENT dojang names (`'A'`, `'B'`, `'C'`, `'D'`) to avoid this path. Keep it that way.

### ⚠️ Following Existing Patterns Exactly

**Params class pattern** — copy from `apply_dojang_separation_seeding_params.dart`:
- `@immutable` annotation
- `const` constructor
- Same field types and defaults
- Minus `minimumRoundsSeparation` (irrelevant for random)

**Use case pattern** — copy from `apply_dojang_separation_seeding_use_case.dart`:
- `@injectable` annotation (NOT `@lazySingleton`)
- Extends `UseCase<SeedingResult, ApplyRandomSeedingParams>`
- Constructor injects `SeedingEngine` (same single dependency)
- Same validation structure
- Same delegation to `_seedingEngine.generateSeeding(...)`
- Returns `SeedingResult` directly (engine call is synchronous, wrapped in Future)

**Test pattern** — copy from `apply_dojang_separation_seeding_use_case_test.dart`:
- `MockSeedingEngine extends Mock implements SeedingEngine {}`
- `setUpAll` with `registerFallbackValue` for `BracketFormat` and `SeedingStrategy`
- `setUp` creates mock and use case
- Same validation test structure
- Same `verify` call pattern with `any(named: ...)` matchers

### Existing Infrastructure (DO NOT MODIFY)

#### SeedingEngine Interface
```dart
abstract class SeedingEngine {
  Either<Failure, SeedingResult> generateSeeding({
    required List<SeedingParticipant> participants,
    required SeedingStrategy strategy,
    required List<SeedingConstraint> constraints,
    required BracketFormat bracketFormat,
    int? randomSeed,
    Map<String, int>? pinnedSeeds,
  });
}
```

#### SeedingResult (already stores seed for reproducibility)
```dart
class SeedingResult {
  final List<ParticipantPlacement> placements;
  final List<String> appliedConstraints;
  final int randomSeed;  // ← THIS IS THE STORED SEED
  final List<String> warnings;
  final int constraintViolationCount;
  final bool isFullySatisfied;
}
```

#### SeedingStrategy Enum
```dart
enum SeedingStrategy {
  random('random'),      // ← USE THIS
  ranked('ranked'),
  performanceBased('performance_based'),
  manual('manual');
}
```

### Project Structure Notes

New files created by this story:
```
lib/core/algorithms/seeding/usecases/
├── apply_random_seeding_params.dart       # NEW
└── apply_random_seeding_use_case.dart     # NEW

test/core/algorithms/seeding/usecases/
└── apply_random_seeding_use_case_test.dart  # NEW
```

No files are modified. DI regeneration IS needed — Task 4 runs `build_runner` to register the new use case in `injection.config.dart`.

### ⚠️ DI Registration Details

- The `@injectable` annotation on `ApplyRandomSeedingUseCase` causes `build_runner` to auto-generate a factory registration in `lib/core/di/injection.config.dart`
- The factory will inject `SeedingEngine` → resolved as `ConstraintSatisfyingSeedingEngine` (already registered via `@LazySingleton(as: SeedingEngine)`)
- After running `dart run build_runner build --delete-conflicting-outputs`, verify the generated file contains a line like: `gh.factory<ApplyRandomSeedingUseCase>(() => ApplyRandomSeedingUseCase(gh<SeedingEngine>()));`
- **DO NOT manually edit `injection.config.dart`** — it is fully auto-generated

### ⚠️ Common LLM Mistakes — Prevention Rules

| #   | Mistake                                                                | Correct Approach                                                                                                                                            |
| --- | ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Creating a new `RandomSeedingService` or `RandomSeedingStrategy` class | DO NOT create new service/strategy classes. The existing `SeedingEngine` with `SeedingStrategy.random` and empty constraints IS random seeding              |
| 2   | Modifying `ConstraintSatisfyingSeedingEngine`                          | DO NOT modify the engine. It already handles `randomSeed` parameter and empty constraints correctly                                                         |
| 3   | Using `Random()` instead of `Random.secure()` for seed generation      | MUST use `Random.secure().nextInt(1 << 31)` — this is the cryptographic fairness requirement (FR27)                                                         |
| 4   | Validating `dojangName` in the use case                                | DO NOT validate dojang names. Random seeding doesn't need dojang data. Only validate: divisionId, participant count, empty IDs, duplicates                  |
| 5   | Passing constraints to the engine                                      | Pass `constraints: const []` — random seeding means NO separation constraints                                                                               |
| 6   | Using `@lazySingleton` for the use case                                | Use `@injectable` — all use cases use `@injectable`, only services use `@LazySingleton(as: ...)`                                                            |
| 7   | Forgetting `registerFallbackValue` in test setUpAll                    | MUST register `BracketFormat.singleElimination`, `SeedingStrategy.random`, AND `<SeedingConstraint>[]` — follow the test code in Task 3                     |
| 8   | Not testing the secure seed generation path                            | MUST test that when `randomSeed` is null, the engine is still called with a non-null randomSeed (generated via `Random.secure()`)                           |
| 9   | Using `DateTime.now()` for seed generation in the use case             | The USE CASE must use `Random.secure()`. The engine's internal `DateTime.now()` fallback is for the legacy path — the use case should never reach that path |
| 10  | Importing from `feature/bracket` or `feature/participant`              | This is a `core/algorithms/seeding` use case. Only import from `core/` — never cross into feature layers                                                    |
| 11  | Using `Random.secure().nextInt(2147483648)` literal instead of shift   | Use `1 << 31` for clarity — it equals `2147483648` but is self-documenting                                                                                  |
| 12  | Not writing a reproducibility integration test                         | MUST include a test with the REAL `ConstraintSatisfyingSeedingEngine` that proves `same seed → identical placements`                                        |
| 13  | Using test participants all with the same dojangName                   | Engine takes `_buildRandomResult` fast-path for all-same-dojang → sets `isFullySatisfied: false` with warning. Use DIFFERENT dojang names in test fixtures  |
| 14  | Skipping `build_runner` after creating the use case                    | MUST run `dart run build_runner build --delete-conflicting-outputs` to register the new injectable in `injection.config.dart`                               |
| 15  | Using `captureAny` without `named:` parameter                          | MUST use `captureAny(named: 'randomSeed')` — mocktail requires the named parameter for named arguments                                                      |
| 16  | Passing `divisionId: '  '` (whitespace-only) and expecting success     | The validation uses `.trim().isEmpty` — whitespace-only strings ARE caught and return `ValidationFailure`. This is correct behavior.                        |

### Previous Story Intelligence

Learnings from Story 5.15 (Pool Play → Elimination Hybrid Generator):
- The `@injectable` annotation for use cases is auto-discovered by `build_runner` — but you MUST run `build_runner` to regenerate `injection.config.dart`
- `SeedingStrategy.random` is the correct strategy for any randomized seeding
- The `SeedingEngine.generateSeeding` method is synchronous, so the use case wraps it in `async` to satisfy the `UseCase<T, Params>` contract (`Future<Either<...>>`)
- Test files follow a strict pattern: mock class outside `main()`, `setUpAll` with `registerFallbackValue`, `setUp` with mock creation

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 5.16] — Random Seeding Algorithm acceptance criteria
- [Source: _bmad-output/planning-artifacts/prd.md#FR27] — System applies random seeding with cryptographic fairness
- [Source: lib/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart] — Existing engine that handles Random(seed) and empty constraints
- [Source: lib/core/algorithms/seeding/usecases/apply_dojang_separation_seeding_use_case.dart] — Pattern to follow for use case structure
- [Source: lib/core/algorithms/seeding/usecases/apply_dojang_separation_seeding_params.dart] — Pattern to follow for params structure
- [Source: test/core/algorithms/seeding/usecases/apply_dojang_separation_seeding_use_case_test.dart] — Pattern to follow for test structure
- [Source: lib/core/algorithms/seeding/seeding_engine.dart] — SeedingEngine interface (DO NOT MODIFY)
- [Source: lib/core/algorithms/seeding/models/seeding_result.dart] — SeedingResult already stores randomSeed (DO NOT MODIFY)
- [Source: lib/core/algorithms/seeding/seeding_strategy.dart] — SeedingStrategy.random (DO NOT MODIFY)
- [Source: _bmad-output/planning-artifacts/architecture.md#Seeding Algorithm Architecture] — Constraint-satisfaction approach with randomSeed for reproducibility

## Dev Agent Record

### Agent Model Used

Antigravity (Gemini)

### Debug Log References

### Completion Notes List

- ✅ Created `ApplyRandomSeedingParams` PODO in `lib/core/algorithms/seeding/usecases/apply_random_seeding_params.dart`.
- ✅ Implemented `ApplyRandomSeedingUseCase` in `lib/core/algorithms/seeding/usecases/apply_random_seeding_use_case.dart` with `Random.secure()` for cryptographic fairness (FR27).
- ✅ Added comprehensive unit tests in `test/core/algorithms/seeding/usecases/apply_random_seeding_use_case_test.dart`, including validation logic and secure seed generation.
- ✅ Included integration tests verifying reproducibility (same seed -> same result).
- ✅ Successfully regenerated DI configuration with `build_runner`.
- ✅ Verified `dart analyze` passes with zero errors/warnings.
- ✅ Verified all seeding tests and full project tests pass 100%.

### File List

- `lib/core/algorithms/seeding/usecases/apply_random_seeding_params.dart`
- `lib/core/algorithms/seeding/usecases/apply_random_seeding_use_case.dart`
- `test/core/algorithms/seeding/usecases/apply_random_seeding_use_case_test.dart`
- `lib/core/di/injection.config.dart`
