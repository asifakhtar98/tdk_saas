import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_row_data.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_row_error.dart';

part 'csv_import_result.freezed.dart';

@freezed
class CSVImportResult with _$CSVImportResult {
  const factory CSVImportResult({
    required List<CSVRowData> validRows,
    required List<CSVRowError> errors,
    required int totalRows,
  }) = _CSVImportResult;

  const CSVImportResult._();

  int get successCount => validRows.length;
  int get errorCount => errors.length;
  bool get hasErrors => errors.isNotEmpty;
  bool get isEmpty => totalRows == 0;
}
