import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_row_status.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_usecase.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/csv_import_bloc.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/csv_import_event.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/csv_import_state.dart';

class CSVImportPage extends StatelessWidget {
  const CSVImportPage({
    required this.tournamentId, required this.divisionId, super.key,
  });

  final String tournamentId;
  final String divisionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CSVImportBloc(getIt<BulkImportUseCase>()),
      child: _CSVImportView(tournamentId: tournamentId, divisionId: divisionId),
    );
  }
}

class _CSVImportView extends StatelessWidget {
  const _CSVImportView({
    required this.tournamentId,
    required this.divisionId,
  });

  final String tournamentId;
  final String divisionId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CSVImportBloc, CSVImportState>(
      listener: (context, state) {
        if (state is CSVImportFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.userFriendlyMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('CSV Import Wizard'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CSVImportState state) {
    if (state is CSVImportInitial || state is CSVImportFailure) {
      return _buildInputStep(context, state);
    }
    if (state is CSVImportPreviewInProgress) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is CSVImportPreviewSuccess || state is CSVImportImportInProgress) {
      return _buildPreviewStep(context, state);
    }
    if (state is CSVImportImportSuccess) {
      return _buildResultStep(context, state);
    }
    return const SizedBox();
  }

  String _extractCsvContent(CSVImportState state) {
    if (state is CSVImportInitial) {
      return state.csvContent;
    }
    if (state is CSVImportFailure) {
      return state.csvContent;
    }
    if (state is CSVImportPreviewSuccess) {
      return state.csvContent;
    }
    return '';
  }

  Widget _buildInputStep(
    BuildContext context,
    CSVImportState state,
  ) {
    final csvContent = _extractCsvContent(state);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Paste your CSV content below. Required columns: first_name, last_name, school, belt.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                hintText: 'first_name,last_name,school,belt\nJohn,Doe,Academy,red',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => context.read<CSVImportBloc>().add(
                    CSVImportEvent.csvContentChanged(v),
                  ),
              controller: TextEditingController(text: csvContent)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: csvContent.length),
                ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: csvContent.isEmpty
                ? null
                : () => context.read<CSVImportBloc>().add(
                      CSVImportEvent.previewRequested(
                        divisionId: divisionId,
                        tournamentId: tournamentId,
                      ),
                    ),
            child: const Text('Analyze & Preview'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep(BuildContext context, CSVImportState state) {
    if (state is! CSVImportPreviewSuccess && state is! CSVImportImportInProgress) {
      return const SizedBox();
    }

    final preview = (state is CSVImportPreviewSuccess)
        ? state.preview
        : (state as CSVImportImportInProgress).preview;
    final selection = (state is CSVImportPreviewSuccess)
        ? state.selectedRowIndexes
        : (state as CSVImportImportInProgress).selectedRowIndexes;
    final isImporting = state is CSVImportImportInProgress;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _SummaryCard(label: 'Total', value: '${preview.totalRows}', color: Colors.blue),
              _SummaryCard(label: 'Valid', value: '${preview.validCount}', color: Colors.green),
              _SummaryCard(label: 'Warning', value: '${preview.warningCount}', color: Colors.orange),
              _SummaryCard(label: 'Error', value: '${preview.errorCount}', color: Colors.red),
            ],
          ),
        ),
        CheckboxListTile(
          title: const Text('Select All Valid Rows'),
          value: selection.length == (preview.validCount + preview.warningCount),
          onChanged: isImporting
              ? null
              : (v) => context.read<CSVImportBloc>().add(
                    CSVImportEvent.selectAllToggled(selectAll: v ?? false),
                  ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: preview.rows.length,
            itemBuilder: (context, index) {
              final row = preview.rows[index];
              return CheckboxListTile(
                secondary: _RowStatusIcon(status: row.status),
                title: Text('${row.rowData.firstName} ${row.rowData.lastName}'),
                subtitle: Text(row.status == BulkImportRowStatus.error
                    ? row.validationErrors.values.join(', ')
                    : row.rowData.schoolOrDojangName),
                value: selection.contains(index),
                onChanged: isImporting || row.status == BulkImportRowStatus.error
                    ? null
                    : (_) => context.read<CSVImportBloc>().add(
                          CSVImportEvent.rowSelectionToggled(index),
                        ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              TextButton(
                onPressed: isImporting
                    ? null
                    : () => context.read<CSVImportBloc>().add(
                          const CSVImportEvent.resetRequested(),
                        ),
                child: const Text('Back'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: isImporting || selection.isEmpty
                    ? null
                    : () => context.read<CSVImportBloc>().add(
                          CSVImportEvent.importRequested(divisionId: divisionId),
                        ),
                child: isImporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Import ${selection.length} Participants'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultStep(BuildContext context, CSVImportImportSuccess state) {
    final result = state.result;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              'Import Complete!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Successfully imported ${result.successCount} participants.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (result.failureCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${result.failureCount} rows failed.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 40),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Roster'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.05),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              Text(label, style: TextStyle(color: color, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowStatusIcon extends StatelessWidget {
  const _RowStatusIcon({required this.status});
  final BulkImportRowStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case BulkImportRowStatus.valid:
        return const Icon(Icons.check_circle, color: Colors.green);
      case BulkImportRowStatus.warning:
        return const Icon(Icons.warning, color: Colors.orange);
      case BulkImportRowStatus.error:
        return const Icon(Icons.error, color: Colors.red);
    }
  }
}
