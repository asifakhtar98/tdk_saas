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
    final effectiveSeed = params.randomSeed ?? Random.secure().nextInt(1 << 31);

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
