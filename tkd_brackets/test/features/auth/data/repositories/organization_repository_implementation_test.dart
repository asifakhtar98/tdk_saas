// Test file for OrganizationRepositoryImplementation - tests offline-first
// logic.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/auth/data/datasources/organization_local_datasource.dart';
import 'package:tkd_brackets/features/auth/data/datasources/organization_remote_datasource.dart';
import 'package:tkd_brackets/features/auth/data/models/organization_model.dart';
import 'package:tkd_brackets/features/auth/data/repositories/organization_repository_implementation.dart';

class MockOrganizationLocalDatasource extends Mock
    implements OrganizationLocalDatasource {}

class MockOrganizationRemoteDatasource extends Mock
    implements OrganizationRemoteDatasource {}

class MockConnectivityService extends Mock
    implements ConnectivityService {}

class FakeOrganizationModel extends Fake
    implements OrganizationModel {}

void main() {
  late OrganizationRepositoryImplementation repository;
  late MockOrganizationLocalDatasource mockLocalDatasource;
  late MockOrganizationRemoteDatasource mockRemoteDatasource;
  late MockConnectivityService mockConnectivityService;

  final testModel = OrganizationModel(
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
  );

  setUpAll(() {
    registerFallbackValue(FakeOrganizationModel());
  });

  setUp(() {
    mockLocalDatasource = MockOrganizationLocalDatasource();
    mockRemoteDatasource = MockOrganizationRemoteDatasource();
    mockConnectivityService = MockConnectivityService();
    repository = OrganizationRepositoryImplementation(
      mockLocalDatasource,
      mockRemoteDatasource,
      mockConnectivityService,
    );
  });

  group('getOrganizationById', () {
    test('returns organization from local when available', () async {
      when(() => mockLocalDatasource.getOrganizationById('org-1'))
          .thenAnswer((_) async => testModel);

      final result = await repository.getOrganizationById('org-1');

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right'),
        (org) => expect(org.id, 'org-1'),
      );
      verifyNever(() => mockRemoteDatasource.getOrganizationById(any()));
    });

    test('fetches from remote when local not found and online', () async {
      when(() => mockLocalDatasource.getOrganizationById('org-1'))
          .thenAnswer((_) async => null);
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemoteDatasource.getOrganizationById('org-1'))
          .thenAnswer((_) async => testModel);
      when(() => mockLocalDatasource.insertOrganization(any()))
          .thenAnswer((_) async {});

      final result = await repository.getOrganizationById('org-1');

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.insertOrganization(testModel)).called(1);
    });

    test('returns failure when not found locally and offline', () async {
      when(() => mockLocalDatasource.getOrganizationById('org-1'))
          .thenAnswer((_) async => null);
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => false);

      final result = await repository.getOrganizationById('org-1');

      expect(result.isLeft(), true);
    });

    test('returns failure when not found in both data sources', () async {
      when(() => mockLocalDatasource.getOrganizationById('org-1'))
          .thenAnswer((_) async => null);
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemoteDatasource.getOrganizationById('org-1'))
          .thenAnswer((_) async => null);

      final result = await repository.getOrganizationById('org-1');

      expect(result.isLeft(), true);
    });

    test('returns failure on exception', () async {
      when(() => mockLocalDatasource.getOrganizationById('org-1'))
          .thenThrow(Exception('database error'));

      final result = await repository.getOrganizationById('org-1');

      expect(result.isLeft(), true);
    });
  });

  group('getOrganizationBySlug', () {
    test('returns organization from local when available', () async {
      when(() => mockLocalDatasource.getOrganizationBySlug('dragon-martial-arts'))
          .thenAnswer((_) async => testModel);

      final result = await repository.getOrganizationBySlug('dragon-martial-arts');

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right'),
        (org) => expect(org.slug, 'dragon-martial-arts'),
      );
    });

    test('fetches from remote when local not found and online', () async {
      when(() => mockLocalDatasource.getOrganizationBySlug('dragon-martial-arts'))
          .thenAnswer((_) async => null);
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemoteDatasource.getOrganizationBySlug('dragon-martial-arts'))
          .thenAnswer((_) async => testModel);
      when(() => mockLocalDatasource.insertOrganization(any()))
          .thenAnswer((_) async {});

      final result = await repository.getOrganizationBySlug('dragon-martial-arts');

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.insertOrganization(testModel)).called(1);
    });

    test('returns failure when not found and offline', () async {
      when(() => mockLocalDatasource.getOrganizationBySlug('nonexistent'))
          .thenAnswer((_) async => null);
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => false);

      final result = await repository.getOrganizationBySlug('nonexistent');

      expect(result.isLeft(), true);
    });
  });

  group('getActiveOrganizations', () {
    test('returns local organizations when offline', () async {
      when(() => mockLocalDatasource.getActiveOrganizations())
          .thenAnswer((_) async => [testModel]);
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => false);

      final result = await repository.getActiveOrganizations();

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right'),
        (orgs) => expect(orgs.length, 1),
      );
    });

    test('syncs from remote when online and inserts new records', () async {
      when(() => mockLocalDatasource.getActiveOrganizations())
          .thenAnswer((_) async => []);
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemoteDatasource.getActiveOrganizations())
          .thenAnswer((_) async => [testModel]);
      when(() => mockLocalDatasource.getOrganizationById('org-1'))
          .thenAnswer((_) async => null);
      when(() => mockLocalDatasource.insertOrganization(any()))
          .thenAnswer((_) async {});

      final result = await repository.getActiveOrganizations();

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.insertOrganization(any())).called(1);
    });

    test('updates local records when remote has higher sync version', () async {
      final olderModel = testModel.copyWith(syncVersion: 1);
      final newerModel = testModel.copyWith(syncVersion: 3);

      when(() => mockLocalDatasource.getActiveOrganizations())
          .thenAnswer((_) async => [olderModel]);
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemoteDatasource.getActiveOrganizations())
          .thenAnswer((_) async => [newerModel]);
      when(() => mockLocalDatasource.getOrganizationById('org-1'))
          .thenAnswer((_) async => olderModel);
      when(() => mockLocalDatasource.updateOrganization(any()))
          .thenAnswer((_) async {});

      final result = await repository.getActiveOrganizations();

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.updateOrganization(newerModel)).called(1);
    });

    test('uses local data when remote fetch fails', () async {
      when(() => mockLocalDatasource.getActiveOrganizations())
          .thenAnswer((_) async => [testModel]);
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemoteDatasource.getActiveOrganizations())
          .thenThrow(Exception('network error'));

      final result = await repository.getActiveOrganizations();

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right'),
        (orgs) => expect(orgs.length, 1),
      );
    });

    test('returns failure on local exception', () async {
      when(() => mockLocalDatasource.getActiveOrganizations())
          .thenThrow(Exception('database error'));

      final result = await repository.getActiveOrganizations();

      expect(result.isLeft(), true);
    });
  });

  group('createOrganization', () {
    test('saves locally first then syncs to remote', () async {
      when(() => mockLocalDatasource.insertOrganization(any()))
          .thenAnswer((_) async {});
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemoteDatasource.insertOrganization(any()))
          .thenAnswer((_) async => testModel);

      final entity = testModel.convertToEntity();
      final result = await repository.createOrganization(entity);

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.insertOrganization(any())).called(1);
      verify(() => mockRemoteDatasource.insertOrganization(any())).called(1);
    });

    test('succeeds with local only when offline', () async {
      when(() => mockLocalDatasource.insertOrganization(any()))
          .thenAnswer((_) async {});
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => false);

      final entity = testModel.convertToEntity();
      final result = await repository.createOrganization(entity);

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.insertOrganization(any())).called(1);
      verifyNever(() => mockRemoteDatasource.insertOrganization(any()));
    });

    test('succeeds locally when remote sync fails', () async {
      when(() => mockLocalDatasource.insertOrganization(any()))
          .thenAnswer((_) async {});
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemoteDatasource.insertOrganization(any()))
          .thenThrow(Exception('network error'));

      final entity = testModel.convertToEntity();
      final result = await repository.createOrganization(entity);

      expect(result.isRight(), true);
    });

    test('returns failure when local insert fails', () async {
      when(() => mockLocalDatasource.insertOrganization(any()))
          .thenThrow(Exception('database error'));

      final entity = testModel.convertToEntity();
      final result = await repository.createOrganization(entity);

      expect(result.isLeft(), true);
    });
  });

  group('updateOrganization', () {
    test('updates locally and syncs to remote when online', () async {
      when(() => mockLocalDatasource.getOrganizationById('org-1'))
          .thenAnswer((_) async => testModel);
      when(() => mockLocalDatasource.updateOrganization(any()))
          .thenAnswer((_) async {});
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemoteDatasource.updateOrganization(any()))
          .thenAnswer((_) async => testModel);

      final entity = testModel.convertToEntity();
      final result = await repository.updateOrganization(entity);

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.getOrganizationById('org-1')).called(1);
      verify(() => mockLocalDatasource.updateOrganization(any())).called(1);
      verify(() => mockRemoteDatasource.updateOrganization(any())).called(1);
    });

    test('sends correct incremented syncVersion to remote', () async {
      final existingModel = testModel.copyWith(syncVersion: 5);
      when(() => mockLocalDatasource.getOrganizationById('org-1'))
          .thenAnswer((_) async => existingModel);
      when(() => mockLocalDatasource.updateOrganization(any()))
          .thenAnswer((_) async {});
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => true);

      OrganizationModel? capturedModel;
      when(() => mockRemoteDatasource.updateOrganization(any()))
          .thenAnswer((invocation) async {
        capturedModel = invocation.positionalArguments[0] as OrganizationModel;
        return testModel;
      });

      final entity = testModel.convertToEntity();
      await repository.updateOrganization(entity);

      expect(capturedModel, isNotNull);
      expect(capturedModel!.syncVersion, 6); // 5 + 1
    });

    test('succeeds with local only when offline', () async {
      when(() => mockLocalDatasource.getOrganizationById('org-1'))
          .thenAnswer((_) async => testModel);
      when(() => mockLocalDatasource.updateOrganization(any()))
          .thenAnswer((_) async {});
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => false);

      final entity = testModel.convertToEntity();
      final result = await repository.updateOrganization(entity);

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.updateOrganization(any())).called(1);
      verifyNever(() => mockRemoteDatasource.updateOrganization(any()));
    });

    test('succeeds locally when remote sync fails', () async {
      when(() => mockLocalDatasource.getOrganizationById('org-1'))
          .thenAnswer((_) async => testModel);
      when(() => mockLocalDatasource.updateOrganization(any()))
          .thenAnswer((_) async {});
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemoteDatasource.updateOrganization(any()))
          .thenThrow(Exception('network error'));

      final entity = testModel.convertToEntity();
      final result = await repository.updateOrganization(entity);

      expect(result.isRight(), true);
    });

    test('returns failure when local update fails', () async {
      when(() => mockLocalDatasource.getOrganizationById('org-1'))
          .thenAnswer((_) async => testModel);
      when(() => mockLocalDatasource.updateOrganization(any()))
          .thenThrow(Exception('database error'));

      final entity = testModel.convertToEntity();
      final result = await repository.updateOrganization(entity);

      expect(result.isLeft(), true);
    });
  });

  group('deleteOrganization', () {
    test('deletes locally and syncs to remote when online', () async {
      when(() => mockLocalDatasource.deleteOrganization('org-1'))
          .thenAnswer((_) async {});
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemoteDatasource.deleteOrganization('org-1'))
          .thenAnswer((_) async {});

      final result = await repository.deleteOrganization('org-1');

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.deleteOrganization('org-1')).called(1);
      verify(() => mockRemoteDatasource.deleteOrganization('org-1')).called(1);
    });

    test('succeeds with local only when offline', () async {
      when(() => mockLocalDatasource.deleteOrganization('org-1'))
          .thenAnswer((_) async {});
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => false);

      final result = await repository.deleteOrganization('org-1');

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.deleteOrganization('org-1')).called(1);
      verifyNever(() => mockRemoteDatasource.deleteOrganization(any()));
    });

    test('succeeds locally when remote delete fails', () async {
      when(() => mockLocalDatasource.deleteOrganization('org-1'))
          .thenAnswer((_) async {});
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemoteDatasource.deleteOrganization('org-1'))
          .thenThrow(Exception('network error'));

      final result = await repository.deleteOrganization('org-1');

      expect(result.isRight(), true);
    });

    test('returns failure when local delete fails', () async {
      when(() => mockLocalDatasource.deleteOrganization('org-1'))
          .thenThrow(Exception('database error'));

      final result = await repository.deleteOrganization('org-1');

      expect(result.isLeft(), true);
    });
  });
}
