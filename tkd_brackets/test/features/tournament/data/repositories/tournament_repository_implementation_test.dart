import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/tournament/data/datasources/tournament_local_datasource.dart';
import 'package:tkd_brackets/features/tournament/data/datasources/tournament_remote_datasource.dart';
import 'package:tkd_brackets/features/tournament/data/models/tournament_model.dart';
import 'package:tkd_brackets/features/tournament/data/repositories/tournament_repository_implementation.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';

class MockTournamentLocalDatasource extends Mock
    implements TournamentLocalDatasource {}

class MockTournamentRemoteDatasource extends Mock
    implements TournamentRemoteDatasource {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late TournamentRepositoryImplementation repository;
  late MockTournamentLocalDatasource mockLocalDatasource;
  late MockTournamentRemoteDatasource mockRemoteDatasource;
  late MockConnectivityService mockConnectivityService;
  late MockAppDatabase mockAppDatabase;

  final testDate = DateTime.now();
  final testEntity = TournamentEntity(
    id: 'test-id',
    organizationId: 'org-id',
    createdByUserId: 'user-id',
    name: 'Test Tournament',
    scheduledDate: testDate,
    federationType: FederationType.wt,
    status: TournamentStatus.draft,
    numberOfRings: 2,
    settingsJson: {},
    isTemplate: false,
    createdAt: testDate,
    updatedAtTimestamp: testDate,
  );

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

  setUpAll(() {
    registerFallbackValue(testModel);
    registerFallbackValue(testEntity);
  });

  setUp(() {
    mockLocalDatasource = MockTournamentLocalDatasource();
    mockRemoteDatasource = MockTournamentRemoteDatasource();
    mockConnectivityService = MockConnectivityService();
    mockAppDatabase = MockAppDatabase();
    repository = TournamentRepositoryImplementation(
      mockLocalDatasource,
      mockRemoteDatasource,
      mockConnectivityService,
      mockAppDatabase,
    );
  });

  group('getTournamentById', () {
    test('should return TournamentEntity when local data exists', () async {
      // Arrange
      when(
        () => mockLocalDatasource.getTournamentById(any()),
      ).thenAnswer((_) async => testModel);

      // Act
      final result = await repository.getTournamentById('test-id');

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return failure'),
        (r) => expect(r.id, 'test-id'),
      );
      verify(() => mockLocalDatasource.getTournamentById('test-id')).called(1);
      verifyNever(() => mockRemoteDatasource.getTournamentById(any()));
    });

    test('should fallback to remote when local is empty and online', () async {
      // Arrange
      when(
        () => mockLocalDatasource.getTournamentById(any()),
      ).thenAnswer((_) async => null);
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => true);
      when(
        () => mockRemoteDatasource.getTournamentById(any()),
      ).thenAnswer((_) async => testModel);
      when(
        () => mockLocalDatasource.insertTournament(any()),
      ).thenAnswer((_) async {});

      // Act
      final result = await repository.getTournamentById('test-id');

      // Assert
      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.insertTournament(any())).called(1);
    });

    test('should return failure when not found locally and offline', () async {
      // Arrange
      when(
        () => mockLocalDatasource.getTournamentById(any()),
      ).thenAnswer((_) async => null);
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => false);

      // Act
      final result = await repository.getTournamentById('test-id');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<LocalCacheAccessFailure>()),
        (r) => fail('Should not return success'),
      );
    });
  });

  group('getTournamentsForOrganization', () {
    test('should return list of tournaments', () async {
      // Arrange
      when(
        () => mockLocalDatasource.getTournamentsForOrganization(any()),
      ).thenAnswer((_) async => [testModel]);
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => false);

      // Act
      final result = await repository.getTournamentsForOrganization('org-id');

      // Assert
      expect(result.isRight(), true);
      result.fold((l) => fail('Should not return failure'), (r) {
        expect(r.length, 1);
        expect(r.first.id, 'test-id');
      });
    });
  });

  group('createTournament', () {
    test('should save locally and return entity', () async {
      // Arrange
      when(
        () => mockLocalDatasource.insertTournament(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => false);

      // Act
      final result = await repository.createTournament(testEntity, 'org-id');

      // Assert
      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.insertTournament(any())).called(1);
    });

    test('should sync to remote when online', () async {
      // Arrange
      when(
        () => mockLocalDatasource.insertTournament(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => true);
      when(
        () => mockRemoteDatasource.insertTournament(any()),
      ).thenAnswer((_) async => testModel);

      // Act
      final result = await repository.createTournament(testEntity, 'org-id');

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRemoteDatasource.insertTournament(any())).called(1);
    });
  });

  group('updateTournament', () {
    test('should update locally with incremented sync version', () async {
      // Arrange
      when(
        () => mockLocalDatasource.getTournamentById(any()),
      ).thenAnswer((_) async => testModel.copyWith(syncVersion: 5));
      when(
        () => mockLocalDatasource.updateTournament(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => false);

      // Act
      final result = await repository.updateTournament(testEntity);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.updateTournament(any())).called(1);
    });
  });

  group('deleteTournament', () {
    test('should soft delete locally', () async {
      // Arrange
      when(
        () => mockLocalDatasource.deleteTournament(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => false);

      // Act
      final result = await repository.deleteTournament('test-id');

      // Assert
      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.deleteTournament(any())).called(1);
    });

    test('should sync deletion to remote when online', () async {
      // Arrange
      when(
        () => mockLocalDatasource.deleteTournament(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => true);
      when(
        () => mockRemoteDatasource.deleteTournament(any()),
      ).thenAnswer((_) async {});

      // Act
      final result = await repository.deleteTournament('test-id');

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRemoteDatasource.deleteTournament(any())).called(1);
    });
  });
}
