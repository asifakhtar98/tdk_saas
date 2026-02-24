import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/update_tournament_settings_params.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/update_tournament_settings_usecase.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class FakeTournamentEntity extends Fake implements TournamentEntity {}

class FakeUserEntity extends Fake implements UserEntity {}

void main() {
  late UpdateTournamentSettingsUseCase useCase;
  late MockTournamentRepository mockRepository;
  late MockUserRepository mockUserRepository;

  setUpAll(() {
    registerFallbackValue(FakeTournamentEntity());
    registerFallbackValue(FakeUserEntity());
  });

  setUp(() {
    mockRepository = MockTournamentRepository();
    mockUserRepository = MockUserRepository();
    useCase = UpdateTournamentSettingsUseCase(
      mockRepository,
      mockUserRepository,
    );
  });

  final testTournament = TournamentEntity(
    id: 'tournament-123',
    organizationId: 'org-456',
    createdByUserId: 'user-123',
    name: 'Test Tournament',
    scheduledDate: DateTime(2026, 3, 15),
    federationType: FederationType.wt,
    status: TournamentStatus.draft,
    numberOfRings: 2,
    venueName: 'Test Venue',
    venueAddress: '123 Test St',
    settingsJson: const {},
    isTemplate: false,
    createdAt: DateTime(2024),
    updatedAtTimestamp: DateTime(2024),
  );

  final testOwner = UserEntity(
    id: 'user-123',
    email: 'owner@example.com',
    displayName: 'Owner User',
    organizationId: 'org-456',
    role: UserRole.owner,
    isActive: true,
    createdAt: DateTime(2024),
  );

  group('UpdateTournamentSettingsUseCase', () {
    group('validation', () {
      test('returns InputValidationFailure for ringCount < 1', () async {
        final result = await useCase(
          const UpdateTournamentSettingsParams(
            tournamentId: 'tournament-123',
            ringCount: 0,
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns InputValidationFailure for ringCount > 20', () async {
        final result = await useCase(
          const UpdateTournamentSettingsParams(
            tournamentId: 'tournament-123',
            ringCount: 21,
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test(
        'returns InputValidationFailure for venueName > 200 chars',
        () async {
          final longName = 'A' * 201;
          final result = await useCase(
            UpdateTournamentSettingsParams(
              tournamentId: 'tournament-123',
              venueName: longName,
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<InputValidationFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );

      test(
        'returns InputValidationFailure for venueAddress > 500 chars',
        () async {
          final longAddress = 'A' * 501;
          final result = await useCase(
            UpdateTournamentSettingsParams(
              tournamentId: 'tournament-123',
              venueAddress: longAddress,
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<InputValidationFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );
    });

    group('tournament not found', () {
      test('returns NotFoundFailure when tournament does not exist', () async {
        when(() => mockRepository.getTournamentById(any())).thenAnswer(
          (_) async => const Left(
            NotFoundFailure(userFriendlyMessage: 'Tournament not found'),
          ),
        );

        final result = await useCase(
          const UpdateTournamentSettingsParams(
            tournamentId: 'nonexistent',
            venueName: 'New Venue',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test(
        'returns NotFoundFailure when repository returns null tournament',
        () async {
          when(() => mockRepository.getTournamentById(any())).thenAnswer(
            (_) async => const Left(
              LocalCacheAccessFailure(userFriendlyMessage: 'Not found'),
            ),
          );

          final result = await useCase(
            const UpdateTournamentSettingsParams(
              tournamentId: 'nonexistent',
              venueName: 'New Venue',
            ),
          );

          expect(result.isLeft(), isTrue);
        },
      );
    });

    group('authorization', () {
      test(
        'returns AuthenticationFailure when user not authenticated',
        () async {
          when(
            () => mockRepository.getTournamentById(any()),
          ).thenAnswer((_) async => Right(testTournament));
          when(() => mockUserRepository.getCurrentUser()).thenAnswer(
            (_) async => const Left(
              AuthenticationFailure(userFriendlyMessage: 'Not authenticated'),
            ),
          );

          final result = await useCase(
            const UpdateTournamentSettingsParams(
              tournamentId: 'tournament-123',
              venueName: 'New Venue',
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<AuthenticationFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );

      test(
        'returns AuthorizationPermissionDeniedFailure for Viewer role',
        () async {
          final viewerUser = testOwner.copyWith(role: UserRole.viewer);
          when(
            () => mockRepository.getTournamentById(any()),
          ).thenAnswer((_) async => Right(testTournament));
          when(
            () => mockUserRepository.getCurrentUser(),
          ).thenAnswer((_) async => Right(viewerUser));

          final result = await useCase(
            const UpdateTournamentSettingsParams(
              tournamentId: 'tournament-123',
              venueName: 'New Venue',
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) =>
                expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );

      test(
        'returns AuthorizationPermissionDeniedFailure for Scorer role',
        () async {
          final scorerUser = testOwner.copyWith(role: UserRole.scorer);
          when(
            () => mockRepository.getTournamentById(any()),
          ).thenAnswer((_) async => Right(testTournament));
          when(
            () => mockUserRepository.getCurrentUser(),
          ).thenAnswer((_) async => Right(scorerUser));

          final result = await useCase(
            const UpdateTournamentSettingsParams(
              tournamentId: 'tournament-123',
              venueName: 'New Venue',
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) =>
                expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );

      test('allows Admin role to modify settings', () async {
        final adminUser = testOwner.copyWith(role: UserRole.admin);
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(adminUser));
        when(() => mockRepository.updateTournament(any())).thenAnswer(
          (_) async => Right(testTournament.copyWith(venueName: 'New Venue')),
        );

        final result = await useCase(
          const UpdateTournamentSettingsParams(
            tournamentId: 'tournament-123',
            venueName: 'New Venue',
          ),
        );

        expect(result.isRight(), isTrue);
      });
    });

    group('successful update', () {
      test('updates tournament with new settings', () async {
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(() => mockRepository.updateTournament(any())).thenAnswer(
          (_) async => Right(
            testTournament.copyWith(
              venueName: 'New Venue',
              federationType: FederationType.itf,
            ),
          ),
        );

        final result = await useCase(
          const UpdateTournamentSettingsParams(
            tournamentId: 'tournament-123',
            venueName: 'New Venue',
            federationType: FederationType.itf,
          ),
        );

        expect(result.isRight(), isTrue);
        verify(() => mockRepository.updateTournament(any())).called(1);
      });

      test('empty string removes venueName value', () async {
        final tournamentWithVenue = testTournament.copyWith(
          venueName: 'Old Venue',
        );
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(tournamentWithVenue));
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(() => mockRepository.updateTournament(any())).thenAnswer(
          (_) async => Right(tournamentWithVenue.copyWith(venueName: null)),
        );

        final result = await useCase(
          const UpdateTournamentSettingsParams(
            tournamentId: 'tournament-123',
            venueName: '',
          ),
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (tournament) => expect(tournament.venueName, isNull),
        );
      });

      test('empty string removes venueAddress value', () async {
        final tournamentWithAddress = testTournament.copyWith(
          venueAddress: '123 Old St',
        );
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(tournamentWithAddress));
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(() => mockRepository.updateTournament(any())).thenAnswer(
          (_) async =>
              Right(tournamentWithAddress.copyWith(venueAddress: null)),
        );

        final result = await useCase(
          const UpdateTournamentSettingsParams(
            tournamentId: 'tournament-123',
            venueAddress: '',
          ),
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (tournament) => expect(tournament.venueAddress, isNull),
        );
      });

      test('updates ring count correctly', () async {
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(() => mockRepository.updateTournament(any())).thenAnswer(
          (_) async => Right(testTournament.copyWith(numberOfRings: 5)),
        );

        final result = await useCase(
          const UpdateTournamentSettingsParams(
            tournamentId: 'tournament-123',
            ringCount: 5,
          ),
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (tournament) => expect(tournament.numberOfRings, equals(5)),
        );
      });

      test('updates scheduled times correctly', () async {
        final startTime = DateTime(2026, 4, 1, 9, 0);
        final endTime = DateTime(2026, 4, 1, 18, 0);
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(() => mockRepository.updateTournament(any())).thenAnswer(
          (_) async => Right(
            testTournament.copyWith(
              scheduledStartTime: startTime,
              scheduledEndTime: endTime,
            ),
          ),
        );

        final result = await useCase(
          UpdateTournamentSettingsParams(
            tournamentId: 'tournament-123',
            scheduledStartTime: startTime,
            scheduledEndTime: endTime,
          ),
        );

        expect(result.isRight(), isTrue);
      });

      test('leaves unchanged fields as-is when not provided', () async {
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(
          () => mockRepository.updateTournament(any()),
        ).thenAnswer((_) async => Right(testTournament));

        final result = await useCase(
          const UpdateTournamentSettingsParams(
            tournamentId: 'tournament-123',
            venueName: 'New Venue',
          ),
        );

        expect(result.isRight(), isTrue);

        final captured = verify(
          () => mockRepository.updateTournament(captureAny()),
        ).captured;
        final capturedTournament = captured.first as TournamentEntity;
        expect(capturedTournament.federationType, equals(FederationType.wt));
        expect(capturedTournament.numberOfRings, equals(2));
      });
    });

    group('error propagation', () {
      test('propagates repository errors on update', () async {
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(() => mockRepository.updateTournament(any())).thenAnswer(
          (_) async => const Left(
            LocalCacheWriteFailure(userFriendlyMessage: 'Failed to save'),
          ),
        );

        final result = await useCase(
          const UpdateTournamentSettingsParams(
            tournamentId: 'tournament-123',
            venueName: 'New Venue',
          ),
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
