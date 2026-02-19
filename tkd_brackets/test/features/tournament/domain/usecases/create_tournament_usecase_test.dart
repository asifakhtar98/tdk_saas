import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/create_tournament_params.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/create_tournament_usecase.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class FakeTournamentEntity extends Fake implements TournamentEntity {}

class FakeUserEntity extends Fake implements UserEntity {}

void main() {
  late CreateTournamentUseCase useCase;
  late MockTournamentRepository mockRepository;
  late MockUserRepository mockUserRepository;

  setUpAll(() {
    registerFallbackValue(FakeTournamentEntity());
    registerFallbackValue(FakeUserEntity());
  });

  setUp(() {
    mockRepository = MockTournamentRepository();
    mockUserRepository = MockUserRepository();
    useCase = CreateTournamentUseCase(mockRepository, mockUserRepository);
  });

  final testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    organizationId: 'org-456',
    role: UserRole.owner,
    isActive: true,
    createdAt: DateTime(2024),
  );

  group('CreateTournamentUseCase', () {
    group('validation', () {
      test('returns InputValidationFailure for empty name', () async {
        final result = await useCase(
          CreateTournamentParams(
            name: '',
            scheduledDate: DateTime.now().add(const Duration(days: 7)),
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns InputValidationFailure for whitespace-only name', () async {
        final result = await useCase(
          CreateTournamentParams(
            name: '   ',
            scheduledDate: DateTime.now().add(const Duration(days: 7)),
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns InputValidationFailure for past date', () async {
        final result = await useCase(
          CreateTournamentParams(
            name: 'Test Tournament',
            scheduledDate: DateTime.now().subtract(const Duration(days: 1)),
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns InputValidationFailure for name > 100 chars', () async {
        final longName = 'A' * 101;
        final result = await useCase(
          CreateTournamentParams(
            name: longName,
            scheduledDate: DateTime.now().add(const Duration(days: 7)),
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<InputValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test(
        'returns InputValidationFailure for description > 1000 chars',
        () async {
          final longDescription = 'A' * 1001;
          final result = await useCase(
            CreateTournamentParams(
              name: 'Test Tournament',
              scheduledDate: DateTime.now().add(const Duration(days: 7)),
              description: longDescription,
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<InputValidationFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );

      test('passes validation for valid params', () async {
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testUser));

        when(() => mockRepository.createTournament(any(), any())).thenAnswer(
          (_) async => Right(
            TournamentEntity(
              id: 'tournament-123',
              organizationId: 'org-456',
              createdByUserId: 'user-123',
              name: 'Valid Tournament',
              scheduledDate: DateTime(2026, 3, 15),
              federationType: FederationType.wt,
              status: TournamentStatus.draft,
              numberOfRings: 1,
              isTemplate: false,
              settingsJson: const {},
              createdAt: DateTime.now(),
              updatedAtTimestamp: DateTime.now(),
            ),
          ),
        );

        final result = await useCase(
          CreateTournamentParams(
            name: 'Valid Tournament',
            scheduledDate: DateTime.now().add(const Duration(days: 7)),
          ),
        );

        expect(result.isRight(), isTrue);
      });
    });

    group('auth verification', () {
      test(
        'returns AuthenticationFailure when user not authenticated',
        () async {
          when(() => mockUserRepository.getCurrentUser()).thenAnswer(
            (_) async => const Left(
              AuthenticationFailure(userFriendlyMessage: 'Not authenticated'),
            ),
          );

          final result = await useCase(
            CreateTournamentParams(
              name: 'Test Tournament',
              scheduledDate: DateTime.now().add(const Duration(days: 7)),
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
        'returns AuthenticationFailure when user has no organization',
        () async {
          final userNoOrg = testUser.copyWith(organizationId: '');
          when(
            () => mockUserRepository.getCurrentUser(),
          ).thenAnswer((_) async => Right(userNoOrg));

          final result = await useCase(
            CreateTournamentParams(
              name: 'Test Tournament',
              scheduledDate: DateTime.now().add(const Duration(days: 7)),
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<AuthenticationFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );
    });

    group('successful creation', () {
      test('creates tournament with correct defaults', () async {
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testUser));

        when(() => mockRepository.createTournament(any(), any())).thenAnswer(
          (_) async => Right(
            TournamentEntity(
              id: 'tournament-123',
              organizationId: 'org-456',
              createdByUserId: 'user-123',
              name: 'Test Tournament',
              scheduledDate: DateTime(2026, 3, 15),
              federationType: FederationType.wt,
              status: TournamentStatus.draft,
              numberOfRings: 1,
              isTemplate: false,
              settingsJson: const {},
              createdAt: DateTime.now(),
              updatedAtTimestamp: DateTime.now(),
            ),
          ),
        );

        final result = await useCase(
          CreateTournamentParams(
            name: 'Test Tournament',
            scheduledDate: DateTime(2026, 3, 15),
          ),
        );

        expect(result.isRight(), isTrue);
        verify(
          () => mockRepository.createTournament(any(), 'org-456'),
        ).called(1);
      });

      test('trims whitespace from name and description', () async {
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testUser));

        when(() => mockRepository.createTournament(any(), any())).thenAnswer(
          (_) async => Right(
            TournamentEntity(
              id: 'tournament-123',
              organizationId: 'org-456',
              createdByUserId: 'user-123',
              name: 'Test Tournament',
              scheduledDate: DateTime(2026, 3, 15),
              federationType: FederationType.wt,
              status: TournamentStatus.draft,
              numberOfRings: 1,
              isTemplate: false,
              settingsJson: const {},
              createdAt: DateTime.now(),
              updatedAtTimestamp: DateTime.now(),
            ),
          ),
        );

        final result = await useCase(
          CreateTournamentParams(
            name: '  Test Tournament  ',
            scheduledDate: DateTime(2026, 3, 15),
            description: '  Test description  ',
          ),
        );

        expect(result.isRight(), isTrue);

        final captured = verify(
          () => mockRepository.createTournament(captureAny(), any()),
        ).captured;

        final capturedTournament = captured.first as TournamentEntity;
        expect(capturedTournament.name, equals('Test Tournament'));
        expect(capturedTournament.description, equals('Test description'));
      });
    });
  });
}
