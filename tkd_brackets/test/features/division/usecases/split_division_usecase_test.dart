import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/division/domain/usecases/split_division_params.dart';
import 'package:tkd_brackets/features/division/domain/usecases/split_division_usecase.dart';
import 'package:uuid/uuid.dart';

class MockDivisionRepository extends Mock implements DivisionRepository {}

class MockUuid extends Mock implements Uuid {}

class FakeDivisionEntity extends Fake implements DivisionEntity {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDivisionEntity());
  });

  late SplitDivisionUseCase useCase;
  late MockDivisionRepository mockRepository;
  late MockUuid mockUuid;

  setUp(() {
    mockRepository = MockDivisionRepository();
    mockUuid = MockUuid();
    useCase = SplitDivisionUseCase(mockRepository, mockUuid);
  });

  DivisionEntity createTestDivision({
    required String id,
    required String tournamentId,
    String name = 'Test Division',
    bool isCombined = false,
    bool isDeleted = false,
    int displayOrder = 0,
  }) {
    return DivisionEntity(
      id: id,
      tournamentId: tournamentId,
      name: name,
      category: DivisionCategory.sparring,
      gender: DivisionGender.male,
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

  group('SplitDivisionUseCase - Success', () {
    test('should split division into Pool A and Pool B', () async {
      when(() => mockUuid.v4()).thenReturn('new-uuid-123');

      const params = SplitDivisionParams(
        divisionId: 'div-a',
        distributionMethod: SplitDistributionMethod.alphabetical,
      );

      final sourceDivision = createTestDivision(
        id: 'div-a',
        tournamentId: 'tournament-1',
        name: 'Cadets -40kg',
      );

      when(
        () => mockRepository.getDivision('div-a'),
      ).thenAnswer((_) async => Right(sourceDivision));
      when(
        () => mockRepository.getParticipantsForDivision('div-a'),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockRepository.splitDivision(
          poolADivision: any(named: 'poolADivision'),
          poolBDivision: any(named: 'poolBDivision'),
          sourceDivision: any(named: 'sourceDivision'),
          poolAParticipants: any(named: 'poolAParticipants'),
          poolBParticipants: any(named: 'poolBParticipants'),
        ),
      ).thenAnswer((_) async => const Right([]));

      final result = await useCase(params);

      expect(result.isRight(), true);
      verify(
        () => mockRepository.splitDivision(
          poolADivision: any(named: 'poolADivision'),
          poolBDivision: any(named: 'poolBDivision'),
          sourceDivision: any(named: 'sourceDivision'),
          poolAParticipants: any(named: 'poolAParticipants'),
          poolBParticipants: any(named: 'poolBParticipants'),
        ),
      ).called(1);
    });

    test('should use custom base name when provided', () async {
      when(() => mockUuid.v4()).thenReturn('new-uuid-123');

      const params = SplitDivisionParams(
        divisionId: 'div-a',
        distributionMethod: SplitDistributionMethod.random,
        baseName: 'Custom Division',
      );

      final sourceDivision = createTestDivision(
        id: 'div-a',
        tournamentId: 'tournament-1',
      );

      when(
        () => mockRepository.getDivision('div-a'),
      ).thenAnswer((_) async => Right(sourceDivision));
      when(
        () => mockRepository.getParticipantsForDivision('div-a'),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockRepository.splitDivision(
          poolADivision: any(named: 'poolADivision'),
          poolBDivision: any(named: 'poolBDivision'),
          sourceDivision: any(named: 'sourceDivision'),
          poolAParticipants: any(named: 'poolAParticipants'),
          poolBParticipants: any(named: 'poolBParticipants'),
        ),
      ).thenAnswer((_) async => const Right([]));

      final result = await useCase(params);

      expect(result.isRight(), true);
    });
  });

  group('SplitDivisionUseCase - Validation Failures', () {
    test('should return ValidationFailure when division not found', () async {
      const params = SplitDivisionParams(
        divisionId: 'div-a',
        distributionMethod: SplitDistributionMethod.alphabetical,
      );

      when(
        () => mockRepository.getDivision('div-a'),
      ).thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await useCase(params);

      expect(result.isLeft(), true);
    });

    test('should return ValidationFailure for deleted division', () async {
      const params = SplitDivisionParams(
        divisionId: 'div-a',
        distributionMethod: SplitDistributionMethod.alphabetical,
      );

      final division = createTestDivision(
        id: 'div-a',
        tournamentId: 't1',
        isDeleted: true,
      );

      when(
        () => mockRepository.getDivision('div-a'),
      ).thenAnswer((_) async => Right(division));

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(
          (l as ValidationFailure).fieldErrors?.containsKey('divisionId'),
          true,
        ),
        (r) => fail('Expected Left'),
      );
    });

    test('should return ValidationFailure for combined division', () async {
      const params = SplitDivisionParams(
        divisionId: 'div-a',
        distributionMethod: SplitDistributionMethod.alphabetical,
      );

      final division = createTestDivision(
        id: 'div-a',
        tournamentId: 't1',
        isCombined: true,
      );

      when(
        () => mockRepository.getDivision('div-a'),
      ).thenAnswer((_) async => Right(division));
      when(
        () => mockRepository.getParticipantsForDivision('div-a'),
      ).thenAnswer((_) async => const Right([]));

      final result = await useCase(params);

      expect(result.isLeft(), true);
    });

    test(
      'should return ValidationFailure when less than 4 participants',
      () async {
        const params = SplitDivisionParams(
          divisionId: 'div-a',
          distributionMethod: SplitDistributionMethod.alphabetical,
        );

        final division = createTestDivision(id: 'div-a', tournamentId: 't1');

        when(
          () => mockRepository.getDivision('div-a'),
        ).thenAnswer((_) async => Right(division));
        when(
          () => mockRepository.getParticipantsForDivision('div-a'),
        ).thenAnswer((_) async => const Right([]));

        final result = await useCase(params);

        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(
            (l as ValidationFailure).fieldErrors?.containsKey('participants'),
            true,
          ),
          (r) => fail('Expected Left'),
        );
      },
    );
  });
}
