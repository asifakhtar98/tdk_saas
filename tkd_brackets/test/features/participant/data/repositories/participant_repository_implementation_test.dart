import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/participant/data/datasources/participant_local_datasource.dart';
import 'package:tkd_brackets/features/participant/data/datasources/participant_remote_datasource.dart';
import 'package:tkd_brackets/features/participant/data/models/participant_model.dart';
import 'package:tkd_brackets/features/participant/data/repositories/participant_repository_implementation.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';

class MockParticipantLocalDatasource extends Mock
    implements ParticipantLocalDatasource {}

class MockParticipantRemoteDatasource extends Mock
    implements ParticipantRemoteDatasource {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late ParticipantRepositoryImplementation repository;
  late MockParticipantLocalDatasource mockLocalDatasource;
  late MockParticipantRemoteDatasource mockRemoteDatasource;
  late MockConnectivityService mockConnectivityService;

  final testDateTime = DateTime(2026, 1, 15, 10, 30);

  final testModel = ParticipantModel(
    id: 'id-1',
    divisionId: 'division-1',
    firstName: 'John',
    lastName: 'Doe',
    dateOfBirth: null,
    gender: 'male',
    weightKg: 65.5,
    schoolOrDojangName: 'Test Dojang',
    beltRank: 'black 1dan',
    seedNumber: 1,
    registrationNumber: 'REG-001',
    isBye: false,
    checkInStatus: 'pending',
    checkInAtTimestamp: null,
    photoUrl: null,
    notes: null,
    syncVersion: 1,
    isDeleted: false,
    deletedAtTimestamp: null,
    isDemoData: false,
    createdAtTimestamp: testDateTime,
    updatedAtTimestamp: testDateTime,
  );

  final testEntity = ParticipantEntity(
    id: 'id-1',
    divisionId: 'division-1',
    firstName: 'John',
    lastName: 'Doe',
    gender: Gender.male,
    weightKg: 65.5,
    schoolOrDojangName: 'Test Dojang',
    beltRank: 'black 1dan',
    seedNumber: 1,
    registrationNumber: 'REG-001',
    createdAtTimestamp: testDateTime,
    updatedAtTimestamp: testDateTime,
  );

  setUpAll(() {
    registerFallbackValue(testModel);
    registerFallbackValue(testEntity);
  });

  setUp(() {
    mockLocalDatasource = MockParticipantLocalDatasource();
    mockRemoteDatasource = MockParticipantRemoteDatasource();
    mockConnectivityService = MockConnectivityService();
    repository = ParticipantRepositoryImplementation(
      mockLocalDatasource,
      mockRemoteDatasource,
      mockConnectivityService,
    );
  });

  group('getParticipantsForDivision', () {
    test('should return Right with list of entities when offline', () async {
      when(
        () => mockLocalDatasource.getParticipantsForDivision('division-1'),
      ).thenAnswer((_) async => [testModel]);
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => false);

      final result = await repository.getParticipantsForDivision('division-1');

      expect(result.isRight(), true);
      result.fold((l) => fail('Should not return Left'), (r) {
        expect(r.length, 1);
        expect(r.first.id, 'id-1');
      });
      verify(
        () => mockLocalDatasource.getParticipantsForDivision('division-1'),
      ).called(1);
      verifyNever(() => mockRemoteDatasource.getParticipantsForDivision(any()));
    });

    test(
      'should return Left with LocalCacheAccessFailure on exception',
      () async {
        when(
          () => mockLocalDatasource.getParticipantsForDivision('division-1'),
        ).thenThrow(Exception('Database error'));

        final result = await repository.getParticipantsForDivision(
          'division-1',
        );

        expect(result.isLeft(), true);
      },
    );
  });

  group('getParticipantById', () {
    test('should return Right with entity when found locally', () async {
      when(
        () => mockLocalDatasource.getParticipantById('id-1'),
      ).thenAnswer((_) async => testModel);

      final result = await repository.getParticipantById('id-1');

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return Left'),
        (r) => expect(r.id, 'id-1'),
      );
      verify(() => mockLocalDatasource.getParticipantById('id-1')).called(1);
    });

    test(
      'should return Left with NotFoundFailure when not found locally and offline',
      () async {
        when(
          () => mockLocalDatasource.getParticipantById('unknown-id'),
        ).thenAnswer((_) async => null);
        when(
          () => mockConnectivityService.hasInternetConnection(),
        ).thenAnswer((_) async => false);

        final result = await repository.getParticipantById('unknown-id');

        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<NotFoundFailure>()),
          (r) => fail('Should not return Right'),
        );
      },
    );

    test(
      'should return Right with entity when not found locally but found remotely',
      () async {
        when(
          () => mockLocalDatasource.getParticipantById('id-1'),
        ).thenAnswer((_) async => null);
        when(
          () => mockRemoteDatasource.getParticipantById('id-1'),
        ).thenAnswer((_) async => testModel);
        when(
          () => mockConnectivityService.hasInternetConnection(),
        ).thenAnswer((_) async => true);
        when(
          () => mockLocalDatasource.insertParticipant(any()),
        ).thenAnswer((_) async {});

        final result = await repository.getParticipantById('id-1');

        expect(result.isRight(), true);
        verify(() => mockRemoteDatasource.getParticipantById('id-1')).called(1);
        verify(() => mockLocalDatasource.insertParticipant(any())).called(1);
      },
    );
  });

  group('createParticipant', () {
    test('should return Right with entity when offline', () async {
      when(
        () => mockLocalDatasource.insertParticipant(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => false);

      final result = await repository.createParticipant(testEntity);

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.insertParticipant(any())).called(1);
      verifyNever(() => mockRemoteDatasource.insertParticipant(any()));
    });

    test(
      'should return Left with LocalCacheWriteFailure on exception',
      () async {
        when(
          () => mockLocalDatasource.insertParticipant(any()),
        ).thenThrow(Exception('Database error'));

        final result = await repository.createParticipant(testEntity);

        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<LocalCacheWriteFailure>()),
          (r) => fail('Should not return Right'),
        );
      },
    );
  });

  group('updateParticipant', () {
    test(
      'should return Right with entity with incremented syncVersion',
      () async {
        when(
          () => mockLocalDatasource.getParticipantById('id-1'),
        ).thenAnswer((_) async => testModel);
        when(
          () => mockLocalDatasource.updateParticipant(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockConnectivityService.hasInternetConnection(),
        ).thenAnswer((_) async => false);

        final result = await repository.updateParticipant(testEntity);

        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return Left'),
          (r) => expect(r.syncVersion, 2),
        );
        verify(() => mockLocalDatasource.updateParticipant(any())).called(1);
      },
    );
  });

  group('deleteParticipant', () {
    test('should return Right(unit) when offline', () async {
      when(
        () => mockLocalDatasource.deleteParticipant('id-1'),
      ).thenAnswer((_) async {});
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => false);

      final result = await repository.deleteParticipant('id-1');

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.deleteParticipant('id-1')).called(1);
    });

    test(
      'should return Left with LocalCacheWriteFailure on exception',
      () async {
        when(
          () => mockLocalDatasource.deleteParticipant('id-1'),
        ).thenThrow(Exception('Database error'));

        final result = await repository.deleteParticipant('id-1');

        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<LocalCacheWriteFailure>()),
          (r) => fail('Should not return Right'),
        );
      },
    );
  });
}
