import 'package:freezed_annotation/freezed_annotation.dart';

part 'conflict_warning.freezed.dart';
part 'conflict_warning.g.dart';

@freezed
class ConflictWarning with _$ConflictWarning {
  const factory ConflictWarning({
    required String id,
    required String participantId,
    required String participantName,
    required String divisionId1,
    required String divisionName1,
    required int? ringNumber1,
    required String divisionId2,
    required String divisionName2,
    required int? ringNumber2,
    required ConflictType conflictType,
    String? dojangName,
  }) = _ConflictWarning;
  const ConflictWarning._();

  factory ConflictWarning.fromJson(Map<String, dynamic> json) =>
      _$ConflictWarningFromJson(json);
}

enum ConflictType { sameRing, timeOverlap }
