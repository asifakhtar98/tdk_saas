import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/features/bracket/data/services/single_elimination_bracket_generator_service_implementation.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:uuid/uuid.dart';

class MockUuid extends Mock implements Uuid {}

void main() {
  late SingleEliminationBracketGeneratorServiceImplementation generator;
  late MockUuid mockUuid;
  var uuidCounter = 0;

  setUp(() {
    mockUuid = MockUuid();
    uuidCounter = 0;
    generator =
        SingleEliminationBracketGeneratorServiceImplementation(mockUuid);

    when(() => mockUuid.v4()).thenAnswer(
      (_) => 'match-${uuidCounter++}',
    );
  });

  List<String> makeParticipants(int count) =>
      List.generate(count, (i) => 'p${i + 1}');

  group('SingleEliminationBracketGeneratorServiceImplementation', () {
    group('bracket structure - round count', () {
      test('should create 1 round for 2 participants', () {
        final result = generator.generate(
          divisionId: 'div-1',
          participantIds: makeParticipants(2),
          bracketId: 'bracket-1',
        );
        expect(result.bracket.totalRounds, 1);
        expect(result.matches.length, 1);
      });

      test('should create 2 rounds for 3 participants', () {
        final result = generator.generate(
          divisionId: 'div-1',
          participantIds: makeParticipants(3),
          bracketId: 'bracket-1',
        );
        expect(result.bracket.totalRounds, 2);
      });

      test('should create 2 rounds for 4 participants', () {
        final result = generator.generate(
          divisionId: 'div-1',
          participantIds: makeParticipants(4),
          bracketId: 'bracket-1',
        );
        expect(result.bracket.totalRounds, 2);
        expect(result.matches.length, 3);
      });

      test('should create 3 rounds for 5 participants', () {
        final result = generator.generate(
          divisionId: 'div-1',
          participantIds: makeParticipants(5),
          bracketId: 'bracket-1',
        );
        expect(result.bracket.totalRounds, 3);
        expect(result.matches.length, 7);
      });

      test('should create 3 rounds for 7 participants', () {
        final result = generator.generate(
          divisionId: 'div-1',
          participantIds: makeParticipants(7),
          bracketId: 'bracket-1',
        );
        expect(result.bracket.totalRounds, 3);
        expect(result.matches.length, 7);
      });

      test('should create 3 rounds for 8 participants', () {
        final result = generator.generate(
          divisionId: 'div-1',
          participantIds: makeParticipants(8),
          bracketId: 'bracket-1',
        );
        expect(result.bracket.totalRounds, 3);
        expect(result.matches.length, 7);
      });

      test('should create 4 rounds for 16 participants', () {
        final result = generator.generate(
          divisionId: 'div-1',
          participantIds: makeParticipants(16),
          bracketId: 'bracket-1',
        );
        expect(result.bracket.totalRounds, 4);
        expect(result.matches.length, 15);
      });

      test('should create 5 rounds for 32 participants', () {
        final result = generator.generate(
          divisionId: 'div-1',
          participantIds: makeParticipants(32),
          bracketId: 'bracket-1',
        );
        expect(result.bracket.totalRounds, 5);
        expect(result.matches.length, 31);
      });

      test('should create 6 rounds for 64 participants', () {
        final result = generator.generate(
          divisionId: 'div-1',
          participantIds: makeParticipants(64),
          bracketId: 'bracket-1',
        );
        expect(result.bracket.totalRounds, 6);
        expect(result.matches.length, 63);
      });
    });

    group('match tree linkage', () {
      test('should link all winners to correct next match', () {
        final result = generator.generate(
          divisionId: 'div-1',
          participantIds: makeParticipants(4),
          bracketId: 'bracket-1',
        );

        final m1 = result.matches.firstWhere(
          (m) => m.roundNumber == 1 && m.matchNumberInRound == 1,
        );
        final m2 = result.matches.firstWhere(
          (m) => m.roundNumber == 1 && m.matchNumberInRound == 2,
        );
        final m3 = result.matches.firstWhere(
          (m) => m.roundNumber == 2 && m.matchNumberInRound == 1,
        );

        expect(m1.winnerAdvancesToMatchId, m3.id);
        expect(m2.winnerAdvancesToMatchId, m3.id);
      });

      test(
        'should have null winnerAdvancesToMatchId for final',
        () {
          final result = generator.generate(
            divisionId: 'div-1',
            participantIds: makeParticipants(4),
            bracketId: 'bracket-1',
          );

          final finalMatch = result.matches.firstWhere(
            (m) =>
                m.roundNumber == result.bracket.totalRounds &&
                m.matchNumberInRound == 1,
          );

          expect(finalMatch.winnerAdvancesToMatchId, isNull);
        },
      );

      test(
        'should have correct match count: bracketSize - 1',
        () {
          // 8 participants → bracketSize 8 → 7 matches
          final result = generator.generate(
            divisionId: 'div-1',
            participantIds: makeParticipants(8),
            bracketId: 'bracket-1',
          );
          expect(result.matches.length, 7);

          // 5 participants → bracketSize 8 → 7 matches
          final result2 = generator.generate(
            divisionId: 'div-1',
            participantIds: makeParticipants(5),
            bracketId: 'bracket-2',
          );
          expect(result2.matches.length, 7);
        },
      );
    });

    group('bye handling', () {
      test(
        'should create 0 byes for power-of-2 participants',
        () {
          final result = generator.generate(
            divisionId: 'div-1',
            participantIds: makeParticipants(4),
            bracketId: 'bracket-1',
          );

          final byes = result.matches
              .where(
                (m) => m.resultType == MatchResultType.bye,
              )
              .toList();
          expect(byes.length, 0);
        },
      );

      test(
        'should create correct bye count: bracketSize - N',
        () {
          // 5 participants → bracketSize 8 → 3 byes
          final result = generator.generate(
            divisionId: 'div-1',
            participantIds: makeParticipants(5),
            bracketId: 'bracket-1',
          );

          final byes = result.matches
              .where(
                (m) => m.resultType == MatchResultType.bye,
              )
              .toList();
          expect(byes.length, 3);
        },
      );

      test(
        'should mark bye matches as completed with '
        'resultType bye',
        () {
          final result = generator.generate(
            divisionId: 'div-1',
            participantIds: makeParticipants(3),
            bracketId: 'bracket-1',
          );

          final byes = result.matches
              .where(
                (m) => m.resultType == MatchResultType.bye,
              )
              .toList();
          expect(byes.length, 1);

          final bye = byes.first;
          expect(bye.status, MatchStatus.completed);
          expect(bye.resultType, MatchResultType.bye);
          expect(bye.completedAtTimestamp, isNotNull);
        },
      );

      test('should set winnerId on bye matches', () {
        final result = generator.generate(
          divisionId: 'div-1',
          participantIds: makeParticipants(3),
          bracketId: 'bracket-1',
        );

        final bye = result.matches.firstWhere(
          (m) => m.resultType == MatchResultType.bye,
        );

        expect(bye.winnerId, isNotNull);
        expect(bye.winnerId, bye.participantRedId);
      });

      test(
        'should distribute byes evenly from top of bracket',
        () {
          // 5 participants → 3 byes → M1, M2, M3 are byes
          final result = generator.generate(
            divisionId: 'div-1',
            participantIds: makeParticipants(5),
            bracketId: 'bracket-1',
          );

          final r1 = result.matches
              .where((m) => m.roundNumber == 1)
              .toList()
            ..sort(
              (a, b) => a.matchNumberInRound
                  .compareTo(b.matchNumberInRound),
            );

          // First 3 matches should be byes
          expect(r1[0].resultType, MatchResultType.bye);
          expect(r1[1].resultType, MatchResultType.bye);
          expect(r1[2].resultType, MatchResultType.bye);
          // Last match is a normal match
          expect(r1[3].resultType, isNull);
        },
      );

      test('should advance bye winner to Round 2', () {
        final result = generator.generate(
          divisionId: 'div-1',
          participantIds: makeParticipants(3),
          bracketId: 'bracket-1',
        );

        final m1 = result.matches.firstWhere(
          (m) =>
              m.roundNumber == 1 && m.matchNumberInRound == 1,
        );
        final m3 = result.matches.firstWhere(
          (m) =>
              m.roundNumber == 2 && m.matchNumberInRound == 1,
        );

        expect(m1.winnerId, 'p1');
        expect(m3.participantRedId, 'p1');
      });
    });

    group('3rd-place match', () {
      test(
        'should create 3rd-place match when configured',
        () {
          final result = generator.generate(
            divisionId: 'div-1',
            participantIds: makeParticipants(4),
            bracketId: 'bracket-1',
            includeThirdPlaceMatch: true,
          );

          // 3 bracket matches + 1 third-place = 4
          expect(result.matches.length, 4);

          final third = result.matches.firstWhere(
            (m) =>
                m.roundNumber == 2 &&
                m.matchNumberInRound == 2,
          );
          expect(third, isNotNull);
        },
      );

      test(
        'should link semifinal losers to 3rd-place match',
        () {
          final result = generator.generate(
            divisionId: 'div-1',
            participantIds: makeParticipants(4),
            bracketId: 'bracket-1',
            includeThirdPlaceMatch: true,
          );

          final semi1 = result.matches.firstWhere(
            (m) =>
                m.roundNumber == 1 &&
                m.matchNumberInRound == 1,
          );
          final semi2 = result.matches.firstWhere(
            (m) =>
                m.roundNumber == 1 &&
                m.matchNumberInRound == 2,
          );
          final thirdPlace = result.matches.firstWhere(
            (m) =>
                m.roundNumber == 2 &&
                m.matchNumberInRound == 2,
          );

          expect(
            semi1.loserAdvancesToMatchId,
            thirdPlace.id,
          );
          expect(
            semi2.loserAdvancesToMatchId,
            thirdPlace.id,
          );
        },
      );

      test(
        'should not create 3rd-place match by default',
        () {
          final result = generator.generate(
            divisionId: 'div-1',
            participantIds: makeParticipants(4),
            bracketId: 'bracket-1',
          );

          // Only 3 bracket matches, no 3rd-place
          expect(result.matches.length, 3);

          final thirdPlaces = result.matches.where(
            (m) =>
                m.roundNumber == 2 &&
                m.matchNumberInRound == 2,
          );
          expect(thirdPlaces, isEmpty);
        },
      );

      test(
        'should not create 3rd-place match for '
        '2-participant bracket',
        () {
          final result = generator.generate(
            divisionId: 'div-1',
            participantIds: makeParticipants(2),
            bracketId: 'bracket-1',
            includeThirdPlaceMatch: true,
          );

          // Only 1 match (the final), no 3rd-place
          // because totalRounds < 2
          expect(result.matches.length, 1);
        },
      );
    });

    group('bracket entity', () {
      test('should set bracket fields correctly', () {
        final result = generator.generate(
          divisionId: 'div-1',
          participantIds: makeParticipants(4),
          bracketId: 'bracket-1',
        );

        expect(result.bracket.id, 'bracket-1');
        expect(result.bracket.divisionId, 'div-1');
        expect(result.bracket.bracketType, BracketType.winners);
        expect(result.bracket.isFinalized, isFalse);
        expect(
          result.bracket.generatedAtTimestamp,
          isNotNull,
        );
        expect(
          result.bracket.bracketDataJson?['participantCount'],
          4,
        );
      });
    });

    group('participant assignment', () {
      test('should assign 2 participants to single match', () {
        final result = generator.generate(
          divisionId: 'div-1',
          participantIds: ['p1', 'p2'],
          bracketId: 'bracket-1',
        );

        final match = result.matches.first;
        expect(match.participantRedId, 'p1');
        expect(match.participantBlueId, 'p2');
        expect(match.winnerAdvancesToMatchId, isNull);
      });
    });
  });
}
