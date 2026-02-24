import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';

part 'smart_division_builder_params.freezed.dart';

@freezed
class SmartDivisionBuilderParams with _$SmartDivisionBuilderParams {
  const factory SmartDivisionBuilderParams({
    required String tournamentId,
    required FederationType federationType,
    required DivisionCategoryConfig categoryConfig,
    required List<AgeGroupConfig> ageGroups,
    required List<BeltGroupConfig> beltGroups,
    required WeightClassConfig weightClasses,
    @Default(true) bool includeEmptyDivisions,
    @Default(1) int? minimumParticipants,
    @Default(false) bool isDemoMode,
    @Default(NamingConventionType.federationDefault)
    NamingConventionType namingConvention,
  }) = _SmartDivisionBuilderParams;
}

class AgeGroupConfig {

  const AgeGroupConfig({
    required this.name,
    required this.minAge,
    required this.maxAge,
  });
  final String name;
  final int minAge;
  final int maxAge;

  static const List<AgeGroupConfig> defaultAgeGroups = [
    AgeGroupConfig(name: 'Pediatric 1', minAge: 5, maxAge: 7),
    AgeGroupConfig(name: 'Pediatric 2', minAge: 8, maxAge: 9),
    AgeGroupConfig(name: 'Pediatric 3', minAge: 10, maxAge: 11),
    AgeGroupConfig(name: 'Youth 1', minAge: 12, maxAge: 13),
    AgeGroupConfig(name: 'Youth 2', minAge: 14, maxAge: 15),
    AgeGroupConfig(name: 'Cadet', minAge: 16, maxAge: 17),
    AgeGroupConfig(name: 'Junior', minAge: 18, maxAge: 21),
    AgeGroupConfig(name: 'Senior', minAge: 22, maxAge: 34),
    AgeGroupConfig(name: 'Veterans', minAge: 35, maxAge: 99),
  ];

  static const List<AgeGroupConfig> storyAgeGroups = [
    AgeGroupConfig(name: '6-8', minAge: 6, maxAge: 8),
    AgeGroupConfig(name: '9-10', minAge: 9, maxAge: 10),
    AgeGroupConfig(name: '11-12', minAge: 11, maxAge: 12),
    AgeGroupConfig(name: '13-14', minAge: 13, maxAge: 14),
    AgeGroupConfig(name: '15-17', minAge: 15, maxAge: 17),
    AgeGroupConfig(name: '18-32', minAge: 18, maxAge: 32),
    AgeGroupConfig(name: '33+', minAge: 33, maxAge: 99),
  ];
}

class BeltGroupConfig {

  const BeltGroupConfig({
    required this.name,
    required this.minOrder,
    required this.maxOrder,
  });
  final String name;
  final int minOrder;
  final int maxOrder;

  static const List<BeltGroupConfig> defaultBeltGroups = [
    BeltGroupConfig(name: 'white-yellow', minOrder: 1, maxOrder: 2),
    BeltGroupConfig(name: 'green-blue', minOrder: 4, maxOrder: 5),
    BeltGroupConfig(name: 'red-black', minOrder: 6, maxOrder: 7),
  ];

  static const List<BeltGroupConfig> storyBeltGroups = [
    BeltGroupConfig(name: 'white-yellow', minOrder: 1, maxOrder: 2),
    BeltGroupConfig(name: 'green-blue', minOrder: 4, maxOrder: 5),
    BeltGroupConfig(name: 'red-black', minOrder: 6, maxOrder: 7),
  ];
}

class DivisionCategoryConfig {

  const DivisionCategoryConfig({
    required this.category,
    this.applyWeightClasses = true,
  });
  final DivisionCategoryType category;
  final bool applyWeightClasses;
}

enum DivisionCategoryType { sparring, poomsae, breaking, demoTeam }

enum DivisionGenderType { male, female, mixed }

class WeightClassConfig {

  const WeightClassConfig({
    required this.federationType,
    required this.maleClasses,
    required this.femaleClasses,
  });
  final FederationType federationType;
  final List<WeightClass> maleClasses;
  final List<WeightClass> femaleClasses;

  static const WeightClassConfig wt = WeightClassConfig(
    federationType: FederationType.wt,
    maleClasses: [
      WeightClass(name: '-54kg', maxWeight: 54),
      WeightClass(name: '-58kg', maxWeight: 58),
      WeightClass(name: '-63kg', maxWeight: 63),
      WeightClass(name: '-68kg', maxWeight: 68),
      WeightClass(name: '-74kg', maxWeight: 74),
      WeightClass(name: '-80kg', maxWeight: 80),
      WeightClass(name: '+80kg', maxWeight: 999),
    ],
    femaleClasses: [
      WeightClass(name: '-46kg', maxWeight: 46),
      WeightClass(name: '-49kg', maxWeight: 49),
      WeightClass(name: '-53kg', maxWeight: 53),
      WeightClass(name: '-57kg', maxWeight: 57),
      WeightClass(name: '-62kg', maxWeight: 62),
      WeightClass(name: '-67kg', maxWeight: 67),
      WeightClass(name: '+67kg', maxWeight: 999),
    ],
  );

  static const WeightClassConfig itf = WeightClassConfig(
    federationType: FederationType.itf,
    maleClasses: [
      WeightClass(name: '-54kg', maxWeight: 54),
      WeightClass(name: '-58kg', maxWeight: 58),
      WeightClass(name: '-62kg', maxWeight: 62),
      WeightClass(name: '-67kg', maxWeight: 67),
      WeightClass(name: '-72kg', maxWeight: 72),
      WeightClass(name: '-77kg', maxWeight: 77),
      WeightClass(name: '-82kg', maxWeight: 82),
      WeightClass(name: '+82kg', maxWeight: 999),
    ],
    femaleClasses: [
      WeightClass(name: '-46kg', maxWeight: 46),
      WeightClass(name: '-49kg', maxWeight: 49),
      WeightClass(name: '-53kg', maxWeight: 53),
      WeightClass(name: '-57kg', maxWeight: 57),
      WeightClass(name: '-62kg', maxWeight: 62),
      WeightClass(name: '-67kg', maxWeight: 67),
      WeightClass(name: '+67kg', maxWeight: 999),
    ],
  );

  static const WeightClassConfig ata = WeightClassConfig(
    federationType: FederationType.ata,
    maleClasses: [
      WeightClass(name: 'Light', maxWeight: 55),
      WeightClass(name: 'Light-Medium', maxWeight: 65),
      WeightClass(name: 'Medium', maxWeight: 75),
      WeightClass(name: 'Medium-Heavy', maxWeight: 85),
      WeightClass(name: 'Heavy', maxWeight: 999),
    ],
    femaleClasses: [
      WeightClass(name: 'Light', maxWeight: 50),
      WeightClass(name: 'Light-Medium', maxWeight: 60),
      WeightClass(name: 'Medium', maxWeight: 70),
      WeightClass(name: 'Medium-Heavy', maxWeight: 80),
      WeightClass(name: 'Heavy', maxWeight: 999),
    ],
  );

  static WeightClassConfig forFederation(FederationType type) {
    switch (type) {
      case FederationType.wt:
        return wt;
      case FederationType.itf:
        return itf;
      case FederationType.ata:
        return ata;
      case FederationType.custom:
        return wt;
    }
  }
}

class WeightClass {

  const WeightClass({required this.name, required this.maxWeight});
  final String name;
  final double maxWeight;
}

enum NamingConventionType {
  federationDefault,
  withAgePrefix,
  withoutAgePrefix,
  short,
}
