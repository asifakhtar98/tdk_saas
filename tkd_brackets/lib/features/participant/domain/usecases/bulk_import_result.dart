import 'package:freezed_annotation/freezed_annotation.dart';

part 'bulk_import_result.freezed.dart';

@freezed
class BulkImportResult with _$BulkImportResult {
  const factory BulkImportResult({
    required int successCount,
    required int failureCount,
    required List<String> errorMessages,
  }) = _BulkImportResult;
}
