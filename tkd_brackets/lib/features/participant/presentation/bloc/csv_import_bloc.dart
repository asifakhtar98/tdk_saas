import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_row_status.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_usecase.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/csv_import_event.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/csv_import_state.dart';

@injectable
class CSVImportBloc extends Bloc<CSVImportEvent, CSVImportState> {
  CSVImportBloc(this._bulkImportUseCase) : super(const CSVImportInitial()) {
    on<CSVImportContentChanged>(_onContentChanged);
    on<CSVImportPreviewRequested>(_onPreviewRequested);
    on<CSVImportRowSelectionToggled>(_onRowSelectionToggled);
    on<CSVImportSelectAllToggled>(_onSelectAllToggled);
    on<CSVImportImportRequested>(_onImportRequested);
    on<CSVImportResetRequested>(_onResetRequested);
  }

  final BulkImportUseCase _bulkImportUseCase;

  void _onContentChanged(
    CSVImportContentChanged event,
    Emitter<CSVImportState> emit,
  ) {
    if (state is CSVImportInitial) {
      emit((state as CSVImportInitial).copyWith(csvContent: event.content));
    } else if (state is CSVImportFailure) {
      emit((state as CSVImportFailure).copyWith(csvContent: event.content));
    }
  }

  Future<void> _onPreviewRequested(
    CSVImportPreviewRequested event,
    Emitter<CSVImportState> emit,
  ) async {
    final csvContent = _getCurrentCsvContent();
    if (csvContent.isEmpty) return;

    emit(CSVImportPreviewInProgress(csvContent: csvContent));

    final result = await _bulkImportUseCase.generatePreview(
      csvContent: csvContent,
      divisionId: event.divisionId,
      tournamentId: event.tournamentId,
    );

    result.fold(
      (failure) => emit(
        CSVImportFailure(
          userFriendlyMessage: failure.userFriendlyMessage,
          technicalDetails: failure.technicalDetails,
          csvContent: csvContent,
        ),
      ),
      (preview) {
        // By default, select all valid and warning rows
        final selectedIndexes = <int>{};
        for (var i = 0; i < preview.rows.length; i++) {
          if (preview.rows[i].status != BulkImportRowStatus.error) {
            selectedIndexes.add(i);
          }
        }

        emit(
          CSVImportPreviewSuccess(
            csvContent: csvContent,
            preview: preview,
            selectedRowIndexes: selectedIndexes,
          ),
        );
      },
    );
  }

  void _onRowSelectionToggled(
    CSVImportRowSelectionToggled event,
    Emitter<CSVImportState> emit,
  ) {
    final currentState = state;
    if (currentState is! CSVImportPreviewSuccess) return;

    final newSelection = Set<int>.from(currentState.selectedRowIndexes);
    if (newSelection.contains(event.rowIndex)) {
      newSelection.remove(event.rowIndex);
    } else {
      // Don't allow selecting rows with errors
      if (currentState.preview.rows[event.rowIndex].status !=
          BulkImportRowStatus.error) {
        newSelection.add(event.rowIndex);
      }
    }

    emit(currentState.copyWith(selectedRowIndexes: newSelection));
  }

  void _onSelectAllToggled(
    CSVImportSelectAllToggled event,
    Emitter<CSVImportState> emit,
  ) {
    final currentState = state;
    if (currentState is! CSVImportPreviewSuccess) return;

    final newSelection = <int>{};
    if (event.selectAll) {
      for (var i = 0; i < currentState.preview.rows.length; i++) {
        if (currentState.preview.rows[i].status != BulkImportRowStatus.error) {
          newSelection.add(i);
        }
      }
    }

    emit(currentState.copyWith(selectedRowIndexes: newSelection));
  }

  Future<void> _onImportRequested(
    CSVImportImportRequested event,
    Emitter<CSVImportState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CSVImportPreviewSuccess) return;

    if (currentState.selectedRowIndexes.isEmpty) return;

    emit(
      CSVImportImportInProgress(
        csvContent: currentState.csvContent,
        preview: currentState.preview,
        selectedRowIndexes: currentState.selectedRowIndexes,
      ),
    );

    final selectedRows = currentState.selectedRowIndexes
        .map((idx) => currentState.preview.rows[idx])
        .toList();

    final result = await _bulkImportUseCase.importSelected(
      selectedRows: selectedRows,
      divisionId: event.divisionId,
    );

    result.fold(
      (failure) => emit(
        CSVImportFailure(
          userFriendlyMessage: failure.userFriendlyMessage,
          technicalDetails: failure.technicalDetails,
          csvContent: currentState.csvContent,
        ),
      ),
      (importResult) => emit(CSVImportImportSuccess(result: importResult)),
    );
  }

  void _onResetRequested(
    CSVImportResetRequested event,
    Emitter<CSVImportState> emit,
  ) {
    emit(const CSVImportInitial());
  }

  String _getCurrentCsvContent() {
    final currentState = state;
    if (currentState is CSVImportInitial) return currentState.csvContent;
    if (currentState is CSVImportFailure) return currentState.csvContent;
    if (currentState is CSVImportPreviewSuccess) return currentState.csvContent;
    return '';
  }
}
