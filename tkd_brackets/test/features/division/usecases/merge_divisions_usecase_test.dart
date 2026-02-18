import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/features/division/domain/usecases/merge_divisions_usecase.dart';
import 'package:tkd_brackets/features/division/domain/usecases/merge_divisions_params.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:uuid/uuid.dart';

class MockDivisionRepository extends Mock implements DivisionRepository {}

class MockUuid extends Mock implements Uuid {}

class FakeDivisionEntity extends Fake implements DivisionEntity {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDivisionEntity());
  });

  late MergeDivisionsUseCase useCase;
  late MockDivisionRepository mockRepository;
  late MockUuid mockUuid;

  setUp(() {
    mockRepository = MockDivisionRepository();
    mockUuid = MockUuid();
    useCase = MergeDivisionsUseCase(mockRepository, mockUuid);
  });

  DivisionEntity _createTestDivision({
    required String id,
    required String tournamentId,
    String name = 'Test Division',
    double? weightMin,
    double? weightMax,
    DivisionCategory category = DivisionCategory.sparring,
    bool isCombined = false,
    bool isDeleted = false,
    DivisionGender gender = DivisionGender.male,
    int displayOrder = 0,
  }) {
    return DivisionEntity(
      id: id,
      tournamentId: tournamentId,
      name: name,
      category: category,
      gender: gender,
      weightMinKg: weightMin,
      weightMaxKg: weightMax,
      bracketFormat: BracketFormat.singleElimination,
      isCustom: true,
      status: DivisionStatus.setup,
      isCombined: isCombined,
      displayOrder: displayOrder,
      syncVersion: 1,
      isDeleted: isDeleted,
      isDemoData: false,
      createdAtTimestamp: DateTime.now(),
      updatedAtTimestamp: DateTime.now(),
    );
  }

  group('MergeDivisionsUseCase - Success', () {
    test('should merge two divisions with broadened criteria', () async {
      when(() => mockUuid.v4()).thenReturn('new-uuid-123');

      final params = MergeDivisionsParams(
        divisionIdA: 'div-a',
        divisionIdB: 'div-b',
      );

      final divisionA = _createTestDivision(
        id: 'div-a',
        tournamentId: 'tournament-1',
        weightMin: 40.0,
        weightMax: 45.0,
      );
      final divisionB = _createTestDivision(
        id: 'div-b',
        tournamentId: 'tournament-1',
        weightMin: 45.0,
        weightMax: 50.0,
      );

      when(
        () => mockRepository.getDivision('div-a'),
      ).thenAnswer((_) async => Right(divisionA));
      when(
        () => mockRepository.getDivision('div-b'),
      ).thenAnswer((_) async => Right(divisionB));
      when(
        () => mockRepository.isDivisionNameUnique(
          any(),
          any(),
          excludeDivisionId: any(named: 'excludeDivisionId'),
        ),
      ).thenAnswer((_) async => const Right(true));
      when(
        () => mockRepository.getParticipantsForDivisions(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockRepository.mergeDivisions(
          mergedDivision: any(named: 'mergedDivision'),
          sourceDivisions: any(named: 'sourceDivisions'),
          participants: any(named: 'participants'),
        ),
      ).thenAnswer((_) async => const Right([]));

      final result = await useCase(params);

      expect(result.isRight(), true);
      verify(
        () => mockRepository.mergeDivisions(
          mergedDivision: any(named: 'mergedDivision'),
          sourceDivisions: any(named: 'sourceDivisions'),
          participants: any(named: 'participants'),
        ),
      ).called(1);
    });

    test('should use custom name when provided', () async {
      when(() => mockUuid.v4()).thenReturn('new-uuid-123');

      final params = MergeDivisionsParams(
        divisionIdA: 'div-a',
        divisionIdB: 'div-b',
        name: 'Custom Merged Name',
      );

      final divisionA = _createTestDivision(
        id: 'div-a',
        tournamentId: 'tournament-1',
      );
      final divisionB = _createTestDivision(
        id: 'div-b',
        tournamentId: 'tournament-1',
      );

      when(
        () => mockRepository.getDivision('div-a'),
      ).thenAnswer((_) async => Right(divisionA));
      when(
        () => mockRepository.getDivision('div-b'),
      ).thenAnswer((_) async => Right(divisionB));
      when(
        () => mockRepository.isDivisionNameUnique(
          'Custom Merged Name',
          'tournament-1',
          excludeDivisionId: any(named: 'excludeDivisionId'),
        ),
      ).thenAnswer((_) async => const Right(true));
      when(
        () => mockRepository.getParticipantsForDivisions(any()),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockRepository.mergeDivisions(
          mergedDivision: any(named: 'mergedDivision'),
          sourceDivisions: any(named: 'sourceDivisions'),
          participants: any(named: 'participants'),
        ),
      ).thenAnswer((_) async => const Right([]));

      final result = await useCase(params);

      expect(result.isRight(), true);
      verify(
        () => mockRepository.isDivisionNameUnique(
          'Custom Merged Name',
          'tournament-1',
          excludeDivisionId: any(named: 'excludeDivisionId'),
        ),
      ).called(1);
    });
  });

  group('MergeDivisionsUseCase - Validation Failures', () {
    test(
      'should return ValidationFailure when merging same division',
      () async {
        final params = MergeDivisionsParams(
          divisionIdA: 'div-a',
          divisionIdB: 'div-a',
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
      'should return ValidationFailure when divisions in different tournaments',
      () async {
        final params = MergeDivisionsParams(
          divisionIdA: 'div-a',
          divisionIdB: 'div-b',
        );

        final divisionA = _createTestDivision(
          id: 'div-a',
          tournamentId: 'tournament-1',
        );
        final divisionB = _createTestDivision(
          id: 'div-b',
          tournamentId: 'tournament-2',
        );

        when(
          () => mockRepository.getDivision('div-a'),
        ).thenAnswer((_) async => Right(divisionA));
        when(
          () => mockRepository.getDivision('div-b'),
        ).thenAnswer((_) async => Right(divisionB));

        final result = await useCase(params);

        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(
            (l as ValidationFailure).fieldErrors?.containsKey('tournament'),
            true,
          ),
          (r) => fail('Expected Left'),
        );
      },
    );

    test('should return ValidationFailure for category mismatch', () async {
      final params = MergeDivisionsParams(
        divisionIdA: 'div-a',
        divisionIdB: 'div-b',
      );

      final divisionA = _createTestDivision(
        id: 'div-a',
        tournamentId: 't1',
        category: DivisionCategory.sparring,
      );
      final divisionB = _createTestDivision(
        id: 'div-b',
        tournamentId: 't1',
        category: DivisionCategory.poomsae,
      );

      when(
        () => mockRepository.getDivision('div-a'),
      ).thenAnswer((_) async => Right(divisionA));
      when(
        () => mockRepository.getDivision('div-b'),
      ).thenAnswer((_) async => Right(divisionB));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(
          (l as ValidationFailure).fieldErrors?.containsKey('category'),
          true,
        ),
        (r) => fail('Expected Left'),
      );
    });

    test(
      'should return ValidationFailure for already combined divisions',
      () async {
        final params = MergeDivisionsParams(
          divisionIdA: 'div-a',
          divisionIdB: 'div-b',
        );

        final divisionA = _createTestDivision(
          id: 'div-a',
          tournamentId: 't1',
          isCombined: true,
        );
        final divisionB = _createTestDivision(id: 'div-b', tournamentId: 't1');

        when(
          () => mockRepository.getDivision('div-a'),
        ).thenAnswer((_) async => Right(divisionA));
        when(
          () => mockRepository.getDivision('div-b'),
        ).thenAnswer((_) async => Right(divisionB));

        final result = await useCase(params);

        expect(result.isLeft(), true);
      },
    );

    test('should return ValidationFailure for deleted divisions', () async {
      final params = MergeDivisionsParams(
        divisionIdA: 'div-a',
        divisionIdB: 'div-b',
      );

      final divisionA = _createTestDivision(
        id: 'div-a',
        tournamentId: 't1',
        isDeleted: true,
      );
      final divisionB = _createTestDivision(id: 'div-b', tournamentId: 't1');

      when(
        () => mockRepository.getDivision('div-a'),
      ).thenAnswer((_) async => Right(divisionA));
      when(
        () => mockRepository.getDivision('div-b'),
      ).thenAnswer((_) async => Right(divisionB));

      final result = await useCase(params);

      expect(result.isLeft(), true);
    });

    test('should return ValidationFailure for duplicate name', () async {
      final params = MergeDivisionsParams(
        divisionIdA: 'div-a',
        divisionIdB: 'div-b',
        name: 'Existing Name',
      );

      final divisionA = _createTestDivision(id: 'div-a', tournamentId: 't1');
      final divisionB = _createTestDivision(id: 'div-b', tournamentId: 't1');

      when(
        () => mockRepository.getDivision('div-a'),
      ).thenAnswer((_) async => Right(divisionA));
      when(
        () => mockRepository.getDivision('div-b'),
      ).thenAnswer((_) async => Right(divisionB));
      when(
        () => mockRepository.isDivisionNameUnique(
          'Existing Name',
          't1',
          excludeDivisionId: any(named: 'excludeDivisionId'),
        ),
      ).thenAnswer((_) async => const Right(false));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(
          (l as ValidationFailure).fieldErrors?.containsKey('name'),
          true,
        ),
        (r) => fail('Expected Left'),
      );
    });
  });
}
