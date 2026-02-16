import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/tournament/data/datasources/tournament_local_datasource.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late TournamentLocalDatasourceImplementation datasource;
  late MockAppDatabase mockDatabase;

  setUp(() {
    mockDatabase = MockAppDatabase();
    datasource = TournamentLocalDatasourceImplementation(mockDatabase);
  });

  group('getTournamentsForOrganization', () {
    test('should call database method', () async {
      // Arrange
      when(
        () => mockDatabase.getTournamentsForOrganization('org-id'),
      ).thenAnswer((_) async => []);

      // Act
      await datasource.getTournamentsForOrganization('org-id');

      // Assert
      verify(
        () => mockDatabase.getTournamentsForOrganization('org-id'),
      ).called(1);
    });
  });

  group('getTournamentById', () {
    test('should return null when tournament not found', () async {
      // Arrange
      when(
        () => mockDatabase.getTournamentById('test-id'),
      ).thenAnswer((_) async => null);

      // Act
      final result = await datasource.getTournamentById('test-id');

      // Assert
      expect(result, isNull);
    });
  });
}
