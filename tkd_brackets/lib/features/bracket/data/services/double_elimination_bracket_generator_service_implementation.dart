import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/double_elimination_bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/services/double_elimination_bracket_generator_service.dart';
import 'package:uuid/uuid.dart';

/// Implementation of [DoubleEliminationBracketGeneratorService].
@LazySingleton(as: DoubleEliminationBracketGeneratorService)
class DoubleEliminationBracketGeneratorServiceImplementation
    implements DoubleEliminationBracketGeneratorService {
  DoubleEliminationBracketGeneratorServiceImplementation(this._uuid);

  final Uuid _uuid;

  @override
  DoubleEliminationBracketGenerationResult generate({
    required String divisionId,
    required List<String> participantIds,
    required String winnersBracketId,
    required String losersBracketId,
    bool includeResetMatch = true,
  }) {
    final n = participantIds.length;
    if (n < 2) {
      throw ArgumentError(
        'At least 2 participants are required '
        'to generate a double elimination bracket.',
      );
    }
    final wRounds = (log(n) / ln2).ceil();
    final bracketSize = pow(2, wRounds).toInt();
    // Losers bracket has 2 * (wRounds - 1) rounds (for n >= 4)
    // For n=2, wRounds=1, lRounds=0
    final lRounds = max(0, 2 * (wRounds - 1));
    final now = DateTime.now();

    // Step 1: Calculate total matches and pre-generate all IDs
    final wMatchesCount = bracketSize - 1;
    final lMatchesCount = max(0, bracketSize - 2);
    const grandFinalsCount = 1;
    final resetCount = includeResetMatch ? 1 : 0;
    final totalMatches =
        wMatchesCount + lMatchesCount + grandFinalsCount + resetCount;
    final matchIds = List.generate(totalMatches, (_) => _uuid.v4());

    var matchIdIdx = 0;

    // Step 2: Create winners bracket entity
    final winnersBracket = BracketEntity(
      id: winnersBracketId,
      divisionId: divisionId,
      bracketType: BracketType.winners,
      totalRounds: wRounds,
      createdAtTimestamp: now,
      updatedAtTimestamp: now,
      generatedAtTimestamp: now,
      bracketDataJson: {
        'doubleElimination': true,
        'participantCount': n,
        'includeResetMatch': includeResetMatch,
      },
    );

    // Step 3: Create losers bracket entity
    final losersBracket = BracketEntity(
      id: losersBracketId,
      divisionId: divisionId,
      bracketType: BracketType.losers,
      totalRounds: lRounds,
      createdAtTimestamp: now,
      updatedAtTimestamp: now,
      generatedAtTimestamp: now,
      bracketDataJson: {
        'doubleElimination': true,
        'participantCount': n,
        'includeResetMatch': includeResetMatch,
      },
    );

    // Maps to store matches by round and match number
    final wbMatchMap = <int, Map<int, MatchEntity>>{};
    final lbMatchMap = <int, Map<int, MatchEntity>>{};

    // Step 4: Build winners bracket match slots
    for (var r = 1; r <= wRounds; r++) {
      wbMatchMap[r] = {};
      final matchesInRound = bracketSize ~/ pow(2, r);
      for (var m = 1; m <= matchesInRound; m++) {
        wbMatchMap[r]![m] = MatchEntity(
          id: matchIds[matchIdIdx++],
          bracketId: winnersBracketId,
          roundNumber: r,
          matchNumberInRound: m,
          createdAtTimestamp: now,
          updatedAtTimestamp: now,
          status: MatchStatus.pending,
        );
      }
    }

    // Step 5: Build losers bracket match slots
    for (var r = 1; r <= lRounds; r++) {
      lbMatchMap[r] = {};
      final pairIndex = (r + 1) ~/ 2;
      final matchesInRound = bracketSize ~/ pow(2, pairIndex + 1);
      for (var m = 1; m <= matchesInRound; m++) {
        lbMatchMap[r]![m] = MatchEntity(
          id: matchIds[matchIdIdx++],
          bracketId: losersBracketId,
          roundNumber: r,
          matchNumberInRound: m,
          createdAtTimestamp: now,
          updatedAtTimestamp: now,
          status: MatchStatus.pending,
        );
      }
    }

    // Step 6: Create Grand Finals and Reset slots
    MatchEntity? resetMatch;

    var grandFinalsMatch = MatchEntity(
      id: matchIds[matchIdIdx++],
      bracketId: winnersBracketId,
      roundNumber: wRounds + 1,
      matchNumberInRound: 1,
      createdAtTimestamp: now,
      updatedAtTimestamp: now,
      status: MatchStatus.pending,
    );

    if (includeResetMatch) {
      resetMatch = MatchEntity(
        id: matchIds[matchIdIdx++],
        bracketId: winnersBracketId,
        roundNumber: wRounds + 2,
        matchNumberInRound: 1,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
        status: MatchStatus.pending,
      );
      grandFinalsMatch = grandFinalsMatch.copyWith(
        winnerAdvancesToMatchId: resetMatch.id,
      );
    }

    // Step 7: Link intra-Winners advancement
    for (var r = 1; r < wRounds; r++) {
      for (var m = 1; m <= wbMatchMap[r]!.length; m++) {
        final nextMatchNum = (m + 1) ~/ 2;
        wbMatchMap[r]![m] = wbMatchMap[r]![m]!.copyWith(
          winnerAdvancesToMatchId: wbMatchMap[r + 1]![nextMatchNum]!.id,
        );
      }
    }
    // Winners Final winner advances to Grand Finals
    wbMatchMap[wRounds]![1] = wbMatchMap[wRounds]![1]!.copyWith(
      winnerAdvancesToMatchId: grandFinalsMatch.id,
    );

    // Step 8: Link intra-Losers advancement
    for (var r = 1; r < lRounds; r++) {
      final currentRoundMatches = lbMatchMap[r]!;
      final nextRoundMatches = lbMatchMap[r + 1]!;
      if (r.isOdd) {
        // Elimination round -> next is drop-down (same count)
        for (var m = 1; m <= currentRoundMatches.length; m++) {
          lbMatchMap[r]![m] = lbMatchMap[r]![m]!.copyWith(
            winnerAdvancesToMatchId: nextRoundMatches[m]!.id,
          );
        }
      } else {
        // Drop-down round -> next is elimination (half count)
        for (var m = 1; m <= currentRoundMatches.length; m++) {
          final nextMatchNum = (m + 1) ~/ 2;
          lbMatchMap[r]![m] = lbMatchMap[r]![m]!.copyWith(
            winnerAdvancesToMatchId: nextRoundMatches[nextMatchNum]!.id,
          );
        }
      }
    }
    // Losers Final winner advances to Grand Finals
    if (lRounds > 0) {
      lbMatchMap[lRounds]![1] = lbMatchMap[lRounds]![1]!.copyWith(
        winnerAdvancesToMatchId: grandFinalsMatch.id,
      );
    }

    // Step 9: Link cross-bracket routing (WB losers -> LB)
    // WB R1 losers -> LB R1
    for (var m = 1; m <= wbMatchMap[1]!.length; m++) {
      final lbMatchNum = (m + 1) ~/ 2;
      if (lRounds >= 1) {
        wbMatchMap[1]![m] = wbMatchMap[1]![m]!.copyWith(
          loserAdvancesToMatchId: lbMatchMap[1]![lbMatchNum]!.id,
        );
      } else {
        // Special case n=2: WB loser goes to GF
        wbMatchMap[1]![m] = wbMatchMap[1]![m]!.copyWith(
          loserAdvancesToMatchId: grandFinalsMatch.id,
        );
      }
    }

    // WB Round R (R>=2) losers -> LB Round 2*(R-1)
    for (var r = 2; r <= wRounds; r++) {
      final lbTargetRound = 2 * (r - 1);
      final wbMatches = wbMatchMap[r]!;
      final lbMatches = lbMatchMap[lbTargetRound];
      if (lbMatches != null) {
        for (var m = 1; m <= wbMatches.length; m++) {
          // Reverse order for fairness
          final lbMatchNum = lbMatches.length - m + 1;
          wbMatchMap[r]![m] = wbMatchMap[r]![m]!.copyWith(
            loserAdvancesToMatchId: lbMatches[lbMatchNum]!.id,
          );
        }
      }
    }

    // Step 10: Assign participants to WB Round 1 and handle byes
    final r1Matches = wbMatchMap[1]!;
    final r1Count = r1Matches.length;
    final byeCount = bracketSize - n;
    var pIdx = 0;
    for (var m = 1; m <= r1Count; m++) {
      String? redId;
      String? blueId;
      if (m <= byeCount) {
        if (pIdx < n) redId = participantIds[pIdx++];
      } else {
        if (pIdx < n) redId = participantIds[pIdx++];
        if (pIdx < n) blueId = participantIds[pIdx++];
      }

      var match = r1Matches[m]!;
      match = match.copyWith(
        participantRedId: redId,
        participantBlueId: blueId,
      );

      if (redId != null && blueId == null) {
        match = match.copyWith(
          status: MatchStatus.completed,
          resultType: MatchResultType.bye,
          completedAtTimestamp: now,
          winnerId: redId,
          loserAdvancesToMatchId: null, // Bye has no loser
        );
      }
      r1Matches[m] = match;
    }

    // Step 11: Advance bye winners in Winners Bracket
    if (wRounds >= 2) {
      final r1Matches = wbMatchMap[1]!;
      final r1Count = r1Matches.length;
      for (var m = 1; m <= r1Count; m++) {
        final match = r1Matches[m]!;
        if (match.resultType == MatchResultType.bye &&
            match.winnerId != null) {
          final nextMatchNum = (m + 1) ~/ 2;
          var nextMatch = wbMatchMap[2]![nextMatchNum]!;
          if (m % 2 != 0) {
            nextMatch = nextMatch.copyWith(participantRedId: match.winnerId);
          } else {
            nextMatch = nextMatch.copyWith(participantBlueId: match.winnerId);
          }
          wbMatchMap[2]![nextMatchNum] = nextMatch;
        }
      }
    }

    // Flatten matches
    final allMatches = <MatchEntity>[];
    for (final roundMatches in wbMatchMap.values) {
      allMatches.addAll(roundMatches.values);
    }
    for (final roundMatches in lbMatchMap.values) {
      allMatches.addAll(roundMatches.values);
    }
    allMatches.add(grandFinalsMatch);
    if (resetMatch != null) {
      allMatches.add(resetMatch);
    }

    return DoubleEliminationBracketGenerationResult(
      winnersBracket: winnersBracket,
      losersBracket: losersBracket,
      grandFinalsMatch: grandFinalsMatch,
      resetMatch: resetMatch,
      allMatches: allMatches,
    );
  }
}
