import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/division/domain/usecases/smart_division_builder_params.dart';
import 'package:tkd_brackets/features/division/domain/usecases/smart_division_builder_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';

class MockDivisionRepository extends Mock implements DivisionRepository {}

class MockAppDatabase extends Mock implements AppDatabase {}

class FakeDivisionEntity extends Fake implements DivisionEntity {}

void main() {
  late SmartDivisionBuilderUseCase useCase;
  late MockDivisionRepository mockRepository;
  late MockAppDatabase mockDatabase;

  setUpAll(() {
    registerFallbackValue(FakeDivisionEntity());
  });

  setUp(() {
    mockRepository = MockDivisionRepository();
    mockDatabase = MockAppDatabase();
    useCase = SmartDivisionBuilderUseCase(mockRepository, mockDatabase);
  });

  final defaultParams = SmartDivisionBuilderParams(
    tournamentId: 'tournament-123',
    federationType: FederationType.wt,
    categoryConfig: const DivisionCategoryConfig(
      category: DivisionCategoryType.sparring,
      applyWeightClasses: true,
    ),
    ageGroups: const [
      AgeGroupConfig(name: '6-8', minAge: 6, maxAge: 8),
      AgeGroupConfig(name: '9-10', minAge: 9, maxAge: 10),
    ],
    beltGroups: const [
      BeltGroupConfig(name: 'white-yellow', minOrder: 1, maxOrder: 2),
      BeltGroupConfig(name: 'green-blue', minOrder: 4, maxOrder: 5),
    ],
    weightClasses: WeightClassConfig.wt,
    includeEmptyDivisions: true,
    minimumParticipants: 1,
  );

  group('SmartDivisionBuilderUseCase', () {
    test('generates divisions successfully', () async {
      when(() => mockRepository.createDivision(any())).thenAnswer((
        invocation,
      ) async {
        final entity = invocation.positionalArguments[0] as DivisionEntity;
        return Right(entity);
      });

      final result = await useCase(defaultParams);

      result.fold((failure) => fail('Expected Right'), (divisions) {
        expect(divisions.isNotEmpty, isTrue);
      });

      verify(() => mockRepository.createDivision(any())).called(greaterThan(0));
    });

    test('generates divisions with correct age groups', () async {
      DivisionEntity? captured;
      when(() => mockRepository.createDivision(any())).thenAnswer((inv) async {
        captured = inv.positionalArguments[0] as DivisionEntity;
        return Right(captured!);
      });

      final result = await useCase(defaultParams);

      result.fold((failure) => fail('Expected Right'), (divisions) {
        expect(divisions.any((d) => d.ageMin == 6), isTrue);
        expect(divisions.any((d) => d.ageMin == 9), isTrue);
      });
    });

    test('generates divisions with correct belt groups', () async {
      when(() => mockRepository.createDivision(any())).thenAnswer((inv) async {
        final entity = inv.positionalArguments[0] as DivisionEntity;
        return Right(entity);
      });

      final result = await useCase(defaultParams);

      result.fold((failure) => fail('Expected Right'), (divisions) {
        expect(divisions.any((d) => d.beltRankMin == 'white'), isTrue);
        expect(divisions.any((d) => d.beltRankMin == 'green'), isTrue);
      });
    });

    test('generates WT male weight classes', () async {
      when(() => mockRepository.createDivision(any())).thenAnswer((inv) async {
        final entity = inv.positionalArguments[0] as DivisionEntity;
        return Right(entity);
      });

      final result = await useCase(defaultParams);

      result.fold((failure) => fail('Expected Right'), (divisions) {
        final maleDivs = divisions
            .where((d) => d.gender == DivisionGender.male)
            .toList();
        expect(maleDivs.any((d) => d.weightMaxKg == 54.0), isTrue);
        expect(maleDivs.any((d) => d.weightMaxKg == 58.0), isTrue);
      });
    });

    test('generates WT female weight classes', () async {
      when(() => mockRepository.createDivision(any())).thenAnswer((inv) async {
        final entity = inv.positionalArguments[0] as DivisionEntity;
        return Right(entity);
      });

      final result = await useCase(defaultParams);

      result.fold((failure) => fail('Expected Right'), (divisions) {
        final femaleDivs = divisions
            .where((d) => d.gender == DivisionGender.female)
            .toList();
        expect(femaleDivs.any((d) => d.weightMaxKg == 46.0), isTrue);
        expect(femaleDivs.any((d) => d.weightMaxKg == 49.0), isTrue);
      });
    });

    test('generates ITF weight classes', () async {
      final itfParams = defaultParams.copyWith(
        federationType: FederationType.itf,
        weightClasses: WeightClassConfig.itf,
      );
      when(() => mockRepository.createDivision(any())).thenAnswer((inv) async {
        final entity = inv.positionalArguments[0] as DivisionEntity;
        return Right(entity);
      });

      final result = await useCase(itfParams);

      result.fold((failure) => fail('Expected Right'), (divisions) {
        expect(divisions.any((d) => d.weightMaxKg == 82.0), isTrue);
      });
    });

    test('generates ATA custom weight classes', () async {
      final ataParams = defaultParams.copyWith(
        federationType: FederationType.ata,
        weightClasses: WeightClassConfig.ata,
      );
      when(() => mockRepository.createDivision(any())).thenAnswer((inv) async {
        final entity = inv.positionalArguments[0] as DivisionEntity;
        return Right(entity);
      });

      final result = await useCase(ataParams);

      result.fold((failure) => fail('Expected Right'), (divisions) {
        expect(divisions.any((d) => d.name.contains('Light')), isTrue);
        expect(divisions.any((d) => d.name.contains('Heavy')), isTrue);
      });
    });
  });

  group('performance', () {
    test('completes within 500ms for typical configuration', () async {
      when(() => mockRepository.createDivision(any())).thenAnswer((inv) async {
        final entity = inv.positionalArguments[0] as DivisionEntity;
        return Right(entity);
      });

      final stopwatch = Stopwatch()..start();
      final result = await useCase(defaultParams);
      stopwatch.stop();

      result.fold((failure) => fail('Expected Right'), (divisions) {
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
        expect(divisions.isNotEmpty, isTrue);
      });
    });

    test('handles large configuration efficiently', () async {
      when(() => mockRepository.createDivision(any())).thenAnswer((inv) async {
        final entity = inv.positionalArguments[0] as DivisionEntity;
        return Right(entity);
      });

      final params = SmartDivisionBuilderParams(
        tournamentId: 'tournament-123',
        federationType: FederationType.wt,
        categoryConfig: const DivisionCategoryConfig(
          category: DivisionCategoryType.sparring,
          applyWeightClasses: true,
        ),
        ageGroups: const [
          AgeGroupConfig(name: '6-8', minAge: 6, maxAge: 8),
          AgeGroupConfig(name: '9-10', minAge: 9, maxAge: 10),
          AgeGroupConfig(name: '11-12', minAge: 11, maxAge: 12),
          AgeGroupConfig(name: '13-14', minAge: 13, maxAge: 14),
          AgeGroupConfig(name: '15-17', minAge: 15, maxAge: 17),
          AgeGroupConfig(name: '18-32', minAge: 18, maxAge: 32),
          AgeGroupConfig(name: '33+', minAge: 33, maxAge: 99),
        ],
        beltGroups: const [
          BeltGroupConfig(name: 'white-yellow', minOrder: 1, maxOrder: 2),
          BeltGroupConfig(name: 'green-blue', minOrder: 4, maxOrder: 5),
          BeltGroupConfig(name: 'red-black', minOrder: 6, maxOrder: 7),
        ],
        weightClasses: WeightClassConfig.wt,
        includeEmptyDivisions: true,
        minimumParticipants: 1,
        isDemoMode: true,
      );

      final stopwatch = Stopwatch()..start();
      final result = await useCase(params);
      stopwatch.stop();

      result.fold((failure) => fail('Expected Right'), (divisions) {
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
        expect(divisions.isNotEmpty, isTrue);
      });
    });
  });

  group('filtering', () {
    test(
      'excludes empty divisions when includeEmptyDivisions is false',
      () async {
        when(() => mockRepository.createDivision(any())).thenAnswer((
          inv,
        ) async {
          final entity = inv.positionalArguments[0] as DivisionEntity;
          return Right(entity);
        });

        final paramsWithNoEmpty = defaultParams.copyWith(
          includeEmptyDivisions: false,
          minimumParticipants: 2,
        );

        final result = await useCase(paramsWithNoEmpty);

        result.fold((failure) => fail('Expected Right'), (divisions) {
          expect(divisions.isEmpty, isTrue);
        });
      },
    );

    test(
      'includes empty divisions when includeEmptyDivisions is true',
      () async {
        when(() => mockRepository.createDivision(any())).thenAnswer((
          inv,
        ) async {
          final entity = inv.positionalArguments[0] as DivisionEntity;
          return Right(entity);
        });

        final paramsWithEmpty = defaultParams.copyWith(
          includeEmptyDivisions: true,
          minimumParticipants: 1,
        );

        final result = await useCase(paramsWithEmpty);

        result.fold((failure) => fail('Expected Right'), (divisions) {
          expect(divisions.isNotEmpty, isTrue);
        });
      },
    );

    test('applies minimumParticipants threshold', () async {
      when(() => mockRepository.createDivision(any())).thenAnswer((inv) async {
        final entity = inv.positionalArguments[0] as DivisionEntity;
        return Right(entity);
      });

      final paramsWithThreshold = defaultParams.copyWith(
        minimumParticipants: 10,
        includeEmptyDivisions: false,
      );

      final result = await useCase(paramsWithThreshold);

      result.fold((failure) => fail('Expected Right'), (divisions) {
        expect(divisions.isEmpty, isTrue);
      });
    });
  });
}
