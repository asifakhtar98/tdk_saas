import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/services/single_elimination_bracket_generator_service.dart';
import 'package:uuid/uuid.dart';

/// Implementation of [SingleEliminationBracketGeneratorService].
@LazySingleton(as: SingleEliminationBracketGeneratorService)
class SingleEliminationBracketGeneratorServiceImplementation
    implements SingleEliminationBracketGeneratorService {
  SingleEliminationBracketGeneratorServiceImplementation(this._uuid);

  final Uuid _uuid;

  @override
  BracketGenerationResult generate({
    required String divisionId,
    required List<String> participantIds,
    required String bracketId,
    bool includeThirdPlaceMatch = false,
  }) {
    final n = participantIds.length;
    final totalRounds = (log(n) / ln2).ceil();
    final bracketSize = pow(2, totalRounds).toInt();
    final now = DateTime.now();

    // Calculate total matches (excluding 3rd place for now)
    final tournamentMatches = bracketSize - 1;
    final totalMatches = tournamentMatches +
        (includeThirdPlaceMatch && totalRounds >= 2 ? 1 : 0);

    // Generate ALL match IDs upfront
    final matchIds =
        List.generate(totalMatches, (_) => _uuid.v4());

    final matches = <MatchEntity>[];

    // Create the bracket entity
    final bracket = BracketEntity(
      id: bracketId,
      divisionId: divisionId,
      bracketType: BracketType.winners,
      totalRounds: totalRounds,
      createdAtTimestamp: now,
      updatedAtTimestamp: now,
      generatedAtTimestamp: now,
      bracketDataJson: {
        'includeThirdPlaceMatch': includeThirdPlaceMatch,
        'participantCount': n,
      },
    );

    // Map to keep track of match by round and index (1-indexed)
    final matchMap = <int, Map<int, MatchEntity>>{};

    // 1. Create all match slots
    var matchIdIdx = 0;
    for (var r = 1; r <= totalRounds; r++) {
      matchMap[r] = {};
      final matchesInRound = bracketSize ~/ pow(2, r);
      for (var m = 1; m <= matchesInRound; m++) {
        final matchId = matchIds[matchIdIdx++];
        final match = MatchEntity(
          id: matchId,
          bracketId: bracketId,
          roundNumber: r,
          matchNumberInRound: m,
          createdAtTimestamp: now,
          updatedAtTimestamp: now,
          status: MatchStatus.pending,
        );
        matchMap[r]![m] = match;
      }
    }

    // 2. Link matches (advancement)
    for (var r = 1; r < totalRounds; r++) {
      final matchesInRound = matchMap[r]!.length;
      for (var m = 1; m <= matchesInRound; m++) {
        final nextMatchNum = (m + 1) ~/ 2;
        final nextMatch = matchMap[r + 1]![nextMatchNum]!;
        matchMap[r]![m] = matchMap[r]![m]!.copyWith(
          winnerAdvancesToMatchId: nextMatch.id,
        );
      }
    }

    // 3. Assign participants to Round 1 and handle byes
    final r1Matches = matchMap[1]!;
    final r1Count = r1Matches.length;
    final byeCount = bracketSize - n;

    // Byes go to top matches first (M1..MB), then normal
    // matches (MB+1..r1Count).
    var pIdx = 0;
    for (var m = 1; m <= r1Count; m++) {
      String? redId;
      String? blueId;

      if (m <= byeCount) {
        // Bye match: top-seeded positions get byes
        if (pIdx < n) redId = participantIds[pIdx++];
      } else {
        // Normal match
        if (pIdx < n) redId = participantIds[pIdx++];
        if (pIdx < n) blueId = participantIds[pIdx++];
      }

      var match = r1Matches[m]!;
      match = match.copyWith(
        participantRedId: redId,
        participantBlueId: blueId,
      );

      // Handle BYE Status/Result
      if (redId != null && blueId == null) {
        match = match.copyWith(
          status: MatchStatus.completed,
          resultType: MatchResultType.bye,
          completedAtTimestamp: now,
          winnerId: redId,
        );
      }
      r1Matches[m] = match;
    }

    // 4. Handle 3rd place match
    MatchEntity? thirdPlaceMatch;
    if (includeThirdPlaceMatch && totalRounds >= 2) {
      final matchId = matchIds.last;
      thirdPlaceMatch = MatchEntity(
        id: matchId,
        bracketId: bracketId,
        roundNumber: totalRounds,
        matchNumberInRound: 2, // Final is 1
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
        status: MatchStatus.pending,
      );

      // Link semi-final losers to 3rd place
      final semiRound = totalRounds - 1;
      final semiMatches = matchMap[semiRound]!;
      if (semiMatches.containsKey(1)) {
        semiMatches[1] = semiMatches[1]!.copyWith(
          loserAdvancesToMatchId: thirdPlaceMatch.id,
        );
      }
      if (semiMatches.containsKey(2)) {
        semiMatches[2] = semiMatches[2]!.copyWith(
          loserAdvancesToMatchId: thirdPlaceMatch.id,
        );
      }
    }

    // 5. Advance bye winners to Round 2
    if (totalRounds >= 2) {
      final r2Matches = matchMap[2]!;
      for (var m = 1; m <= r1Count; m++) {
        final match = r1Matches[m]!;
        if (match.resultType == MatchResultType.bye &&
            match.winnerId != null) {
          final nextMatchNum = (m + 1) ~/ 2;
          var nextMatch = r2Matches[nextMatchNum]!;

          if (m % 2 != 0) {
            nextMatch = nextMatch.copyWith(
              participantRedId: match.winnerId,
            );
          } else {
            nextMatch = nextMatch.copyWith(
              participantBlueId: match.winnerId,
            );
          }
          r2Matches[nextMatchNum] = nextMatch;
        }
      }
    }

    // Flatten matchMap to list
    for (final roundMatches in matchMap.values) {
      matches.addAll(roundMatches.values);
    }

    if (thirdPlaceMatch != null) {
      matches.add(thirdPlaceMatch);
    }

    return BracketGenerationResult(
      bracket: bracket,
      matches: matches,
    );
  }
}
