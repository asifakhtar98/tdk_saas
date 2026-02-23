import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_parser_service.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_row_data.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_row_error.dart';
import 'package:tkd_brackets/features/participant/domain/services/duplicate_detection_service.dart';
import 'package:tkd_brackets/features/participant/domain/services/duplicate_match.dart';
import 'package:tkd_brackets/features/participant/domain/services/participant_check_data.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_preview.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_preview_row.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_result.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_row_status.dart';
import 'package:uuid/uuid.dart';

@injectable
class BulkImportUseCase {
  BulkImportUseCase(
    this._csvParserService,
    this._duplicateDetectionService,
    this._participantRepository,
  );

  final CSVParserService _csvParserService;
  final DuplicateDetectionService _duplicateDetectionService;
  final ParticipantRepository _participantRepository;

  static const _uuid = Uuid();

  Future<Either<Failure, BulkImportPreview>> generatePreview({
    required String csvContent,
    required String divisionId,
    required String tournamentId,
  }) async {
    final parseResult = await _csvParserService.parseCSV(
      csvContent: csvContent,
      divisionId: divisionId,
    );

    return parseResult.fold(Left.new, (csvResult) async {
      final errorsByRow = <int, List<CSVRowError>>{};
      for (final error in csvResult.errors) {
        errorsByRow.putIfAbsent(error.rowNumber, () => []).add(error);
      }

      final previewRows = <BulkImportPreviewRow>[];
      for (final entry in errorsByRow.entries) {
        final rowNumber = entry.key;
        final errors = entry.value;

        final validationErrors = <String, String>{};
        for (final error in errors) {
          validationErrors[error.fieldName] = error.errorMessage;
        }

        final placeholderRowData = CSVRowData(
          firstName: '',
          lastName: '',
          schoolOrDojangName: '',
          beltRank: '',
          sourceRowNumber: rowNumber,
        );

        previewRows.add(
          BulkImportPreviewRow(
            sourceRowNumber: rowNumber,
            rowData: placeholderRowData,
            status: BulkImportRowStatus.error,
            duplicateMatches: [],
            validationErrors: validationErrors,
          ),
        );
      }

      final validRows = csvResult.validRows;
      if (validRows.isNotEmpty) {
        final checkDataList = validRows
            .map(ParticipantCheckData.fromCSVRowData)
            .toList();
        final sourceRowNumbers = validRows
            .map((row) => row.sourceRowNumber)
            .toList();

        final duplicatesResult = await _duplicateDetectionService
            .checkForDuplicatesBatch(
              tournamentId: tournamentId,
              newParticipants: checkDataList,
              sourceRowNumbers: sourceRowNumbers,
            );

        final duplicatesByRow = duplicatesResult.fold(
          (_) => <int, List<DuplicateMatch>>{},
          (map) => map,
        );

        for (final row in validRows) {
          final duplicates = duplicatesByRow[row.sourceRowNumber] ?? [];
          final status = _determineStatus(
            hasValidationErrors: false,
            duplicates: duplicates,
          );

          previewRows.add(
            BulkImportPreviewRow(
              sourceRowNumber: row.sourceRowNumber,
              rowData: row,
              status: status,
              duplicateMatches: duplicates,
              validationErrors: {},
            ),
          );
        }
      }

      previewRows.sort(
        (a, b) => a.sourceRowNumber.compareTo(b.sourceRowNumber),
      );

      final validCount = previewRows
          .where((r) => r.status == BulkImportRowStatus.valid)
          .length;
      final warningCount = previewRows
          .where((r) => r.status == BulkImportRowStatus.warning)
          .length;
      final errorCount = previewRows
          .where((r) => r.status == BulkImportRowStatus.error)
          .length;

      return Right(
        BulkImportPreview(
          rows: previewRows,
          validCount: validCount,
          warningCount: warningCount,
          errorCount: errorCount,
          totalRows: previewRows.length,
        ),
      );
    });
  }

  Future<Either<Failure, BulkImportResult>> importSelected({
    required List<BulkImportPreviewRow> selectedRows,
    required String divisionId,
  }) async {
    if (selectedRows.isEmpty) {
      return const Right(
        BulkImportResult(successCount: 0, failureCount: 0, errorMessages: []),
      );
    }

    final participants = <ParticipantEntity>[];
    final errorMessages = <String>[];

    for (final row in selectedRows) {
      if (row.status == BulkImportRowStatus.error) {
        final fields = row.validationErrors.keys.join(', ');
        errorMessages.add(
          'Row ${row.sourceRowNumber}: cannot import - invalid fields: $fields',
        );
        continue;
      }

      final params = row.rowData.toCreateParticipantParams(divisionId);
      final participant = ParticipantEntity(
        id: _uuid.v4(),
        divisionId: params.divisionId,
        firstName: params.firstName,
        lastName: params.lastName,
        schoolOrDojangName: params.schoolOrDojangName,
        beltRank: params.beltRank,
        dateOfBirth: params.dateOfBirth,
        gender: params.gender,
        weightKg: params.weightKg,
        registrationNumber: params.registrationNumber,
        notes: params.notes,
        checkInStatus: ParticipantStatus.pending,
        createdAtTimestamp: DateTime.now(),
        updatedAtTimestamp: DateTime.now(),
        syncVersion: 1,
        isDeleted: false,
      );
      participants.add(participant);
    }

    if (participants.isEmpty) {
      return Right(
        BulkImportResult(
          successCount: 0,
          failureCount: errorMessages.length,
          errorMessages: errorMessages,
        ),
      );
    }

    final result = await _participantRepository.createParticipantsBatch(
      participants,
    );

    return result.fold(
      Left.new,
      (created) => Right(
        BulkImportResult(
          successCount: created.length,
          failureCount: errorMessages.length,
          errorMessages: errorMessages,
        ),
      ),
    );
  }

  BulkImportRowStatus _determineStatus({
    required bool hasValidationErrors,
    required List<DuplicateMatch> duplicates,
  }) {
    if (hasValidationErrors) return BulkImportRowStatus.error;
    if (duplicates.isNotEmpty) return BulkImportRowStatus.warning;
    return BulkImportRowStatus.valid;
  }
}
