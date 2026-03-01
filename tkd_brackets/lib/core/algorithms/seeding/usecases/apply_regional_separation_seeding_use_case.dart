import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/dojang_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/regional_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/seeding_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_regional_separation_seeding_params.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';

/// Use case that applies regional separation seeding (optionally combined
/// with dojang separation) to a set of participants for a division.
///
/// Validates input, constructs constraint list (dojang first for priority,
/// then regional), and delegates to the [SeedingEngine].
@injectable
class ApplyRegionalSeparationSeedingUseCase
    extends UseCase<SeedingResult, ApplyRegionalSeparationSeedingParams> {
  ApplyRegionalSeparationSeedingUseCase(this._seedingEngine);

  final SeedingEngine _seedingEngine;

  @override
  Future<Either<Failure, SeedingResult>> call(
    ApplyRegionalSeparationSeedingParams params,
  ) async {
    // 1. Validation — same checks as dojang use case
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

    // 2. Build constraint list — dojang FIRST (higher priority)
    final constraints = <SeedingConstraint>[];

    if (params.enableDojangSeparation) {
      constraints.add(
        DojangSeparationConstraint(
          minimumRoundsSeparation: params.dojangMinimumRoundsSeparation,
        ),
      );
    }

    constraints.add(
      RegionalSeparationConstraint(
        minimumRoundsSeparation: params.regionalMinimumRoundsSeparation,
      ),
    );

    // 3. Run seeding engine (synchronous — return directly)
    return _seedingEngine.generateSeeding(
      participants: params.participants,
      strategy: SeedingStrategy.random,
      constraints: constraints,
      bracketFormat: params.bracketFormat,
      randomSeed: params.randomSeed,
    );
  }
}
