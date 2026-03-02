import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/unlock_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/unlock_bracket_use_case.dart';

class MockBracketRepository extends Mock implements BracketRepository {}

void main() {
  late MockBracketRepository mockBracketRepo;
  late UnlockBracketUseCase useCase;

  setUpAll(() {
    registerFallbackValue(const UnlockBracketParams(bracketId: 'b1'));
    registerFallbackValue(
      BracketEntity(
        id: 'b1',
        divisionId: 'div1',
        bracketType: BracketType.winners,
        totalRounds: 3,
        createdAtTimestamp: DateTime(2026),
        updatedAtTimestamp: DateTime(2026),
      ),
    );
  });

  setUp(() {
    mockBracketRepo = MockBracketRepository();
    useCase = UnlockBracketUseCase(mockBracketRepo);
  });

  BracketEntity makeBracket({
    String id = 'bracket-1',
    bool isFinalized = false,
    DateTime? finalizedAtTimestamp,
  }) =>
      BracketEntity(
        id: id,
        divisionId: 'div1',
        bracketType: BracketType.winners,
        totalRounds: 3,
        createdAtTimestamp: DateTime(2026),
        updatedAtTimestamp: DateTime(2026),
        isFinalized: isFinalized,
        finalizedAtTimestamp: finalizedAtTimestamp,
      );

  const validParams = UnlockBracketParams(bracketId: 'bracket-1');

  group('Validation', () {
    test('empty bracketId → ValidationFailure', () async {
      final result = await useCase(
        const UnlockBracketParams(bracketId: ''),
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.getBracketById(any()));
    });

    test('whitespace-only bracketId → ValidationFailure', () async {
      final result = await useCase(
        const UnlockBracketParams(bracketId: '   '),
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.getBracketById(any()));
    });
  });

  group('Not finalized', () {
    test('not-finalized bracket → ValidationFailure with "not locked"', () async {
      when(() => mockBracketRepo.getBracketById('bracket-1'))
          .thenAnswer((_) async => Right(makeBracket(isFinalized: false)));

      final result = await useCase(validParams);
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) {
          expect(f, isA<ValidationFailure>());
          expect(f.userFriendlyMessage, contains('not locked'));
        },
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.updateBracket(any()));
    });
  });

  group('Success', () {
    test('unlocks bracket → returns entity with isFinalized=false', () async {
      final bracket = makeBracket(
        isFinalized: true,
        finalizedAtTimestamp: DateTime(2026),
      );
      when(() => mockBracketRepo.getBracketById('bracket-1'))
          .thenAnswer((_) async => Right(bracket));
      when(() => mockBracketRepo.updateBracket(any()))
          .thenAnswer((inv) async =>
              Right(inv.positionalArguments.first as BracketEntity));

      final result = await useCase(validParams);
      expect(result.isRight(), isTrue);

      result.fold(
        (_) => fail('Should be right'),
        (r) {
          expect(r.isFinalized, isFalse);
          expect(r.finalizedAtTimestamp, isNull);
        },
      );
    });

    test('unlocks bracket → verifies update called with correct entity', () async {
      final bracket = makeBracket(
        isFinalized: true,
        finalizedAtTimestamp: DateTime(2026),
      );
      when(() => mockBracketRepo.getBracketById('bracket-1'))
          .thenAnswer((_) async => Right(bracket));
      when(() => mockBracketRepo.updateBracket(any()))
          .thenAnswer((inv) async =>
              Right(inv.positionalArguments.first as BracketEntity));

      await useCase(validParams);

      final captured = verify(
        () => mockBracketRepo.updateBracket(captureAny()),
      ).captured.single as BracketEntity;

      expect(captured.isFinalized, isFalse);
      expect(captured.finalizedAtTimestamp, isNull);
      expect(captured.id, equals('bracket-1'));
    });
  });

  group('Error propagation', () {
    test('getBracketById returns NotFoundFailure → propagates failure', () async {
      when(() => mockBracketRepo.getBracketById('bracket-1'))
          .thenAnswer((_) async => const Left(
                NotFoundFailure(userFriendlyMessage: 'Bracket not found'),
              ));

      final result = await useCase(validParams);
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.updateBracket(any()));
    });

    test('getBracketById returns LocalCacheAccessFailure → propagates failure', () async {
      when(() => mockBracketRepo.getBracketById('bracket-1'))
          .thenAnswer((_) async => const Left(LocalCacheAccessFailure()));

      final result = await useCase(validParams);
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<LocalCacheAccessFailure>()),
        (_) => fail('Should have failed'),
      );
      verifyNever(() => mockBracketRepo.updateBracket(any()));
    });

    test('updateBracket fails → propagates failure', () async {
      when(() => mockBracketRepo.getBracketById('bracket-1'))
          .thenAnswer((_) async => Right(makeBracket(isFinalized: true)));
      when(() => mockBracketRepo.updateBracket(any()))
          .thenAnswer((_) async => const Left(LocalCacheWriteFailure()));

      final result = await useCase(validParams);
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<LocalCacheWriteFailure>()),
        (_) => fail('Should have failed'),
      );
    });
  });
}
