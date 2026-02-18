import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/core/sync/sync_queue.dart';
import 'package:tkd_brackets/features/division/data/datasources/division_local_datasource.dart';
import 'package:tkd_brackets/features/division/data/datasources/division_remote_datasource.dart';
import 'package:tkd_brackets/features/division/data/models/division_model.dart';
import 'package:tkd_brackets/features/division/data/repositories/division_repository_implementation.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';

class MockDivisionLocalDatasource extends Mock
    implements DivisionLocalDatasource {}

class MockDivisionRemoteDatasource extends Mock
    implements DivisionRemoteDatasource {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncQueue extends Mock implements SyncQueue {}

void main() {
  late DivisionRepositoryImplementation repository;
  late MockDivisionLocalDatasource mockLocalDatasource;
  late MockDivisionRemoteDatasource mockRemoteDatasource;
  late MockConnectivityService mockConnectivityService;
  late MockSyncQueue mockSyncQueue;

  final testDate = DateTime(2024, 1, 1);

  final testEntity = DivisionEntity(
    id: 'division-id',
    tournamentId: 'tournament-id',
    name: 'Cadets Male -45kg',
    category: DivisionCategory.sparring,
    gender: DivisionGender.male,
    bracketFormat: BracketFormat.singleElimination,
    status: DivisionStatus.setup,
    createdAtTimestamp: testDate,
    updatedAtTimestamp: testDate,
  );

  final testModel = DivisionModel(
    id: 'division-id',
    tournamentId: 'tournament-id',
    name: 'Cadets Male -45kg',
    category: 'sparring',
    gender: 'male',
    bracketFormat: 'single_elimination',
    status: 'setup',
    createdAtTimestamp: testDate,
    updatedAtTimestamp: testDate,
    syncVersion: 1,
    isDeleted: false,
    isDemoData: false,
  );

  setUpAll(() {
    registerFallbackValue(testModel);
    registerFallbackValue(testEntity);
  });

  setUp(() {
    mockLocalDatasource = MockDivisionLocalDatasource();
    mockRemoteDatasource = MockDivisionRemoteDatasource();
    mockConnectivityService = MockConnectivityService();
    mockSyncQueue = MockSyncQueue();
    repository = DivisionRepositoryImplementation(
      mockLocalDatasource,
      mockRemoteDatasource,
      mockConnectivityService,
      mockSyncQueue,
    );
  });

  group('getDivisionById', () {
    test('should return DivisionEntity when local data exists', () async {
      when(
        () => mockLocalDatasource.getDivisionById(any()),
      ).thenAnswer((_) async => testModel);

      final result = await repository.getDivisionById('division-id');

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return failure'),
        (r) => expect(r.id, 'division-id'),
      );
      verify(
        () => mockLocalDatasource.getDivisionById('division-id'),
      ).called(1);
      verifyNever(() => mockRemoteDatasource.getDivisionById(any()));
    });

    test('should fallback to remote when local is empty and online', () async {
      when(
        () => mockLocalDatasource.getDivisionById(any()),
      ).thenAnswer((_) async => null);
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => true);
      when(
        () => mockRemoteDatasource.getDivisionById(any()),
      ).thenAnswer((_) async => testModel);
      when(
        () => mockLocalDatasource.insertDivision(any()),
      ).thenAnswer((_) async {});

      final result = await repository.getDivisionById('division-id');

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return failure'),
        (r) => expect(r.id, 'division-id'),
      );
      verify(
        () => mockLocalDatasource.getDivisionById('division-id'),
      ).called(1);
      verify(
        () => mockRemoteDatasource.getDivisionById('division-id'),
      ).called(1);
      verify(() => mockLocalDatasource.insertDivision(any())).called(1);
    });

    test('should return failure when division not found', () async {
      when(
        () => mockLocalDatasource.getDivisionById(any()),
      ).thenAnswer((_) async => null);
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => false);

      final result = await repository.getDivisionById('division-id');

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<LocalCacheAccessFailure>()),
        (r) => fail('Should return failure'),
      );
    });
  });

  group('getDivisionsForTournament', () {
    test(
      'should return list of DivisionEntity when local data exists',
      () async {
        when(
          () => mockLocalDatasource.getDivisionsForTournament(any()),
        ).thenAnswer((_) async => [testModel]);
        when(
          () => mockConnectivityService.hasInternetConnection(),
        ).thenAnswer((_) async => false);

        final result = await repository.getDivisionsForTournament(
          'tournament-id',
        );

        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return failure'),
          (r) => expect(r.length, 1),
        );
        verify(
          () => mockLocalDatasource.getDivisionsForTournament('tournament-id'),
        ).called(1);
      },
    );
  });

  group('createDivision', () {
    test(
      'should insert division locally and sync to remote when online',
      () async {
        when(
          () => mockLocalDatasource.insertDivision(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockConnectivityService.hasInternetConnection(),
        ).thenAnswer((_) async => true);
        when(
          () => mockRemoteDatasource.insertDivision(any()),
        ).thenAnswer((_) async => testModel);

        final result = await repository.createDivision(testEntity);

        expect(result.isRight(), true);
        verify(() => mockLocalDatasource.insertDivision(any())).called(1);
        verify(() => mockRemoteDatasource.insertDivision(any())).called(1);
      },
    );

    test('should insert locally even when offline', () async {
      when(
        () => mockLocalDatasource.insertDivision(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => false);

      final result = await repository.createDivision(testEntity);

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.insertDivision(any())).called(1);
      verifyNever(() => mockRemoteDatasource.insertDivision(any()));
    });
  });

  group('updateDivision', () {
    test(
      'should update division locally and sync to remote when online',
      () async {
        when(
          () => mockLocalDatasource.getDivisionById(any()),
        ).thenAnswer((_) async => testModel);
        when(
          () => mockLocalDatasource.updateDivision(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockConnectivityService.hasInternetConnection(),
        ).thenAnswer((_) async => true);
        when(
          () => mockRemoteDatasource.updateDivision(any()),
        ).thenAnswer((_) async => testModel);

        final result = await repository.updateDivision(testEntity);

        expect(result.isRight(), true);
        verify(() => mockLocalDatasource.updateDivision(any())).called(1);
        verify(() => mockRemoteDatasource.updateDivision(any())).called(1);
      },
    );

    test('should queue for sync when offline during update', () async {
      when(
        () => mockLocalDatasource.getDivisionById(any()),
      ).thenAnswer((_) async => testModel);
      when(
        () => mockLocalDatasource.updateDivision(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => false);
      when(
        () => mockSyncQueue.enqueue(
          tableName: any(named: 'tableName'),
          recordId: any(named: 'recordId'),
          operation: any(named: 'operation'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.updateDivision(testEntity);

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.updateDivision(any())).called(1);
      verify(
        () => mockSyncQueue.enqueue(
          tableName: 'divisions',
          recordId: 'division-id',
          operation: 'update',
        ),
      ).called(1);
    });

    test('should queue for sync when remote fails during update', () async {
      when(
        () => mockLocalDatasource.getDivisionById(any()),
      ).thenAnswer((_) async => testModel);
      when(
        () => mockLocalDatasource.updateDivision(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => true);
      when(
        () => mockRemoteDatasource.updateDivision(any()),
      ).thenThrow(Exception('Network error'));
      when(
        () => mockSyncQueue.enqueue(
          tableName: any(named: 'tableName'),
          recordId: any(named: 'recordId'),
          operation: any(named: 'operation'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.updateDivision(testEntity);

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.updateDivision(any())).called(1);
      verify(
        () => mockSyncQueue.enqueue(
          tableName: 'divisions',
          recordId: 'division-id',
          operation: 'update',
        ),
      ).called(1);
    });
  });

  group('deleteDivision', () {
    test('should soft delete locally and sync to remote when online', () async {
      when(
        () => mockLocalDatasource.deleteDivision(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => true);
      when(
        () => mockRemoteDatasource.deleteDivision(any()),
      ).thenAnswer((_) async {});

      final result = await repository.deleteDivision('division-id');

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.deleteDivision('division-id')).called(1);
      verify(
        () => mockRemoteDatasource.deleteDivision('division-id'),
      ).called(1);
    });

    test('should return failure when error occurs', () async {
      when(
        () => mockLocalDatasource.getDivisionById(any()),
      ).thenThrow(Exception('Database error'));

      final result = await repository.updateDivision(testEntity);

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<LocalCacheWriteFailure>()),
        (r) => fail('Should return failure'),
      );
    });
  });
}
