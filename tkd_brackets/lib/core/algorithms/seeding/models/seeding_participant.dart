import 'package:flutter/foundation.dart' show immutable;

/// Lightweight participant data for seeding algorithms.
///
/// This avoids coupling core/algorithms to feature/participant entities.
/// The calling use case maps from ParticipantEntity to this type.
@immutable
class SeedingParticipant {
  const SeedingParticipant({required this.id, required this.dojangName});

  /// Unique participant ID.
  final String id;

  /// School or dojang name — used for separation constraints.
  final String dojangName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeedingParticipant &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          dojangName == other.dojangName;

  @override
  int get hashCode => id.hashCode ^ dojangName.hashCode;

  @override
  String toString() => 'SeedingParticipant(id: $id, dojang: $dojangName)';
}
