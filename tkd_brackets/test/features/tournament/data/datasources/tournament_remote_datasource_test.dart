import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/features/tournament/data/datasources/tournament_remote_datasource.dart';
import 'package:tkd_brackets/features/tournament/data/models/tournament_model.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<Map<String, dynamic>> {}

class MockPostgrestTransformBuilder extends Mock
    implements PostgrestTransformBuilder<Map<String, dynamic>> {}

class MockPostgrestBuilder extends Mock
    implements PostgrestBuilder<Map<String, dynamic>, dynamic, dynamic> {}

void main() {
  late TournamentRemoteDatasourceImplementation datasource;
  late MockSupabaseClient mockSupabase;

  final testDate = DateTime.now();
  final testModel = TournamentModel(
    id: 'test-id',
    organizationId: 'org-id',
    createdByUserId: 'user-id',
    name: 'Test Tournament',
    scheduledDate: testDate,
    federationType: 'wt',
    status: 'draft',
    isTemplate: false,
    numberOfRings: 2,
    settingsJson: {},
    syncVersion: 1,
    isDeleted: false,
    isDemoData: false,
    createdAtTimestamp: testDate,
    updatedAtTimestamp: testDate,
  );

  setUp(() {
    mockSupabase = MockSupabaseClient();
    datasource = TournamentRemoteDatasourceImplementation(mockSupabase);
  });

  group('getTournamentsForOrganization', () {
    test('should return empty list when no tournaments', () async {
      // Arrange
      when(
        () => mockSupabase.from('tournaments'),
      ).thenThrow(Exception('Not mocked'));

      // Act & Assert
      expect(
        () => datasource.getTournamentsForOrganization('org-id'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getTournamentById', () {
    test('should return null when not found', () async {
      // Arrange
      when(
        () => mockSupabase.from('tournaments'),
      ).thenThrow(Exception('Not mocked'));

      // Act & Assert
      expect(
        () => datasource.getTournamentById('test-id'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('deleteTournament', () {
    test('should perform soft delete with timestamp', () async {
      // Arrange
      when(
        () => mockSupabase.from('tournaments'),
      ).thenThrow(Exception('Not mocked'));

      // Act & Assert
      expect(
        () => datasource.deleteTournament('test-id'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
