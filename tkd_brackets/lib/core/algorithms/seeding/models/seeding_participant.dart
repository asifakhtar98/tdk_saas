import 'package:flutter/foundation.dart' show immutable;

/// Lightweight participant data for seeding algorithms.
///
/// This avoids coupling core/algorithms to feature/participant entities.
/// The calling use case maps from ParticipantEntity to this type.
@immutable
class SeedingParticipant {
  const SeedingParticipant({
    required this.id,
    required this.dojangName,
    this.regionName,
  });

  /// Unique participant ID.
  final String id;

  /// School or dojang name — used for separation constraints.
  final String dojangName;

  /// Geographic region name — used for regional separation constraints.
  /// Nullable: participants without a region are fully supported.
  /// Empty string or whitespace-only values are treated as no region.
  final String? regionName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeedingParticipant &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          dojangName == other.dojangName &&
          regionName == other.regionName;

  @override
  int get hashCode => Object.hash(id, dojangName, regionName);

  @override
  String toString() =>
      'SeedingParticipant(id: $id, dojang: $dojangName, region: $regionName)';
}
