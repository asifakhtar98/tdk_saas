import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/bracket/data/datasources/bracket_local_datasource.dart';
import 'package:tkd_brackets/features/bracket/data/models/bracket_model.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late BracketLocalDatasourceImplementation datasource;
  late MockAppDatabase mockDatabase;

  final testDateTime = DateTime(2026, 1, 15, 10, 30);

  setUpAll(() {
    registerFallbackValue(const BracketsCompanion());
  });

  setUp(() {
    mockDatabase = MockAppDatabase();
    datasource = BracketLocalDatasourceImplementation(mockDatabase);
  });

  group('getBracketsForDivision', () {
    test('should return empty list when database returns empty', () async {
      when(
        () => mockDatabase.getBracketsForDivision('division-1'),
      ).thenAnswer((_) async => []);

      final result = await datasource.getBracketsForDivision('division-1');

      expect(result, isEmpty);
      verify(() => mockDatabase.getBracketsForDivision('division-1')).called(1);
    });

    test('should return list of models when database returns entries', () async {
      final entries = [
        BracketEntry(
          id: 'bracket-1',
          divisionId: 'division-1',
          bracketType: 'winners',
          totalRounds: 4,
          isFinalized: false,
          syncVersion: 1,
          isDeleted: false,
          isDemoData: false,
          createdAtTimestamp: testDateTime,
          updatedAtTimestamp: testDateTime,
        ),
      ];

      when(
        () => mockDatabase.getBracketsForDivision('division-1'),
      ).thenAnswer((_) async => entries);

      final result = await datasource.getBracketsForDivision('division-1');

      expect(result.length, 1);
      expect(result.first.id, 'bracket-1');
      expect(result.first.bracketType, 'winners');
    });
  });

  group('getBracketById', () {
    test('should return null when database returns null', () async {
      when(
        () => mockDatabase.getBracketById('unknown'),
      ).thenAnswer((_) async => null);

      final result = await datasource.getBracketById('unknown');

      expect(result, isNull);
    });

    test('should return model when database returns entry', () async {
      final entry = BracketEntry(
        id: 'bracket-1',
        divisionId: 'division-1',
        bracketType: 'winners',
        totalRounds: 4,
        isFinalized: false,
        syncVersion: 1,
        isDeleted: false,
        isDemoData: false,
        createdAtTimestamp: testDateTime,
        updatedAtTimestamp: testDateTime,
      );

      when(
        () => mockDatabase.getBracketById('bracket-1'),
      ).thenAnswer((_) async => entry);

      final result = await datasource.getBracketById('bracket-1');

      expect(result, isNotNull);
      expect(result!.id, 'bracket-1');
    });
  });

  group('insertBracket', () {
    test('should call database insert', () async {
      final model = BracketModel(
        id: 'bracket-1',
        divisionId: 'division-1',
        bracketType: 'winners',
        totalRounds: 4,
        syncVersion: 1,
        createdAtTimestamp: testDateTime,
        updatedAtTimestamp: testDateTime,
      );

      when(() => mockDatabase.insertBracket(any())).thenAnswer((_) async => 1);

      await datasource.insertBracket(model);

      verify(() => mockDatabase.insertBracket(any())).called(1);
    });
  });

  group('updateBracket', () {
    test('should call database update', () async {
      final model = BracketModel(
        id: 'bracket-1',
        divisionId: 'division-1',
        bracketType: 'winners',
        totalRounds: 4,
        syncVersion: 1,
        createdAtTimestamp: testDateTime,
        updatedAtTimestamp: testDateTime,
      );

      when(() => mockDatabase.updateBracket(any(), any()))
          .thenAnswer((_) async => true);

      await datasource.updateBracket(model);

      verify(() => mockDatabase.updateBracket('bracket-1', any())).called(1);
    });
  });

  group('deleteBracket', () {
    test('should call database soft delete', () async {
      when(() => mockDatabase.softDeleteBracket(any()))
          .thenAnswer((_) async => true);

      await datasource.deleteBracket('bracket-1');

      verify(() => mockDatabase.softDeleteBracket('bracket-1')).called(1);
    });
  });
}
