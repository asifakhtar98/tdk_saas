import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/create_participant_params.dart';

part 'csv_row_data.freezed.dart';

@freezed
class CSVRowData with _$CSVRowData {
  const factory CSVRowData({
    required String firstName,
    required String lastName,
    required String schoolOrDojangName,
    required String beltRank,
    required int sourceRowNumber,
    DateTime? dateOfBirth,
    Gender? gender,
    double? weightKg,
    String? registrationNumber,
    String? notes,
  }) = _CSVRowData;

  const CSVRowData._();

  CreateParticipantParams toCreateParticipantParams(String divisionId) {
    return CreateParticipantParams(
      divisionId: divisionId,
      firstName: firstName,
      lastName: lastName,
      schoolOrDojangName: schoolOrDojangName,
      beltRank: beltRank,
      dateOfBirth: dateOfBirth,
      gender: gender,
      weightKg: weightKg,
      registrationNumber: registrationNumber,
      notes: notes,
    );
  }
}
