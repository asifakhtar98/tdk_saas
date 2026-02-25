import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/bracket/data/datasources/bracket_local_datasource.dart';
import 'package:tkd_brackets/features/bracket/data/datasources/bracket_remote_datasource.dart';
import 'package:tkd_brackets/features/bracket/data/models/bracket_model.dart';
import 'package:tkd_brackets/features/bracket/data/repositories/bracket_repository_implementation.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';

class MockBracketLocalDatasource extends Mock
    implements BracketLocalDatasource {}

class MockBracketRemoteDatasource extends Mock
    implements BracketRemoteDatasource {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late BracketRepositoryImplementation repository;
  late MockBracketLocalDatasource mockLocalDatasource;
  late MockBracketRemoteDatasource mockRemoteDatasource;
  late MockConnectivityService mockConnectivityService;
  late MockAppDatabase mockAppDatabase;

  final testDateTime = DateTime(2026, 1, 15, 10, 30);

  final testModel = BracketModel(
    id: 'bracket-1',
    divisionId: 'division-1',
    bracketType: 'winners',
    totalRounds: 4,
    syncVersion: 1,
    createdAtTimestamp: testDateTime,
    updatedAtTimestamp: testDateTime,
  );

  final testEntity = BracketEntity(
    id: 'bracket-1',
    divisionId: 'division-1',
    bracketType: BracketType.winners,
    totalRounds: 4,
    syncVersion: 1,
    createdAtTimestamp: testDateTime,
    updatedAtTimestamp: testDateTime,
  );

  setUpAll(() {
    registerFallbackValue(testModel);
    registerFallbackValue(testEntity);
  });

  setUp(() {
    mockLocalDatasource = MockBracketLocalDatasource();
    mockRemoteDatasource = MockBracketRemoteDatasource();
    mockConnectivityService = MockConnectivityService();
    mockAppDatabase = MockAppDatabase();
    repository = BracketRepositoryImplementation(
      mockLocalDatasource,
      mockRemoteDatasource,
      mockConnectivityService,
      mockAppDatabase,
    );
  });

  group('getBracketsForDivision', () {
    test('should return Right with list of entities from local', () async {
      when(
        () => mockLocalDatasource.getBracketsForDivision('division-1'),
      ).thenAnswer((_) async => [testModel]);

      final result = await repository.getBracketsForDivision('division-1');

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return Left'),
        (r) => expect(r.first.id, 'bracket-1'),
      );
      verify(() => mockLocalDatasource.getBracketsForDivision('division-1'))
          .called(1);
    });

    test('should return Left with LocalCacheAccessFailure on exception',
        () async {
      when(
        () => mockLocalDatasource.getBracketsForDivision('division-1'),
      ).thenThrow(Exception('DB error'));

      final result = await repository.getBracketsForDivision('division-1');

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<LocalCacheAccessFailure>()),
        (r) => fail('Should not return Right'),
      );
    });
  });

  group('getBracketById', () {
    test('should return entity if found locally', () async {
      when(
        () => mockLocalDatasource.getBracketById('bracket-1'),
      ).thenAnswer((_) async => testModel);

      final result = await repository.getBracketById('bracket-1');

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.getBracketById('bracket-1')).called(1);
    });

    test('should fetch from remote if not found locally and online', () async {
      when(
        () => mockLocalDatasource.getBracketById('bracket-1'),
      ).thenAnswer((_) async => null);
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => true);
      when(
        () => mockRemoteDatasource.getBracketById('bracket-1'),
      ).thenAnswer((_) async => testModel);
      when(
        () => mockLocalDatasource.insertBracket(any()),
      ).thenAnswer((_) async {});

      final result = await repository.getBracketById('bracket-1');

      expect(result.isRight(), true);
      verify(() => mockRemoteDatasource.getBracketById('bracket-1')).called(1);
      verify(() => mockLocalDatasource.insertBracket(any())).called(1);
    });

    test('should return NotFoundFailure when not found locally and offline',
        () async {
      when(
        () => mockLocalDatasource.getBracketById('bracket-1'),
      ).thenAnswer((_) async => null);
      when(
        () => mockConnectivityService.hasInternetConnection(),
      ).thenAnswer((_) async => false);

      final result = await repository.getBracketById('bracket-1');

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<NotFoundFailure>()),
        (r) => fail('Should not return Right'),
      );
      verifyNever(() => mockRemoteDatasource.getBracketById(any()));
    });
  });

  group('createBracket', () {
    test('should return Right and call both datasources when online', () async {
      when(() => mockLocalDatasource.insertBracket(any()))
          .thenAnswer((_) async {});
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemoteDatasource.insertBracket(any()))
          .thenAnswer((_) async {});

      final result = await repository.createBracket(testEntity);

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.insertBracket(any())).called(1);
      verify(() => mockRemoteDatasource.insertBracket(any())).called(1);
    });

    test('should return Right with only local insert when offline', () async {
      when(() => mockLocalDatasource.insertBracket(any()))
          .thenAnswer((_) async {});
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => false);

      final result = await repository.createBracket(testEntity);

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.insertBracket(any())).called(1);
      verifyNever(() => mockRemoteDatasource.insertBracket(any()));
    });

    test('should return Left with LocalCacheWriteFailure on exception',
        () async {
      when(() => mockLocalDatasource.insertBracket(any()))
          .thenThrow(Exception('DB write failed'));

      final result = await repository.createBracket(testEntity);

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<LocalCacheWriteFailure>()),
        (r) => fail('Should not return Right'),
      );
    });
  });

  group('updateBracket', () {
    test('should increment syncVersion and call local update', () async {
      when(() => mockLocalDatasource.getBracketById('bracket-1'))
          .thenAnswer((_) async => testModel);
      when(() => mockLocalDatasource.updateBracket(any()))
          .thenAnswer((_) async {});
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => false);

      final result = await repository.updateBracket(testEntity);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return Left'),
        (r) => expect(r.syncVersion, 2),
      );
    });
  });

  group('deleteBracket', () {
    test('should call local delete', () async {
      when(() => mockLocalDatasource.deleteBracket('bracket-1'))
          .thenAnswer((_) async {});
      when(() => mockConnectivityService.hasInternetConnection())
          .thenAnswer((_) async => false);

      final result = await repository.deleteBracket('bracket-1');

      expect(result.isRight(), true);
      verify(() => mockLocalDatasource.deleteBracket('bracket-1')).called(1);
    });

    test('should return Left with LocalCacheWriteFailure on exception',
        () async {
      when(() => mockLocalDatasource.deleteBracket('bracket-1'))
          .thenThrow(Exception('DB delete failed'));

      final result = await repository.deleteBracket('bracket-1');

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<LocalCacheWriteFailure>()),
        (r) => fail('Should not return Right'),
      );
    });
  });
}
