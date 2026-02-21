import 'package:freezed_annotation/freezed_annotation.dart';

part 'csv_row_error.freezed.dart';

@freezed
class CSVRowError with _$CSVRowError {
  const factory CSVRowError({
    required int rowNumber,
    required String fieldName,
    required String errorMessage,
    String? rawValue,
  }) = _CSVRowError;
}
