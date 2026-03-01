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
  int get hashCode => Object.hash(
    randomSeed,
    constraintViolationCount,
    isFullySatisfied,
    Object.hashAll(placements),
    Object.hashAll(appliedConstraints),
    Object.hashAll(warnings),
  );

  @override
  String toString() =>
      'SeedingResult(placements: ${placements.length}, fullySatisfied: $isFullySatisfied, violations: $constraintViolationCount)';
}
