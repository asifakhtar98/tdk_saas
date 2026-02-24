import 'package:freezed_annotation/freezed_annotation.dart';

part 'division_entity.freezed.dart';

@freezed
class DivisionEntity with _$DivisionEntity {
  const factory DivisionEntity({
    required String id,
    required String tournamentId,
    required String name,
    required DivisionCategory category,
    required DivisionGender gender,
    required BracketFormat bracketFormat, required DivisionStatus status, required DateTime createdAtTimestamp, required DateTime updatedAtTimestamp, int? ageMin,
    int? ageMax,
    double? weightMinKg,
    double? weightMaxKg,
    String? beltRankMin,
    String? beltRankMax,
    int? assignedRingNumber,
    @Default(false) bool isCombined,
    @Default(0) int displayOrder,
    @Default(false) bool isDeleted,
    DateTime? deletedAtTimestamp,
    @Default(false) bool isDemoData,
    @Default(false) bool isCustom,
    @Default(1) int syncVersion,
  }) = _DivisionEntity;
}

enum DivisionCategory {
  sparring('sparring'),
  poomsae('poomsae'),
  breaking('breaking'),
  demoTeam('demo_team');

  const DivisionCategory(this.value);

  final String value;

  static DivisionCategory fromString(String value) {
    return DivisionCategory.values.firstWhere(
      (cat) => cat.value == value,
      orElse: () => DivisionCategory.sparring,
    );
  }
}

enum DivisionGender {
  male('male'),
  female('female'),
  mixed('mixed');

  const DivisionGender(this.value);

  final String value;

  static DivisionGender fromString(String value) {
    return DivisionGender.values.firstWhere(
      (g) => g.value == value,
      orElse: () => DivisionGender.mixed,
    );
  }
}

enum BracketFormat {
  singleElimination('single_elimination'),
  doubleElimination('double_elimination'),
  roundRobin('round_robin'),
  poolPlay('pool_play');

  const BracketFormat(this.value);

  final String value;

  static BracketFormat fromString(String value) {
    return BracketFormat.values.firstWhere(
      (f) => f.value == value,
      orElse: () => BracketFormat.singleElimination,
    );
  }
}

enum DivisionStatus {
  setup('setup'),
  ready('ready'),
  inProgress('in_progress'),
  completed('completed');

  const DivisionStatus(this.value);

  final String value;

  static DivisionStatus fromString(String value) {
    return DivisionStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => DivisionStatus.setup,
    );
  }
}
