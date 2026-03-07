import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/ranked_seeding_entry.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/ranked_seeding_import_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/ranked_seeding_match_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/ranked_seeding_import_params.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';

/// Use case for importing ranked seeding from federation data.
///
/// Multi-step process:
/// 1. Validate inputs (division, participants, ranked entries)
/// 2. Perform fuzzy name matching (and optional club match)
/// 3. Normalizes ranks and assigns contiguous seed positions (1..N)
/// 4. Pins ALL participants to their assigned seeds
/// 5. Delegates to SeedingEngine to validate/generate the final seeding
@injectable
class RankedSeedingImportUseCase
    extends UseCase<RankedSeedingImportResult, RankedSeedingImportParams> {
  RankedSeedingImportUseCase(this._seedingEngine);

  final SeedingEngine _seedingEngine;

  @override
  Future<Either<Failure, RankedSeedingImportResult>> call(
    RankedSeedingImportParams params,
  ) async {
    // 1. Validation
    final validationError = _validate(params);
    if (validationError != null) return Left(validationError);

    // 2. Fuzzy Matching
    final matchedParticipantIds = <String>{};
    final matchedParticipants = <String, int>{}; // participantId -> rank
    final matchConfidences = <String, double>{}; // participantId -> score
    final unmatchedEntries = <RankedSeedingEntry>[];

    final sortedEntries = List<RankedSeedingEntry>.from(params.rankedEntries)
      ..sort((a, b) => a.rank.compareTo(b.rank));

    for (final entry in sortedEntries) {
      String? bestParticipantId;
      var bestScore = -1.0;

      for (final participant in params.participants) {
        if (matchedParticipantIds.contains(participant.id)) continue;

        final pName = params.participantNames[participant.id]!;
        final nameScore = _levenshteinSimilarity(
          _normalize(entry.name),
          _normalize(pName),
        );

        if (nameScore < params.matchThreshold) continue;

        var totalScore = nameScore;
        if (entry.club != null && entry.club!.trim().isNotEmpty) {
          final clubScore = _levenshteinSimilarity(
            _normalize(entry.club!),
            _normalize(participant.dojangName),
          );
          if (clubScore < params.matchThreshold) continue;
          totalScore = (nameScore + clubScore) / 2;
        }

        if (totalScore > bestScore) {
          bestScore = totalScore;
          bestParticipantId = participant.id;
        }
      }

      if (bestParticipantId != null) {
        matchedParticipantIds.add(bestParticipantId);
        matchedParticipants[bestParticipantId] = entry.rank;
        matchConfidences[bestParticipantId] = bestScore;
      } else {
        unmatchedEntries.add(entry);
      }
    }

    final unmatchedParticipants = params.participants
        .where((p) => !matchedParticipantIds.contains(p.id))
        .toList();

    final matchResult = RankedSeedingMatchResult(
      matchedParticipants: matchedParticipants,
      unmatchedEntries: unmatchedEntries,
      unmatchedParticipants: unmatchedParticipants,
      matchConfidences: matchConfidences,
    );

    // 3. Seed assignment (normalize and pin ALL)
    final pinnedSeeds = <String, int>{};

    // Sort matched by their source rank
    final matchedByRank = matchedParticipants.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Contiguous assignment 1..M for matched
    var currentSeed = 1;
    for (final entry in matchedByRank) {
      pinnedSeeds[entry.key] = currentSeed++;
    }

    // Append unmatched after matched
    for (final p in unmatchedParticipants) {
      pinnedSeeds[p.id] = currentSeed++;
    }

    // 4. Delegate to SeedingEngine
    final seedingResult = _seedingEngine.generateSeeding(
      participants: params.participants,
      strategy: SeedingStrategy.ranked,
      constraints: const [],
      bracketFormat: params.bracketFormat,
      randomSeed: 0,
      pinnedSeeds: pinnedSeeds,
    );

    return seedingResult.map(
      (sResult) => RankedSeedingImportResult(
        seedingResult: sResult,
        matchResult: matchResult,
      ),
    );
  }

  ValidationFailure? _validate(RankedSeedingImportParams params) {
    if (params.divisionId.isEmpty) {
      return const ValidationFailure(userFriendlyMessage: 'Division ID cannot be empty');
    }
    if (params.participants.length < 2) {
      return const ValidationFailure(userFriendlyMessage: 'At least 2 participants are required');
    }
    if (params.rankedEntries.isEmpty) {
      return const ValidationFailure(userFriendlyMessage: 'Ranked entries list cannot be empty');
    }
    if (params.matchThreshold < 0.0 || params.matchThreshold > 1.0) {
      return const ValidationFailure(userFriendlyMessage: 'Match threshold must be between 0.0 and 1.0');
    }

    final ids = <String>{};
    for (final p in params.participants) {
      if (p.id.isEmpty) {
        return const ValidationFailure(userFriendlyMessage: 'Participant ID cannot be empty');
      }
      if (!ids.add(p.id)) {
        return ValidationFailure(userFriendlyMessage: 'Duplicate participant ID: ${p.id}');
      }
      if (!params.participantNames.containsKey(p.id)) {
        return ValidationFailure(userFriendlyMessage: 'Missing name for participant ID: ${p.id}');
      }
    }

    final ranks = <int>{};
    for (final entry in params.rankedEntries) {
      if (entry.name.trim().isEmpty) {
        return const ValidationFailure(userFriendlyMessage: 'Ranked entry name cannot be empty');
      }
      if (entry.rank <= 0) {
        return ValidationFailure(userFriendlyMessage: 'Invalid rank for ${entry.name}: must be > 0');
      }
      if (!ranks.add(entry.rank)) {
        return ValidationFailure(userFriendlyMessage: 'Duplicate rank found: ${entry.rank}');
      }
    }

    return null;
  }

  /// Computes similarity ratio between two strings (0–1).
  /// 1 = identical, 0 = completely different.
  double _levenshteinSimilarity(String a, String b) {
    if (a == b) return 1;
    if (a.isEmpty || b.isEmpty) return 0;
    final maxLen = a.length > b.length ? a.length : b.length;
    return 1 - (_levenshteinDistance(a, b) / maxLen);
  }

  /// Standard Levenshtein distance via dynamic programming.
  /// O(n*m) time, O(min(n,m)) space using single-row optimization.
  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    var s = s1;
    var t = s2;

    // Ensure s is the shorter string for space optimization
    if (s.length > t.length) {
      s = s2;
      t = s1;
    }

    final sLen = s.length;
    final tLen = t.length;
    var previousRow = List<int>.generate(sLen + 1, (i) => i);

    for (var j = 1; j <= tLen; j++) {
      final currentRow = List<int>.filled(sLen + 1, 0);
      currentRow[0] = j;
      for (var i = 1; i <= sLen; i++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        currentRow[i] = [
          currentRow[i - 1] + 1, // insertion
          previousRow[i] + 1, // deletion
          previousRow[i - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
      previousRow = currentRow;
    }
    return previousRow[sLen];
  }

  String _normalize(String name) => name.trim().toLowerCase();
}
