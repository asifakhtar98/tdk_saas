import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/bracket/data/models/match_model.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';

void main() {
  final testDateTime = DateTime(2026, 1, 15, 10, 30);

  final testJson = {
    'id': 'match-1',
    'bracket_id': 'bracket-1',
    'round_number': 1,
    'match_number_in_round': 1,
    'status': 'pending',
    'sync_version': 1,
    'is_deleted': false,
    'is_demo_data': false,
    'created_at_timestamp': testDateTime.toIso8601String(),
    'updated_at_timestamp': testDateTime.toIso8601String(),
  };

  final testModel = MatchModel(
    id: 'match-1',
    bracketId: 'bracket-1',
    roundNumber: 1,
    matchNumberInRound: 1,
    status: 'pending',
    syncVersion: 1,
    isDeleted: false,
    isDemoData: false,
    createdAtTimestamp: testDateTime,
    updatedAtTimestamp: testDateTime,
  );

  final testMatchEntry = MatchEntry(
    id: 'match-1',
    bracketId: 'bracket-1',
    roundNumber: 1,
    matchNumberInRound: 1,
    status: 'pending',
    syncVersion: 1,
    isDeleted: false,
    isDemoData: false,
    createdAtTimestamp: testDateTime,
    updatedAtTimestamp: testDateTime,
  );

  group('MatchModel', () {
    test('fromJson should return correct model', () {
      final model = MatchModel.fromJson(testJson);
      expect(model.id, testModel.id);
      expect(model.bracketId, testModel.bracketId);
      expect(model.roundNumber, testModel.roundNumber);
      expect(model.matchNumberInRound, testModel.matchNumberInRound);
      expect(model.status, testModel.status);
      expect(model.syncVersion, testModel.syncVersion);
      expect(model.isDeleted, testModel.isDeleted);
      expect(model.isDemoData, testModel.isDemoData);
      expect(model.createdAtTimestamp, testModel.createdAtTimestamp);
      expect(model.updatedAtTimestamp, testModel.updatedAtTimestamp);
    });

    test('toJson should return correct json map', () {
      final json = testModel.toJson();
      expect(json['id'], testJson['id']);
      expect(json['bracket_id'], testJson['bracket_id']);
      expect(json['round_number'], testJson['round_number']);
      expect(json['match_number_in_round'], testJson['match_number_in_round']);
      expect(json['status'], testJson['status']);
      expect(json['sync_version'], testJson['sync_version']);
      expect(json['is_deleted'], testJson['is_deleted']);
      expect(json['is_demo_data'], testJson['is_demo_data']);
      expect(json['created_at_timestamp'], testJson['created_at_timestamp']);
      expect(json['updated_at_timestamp'], testJson['updated_at_timestamp']);
    });

    test('fromDriftEntry should convert all fields correctly', () {
      final model = MatchModel.fromDriftEntry(testMatchEntry);
      expect(model.id, testModel.id);
      expect(model.bracketId, testModel.bracketId);
      expect(model.roundNumber, testModel.roundNumber);
      expect(model.matchNumberInRound, testModel.matchNumberInRound);
      expect(model.status, testModel.status);
      expect(model.syncVersion, testModel.syncVersion);
      expect(model.isDeleted, testModel.isDeleted);
      expect(model.isDemoData, testModel.isDemoData);
      expect(model.createdAtTimestamp, testModel.createdAtTimestamp);
      expect(model.updatedAtTimestamp, testModel.updatedAtTimestamp);
    });

    test('convertToEntity should produce correct entity', () {
      final entity = testModel.convertToEntity();
      expect(entity.id, testModel.id);
      expect(entity.bracketId, testModel.bracketId);
      expect(entity.roundNumber, testModel.roundNumber);
      expect(entity.matchNumberInRound, testModel.matchNumberInRound);
      expect(entity.status, MatchStatus.pending);
      expect(entity.syncVersion, testModel.syncVersion);
      expect(entity.isDeleted, testModel.isDeleted);
      expect(entity.isDemoData, testModel.isDemoData);
      expect(entity.createdAtTimestamp, testModel.createdAtTimestamp);
      expect(entity.updatedAtTimestamp, testModel.updatedAtTimestamp);
    });

    test('convertFromEntity should produce correct model', () {
      final entity = MatchEntity(
        id: 'match-1',
        bracketId: 'bracket-1',
        roundNumber: 1,
        matchNumberInRound: 1,
        createdAtTimestamp: testDateTime,
        updatedAtTimestamp: testDateTime,
      );
      final model = MatchModel.convertFromEntity(entity);
      expect(model.id, testModel.id);
      expect(model.bracketId, testModel.bracketId);
      expect(model.roundNumber, testModel.roundNumber);
      expect(model.matchNumberInRound, testModel.matchNumberInRound);
      expect(model.status, 'pending');
      expect(model.syncVersion, testModel.syncVersion);
      expect(model.isDeleted, testModel.isDeleted);
      expect(model.isDemoData, testModel.isDemoData);
      expect(model.createdAtTimestamp, testModel.createdAtTimestamp);
      expect(model.updatedAtTimestamp, testModel.updatedAtTimestamp);
    });

    test('convertToEntity should handle resultType enum', () {
      final model = testModel.copyWith(resultType: 'points');
      final entity = model.convertToEntity();
      expect(entity.resultType, MatchResultType.points);
    });

    test('convertFromEntity should handle resultType enum', () {
      final entity = MatchEntity(
        id: 'match-1',
        bracketId: 'bracket-1',
        roundNumber: 1,
        matchNumberInRound: 1,
        resultType: MatchResultType.knockout,
        createdAtTimestamp: testDateTime,
        updatedAtTimestamp: testDateTime,
      );
      final model = MatchModel.convertFromEntity(entity);
      expect(model.resultType, 'knockout');
    });

    test('toDriftCompanion should produce correct companion', () {
      final companion = testModel.toDriftCompanion();
      expect(companion.id.value, testModel.id);
      expect(companion.bracketId.value, testModel.bracketId);
      expect(companion.roundNumber.value, testModel.roundNumber);
      expect(companion.matchNumberInRound.value, testModel.matchNumberInRound);
      expect(companion.status.value, testModel.status);
    });

    test('convertToEntity should handle null resultType', () {
      final entity = testModel.convertToEntity();
      expect(entity.resultType, isNull);
    });

    test('convertFromEntity should handle null resultType', () {
      final entity = MatchEntity(
        id: 'match-1',
        bracketId: 'bracket-1',
        roundNumber: 1,
        matchNumberInRound: 1,
        createdAtTimestamp: testDateTime,
        updatedAtTimestamp: testDateTime,
      );
      final model = MatchModel.convertFromEntity(entity);
      expect(model.resultType, isNull);
    });
  });
}
