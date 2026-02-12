import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/auth/data/datasources/organization_local_datasource.dart';
import 'package:tkd_brackets/features/auth/data/models/organization_model.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

class FakeOrganizationsCompanion extends Fake
    implements OrganizationsCompanion {}

void main() {
  late OrganizationLocalDatasourceImplementation datasource;
  late MockAppDatabase mockDatabase;

  setUpAll(() {
    registerFallbackValue(FakeOrganizationsCompanion());
  });

  final testEntry = OrganizationEntry(
    id: 'org-1',
    name: 'Dragon Martial Arts',
    slug: 'dragon-martial-arts',
    subscriptionTier: 'free',
    subscriptionStatus: 'active',
    maxTournamentsPerMonth: 2,
    maxActiveBrackets: 3,
    maxParticipantsPerBracket: 32,
    maxParticipantsPerTournament: 100,
    maxScorers: 2,
    isActive: true,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
    syncVersion: 1,
    isDeleted: false,
    isDemoData: false,
    deletedAtTimestamp: null,
  );

  setUp(() {
    mockDatabase = MockAppDatabase();
    datasource =
        OrganizationLocalDatasourceImplementation(mockDatabase);
  });

  group('OrganizationLocalDatasource', () {
    group('getOrganizationById', () {
      test('returns OrganizationModel when found', () async {
        when(() => mockDatabase.getOrganizationById('org-1'))
            .thenAnswer((_) async => testEntry);

        final result =
            await datasource.getOrganizationById('org-1');

        expect(result, isNotNull);
        expect(result!.id, 'org-1');
        expect(result.name, 'Dragon Martial Arts');
        verify(() => mockDatabase.getOrganizationById('org-1'))
            .called(1);
      });

      test('returns null when not found', () async {
        when(() => mockDatabase.getOrganizationById('nonexistent'))
            .thenAnswer((_) async => null);

        final result =
            await datasource.getOrganizationById('nonexistent');

        expect(result, isNull);
      });
    });

    group('getOrganizationBySlug', () {
      test('returns OrganizationModel when found', () async {
        when(
          () => mockDatabase
              .getOrganizationBySlug('dragon-martial-arts'),
        ).thenAnswer((_) async => testEntry);

        final result = await datasource
            .getOrganizationBySlug('dragon-martial-arts');

        expect(result, isNotNull);
        expect(result!.slug, 'dragon-martial-arts');
        verify(
          () => mockDatabase
              .getOrganizationBySlug('dragon-martial-arts'),
        ).called(1);
      });

      test('returns null when not found', () async {
        when(
          () => mockDatabase.getOrganizationBySlug('nonexistent'),
        ).thenAnswer((_) async => null);

        final result =
            await datasource.getOrganizationBySlug('nonexistent');

        expect(result, isNull);
      });
    });

    group('getActiveOrganizations', () {
      test('returns list of OrganizationModels', () async {
        when(() => mockDatabase.getActiveOrganizations())
            .thenAnswer((_) async => [testEntry]);

        final result =
            await datasource.getActiveOrganizations();

        expect(result.length, 1);
        expect(result.first.id, 'org-1');
      });

      test('returns empty list when no organizations', () async {
        when(() => mockDatabase.getActiveOrganizations())
            .thenAnswer((_) async => []);

        final result =
            await datasource.getActiveOrganizations();

        expect(result, isEmpty);
      });
    });

    group('insertOrganization', () {
      test('calls database insertOrganization', () async {
        final model =
            OrganizationModel.fromDriftEntry(testEntry);
        when(() => mockDatabase.insertOrganization(any()))
            .thenAnswer((_) async => 1);

        await datasource.insertOrganization(model);

        verify(() => mockDatabase.insertOrganization(any()))
            .called(1);
      });
    });

    group('updateOrganization', () {
      test('calls database updateOrganization', () async {
        final model =
            OrganizationModel.fromDriftEntry(testEntry);
        when(() => mockDatabase.updateOrganization(any(), any()))
            .thenAnswer((_) async => true);

        await datasource.updateOrganization(model);

        verify(
          () => mockDatabase.updateOrganization('org-1', any()),
        ).called(1);
      });
    });

    group('deleteOrganization', () {
      test('calls database softDeleteOrganization', () async {
        when(() => mockDatabase.softDeleteOrganization('org-1'))
            .thenAnswer((_) async => true);

        await datasource.deleteOrganization('org-1');

        verify(
          () => mockDatabase.softDeleteOrganization('org-1'),
        ).called(1);
      });
    });
  });
}
