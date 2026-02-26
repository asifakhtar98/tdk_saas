import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';

void main() {
  final testDateTime = DateTime(2026, 1, 15, 10, 30);

  group('MatchStatus', () {
    test('fromString should return correct status or pending for unknown', () {
      expect(MatchStatus.fromString('pending'), MatchStatus.pending);
      expect(MatchStatus.fromString('ready'), MatchStatus.ready);
      expect(MatchStatus.fromString('in_progress'), MatchStatus.inProgress);
      expect(MatchStatus.fromString('completed'), MatchStatus.completed);
      expect(MatchStatus.fromString('cancelled'), MatchStatus.cancelled);
      expect(MatchStatus.fromString('unknown'), MatchStatus.pending);
    });

    test('value should return correct string', () {
      expect(MatchStatus.pending.value, 'pending');
      expect(MatchStatus.ready.value, 'ready');
      expect(MatchStatus.inProgress.value, 'in_progress');
      expect(MatchStatus.completed.value, 'completed');
      expect(MatchStatus.cancelled.value, 'cancelled');
    });
  });

  group('MatchResultType', () {
    test('fromString should return correct type or points for unknown', () {
      expect(MatchResultType.fromString('points'), MatchResultType.points);
      expect(MatchResultType.fromString('knockout'), MatchResultType.knockout);
      expect(
        MatchResultType.fromString('disqualification'),
        MatchResultType.disqualification,
      );
      expect(
        MatchResultType.fromString('withdrawal'),
        MatchResultType.withdrawal,
      );
      expect(
        MatchResultType.fromString('referee_decision'),
        MatchResultType.refereeDecision,
      );
      expect(MatchResultType.fromString('bye'), MatchResultType.bye);
      expect(MatchResultType.fromString('unknown'), MatchResultType.points);
    });

    test('value should return correct string', () {
      expect(MatchResultType.points.value, 'points');
      expect(MatchResultType.knockout.value, 'knockout');
      expect(MatchResultType.disqualification.value, 'disqualification');
      expect(MatchResultType.withdrawal.value, 'withdrawal');
      expect(MatchResultType.refereeDecision.value, 'referee_decision');
      expect(MatchResultType.bye.value, 'bye');
    });
  });

  group('MatchEntity', () {
    test('should support equality', () {
      final entity1 = MatchEntity(
        id: '1',
        bracketId: 'b1',
        roundNumber: 1,
        matchNumberInRound: 1,
        createdAtTimestamp: testDateTime,
        updatedAtTimestamp: testDateTime,
      );
      final entity2 = MatchEntity(
        id: '1',
        bracketId: 'b1',
        roundNumber: 1,
        matchNumberInRound: 1,
        createdAtTimestamp: testDateTime,
        updatedAtTimestamp: testDateTime,
      );

      expect(entity1, entity2);
    });

    test('should not be equal when fields differ', () {
      final entity1 = MatchEntity(
        id: '1',
        bracketId: 'b1',
        roundNumber: 1,
        matchNumberInRound: 1,
        createdAtTimestamp: testDateTime,
        updatedAtTimestamp: testDateTime,
      );
      final entity2 = MatchEntity(
        id: '2',
        bracketId: 'b1',
        roundNumber: 1,
        matchNumberInRound: 1,
        createdAtTimestamp: testDateTime,
        updatedAtTimestamp: testDateTime,
      );

      expect(entity1, isNot(entity2));
    });

    test('should have correct default values', () {
      final entity = MatchEntity(
        id: '1',
        bracketId: 'b1',
        roundNumber: 1,
        matchNumberInRound: 1,
        createdAtTimestamp: testDateTime,
        updatedAtTimestamp: testDateTime,
      );

      expect(entity.status, MatchStatus.pending);
      expect(entity.syncVersion, 1);
      expect(entity.isDeleted, isFalse);
      expect(entity.isDemoData, isFalse);
    });

    test('should allow optional fields', () {
      final entity = MatchEntity(
        id: '1',
        bracketId: 'b1',
        roundNumber: 1,
        matchNumberInRound: 1,
        participantRedId: 'p1',
        participantBlueId: 'p2',
        winnerId: 'p1',
        winnerAdvancesToMatchId: 'm2',
        loserAdvancesToMatchId: 'm3',
        scheduledRingNumber: 1,
        scheduledTime: testDateTime,
        status: MatchStatus.completed,
        resultType: MatchResultType.points,
        notes: 'notes',
        startedAtTimestamp: testDateTime,
        completedAtTimestamp: testDateTime,
        syncVersion: 2,
        isDeleted: true,
        deletedAtTimestamp: testDateTime,
        isDemoData: true,
        createdAtTimestamp: testDateTime,
        updatedAtTimestamp: testDateTime,
      );

      expect(entity.participantRedId, 'p1');
      expect(entity.participantBlueId, 'p2');
      expect(entity.winnerId, 'p1');
      expect(entity.winnerAdvancesToMatchId, 'm2');
      expect(entity.loserAdvancesToMatchId, 'm3');
      expect(entity.scheduledRingNumber, 1);
      expect(entity.scheduledTime, testDateTime);
      expect(entity.status, MatchStatus.completed);
      expect(entity.resultType, MatchResultType.points);
      expect(entity.notes, 'notes');
      expect(entity.startedAtTimestamp, testDateTime);
      expect(entity.completedAtTimestamp, testDateTime);
      expect(entity.syncVersion, 2);
      expect(entity.isDeleted, isTrue);
      expect(entity.deletedAtTimestamp, testDateTime);
      expect(entity.isDemoData, isTrue);
    });
  });
}
