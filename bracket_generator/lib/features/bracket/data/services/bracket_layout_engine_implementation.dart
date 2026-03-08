import 'dart:math';
import 'dart:ui' show Offset, Size;

import 'package:injectable/injectable.dart';
import 'package:bracket_generator/features/bracket/domain/entities/bracket_entity.dart';
import 'package:bracket_generator/features/bracket/domain/entities/bracket_layout.dart';
import 'package:bracket_generator/features/bracket/domain/entities/match_entity.dart';
import 'package:bracket_generator/features/bracket/domain/services/bracket_layout_engine.dart';

@LazySingleton(as: BracketLayoutEngine)
class BracketLayoutEngineImplementation implements BracketLayoutEngine {
  @override
  BracketLayout calculateLayout({
    required BracketEntity bracket,
    required List<MatchEntity> matches,
    required BracketLayoutOptions options,
  }) {
    if (matches.isEmpty) {
      return BracketLayout(
        format: _getFormat(bracket, matches),
        rounds: const [],
        canvasSize: Size.zero,
      );
    }

    final format = _getFormat(bracket, matches);

    return switch (format) {
      BracketFormat.roundRobin => _calculateRoundRobinLayout(),
      BracketFormat.doubleElimination => _calculateDoubleEliminationLayout(
        bracket,
        matches,
        options,
      ),
      BracketFormat.singleElimination => _calculateSingleEliminationLayout(
        bracket,
        matches,
        options,
      ),
    };
  }

  BracketFormat _getFormat(BracketEntity bracket, List<MatchEntity> matches) {
    if (bracket.bracketType == BracketType.pool) {
      return BracketFormat.roundRobin;
    }
    final hasLoserAdvances = matches.any(
      (m) => m.loserAdvancesToMatchId != null,
    );
    if (hasLoserAdvances) {
      return BracketFormat.doubleElimination;
    }
    return BracketFormat.singleElimination;
  }

  BracketLayout _calculateSingleEliminationLayout(
    BracketEntity bracket,
    List<MatchEntity> matches,
    BracketLayoutOptions options,
  ) {
    return _calculateBranchLayout(
      matches: matches,
      options: options,
      totalRounds: bracket.totalRounds,
      format: BracketFormat.singleElimination,
    );
  }

  BracketLayout _calculateBranchLayout({
    required List<MatchEntity> matches,
    required BracketLayoutOptions options,
    required int totalRounds,
    required BracketFormat format,
    double yOffset = 0,
    double xOffset = 0,
  }) {
    final matchMap = <String, MatchSlot>{};

    // Group matches by round
    final matchesByRound = <int, List<MatchEntity>>{};
    for (final match in matches) {
      matchesByRound.putIfAbsent(match.roundNumber, () => []).add(match);
    }

    // Sort matches in each round by matchNumberInRound
    for (final roundMatches in matchesByRound.values) {
      roundMatches.sort(
        (a, b) => a.matchNumberInRound.compareTo(b.matchNumberInRound),
      );
    }

    // Calculate layout round by round
    final rounds = <BracketRound>[];
    for (var r = 1; r <= totalRounds; r++) {
      final roundMatches = matchesByRound[r] ?? [];
      final xPos =
          xOffset +
          (r - 1) * (options.matchCardWidth + options.horizontalSpacing);
      final slots = <MatchSlot>[];

      for (var i = 0; i < roundMatches.length; i++) {
        final match = roundMatches[i];
        double yPos;

        if (r == 1) {
          yPos =
              yOffset + i * (options.matchCardHeight + options.verticalSpacing);
        } else {
          // Subsequent rounds: Center between feeding matches
          final feedingMatches =
              matchesByRound[r - 1]
                  ?.where((m) => m.winnerAdvancesToMatchId == match.id)
                  .toList() ??
              [];

          if (feedingMatches.length == 2) {
            final slot1 = matchMap[feedingMatches[0].id]!;
            final slot2 = matchMap[feedingMatches[1].id]!;
            yPos = (slot1.position.dy + slot2.position.dy) / 2;
          } else if (feedingMatches.length == 1) {
            yPos = matchMap[feedingMatches[0].id]!.position.dy;
          } else {
            yPos =
                yOffset +
                i *
                    (options.matchCardHeight + options.verticalSpacing) *
                    pow(2, r - 1);
          }
        }

        final slot = MatchSlot(
          matchId: match.id,
          position: Offset(xPos, yPos),
          size: Size(options.matchCardWidth, options.matchCardHeight),
        );
        slots.add(slot);
        matchMap[match.id] = slot;
      }

      rounds.add(
        BracketRound(
          roundNumber: r,
          roundLabel: _getRoundLabel(r, totalRounds),
          matchSlots: slots,
          xPosition: xPos,
        ),
      );
    }

    // Link advancesToSlot
    final finalRounds = rounds.map((round) {
      final updatedSlots = round.matchSlots.map((slot) {
        final match = matches.firstWhere((m) => m.id == slot.matchId);
        if (match.winnerAdvancesToMatchId != null) {
          final targetSlot = matchMap[match.winnerAdvancesToMatchId];
          return MatchSlot(
            matchId: slot.matchId,
            position: slot.position,
            size: slot.size,
            advancesToSlot: targetSlot,
          );
        }
        return slot;
      }).toList();

      return BracketRound(
        roundNumber: round.roundNumber,
        roundLabel: round.roundLabel,
        matchSlots: updatedSlots,
        xPosition: round.xPosition,
      );
    }).toList();

    // Calculate canvas size per story spec formula
    final canvasWidth =
        totalRounds * (options.matchCardWidth + options.horizontalSpacing) +
        options.matchCardWidth;
    final firstRoundMatchCount = matchesByRound[1]?.length ?? 0;
    final canvasHeight =
        firstRoundMatchCount *
            (options.matchCardHeight + options.verticalSpacing) -
        options.verticalSpacing;

    return BracketLayout(
      format: format,
      rounds: finalRounds,
      canvasSize: Size(xOffset + canvasWidth, max(0, yOffset + canvasHeight)),
    );
  }

  BracketLayout _calculateDoubleEliminationLayout(
    BracketEntity bracket,
    List<MatchEntity> matches,
    BracketLayoutOptions options,
  ) {
    // Separate winners and losers matches.
    // Winners matches: those without loserAdvancesToMatchId pointing TO them
    // from a losers bracket. In practice, we identify losers matches as those
    // that are targets of loserAdvancesToMatchId from other matches.
    final loserTargetIds = <String>{};
    for (final m in matches) {
      if (m.loserAdvancesToMatchId != null) {
        loserTargetIds.add(m.loserAdvancesToMatchId!);
      }
    }

    // Build the losers tree: any match reachable from loserTargetIds
    final losersMatchIds = <String>{};
    final queue = loserTargetIds.toList();
    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      if (losersMatchIds.add(id)) {
        // Also follow winnerAdvancesToMatchId from losers matches
        final m = matches.where((match) => match.id == id).firstOrNull;
        if (m != null && m.winnerAdvancesToMatchId != null) {
          // Only follow if the target is also a losers match or grand finals
          queue.add(m.winnerAdvancesToMatchId!);
        }
      }
    }

    final winnersMatches = matches
        .where((m) => !losersMatchIds.contains(m.id))
        .toList();
    final losersMatches = matches
        .where((m) => losersMatchIds.contains(m.id))
        .toList();

    // Calculate winners layout
    final winnersLayout = _calculateBranchLayout(
      matches: winnersMatches,
      options: options,
      totalRounds: bracket.totalRounds,
      format: BracketFormat.doubleElimination,
    );

    if (losersMatches.isEmpty) {
      return winnersLayout;
    }

    // Calculate losers layout offset below winners
    final losersYOffset =
        winnersLayout.canvasSize.height + 2 * options.verticalSpacing;
    final losersTotalRounds = losersMatches.fold<int>(
      0,
      (maxR, m) => max(maxR, m.roundNumber),
    );

    final losersLayout = _calculateBranchLayout(
      matches: losersMatches,
      options: options,
      totalRounds: losersTotalRounds,
      format: BracketFormat.doubleElimination,
      yOffset: losersYOffset,
    );

    // Merge rounds
    final mergedRounds = <BracketRound>[
      ...winnersLayout.rounds,
      ...losersLayout.rounds,
    ];

    final totalWidth = max(
      winnersLayout.canvasSize.width,
      losersLayout.canvasSize.width,
    );
    final totalHeight = losersYOffset + losersLayout.canvasSize.height;

    return BracketLayout(
      format: BracketFormat.doubleElimination,
      rounds: mergedRounds,
      canvasSize: Size(totalWidth, totalHeight),
    );
  }

  BracketLayout _calculateRoundRobinLayout() {
    return const BracketLayout(
      format: BracketFormat.roundRobin,
      rounds: [],
      canvasSize: Size.zero,
    );
  }

  String _getRoundLabel(int roundNumber, int totalRounds) {
    final roundsFromEnd = totalRounds - roundNumber;
    return switch (roundsFromEnd) {
      0 => 'Finals',
      1 => 'Semifinals',
      2 => 'Quarterfinals',
      _ => 'Round $roundNumber',
    };
  }
}
