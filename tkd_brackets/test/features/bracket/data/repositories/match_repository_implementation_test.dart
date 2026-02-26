import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/bracket/data/datasources/match_local_datasource.dart';
import 'package:tkd_brackets/features/bracket/data/datasources/match_remote_datasource.dart';
import 'package:tkd_brackets/features/bracket/data/models/match_model.dart';
import 'package:tkd_brackets/features/bracket/data/repositories/match_repository_implementation.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';

class MockMatchLocalDatasource extends Mock
    implements MatchLocalDatasource {}

class MockMatchRemoteDatasource extends Mock
    implements MatchRemoteDatasource {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MatchRepositoryImplementation repository;
  late MockMatchLocalDatasource mockLocal;
  late MockMatchRemoteDatasource mockRemote;
  late MockConnectivityService mockConnectivity;

  final testDateTime = DateTime(2026, 1, 15, 10, 30);

  final testEntity = MatchEntity(
    id: 'm1',
    bracketId: 'b1',
    roundNumber: 1,
    matchNumberInRound: 1,
    createdAtTimestamp: testDateTime,
    updatedAtTimestamp: testDateTime,
  );

  final testModel = MatchModel.convertFromEntity(testEntity);

  setUpAll(() {
    registerFallbackValue(testModel);
    registerFallbackValue(testEntity);
  });

  setUp(() {
    mockLocal = MockMatchLocalDatasource();
    mockRemote = MockMatchRemoteDatasource();
    mockConnectivity = MockConnectivityService();
    repository = MatchRepositoryImplementation(
      mockLocal,
      mockRemote,
      mockConnectivity,
    );
  });

  group('getMatchesForBracket', () {
    test('should return Right with list of entities from local',
        () async {
      when(() => mockLocal.getMatchesForBracket(any()))
          .thenAnswer((_) async => [testModel]);

      final result = await repository.getMatchesForBracket('b1');

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should not return Left'),
        (r) => expect(r.length, 1),
      );
      verify(() => mockLocal.getMatchesForBracket('b1')).called(1);
    });

    test(
        'should return Left with LocalCacheAccessFailure on exception',
        () async {
      when(() => mockLocal.getMatchesForBracket(any()))
          .thenThrow(Exception('DB error'));

      final result = await repository.getMatchesForBracket('b1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<LocalCacheAccessFailure>()),
        (r) => fail('Should not return Right'),
      );
    });
  });

  group('getMatchesForRound', () {
    test('should return Right with list of entities from local',
        () async {
      when(() => mockLocal.getMatchesForRound(any(), any()))
          .thenAnswer((_) async => [testModel]);

      final result =
          await repository.getMatchesForRound('b1', 1);

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should not return Left'),
        (r) => expect(r.length, 1),
      );
      verify(() => mockLocal.getMatchesForRound('b1', 1))
          .called(1);
    });

    test(
        'should return Left with LocalCacheAccessFailure on exception',
        () async {
      when(() => mockLocal.getMatchesForRound(any(), any()))
          .thenThrow(Exception('DB error'));

      final result =
          await repository.getMatchesForRound('b1', 1);

      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<LocalCacheAccessFailure>()),
        (r) => fail('Should not return Right'),
      );
    });
  });

  group('getMatchById', () {
    test('should return Right when found locally', () async {
      when(() => mockLocal.getMatchById(any()))
          .thenAnswer((_) async => testModel);

      final result = await repository.getMatchById('m1');

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should not return Left'),
        (r) => expect(r.id, 'm1'),
      );
      verify(() => mockLocal.getMatchById('m1')).called(1);
      verifyNever(() => mockRemote.getMatchById(any()));
    });

    test(
        'should return Left(NotFoundFailure) when not found '
        'locally and offline', () async {
      when(() => mockLocal.getMatchById(any()))
          .thenAnswer((_) async => null);
      when(() => mockConnectivity.hasInternetConnection())
          .thenAnswer((_) async => false);

      final result = await repository.getMatchById('m1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<NotFoundFailure>()),
        (r) => fail('Should not return Right'),
      );
      verifyNever(() => mockRemote.getMatchById(any()));
    });

    test(
        'should return Right when found remotely and cache locally',
        () async {
      when(() => mockLocal.getMatchById(any()))
          .thenAnswer((_) async => null);
      when(() => mockConnectivity.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemote.getMatchById(any()))
          .thenAnswer((_) async => testModel);
      when(() => mockLocal.insertMatch(any()))
          .thenAnswer((_) async => unit);

      final result = await repository.getMatchById('m1');

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should not return Left'),
        (r) => expect(r.id, 'm1'),
      );
      verify(() => mockRemote.getMatchById('m1')).called(1);
      verify(() => mockLocal.insertMatch(any())).called(1);
    });

    test(
        'should return Left(NotFoundFailure) when both local '
        'and remote fail', () async {
      when(() => mockLocal.getMatchById(any()))
          .thenAnswer((_) async => null);
      when(() => mockConnectivity.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemote.getMatchById(any()))
          .thenAnswer((_) async => null);

      final result = await repository.getMatchById('m1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<NotFoundFailure>()),
        (r) => fail('Should not return Right'),
      );
    });
  });

  group('createMatch', () {
    test(
        'should return Right and call both datasources when online',
        () async {
      when(() => mockLocal.insertMatch(any()))
          .thenAnswer((_) async => unit);
      when(() => mockConnectivity.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemote.insertMatch(any()))
          .thenAnswer((_) async => unit);

      final result = await repository.createMatch(testEntity);

      expect(result.isRight(), isTrue);
      verify(() => mockLocal.insertMatch(any())).called(1);
      verify(() => mockRemote.insertMatch(any())).called(1);
    });

    test(
        'should return Right with only local insert when offline',
        () async {
      when(() => mockLocal.insertMatch(any()))
          .thenAnswer((_) async => unit);
      when(() => mockConnectivity.hasInternetConnection())
          .thenAnswer((_) async => false);

      final result = await repository.createMatch(testEntity);

      expect(result.isRight(), isTrue);
      verify(() => mockLocal.insertMatch(any())).called(1);
      verifyNever(() => mockRemote.insertMatch(any()));
    });

    test(
        'should return Left with LocalCacheWriteFailure '
        'on exception', () async {
      when(() => mockLocal.insertMatch(any()))
          .thenThrow(Exception('DB write failed'));

      final result = await repository.createMatch(testEntity);

      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<LocalCacheWriteFailure>()),
        (r) => fail('Should not return Right'),
      );
    });
  });

  group('updateMatch', () {
    test(
        'should increment syncVersion and call local update',
        () async {
      when(() => mockLocal.getMatchById(any()))
          .thenAnswer((_) async => testModel);
      when(() => mockLocal.updateMatch(any()))
          .thenAnswer((_) async => unit);
      when(() => mockConnectivity.hasInternetConnection())
          .thenAnswer((_) async => false);

      final result = await repository.updateMatch(testEntity);

      expect(result.isRight(), isTrue);
      final updated = result.fold((l) => null, (r) => r)!;
      expect(updated.syncVersion, 2);
      verify(() => mockLocal.updateMatch(any())).called(1);
    });

    test(
        'should return Left with LocalCacheWriteFailure '
        'on exception', () async {
      when(() => mockLocal.getMatchById(any()))
          .thenThrow(Exception('DB read failed'));

      final result = await repository.updateMatch(testEntity);

      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<LocalCacheWriteFailure>()),
        (r) => fail('Should not return Right'),
      );
    });
  });

  group('deleteMatch', () {
    test('should return Right(unit) when offline', () async {
      when(() => mockLocal.deleteMatch(any()))
          .thenAnswer((_) async => unit);
      when(() => mockConnectivity.hasInternetConnection())
          .thenAnswer((_) async => false);

      final result = await repository.deleteMatch('m1');

      expect(result.isRight(), isTrue);
      verify(() => mockLocal.deleteMatch('m1')).called(1);
      verifyNever(() => mockRemote.deleteMatch(any()));
    });

    test('should call remote when online', () async {
      when(() => mockLocal.deleteMatch(any()))
          .thenAnswer((_) async => unit);
      when(() => mockConnectivity.hasInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockRemote.deleteMatch(any()))
          .thenAnswer((_) async => unit);

      final result = await repository.deleteMatch('m1');

      expect(result.isRight(), isTrue);
      verify(() => mockLocal.deleteMatch('m1')).called(1);
      verify(() => mockRemote.deleteMatch('m1')).called(1);
    });

    test(
        'should return Left with LocalCacheWriteFailure '
        'on exception', () async {
      when(() => mockLocal.deleteMatch(any()))
          .thenThrow(Exception('DB delete failed'));

      final result = await repository.deleteMatch('m1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<LocalCacheWriteFailure>()),
        (r) => fail('Should not return Right'),
      );
    });
  });
}
