// Freezed uses @JsonKey on constructor parameters which triggers this lint.
// This is the documented freezed pattern and works correctly with code gen.
// ignore_for_file: invalid_annotation_target

import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_template.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';

part 'division_template_model.freezed.dart';
part 'division_template_model.g.dart';

@freezed
class DivisionTemplateModel with _$DivisionTemplateModel {
  const factory DivisionTemplateModel({
    required String id,
    String? organizationId,
    required String federationType,
    required String category,
    required String name,
    required String gender,
    int? ageMin,
    int? ageMax,
    double? weightMinKg,
    double? weightMaxKg,
    String? beltRankMin,
    String? beltRankMax,
    @Default('single_elimination') String defaultBracketFormat,
    @Default(0) int displayOrder,
    @Default(true) bool isActive,
    required DateTime createdAtTimestamp,
    required DateTime updatedAtTimestamp,
  }) = _DivisionTemplateModel;

  const DivisionTemplateModel._();

  factory DivisionTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$DivisionTemplateModelFromJson(json);

  factory DivisionTemplateModel.fromDriftEntry(DivisionTemplateEntry entry) {
    return DivisionTemplateModel(
      id: entry.id,
      organizationId: entry.organizationId,
      federationType: entry.federationType,
      category: entry.category,
      name: entry.name,
      gender: entry.gender,
      ageMin: entry.ageMin,
      ageMax: entry.ageMax,
      weightMinKg: entry.weightMinKg,
      weightMaxKg: entry.weightMaxKg,
      beltRankMin: entry.beltRankMin,
      beltRankMax: entry.beltRankMax,
      defaultBracketFormat: entry.defaultBracketFormat,
      displayOrder: entry.displayOrder,
      isActive: entry.isActive,
      createdAtTimestamp: entry.createdAtTimestamp,
      updatedAtTimestamp: entry.updatedAtTimestamp,
    );
  }

  factory DivisionTemplateModel.convertFromEntity(DivisionTemplate entity) {
    final now = DateTime.now();
    return DivisionTemplateModel(
      id: entity.id,
      organizationId: entity.organizationId,
      federationType: entity.federation.value,
      category: entity.category.value,
      name: entity.name,
      gender: entity.gender.value,
      ageMin: entity.ageMin,
      ageMax: entity.ageMax,
      weightMinKg: entity.weightMinKg,
      weightMaxKg: entity.weightMaxKg,
      beltRankMin: entity.beltRankMin,
      beltRankMax: entity.beltRankMax,
      defaultBracketFormat: entity.defaultBracketFormat.value,
      displayOrder: entity.displayOrder,
      isActive: entity.isActive,
      createdAtTimestamp: now,
      updatedAtTimestamp: now,
    );
  }

  DivisionTemplatesCompanion toDriftCompanion() {
    return DivisionTemplatesCompanion.insert(
      id: id,
      organizationId: Value(organizationId),
      federationType: federationType,
      category: category,
      name: name,
      gender: gender,
      ageMin: Value(ageMin),
      ageMax: Value(ageMax),
      weightMinKg: Value(weightMinKg),
      weightMaxKg: Value(weightMaxKg),
      beltRankMin: Value(beltRankMin),
      beltRankMax: Value(beltRankMax),
      defaultBracketFormat: Value(defaultBracketFormat),
      displayOrder: Value(displayOrder),
      isActive: Value(isActive),
      createdAtTimestamp: Value(createdAtTimestamp),
      updatedAtTimestamp: Value(updatedAtTimestamp),
    );
  }

  DivisionTemplate convertToEntity() {
    return DivisionTemplate(
      id: id,
      organizationId: organizationId,
      federation: FederationType.fromString(federationType),
      category: DivisionCategory.fromString(category),
      name: name,
      gender: DivisionGender.fromString(gender),
      ageMin: ageMin,
      ageMax: ageMax,
      weightMinKg: weightMinKg,
      weightMaxKg: weightMaxKg,
      beltRankMin: beltRankMin,
      beltRankMax: beltRankMax,
      defaultBracketFormat: BracketFormat.fromString(defaultBracketFormat),
      displayOrder: displayOrder,
      isActive: isActive,
    );
  }
}
