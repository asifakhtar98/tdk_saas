import 'package:freezed_annotation/freezed_annotation.dart';

part 'conflict_warning.freezed.dart';
part 'conflict_warning.g.dart';

@freezed
class ConflictWarning with _$ConflictWarning {
  const ConflictWarning._();

  const factory ConflictWarning({
    required String id,
    required String participantId,
    required String participantName,
    String? dojangName,
    required String divisionId1,
    required String divisionName1,
    required int? ringNumber1,
    required String divisionId2,
    required String divisionName2,
    required int? ringNumber2,
    required ConflictType conflictType,
  }) = _ConflictWarning;

  factory ConflictWarning.fromJson(Map<String, dynamic> json) =>
      _$ConflictWarningFromJson(json);
}

enum ConflictType { sameRing, timeOverlap }
