import 'package:flutter/foundation.dart' show immutable;

/// A single entry from a federation ranking file.
///
/// Represents one ranked athlete with their name, club, and ranking position.
/// Used as input to RankedSeedingImportUseCase for matching against
/// division participants.
@immutable
class RankedSeedingEntry {
  const RankedSeedingEntry({
    required this.name,
    required this.rank,
    this.club,
  });

  /// Athlete name from the federation ranking.
  final String name;

  /// The athlete's club/dojang name from the ranking file.
  /// Used for disambiguation when multiple athletes share similar names.
  /// Null or empty means no club disambiguation is applied.
  final String? club;

  /// Ranking position (1-indexed, 1 = highest rank / top seed).
  final int rank;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankedSeedingEntry &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          club == other.club &&
          rank == other.rank;

  @override
  int get hashCode => Object.hash(name, club, rank);

  @override
  String toString() =>
      'RankedSeedingEntry(name: $name, club: $club, rank: $rank)';
}
