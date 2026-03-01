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
