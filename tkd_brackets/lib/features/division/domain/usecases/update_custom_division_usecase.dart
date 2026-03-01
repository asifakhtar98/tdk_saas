import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/division/domain/entities/belt_rank.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/division/domain/usecases/update_custom_division_params.dart';

@injectable
class UpdateCustomDivisionUseCase
    extends UseCase<DivisionEntity, UpdateCustomDivisionParams> {
  UpdateCustomDivisionUseCase(this._divisionRepository);

  final DivisionRepository _divisionRepository;

  @override
  Future<Either<Failure, DivisionEntity>> call(
    UpdateCustomDivisionParams params,
  ) async {
    final existingResult = await _divisionRepository.getDivisionById(
      params.divisionId,
    );

    return existingResult.fold(Left.new, (existingDivision) async {
      if (existingDivision.isCustom == false) {
        return const Left(
          ValidationFailure(
            userFriendlyMessage: 'Cannot modify template-derived divisions',
            fieldErrors: {
              'division':
                  'Template divisions are read-only. Create a custom division instead.',
            },
          ),
        );
      }

      final validationFailure = _validateParams(params);
      if (validationFailure != null) {
        return Left(validationFailure);
      }

      final updatedDivision = existingDivision.copyWith(
        name: params.name ?? existingDivision.name,
        category: params.category ?? existingDivision.category,
        gender: params.gender ?? existingDivision.gender,
        ageMin: params.ageMin ?? existingDivision.ageMin,
        ageMax: params.ageMax ?? existingDivision.ageMax,
        weightMinKg: params.weightMinKg ?? existingDivision.weightMinKg,
        weightMaxKg: params.weightMaxKg ?? existingDivision.weightMaxKg,
        beltRankMin: params.beltRankMin ?? existingDivision.beltRankMin,
        beltRankMax: params.beltRankMax ?? existingDivision.beltRankMax,
        bracketFormat: params.bracketFormat ?? existingDivision.bracketFormat,
        syncVersion: existingDivision.syncVersion + 1,
        updatedAtTimestamp: DateTime.now(),
      );

      return _divisionRepository.updateDivision(updatedDivision);
    });
  }

  ValidationFailure? _validateParams(UpdateCustomDivisionParams params) {
    if (params.name != null && params.name!.trim().isEmpty) {
      return const ValidationFailure(
        userFriendlyMessage: 'Division name cannot be empty',
        fieldErrors: {'name': 'Name is required'},
      );
    }

    if (params.name != null && params.name!.length > 100) {
      return const ValidationFailure(
        userFriendlyMessage: 'Division name is too long',
        fieldErrors: {'name': 'Maximum 100 characters'},
      );
    }

    if (params.ageMin != null && params.ageMax != null) {
      if (params.ageMin! > params.ageMax!) {
        return const ValidationFailure(
          userFriendlyMessage: 'Invalid age range',
          fieldErrors: {'ageMin': 'Min must be less than max'},
        );
      }
    }

    if (params.weightMinKg != null && params.weightMaxKg != null) {
      if (params.weightMinKg! > params.weightMaxKg!) {
        return const ValidationFailure(
          userFriendlyMessage: 'Invalid weight range',
          fieldErrors: {'weightMinKg': 'Min must be less than max'},
        );
      }
    }

    if (params.beltRankMin != null && params.beltRankMax != null) {
      final minRank = BeltRank.fromString(params.beltRankMin!);
      final maxRank = BeltRank.fromString(params.beltRankMax!);
      if (minRank != null && maxRank != null && minRank.order > maxRank.order) {
        return const ValidationFailure(
          userFriendlyMessage: 'Invalid belt rank range',
          fieldErrors: {'beltRankMin': 'Min belt must be less than max'},
        );
      }
    }

    if (params.judgeCount != null &&
        (params.judgeCount! < 1 || params.judgeCount! > 5)) {
      return const ValidationFailure(
        userFriendlyMessage: 'Invalid judge count',
        fieldErrors: {'judgeCount': 'Must be between 1 and 5'},
      );
    }

    return null;
  }
}
