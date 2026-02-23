import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/mark_no_show_usecase.dart';

class MockParticipantRepository extends Mock implements ParticipantRepository {}

class FakeParticipantEntity extends Fake implements ParticipantEntity {}

void main() {
  late MarkNoShowUseCase useCase;
  late MockParticipantRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeParticipantEntity());
  });

  setUp(() {
    mockRepository = MockParticipantRepository();
    useCase = MarkNoShowUseCase(mockRepository);
  });

  final tParticipant = ParticipantEntity(
    id: 'test-id',
    divisionId: 'division-id',
    firstName: 'John',
    lastName: 'Doe',
    checkInStatus: ParticipantStatus.pending,
    syncVersion: 1,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  group('MarkNoShowUseCase', () {
    group('successful marking', () {
      test('returns updated participant with noShow status', () async {
        when(
          () => mockRepository.getParticipantById('test-id'),
        ).thenAnswer((_) async => Right(tParticipant));
        when(() => mockRepository.updateParticipant(any())).thenAnswer((
          invocation,
        ) async {
          final participant =
              invocation.positionalArguments.first as ParticipantEntity;
          return Right(participant);
        });

        final result = await useCase('test-id');

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (participant) {
          expect(participant.checkInStatus, equals(ParticipantStatus.noShow));
        });
        verify(() => mockRepository.updateParticipant(any())).called(1);
      });

      test('clears checkInAtTimestamp when marking no-show', () async {
        final checkedInParticipant = tParticipant.copyWith(
          checkInStatus: ParticipantStatus.checkedIn,
          checkInAtTimestamp: DateTime(2024, 1, 15),
        );
        when(
          () => mockRepository.getParticipantById('test-id'),
        ).thenAnswer((_) async => Right(checkedInParticipant));
        when(() => mockRepository.updateParticipant(any())).thenAnswer((
          invocation,
        ) async {
          final participant =
              invocation.positionalArguments.first as ParticipantEntity;
          return Right(participant);
        });

        final result = await useCase('test-id');

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (participant) {
          expect(participant.checkInAtTimestamp, isNull);
        });
      });

      test('clears dqReason when marking no-show', () async {
        final dqParticipant = tParticipant.copyWith(
          checkInStatus: ParticipantStatus.disqualified,
          dqReason: 'Previous DQ reason',
        );
        when(
          () => mockRepository.getParticipantById('test-id'),
        ).thenAnswer((_) async => Right(dqParticipant));
        when(() => mockRepository.updateParticipant(any())).thenAnswer((
          invocation,
        ) async {
          final participant =
              invocation.positionalArguments.first as ParticipantEntity;
          return Right(participant);
        });

        final result = await useCase('test-id');

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (participant) {
          expect(participant.dqReason, isNull);
        });
      });

      test('increments syncVersion', () async {
        when(
          () => mockRepository.getParticipantById('test-id'),
        ).thenAnswer((_) async => Right(tParticipant));
        when(() => mockRepository.updateParticipant(any())).thenAnswer((
          invocation,
        ) async {
          final participant =
              invocation.positionalArguments.first as ParticipantEntity;
          return Right(participant);
        });

        final result = await useCase('test-id');

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (participant) {
          expect(participant.syncVersion, equals(2));
        });
      });

      test('updates updatedAtTimestamp', () async {
        final beforeUpdate = DateTime.now();
        when(
          () => mockRepository.getParticipantById('test-id'),
        ).thenAnswer((_) async => Right(tParticipant));
        when(() => mockRepository.updateParticipant(any())).thenAnswer((
          invocation,
        ) async {
          final participant =
              invocation.positionalArguments.first as ParticipantEntity;
          return Right(participant);
        });

        final result = await useCase('test-id');
        final afterUpdate = DateTime.now();

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (participant) {
          expect(
            participant.updatedAtTimestamp.isAfter(
              beforeUpdate.subtract(const Duration(seconds: 1)),
            ),
            isTrue,
          );
          expect(
            participant.updatedAtTimestamp.isBefore(
              afterUpdate.add(const Duration(seconds: 1)),
            ),
            isTrue,
          );
        });
      });
    });

    group('failure handling', () {
      test('returns NotFoundFailure when participant not found', () async {
        when(() => mockRepository.getParticipantById('nonexistent')).thenAnswer(
          (_) async => const Left(
            NotFoundFailure(userFriendlyMessage: 'Participant not found'),
          ),
        );

        final result = await useCase('nonexistent');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyNever(() => mockRepository.updateParticipant(any()));
      });

      test('propagates repository update failure', () async {
        when(
          () => mockRepository.getParticipantById('test-id'),
        ).thenAnswer((_) async => Right(tParticipant));
        when(
          () => mockRepository.updateParticipant(any()),
        ).thenAnswer((_) async => const Left(LocalCacheWriteFailure()));

        final result = await useCase('test-id');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<LocalCacheWriteFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });
  });
}
