import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/update_participant_status_usecase.dart';

class MockParticipantRepository extends Mock implements ParticipantRepository {}

class FakeParticipantEntity extends Fake implements ParticipantEntity {}

void main() {
  late UpdateParticipantStatusUseCase useCase;
  late MockParticipantRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeParticipantEntity());
  });

  setUp(() {
    mockRepository = MockParticipantRepository();
    useCase = UpdateParticipantStatusUseCase(mockRepository);
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

  group('UpdateParticipantStatusUseCase', () {
    group('validation - dqReason for disqualified status', () {
      test(
        'returns InputValidationFailure when transitioning to disqualified without reason',
        () async {
          final result = await useCase(
            participantId: 'test-id',
            newStatus: ParticipantStatus.disqualified,
            dqReason: null,
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

      test(
        'returns InputValidationFailure when dqReason is empty string',
        () async {
          final result = await useCase(
            participantId: 'test-id',
            newStatus: ParticipantStatus.disqualified,
            dqReason: '',
          );

          expect(result.isLeft(), isTrue);
          result.fold((failure) {
            expect(failure, isA<InputValidationFailure>());
          }, (_) => fail('Expected Left'));
        },
      );
    });

    group('status transition validation', () {
      test('allows pending -> checkedIn transition', () async {
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
          newStatus: ParticipantStatus.checkedIn,
        );

        expect(result.isRight(), isTrue);
      });

      test('allows pending -> noShow transition', () async {
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
          newStatus: ParticipantStatus.noShow,
        );

        expect(result.isRight(), isTrue);
      });

      test('allows pending -> withdrawn transition', () async {
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
          newStatus: ParticipantStatus.withdrawn,
        );

        expect(result.isRight(), isTrue);
      });

      test('allows pending -> disqualified transition with reason', () async {
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
          newStatus: ParticipantStatus.disqualified,
          dqReason: 'Rule violation',
        );

        expect(result.isRight(), isTrue);
      });

      test('allows checkedIn -> withdrawn transition', () async {
        final checkedInParticipant = tParticipant.copyWith(
          checkInStatus: ParticipantStatus.checkedIn,
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
          newStatus: ParticipantStatus.withdrawn,
        );

        expect(result.isRight(), isTrue);
      });

      test('allows checkedIn -> disqualified transition with reason', () async {
        final checkedInParticipant = tParticipant.copyWith(
          checkInStatus: ParticipantStatus.checkedIn,
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
          newStatus: ParticipantStatus.disqualified,
          dqReason: 'Rule violation',
        );

        expect(result.isRight(), isTrue);
      });

      test('allows noShow -> pending transition (undo)', () async {
        final noShowParticipant = tParticipant.copyWith(
          checkInStatus: ParticipantStatus.noShow,
        );
        when(
          () => mockRepository.getParticipantById('test-id'),
        ).thenAnswer((_) async => Right(noShowParticipant));
        when(() => mockRepository.updateParticipant(any())).thenAnswer((
          invocation,
        ) async {
          final participant =
              invocation.positionalArguments.first as ParticipantEntity;
          return Right(participant);
        });

        final result = await useCase(
          participantId: 'test-id',
          newStatus: ParticipantStatus.pending,
        );

        expect(result.isRight(), isTrue);
      });

      test('allows withdrawn -> pending transition (undo)', () async {
        final withdrawnParticipant = tParticipant.copyWith(
          checkInStatus: ParticipantStatus.withdrawn,
        );
        when(
          () => mockRepository.getParticipantById('test-id'),
        ).thenAnswer((_) async => Right(withdrawnParticipant));
        when(() => mockRepository.updateParticipant(any())).thenAnswer((
          invocation,
        ) async {
          final participant =
              invocation.positionalArguments.first as ParticipantEntity;
          return Right(participant);
        });

        final result = await useCase(
          participantId: 'test-id',
          newStatus: ParticipantStatus.pending,
        );

        expect(result.isRight(), isTrue);
      });

      test('allows disqualified -> pending transition (undo DQ)', () async {
        final dqParticipant = tParticipant.copyWith(
          checkInStatus: ParticipantStatus.disqualified,
          dqReason: 'Previous violation',
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

        final result = await useCase(
          participantId: 'test-id',
          newStatus: ParticipantStatus.pending,
        );

        expect(result.isRight(), isTrue);
      });

      test('allows same status (idempotent)', () async {
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
          newStatus: ParticipantStatus.pending,
        );

        expect(result.isRight(), isTrue);
      });

      test('rejects checkedIn -> noShow transition', () async {
        final checkedInParticipant = tParticipant.copyWith(
          checkInStatus: ParticipantStatus.checkedIn,
        );
        when(
          () => mockRepository.getParticipantById('test-id'),
        ).thenAnswer((_) async => Right(checkedInParticipant));

        final result = await useCase(
          participantId: 'test-id',
          newStatus: ParticipantStatus.noShow,
        );

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<InputValidationFailure>());
          final validationFailure = failure as InputValidationFailure;
          expect(validationFailure.fieldErrors['status'], contains('Invalid'));
        }, (_) => fail('Expected Left'));
        verifyNever(() => mockRepository.updateParticipant(any()));
      });

      test('rejects noShow -> disqualified transition', () async {
        final noShowParticipant = tParticipant.copyWith(
          checkInStatus: ParticipantStatus.noShow,
        );
        when(
          () => mockRepository.getParticipantById('test-id'),
        ).thenAnswer((_) async => Right(noShowParticipant));

        final result = await useCase(
          participantId: 'test-id',
          newStatus: ParticipantStatus.disqualified,
          dqReason: 'Late DQ',
        );

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<InputValidationFailure>());
        }, (_) => fail('Expected Left'));
      });

      test('rejects noShow -> withdrawn transition', () async {
        final noShowParticipant = tParticipant.copyWith(
          checkInStatus: ParticipantStatus.noShow,
        );
        when(
          () => mockRepository.getParticipantById('test-id'),
        ).thenAnswer((_) async => Right(noShowParticipant));

        final result = await useCase(
          participantId: 'test-id',
          newStatus: ParticipantStatus.withdrawn,
        );

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<InputValidationFailure>());
        }, (_) => fail('Expected Left'));
        verifyNever(() => mockRepository.updateParticipant(any()));
      });
    });

    group('field management by status', () {
      test('sets checkInAtTimestamp to now when checking in', () async {
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
          newStatus: ParticipantStatus.checkedIn,
        );
        final afterUpdate = DateTime.now();

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (participant) {
          expect(participant.checkInAtTimestamp, isNotNull);
          expect(
            participant.checkInAtTimestamp!.isAfter(
              beforeUpdate.subtract(const Duration(seconds: 1)),
            ),
            isTrue,
          );
          expect(
            participant.checkInAtTimestamp!.isBefore(
              afterUpdate.add(const Duration(seconds: 1)),
            ),
            isTrue,
          );
        });
      });

      test(
        'clears checkInAtTimestamp when setting to pending (from noShow)',
        () async {
          final noShowParticipant = tParticipant.copyWith(
            checkInStatus: ParticipantStatus.noShow,
          );
          when(
            () => mockRepository.getParticipantById('test-id'),
          ).thenAnswer((_) async => Right(noShowParticipant));
          when(() => mockRepository.updateParticipant(any())).thenAnswer((
            invocation,
          ) async {
            final participant =
                invocation.positionalArguments.first as ParticipantEntity;
            return Right(participant);
          });

          final result = await useCase(
            participantId: 'test-id',
            newStatus: ParticipantStatus.pending,
          );

          expect(result.isRight(), isTrue);
          result.fold((_) => fail('Expected Right'), (participant) {
            expect(participant.checkInAtTimestamp, isNull);
          });
        },
      );

      test(
        'clears checkInAtTimestamp when setting to disqualified (from checkedIn)',
        () async {
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
            newStatus: ParticipantStatus.disqualified,
            dqReason: 'Rule violation',
          );

          expect(result.isRight(), isTrue);
          result.fold((_) => fail('Expected Right'), (participant) {
            expect(participant.checkInAtTimestamp, isNull);
          });
        },
      );

      test('keeps checkInAtTimestamp when setting to withdrawn', () async {
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
          newStatus: ParticipantStatus.withdrawn,
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (participant) {
          expect(participant.checkInAtTimestamp, equals(DateTime(2024, 1, 15)));
        });
      });

      test(
        'clears dqReason when transitioning from disqualified to pending',
        () async {
          final dqParticipant = tParticipant.copyWith(
            checkInStatus: ParticipantStatus.disqualified,
            dqReason: 'Previous violation',
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

          final result = await useCase(
            participantId: 'test-id',
            newStatus: ParticipantStatus.pending,
          );

          expect(result.isRight(), isTrue);
          result.fold((_) => fail('Expected Right'), (participant) {
            expect(participant.dqReason, isNull);
          });
        },
      );

      test('clears dqReason when setting to pending (undo DQ)', () async {
        final dqParticipant = tParticipant.copyWith(
          checkInStatus: ParticipantStatus.disqualified,
          dqReason: 'Previous violation',
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

        final result = await useCase(
          participantId: 'test-id',
          newStatus: ParticipantStatus.pending,
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (participant) {
          expect(participant.dqReason, isNull);
        });
      });
    });

    group('sync version and timestamps', () {
      test('increments syncVersion on every update', () async {
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
          newStatus: ParticipantStatus.checkedIn,
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (participant) {
          expect(participant.syncVersion, equals(2));
        });
      });

      test('updates updatedAtTimestamp on every change', () async {
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
          newStatus: ParticipantStatus.noShow,
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
          newStatus: ParticipantStatus.checkedIn,
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
          newStatus: ParticipantStatus.checkedIn,
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
