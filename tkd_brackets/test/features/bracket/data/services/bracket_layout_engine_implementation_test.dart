import 'dart:math';
import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/features/bracket/data/services/bracket_layout_engine_implementation.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_layout.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';

class MockBracketEntity extends Mock implements BracketEntity {}

class MockMatchEntity extends Mock implements MatchEntity {}

void main() {
  late BracketLayoutEngineImplementation engine;
  late BracketLayoutOptions options;

  setUp(() {
    engine = BracketLayoutEngineImplementation();
    options = const BracketLayoutOptions(
      matchCardWidth: 200,
      matchCardHeight: 80,
      horizontalSpacing: 50,
      verticalSpacing: 20,
    );
  });

  MockMatchEntity makeMatch(
    String id, {
    required int roundNumber,
    required int matchNumberInRound,
    String? winnerAdvancesToMatchId,
    String? loserAdvancesToMatchId,
  }) {
    final m = MockMatchEntity();
    when(() => m.id).thenReturn(id);
    when(() => m.roundNumber).thenReturn(roundNumber);
    when(() => m.matchNumberInRound).thenReturn(matchNumberInRound);
    when(() => m.winnerAdvancesToMatchId).thenReturn(winnerAdvancesToMatchId);
    when(() => m.loserAdvancesToMatchId).thenReturn(loserAdvancesToMatchId);
    return m;
  }

  MockBracketEntity makeBracket({
    required int totalRounds,
    String id = 'b1',
    BracketType type = BracketType.winners,
  }) {
    final bracket = MockBracketEntity();
    when(() => bracket.id).thenReturn(id);
    when(() => bracket.bracketType).thenReturn(type);
    when(() => bracket.totalRounds).thenReturn(totalRounds);
    return bracket;
  }

  group('BracketLayoutEngine - Empty', () {
    test('should return empty layout for empty matches', () {
      final bracket = makeBracket(totalRounds: 2);

      final layout = engine.calculateLayout(
        bracket: bracket,
        matches: [],
        options: options,
      );

      expect(layout.rounds, isEmpty);
      expect(layout.canvasSize, Size.zero);
    });
  });

  group('BracketLayoutEngine - Single Elimination', () {
    test('should calculate layout for 2 players (1 round, 1 match)', () {
      final bracket = makeBracket(totalRounds: 1);
      final match = makeMatch('m1', roundNumber: 1, matchNumberInRound: 1);

      final layout = engine.calculateLayout(
        bracket: bracket,
        matches: [match],
        options: options,
      );

      expect(layout.format, BracketFormat.singleElimination);
      expect(layout.rounds.length, 1);
      expect(layout.rounds[0].matchSlots.length, 1);
      expect(layout.rounds[0].matchSlots[0].position.dx, 0);
      expect(layout.rounds[0].matchSlots[0].position.dy, 0);
      // Canvas: 1 * (200 + 50) + 200 = 450 width, 1 * (80 + 20) - 20 = 80 height
      expect(layout.canvasSize.width, 450);
      expect(layout.canvasSize.height, 80);
    });

    test('should calculate layout for 4 players (2 rounds, 3 matches)', () {
      final bracket = makeBracket(totalRounds: 2);
      final matches = [
        makeMatch(
          'm1',
          roundNumber: 1,
          matchNumberInRound: 1,
          winnerAdvancesToMatchId: 'm3',
        ),
        makeMatch(
          'm2',
          roundNumber: 1,
          matchNumberInRound: 2,
          winnerAdvancesToMatchId: 'm3',
        ),
        makeMatch('m3', roundNumber: 2, matchNumberInRound: 1),
      ];

      final layout = engine.calculateLayout(
        bracket: bracket,
        matches: matches,
        options: options,
      );

      expect(layout.rounds.length, 2);
      expect(layout.rounds[0].matchSlots.length, 2);
      expect(layout.rounds[1].matchSlots.length, 1);
      expect(layout.rounds[1].roundLabel, 'Finals');
      expect(layout.rounds[0].roundLabel, 'Semifinals');
    });

    test('should calculate layout for 8 players (3 rounds, 7 matches)', () {
      final bracket = makeBracket(totalRounds: 3);

      final matches = <MatchEntity>[];
      for (var i = 1; i <= 4; i++) {
        matches.add(
          makeMatch(
            'm1_$i',
            roundNumber: 1,
            matchNumberInRound: i,
            winnerAdvancesToMatchId: 'm2_${(i + 1) ~/ 2}',
          ),
        );
      }
      for (var i = 1; i <= 2; i++) {
        matches.add(
          makeMatch(
            'm2_$i',
            roundNumber: 2,
            matchNumberInRound: i,
            winnerAdvancesToMatchId: 'm3_1',
          ),
        );
      }
      matches.add(makeMatch('m3_1', roundNumber: 3, matchNumberInRound: 1));

      final layout = engine.calculateLayout(
        bracket: bracket,
        matches: matches,
        options: options,
      );

      expect(layout.rounds.length, 3);
      expect(layout.rounds[2].roundLabel, 'Finals');
      expect(layout.rounds[1].roundLabel, 'Semifinals');
      expect(layout.rounds[0].roundLabel, 'Quarterfinals');

      // Canvas: 3 * (200 + 50) + 200 = 950 width
      expect(layout.canvasSize.width, 950);
      // Height: 4 * (80 + 20) - 20 = 380
      expect(layout.canvasSize.height, 380);
    });

    test('should calculate layout for 16 players (4 rounds, 15 matches)', () {
      final bracket = makeBracket(totalRounds: 4);

      final matches = <MatchEntity>[];
      for (var r = 1; r <= 4; r++) {
        final count = pow(2, 4 - r).toInt();
        for (var i = 1; i <= count; i++) {
          matches.add(
            makeMatch(
              'm${r}_$i',
              roundNumber: r,
              matchNumberInRound: i,
              winnerAdvancesToMatchId: r < 4
                  ? 'm${r + 1}_${(i + 1) ~/ 2}'
                  : null,
            ),
          );
        }
      }

      final layout = engine.calculateLayout(
        bracket: bracket,
        matches: matches,
        options: options,
      );

      expect(layout.rounds.length, 4);
      expect(layout.rounds[3].roundLabel, 'Finals');
      expect(layout.rounds[2].roundLabel, 'Semifinals');
      expect(layout.rounds[1].roundLabel, 'Quarterfinals');
      expect(layout.rounds[0].roundLabel, 'Round 1');

      // Canvas: 4 * (200 + 50) + 200 = 1200 width
      expect(layout.canvasSize.width, 1200);
      // Height: 8 * (80 + 20) - 20 = 780
      expect(layout.canvasSize.height, 780);
    });

    test('should link advancesToSlot correctly', () {
      final bracket = makeBracket(totalRounds: 2);
      final matches = [
        makeMatch(
          'm1',
          roundNumber: 1,
          matchNumberInRound: 1,
          winnerAdvancesToMatchId: 'm3',
        ),
        makeMatch(
          'm2',
          roundNumber: 1,
          matchNumberInRound: 2,
          winnerAdvancesToMatchId: 'm3',
        ),
        makeMatch('m3', roundNumber: 2, matchNumberInRound: 1),
      ];

      final layout = engine.calculateLayout(
        bracket: bracket,
        matches: matches,
        options: options,
      );

      // Round 1 slots should advance to round 2 slot
      final r1Slot1 = layout.rounds[0].matchSlots[0];
      final r1Slot2 = layout.rounds[0].matchSlots[1];
      final finalsSlot = layout.rounds[1].matchSlots[0];

      expect(r1Slot1.advancesToSlot, isNotNull);
      expect(r1Slot1.advancesToSlot!.matchId, 'm3');
      expect(r1Slot2.advancesToSlot, isNotNull);
      expect(r1Slot2.advancesToSlot!.matchId, 'm3');
      expect(finalsSlot.advancesToSlot, isNull);
    });

    test('should assign correct round labels', () {
      final bracket = makeBracket(totalRounds: 5);

      final matches = <MatchEntity>[];
      for (var r = 1; r <= 5; r++) {
        matches.add(
          makeMatch('m${r}_1', roundNumber: r, matchNumberInRound: 1),
        );
      }

      final layout = engine.calculateLayout(
        bracket: bracket,
        matches: matches,
        options: options,
      );

      expect(layout.rounds[0].roundLabel, 'Round 1');
      expect(layout.rounds[1].roundLabel, 'Round 2');
      expect(layout.rounds[2].roundLabel, 'Quarterfinals');
      expect(layout.rounds[3].roundLabel, 'Semifinals');
      expect(layout.rounds[4].roundLabel, 'Finals');
    });
  });

  group('BracketLayoutEngine - Round Robin', () {
    test('should return flat grid layout for round robin', () {
      final bracket = makeBracket(type: BracketType.pool, totalRounds: 1);
      final match = makeMatch('m1', roundNumber: 1, matchNumberInRound: 1);
      when(() => match.loserAdvancesToMatchId).thenReturn(null);

      final layout = engine.calculateLayout(
        bracket: bracket,
        matches: [match],
        options: options,
      );

      expect(layout.format, BracketFormat.roundRobin);
      expect(layout.rounds, isEmpty);
      expect(layout.canvasSize, Size.zero);
    });
  });

  group('BracketLayoutEngine - Double Elimination', () {
    test('should detect double elimination from loserAdvancesToMatchId', () {
      final bracket = makeBracket(totalRounds: 2);
      final matches = [
        makeMatch(
          'w1',
          roundNumber: 1,
          matchNumberInRound: 1,
          winnerAdvancesToMatchId: 'w3',
          loserAdvancesToMatchId: 'l1',
        ),
        makeMatch(
          'w2',
          roundNumber: 1,
          matchNumberInRound: 2,
          winnerAdvancesToMatchId: 'w3',
          loserAdvancesToMatchId: 'l1',
        ),
        makeMatch('w3', roundNumber: 2, matchNumberInRound: 1),
        makeMatch('l1', roundNumber: 1, matchNumberInRound: 1),
      ];

      final layout = engine.calculateLayout(
        bracket: bracket,
        matches: matches,
        options: options,
      );

      expect(layout.format, BracketFormat.doubleElimination);
      expect(layout.rounds.isNotEmpty, isTrue);
    });
  });
}
