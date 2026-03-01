import 'package:freezed_annotation/freezed_annotation.dart';

part 'csv_import_event.freezed.dart';

@freezed
class CSVImportEvent with _$CSVImportEvent {
  /// Request to update the CSV content.
  const factory CSVImportEvent.csvContentChanged(String content) =
      CSVImportContentChanged;

  /// Request to generate a preview of the CSV.
  const factory CSVImportEvent.previewRequested({
    required String divisionId,
    required String tournamentId,
  }) = CSVImportPreviewRequested;

  /// Request to toggle selection of a row in the preview.
  const factory CSVImportEvent.rowSelectionToggled(int rowIndex) =
      CSVImportRowSelectionToggled;

  /// Request to toggle selection of all rows in the preview.
  const factory CSVImportEvent.selectAllToggled({required bool selectAll}) =
      CSVImportSelectAllToggled;

  /// Request to perform the actual import.
  const factory CSVImportEvent.importRequested({required String divisionId}) =
      CSVImportImportRequested;

  /// Request to reset the import flow.
  const factory CSVImportEvent.resetRequested() = CSVImportResetRequested;
}
