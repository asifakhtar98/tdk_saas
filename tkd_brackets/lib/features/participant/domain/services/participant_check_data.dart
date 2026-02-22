import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_row_data.dart';

part 'participant_check_data.freezed.dart';

@freezed
class ParticipantCheckData with _$ParticipantCheckData {
  const factory ParticipantCheckData({
    required String firstName,
    required String lastName,
    required String schoolOrDojangName,
    DateTime? dateOfBirth,
    String? gender,
    String? beltRank,
    double? weightKg,
  }) = _ParticipantCheckData;

  const ParticipantCheckData._();

  factory ParticipantCheckData.fromCSVRowData(CSVRowData csvRow) {
    return ParticipantCheckData(
      firstName: csvRow.firstName,
      lastName: csvRow.lastName,
      schoolOrDojangName: csvRow.schoolOrDojangName,
      dateOfBirth: csvRow.dateOfBirth,
      gender: csvRow.gender?.value,
      beltRank: csvRow.beltRank,
      weightKg: csvRow.weightKg,
    );
  }

  factory ParticipantCheckData.fromEntity(ParticipantEntity entity) {
    return ParticipantCheckData(
      firstName: entity.firstName,
      lastName: entity.lastName,
      schoolOrDojangName: entity.schoolOrDojangName ?? '',
      dateOfBirth: entity.dateOfBirth,
      gender: entity.gender?.value,
      beltRank: entity.beltRank,
      weightKg: entity.weightKg,
    );
  }
}
