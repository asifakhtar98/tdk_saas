import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';

void main() {
  group('BracketEntity', () {
    final now = DateTime.now();

    test('should support value equality', () {
      final b1 = BracketEntity(
        id: '1',
        divisionId: 'div1',
        bracketType: BracketType.winners,
        totalRounds: 3,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
      );

      final b2 = BracketEntity(
        id: '1',
        divisionId: 'div1',
        bracketType: BracketType.winners,
        totalRounds: 3,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
      );

      expect(b1, equals(b2));
    });

    test('should have correct default values', () {
      final entity = BracketEntity(
        id: '1',
        divisionId: 'div1',
        bracketType: BracketType.winners,
        totalRounds: 3,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
      );

      expect(entity.isFinalized, false);
      expect(entity.syncVersion, 1);
      expect(entity.isDeleted, false);
      expect(entity.isDemoData, false);
      expect(entity.poolIdentifier, isNull);
      expect(entity.generatedAtTimestamp, isNull);
      expect(entity.finalizedAtTimestamp, isNull);
      expect(entity.bracketDataJson, isNull);
      expect(entity.deletedAtTimestamp, isNull);
    });

    test('should create entity with optional fields', () {
      final generatedAt = DateTime(2026, 1, 20);
      final finalizedAt = DateTime(2026, 1, 21);
      final bracketData = {'matches': [], 'rounds': 3};

      final entity = BracketEntity(
        id: '1',
        divisionId: 'div1',
        bracketType: BracketType.pool,
        totalRounds: 2,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
        poolIdentifier: 'A',
        isFinalized: true,
        generatedAtTimestamp: generatedAt,
        finalizedAtTimestamp: finalizedAt,
        bracketDataJson: bracketData,
        syncVersion: 5,
        isDemoData: true,
      );

      expect(entity.poolIdentifier, 'A');
      expect(entity.isFinalized, true);
      expect(entity.generatedAtTimestamp, generatedAt);
      expect(entity.finalizedAtTimestamp, finalizedAt);
      expect(entity.bracketDataJson, bracketData);
      expect(entity.syncVersion, 5);
      expect(entity.isDemoData, true);
    });

    test('should not be equal when fields differ', () {
      final b1 = BracketEntity(
        id: '1',
        divisionId: 'div1',
        bracketType: BracketType.winners,
        totalRounds: 3,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
      );

      final b2 = BracketEntity(
        id: '2',
        divisionId: 'div1',
        bracketType: BracketType.winners,
        totalRounds: 3,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
      );

      final b3 = BracketEntity(
        id: '1',
        divisionId: 'div1',
        bracketType: BracketType.losers,
        totalRounds: 3,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
      );

      expect(b1, isNot(equals(b2)));
      expect(b1, isNot(equals(b3)));
    });

    test('BracketType.fromString should return correct type', () {
      expect(BracketType.fromString('winners'), BracketType.winners);
      expect(BracketType.fromString('losers'), BracketType.losers);
      expect(BracketType.fromString('pool'), BracketType.pool);
      expect(BracketType.fromString('unknown'), BracketType.winners); // Default
    });

    test('BracketType value should match string representation', () {
      expect(BracketType.winners.value, 'winners');
      expect(BracketType.losers.value, 'losers');
      expect(BracketType.pool.value, 'pool');
    });
  });
}
