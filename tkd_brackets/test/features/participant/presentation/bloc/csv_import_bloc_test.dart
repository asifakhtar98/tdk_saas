import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_row_data.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_preview.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_preview_row.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_result.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_row_status.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_usecase.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/csv_import_bloc.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/csv_import_event.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/csv_import_state.dart';

class MockBulkImportUseCase extends Mock implements BulkImportUseCase {}

void main() {
  late MockBulkImportUseCase mockUseCase;
  late BulkImportPreview tPreview;
  late BulkImportResult tResult;

  setUp(() {
    mockUseCase = MockBulkImportUseCase();
    
    final tRow = BulkImportPreviewRow(
      sourceRowNumber: 1,
      rowData: const CSVRowData(
        firstName: 'John',
        lastName: 'Doe',
        schoolOrDojangName: 'TDK',
        beltRank: 'red',
        sourceRowNumber: 1,
      ),
      status: BulkImportRowStatus.valid,
      duplicateMatches: const [],
      validationErrors: const {},
    );

    tPreview = BulkImportPreview(
      rows: [tRow],
      validCount: 1,
      warningCount: 0,
      errorCount: 0,
      totalRows: 1,
    );

    tResult = const BulkImportResult(
      successCount: 1,
      failureCount: 0,
      errorMessages: [],
    );
  });

  CSVImportBloc buildBloc() => CSVImportBloc(mockUseCase);

  group('CSVImportBloc', () {
    test('initial state is CSVImportInitial', () {
      expect(buildBloc().state, const CSVImportInitial());
    });

    group('PreviewRequested', () {
      blocTest<CSVImportBloc, CSVImportState>(
        'emits [previewInProgress, previewSuccess] when preview generated successfully',
        seed: () => const CSVImportInitial(csvContent: 'test,csv'),
        build: () {
          when(() => mockUseCase.generatePreview(
                csvContent: any(named: 'csvContent'),
                divisionId: any(named: 'divisionId'),
                tournamentId: any(named: 'tournamentId'),
              )).thenAnswer((_) async => Right(tPreview));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const CSVImportPreviewRequested(
          divisionId: 'div-123',
          tournamentId: 'tour-123',
        )),
        expect: () => [
          isA<CSVImportPreviewInProgress>(),
          isA<CSVImportPreviewSuccess>().having((s) => s.preview, 'preview', tPreview),
        ],
      );
    });

    group('ImportRequested', () {
      blocTest<CSVImportBloc, CSVImportState>(
        'emits [importInProgress, importSuccess] when import successful',
        seed: () => CSVImportPreviewSuccess(
          csvContent: 'test,csv',
          preview: tPreview,
          selectedRowIndexes: const {0},
        ),
        build: () {
          when(() => mockUseCase.importSelected(
                selectedRows: any(named: 'selectedRows'),
                divisionId: any(named: 'divisionId'),
              )).thenAnswer((_) async => Right(tResult));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const CSVImportImportRequested(
          divisionId: 'div-123',
        )),
        expect: () => [
          isA<CSVImportImportInProgress>(),
          CSVImportImportSuccess(result: tResult),
        ],
      );
    });
  });
}
