import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/features/bracket/data/services/double_elimination_bracket_generator_service_implementation.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:uuid/uuid.dart';

class MockUuid extends Mock implements Uuid {}

void main() {
  late DoubleEliminationBracketGeneratorServiceImplementation generator;
  late MockUuid mockUuid;
  var uuidCounter = 0;

  setUp(() {
    mockUuid = MockUuid();
    uuidCounter = 0;
    generator = DoubleEliminationBracketGeneratorServiceImplementation(
      mockUuid,
    );

    when(() => mockUuid.v4()).thenAnswer((_) => 'match-${uuidCounter++}');
  });

  List<String> makeParticipants(int count) =>
      List.generate(count, (i) => 'p${i + 1}');

  group('DoubleEliminationBracketGeneratorServiceImplementation', () {
    test('should set bracket entities correctly', () {
      final result = generator.generate(
        divisionId: 'div-1',
        participantIds: makeParticipants(4),
        winnersBracketId: 'wb-1',
        losersBracketId: 'lb-1',
      );

      expect(result.winnersBracket.id, 'wb-1');
      expect(result.winnersBracket.bracketType, BracketType.winners);
      expect(result.winnersBracket.totalRounds, 2);

      expect(result.losersBracket.id, 'lb-1');
      expect(result.losersBracket.bracketType, BracketType.losers);
      expect(result.losersBracket.totalRounds, 2); // 2 * (2-1)
    });

    test('should create correct number of rounds for various N', () {
      final cases = {
        2: [1, 0, 3], // wRounds, lRounds, totalMatches (includeResetMatch=true)
        3: [2, 2, 7],
        4: [2, 2, 7],
        5: [3, 4, 15], // bracketSize 8 -> 2*8 - 2 + 1 = 15
        8: [3, 4, 15],
        16: [4, 6, 31], // 2*16 - 2 + 1 = 31
      };

      cases.forEach((n, expected) {
        final result = generator.generate(
          divisionId: 'div-1',
          participantIds: makeParticipants(n),
          winnersBracketId: 'wb',
          losersBracketId: 'lb',
        );

        expect(
          result.winnersBracket.totalRounds,
          expected[0],
          reason: 'n=$n wRounds',
        );
        expect(
          result.losersBracket.totalRounds,
          expected[1],
          reason: 'n=$n lRounds',
        );
        expect(
          result.allMatches.length,
          expected[2],
          reason: 'n=$n totalMatches',
        );
      });
    });

    test('should link all winners to correct next match in WB', () {
      final result = generator.generate(
        divisionId: 'div-1',
        participantIds: makeParticipants(4),
        winnersBracketId: 'wb',
        losersBracketId: 'lb',
      );

      final m1 = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'wb' &&
            m.roundNumber == 1 &&
            m.matchNumberInRound == 1,
      );
      final m2 = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'wb' &&
            m.roundNumber == 1 &&
            m.matchNumberInRound == 2,
      );
      final m3 = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'wb' &&
            m.roundNumber == 2 &&
            m.matchNumberInRound == 1,
      );

      expect(m1.winnerAdvancesToMatchId, m3.id);
      expect(m2.winnerAdvancesToMatchId, m3.id);
    });

    test('should route winners final champ to grand finals', () {
      final result = generator.generate(
        divisionId: 'div-1',
        participantIds: makeParticipants(4),
        winnersBracketId: 'wb',
        losersBracketId: 'lb',
      );

      final winnersFinal = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'wb' &&
            m.roundNumber == 2 &&
            m.matchNumberInRound == 1,
      );

      expect(winnersFinal.winnerAdvancesToMatchId, result.grandFinalsMatch.id);
    });

    test('should route losers final champ to grand finals', () {
      final result = generator.generate(
        divisionId: 'div-1',
        participantIds: makeParticipants(4),
        winnersBracketId: 'wb',
        losersBracketId: 'lb',
      );

      final losersFinal = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'lb' &&
            m.roundNumber == 2 &&
            m.matchNumberInRound == 1,
      );

      expect(losersFinal.winnerAdvancesToMatchId, result.grandFinalsMatch.id);
    });

    test('should connect grand finals to reset match when enabled', () {
      final result = generator.generate(
        divisionId: 'div-1',
        participantIds: makeParticipants(4),
        winnersBracketId: 'wb',
        losersBracketId: 'lb',
        includeResetMatch: true,
      );

      expect(result.resetMatch, isNotNull);
      expect(
        result.grandFinalsMatch.winnerAdvancesToMatchId,
        result.resetMatch!.id,
      );
    });

    test('should not have reset match when disabled', () {
      final result = generator.generate(
        divisionId: 'div-1',
        participantIds: makeParticipants(4),
        winnersBracketId: 'wb',
        losersBracketId: 'lb',
        includeResetMatch: false,
      );

      expect(result.resetMatch, isNull);
      expect(result.grandFinalsMatch.winnerAdvancesToMatchId, isNull);
    });

    test('should route losers of WB Round 1 to LB Round 1', () {
      final result = generator.generate(
        divisionId: 'div-1',
        participantIds: makeParticipants(4),
        winnersBracketId: 'wb',
        losersBracketId: 'lb',
      );

      final wbR1M1 = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'wb' &&
            m.roundNumber == 1 &&
            m.matchNumberInRound == 1,
      );

      final lbR1M1 = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'lb' &&
            m.roundNumber == 1 &&
            m.matchNumberInRound == 1,
      );

      expect(wbR1M1.loserAdvancesToMatchId, lbR1M1.id);
    });

    test('should route losers of WB Round 2 to LB Round 2', () {
      final result = generator.generate(
        divisionId: 'div-1',
        participantIds: makeParticipants(4),
        winnersBracketId: 'wb',
        losersBracketId: 'lb',
      );

      final winnersFinal = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'wb' &&
            m.roundNumber == 2 &&
            m.matchNumberInRound == 1,
      );

      final lbR2M1 = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'lb' &&
            m.roundNumber == 2 &&
            m.matchNumberInRound == 1,
      );

      expect(winnersFinal.loserAdvancesToMatchId, lbR2M1.id);
    });

    test('should handle byes correctly for winners round 1', () {
      // 3 participants -> 1 bye
      final result = generator.generate(
        divisionId: 'div-1',
        participantIds: makeParticipants(3),
        winnersBracketId: 'wb',
        losersBracketId: 'lb',
      );

      final m1 = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'wb' &&
            m.roundNumber == 1 &&
            m.matchNumberInRound == 1,
      );
      final m2 = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'wb' &&
            m.roundNumber == 1 &&
            m.matchNumberInRound == 2,
      );

      expect(m1.resultType, MatchResultType.bye);
      expect(m1.status, MatchStatus.completed);
      expect(m1.winnerId, 'p1');
      expect(m1.loserAdvancesToMatchId, isNull);

      expect(m2.resultType, isNull);
      expect(m2.participantRedId, 'p2');
      expect(m2.participantBlueId, 'p3');
    });

    test('should advance bye winner to Round 2', () {
      final result = generator.generate(
        divisionId: 'div-1',
        participantIds: makeParticipants(3),
        winnersBracketId: 'wb',
        losersBracketId: 'lb',
      );

      final m3 = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'wb' &&
            m.roundNumber == 2 &&
            m.matchNumberInRound == 1,
      );

      expect(m3.participantRedId, 'p1');
    });

    test('should handle n=2 edge case', () {
      final result = generator.generate(
        divisionId: 'div-1',
        participantIds: makeParticipants(2),
        winnersBracketId: 'wb',
        losersBracketId: 'lb',
      );

      expect(result.winnersBracket.totalRounds, 1);
      expect(result.losersBracket.totalRounds, 0);
      expect(result.allMatches.length, 3); // 1 WB, 1 GF, 1 Reset

      final wbMatch = result.allMatches.firstWhere(
        (m) => m.bracketId == 'wb' && m.roundNumber == 1,
      );

      expect(wbMatch.winnerAdvancesToMatchId, result.grandFinalsMatch.id);
      expect(wbMatch.loserAdvancesToMatchId, result.grandFinalsMatch.id);
    });

    test('should throw ArgumentError for less than 2 participants', () {
      expect(
        () => generator.generate(
          divisionId: 'div-1',
          participantIds: ['p1'],
          winnersBracketId: 'wb',
          losersBracketId: 'lb',
        ),
        throwsArgumentError,
      );
    });

    test('should link LB winners to correct next LB match', () {
      final result = generator.generate(
        divisionId: 'div-1',
        participantIds: makeParticipants(8),
        winnersBracketId: 'wb',
        losersBracketId: 'lb',
      );

      // LB R1 (odd/elimination) → LB R2 (even/drop-down): same index
      final lbR1M1 = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'lb' &&
            m.roundNumber == 1 &&
            m.matchNumberInRound == 1,
      );
      final lbR2M1 = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'lb' &&
            m.roundNumber == 2 &&
            m.matchNumberInRound == 1,
      );
      expect(lbR1M1.winnerAdvancesToMatchId, lbR2M1.id);

      // LB R2 (even/drop-down) → LB R3 (odd/elimination): ceil(m/2)
      final lbR3M1 = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'lb' &&
            m.roundNumber == 3 &&
            m.matchNumberInRound == 1,
      );
      expect(lbR2M1.winnerAdvancesToMatchId, lbR3M1.id);
    });

    test('should set correct metadata on both brackets (AC#12)', () {
      final result = generator.generate(
        divisionId: 'div-1',
        participantIds: makeParticipants(8),
        winnersBracketId: 'wb',
        losersBracketId: 'lb',
      );

      // isFinalized defaults to false
      expect(result.winnersBracket.isFinalized, isFalse);
      expect(result.losersBracket.isFinalized, isFalse);

      // generatedAtTimestamp is set
      expect(result.winnersBracket.generatedAtTimestamp, isNotNull);
      expect(result.losersBracket.generatedAtTimestamp, isNotNull);

      // bracketDataJson contains required keys
      final wbJson = result.winnersBracket.bracketDataJson!;
      expect(wbJson['doubleElimination'], isTrue);
      expect(wbJson['participantCount'], 8);
      expect(wbJson['includeResetMatch'], isTrue);

      final lbJson = result.losersBracket.bracketDataJson!;
      expect(lbJson['doubleElimination'], isTrue);
      expect(lbJson['participantCount'], 8);
      expect(lbJson['includeResetMatch'], isTrue);
    });

    test('GF roundNumber should be wRounds+1 and reset wRounds+2', () {
      final result = generator.generate(
        divisionId: 'div-1',
        participantIds: makeParticipants(8),
        winnersBracketId: 'wb',
        losersBracketId: 'lb',
      );

      // wRounds for 8 participants = 3
      expect(result.grandFinalsMatch.roundNumber, 4); // 3+1
      expect(result.resetMatch!.roundNumber, 5); // 3+2
    });

    test('drop-down routing should use reverse order for fairness', () {
      final result = generator.generate(
        divisionId: 'div-1',
        participantIds: makeParticipants(8),
        winnersBracketId: 'wb',
        losersBracketId: 'lb',
      );

      // WB R2 has 2 matches, LB R2 (drop-down) has 2 matches
      // WB R2 M1 loser → LB R2 M2 (reverse)
      // WB R2 M2 loser → LB R2 M1 (reverse)
      final wbR2M1 = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'wb' &&
            m.roundNumber == 2 &&
            m.matchNumberInRound == 1,
      );
      final wbR2M2 = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'wb' &&
            m.roundNumber == 2 &&
            m.matchNumberInRound == 2,
      );
      final lbR2M1 = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'lb' &&
            m.roundNumber == 2 &&
            m.matchNumberInRound == 1,
      );
      final lbR2M2 = result.allMatches.firstWhere(
        (m) =>
            m.bracketId == 'lb' &&
            m.roundNumber == 2 &&
            m.matchNumberInRound == 2,
      );

      // Reversed: M1→M2, M2→M1
      expect(wbR2M1.loserAdvancesToMatchId, lbR2M2.id);
      expect(wbR2M2.loserAdvancesToMatchId, lbR2M1.id);
    });
  });
}
