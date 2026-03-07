import 'package:flutter/foundation.dart' show immutable, listEquals, mapEquals;
import 'package:tkd_brackets/core/algorithms/seeding/models/ranked_seeding_entry.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

/// Diagnostics from the ranked seeding matching process.
///
/// Reports which ranked entries matched which participants,
/// which entries/participants were unmatched, and match confidence scores.
@immutable
class RankedSeedingMatchResult {
  const RankedSeedingMatchResult({
    required this.matchedParticipants,
    required this.unmatchedEntries,
    required this.unmatchedParticipants,
    required this.matchConfidences,
  });

  /// Map of participantId → rank for successfully matched athletes.
  final Map<String, int> matchedParticipants;

  /// Ranked entries that could not be matched to any participant.
  /// Flagged for manual review by the organizer.
  final List<RankedSeedingEntry> unmatchedEntries;

  /// Participants that were not matched to any ranked entry.
  /// These receive seed positions after all matched participants.
  final List<SeedingParticipant> unmatchedParticipants;

  /// Map of participantId → fuzzy match confidence score (0.0–1.0).
  final Map<String, double> matchConfidences;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankedSeedingMatchResult &&
          runtimeType == other.runtimeType &&
          mapEquals(matchedParticipants, other.matchedParticipants) &&
          listEquals(unmatchedEntries, other.unmatchedEntries) &&
          listEquals(unmatchedParticipants, other.unmatchedParticipants) &&
          mapEquals(matchConfidences, other.matchConfidences);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(matchedParticipants.entries),
        Object.hashAll(unmatchedEntries),
        Object.hashAll(unmatchedParticipants),
        Object.hashAll(matchConfidences.entries),
      );

  @override
  String toString() =>
      'RankedSeedingMatchResult(matched: ${matchedParticipants.length}, '
      'unmatchedEntries: ${unmatchedEntries.length}, '
      'unmatchedParticipants: ${unmatchedParticipants.length})';
}
