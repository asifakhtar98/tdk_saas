import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/disqualify_participant_usecase.dart';

class MockParticipantRepository extends Mock implements ParticipantRepository {}

class FakeParticipantEntity extends Fake implements ParticipantEntity {}

void main() {
  late DisqualifyParticipantUseCase useCase;
  late MockParticipantRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeParticipantEntity());
  });

  setUp(() {
    mockRepository = MockParticipantRepository();
    useCase = DisqualifyParticipantUseCase(mockRepository);
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

  group('DisqualifyParticipantUseCase', () {
    group('validation', () {
      test('returns InputValidationFailure when dqReason is empty', () async {
        final result = await useCase(participantId: 'test-id', dqReason: '');

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<InputValidationFailure>());
          final validationFailure = failure as InputValidationFailure;
          expect(validationFailure.fieldErrors['dqReason'], isNotNull);
        }, (_) => fail('Expected Left'));
        verifyNever(() => mockRepository.getParticipantById(any()));
      });

      test(
        'returns InputValidationFailure when dqReason is whitespace only',
        () async {
          final result = await useCase(
            participantId: 'test-id',
            dqReason: '   ',
          );

          expect(result.isLeft(), isTrue);
          result.fold((failure) {
            expect(failure, isA<InputValidationFailure>());
            final validationFailure = failure as InputValidationFailure;
            expect(validationFailure.fieldErrors['dqReason'], isNotNull);
          }, (_) => fail('Expected Left'));
          verifyNever(() => mockRepository.getParticipantById(any()));
        },
      );

      test('validates before making repository calls', () async {
        await useCase(participantId: 'test-id', dqReason: '');

        verifyNever(() => mockRepository.getParticipantById(any()));
        verifyNever(() => mockRepository.updateParticipant(any()));
      });
    });

    group('successful disqualification', () {
      test('returns updated participant with disqualified status', () async {
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

        final result = await useCase(
          participantId: 'test-id',
          dqReason: 'Rule violation',
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (participant) {
          expect(
            participant.checkInStatus,
            equals(ParticipantStatus.disqualified),
          );
        });
      });

      test('sets dqReason to trimmed value', () async {
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

        final result = await useCase(
          participantId: 'test-id',
          dqReason: '  Rule violation  ',
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (participant) {
          expect(participant.dqReason, equals('Rule violation'));
        });
      });

      test('clears checkInAtTimestamp when disqualifying', () async {
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

        final result = await useCase(
          participantId: 'test-id',
          dqReason: 'Rule violation',
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (participant) {
          expect(participant.checkInAtTimestamp, isNull);
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

        final result = await useCase(
          participantId: 'test-id',
          dqReason: 'Rule violation',
        );

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

        final result = await useCase(
          participantId: 'test-id',
          dqReason: 'Rule violation',
        );
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

        final result = await useCase(
          participantId: 'nonexistent',
          dqReason: 'Rule violation',
        );

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

        final result = await useCase(
          participantId: 'test-id',
          dqReason: 'Rule violation',
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<LocalCacheWriteFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });
  });
}
