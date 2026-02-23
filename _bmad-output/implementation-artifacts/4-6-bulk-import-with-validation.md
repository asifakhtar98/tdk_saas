# Story 4.6: Bulk Import with Validation

Status: done

**Created:** 2026-02-22

**Epic:** 4 - Participant Management

**FRs Covered:** FR14 (CSV import with validation), FR15 (duplicate detection preview)

**Dependencies:** Story 4.5 (Duplicate Detection) - COMPLETE | Story 4.4 (CSV Import Parser) - COMPLETE | Story 4.3 (Manual Participant Entry) - COMPLETE | Story 4.2 (Participant Entity & Repository) - COMPLETE | Story 4.1 (Participant Feature Structure) - COMPLETE | Epic 3 (Tournament & Division) - COMPLETE | Epic 2 (Auth) - COMPLETE | Epic 1 (Foundation) - COMPLETE

---

## TL;DR — Critical Facts

**CURRENT STATE:**
- ✅ `lib/features/participant/domain/entities/participant_entity.dart` — ParticipantEntity exists
- ✅ `lib/features/participant/domain/usecases/create_participant_usecase.dart` — CreateParticipantUseCase with validation patterns
- ✅ `lib/features/participant/domain/services/csv_parser_service.dart` — CSVParserService parses CSV into CSVImportResult
- ✅ `lib/features/participant/domain/services/csv_row_data.dart` — CSVRowData with `toCreateParticipantParams()` method
- ✅ `lib/features/participant/domain/services/csv_import_result.dart` — CSVImportResult with `validRows`, `errors`, `totalRows`
- ✅ `lib/features/participant/domain/services/csv_row_error.dart` — CSVRowError with `rowNumber`, `fieldName`, `errorMessage`, `rawValue`
- ✅ `lib/features/participant/domain/services/duplicate_detection_service.dart` — DuplicateDetectionService with `checkForDuplicatesBatch()`
- ✅ `lib/features/participant/domain/services/duplicate_match.dart` — DuplicateMatch with `existingParticipant`, `matchType`, `confidenceScore`, `matchedFields`
- ✅ `lib/features/participant/domain/services/participant_check_data.dart` — ParticipantCheckData with `fromCSVRowData()` factory
- ✅ `lib/features/participant/domain/repositories/participant_repository.dart` — ParticipantRepository (no batch method)
- ✅ `lib/features/participant/data/datasources/participant_local_datasource.dart` — ParticipantLocalDatasource (no batch method)
- ✅ `lib/core/error/failures.dart` — Failure types exist
- ❌ `BulkImportPreview` — **DOES NOT EXIST** — Create in this story
- ❌ `BulkImportPreviewRow` — **DOES NOT EXIST** — Create in this story
- ❌ `BulkImportRowStatus` enum — **DOES NOT EXIST** — Create in this story
- ❌ `BulkImportUseCase` — **DOES NOT EXIST** — Create in this story
- ❌ `BulkImportResult` — **DOES NOT EXIST** — Create in this story
- ❌ Batch insert method in `ParticipantRepository` — **ADD** to this story
- ❌ Batch insert method in `ParticipantLocalDatasource` — **ADD** to this story

**TARGET STATE:** Create `BulkImportUseCase` that orchestrates CSV parsing, duplicate detection, and produces a preview with color-coded rows (valid/warning/error). User can select rows to import, then batch-insert selected participants.

**FILES TO CREATE:**
| File | Type | Description |
|------|------|-------------|
| `bulk_import_row_status.dart` | Enum | `valid`, `warning`, `error` |
| `bulk_import_preview_row.dart` | Freezed class | Single row with status, data, duplicates, errors |
| `bulk_import_preview.dart` | Freezed class | Full preview with all rows and summary counts |
| `bulk_import_result.dart` | Freezed class | Import result with success/failure counts |
| `bulk_import_usecase.dart` | Use case | Orchestrates parsing + duplicate check, then batch insert |

**FILES TO MODIFY:**
| File | Change |
|------|--------|
| `participant_repository.dart` | Add `createParticipantsBatch()` method |
| `participant_repository_implementation.dart` | Implement batch insert |
| `participant_local_datasource.dart` | Add batch insert method |
| `usecases.dart` | Export new use case and data classes |

**KEY PREVIOUS STORY LESSONS — APPLY ALL:**
1. Use `@injectable` for use cases (not `@lazySingleton`)
2. Inject existing services — don't re-implement logic
3. Use `checkForDuplicatesBatch()` for efficient batch duplicate checking
4. Generate UUIDs for new participants in use case
5. Run `build_runner build --delete-conflicting-outputs` after ANY generated file changes
6. Keep domain layer pure — no Drift, Supabase, or Flutter dependencies

---

## Story

**As an** organizer,
**I want** to import a CSV and see validation results before committing,
**So that** I can fix errors before registration (FR14, FR15).

---

## Acceptance Criteria

- [x] **AC1:** `BulkImportRowStatus` enum created with values: `valid`, `warning`, `error`

- [x] **AC2:** `BulkImportPreviewRow` freezed class created:
  ```dart
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
  ```
  
  **⚠️ CRITICAL: `rowData` for error rows:**
  - For rows with parsing errors, `rowData` contains the partially-parsed CSVRowData from CSVParserService
  - CSVParserService only creates CSVRowData for valid rows, so error rows will have empty placeholder CSVRowData
  - The `sourceRowNumber` tracks the original CSV row position
  - `validationErrors` is populated by aggregating `CSVRowError` objects (see AC5 error handling)

- [x] **AC3:** `BulkImportPreview` freezed class created:
  ```dart
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
  ```

- [x] **AC4:** `BulkImportUseCase` created with `@injectable`:
  - Method: `Future<Either<Failure, BulkImportPreview>> generatePreview({required String csvContent, required String divisionId, required String tournamentId})`
  - Method: `Future<Either<Failure, BulkImportResult>> importSelected({required List<BulkImportPreviewRow> selectedRows})`

- [x] **AC5:** Preview generation flow:
  1. Call `CSVParserService.parseCSV()` to get `CSVImportResult`
  2. If parsing has errors, map them to `BulkImportPreviewRow` with `status = error`:
     - **⚠️ CRITICAL:** `CSVImportResult.errors` contains `List<CSVRowError>` (individual errors)
     - **Each `CSVRowError` has:** `rowNumber` (NOT `sourceRowNumber`), `fieldName`, `errorMessage`, `rawValue`
     - **Must aggregate errors by row number:**
       ```dart
       // Group CSVRowError objects by rowNumber
       final errorsByRow = <int, List<CSVRowError>>{};
       for (final error in csvResult.errors) {
         errorsByRow.putIfAbsent(error.rowNumber, () => []).add(error);
       }
       
       // Convert to Map<String, String> for each row
       for (final entry in errorsByRow.entries) {
         final validationErrors = <String, String>{};
         for (final error in entry.value) {
           validationErrors[error.fieldName] = error.errorMessage;
         }
         // Create BulkImportPreviewRow with these validationErrors
       }
       ```
     - **Error row CSVRowData:** Create empty placeholder with just `sourceRowNumber`:
       ```dart
       CSVRowData(
         firstName: '',
         lastName: '',
         schoolOrDojangName: '',
         beltRank: '',
         sourceRowNumber: errorRowNumber,
       )
       ```
  3. For valid rows, call `DuplicateDetectionService.checkForDuplicatesBatch()`:
     - **⚠️ CRITICAL:** Use `ParticipantCheckData.fromCSVRowData()` to convert:
       ```dart
       final checkDataList = csvResult.validRows
           .map((row) => ParticipantCheckData.fromCSVRowData(row))
           .toList();
       final sourceRowNumbers = csvResult.validRows
           .map((row) => row.sourceRowNumber)
           .toList();
       ```
     - Pass `sourceRowNumbers` to batch method for proper row tracking
  4. Map each row to `BulkImportPreviewRow` with appropriate status:
     - `error` — Has validation errors from parser (row in errorsByRow map)
     - `warning` — Has duplicate matches (any confidence)
     - `valid` — No errors and no duplicates

- [x] **AC6:** Status determination logic:
  ```dart
  BulkImportRowStatus _determineStatus({
    required bool hasValidationErrors,
    required List<DuplicateMatch> duplicates,
  }) {
    if (hasValidationErrors) return BulkImportRowStatus.error;
    if (duplicates.isNotEmpty) return BulkImportRowStatus.warning;
    return BulkImportRowStatus.valid;
  }
  ```

- [x] **AC7:** Import flow for selected rows:
  1. **Skip rows with `error` status** (cannot import invalid data)
  2. Convert `BulkImportPreviewRow.rowData` → `ParticipantEntity`:
     ```dart
     final params = row.rowData.toCreateParticipantParams(divisionId);
     final participant = ParticipantEntity(
       id: _uuid.v4(),  // Generate new UUID
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
     ```
  3. Call `ParticipantRepository.createParticipantsBatch()` for all valid entities
  4. Return `BulkImportResult` with counts and any error messages

- [x] **AC8:** Batch insert method added to `ParticipantRepository` interface:
  ```dart
  /// Batch create multiple participants in a single transaction.
  /// More efficient than individual inserts for bulk operations.
  /// Returns created participants on success.
  Future<Either<Failure, List<ParticipantEntity>>> createParticipantsBatch(
    List<ParticipantEntity> participants,
  );
  ```
  
  **And to `ParticipantLocalDatasource` interface:**
  ```dart
  /// Batch insert participants using Drift batch operation.
  Future<List<ParticipantModel>> insertParticipantsBatch(
    List<ParticipantModel> participants,
  );
  ```
  
  **⚠️ CRITICAL: Drift Batch Insert Implementation:**
  ```dart
  // In ParticipantLocalDatasourceImplementation
  @override
  Future<List<ParticipantModel>> insertParticipantsBatch(
    List<ParticipantModel> participants,
  ) async {
    final companions = participants.map((p) => p.toDriftCompanion()).toList();
    // Drift batch insert using transaction
    await _database.batch((batch) {
      batch.insertAll(_database.participants, companions);
    });
    // Return the models (they now have IDs from the insert)
    return participants;
  }
  ```

- [x] **AC9:** `BulkImportResult` freezed class created:
  ```dart
  @freezed
  class BulkImportResult with _$BulkImportResult {
    const factory BulkImportResult({
      required int successCount,
      required int failureCount,
      required List<String> errorMessages,
    }) = _BulkImportResult;
  }
  ```

- [x] **AC10:** Error handling:
  - **CSV parsing failure** → return `Left(ValidationFailure)` from CSVParserService
  - **Duplicate detection failure** → gracefully degrade (empty matches list), don't fail preview
  - **Batch insert failure** → return `Left(LocalCacheWriteFailure)`
  - **Empty selection** → return `Right(BulkImportResult(successCount: 0, failureCount: 0, errorMessages: []))`
  - **All selected rows are errors** → return success with 0 imported, errorMessages populated

- [x] **AC11:** Unit tests verify:
  - Preview generation with valid rows only → all `valid` status
  - Preview generation with parsing errors → rows have `error` status with correct validationErrors map
  - Preview generation with duplicate warnings → rows have `warning` status
  - Mixed preview (some valid, some warnings, some errors)
  - Preview counts are accurate (validCount, warningCount, errorCount, totalRows)
  - Preview rows are sorted by sourceRowNumber ascending
  - Import selected rows with all valid → success with correct count
  - Import with empty selection → returns zero-count result
  - Import with error rows only → skips all, returns errorMessages
  - Import with mix of valid and error rows → skips errors, imports valid
  - Duplicate detection failure during preview → graceful degradation (no warnings shown)
  - Batch insert failure → returns LocalCacheWriteFailure

- [x] **AC12:** `flutter analyze` passes with zero new errors

- [x] **AC13:** Existing infrastructure UNTOUCHED except documented additions:
  - `ParticipantRepository` — ADD method only
  - `ParticipantLocalDatasource` — ADD method only
  - `ParticipantLocalDatasourceImplementation` — ADD method implementation
  - `ParticipantRepositoryImplementation` — ADD method implementation
  - All other files unchanged

---

## Tasks / Subtasks

### Task 1: Create Data Classes (AC: #1, #2, #3, #9)

- [x] 1.1: Create `lib/features/participant/domain/usecases/bulk_import_row_status.dart` with enum
- [x] 1.2: Create `lib/features/participant/domain/usecases/bulk_import_preview_row.dart` with freezed class
- [x] 1.3: Create `lib/features/participant/domain/usecases/bulk_import_preview.dart` with freezed class
- [x] 1.4: Create `lib/features/participant/domain/usecases/bulk_import_result.dart` with freezed class

### Task 2: Add Batch Insert to Repository (AC: #8)

- [x] 2.1: Add `createParticipantsBatch()` to `ParticipantRepository` interface
- [x] 2.2: Add `insertParticipantsBatch()` to `ParticipantLocalDatasource`
- [x] 2.3: Implement `createParticipantsBatch()` in `ParticipantRepositoryImplementation`
- [x] 2.4: Update any barrel files if needed

### Task 3: Create BulkImportUseCase (AC: #4, #5, #6, #7, #10)

- [x] 3.1: Create `lib/features/participant/domain/usecases/bulk_import_usecase.dart`
- [x] 3.2: Inject `CSVParserService`, `DuplicateDetectionService`, `ParticipantRepository`
- [x] 3.3: Implement `generatePreview()` method:
  - Parse CSV content via `CSVParserService.parseCSV()`
  - **Aggregate `CSVImportResult.errors` by `rowNumber`:**
    ```dart
    final errorsByRow = <int, List<CSVRowError>>{};
    for (final error in csvResult.errors) {
      errorsByRow.putIfAbsent(error.rowNumber, () => []).add(error);
    }
    ```
  - Create error preview rows from aggregated errors
  - For valid rows, convert to `ParticipantCheckData` using `fromCSVRowData()`
  - Call `checkForDuplicatesBatch()` with `sourceRowNumbers` parameter
  - Map valid rows to preview rows with duplicate status
  - Sort all preview rows by `sourceRowNumber`
  - Calculate counts and return `BulkImportPreview`
- [x] 3.4: Implement `importSelected()` method:
  - Filter out rows with `error` status
  - Convert each valid row to `ParticipantEntity` (generate UUID, set defaults)
  - Call `createParticipantsBatch()` on repository
  - Return `BulkImportResult` with success/failure counts

### Task 4: Add Batch Insert Methods (AC: #8)

- [x] 4.1: Add `createParticipantsBatch()` to `ParticipantRepository` interface
- [x] 4.2: Add `insertParticipantsBatch()` to `ParticipantLocalDatasource` interface
- [x] 4.3: Implement `insertParticipantsBatch()` in `ParticipantLocalDatasourceImplementation`:
  - Use `_database.batch()` with `batch.insertAll()`
  - Convert models to companions via `toDriftCompanion()`
- [x] 4.4: Implement `createParticipantsBatch()` in `ParticipantRepositoryImplementation`:
  - Convert entities to models via `ParticipantModel.convertFromEntity()`
  - Call local datasource batch insert
  - Attempt remote sync (non-blocking)
  - Convert models back to entities for return

### Task 5: Update Barrel Files (AC: #13)

- [x] 5.1: Update `lib/features/participant/domain/usecases/usecases.dart` with new exports:
  - Export `bulk_import_row_status.dart`
  - Export `bulk_import_preview_row.dart`
  - Export `bulk_import_preview.dart`
  - Export `bulk_import_result.dart`
  - Export `bulk_import_usecase.dart`

### Task 6: Run Code Generation (AC: #12)

- [x] 6.1: Run `dart run build_runner build --delete-conflicting-outputs` from `tkd_brackets/`
- [x] 6.2: Verify generated files:
  - `bulk_import_preview_row.freezed.dart`
  - `bulk_import_preview.freezed.dart`
  - `bulk_import_result.freezed.dart`

### Task 7: Create Unit Tests (AC: #11)

- [x] 7.1: Create `test/features/participant/domain/usecases/bulk_import_usecase_test.dart`
- [x] 7.2: Test preview generation with all valid rows
- [x] 7.3: Test preview generation with parsing errors
- [x] 7.4: Test preview generation with duplicate warnings
- [x] 7.5: Test mixed preview (valid + warnings + errors)
- [x] 7.6: Test preview counts accuracy
- [x] 7.7: Test preview rows sorted by sourceRowNumber
- [x] 7.8: Test import selected with all valid → success
- [x] 7.9: Test import with empty selection
- [x] 7.10: Test import with error rows (should skip)
- [x] 7.11: Test duplicate detection graceful degradation
- [x] 7.12: Test batch insert in repository

### Task 8: Verify Project Integrity (AC: #12, #13)

- [x] 8.1: Run `flutter analyze` from `tkd_brackets/` — zero new issues
- [x] 8.2: Run `dart run build_runner build --delete-conflicting-outputs` — succeeds
- [x] 8.3: Run all participant tests: `flutter test test/features/participant/` — all pass
- [x] 8.4: Verify existing files only have ADDITIVE changes (no modifications to existing methods)

---

## Dev Notes

### Architecture Patterns — MANDATORY

**Use Case Pattern:**
- Use `@injectable` annotation (not `@lazySingleton` — use cases follow use case pattern)
- Inject services and repositories via constructor
- Return `Either<Failure, T>` pattern
- No Drift, Supabase, or Flutter dependencies in domain layer

**Key Service Dependencies:**
| Service | Purpose | Method Used |
|---------|---------|-------------|
| `CSVParserService` | Parse CSV to structured data | `parseCSV()` |
| `DuplicateDetectionService` | Check for duplicates | `checkForDuplicatesBatch()` |
| `ParticipantRepository` | Persist participants | `createParticipantsBatch()` |

**Existing Patterns to Follow:**
- From Story 4.3: `CreateParticipantUseCase` validation patterns, UUID generation
- From Story 4.4: `CSVParserService` error collection pattern, `CSVRowData.toCreateParticipantParams()`
- From Story 4.5: `DuplicateDetectionService.checkForDuplicatesBatch()` returns `Map<int, List<DuplicateMatch>>`

---

### File Structure After This Story

```
lib/features/participant/
├── participant.dart
├── domain/
│   ├── entities/
│   ├── repositories/
│   │   └── participant_repository.dart         ← MODIFIED (add batch method)
│   ├── services/
│   │   ├── services.dart
│   │   ├── csv_parser_service.dart             ← USE
│   │   ├── duplicate_detection_service.dart    ← USE
│   │   └── ...
│   └── usecases/
│       ├── usecases.dart                        ← MODIFIED (add exports)
│       ├── create_participant_usecase.dart      ← PATTERN REFERENCE
│       ├── create_participant_params.dart
│       ├── bulk_import_usecase.dart             ← NEW
│       ├── bulk_import_row_status.dart          ← NEW
│       ├── bulk_import_preview_row.dart         ← NEW
│       ├── bulk_import_preview_row.freezed.dart ← GENERATED
│       ├── bulk_import_preview.dart             ← NEW
│       ├── bulk_import_preview.freezed.dart     ← GENERATED
│       ├── bulk_import_result.dart              ← NEW
│       └── bulk_import_result.freezed.dart      ← GENERATED
├── data/
│   ├── datasources/
│   │   ├── participant_local_datasource.dart    ← MODIFIED (add batch method)
│   │   └── participant_remote_datasource.dart
│   └── repositories/
│       └── participant_repository_implementation.dart  ← MODIFIED
└── presentation/                                ← Empty (Story 4.12)
```

---

### Implementation Reference

**BulkImportUseCase Structure:**

```dart
// lib/features/participant/domain/usecases/bulk_import_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_parser_service.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_import_result.dart';
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

  /// Generates a preview of CSV import with validation and duplicate detection.
  /// 
  /// Returns [BulkImportPreview] with all rows, their status, and summary counts.
  /// Does NOT persist any data - only analyzes the CSV content.
  Future<Either<Failure, BulkImportPreview>> generatePreview({
    required String csvContent,
    required String divisionId,
    required String tournamentId,
  }) async {
    // Step 1: Parse CSV content
    final parseResult = await _csvParserService.parseCSV(
      csvContent: csvContent,
      divisionId: divisionId,
    );

    return parseResult.fold(
      (failure) => Left(failure),
      (csvResult) async {
        // Step 2: Aggregate errors by row number
        // CSVRowError.rowNumber maps to CSVRowData.sourceRowNumber
        final errorsByRow = <int, List<CSVRowError>>{};
        for (final error in csvResult.errors) {
          errorsByRow.putIfAbsent(error.rowNumber, () => []).add(error);
        }

        // Step 3: Create preview rows for error rows
        final previewRows = <BulkImportPreviewRow>[];
        for (final entry in errorsByRow.entries) {
          final rowNumber = entry.key;
          final errors = entry.value;
          
          // Convert List<CSVRowError> to Map<String, String>
          final validationErrors = <String, String>{};
          for (final error in errors) {
            validationErrors[error.fieldName] = error.errorMessage;
          }
          
          // Create placeholder CSVRowData for error row
          // (CSVParserService only creates CSVRowData for valid rows)
          final placeholderRowData = CSVRowData(
            firstName: '',
            lastName: '',
            schoolOrDojangName: '',
            beltRank: '',
            sourceRowNumber: rowNumber,
          );
          
          previewRows.add(BulkImportPreviewRow(
            sourceRowNumber: rowNumber,
            rowData: placeholderRowData,
            status: BulkImportRowStatus.error,
            duplicateMatches: [],
            validationErrors: validationErrors,
          ));
        }

        // Step 4: Prepare valid rows for duplicate check
        final validRows = csvResult.validRows;
        if (validRows.isNotEmpty) {
          final checkDataList = validRows
              .map((row) => ParticipantCheckData.fromCSVRowData(row))
              .toList();
          final sourceRowNumbers = validRows
              .map((row) => row.sourceRowNumber)
              .toList();

          // Step 5: Batch duplicate check
          final duplicatesResult = await _duplicateDetectionService
              .checkForDuplicatesBatch(
            tournamentId: tournamentId,
            newParticipants: checkDataList,
            sourceRowNumbers: sourceRowNumbers,
          );

          // Step 6: Process duplicate results (graceful degradation on failure)
          final duplicatesByRow = duplicatesResult.fold(
            (failure) => <int, List<DuplicateMatch>>{},  // Empty on failure
            (map) => map,
          );

          // Step 7: Create preview rows for valid rows
          for (final row in validRows) {
            final duplicates = duplicatesByRow[row.sourceRowNumber] ?? [];
            final status = _determineStatus(
              hasValidationErrors: false,
              duplicates: duplicates,
            );

            previewRows.add(BulkImportPreviewRow(
              sourceRowNumber: row.sourceRowNumber,
              rowData: row,
              status: status,
              duplicateMatches: duplicates,
              validationErrors: {},
            ));
          }
        }

        // Step 8: Sort by source row number
        previewRows.sort((a, b) => a.sourceRowNumber.compareTo(b.sourceRowNumber));

        // Step 9: Calculate counts
        final validCount = previewRows
            .where((r) => r.status == BulkImportRowStatus.valid)
            .length;
        final warningCount = previewRows
            .where((r) => r.status == BulkImportRowStatus.warning)
            .length;
        final errorCount = previewRows
            .where((r) => r.status == BulkImportRowStatus.error)
            .length;

        return Right(BulkImportPreview(
          rows: previewRows,
          validCount: validCount,
          warningCount: warningCount,
          errorCount: errorCount,
          totalRows: previewRows.length,
        ));
      },
    );
  }

  /// Imports selected rows, skipping those with error status.
  /// 
  /// Returns [BulkImportResult] with success and failure counts.
  /// Rows with [BulkImportRowStatus.error] are always skipped.
  Future<Either<Failure, BulkImportResult>> importSelected({
    required List<BulkImportPreviewRow> selectedRows,
    required String divisionId,
  }) async {
    if (selectedRows.isEmpty) {
      return const Right(BulkImportResult(
        successCount: 0,
        failureCount: 0,
        errorMessages: [],
      ));
    }

    final participants = <ParticipantEntity>[];
    final errorMessages = <String>[];

    for (final row in selectedRows) {
      // Skip error rows - they cannot be imported
      if (row.status == BulkImportRowStatus.error) {
        errorMessages.add(
          'Row ${row.sourceRowNumber}: Cannot import row with validation errors',
        );
        continue;
      }

      // Convert to ParticipantEntity with new UUID
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
      return Right(BulkImportResult(
        successCount: 0,
        failureCount: errorMessages.length,
        errorMessages: errorMessages,
      ));
    }

    final result = await _participantRepository.createParticipantsBatch(participants);

    return result.fold(
      (failure) => Left(failure),
      (created) => Right(BulkImportResult(
        successCount: created.length,
        failureCount: errorMessages.length,
        errorMessages: errorMessages,
      )),
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
```

---

### Batch Insert Implementation Reference

**⚠️ CRITICAL: Drift Batch Insert Pattern**

Drift uses `batch()` with `insertAll()` for batch operations. The table reference must be accessed correctly.

**ParticipantLocalDatasource interface addition:**

```dart
// lib/features/participant/data/datasources/participant_local_datasource.dart

/// Batch insert participants using Drift batch operation.
/// More efficient than individual inserts for bulk operations.
Future<List<ParticipantModel>> insertParticipantsBatch(
  List<ParticipantModel> participants,
);
```

**ParticipantLocalDatasourceImplementation addition:**

```dart
// In ParticipantLocalDatasourceImplementation

@override
Future<List<ParticipantModel>> insertParticipantsBatch(
  List<ParticipantModel> participants,
) async {
  // Convert models to Drift companions
  final companions = participants
      .map((p) => p.toDriftCompanion())
      .toList();
  
  // Use Drift batch insert
  await _database.batch((batch) {
    batch.insertAll(_database.participants, companions);
  });
  
  // Return the original models (they have their IDs)
  return participants;
}
```

**ParticipantRepositoryImplementation addition:**

```dart
// In ParticipantRepositoryImplementation

@override
Future<Either<Failure, List<ParticipantEntity>>> createParticipantsBatch(
  List<ParticipantEntity> participants,
) async {
  try {
    // Convert entities to models
    final models = participants
        .map((p) => ParticipantModel.convertFromEntity(p))
        .toList();

    // Batch insert to local database
    await _localDatasource.insertParticipantsBatch(models);

    // Attempt remote sync (non-blocking, queued if offline)
    if (await _connectivityService.hasInternetConnection()) {
      try {
        for (final model in models) {
          await _remoteDatasource.insertParticipant(model);
        }
      } on Exception catch (_) {
        // Queued for sync - local data is safe
      }
    }

    return Right(participants);
  } on Exception catch (e) {
    return Left(LocalCacheWriteFailure(
      userFriendlyMessage: 'Failed to save participants',
      technicalDetails: e.toString(),
    ));
  }
}
```

---

## ⚡ Quick Reference — Critical Conversions

### Field Name Mapping

| Type | Field Name | Notes |
|------|------------|-------|
| `CSVRowData` | `sourceRowNumber` | Original CSV row position (1-indexed) |
| `CSVRowError` | `rowNumber` | **NOT** `sourceRowNumber` — same concept, different name |
| `BulkImportPreviewRow` | `sourceRowNumber` | Maps from CSVRowData/CSVRowError |

### Error Aggregation Pattern

```dart
// CSVRowError is individual, BulkImportPreviewRow.validationErrors is Map<String, String>
// Must aggregate:

final errorsByRow = <int, List<CSVRowError>>{};
for (final error in csvResult.errors) {
  errorsByRow.putIfAbsent(error.rowNumber, () => []).add(error);
}

for (final entry in errorsByRow.entries) {
  final validationErrors = <String, String>{};
  for (final error in entry.value) {
    validationErrors[error.fieldName] = error.errorMessage;
  }
  // Use validationErrors in BulkImportPreviewRow
}
```

### Required Imports

```dart
// BulkImportUseCase
import 'package:tkd_brackets/features/participant/domain/services/csv_row_error.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_import_result.dart';
import 'package:tkd_brackets/features/participant/domain/services/participant_check_data.dart';

// BulkImportPreviewRow
import 'package:tkd_brackets/features/participant/domain/services/csv_row_data.dart';
import 'package:tkd_brackets/features/participant/domain/services/duplicate_match.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/bulk_import_row_status.dart';
```

### CSVRowData Placeholder for Error Rows

```dart
// CSVRowData requires these fields - use empty strings for error rows
CSVRowData(
  firstName: '',
  lastName: '',
  schoolOrDojangName: '',
  beltRank: '',
  sourceRowNumber: rowNumber,
)
```

---

### Test Fixtures

```dart
const validCsvContent = '''
FirstName,LastName,Dojang,Belt,Weight
John,Smith,Kim's TKD,blue,45.5
Jane,Doe,Elite TKD,red,52.0
''';

const csvWithErrors = '''
FirstName,LastName,Dojang,Belt
John,,Kim's TKD,blue
,Smith,Elite TKD,red
''';

const emptyCsvContent = '';
```

---

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 4, Story 4.6]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Clean Architecture, Use Case Pattern]
- [Source: `_bmad-output/implementation-artifacts/4-5-duplicate-detection-algorithm.md` — DuplicateDetectionService, batch method]
- [Source: `_bmad-output/implementation-artifacts/4-4-csv-import-parser.md` — CSVParserService, CSVRowData]
- [Source: `_bmad-output/implementation-artifacts/4-3-manual-participant-entry.md` — CreateParticipantUseCase, validation patterns]
- [Source: `tkd_brackets/lib/features/participant/domain/entities/participant_entity.dart` — ParticipantEntity fields]
- [Source: `tkd_brackets/lib/features/participant/domain/repositories/participant_repository.dart` — Repository interface pattern]

---

## Anti-Patterns — WHAT NOT TO DO

| ❌ Don't Do This | ✅ Do This Instead | Source |
|-----------------|---------------------|--------|
| Create participants one-by-one in a loop | Use batch insert method for performance | AC8 |
| Re-implement CSV parsing logic | Inject and use existing `CSVParserService` | AC5 |
| Re-implement duplicate detection | Inject and use existing `DuplicateDetectionService` | AC5 |
| Skip duplicate check for performance | Always check duplicates per FR15 | AC5 |
| Return partial results on parsing failure | Return `Left(ValidationFailure)` | AC10 |
| Modify `CSVRowData` or `CSVParserService` | Use as-is, don't modify | AC13 |
| Put preview classes in presentation layer | Keep in domain/usecases/ | Architecture |
| Forget to generate UUIDs for new participants | Generate UUID in `importSelected()` | AC7 |
| Allow importing rows with `error` status | Skip error rows, add to errorMessages | AC7 |
| Use `@lazySingleton` for use case | Use `@injectable` | Use case pattern |
| Use `error.sourceRowNumber` | CSVRowError uses `rowNumber`, not `sourceRowNumber` | Critical |
| Assume `CSVRowError.fieldErrors` exists | CSVRowError has individual `fieldName`/`errorMessage` - must aggregate | Critical |
| Create CSVRowData with `divisionId` field | CSVRowData doesn't have divisionId - pass to `toCreateParticipantParams()` | Critical |
| Fail preview on duplicate detection error | Gracefully degrade with empty duplicates list | AC10 |
| Call `toCreateParticipantParams()` without divisionId | Always pass divisionId parameter | AC7 |
| Import all preview classes without checking exports | Update usecases.dart barrel file | AC13 |
| Forget `_` prefix on private methods | Use `_determineStatus()`, `_aggregateErrors()` | Dart convention |
| Skip organization/permission validation | Verify tournament belongs to user's org | Security |

---

## Previous Story Intelligence

### From Story 4.5: Duplicate Detection Algorithm

**Key Learnings:**
1. **Batch method exists:** `checkForDuplicatesBatch()` returns `Map<int, List<DuplicateMatch>>` keyed by source row number
2. **Use `ParticipantCheckData.fromCSVRowData()`:** Convert CSV row to check data
3. **Confidence levels:** `isHighConfidence` (≥0.8), `isMediumConfidence` (≥0.5), `isLowConfidence` (<0.5)
4. **On fetch failure:** Returns `Right({})` — empty map, graceful degradation
5. **⚠️ Pass `sourceRowNumbers` parameter:** Maps results back to correct CSV rows
6. **Method signature:**
   ```dart
   Future<Either<Failure, Map<int, List<DuplicateMatch>>>> checkForDuplicatesBatch({
     required String tournamentId,
     required List<ParticipantCheckData> newParticipants,
     List<int>? sourceRowNumbers,  // Optional but recommended for CSV import
   });
   ```

### From Story 4.4: CSV Import Parser

**Key Learnings:**
1. **CSVImportResult:** Has `validRows` (List<CSVRowData>) and `errors` (List<CSVRowError>)
2. **CSVRowData:** Has `toCreateParticipantParams(divisionId)` method — **must pass divisionId**
3. **Per-row error collection:** Don't fail entire import on single row error
4. **`sourceRowNumber` on CSVRowData:** Key for tracking rows through pipeline
5. **⚠️ CRITICAL FIELD NAME MISMATCH:**
   - `CSVRowData.sourceRowNumber` — for valid rows
   - `CSVRowError.rowNumber` — for error rows (NOT `sourceRowNumber`!)
6. **⚠️ CSVRowError structure:** Individual error with `fieldName`, `errorMessage`, `rawValue` — NOT a map!
7. **CSVRowData does NOT have divisionId:** Pass divisionId to `toCreateParticipantParams()`

### From Story 4.3: Manual Participant Entry

**Key Learnings:**
1. **Validation constants:** `minAge = 4`, `maxAge = 80`, `maxWeightKg = 150`
2. **Required fields:** firstName, lastName, schoolOrDojangName, beltRank
3. **Entity creation:** Generate UUID with `Uuid().v4()`, set timestamps, default `checkInStatus = pending`
4. **Repository pattern:** Call repository for persistence

---

## Dev Agent Record

### Agent Model Used
glm-5-free
### Debug Log References
N/A
### Completion Notes List
- Implemented BulkImportUseCase with generatePreview() and importSelected() methods
- Added BulkImportRowStatus enum (valid, warning, error)
- Created BulkImportPreviewRow, BulkImportPreview, BulkImportResult freezed classes
- Added createParticipantsBatch() to ParticipantRepository and insertParticipantsBatch() to ParticipantLocalDatasource
- Implemented batch insert in both datasource and repository implementations
- Injected CSVParserService, DuplicateDetectionService, ParticipantRepository
- Aggregates CSVRowError by row number for error handling
- Graceful degradation on duplicate detection failure
- All 17 unit tests pass
- flutter analyze passes with zero new errors
- Existing infrastructure only has additive changes

### File List
- tkd_brackets/lib/features/participant/domain/usecases/bulk_import_row_status.dart (NEW)
- tkd_brackets/lib/features/participant/domain/usecases/bulk_import_preview_row.dart (NEW)
- tkd_brackets/lib/features/participant/domain/usecases/bulk_import_preview_row.freezed.dart (GENERATED)
- tkd_brackets/lib/features/participant/domain/usecases/bulk_import_preview.dart (NEW)
- tkd_brackets/lib/features/participant/domain/usecases/bulk_import_preview.freezed.dart (GENERATED)
- tkd_brackets/lib/features/participant/domain/usecases/bulk_import_result.dart (NEW)
- tkd_brackets/lib/features/participant/domain/usecases/bulk_import_result.freezed.dart (GENERATED)
- tkd_brackets/lib/features/participant/domain/usecases/bulk_import_usecase.dart (NEW)
- tkd_brackets/lib/features/participant/domain/repositories/participant_repository.dart (MODIFIED - added createParticipantsBatch)
- tkd_brackets/lib/features/participant/data/datasources/participant_local_datasource.dart (MODIFIED - added insertParticipantsBatch)
- tkd_brackets/lib/features/participant/data/repositories/participant_repository_implementation.dart (MODIFIED - added createParticipantsBatch)
- tkd_brackets/lib/features/participant/domain/usecases/usecases.dart (MODIFIED - added exports)
- tkd_brackets/test/features/participant/domain/usecases/bulk_import_usecase_test.dart (NEW)
- _bmad-output/implementation-artifacts/sprint-status.yaml (MODIFIED - status changed to review)
