import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/division/domain/entities/belt_rank.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/division/domain/usecases/create_custom_division_params.dart';

@injectable
class CreateCustomDivisionUseCase
    extends UseCase<DivisionEntity, CreateCustomDivisionParams> {
  CreateCustomDivisionUseCase(this._divisionRepository);

  final DivisionRepository _divisionRepository;

  @override
  Future<Either<Failure, DivisionEntity>> call(
    CreateCustomDivisionParams params,
  ) async {
    final validationFailure = await _validateParams(params);
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    final now = DateTime.now();
    final division = DivisionEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tournamentId: params.tournamentId,
      name: params.name,
      category: params.category ?? DivisionCategory.sparring,
      gender: params.gender ?? DivisionGender.mixed,
      ageMin: params.ageMin,
      ageMax: params.ageMax,
      weightMinKg: params.weightMinKg,
      weightMaxKg: params.weightMaxKg,
      beltRankMin: params.beltRankMin,
      beltRankMax: params.beltRankMax,
      bracketFormat: params.bracketFormat ?? BracketFormat.singleElimination,
      isCustom: true,
      status: DivisionStatus.setup,
      isCombined: false,
      displayOrder: 0,
      syncVersion: 1,
      isDeleted: false,
      isDemoData: false,
      createdAtTimestamp: now,
      updatedAtTimestamp: now,
    );

    return _divisionRepository.createDivision(division);
  }

  Future<ValidationFailure?> _validateParams(
    CreateCustomDivisionParams params,
  ) async {
    if (params.name.trim().isEmpty) {
      return const ValidationFailure(
        userFriendlyMessage: 'Division name is required',
        fieldErrors: {'name': 'Division name cannot be empty'},
      );
    }

    if (params.name.length > 100) {
      return const ValidationFailure(
        userFriendlyMessage: 'Division name is too long',
        fieldErrors: {'name': 'Maximum 100 characters allowed'},
      );
    }

    if (params.ageMin != null || params.ageMax != null) {
      final min = params.ageMin ?? 0;
      final max = params.ageMax ?? 100;
      if (min > max) {
        return const ValidationFailure(
          userFriendlyMessage: 'Invalid age range',
          fieldErrors: {'ageMin': 'Minimum age must be less than maximum age'},
        );
      }
      if (min < 0 || max > 100 || min > 100 || max < 0) {
        return const ValidationFailure(
          userFriendlyMessage: 'Invalid age value',
          fieldErrors: {'age': 'Age must be between 0 and 100'},
        );
      }
    }

    if (params.weightMinKg != null || params.weightMaxKg != null) {
      final min = params.weightMinKg ?? 0.0;
      final max = params.weightMaxKg ?? 200.0;
      if (min > max) {
        return const ValidationFailure(
          userFriendlyMessage: 'Invalid weight range',
          fieldErrors: {
            'weightMinKg': 'Minimum weight must be less than maximum weight',
          },
        );
      }
      if (min < 0 || max > 200 || min > 200 || max < 0) {
        return const ValidationFailure(
          userFriendlyMessage: 'Invalid weight value',
          fieldErrors: {'weight': 'Weight must be between 0 and 200 kg'},
        );
      }
    }

    if (params.beltRankMin != null && params.beltRankMax != null) {
      final minRank = BeltRank.fromString(params.beltRankMin!);
      final maxRank = BeltRank.fromString(params.beltRankMax!);
      if (minRank != null && maxRank != null && minRank.order > maxRank.order) {
        return const ValidationFailure(
          userFriendlyMessage: 'Invalid belt rank range',
          fieldErrors: {
            'beltRankMin': 'Minimum belt rank must be less than maximum',
          },
        );
      }
    }

    if (params.judgeCount < 1 || params.judgeCount > 5) {
      return const ValidationFailure(
        userFriendlyMessage: 'Invalid judge count',
        fieldErrors: {'judgeCount': 'Number of judges must be between 1 and 5'},
      );
    }

    final hasCriteria =
        params.ageMin != null ||
        params.ageMax != null ||
        params.weightMinKg != null ||
        params.weightMaxKg != null ||
        params.beltRankMin != null ||
        params.beltRankMax != null;
    final hasEventType = params.category != null;

    if (!hasCriteria && !hasEventType) {
      return const ValidationFailure(
        userFriendlyMessage: 'At least one criterion or event type is required',
        fieldErrors: {
          'criteria': 'Please specify age, weight, belt, or category',
        },
      );
    }

    final divisionsResult = await _divisionRepository.getDivisionsForTournament(
      params.tournamentId,
    );
    final existingDivisions = divisionsResult.fold(
      (failure) => <DivisionEntity>[],
      (divisions) => divisions,
    );

    final nameExists = existingDivisions.any(
      (d) => d.name.toLowerCase() == params.name.toLowerCase() && !d.isDeleted,
    );

    if (nameExists) {
      return const ValidationFailure(
        userFriendlyMessage: 'Division name already exists in this tournament',
        fieldErrors: {'name': 'A division with this name already exists'},
      );
    }

    return null;
  }
}
