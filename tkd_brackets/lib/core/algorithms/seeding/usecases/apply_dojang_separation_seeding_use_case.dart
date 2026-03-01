import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
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
              'All participants must have a dojang name for '
              'dojang separation seeding.',
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

    // 2. Create constraint
    final constraint = DojangSeparationConstraint(
      minimumRoundsSeparation: params.minimumRoundsSeparation,
    );

    // 3. Run seeding engine (synchronous — return directly wrapped in Future)
    return _seedingEngine.generateSeeding(
      participants: params.participants,
      strategy: SeedingStrategy.random,
      constraints: [constraint],
      bracketFormat: params.bracketFormat,
      randomSeed: params.randomSeed,
    );
  }
}
