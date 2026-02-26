import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/bracket/data/datasources/match_local_datasource.dart';
import 'package:tkd_brackets/features/bracket/data/models/match_model.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late MatchLocalDatasourceImplementation datasource;
  late MockAppDatabase mockDatabase;

  setUpAll(() {
    registerFallbackValue(const MatchesCompanion());
  });

  final testDateTime = DateTime(2026, 1, 15, 10, 30);

  final testMatchEntry = MatchEntry(
    id: 'm1',
    bracketId: 'b1',
    roundNumber: 1,
    matchNumberInRound: 1,
    status: 'pending',
    syncVersion: 1,
    isDeleted: false,
    isDemoData: false,
    createdAtTimestamp: testDateTime,
    updatedAtTimestamp: testDateTime,
  );

  final testMatchModel = MatchModel.fromDriftEntry(testMatchEntry);

  setUp(() {
    mockDatabase = MockAppDatabase();
    datasource = MatchLocalDatasourceImplementation(mockDatabase);
  });

  group('MatchLocalDatasource', () {
    test('getMatchesForBracket should call database method', () async {
      when(() => mockDatabase.getMatchesForBracket(any()))
          .thenAnswer((_) async => [testMatchEntry]);

      final result = await datasource.getMatchesForBracket('b1');

      expect(result.length, 1);
      expect(result.first.id, 'm1');
      verify(() => mockDatabase.getMatchesForBracket('b1')).called(1);
    });

    test('getMatchesForRound should call database method', () async {
      when(() => mockDatabase.getMatchesByRound(any(), any()))
          .thenAnswer((_) async => [testMatchEntry]);

      final result = await datasource.getMatchesForRound('b1', 1);

      expect(result.length, 1);
      verify(() => mockDatabase.getMatchesByRound('b1', 1)).called(1);
    });

    test('getMatchById should call database method', () async {
      when(() => mockDatabase.getMatchById(any()))
          .thenAnswer((_) async => testMatchEntry);

      final result = await datasource.getMatchById('m1');

      expect(result?.id, 'm1');
      verify(() => mockDatabase.getMatchById('m1')).called(1);
    });

    test('insertMatch should call database method', () async {
      when(() => mockDatabase.insertMatch(any())).thenAnswer((_) async => 1);

      await datasource.insertMatch(testMatchModel);

      verify(() => mockDatabase.insertMatch(any())).called(1);
    });

    test('updateMatch should call database method', () async {
      when(() => mockDatabase.updateMatch(any(), any()))
          .thenAnswer((_) async => true);

      await datasource.updateMatch(testMatchModel);

      verify(() => mockDatabase.updateMatch('m1', any())).called(1);
    });

    test('deleteMatch should call database softDelete method', () async {
      when(() => mockDatabase.softDeleteMatch(any()))
          .thenAnswer((_) async => true);

      await datasource.deleteMatch('m1');

      verify(() => mockDatabase.softDeleteMatch('m1')).called(1);
    });
  });
}
