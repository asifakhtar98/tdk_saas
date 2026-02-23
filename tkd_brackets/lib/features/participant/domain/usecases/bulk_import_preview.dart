import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_preview_row.dart';

part 'bulk_import_preview.freezed.dart';

@freezed
class BulkImportPreview with _$BulkImportPreview {
  const factory BulkImportPreview({
    required List<BulkImportPreviewRow> rows,
    required int validCount,
    required int warningCount,
    required int errorCount,
    required int totalRows,
  }) = _BulkImportPreview;

  const BulkImportPreview._();

  bool get hasAnyIssues => warningCount > 0 || errorCount > 0;
  bool get canProceed => validCount > 0 || warningCount > 0;
}
