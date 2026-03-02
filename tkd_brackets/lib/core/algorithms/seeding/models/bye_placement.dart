import 'package:flutter/foundation.dart' show immutable;

/// Represents a single bye assignment: which participant gets a bye
/// and at which bracket position.
@immutable
class ByePlacement {
  /// Creates a [ByePlacement].
  const ByePlacement({
    required this.seedPosition,
    required this.bracketSlot,
    required this.byeSlot,
    this.participantId,
  });

  /// Participant ID receiving the bye. Null if ByeAssignmentParams.seedOrder
  /// was not provided.
  final String? participantId;

  /// Seed number of the participant receiving the bye (1 = top seed).
  final int seedPosition;

  /// Bracket slot (1-indexed) where the participant is placed.
  final int bracketSlot;

  /// Bracket slot (1-indexed) that is empty (the bye position).
  /// This slot is paired with [bracketSlot] in Round 1.
  final int byeSlot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ByePlacement &&
          runtimeType == other.runtimeType &&
          participantId == other.participantId &&
          seedPosition == other.seedPosition &&
          bracketSlot == other.bracketSlot &&
          byeSlot == other.byeSlot;

  @override
  int get hashCode =>
      Object.hash(participantId, seedPosition, bracketSlot, byeSlot);

  @override
  String toString() =>
      'ByePlacement(id: $participantId, seed: $seedPosition, '
      'slot: $bracketSlot, byeSlot: $byeSlot)';
}
