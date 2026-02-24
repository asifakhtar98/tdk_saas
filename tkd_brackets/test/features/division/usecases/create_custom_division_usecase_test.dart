import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/division/domain/usecases/create_custom_division_params.dart';
import 'package:tkd_brackets/features/division/domain/usecases/create_custom_division_usecase.dart';

class MockDivisionRepository extends Mock implements DivisionRepository {}

class FakeDivisionEntity extends Fake implements DivisionEntity {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDivisionEntity());
  });

  late CreateCustomDivisionUseCase useCase;
  late MockDivisionRepository mockRepository;

  setUp(() {
    mockRepository = MockDivisionRepository();
    useCase = CreateCustomDivisionUseCase(mockRepository);

    when(
      () => mockRepository.getDivisionsForTournament(any()),
    ).thenAnswer((_) async => const Right([]));
  });

  group('CreateCustomDivisionUseCase - Success', () {
    test(
      'should create division with isCustom=true when all fields provided',
      () async {
        const params = CreateCustomDivisionParams(
          tournamentId: 'tournament-123',
          name: 'Custom Sparring Division',
          category: DivisionCategory.sparring,
          gender: DivisionGender.male,
          ageMin: 12,
          ageMax: 14,
          weightMinKg: 40,
          weightMaxKg: 50,
          bracketFormat: BracketFormat.singleElimination,
        );

        final expectedDivision = DivisionEntity(
          id: '1',
          tournamentId: 'tournament-123',
          name: 'Custom Sparring Division',
          category: DivisionCategory.sparring,
          gender: DivisionGender.male,
          ageMin: 12,
          ageMax: 14,
          weightMinKg: 40,
          weightMaxKg: 50,
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

        when(
          () => mockRepository.createDivision(any()),
        ).thenAnswer((_) async => Right(expectedDivision));

        final result = await useCase(params);

        expect(result.isRight(), true);
        result.fold((l) => fail('Expected Right'), (r) {
          expect(r.isCustom, true);
        });
        verify(() => mockRepository.createDivision(any())).called(1);
      },
    );

    test(
      'should create division with minimal fields (only name and category)',
      () async {
        const params = CreateCustomDivisionParams(
          tournamentId: 'tournament-123',
          name: 'Minimal Division',
          category: DivisionCategory.demoTeam,
        );

        when(() => mockRepository.createDivision(any())).thenAnswer(
          (_) async => Right(
            DivisionEntity(
              id: '1',
              tournamentId: 'tournament-123',
              name: 'Minimal Division',
              category: DivisionCategory.demoTeam,
              gender: DivisionGender.mixed,
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
            ),
          ),
        );

        final result = await useCase(params);

        expect(result.isRight(), true);
      },
    );

    test('should create division with only criteria (no category)', () async {
      const params = CreateCustomDivisionParams(
        tournamentId: 'tournament-123',
        name: 'Criteria Only Division',
        beltRankMin: 'white',
        beltRankMax: 'blue',
      );

      when(() => mockRepository.createDivision(any())).thenAnswer(
        (_) async => Right(
          DivisionEntity(
            id: '1',
            tournamentId: 'tournament-123',
            name: 'Criteria Only Division',
            beltRankMin: 'white',
            beltRankMax: 'blue',
            category: DivisionCategory.sparring,
            gender: DivisionGender.mixed,
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
          ),
        ),
      );

      final result = await useCase(params);

      expect(result.isRight(), true);
    });
  });

  group('CreateCustomDivisionUseCase - Validation Failures', () {
    test('should return ValidationFailure when name is empty', () async {
      const params = CreateCustomDivisionParams(
        tournamentId: 'tournament-123',
        name: '',
      );

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold((l) {
        expect(l, isA<ValidationFailure>());
        expect((l as ValidationFailure).fieldErrors?.containsKey('name'), true);
      }, (r) => fail('Expected Left'));
    });

    test(
      'should return ValidationFailure when name exceeds 100 characters',
      () async {
        final params = CreateCustomDivisionParams(
          tournamentId: 'tournament-123',
          name: 'A' * 101,
        );

        final result = await useCase(params);

        expect(result.isLeft(), true);
      },
    );

    test(
      'should return ValidationFailure when no criteria and no category',
      () async {
        const params = CreateCustomDivisionParams(
          tournamentId: 'tournament-123',
          name: 'Empty Division',
        );

        final result = await useCase(params);

        expect(result.isLeft(), true);
        result.fold((l) {
          expect(l, isA<ValidationFailure>());
        }, (r) => fail('Expected Left'));
      },
    );

    test('should return ValidationFailure when ageMin > ageMax', () async {
      const params = CreateCustomDivisionParams(
        tournamentId: 'tournament-123',
        name: 'Invalid Age',
        ageMin: 20,
        ageMax: 10,
      );

      final result = await useCase(params);

      expect(result.isLeft(), true);
    });

    test(
      'should return ValidationFailure when weightMin > weightMax',
      () async {
        const params = CreateCustomDivisionParams(
          tournamentId: 'tournament-123',
          name: 'Invalid Weight',
          weightMinKg: 100,
          weightMaxKg: 50,
        );

        final result = await useCase(params);

        expect(result.isLeft(), true);
      },
    );

    test(
      'should return ValidationFailure when judgeCount out of range',
      () async {
        const params = CreateCustomDivisionParams(
          tournamentId: 'tournament-123',
          name: 'Invalid Judges',
          category: DivisionCategory.sparring,
          judgeCount: 10,
        );

        final result = await useCase(params);

        expect(result.isLeft(), true);
      },
    );

    test(
      'should return ValidationFailure when duplicate name exists',
      () async {
        final existingDivision = DivisionEntity(
          id: 'existing-1',
          tournamentId: 'tournament-123',
          name: 'Existing Division',
          category: DivisionCategory.sparring,
          gender: DivisionGender.mixed,
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

        when(
          () => mockRepository.getDivisionsForTournament('tournament-123'),
        ).thenAnswer((_) async => Right([existingDivision]));

        const params = CreateCustomDivisionParams(
          tournamentId: 'tournament-123',
          name: 'Existing Division',
          category: DivisionCategory.sparring,
        );

        final result = await useCase(params);

        expect(result.isLeft(), true);
        result.fold((l) {
          expect(l, isA<ValidationFailure>());
        }, (r) => fail('Expected Left'));
      },
    );
  });

  group('CreateCustomDivisionUseCase - Repository Failures', () {
    test('should return failure when local DB fails', () async {
      const params = CreateCustomDivisionParams(
        tournamentId: 'tournament-123',
        name: 'Test Division',
        category: DivisionCategory.sparring,
      );

      when(() => mockRepository.createDivision(any())).thenAnswer(
        (_) async => const Left(
          LocalCacheWriteFailure(
            userFriendlyMessage: 'Unable to save division locally',
          ),
        ),
      );

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<LocalCacheWriteFailure>()),
        (r) => fail('Expected Left'),
      );
    });
  });
}
