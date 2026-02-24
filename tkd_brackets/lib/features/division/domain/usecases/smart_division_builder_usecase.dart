import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/division/domain/usecases/smart_division_builder_params.dart';
import 'package:tkd_brackets/features/division/domain/usecases/smart_division_naming_service.dart';
import 'package:uuid/uuid.dart';

class _ParticipantData {

  _ParticipantData({
    required this.age,
    required this.weightKg,
    required this.gender,
  });
  final int age;
  final double weightKg;
  final DivisionGenderType gender;
}

@injectable
class SmartDivisionBuilderUseCase
    extends UseCase<List<DivisionEntity>, SmartDivisionBuilderParams> {
  SmartDivisionBuilderUseCase(this._divisionRepository, this._database);

  final DivisionRepository _divisionRepository;
  final AppDatabase _database;
  final DivisionNamingService _namingService = DivisionNamingService();

  static const _uuid = Uuid();

  @override
  Future<Either<Failure, List<DivisionEntity>>> call(
    SmartDivisionBuilderParams params,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final participants = await _getParticipants(params);
      final divisions = _generateDivisions(params, participants);

      stopwatch.stop();
      if (stopwatch.elapsedMilliseconds > 500) {
        return const Left(
          InputValidationFailure(
            userFriendlyMessage:
                'Division generation exceeded 500ms performance limit',
            fieldErrors: {},
          ),
        );
      }

      final savedDivisions = <DivisionEntity>[];
      for (final division in divisions) {
        final result = await _divisionRepository.createDivision(division);
        result.fold(
          (failure) => savedDivisions.add(division),
          savedDivisions.add,
        );
      }

      return Right(savedDivisions);
    } catch (e) {
      return Left(
        ServerResponseFailure(
          userFriendlyMessage: 'Failed to generate divisions: $e',
        ),
      );
    }
  }

  Future<List<_ParticipantData>> _getParticipants(
    SmartDivisionBuilderParams params,
  ) async {
    if (params.isDemoMode) {
      return _getDemoParticipants();
    }

    try {
      final allParticipants = await _database.getActiveParticipants();
      final allDivisions = await _database.getDivisionsForTournament(
        params.tournamentId,
      );
      final divisionIds = allDivisions.map((d) => d.id).toSet();

      return allParticipants
          .where((p) => divisionIds.contains(p.divisionId))
          .map(
            (p) => _ParticipantData(
              age: _calculateAge(p.dateOfBirth),
              weightKg: p.weightKg ?? 0,
              gender: p.gender == 'male'
                  ? DivisionGenderType.male
                  : p.gender == 'female'
                  ? DivisionGenderType.female
                  : DivisionGenderType.mixed,
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  List<_ParticipantData> _getDemoParticipants() {
    return [
      _ParticipantData(age: 13, weightKg: 42, gender: DivisionGenderType.male),
      _ParticipantData(age: 14, weightKg: 44, gender: DivisionGenderType.male),
      _ParticipantData(age: 12, weightKg: 38, gender: DivisionGenderType.male),
      _ParticipantData(
        age: 13,
        weightKg: 41,
        gender: DivisionGenderType.female,
      ),
      _ParticipantData(age: 14, weightKg: 43, gender: DivisionGenderType.male),
      _ParticipantData(
        age: 12,
        weightKg: 39,
        gender: DivisionGenderType.female,
      ),
      _ParticipantData(age: 13, weightKg: 44, gender: DivisionGenderType.male),
      _ParticipantData(
        age: 14,
        weightKg: 45,
        gender: DivisionGenderType.female,
      ),
    ];
  }

  int _calculateAge(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return 0;
    final now = DateTime.now();
    var age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  List<DivisionEntity> _generateDivisions(
    SmartDivisionBuilderParams params,
    List<_ParticipantData> participants,
  ) {
    final divisions = <DivisionEntity>[];
    final now = DateTime.now();

    final genders =
        params.categoryConfig.category == DivisionCategoryType.sparring
        ? [DivisionGenderType.male, DivisionGenderType.female]
        : [DivisionGenderType.mixed];

    for (final ageGroup in params.ageGroups) {
      for (final beltGroup in params.beltGroups) {
        for (final gender in genders) {
          final weightClasses = gender == DivisionGenderType.male
              ? params.weightClasses.maleClasses
              : params.weightClasses.femaleClasses;

          if (!params.categoryConfig.applyWeightClasses) {
            final participantCount = _countMatchingParticipants(
              participants,
              ageGroup,
              beltGroup,
              gender,
              null,
              params.weightClasses,
            );

            if (!_meetsThreshold(participantCount, params)) continue;

            final name = _namingService.generateDivisionName(
              federationType: params.federationType,
              convention: params.namingConvention,
              ageGroup: ageGroup,
              beltGroup: beltGroup,
              weightClass: null,
              gender: gender,
              category: params.categoryConfig.category,
            );

            divisions.add(
              _createDivisionEntity(
                tournamentId: params.tournamentId,
                name: name,
                category: params.categoryConfig.category,
                gender: gender,
                ageGroup: ageGroup,
                beltGroup: beltGroup,
                weightClass: null,
                now: now,
                weightConfig: params.weightClasses,
              ),
            );
          } else {
            for (final weightClass in weightClasses) {
              final participantCount = _countMatchingParticipants(
                participants,
                ageGroup,
                beltGroup,
                gender,
                weightClass,
                params.weightClasses,
              );

              if (!_meetsThreshold(participantCount, params)) continue;

              final name = _namingService.generateDivisionName(
                federationType: params.federationType,
                convention: params.namingConvention,
                ageGroup: ageGroup,
                beltGroup: beltGroup,
                weightClass: weightClass,
                gender: gender,
                category: params.categoryConfig.category,
              );

              divisions.add(
                _createDivisionEntity(
                  tournamentId: params.tournamentId,
                  name: name,
                  category: params.categoryConfig.category,
                  gender: gender,
                  ageGroup: ageGroup,
                  beltGroup: beltGroup,
                  weightClass: weightClass,
                  now: now,
                  weightConfig: params.weightClasses,
                ),
              );
            }
          }
        }
      }
    }

    return divisions;
  }

  int _countMatchingParticipants(
    List<_ParticipantData> participants,
    AgeGroupConfig ageGroup,
    BeltGroupConfig beltGroup,
    DivisionGenderType gender,
    WeightClass? weightClass,
    WeightClassConfig weightConfig,
  ) {
    return participants.where((p) {
      if (p.gender != gender && gender != DivisionGenderType.mixed) {
        return false;
      }
      if (p.age < ageGroup.minAge || p.age > ageGroup.maxAge) {
        return false;
      }
      if (weightClass != null) {
        if (p.weightKg <= 0) return false;
        final prevWeight = _getPreviousWeight(weightClass, weightConfig) ?? 0;
        if (p.weightKg < prevWeight || p.weightKg > weightClass.maxWeight) {
          return false;
        }
      }
      return true;
    }).length;
  }

  bool _meetsThreshold(int count, SmartDivisionBuilderParams params) {
    if (!params.includeEmptyDivisions && count == 0) {
      return false;
    }
    if (params.minimumParticipants != null && count > 0) {
      if (count < params.minimumParticipants!) {
        return false;
      }
    }
    return true;
  }

  DivisionEntity _createDivisionEntity({
    required String tournamentId,
    required String name,
    required DivisionCategoryType category,
    required DivisionGenderType gender,
    required AgeGroupConfig? ageGroup,
    required BeltGroupConfig? beltGroup,
    required WeightClass? weightClass,
    required DateTime now,
    required WeightClassConfig weightConfig,
  }) {
    return DivisionEntity(
      id: _uuid.v4(),
      tournamentId: tournamentId,
      name: name,
      category: _mapCategoryType(category),
      gender: _mapGender(gender),
      ageMin: ageGroup?.minAge,
      ageMax: ageGroup?.maxAge,
      weightMinKg: weightClass != null && weightClass.maxWeight < 999
          ? _getPreviousWeight(weightClass, weightConfig)
          : null,
      weightMaxKg: weightClass != null && weightClass.maxWeight < 999
          ? weightClass.maxWeight
          : null,
      beltRankMin: beltGroup != null ? _getBeltRankMin(beltGroup) : null,
      beltRankMax: beltGroup != null ? _getBeltRankMax(beltGroup) : null,
      bracketFormat: BracketFormat.singleElimination,
      status: DivisionStatus.setup,
      createdAtTimestamp: now,
      updatedAtTimestamp: now,
    );
  }

  double? _getPreviousWeight(
    WeightClass weightClass,
    WeightClassConfig weightConfig,
  ) {
    final weightConfigs = weightConfig.maleClasses;
    final sortedWeights = weightConfigs.map((w) => w.maxWeight).toList()
      ..sort();

    final currentWeight = weightClass.maxWeight;
    final index = sortedWeights.indexOf(currentWeight);

    if (index <= 0) return 0;
    return sortedWeights[index - 1];
  }

  String? _getBeltRankMin(BeltGroupConfig beltGroup) {
    switch (beltGroup.minOrder) {
      case 1:
        return 'white';
      case 4:
        return 'green';
      case 6:
        return 'red';
      default:
        return 'white';
    }
  }

  String? _getBeltRankMax(BeltGroupConfig beltGroup) {
    switch (beltGroup.maxOrder) {
      case 2:
        return 'yellow';
      case 5:
        return 'blue';
      case 7:
        return 'black';
      default:
        return 'black';
    }
  }

  DivisionCategory _mapCategoryType(DivisionCategoryType type) {
    switch (type) {
      case DivisionCategoryType.sparring:
        return DivisionCategory.sparring;
      case DivisionCategoryType.poomsae:
        return DivisionCategory.poomsae;
      case DivisionCategoryType.breaking:
        return DivisionCategory.breaking;
      case DivisionCategoryType.demoTeam:
        return DivisionCategory.demoTeam;
    }
  }

  DivisionGender _mapGender(DivisionGenderType type) {
    switch (type) {
      case DivisionGenderType.male:
        return DivisionGender.male;
      case DivisionGenderType.female:
        return DivisionGender.female;
      case DivisionGenderType.mixed:
        return DivisionGender.mixed;
    }
  }
}
