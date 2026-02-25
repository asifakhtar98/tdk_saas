import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/bracket/data/models/bracket_model.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';

void main() {
  group('BracketModel', () {
    final now = DateTime.now();

    final testModel = BracketModel(
      id: 'bracket-1',
      divisionId: 'div-1',
      bracketType: 'winners',
      totalRounds: 4,
      syncVersion: 1,
      createdAtTimestamp: now,
      updatedAtTimestamp: now,
      bracketDataJson: '{"matches":[]}',
    );

    final testEntity = BracketEntity(
      id: 'bracket-1',
      divisionId: 'div-1',
      bracketType: BracketType.winners,
      totalRounds: 4,
      syncVersion: 1,
      createdAtTimestamp: now,
      updatedAtTimestamp: now,
      bracketDataJson: const {'matches': []},
    );

    test('fromJson should return valid model', () {
      final json = {
        'id': 'bracket-1',
        'division_id': 'div-1',
        'bracket_type': 'winners',
        'total_rounds': 4,
        'sync_version': 1,
        'created_at_timestamp': now.toIso8601String(),
        'updated_at_timestamp': now.toIso8601String(),
        'bracket_data_json': '{"matches":[]}',
      };

      final result = BracketModel.fromJson(json);

      expect(result.id, testModel.id);
      expect(result.bracketType, testModel.bracketType);
    });

    test('convertToEntity should return correct entity', () {
      final entity = testModel.convertToEntity();

      expect(entity.id, testEntity.id);
      expect(entity.bracketType, testEntity.bracketType);
      expect(entity.bracketDataJson, testEntity.bracketDataJson);
    });

    test('convertFromEntity should return correct model', () {
      final model = BracketModel.convertFromEntity(testEntity);

      expect(model.id, testModel.id);
      expect(model.bracketType, testModel.bracketType);
      // Compare decoded JSON as strings might have different whitespace
      expect(jsonDecode(model.bracketDataJson!),
          jsonDecode(testModel.bracketDataJson!));
    });

    test('toDriftCompanion should have all required values', () {
      final companion = testModel.toDriftCompanion();

      expect(companion.id.value, testModel.id);
      expect(companion.divisionId.value, testModel.divisionId);
      expect(companion.bracketType.value, testModel.bracketType);
    });

    test('toJson should produce snake_case keys', () {
      final json = testModel.toJson();

      expect(json.containsKey('division_id'), isTrue);
      expect(json.containsKey('bracket_type'), isTrue);
      expect(json.containsKey('total_rounds'), isTrue);
      expect(json.containsKey('is_finalized'), isTrue);
      expect(json.containsKey('sync_version'), isTrue);
      expect(json.containsKey('created_at_timestamp'), isTrue);
      expect(json.containsKey('updated_at_timestamp'), isTrue);
      expect(json['division_id'], 'div-1');
      expect(json['bracket_type'], 'winners');
    });

    test('convertToEntity should handle null bracketDataJson', () {
      final modelWithoutData = BracketModel(
        id: 'bracket-2',
        divisionId: 'div-1',
        bracketType: 'losers',
        totalRounds: 3,
        syncVersion: 1,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
      );

      final entity = modelWithoutData.convertToEntity();

      expect(entity.bracketDataJson, isNull);
      expect(entity.bracketType, BracketType.losers);
    });

    test('convertFromEntity should handle null bracketDataJson', () {
      final entityWithoutData = BracketEntity(
        id: 'bracket-2',
        divisionId: 'div-1',
        bracketType: BracketType.pool,
        totalRounds: 2,
        syncVersion: 1,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
        poolIdentifier: 'B',
      );

      final model = BracketModel.convertFromEntity(entityWithoutData);

      expect(model.bracketDataJson, isNull);
      expect(model.bracketType, 'pool');
      expect(model.poolIdentifier, 'B');
    });

    test('fromDriftEntry should convert all fields correctly', () {
      final entry = BracketEntry(
        id: 'bracket-drift',
        divisionId: 'div-1',
        bracketType: 'pool',
        poolIdentifier: 'C',
        totalRounds: 5,
        isFinalized: true,
        generatedAtTimestamp: now,
        finalizedAtTimestamp: now,
        bracketDataJson: '{"rounds":5}',
        syncVersion: 3,
        isDeleted: false,
        deletedAtTimestamp: null,
        isDemoData: true,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
      );

      final model = BracketModel.fromDriftEntry(entry);

      expect(model.id, 'bracket-drift');
      expect(model.divisionId, 'div-1');
      expect(model.bracketType, 'pool');
      expect(model.poolIdentifier, 'C');
      expect(model.totalRounds, 5);
      expect(model.isFinalized, true);
      expect(model.generatedAtTimestamp, now);
      expect(model.finalizedAtTimestamp, now);
      expect(model.bracketDataJson, '{"rounds":5}');
      expect(model.syncVersion, 3);
      expect(model.isDeleted, false);
      expect(model.isDemoData, true);
    });
  });
}
