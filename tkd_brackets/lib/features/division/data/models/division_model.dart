// Freezed uses @JsonKey on constructor parameters which triggers this lint.
// This is the documented freezed pattern and works correctly with code gen.
// ignore_for_file: invalid_annotation_target

import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';

part 'division_model.freezed.dart';
part 'division_model.g.dart';

@freezed
class DivisionModel with _$DivisionModel {
  const factory DivisionModel({
    required String id,
    required String tournamentId,
    required String name,
    required String category,
    required String gender,
    int? ageMin,
    int? ageMax,
    double? weightMinKg,
    double? weightMaxKg,
    String? beltRankMin,
    String? beltRankMax,
    required String bracketFormat,
    int? assignedRingNumber,
    @Default(false) bool isCombined,
    @Default(0) int displayOrder,
    required String status,
    @Default(false) bool isDeleted,
    DateTime? deletedAtTimestamp,
    @Default(false) bool isDemoData,
    required DateTime createdAtTimestamp,
    required DateTime updatedAtTimestamp,
    @Default(1) int syncVersion,
  }) = _DivisionModel;

  const DivisionModel._();

  factory DivisionModel.fromJson(Map<String, dynamic> json) =>
      _$DivisionModelFromJson(json);

  factory DivisionModel.fromDriftEntry(DivisionEntry entry) {
    return DivisionModel(
      id: entry.id,
      tournamentId: entry.tournamentId,
      name: entry.name,
      category: entry.category,
      gender: entry.gender,
      ageMin: entry.ageMin,
      ageMax: entry.ageMax,
      weightMinKg: entry.weightMinKg,
      weightMaxKg: entry.weightMaxKg,
      beltRankMin: entry.beltRankMin,
      beltRankMax: entry.beltRankMax,
      bracketFormat: entry.bracketFormat,
      assignedRingNumber: entry.assignedRingNumber,
      isCombined: entry.isCombined,
      displayOrder: entry.displayOrder,
      status: entry.status,
      isDeleted: entry.isDeleted,
      deletedAtTimestamp: entry.deletedAtTimestamp,
      isDemoData: entry.isDemoData,
      createdAtTimestamp: entry.createdAtTimestamp,
      updatedAtTimestamp: entry.updatedAtTimestamp,
      syncVersion: entry.syncVersion,
    );
  }

  factory DivisionModel.convertFromEntity(
    DivisionEntity entity, {
    int? syncVersion,
    bool? isDeleted,
    bool? isDemoData,
    DateTime? updatedAtTimestamp,
    DateTime? deletedAtTimestamp,
  }) {
    final now = DateTime.now();
    return DivisionModel(
      id: entity.id,
      tournamentId: entity.tournamentId,
      name: entity.name,
      category: entity.category.value,
      gender: entity.gender.value,
      ageMin: entity.ageMin,
      ageMax: entity.ageMax,
      weightMinKg: entity.weightMinKg,
      weightMaxKg: entity.weightMaxKg,
      beltRankMin: entity.beltRankMin,
      beltRankMax: entity.beltRankMax,
      bracketFormat: entity.bracketFormat.value,
      assignedRingNumber: entity.assignedRingNumber,
      isCombined: entity.isCombined,
      displayOrder: entity.displayOrder,
      status: entity.status.value,
      isDeleted: isDeleted ?? entity.isDeleted,
      deletedAtTimestamp: deletedAtTimestamp ?? entity.deletedAtTimestamp,
      isDemoData: isDemoData ?? entity.isDemoData,
      createdAtTimestamp: entity.createdAtTimestamp,
      updatedAtTimestamp: updatedAtTimestamp ?? now,
      syncVersion: syncVersion ?? entity.syncVersion,
    );
  }

  DivisionsCompanion toDriftCompanion() {
    return DivisionsCompanion.insert(
      id: id,
      tournamentId: tournamentId,
      name: name,
      category: Value(category),
      gender: gender,
      ageMin: Value(ageMin),
      ageMax: Value(ageMax),
      weightMinKg: Value(weightMinKg),
      weightMaxKg: Value(weightMaxKg),
      beltRankMin: Value(beltRankMin),
      beltRankMax: Value(beltRankMax),
      bracketFormat: Value(bracketFormat),
      assignedRingNumber: Value(assignedRingNumber),
      isCombined: Value(isCombined),
      displayOrder: Value(displayOrder),
      status: Value(status),
      isDeleted: Value(isDeleted),
      deletedAtTimestamp: Value(deletedAtTimestamp),
      isDemoData: Value(isDemoData),
      syncVersion: Value(syncVersion),
      createdAtTimestamp: Value(createdAtTimestamp),
      updatedAtTimestamp: Value(updatedAtTimestamp),
    );
  }

  DivisionEntity convertToEntity() {
    return DivisionEntity(
      id: id,
      tournamentId: tournamentId,
      name: name,
      category: DivisionCategory.fromString(category),
      gender: DivisionGender.fromString(gender),
      ageMin: ageMin,
      ageMax: ageMax,
      weightMinKg: weightMinKg,
      weightMaxKg: weightMaxKg,
      beltRankMin: beltRankMin,
      beltRankMax: beltRankMax,
      bracketFormat: BracketFormat.fromString(bracketFormat),
      assignedRingNumber: assignedRingNumber,
      isCombined: isCombined,
      displayOrder: displayOrder,
      status: DivisionStatus.fromString(status),
      isDeleted: isDeleted,
      deletedAtTimestamp: deletedAtTimestamp,
      isDemoData: isDemoData,
      createdAtTimestamp: createdAtTimestamp,
      updatedAtTimestamp: updatedAtTimestamp,
      syncVersion: syncVersion,
    );
  }
}
