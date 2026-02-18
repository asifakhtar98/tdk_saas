import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:tkd_brackets/core/database/app_database.dart'
    show ParticipantEntry;
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/division/domain/usecases/merge_divisions_params.dart';

@injectable
class MergeDivisionsUseCase
    extends UseCase<List<DivisionEntity>, MergeDivisionsParams> {
  MergeDivisionsUseCase(this._divisionRepository, this._uuid);

  final DivisionRepository _divisionRepository;
  final Uuid _uuid;

  @override
  Future<Either<Failure, List<DivisionEntity>>> call(
    MergeDivisionsParams params,
  ) async {
    final validationFailure = await _validateParams(params);
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    final divisionAResult = await _divisionRepository.getDivision(
      params.divisionIdA,
    );
    final divisionBResult = await _divisionRepository.getDivision(
      params.divisionIdB,
    );

    final divisionA = divisionAResult.fold(
      (failure) => null,
      (division) => division,
    );
    final divisionB = divisionBResult.fold(
      (failure) => null,
      (division) => division,
    );

    if (divisionA == null || divisionB == null) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'One or both divisions not found',
          fieldErrors: {'divisionId': 'Invalid division ID'},
        ),
      );
    }

    final raceConditionFailure = await _checkRaceCondition(
      divisionA,
      divisionB,
    );
    if (raceConditionFailure != null) {
      return Left(raceConditionFailure);
    }

    final proposedName =
        params.name ?? _generateMergedName(divisionA, divisionB);
    final nameCheck = await _divisionRepository.isDivisionNameUnique(
      proposedName,
      divisionA.tournamentId,
    );

    final isNameUnique = nameCheck.fold((l) => false, (r) => r);
    if (!isNameUnique) {
      return Left(
        ValidationFailure(
          userFriendlyMessage:
              'Division name already exists in this tournament',
          fieldErrors: {'name': 'Please choose a different name'},
        ),
      );
    }

    final participantsResult = await _divisionRepository
        .getParticipantsForDivisions([params.divisionIdA, params.divisionIdB]);

    final participants = participantsResult.fold(
      (failure) => <ParticipantEntry>[],
      (list) => list,
    );

    final uniqueParticipants = _deduplicateParticipants(participants);

    final mergedDivision = _buildMergedDivision(
      divisionA,
      divisionB,
      proposedName,
    );

    final deletedDivisionA = divisionA.copyWith(
      isDeleted: true,
      syncVersion: divisionA.syncVersion + 1,
      updatedAtTimestamp: DateTime.now(),
    );

    final deletedDivisionB = divisionB.copyWith(
      isDeleted: true,
      syncVersion: divisionB.syncVersion + 1,
      updatedAtTimestamp: DateTime.now(),
    );

    final results = await _divisionRepository.mergeDivisions(
      mergedDivision: mergedDivision,
      sourceDivisions: [deletedDivisionA, deletedDivisionB],
      participants: uniqueParticipants,
    );

    return results;
  }

  Future<ValidationFailure?> _validateParams(
    MergeDivisionsParams params,
  ) async {
    if (params.divisionIdA == params.divisionIdB) {
      return const ValidationFailure(
        userFriendlyMessage: 'Cannot merge a division with itself',
        fieldErrors: {'divisionId': 'Select two different divisions'},
      );
    }

    final divisionAResult = await _divisionRepository.getDivision(
      params.divisionIdA,
    );
    final divisionBResult = await _divisionRepository.getDivision(
      params.divisionIdB,
    );

    final divisionA = divisionAResult.fold((l) => null, (d) => d);
    final divisionB = divisionBResult.fold((l) => null, (d) => d);

    if (divisionA == null || divisionB == null) {
      return const ValidationFailure(
        userFriendlyMessage: 'One or both divisions not found',
        fieldErrors: {'divisionId': 'Invalid division ID'},
      );
    }

    if (divisionA.tournamentId != divisionB.tournamentId) {
      return const ValidationFailure(
        userFriendlyMessage:
            'Cannot merge divisions from different tournaments',
        fieldErrors: {'tournament': 'Divisions must be in the same tournament'},
      );
    }

    if (divisionA.category != divisionB.category) {
      return const ValidationFailure(
        userFriendlyMessage:
            'Cannot merge divisions with different event types',
        fieldErrors: {'category': 'Both divisions must have the same category'},
      );
    }

    if (divisionA.isDeleted || divisionB.isDeleted) {
      return const ValidationFailure(
        userFriendlyMessage: 'Cannot merge already merged/deleted divisions',
        fieldErrors: {
          'divisionId': 'One or both divisions are no longer active',
        },
      );
    }

    if (divisionA.isCombined || divisionB.isCombined) {
      return const ValidationFailure(
        userFriendlyMessage: 'Cannot merge divisions that were already merged',
        fieldErrors: {
          'divisionId': 'One or both divisions are already combined',
        },
      );
    }

    return null;
  }

  DivisionEntity _buildMergedDivision(
    DivisionEntity a,
    DivisionEntity b,
    String name,
  ) {
    return DivisionEntity(
      id: _uuid.v4(),
      tournamentId: a.tournamentId,
      name: name,
      category: a.category,
      gender: _resolveGender(a.gender, b.gender),
      ageMin: _minValue(a.ageMin, b.ageMin),
      ageMax: _maxValue(a.ageMax, b.ageMax),
      weightMinKg: _minWeight(a.weightMinKg, b.weightMinKg),
      weightMaxKg: _maxWeight(a.weightMaxKg, b.weightMaxKg),
      beltRankMin: _minBelt(a.beltRankMin, b.beltRankMin),
      beltRankMax: _maxBelt(a.beltRankMax, b.beltRankMax),
      bracketFormat: a.bracketFormat,
      isCustom: true,
      status: DivisionStatus.setup,
      isCombined: true,
      displayOrder: (_maxValue(a.displayOrder, b.displayOrder) ?? 0) + 1,
      syncVersion: 1,
      isDeleted: false,
      isDemoData: a.isDemoData || b.isDemoData,
      createdAtTimestamp: DateTime.now(),
      updatedAtTimestamp: DateTime.now(),
    );
  }

  String _generateMergedName(DivisionEntity a, DivisionEntity b) {
    final weightMin = a.weightMinKg ?? b.weightMinKg;
    final weightMax = a.weightMaxKg ?? b.weightMaxKg;
    if (weightMin != null && weightMax != null) {
      return '${a.name.split(' ').first} ${weightMin.toInt()} to ${weightMax.toInt()}kg';
    }
    return '${a.name} + ${b.name}';
  }

  int? _minValue(int? a, int? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return a < b ? a : b;
  }

  int? _maxValue(int? a, int? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return a > b ? a : b;
  }

  double? _minWeight(double? a, double? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return a < b ? a : b;
  }

  double? _maxWeight(double? a, double? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return a > b ? a : b;
  }

  String? _minBelt(String? a, String? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return _beltOrdinal(a) < _beltOrdinal(b) ? a : b;
  }

  String? _maxBelt(String? a, String? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return _beltOrdinal(a) > _beltOrdinal(b) ? a : b;
  }

  int _beltOrdinal(String belt) {
    const belts = [
      'white',
      'yellow',
      'orange',
      'green',
      'blue',
      'purple',
      'brown',
      'red',
      'black',
    ];
    final normalizedBelt = belt.toLowerCase().split(' ').first;
    final idx = belts.indexOf(normalizedBelt);
    return idx >= 0 ? idx : 0;
  }

  DivisionGender _resolveGender(DivisionGender a, DivisionGender b) {
    if (a == b) return a;
    if (a == DivisionGender.mixed || b == DivisionGender.mixed)
      return DivisionGender.mixed;
    return DivisionGender.mixed;
  }

  List<ParticipantEntry> _deduplicateParticipants(
    List<ParticipantEntry> participants,
  ) {
    final uniqueMap = <String, ParticipantEntry>{};
    for (final p in participants) {
      uniqueMap[p.id] = p;
    }
    return uniqueMap.values.toList();
  }

  Future<ValidationFailure?> _checkRaceCondition(
    DivisionEntity divisionA,
    DivisionEntity divisionB,
  ) async {
    final currentA = await _divisionRepository.getDivision(divisionA.id);
    final currentB = await _divisionRepository.getDivision(divisionB.id);

    final latestA = currentA.fold((l) => null, (d) => d);
    final latestB = currentB.fold((l) => null, (d) => d);

    if (latestA == null || latestB == null) {
      return const ValidationFailure(
        userFriendlyMessage:
            'One or both divisions were modified by another operation',
        fieldErrors: {'divisionId': 'Please retry the operation'},
      );
    }

    if (latestA.syncVersion != divisionA.syncVersion ||
        latestB.syncVersion != divisionB.syncVersion) {
      return const ValidationFailure(
        userFriendlyMessage: 'Concurrent modification detected. Please retry.',
        fieldErrors: {'syncVersion': 'Data was modified by another user'},
      );
    }

    return null;
  }
}
