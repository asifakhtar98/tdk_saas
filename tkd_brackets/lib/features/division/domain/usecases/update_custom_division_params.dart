import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/entities/scoring_method.dart';

part 'update_custom_division_params.freezed.dart';
part 'update_custom_division_params.g.dart';

@freezed
class UpdateCustomDivisionParams with _$UpdateCustomDivisionParams {

  const factory UpdateCustomDivisionParams({
    required String divisionId,
    String? name,
    DivisionCategory? category,
    DivisionGender? gender,
    int? ageMin,
    int? ageMax,
    double? weightMinKg,
    double? weightMaxKg,
    String? beltRankMin,
    String? beltRankMax,
    BracketFormat? bracketFormat,
    int? judgeCount,
    ScoringMethod? scoringMethod,
  }) = _UpdateCustomDivisionParams;
  const UpdateCustomDivisionParams._();

  factory UpdateCustomDivisionParams.fromJson(Map<String, dynamic> json) =>
      _$UpdateCustomDivisionParamsFromJson(json);
}
