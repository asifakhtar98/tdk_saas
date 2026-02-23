import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_row_data.dart';
import 'package:tkd_brackets/features/participant/domain/services/duplicate_match.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_row_status.dart';

part 'bulk_import_preview_row.freezed.dart';

@freezed
class BulkImportPreviewRow with _$BulkImportPreviewRow {
  const factory BulkImportPreviewRow({
    required int sourceRowNumber,
    required CSVRowData rowData,
    required BulkImportRowStatus status,
    required List<DuplicateMatch> duplicateMatches,
    required Map<String, String> validationErrors,
  }) = _BulkImportPreviewRow;

  const BulkImportPreviewRow._();

  bool get hasDuplicates => duplicateMatches.isNotEmpty;
  bool get hasErrors => validationErrors.isNotEmpty;
  bool get isHighConfidenceDuplicate =>
      duplicateMatches.any((m) => m.isHighConfidence);
}
