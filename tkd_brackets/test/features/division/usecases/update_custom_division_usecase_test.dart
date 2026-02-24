import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/division/domain/usecases/update_custom_division_params.dart';
import 'package:tkd_brackets/features/division/domain/usecases/update_custom_division_usecase.dart';

class MockDivisionRepository extends Mock implements DivisionRepository {}

class FakeDivisionEntity extends Fake implements DivisionEntity {}

class FakeUpdateCustomDivisionParams extends Fake
    implements UpdateCustomDivisionParams {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDivisionEntity());
    registerFallbackValue(FakeUpdateCustomDivisionParams());
  });

  late UpdateCustomDivisionUseCase useCase;
  late MockDivisionRepository mockRepository;

  setUp(() {
    mockRepository = MockDivisionRepository();
    useCase = UpdateCustomDivisionUseCase(mockRepository);
  });

  group('UpdateCustomDivisionUseCase - Success', () {
    test('should update custom division successfully', () async {
      final existingDivision = DivisionEntity(
        id: 'division-1',
        tournamentId: 'tournament-123',
        name: 'Original Division',
        category: DivisionCategory.sparring,
        gender: DivisionGender.male,
        bracketFormat: BracketFormat.singleElimination,
        isCustom: true,
        status: DivisionStatus.setup,
        isCombined: false,
        displayOrder: 0,
        syncVersion: 1,
        isDeleted: false,
        isDemoData: false,
        createdAtTimestamp: DateTime.now(),
        updatedAtTimestamp: DateTime.now(),
      );

      const params = UpdateCustomDivisionParams(
        divisionId: 'division-1',
        name: 'Updated Division',
      );

      when(
        () => mockRepository.getDivisionById('division-1'),
      ).thenAnswer((_) async => Right(existingDivision));

      when(() => mockRepository.updateDivision(any())).thenAnswer(
        (_) async => Right(
          existingDivision.copyWith(name: 'Updated Division', syncVersion: 2),
        ),
      );

      final result = await useCase(params);

      expect(result.isRight(), true);
      verify(() => mockRepository.getDivisionById('division-1')).called(1);
    });

    test('should reject update for template division', () async {
      final templateDivision = DivisionEntity(
        id: 'division-1',
        tournamentId: 'tournament-123',
        name: 'Template Division',
        category: DivisionCategory.sparring,
        gender: DivisionGender.male,
        bracketFormat: BracketFormat.singleElimination,
        isCustom: false,
        status: DivisionStatus.setup,
        isCombined: false,
        displayOrder: 0,
        syncVersion: 1,
        isDeleted: false,
        isDemoData: false,
        createdAtTimestamp: DateTime.now(),
        updatedAtTimestamp: DateTime.now(),
      );

      const params = UpdateCustomDivisionParams(
        divisionId: 'division-1',
        name: 'Try to Update',
      );

      when(
        () => mockRepository.getDivisionById('division-1'),
      ).thenAnswer((_) async => Right(templateDivision));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<ValidationFailure>()),
        (r) => fail('Expected Left'),
      );
    });
  });

  group('UpdateCustomDivisionUseCase - Validation Failures', () {
    test('should return ValidationFailure when name is empty', () async {
      final existingDivision = DivisionEntity(
        id: 'division-1',
        tournamentId: 'tournament-123',
        name: 'Original Division',
        category: DivisionCategory.sparring,
        gender: DivisionGender.male,
        bracketFormat: BracketFormat.singleElimination,
        isCustom: true,
        status: DivisionStatus.setup,
        isCombined: false,
        displayOrder: 0,
        syncVersion: 1,
        isDeleted: false,
        isDemoData: false,
        createdAtTimestamp: DateTime.now(),
        updatedAtTimestamp: DateTime.now(),
      );

      const params = UpdateCustomDivisionParams(
        divisionId: 'division-1',
        name: '',
      );

      when(
        () => mockRepository.getDivisionById('division-1'),
      ).thenAnswer((_) async => Right(existingDivision));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<ValidationFailure>()),
        (r) => fail('Expected Left'),
      );
    });

    test('should return ValidationFailure when ageMin > ageMax', () async {
      final existingDivision = DivisionEntity(
        id: 'division-1',
        tournamentId: 'tournament-123',
        name: 'Original Division',
        category: DivisionCategory.sparring,
        gender: DivisionGender.male,
        bracketFormat: BracketFormat.singleElimination,
        isCustom: true,
        status: DivisionStatus.setup,
        isCombined: false,
        displayOrder: 0,
        syncVersion: 1,
        isDeleted: false,
        isDemoData: false,
        createdAtTimestamp: DateTime.now(),
        updatedAtTimestamp: DateTime.now(),
      );

      const params = UpdateCustomDivisionParams(
        divisionId: 'division-1',
        ageMin: 20,
        ageMax: 10,
      );

      when(
        () => mockRepository.getDivisionById('division-1'),
      ).thenAnswer((_) async => Right(existingDivision));

      final result = await useCase(params);

      expect(result.isLeft(), true);
    });

    test(
      'should return ValidationFailure when weightMin > weightMax',
      () async {
        final existingDivision = DivisionEntity(
          id: 'division-1',
          tournamentId: 'tournament-123',
          name: 'Original Division',
          category: DivisionCategory.sparring,
          gender: DivisionGender.male,
          bracketFormat: BracketFormat.singleElimination,
          isCustom: true,
          status: DivisionStatus.setup,
          isCombined: false,
          displayOrder: 0,
          syncVersion: 1,
          isDeleted: false,
          isDemoData: false,
          createdAtTimestamp: DateTime.now(),
          updatedAtTimestamp: DateTime.now(),
        );

        const params = UpdateCustomDivisionParams(
          divisionId: 'division-1',
          weightMinKg: 100,
          weightMaxKg: 50,
        );

        when(
          () => mockRepository.getDivisionById('division-1'),
        ).thenAnswer((_) async => Right(existingDivision));

        final result = await useCase(params);

        expect(result.isLeft(), true);
      },
    );

    test(
      'should return ValidationFailure when judgeCount out of range',
      () async {
        final existingDivision = DivisionEntity(
          id: 'division-1',
          tournamentId: 'tournament-123',
          name: 'Original Division',
          category: DivisionCategory.sparring,
          gender: DivisionGender.male,
          bracketFormat: BracketFormat.singleElimination,
          isCustom: true,
          status: DivisionStatus.setup,
          isCombined: false,
          displayOrder: 0,
          syncVersion: 1,
          isDeleted: false,
          isDemoData: false,
          createdAtTimestamp: DateTime.now(),
          updatedAtTimestamp: DateTime.now(),
        );

        const params = UpdateCustomDivisionParams(
          divisionId: 'division-1',
          judgeCount: 10,
        );

        when(
          () => mockRepository.getDivisionById('division-1'),
        ).thenAnswer((_) async => Right(existingDivision));

        final result = await useCase(params);

        expect(result.isLeft(), true);
      },
    );
  });

  group('UpdateCustomDivisionUseCase - Repository Failures', () {
    test('should return failure when division not found', () async {
      const params = UpdateCustomDivisionParams(
        divisionId: 'non-existent',
        name: 'Updated Division',
      );

      when(
        () => mockRepository.getDivisionById('non-existent'),
      ).thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<NotFoundFailure>()),
        (r) => fail('Expected Left'),
      );
    });
  });
}
