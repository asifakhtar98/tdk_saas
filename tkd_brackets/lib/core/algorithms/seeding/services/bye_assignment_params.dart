import 'package:flutter/foundation.dart' show immutable, listEquals;


/// Parameters for the bye assignment algorithm.
@immutable
class ByeAssignmentParams {
  /// Creates [ByeAssignmentParams].
  ///
  /// [participantCount] must be >= 2.
  /// [seedOrder] if provided, must have length == [participantCount].
  const ByeAssignmentParams({
    required this.participantCount,
    this.seedOrder,
  });

  /// Total number of actual participants.
  final int participantCount;

  /// Optional ordered list of participant IDs, highest seed first.
  /// If provided, ByePlacement.participantId will be populated.
  /// Length MUST equal [participantCount] when provided.
  final List<String>? seedOrder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ByeAssignmentParams &&
          runtimeType == other.runtimeType &&
          participantCount == other.participantCount &&
          listEquals(seedOrder, other.seedOrder);

  @override
  int get hashCode => Object.hash(
        participantCount,
        seedOrder == null ? null : Object.hashAll(seedOrder!),
      );

  @override
  String toString() =>
      'ByeAssignmentParams(count: $participantCount, seedOrder: $seedOrder)';
}
