import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/features/division/domain/usecases/assign_to_ring_usecase.dart';
import 'package:tkd_brackets/features/division/domain/usecases/assign_to_ring_params.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/core/error/failures.dart';

class MockDivisionRepository extends Mock implements DivisionRepository {}

class MockTournamentRepository extends Mock implements TournamentRepository {}

class FakeDivisionEntity extends Fake implements DivisionEntity {}

class FakeTournamentEntity extends Fake implements TournamentEntity {}

void main() {
  late AssignToRingUseCase useCase;
  late MockDivisionRepository mockDivisionRepository;
  late MockTournamentRepository mockTournamentRepository;

  setUpAll(() {
    registerFallbackValue(FakeDivisionEntity());
    registerFallbackValue(FakeTournamentEntity());
  });

  setUp(() {
    mockDivisionRepository = MockDivisionRepository();
    mockTournamentRepository = MockTournamentRepository();
    useCase = AssignToRingUseCase(
      mockDivisionRepository,
      mockTournamentRepository,
    );
  });

  DivisionEntity _createTestDivision({
    required String id,
    required String tournamentId,
    int? assignedRingNumber,
    int displayOrder = 0,
    int syncVersion = 1,
    bool isDeleted = false,
  }) {
    return DivisionEntity(
      id: id,
      tournamentId: tournamentId,
      name: 'Test Division',
      category: DivisionCategory.sparring,
      gender: DivisionGender.male,
      bracketFormat: BracketFormat.singleElimination,
      isCustom: true,
      status: DivisionStatus.setup,
      assignedRingNumber: assignedRingNumber,
      displayOrder: displayOrder,
      syncVersion: syncVersion,
      isDeleted: isDeleted,
      isDemoData: false,
      createdAtTimestamp: DateTime(2026, 1, 1),
      updatedAtTimestamp: DateTime(2026, 1, 1),
    );
  }

  TournamentEntity _createTestTournament({
    required String id,
    int numberOfRings = 4,
  }) {
    return TournamentEntity(
      id: id,
      organizationId: 'org-uuid-001',
      createdByUserId: 'user-uuid-001',
      name: 'Test Tournament',
      scheduledDate: DateTime(2026, 3, 1),
      federationType: FederationType.wt,
      status: TournamentStatus.draft,
      numberOfRings: numberOfRings,
      settingsJson: const {},
      isTemplate: false,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  group('AssignToRingUseCase - Success Cases', () {
    test(
      'should assign division to ring with auto-generated display order',
      () async {
        final params = AssignToRingParams(
          divisionId: 'div-uuid-001',
          ringNumber: 1,
        );

        final division = _createTestDivision(
          id: 'div-uuid-001',
          tournamentId: 'tournament-uuid-001',
        );
        final tournament = _createTestTournament(
          id: 'tournament-uuid-001',
          numberOfRings: 4,
        );

        when(
          () => mockDivisionRepository.getDivision('div-uuid-001'),
        ).thenAnswer((_) async => Right(division));
        when(
          () =>
              mockTournamentRepository.getTournamentById('tournament-uuid-001'),
        ).thenAnswer((_) async => Right(tournament));
        when(
          () => mockDivisionRepository.getDivisionsForTournament(
            'tournament-uuid-001',
          ),
        ).thenAnswer((_) async => const Right([]));
        when(() => mockDivisionRepository.updateDivision(any())).thenAnswer((
          invocation,
        ) async {
          final div = invocation.positionalArguments[0] as DivisionEntity;
          return Right(div);
        });

        final result = await useCase(params);

        expect(result.isRight(), true);
        verify(() => mockDivisionRepository.updateDivision(any())).called(1);

        final updatedDiv = result.getOrElse(
          (l) => throw Exception('Test failed'),
        );
        expect(updatedDiv.assignedRingNumber, 1);
        expect(updatedDiv.displayOrder, 1);
      },
    );

    test('should use provided display order when specified', () async {
      final params = AssignToRingParams(
        divisionId: 'div-uuid-001',
        ringNumber: 1,
        displayOrder: 5,
      );

      final division = _createTestDivision(
        id: 'div-uuid-001',
        tournamentId: 'tournament-uuid-001',
      );
      final tournament = _createTestTournament(
        id: 'tournament-uuid-001',
        numberOfRings: 4,
      );

      when(
        () => mockDivisionRepository.getDivision('div-uuid-001'),
      ).thenAnswer((_) async => Right(division));
      when(
        () => mockTournamentRepository.getTournamentById('tournament-uuid-001'),
      ).thenAnswer((_) async => Right(tournament));
      when(
        () => mockDivisionRepository.getDivisionsForTournament(
          'tournament-uuid-001',
        ),
      ).thenAnswer((_) async => const Right([]));
      when(() => mockDivisionRepository.updateDivision(any())).thenAnswer((
        invocation,
      ) async {
        final div = invocation.positionalArguments[0] as DivisionEntity;
        return Right(div);
      });

      final result = await useCase(params);

      expect(result.isRight(), true);
      final updatedDiv = result.getOrElse(
        (l) => throw Exception('Test failed'),
      );
      expect(updatedDiv.displayOrder, 5);
    });

    test(
      'should auto-increment display order when other divisions exist in ring',
      () async {
        final params = AssignToRingParams(
          divisionId: 'div-uuid-002',
          ringNumber: 1,
        );

        final division = _createTestDivision(
          id: 'div-uuid-002',
          tournamentId: 'tournament-uuid-001',
        );
        final tournament = _createTestTournament(
          id: 'tournament-uuid-001',
          numberOfRings: 4,
        );

        final existingDivision = _createTestDivision(
          id: 'div-uuid-001',
          tournamentId: 'tournament-uuid-001',
          assignedRingNumber: 1,
          displayOrder: 3,
        );

        when(
          () => mockDivisionRepository.getDivision('div-uuid-002'),
        ).thenAnswer((_) async => Right(division));
        when(
          () =>
              mockTournamentRepository.getTournamentById('tournament-uuid-001'),
        ).thenAnswer((_) async => Right(tournament));
        when(
          () => mockDivisionRepository.getDivisionsForTournament(
            'tournament-uuid-001',
          ),
        ).thenAnswer((_) async => Right([existingDivision]));
        when(() => mockDivisionRepository.updateDivision(any())).thenAnswer((
          invocation,
        ) async {
          final div = invocation.positionalArguments[0] as DivisionEntity;
          return Right(div);
        });

        final result = await useCase(params);

        expect(result.isRight(), true);
        final updatedDiv = result.getOrElse(
          (l) => throw Exception('Test failed'),
        );
        expect(updatedDiv.displayOrder, 4);
      },
    );

    test('should increment syncVersion on update', () async {
      final params = AssignToRingParams(
        divisionId: 'div-uuid-001',
        ringNumber: 1,
      );

      final division = _createTestDivision(
        id: 'div-uuid-001',
        tournamentId: 'tournament-uuid-001',
        syncVersion: 5,
      );
      final tournament = _createTestTournament(
        id: 'tournament-uuid-001',
        numberOfRings: 4,
      );

      when(
        () => mockDivisionRepository.getDivision('div-uuid-001'),
      ).thenAnswer((_) async => Right(division));
      when(
        () => mockTournamentRepository.getTournamentById('tournament-uuid-001'),
      ).thenAnswer((_) async => Right(tournament));
      when(
        () => mockDivisionRepository.getDivisionsForTournament(
          'tournament-uuid-001',
        ),
      ).thenAnswer((_) async => const Right([]));
      when(() => mockDivisionRepository.updateDivision(any())).thenAnswer((
        invocation,
      ) async {
        final div = invocation.positionalArguments[0] as DivisionEntity;
        return Right(div);
      });

      final result = await useCase(params);

      final updatedDiv = result.getOrElse(
        (l) => throw Exception('Test failed'),
      );
      expect(updatedDiv.syncVersion, 6);
    });

    test(
      'should handle tournament with zero ring count (unlimited rings)',
      () async {
        final params = AssignToRingParams(
          divisionId: 'div-uuid-001',
          ringNumber: 100,
        );

        final division = _createTestDivision(
          id: 'div-uuid-001',
          tournamentId: 'tournament-uuid-001',
        );
        final tournament = _createTestTournament(
          id: 'tournament-uuid-001',
          numberOfRings: 0,
        );

        when(
          () => mockDivisionRepository.getDivision('div-uuid-001'),
        ).thenAnswer((_) async => Right(division));
        when(
          () =>
              mockTournamentRepository.getTournamentById('tournament-uuid-001'),
        ).thenAnswer((_) async => Right(tournament));
        when(
          () => mockDivisionRepository.getDivisionsForTournament(
            'tournament-uuid-001',
          ),
        ).thenAnswer((_) async => const Right([]));
        when(() => mockDivisionRepository.updateDivision(any())).thenAnswer((
          invocation,
        ) async {
          final div = invocation.positionalArguments[0] as DivisionEntity;
          return Right(div);
        });

        final result = await useCase(params);

        expect(result.isRight(), true);
      },
    );
  });

  group('AssignToRingUseCase - Validation Failures', () {
    test('should return ValidationFailure when ring number is zero', () async {
      final params = AssignToRingParams(
        divisionId: 'div-uuid-001',
        ringNumber: 0,
      );

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold((l) {
        expect(l, isA<ValidationFailure>());
        expect(
          (l as ValidationFailure).fieldErrors?.containsKey('ringNumber'),
          true,
        );
      }, (r) => fail('Expected Left'));
    });

    test(
      'should return ValidationFailure when ring number is negative',
      () async {
        final params = AssignToRingParams(
          divisionId: 'div-uuid-001',
          ringNumber: -1,
        );

        final result = await useCase(params);

        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ValidationFailure>()),
          (r) => fail('Expected Left'),
        );
      },
    );

    test(
      'should return ValidationFailure when ring number exceeds tournament rings',
      () async {
        final params = AssignToRingParams(
          divisionId: 'div-uuid-001',
          ringNumber: 10,
        );

        final division = _createTestDivision(
          id: 'div-uuid-001',
          tournamentId: 'tournament-uuid-001',
        );
        final tournament = _createTestTournament(
          id: 'tournament-uuid-001',
          numberOfRings: 4,
        );

        when(
          () => mockDivisionRepository.getDivision('div-uuid-001'),
        ).thenAnswer((_) async => Right(division));
        when(
          () =>
              mockTournamentRepository.getTournamentById('tournament-uuid-001'),
        ).thenAnswer((_) async => Right(tournament));

        final result = await useCase(params);

        expect(result.isLeft(), true);
        result.fold((l) {
          expect(l, isA<ValidationFailure>());
          expect(
            (l as ValidationFailure).fieldErrors?.containsKey('ringNumber'),
            true,
          );
          expect(l.userFriendlyMessage.contains('1 and 4'), true);
        }, (r) => fail('Expected Left'));
      },
    );

    test('should return ValidationFailure when division not found', () async {
      final params = AssignToRingParams(
        divisionId: 'non-existent-id',
        ringNumber: 1,
      );

      when(
        () => mockDivisionRepository.getDivision('non-existent-id'),
      ).thenAnswer(
        (_) async => const Left(
          LocalCacheAccessFailure(userFriendlyMessage: 'Division not found.'),
        ),
      );

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<ValidationFailure>()),
        (r) => fail('Expected Left'),
      );
    });

    test('should return ValidationFailure when division ID is empty', () async {
      final params = AssignToRingParams(divisionId: '', ringNumber: 1);

      final result = await useCase(params);

      expect(result.isLeft(), true);
    });
  });

  group('AssignToRingUseCase - Edge Cases', () {
    test(
      'should handle deleted divisions in display order calculation',
      () async {
        final params = AssignToRingParams(
          divisionId: 'div-uuid-002',
          ringNumber: 1,
        );

        final division = _createTestDivision(
          id: 'div-uuid-002',
          tournamentId: 'tournament-uuid-001',
        );
        final tournament = _createTestTournament(
          id: 'tournament-uuid-001',
          numberOfRings: 4,
        );

        final deletedDivision = _createTestDivision(
          id: 'div-uuid-old',
          tournamentId: 'tournament-uuid-001',
          assignedRingNumber: 1,
          displayOrder: 10,
          isDeleted: true,
        );

        when(
          () => mockDivisionRepository.getDivision('div-uuid-002'),
        ).thenAnswer((_) async => Right(division));
        when(
          () =>
              mockTournamentRepository.getTournamentById('tournament-uuid-001'),
        ).thenAnswer((_) async => Right(tournament));
        when(
          () => mockDivisionRepository.getDivisionsForTournament(
            'tournament-uuid-001',
          ),
        ).thenAnswer((_) async => Right([deletedDivision]));
        when(() => mockDivisionRepository.updateDivision(any())).thenAnswer((
          invocation,
        ) async {
          final div = invocation.positionalArguments[0] as DivisionEntity;
          return Right(div);
        });

        final result = await useCase(params);

        expect(result.isRight(), true);
        final updatedDiv = result.getOrElse(
          (l) => throw Exception('Test failed'),
        );
        expect(updatedDiv.displayOrder, 1);
      },
    );
  });
}
