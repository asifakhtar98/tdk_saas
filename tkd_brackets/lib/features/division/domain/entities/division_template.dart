// Freezed uses @JsonKey on constructor parameters which triggers this lint.
// This is the documented freezed pattern and works correctly with code gen.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';

part 'division_template.freezed.dart';
part 'division_template.g.dart';

@freezed
class DivisionTemplate with _$DivisionTemplate {

  const factory DivisionTemplate({
    required String id,
    required FederationType federation, required DivisionCategory category, required String name, required DivisionGender gender, String? organizationId,
    int? ageMin,
    int? ageMax,
    double? weightMinKg,
    double? weightMaxKg,
    String? beltRankMin,
    String? beltRankMax,
    @Default(BracketFormat.singleElimination)
    BracketFormat defaultBracketFormat,
    @Default(0) int displayOrder,
    @Default(true) bool isActive,
  }) = _DivisionTemplate;
  const DivisionTemplate._();

  factory DivisionTemplate.fromJson(Map<String, dynamic> json) =>
      _$DivisionTemplateFromJson(json);

  bool get isStaticTemplate => organizationId == null;
  bool get isCustomTemplate => organizationId != null;
}
