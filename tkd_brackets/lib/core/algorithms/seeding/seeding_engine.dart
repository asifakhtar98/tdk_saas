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
  /// Returns [Left(Failure)] if a critical error occurs.
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
  /// Returns [Left(Failure)] with violation details if any
  /// constraint is not satisfied.
  /// Returns [Right(unit)] if all constraints are satisfied.
  Either<Failure, Unit> validateSeeding({
    required List<ParticipantPlacement> placements,
    required List<SeedingParticipant> participants,
    required List<SeedingConstraint> constraints,
    required BracketFormat bracketFormat,
    required int bracketSize,
  });
}
