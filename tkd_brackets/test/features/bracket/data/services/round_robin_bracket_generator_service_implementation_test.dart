import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/features/bracket/data/services/round_robin_bracket_generator_service_implementation.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:uuid/uuid.dart';

class MockUuid extends Mock implements Uuid {}

void main() {
  late RoundRobinBracketGeneratorServiceImplementation service;
  late MockUuid mockUuid;
  var uuidCounter = 0;

  setUp(() {
    mockUuid = MockUuid();
    uuidCounter = 0;
    when(() => mockUuid.v4()).thenAnswer(
      (_) => 'match-${uuidCounter++}',
    );
    service = RoundRobinBracketGeneratorServiceImplementation(mockUuid);
  });

  List<String> makeParticipants(int count) =>
      List.generate(count, (i) => 'p${i + 1}');

  group('RoundRobinBracketGeneratorServiceImplementation', () {
    // Helper: verify every pair of participants appears exactly once
    void verifyAllPairsCovered(
      List<MatchEntity> matches,
      List<String> participantIds,
    ) {
      final expectedPairs = <String>{};
      for (var i = 0; i < participantIds.length; i++) {
        for (var j = i + 1; j < participantIds.length; j++) {
          final pair = [participantIds[i], participantIds[j]]..sort();
          expectedPairs.add(pair.join('-'));
        }
      }

      final actualPairs = <String>{};
      for (final match in matches) {
        if (match.resultType != MatchResultType.bye &&
            match.participantRedId != null &&
            match.participantBlueId != null) {
          final pair = [match.participantRedId!, match.participantBlueId!]
              ..sort();
          actualPairs.add(pair.join('-'));
        }
      }

      expect(actualPairs, expectedPairs,
          reason: 'All participant pairs should be covered exactly once');
    }

    // Helper: verify no participant appears more than once per round
    void verifyNoDoubleBooking(List<MatchEntity> matches) {
      final roundParticipants = <int, Set<String>>{};
      for (final match in matches) {
        roundParticipants.putIfAbsent(match.roundNumber, () => {});
        if (match.participantRedId != null) {
          expect(
            roundParticipants[match.roundNumber]!.add(match.participantRedId!),
            isTrue,
            reason: 'Participant ${match.participantRedId} appears twice '
                'in round ${match.roundNumber}',
          );
        }
        if (match.participantBlueId != null) {
          expect(
            roundParticipants[match.roundNumber]!.add(match.participantBlueId!),
            isTrue,
            reason: 'Participant ${match.participantBlueId} appears twice '
                'in round ${match.roundNumber}',
          );
        }
      }
    }

    test('N=2: should generate 1 round and 1 match', () {
      final pIds = makeParticipants(2);
      final result = service.generate(
        divisionId: 'div-1',
        participantIds: pIds,
        bracketId: 'b-1',
      );

      expect(result.bracket.totalRounds, 1);
      expect(result.matches.length, 1);
      
      final m = result.matches.first;
      expect(m.roundNumber, 1);
      expect(m.matchNumberInRound, 1);
      expect(m.participantRedId, 'p1');
      expect(m.participantBlueId, 'p2');
      expect(m.status, MatchStatus.pending);
      expect(m.resultType, isNull);

      verifyAllPairsCovered(result.matches, pIds);
      verifyNoDoubleBooking(result.matches);
    });

    test('N=3: should generate 3 rounds with 1 bye each', () {
      final pIds = makeParticipants(3);
      final result = service.generate(
        divisionId: 'div-1',
        participantIds: pIds,
        bracketId: 'b-1',
      );

      // rounds = 3, match slots/round = 2. total match entities = 6.
      expect(result.bracket.totalRounds, 3);
      expect(result.matches.length, 6);

      final realMatches = result.matches.where((m) => m.resultType != MatchResultType.bye).toList();
      final byeMatches = result.matches.where((m) => m.resultType == MatchResultType.bye).toList();

      expect(realMatches.length, 3);
      expect(byeMatches.length, 3);

      for (final m in byeMatches) {
        expect(m.status, MatchStatus.completed);
        expect(m.winnerId, isNotNull);
        expect(m.winnerId, m.participantRedId);
        expect(m.participantBlueId, isNull);
        expect(m.completedAtTimestamp, isNotNull);
      }

      verifyAllPairsCovered(result.matches, pIds);
      verifyNoDoubleBooking(result.matches);
    });

    test('N=4: should generate 3 rounds and 6 matches', () {
      final pIds = makeParticipants(4);
      final result = service.generate(
        divisionId: 'div-1',
        participantIds: pIds,
        bracketId: 'b-1',
      );

      expect(result.bracket.totalRounds, 3);
      expect(result.matches.length, 6);

      verifyAllPairsCovered(result.matches, pIds);
      verifyNoDoubleBooking(result.matches);
    });

    test('N=5: should generate 5 rounds with 1 bye each', () {
      final pIds = makeParticipants(5);
      final result = service.generate(
        divisionId: 'div-1',
        participantIds: pIds,
        bracketId: 'b-1',
      );

      expect(result.bracket.totalRounds, 5);
      expect(result.matches.length, 15); // (5+1)/2 * 5

      final byeMatches = result.matches.where((m) => m.resultType == MatchResultType.bye).toList();
      expect(byeMatches.length, 5);

      verifyAllPairsCovered(result.matches, pIds);
      verifyNoDoubleBooking(result.matches);
    });

    test('N=6: should generate 5 rounds and 15 matches', () {
      final pIds = makeParticipants(6);
      final result = service.generate(
        divisionId: 'div-1',
        participantIds: pIds,
        bracketId: 'b-1',
      );

      expect(result.bracket.totalRounds, 5);
      expect(result.matches.length, 15);

      final byeMatches = result.matches
          .where((m) => m.resultType == MatchResultType.bye)
          .toList();
      expect(byeMatches.length, 0);

      verifyAllPairsCovered(result.matches, pIds);
      verifyNoDoubleBooking(result.matches);
    });

    test('N=7: should generate 7 rounds with 1 bye each', () {
      final pIds = makeParticipants(7);
      final result = service.generate(
        divisionId: 'div-1',
        participantIds: pIds,
        bracketId: 'b-1',
      );

      expect(result.bracket.totalRounds, 7);
      expect(result.matches.length, 28); // 21 real + 7 byes

      final realMatches = result.matches
          .where((m) => m.resultType != MatchResultType.bye)
          .toList();
      final byeMatches = result.matches
          .where((m) => m.resultType == MatchResultType.bye)
          .toList();

      expect(realMatches.length, 21);
      expect(byeMatches.length, 7);

      verifyAllPairsCovered(result.matches, pIds);
      verifyNoDoubleBooking(result.matches);
    });

    test('N=8: should generate 7 rounds and 28 matches', () {
      final pIds = makeParticipants(8);
      final result = service.generate(
        divisionId: 'div-1',
        participantIds: pIds,
        bracketId: 'b-1',
      );

      expect(result.bracket.totalRounds, 7);
      expect(result.matches.length, 28);

      final byeMatches = result.matches
          .where((m) => m.resultType == MatchResultType.bye)
          .toList();
      expect(byeMatches.length, 0);

      verifyAllPairsCovered(result.matches, pIds);
      verifyNoDoubleBooking(result.matches);
    });

    test('should set default poolIdentifier and metadata correctly', () {
      final pIds = makeParticipants(4);
      final result = service.generate(
        divisionId: 'div-1',
        participantIds: pIds,
        bracketId: 'b-1',
      );

      expect(result.bracket.poolIdentifier, 'A');
      expect(result.bracket.bracketType, BracketType.pool);
      expect(result.bracket.totalRounds, 3);
      expect(result.bracket.isFinalized, isFalse);
      expect(result.bracket.generatedAtTimestamp, isNotNull);
      expect(result.bracket.bracketDataJson?['roundRobin'], true);
      expect(result.bracket.bracketDataJson?['participantCount'], 4);
    });

    test('should assign correct 1-indexed roundNumber and matchNumberInRound', () {
      final pIds = makeParticipants(4);
      final result = service.generate(
        divisionId: 'div-1',
        participantIds: pIds,
        bracketId: 'b-1',
      );

      // 3 rounds, 2 matches per round
      for (var r = 1; r <= 3; r++) {
        final roundMatches =
            result.matches.where((m) => m.roundNumber == r).toList();
        expect(roundMatches.length, 2, reason: 'Round $r should have 2 matches');
        final matchNumbers =
            roundMatches.map((m) => m.matchNumberInRound).toSet();
        expect(matchNumbers, {1, 2},
            reason: 'Round $r should have match numbers 1 and 2');
      }
    });

    test('should ensure winnerAdvancesToMatchId and loserAdvancesToMatchId are null', () {
      final pIds = makeParticipants(4);
      final result = service.generate(
        divisionId: 'div-1',
        participantIds: pIds,
        bracketId: 'b-1',
      );

      for (final m in result.matches) {
        expect(m.winnerAdvancesToMatchId, isNull);
        expect(m.loserAdvancesToMatchId, isNull);
      }
    });

    test('should use custom poolIdentifier', () {
      final pIds = makeParticipants(2);
      final result = service.generate(
        divisionId: 'div-1',
        participantIds: pIds,
        bracketId: 'b-1',
        poolIdentifier: 'B',
      );

      expect(result.bracket.poolIdentifier, 'B');
    });

    test('odd N: each participant should get exactly one bye', () {
      final pIds = makeParticipants(5);
      final result = service.generate(
        divisionId: 'div-1',
        participantIds: pIds,
        bracketId: 'b-1',
      );

      final byeMatches = result.matches
          .where((m) => m.resultType == MatchResultType.bye)
          .toList();

      // Each participant should appear as the bye recipient exactly once
      final byeRecipients = byeMatches.map((m) => m.participantRedId).toList();
      expect(byeRecipients.length, 5);
      expect(byeRecipients.toSet().length, 5,
          reason: 'Each of the 5 participants should get exactly 1 bye');
      for (final pId in pIds) {
        expect(byeRecipients.contains(pId), isTrue,
            reason: 'Participant $pId should have exactly one bye');
      }
    });
  });
}
