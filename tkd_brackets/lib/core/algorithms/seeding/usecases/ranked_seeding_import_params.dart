import 'package:flutter/foundation.dart' show immutable, listEquals, mapEquals;
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/ranked_seeding_entry.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

/// Parameters for importing ranked seeding from federation data.
@immutable
class RankedSeedingImportParams {
  const RankedSeedingImportParams({
    required this.divisionId,
    required this.participants,
    required this.rankedEntries,
    required this.participantNames,
    this.bracketFormat = BracketFormat.singleElimination,
    this.matchThreshold = 0.8,
  });

  /// The division ID for context.
  final String divisionId;

  /// Division participants to match against ranked entries.
  final List<SeedingParticipant> participants;

  /// Ranked entries from the federation data file.
  final List<RankedSeedingEntry> rankedEntries;

  /// Map of participantId → athlete display name.
  /// Used for fuzzy matching ranked entry names against participants.
  /// The caller (BLoC or coordinator) builds this from ParticipantEntity data.
  /// EVERY participant ID in [participants] MUST have an entry in this map.
  final Map<String, String> participantNames;

  /// Bracket format affects meeting-round calculations inside the engine.
  /// Default: singleElimination (most common for TKD tournaments).
  final BracketFormat bracketFormat;

  /// Fuzzy match similarity threshold (0.0–1.0).
  /// A ranked entry matches a participant if their name similarity
  /// score is ≥ this threshold.
  /// Default: 0.8 (80% similarity required).
  final double matchThreshold;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankedSeedingImportParams &&
          runtimeType == other.runtimeType &&
          divisionId == other.divisionId &&
          listEquals(participants, other.participants) &&
          listEquals(rankedEntries, other.rankedEntries) &&
          mapEquals(participantNames, other.participantNames) &&
          bracketFormat == other.bracketFormat &&
          matchThreshold == other.matchThreshold;

  @override
  int get hashCode => Object.hash(
        divisionId,
        Object.hashAll(participants),
        Object.hashAll(rankedEntries),
        Object.hashAll(participantNames.entries),
        bracketFormat,
        matchThreshold,
      );

  @override
  String toString() => 'RankedSeedingImportParams('
      'divisionId: $divisionId, '
      'participants: ${participants.length}, '
      'rankedEntries: ${rankedEntries.length}, '
      'matchThreshold: $matchThreshold)';
}
