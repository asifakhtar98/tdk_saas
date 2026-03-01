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

    // Re-validate constraints (using countViolations as per AC #6)
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
                'another participant.',
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
