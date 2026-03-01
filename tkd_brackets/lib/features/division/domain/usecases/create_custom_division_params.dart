import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/entities/scoring_method.dart';

part 'create_custom_division_params.freezed.dart';
part 'create_custom_division_params.g.dart';

@freezed
class CreateCustomDivisionParams with _$CreateCustomDivisionParams {
  const factory CreateCustomDivisionParams({
    required String tournamentId,
    required String name,
    DivisionCategory? category,
    DivisionGender? gender,
    int? ageMin,
    int? ageMax,
    double? weightMinKg,
    double? weightMaxKg,
    String? beltRankMin,
    String? beltRankMax,
    BracketFormat? bracketFormat,
    @Default(3) int judgeCount,
    ScoringMethod? scoringMethod,
  }) = _CreateCustomDivisionParams;
  const CreateCustomDivisionParams._();

  factory CreateCustomDivisionParams.fromJson(Map<String, dynamic> json) =>
      _$CreateCustomDivisionParamsFromJson(json);
}
