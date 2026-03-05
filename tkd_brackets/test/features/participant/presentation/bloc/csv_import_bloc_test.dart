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
import 'package:tkd_brackets/features/participant/domain/services/clipboard_input_service.dart';

class MockBulkImportUseCase extends Mock implements BulkImportUseCase {}
class MockClipboardInputService extends Mock implements ClipboardInputService {}

void main() {
  late MockBulkImportUseCase mockUseCase;
  late MockClipboardInputService mockClipboardInputService;
  late BulkImportPreview tPreview;
  late BulkImportResult tResult;

  setUp(() {
    mockUseCase = MockBulkImportUseCase();
    mockClipboardInputService = MockClipboardInputService();

    // Default stub for normalization (passthrough)
    when(() => mockClipboardInputService.normalizeToCSV(any()))
        .thenAnswer((inv) => inv.positionalArguments[0] as String);

    const tRow = BulkImportPreviewRow(
      sourceRowNumber: 1,
      rowData: CSVRowData(
        firstName: 'John',
        lastName: 'Doe',
        schoolOrDojangName: 'TDK',
        beltRank: 'red',
        sourceRowNumber: 1,
      ),
      status: BulkImportRowStatus.valid,
      duplicateMatches: [],
      validationErrors: {},
    );

    tPreview = const BulkImportPreview(
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

  setUpAll(() {
    registerFallbackValue('');
  });

  CSVImportBloc buildBloc() => CSVImportBloc(mockUseCase, mockClipboardInputService);

  group('CSVImportBloc', () {
    test('initial state is CSVImportInitial', () {
      expect(buildBloc().state, const CSVImportInitial());
    });

    group('PreviewRequested', () {
      blocTest<CSVImportBloc, CSVImportState>(
        'emits [previewInProgress, previewSuccess] when preview generated successfully',
        seed: () => const CSVImportInitial(csvContent: 'test,csv'),
        build: () {
          when(
            () => mockUseCase.generatePreview(
              csvContent: any(named: 'csvContent'),
              divisionId: any(named: 'divisionId'),
              tournamentId: any(named: 'tournamentId'),
            ),
          ).thenAnswer((_) async => Right(tPreview));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          const CSVImportPreviewRequested(
            divisionId: 'div-123',
            tournamentId: 'tour-123',
          ),
        ),
        expect: () => [
          isA<CSVImportPreviewInProgress>(),
          isA<CSVImportPreviewSuccess>().having(
            (s) => s.preview,
            'preview',
            tPreview,
          ),
        ],
      );

      blocTest<CSVImportBloc, CSVImportState>(
        'normalizes tab-delimited content before generating preview',
        seed: () =>
            const CSVImportInitial(csvContent: 'John\tDoe\tAcademy\tBlack'),
        build: () {
          when(() => mockClipboardInputService.normalizeToCSV(any()))
              .thenReturn('John,Doe,Academy,Black\n');
          when(
            () => mockUseCase.generatePreview(
              csvContent: any(named: 'csvContent'),
              divisionId: any(named: 'divisionId'),
              tournamentId: any(named: 'tournamentId'),
            ),
          ).thenAnswer((_) async => Right(tPreview));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          const CSVImportPreviewRequested(
            divisionId: 'div-123',
            tournamentId: 'tour-123',
          ),
        ),
        verify: (_) {
          verify(() => mockClipboardInputService.normalizeToCSV('John\tDoe\tAcademy\tBlack')).called(1);
          verify(() => mockUseCase.generatePreview(
                csvContent: 'John,Doe,Academy,Black\n',
                divisionId: 'div-123',
                tournamentId: 'tour-123',
              )).called(1);
        },
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
          when(
            () => mockUseCase.importSelected(
              selectedRows: any(named: 'selectedRows'),
              divisionId: any(named: 'divisionId'),
            ),
          ).thenAnswer((_) async => Right(tResult));
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const CSVImportImportRequested(divisionId: 'div-123')),
        expect: () => [
          isA<CSVImportImportInProgress>(),
          CSVImportImportSuccess(result: tResult),
        ],
      );
    });
  });
}
