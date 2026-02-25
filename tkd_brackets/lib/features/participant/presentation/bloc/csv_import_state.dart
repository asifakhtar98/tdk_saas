import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_preview.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_result.dart';

part 'csv_import_state.freezed.dart';

@freezed
class CSVImportState with _$CSVImportState {
  /// Initial state, awaiting CSV input.
  const factory CSVImportState.initial({
    @Default('') String csvContent,
  }) = CSVImportInitial;

  /// State when parsing CSV and generating preview.
  const factory CSVImportState.previewInProgress({
    required String csvContent,
  }) = CSVImportPreviewInProgress;

  /// State when preview is ready for user selection.
  const factory CSVImportState.previewSuccess({
    required String csvContent,
    required BulkImportPreview preview,
    required Set<int> selectedRowIndexes,
  }) = CSVImportPreviewSuccess;

  /// State when final import is in progress.
  const factory CSVImportState.importInProgress({
    required String csvContent,
    required BulkImportPreview preview,
    required Set<int> selectedRowIndexes,
  }) = CSVImportImportInProgress;

  /// State when import has been completed.
  const factory CSVImportState.importSuccess({
    required BulkImportResult result,
  }) = CSVImportImportSuccess;

  /// State when an error occurred in any step.
  const factory CSVImportState.failure({
    required String userFriendlyMessage,
    String? technicalDetails,
    @Default('') String csvContent,
  }) = CSVImportFailure;
}
