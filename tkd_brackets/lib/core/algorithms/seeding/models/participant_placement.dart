import 'package:flutter/foundation.dart' show immutable;

/// Represents the assigned position of a participant in a seeded bracket.
@immutable
class ParticipantPlacement {
  const ParticipantPlacement({
    required this.participantId,
    required this.seedPosition,
    this.bracketSlot,
  });

  /// The participant's unique ID.
  final String participantId;

  /// The seed position (1-indexed, 1 = top seed).
  final int seedPosition;

  /// The physical bracket slot position (1-indexed).
  /// May differ from seedPosition if bracket has byes.
  final int? bracketSlot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticipantPlacement &&
          runtimeType == other.runtimeType &&
          participantId == other.participantId &&
          seedPosition == other.seedPosition &&
          bracketSlot == other.bracketSlot;

  @override
  int get hashCode =>
      participantId.hashCode ^ seedPosition.hashCode ^ bracketSlot.hashCode;

  @override
  String toString() =>
      'ParticipantPlacement(id: $participantId, seed: $seedPosition, slot: $bracketSlot)';
}
