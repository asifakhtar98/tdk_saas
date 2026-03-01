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

        // Check pinned participant exists in list
        if (!ids.contains(entry.key)) {
          return Left(
            ValidationFailure(
              userFriendlyMessage:
                  'Pinned participant ID ${entry.key} not found '
                  'in participant list.',
            ),
          );
        }
      }

      // Check for duplicate pin positions
      final pinnedPositions = params.pinnedSeeds.values.toSet();
      if (pinnedPositions.length != params.pinnedSeeds.length) {
        return const Left(
          ValidationFailure(
            userFriendlyMessage:
                'Multiple participants cannot be pinned to same position.',
          ),
        );
      }
    }

    // 2. Build constraints
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
    return Future.value(
      _service.reseedAroundPins(
        ManualSeedOverrideParams(
          participants: params.participants,
          constraints: constraints,
          pinnedSeeds: params.pinnedSeeds,
          bracketFormat: params.bracketFormat,
          randomSeed: params.randomSeed,
        ),
      ),
    );
  }
}
