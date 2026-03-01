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
      return const Left(
        SeedingFailure(
          userFriendlyMessage: 'No participants provided for seeding.',
        ),
      );
    }

    // 1. Compute bracket size (next power of 2 >= n)
    //    Use bitLength for integer precision.
    final bracketSize = n <= 1 ? n : 1 << (n - 1).bitLength;
    final effectiveSeed = randomSeed ?? DateTime.now().microsecondsSinceEpoch;
    final rng = Random(effectiveSeed);

    // 2. Check edge case: all same dojang → shuffle randomly, return with warning
    final uniqueDojangs = participants
        .map((p) => p.dojangName.toLowerCase().trim())
        .toSet();
    if (uniqueDojangs.length <= 1) {
      return _buildRandomResult(
        participants,
        bracketSize,
        effectiveSeed,
        rng,
        constraints,
        warning:
            'All participants are from the same dojang. '
            'Random seeding applied — separation not possible.',
      );
    }

    // 3. Group participants by dojang (case-insensitive, trimmed)
    final groups = _groupByDojang(participants);

    // 4. Flatten groups into placement order (largest dojang first)
    final ordered = _flattenGroupsLargestFirst(groups, rng);

    // 5. Attempt backtracking placement
    final positions = List<int?>.filled(
      n,
      null,
    ); // positions[i] = seed for participant i
    final usedSeeds =
        <int>{}; // track which seed positions (1..bracketSize) are used
    const iterations = 0;

    final success = _backtrack(
      participantIndex: 0,
      ordered: ordered,
      positions: positions,
      usedSeeds: usedSeeds,
      constraints: constraints,
      allParticipants: participants,
      bracketSize: bracketSize,
      context: _BacktrackContext(
        iterations: iterations,
        maxIterations: _maxIterations,
        rng: rng,
      ),
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
      return Left(
        SeedingFailure(
          userFriendlyMessage:
              'Seeding violates constraints: '
              '${violatedConstraints.join(', ')}',
          constraintViolations: violatedConstraints,
        ),
      );
    }
    return const Right(unit);
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  Map<String, List<SeedingParticipant>> _groupByDojang(
    List<SeedingParticipant> participants,
  ) {
    final groups = <String, List<SeedingParticipant>>{};
    for (final p in participants) {
      final key = p.dojangName.toLowerCase().trim();
      groups.putIfAbsent(key, () => []).add(p);
    }
    return groups;
  }

  List<SeedingParticipant> _flattenGroupsLargestFirst(
    Map<String, List<SeedingParticipant>> groups,
    Random rng,
  ) {
    // Sort group keys by list size (descending)
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) => groups[b]!.length.compareTo(groups[a]!.length));

    final result = <SeedingParticipant>[];
    for (final key in sortedKeys) {
      final group = List<SeedingParticipant>.from(groups[key]!)..shuffle(rng);
      result.addAll(group);
    }
    return result;
  }

  bool _backtrack({
    required int participantIndex,
    required List<SeedingParticipant> ordered,
    required List<int?> positions,
    required Set<int> usedSeeds,
    required List<SeedingConstraint> constraints,
    required List<SeedingParticipant> allParticipants,
    required int bracketSize,
    required _BacktrackContext context,
  }) {
    if (participantIndex == ordered.length) return true;
    if (context.iterations >= context.maxIterations) return false;
    context.iterations++;

    // Try all possible seed positions (1..bracketSize)
    // To make it feel "random", we shuffle the available seeds
    final availableSeeds = <int>[];
    for (var i = 1; i <= bracketSize; i++) {
      if (!usedSeeds.contains(i)) availableSeeds.add(i);
    }
    // Shuffle available seeds to explore diverse paths and avoid deterministic dead-ends.
    // Uses the provided RNG to maintain reproducibility if a seed was given.
    availableSeeds.shuffle(context.rng);

    for (final seed in availableSeeds) {
      // Temporary placement to check constraints
      positions[participantIndex] = seed;

      // Check partial constraints
      final currentPlacements = <ParticipantPlacement>[];
      for (var i = 0; i <= participantIndex; i++) {
        currentPlacements.add(
          ParticipantPlacement(
            participantId: ordered[i].id,
            seedPosition: positions[i]!,
            bracketSlot: positions[i],
          ),
        );
      }

      var satisfied = true;
      for (final constraint in constraints) {
        if (!constraint.isSatisfied(
          placements: currentPlacements,
          participants: allParticipants,
          bracketSize: bracketSize,
        )) {
          satisfied = false;
          break;
        }
      }

      if (satisfied) {
        usedSeeds.add(seed);
        if (_backtrack(
          participantIndex: participantIndex + 1,
          ordered: ordered,
          positions: positions,
          usedSeeds: usedSeeds,
          constraints: constraints,
          allParticipants: allParticipants,
          bracketSize: bracketSize,
          context: context,
        )) {
          return true;
        }
        usedSeeds.remove(seed);
      }

      positions[participantIndex] = null;
    }

    return false;
  }

  Either<Failure, SeedingResult> _buildRandomResult(
    List<SeedingParticipant> participants,
    int bracketSize,
    int effectiveSeed,
    Random rng,
    List<SeedingConstraint> constraints, {
    required String warning,
  }) {
    final shuffled = List<SeedingParticipant>.from(participants)..shuffle(rng);
    final placements = <ParticipantPlacement>[];
    for (var i = 0; i < shuffled.length; i++) {
      placements.add(
        ParticipantPlacement(
          participantId: shuffled[i].id,
          seedPosition: i + 1,
          bracketSlot: i + 1,
        ),
      );
    }

    var violationCount = 0;
    for (final constraint in constraints) {
      violationCount += constraint.countViolations(
        placements: placements,
        participants: participants,
        bracketSize: bracketSize,
      );
    }

    return Right(
      SeedingResult(
        placements: placements,
        appliedConstraints: constraints.map((c) => c.name).toList(),
        randomSeed: effectiveSeed,
        warnings: [warning],
        constraintViolationCount: violationCount,
        // Always false when all participants share the same dojang,
        // since dojang separation is inherently impossible.
        isFullySatisfied: false,
      ),
    );
  }

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
  }) {
    final placements = <ParticipantPlacement>[];
    for (var i = 0; i < ordered.length; i++) {
      placements.add(
        ParticipantPlacement(
          participantId: ordered[i].id,
          seedPosition: positions[i]!,
          bracketSlot: positions[i],
        ),
      );
    }

    // Sort placements by seedPosition for consistent output
    placements.sort((a, b) => a.seedPosition.compareTo(b.seedPosition));

    var totalViolations = constraintViolationCount;
    if (totalViolations == 0 && !isFullySatisfied) {
      // Re-calculate violations if not passed
      for (final constraint in constraints) {
        totalViolations += constraint.countViolations(
          placements: placements,
          participants: participants,
          bracketSize: bracketSize,
        );
      }
    }

    final finalWarnings = List<String>.from(warnings);
    if (totalViolations > 0 && finalWarnings.isEmpty) {
      finalWarnings.add(
        'Constraints could not be fully satisfied. '
        'Best effort matching applied with $totalViolations violation(s).',
      );
    }

    return Right(
      SeedingResult(
        placements: placements,
        appliedConstraints: constraints.map((c) => c.name).toList(),
        randomSeed: effectiveSeed,
        warnings: finalWarnings,
        constraintViolationCount: totalViolations,
        isFullySatisfied: totalViolations == 0,
      ),
    );
  }

  Either<Failure, SeedingResult> _fallbackMinimizeViolations({
    required List<SeedingParticipant> participants,
    required List<SeedingConstraint> constraints,
    required int bracketSize,
    required int effectiveSeed,
    required Random rng,
  }) {
    // Try 100 random permutations and pick the best one
    List<ParticipantPlacement>? bestPlacements;
    var minViolations = double.maxFinite.toInt();

    for (var i = 0; i < 100; i++) {
      final shuffled = List<SeedingParticipant>.from(participants)
        ..shuffle(rng);
      final currentPlacements = <ParticipantPlacement>[];
      for (var j = 0; j < shuffled.length; j++) {
        currentPlacements.add(
          ParticipantPlacement(
            participantId: shuffled[j].id,
            seedPosition: j + 1,
            bracketSlot: j + 1,
          ),
        );
      }

      var currentViolations = 0;
      for (final constraint in constraints) {
        currentViolations += constraint.countViolations(
          placements: currentPlacements,
          participants: participants,
          bracketSize: bracketSize,
        );
      }

      if (currentViolations < minViolations) {
        minViolations = currentViolations;
        bestPlacements = currentPlacements;
      }
      if (minViolations == 0) break;
    }

    return Right(
      SeedingResult(
        placements: bestPlacements!,
        appliedConstraints: constraints.map((c) => c.name).toList(),
        randomSeed: effectiveSeed,
        warnings: [
          'Constraints could not be fully satisfied after $_maxIterations iterations. Best effort matching applied with $minViolations violation(s).',
        ],
        constraintViolationCount: minViolations,
        isFullySatisfied: minViolations == 0,
      ),
    );
  }
}

/// Mutable context for tracking backtracking iteration count.
class _BacktrackContext {
  _BacktrackContext({
    required this.iterations,
    required this.maxIterations,
    required this.rng,
  });
  int iterations;
  final int maxIterations;
  final Random rng;
}
