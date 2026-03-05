# Story 4.13: Paste from Spreadsheet

Status: done

**Created:** 2026-03-05

**Epic:** 4 - Participant Management

**FRs Covered:** FR15 (Paste from spreadsheet)

**Dependencies:** Story 4.4 (CSV Import Parser) - COMPLETE | Story 4.6 (Bulk Import with Validation) - COMPLETE | Story 4.12 (Participant Management UI) - COMPLETE

---

## TL;DR — Critical Facts

**CURRENT STATE:**
- ✅ `CSVParserService` at `tkd_brackets/lib/features/participant/domain/services/csv_parser_service.dart` — parses CSV (comma-delimited) content into validated `CSVRowData`, handles column aliases (case-insensitive), belt normalization, date parsing. **Uses comma (`,`) as delimiter ONLY — its `_parseCSVLine` method splits on comma; tab-delimited paste will fail silently (entire row treated as one column).**
- ✅ `CSVParserService._columnAliases` — maps lowercase trimmed headers to internal field names. **Current aliases include `firstname`, `first_name`, `lastname`, `last_name`, `school`, `dojang`, `belt`, `beltrank`, `rank`, etc. but do NOT include space-separated forms like `first name` or `last name` which are common in spreadsheet column headers.**
- ✅ `CSVParserService._mapColumnName(String header)` — returns `_columnAliases[header.toLowerCase().trim()]`
- ✅ `BulkImportUseCase` at `tkd_brackets/lib/features/participant/domain/usecases/bulk_import_usecase.dart` — accepts raw CSV string via `generatePreview({required String csvContent, required String divisionId, required String tournamentId})`, orchestrates parsing → duplicate detection → preview rows. Calls `_csvParserService.parseCSV(csvContent: csvContent, divisionId: divisionId)` internally.
- ✅ `CSVImportBloc` at `tkd_brackets/lib/features/participant/presentation/bloc/csv_import_bloc.dart` — annotated `@injectable`, manages import wizard state, calls `BulkImportUseCase`. **Constructor currently takes ONLY `BulkImportUseCase` as a single positional parameter: `CSVImportBloc(this._bulkImportUseCase)`.**
- ✅ `CSVImportPage` at `tkd_brackets/lib/features/participant/presentation/pages/csv_import_page.dart` — **CRITICAL: creates BLoC MANUALLY, NOT via `getIt`**: `CSVImportBloc(getIt<BulkImportUseCase>())` on line 23. This manual instantiation must be updated when `ClipboardInputService` is added to the constructor.
- ✅ `CSVImportPage` input step hint text currently reads: `'first_name,last_name,school,belt\nJohn,Doe,Academy,red'` — needs updating to mention spreadsheet paste.
- ✅ Existing test `tkd_brackets/test/features/participant/presentation/bloc/csv_import_bloc_test.dart` — creates BLoC as `CSVImportBloc(mockUseCase)` (single arg). **Will break when constructor changes. Must be updated to pass mock `ClipboardInputService` as second argument.**
- ✅ Barrel file `tkd_brackets/lib/features/participant/domain/services/services.dart` — exports all domain services. **Must add `export 'clipboard_input_service.dart';`**
- ✅ `ParticipantListPage` — has "Import CSV" button in AppBar (icon: `Icons.file_upload_outlined`) that navigates to `CsvImportRoute`.
- ✅ DI uses `injectable` + `get_it`. `@lazySingleton` on stateless services, `@injectable` on BLoCs. `build_runner` regenerates `injection.config.dart`.

**KEY INSIGHT — MINIMAL CHANGE APPROACH:**

The existing `CSVParserService.parseCSV()` already does all heavy lifting (column mapping, validation, belt normalization, date parsing). The simplest and safest approach is to create a `ClipboardInputService` that:
1. Detects if pasted content is tab-delimited (spreadsheet paste) vs comma-delimited (CSV)
2. Converts tab-delimited → comma-delimited CSV (handling embedded commas via RFC 4180 quoting)
3. Returns the normalized CSV string to feed into the existing `BulkImportUseCase.generatePreview()` unchanged

This avoids modifying `CSVParserService._parseCSVLine` internals and reuses ALL existing validation, preview, and import logic.

**ADDITIONALLY:** Add space-separated column aliases (e.g. `'first name'` → `'firstName'`) to `CSVParserService._columnAliases` so spreadsheet headers like `First Name`, `Last Name`, `Belt Rank`, `Date of Birth` are recognized after tab→CSV conversion.

---

## Story

**As an** organizer,
**I want** to paste tabular data directly from a spreadsheet,
**So that** I bypass file selection and mapping steps when adding participants (FR15).

---

## Acceptance Criteria

### AC1: ClipboardInputService — Tab-to-CSV Conversion

- [x] **AC1.1:** `ClipboardInputService` created at `tkd_brackets/lib/features/participant/domain/services/clipboard_input_service.dart`
- [x] **AC1.2:** Class annotated `@lazySingleton` (stateless service, same pattern as `CSVParserService` at line 19 of `csv_parser_service.dart`)
- [x] **AC1.3:** Method `String normalizeToCSV(String rawInput)` — **synchronous**, detects delimiter and converts to comma-delimited CSV if needed
- [x] **AC1.4:** Detection logic: if the first non-empty line contains at least one tab character (`\t`), treat ENTIRE input as tab-delimited; otherwise return input unchanged (already CSV)
- [x] **AC1.5:** Tab-to-CSV conversion per line: split line on `\t`, for each cell value apply RFC 4180 quoting (wrap in double quotes if cell contains comma `,`, double-quote `"`, or newline `\n`; escape existing `"` as `""`), join cells with `,`, terminate line with `\n`
- [x] **AC1.6:** Edge cases handled correctly:
  - Empty input → return empty string
  - Input with only whitespace/empty lines → return empty string
  - Trailing tabs → produce empty string cells (e.g., `"John\tDoe\t"` → `"John,Doe,"`)
  - Mixed line endings (`\r\n` and `\n`) → normalize to `\n` in output
  - Cells containing embedded double quotes → escape as `""` and wrap in quotes (e.g., `He said "hi"` → `"He said ""hi"""`)
  - Cells containing embedded commas → wrap in quotes (e.g., `River, City Dojang` → `"River, City Dojang"`)
  - Cells containing embedded tabs within quoted regions (unlikely but safe) → treated as literal content
- [x] **AC1.7:** Preserves header row — first non-empty line is treated as column headers, same `CSVParserService._columnAliases` apply after conversion

### AC2: CSVParserService — Add Space-Separated Column Aliases

- [x] **AC2.1:** Add the following entries to `CSVParserService._columnAliases` map (file: `tkd_brackets/lib/features/participant/domain/services/csv_parser_service.dart`, `_columnAliases` starts at line 21):
  ```dart
  'first name': 'firstName',
  'last name': 'lastName',
  'date of birth': 'dateOfBirth',
  'belt rank': 'beltRank',
  'weight kg': 'weightKg',
  'registration number': 'registrationNumber',
  'school name': 'schoolOrDojangName',
  'dojang name': 'schoolOrDojangName',
  ```
- [x] **AC2.2:** This ensures that when a spreadsheet has headers like `First Name`, `Last Name`, `Date Of Birth`, `Belt Rank`, they map correctly after `_mapColumnName` lowercases and trims the header value
- [x] **AC2.3:** Existing aliases are NOT modified — new entries are added at end of map
- [x] **AC2.4:** Existing `csv_parser_service_test.dart` tests still pass (no behavioral change for comma-delimited CSV with existing headers)

### AC3: CSVImportBloc — Inject ClipboardInputService

- [x] **AC3.1:** Add `ClipboardInputService` as second positional parameter to `CSVImportBloc` constructor:
  ```dart
  // BEFORE (current, line 10):
  CSVImportBloc(this._bulkImportUseCase) : super(const CSVImportInitial()) {
  
  // AFTER:
  CSVImportBloc(this._bulkImportUseCase, this._clipboardInputService)
      : super(const CSVImportInitial()) {
  ```
- [x] **AC3.2:** Add field: `final ClipboardInputService _clipboardInputService;`
- [x] **AC3.3:** In `_onPreviewRequested` (line 32-73), call `_clipboardInputService.normalizeToCSV(csvContent)` BEFORE passing to `_bulkImportUseCase.generatePreview()`:
  ```dart
  Future<void> _onPreviewRequested(
    CSVImportPreviewRequested event,
    Emitter<CSVImportState> emit,
  ) async {
    final csvContent = _getCurrentCsvContent();
    if (csvContent.isEmpty) return;

    // NEW: Normalize tab-delimited paste to comma-delimited CSV
    final normalizedContent = _clipboardInputService.normalizeToCSV(csvContent);

    emit(CSVImportPreviewInProgress(csvContent: csvContent));

    final result = await _bulkImportUseCase.generatePreview(
      csvContent: normalizedContent,  // ← Pass normalized content
      divisionId: event.divisionId,
      tournamentId: event.tournamentId,
    );
    // ... rest UNCHANGED
  }
  ```
- [x] **AC3.4:** The `csvContent` stored in state remains the ORIGINAL user input (tabs and all) — this is correct for display and "back" functionality. Only the content passed to `generatePreview()` is normalized.
- [x] **AC3.5:** Import statement added: `import 'package:tkd_brackets/features/participant/domain/services/clipboard_input_service.dart';`

### AC4: CSVImportPage — Update BLoC Creation and Hint Text

- [x] **AC4.1:** **CRITICAL:** Update manual BLoC instantiation at line 23 of `csv_import_page.dart` to pass `ClipboardInputService`:
  ```dart
  // BEFORE (current, line 23):
  create: (context) => CSVImportBloc(getIt<BulkImportUseCase>()),
  
  // AFTER:
  create: (context) => CSVImportBloc(
    getIt<BulkImportUseCase>(),
    getIt<ClipboardInputService>(),
  ),
  ```
- [x] **AC4.2:** Add import: `import 'package:tkd_brackets/features/participant/domain/services/clipboard_input_service.dart';`
- [x] **AC4.3:** Update hint text in `_buildInputStep` (line 110-111) to mention spreadsheet paste:
  ```dart
  // BEFORE:
  hintText: 'first_name,last_name,school,belt\nJohn,Doe,Academy,red',
  
  // AFTER:
  hintText: 'Paste CSV or spreadsheet data here.\n'
      'Example: first_name,last_name,school,belt\n'
      'John,Doe,Academy,red',
  ```

### AC5: Barrel File — Export ClipboardInputService

- [x] **AC5.1:** Add `export 'clipboard_input_service.dart';` to `tkd_brackets/lib/features/participant/domain/services/services.dart`

### AC6: Unit Tests — ClipboardInputService

- [x] **AC6.1:** Test file at `tkd_brackets/test/features/participant/domain/services/clipboard_input_service_test.dart`
- [x] **AC6.2:** Test: tab-delimited single row → valid CSV
  ```
  Input:  "first_name\tlast_name\tschool\tbelt\nJohn\tDoe\tAcademy\tBlack"
  Output: "first_name,last_name,school,belt\nJohn,Doe,Academy,Black\n"
  ```
- [x] **AC6.3:** Test: comma-delimited CSV passes through UNCHANGED (byte-for-byte identical)
  ```
  Input:  "first_name,last_name,school,belt\nJohn,Doe,Academy,Black"
  Output: "first_name,last_name,school,belt\nJohn,Doe,Academy,Black"
  ```
- [x] **AC6.4:** Test: tab-delimited cell with embedded comma → cell quoted
  ```
  Input:  "name\tschool\nJohn\tRiver, City Dojang"
  Output: "name,\"River, City Dojang\"\n" (after header line)
  ```
- [x] **AC6.5:** Test: tab-delimited cell with embedded double quotes → escaped and quoted
  ```
  Input:  "name\tnotes\nJohn\tHe said \"hi\""
  Output: "name,\"He said \"\"hi\"\"\"\n" (after header line)
  ```
- [x] **AC6.6:** Test: empty input → returns empty string
- [x] **AC6.7:** Test: multi-row tab-delimited paste with header row (3+ data rows) → all rows converted correctly
- [x] **AC6.8:** Test: mixed line endings (`\r\n` and `\n`) → output uses `\n` only
- [x] **AC6.9:** Test: trailing tabs → produce empty cells correctly
  ```
  Input:  "a\tb\t\n1\t2\t"
  Output: "a,b,\n1,2,\n"
  ```
- [x] **AC6.10:** Test: whitespace-only input → returns the input unchanged (or empty)

### AC7: Unit Tests — CSVParserService Column Alias Additions

- [x] **AC7.1:** In existing test file `tkd_brackets/test/features/participant/domain/services/csv_parser_service_test.dart`, add test group for space-separated headers
- [x] **AC7.2:** Test: CSV with headers `First Name,Last Name,School,Belt Rank` → parses successfully, maps to correct fields
- [x] **AC7.3:** Test: CSV with headers `Date Of Birth,Weight Kg,Registration Number` → optional fields parsed correctly

### AC8: Unit Tests — CSVImportBloc Updated Constructor

- [x] **AC8.1:** Update existing test file `tkd_brackets/test/features/participant/presentation/bloc/csv_import_bloc_test.dart`
- [x] **AC8.2:** Add mock: `class MockClipboardInputService extends Mock implements ClipboardInputService {}`
- [x] **AC8.3:** In `setUp()`, create `mockClipboardInputService = MockClipboardInputService();`
- [x] **AC8.4:** **CRITICAL:** Update `buildBloc()` helper (currently line 54):
  ```dart
  // BEFORE:
  CSVImportBloc buildBloc() => CSVImportBloc(mockUseCase);
  
  // AFTER:
  CSVImportBloc buildBloc() => CSVImportBloc(mockUseCase, mockClipboardInputService);
  ```
- [x] **AC8.5:** In `setUpAll()`, add: `registerFallbackValue('');` for String fallback (for `normalizeToCSV` arg)
- [x] **AC8.6:** In `setUp()`, stub `ClipboardInputService.normalizeToCSV` to return input unchanged by default:
  ```dart
  when(() => mockClipboardInputService.normalizeToCSV(any())).thenAnswer((inv) => inv.positionalArguments[0] as String);
  ```
  This ensures ALL existing tests pass unchanged (CSV passthrough behavior).
- [x] **AC8.7:** Add NEW test group `'Tab-delimited paste normalization'`:
  ```dart
  blocTest<CSVImportBloc, CSVImportState>(
    'normalizes tab-delimited content before generating preview',
    seed: () => const CSVImportInitial(csvContent: 'John\tDoe\tAcademy\tBlack'),
    build: () {
      when(() => mockClipboardInputService.normalizeToCSV(any()))
          .thenReturn('John,Doe,Academy,Black\n');
      when(() => mockUseCase.generatePreview(
            csvContent: any(named: 'csvContent'),
            divisionId: any(named: 'divisionId'),
            tournamentId: any(named: 'tournamentId'),
          )).thenAnswer((_) async => Right(tPreview));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const CSVImportPreviewRequested(
      divisionId: 'div-123', tournamentId: 'tour-123',
    )),
    verify: (_) {
      verify(() => mockClipboardInputService.normalizeToCSV('John\tDoe\tAcademy\tBlack')).called(1);
      verify(() => mockUseCase.generatePreview(
        csvContent: 'John,Doe,Academy,Black\n',
        divisionId: 'div-123',
        tournamentId: 'tour-123',
      )).called(1);
    },
  );
  ```

### AC9: Integration Test — End-to-End Paste Flow

- [x] **AC9.1:** Test (can be in `clipboard_input_service_test.dart` or a new integration test file) that verifies the full chain: tab-delimited input with spreadsheet-style headers → `ClipboardInputService.normalizeToCSV()` → resulting CSV string is parseable by `CSVParserService.parseCSV()` → produces valid `CSVImportResult` with correct `validRows`
- [x] **AC9.2:** Use REAL `CSVParserService` (not mocked) to validate actual integration. Create `ClipboardInputService` and `CSVParserService` directly (no DI needed — both are stateless).
  ```dart
  test('tab-delimited spreadsheet paste produces valid parsed rows', () async {
    final clipboardService = ClipboardInputService();
    final csvParser = CSVParserService();
    
    const tabInput = 'First Name\tLast Name\tSchool\tBelt\n'
        'John\tDoe\tAcademy\tBlack\n'
        'Jane\tKim\tTiger Dojang\tRed\n';
    
    final normalized = clipboardService.normalizeToCSV(tabInput);
    final result = await csvParser.parseCSV(
      csvContent: normalized,
      divisionId: 'div-test',
    );
    
    expect(result.isRight(), true);
    result.fold((_) {}, (r) {
      expect(r.validRows.length, 2);
      expect(r.validRows[0].firstName, 'John');
      expect(r.validRows[1].firstName, 'Jane');
    });
  });
  ```

### AC10: Build Verification

- [x] **AC10.1:** `dart run build_runner build --delete-conflicting-outputs` completes without errors (regenerates `injection.config.dart` with new `ClipboardInputService` registration)
- [x] **AC10.2:** `dart analyze` shows no errors in all modified/created files
- [x] **AC10.3:** All new tests pass: `flutter test test/features/participant/domain/services/clipboard_input_service_test.dart`
- [x] **AC10.4:** All modified tests pass: `flutter test test/features/participant/presentation/bloc/csv_import_bloc_test.dart`
- [x] **AC10.5:** All existing tests still pass: `flutter test`

---

## Tasks / Subtasks

- [x] Task 1: Create `ClipboardInputService` (AC: #1)
  - [x] 1.1: Create `tkd_brackets/lib/features/participant/domain/services/clipboard_input_service.dart`
  - [x] 1.2: Implement `normalizeToCSV(String rawInput)` — tab detection → conversion with RFC 4180 quoting
  - [x] 1.3: Implement `_quoteIfNeeded(String cell)` private helper
- [x] Task 2: Add column aliases to CSVParserService (AC: #2)
  - [x] 2.1: Add space-separated aliases to `_columnAliases` map in `csv_parser_service.dart`
- [x] Task 3: Integrate into CSVImportBloc (AC: #3)
  - [x] 3.1: Add `ClipboardInputService` as second constructor parameter
  - [x] 3.2: Call `normalizeToCSV()` in `_onPreviewRequested` before `generatePreview()`
- [x] Task 4: Update CSVImportPage (AC: #4)
  - [x] 4.1: Update `BlocProvider` create to pass `getIt<ClipboardInputService>()`
  - [x] 4.2: Update hint text
- [x] Task 5: Update barrel file (AC: #5)
  - [x] 5.1: Add export to `services.dart`
- [x] Task 6: Unit Tests — ClipboardInputService (AC: #6)
  - [x] 6.1: Create `clipboard_input_service_test.dart`
  - [x] 6.2: Write all conversion and edge case tests
- [x] Task 7: Unit Tests — CSVParserService aliases (AC: #7)
  - [x] 7.1: Add space-separated header tests to existing test file
- [x] Task 8: Update CSVImportBloc tests (AC: #8)
  - [x] 8.1: Add `MockClipboardInputService` mock class
  - [x] 8.2: Update `buildBloc()` to pass both mocks
  - [x] 8.3: Add default stub for `normalizeToCSV` in `setUp()`
  - [x] 8.4: Add tab-delimited normalization verification test
- [x] Task 9: Integration test (AC: #9)
  - [x] 9.1: Write end-to-end test using REAL services
- [x] Task 10: Build verification (AC: #10)
  - [x] 10.1: Run `build_runner` to regenerate DI config
  - [x] 10.2: Run `dart analyze`
  - [x] 10.3: Run full test suite

---

## Dev Notes

### ⚠️ CRITICAL: Files to Create

| File                                                                                       | Type    | Description              |
| ------------------------------------------------------------------------------------------ | ------- | ------------------------ |
| `tkd_brackets/lib/features/participant/domain/services/clipboard_input_service.dart`       | Service | Tab→CSV conversion       |
| `tkd_brackets/test/features/participant/domain/services/clipboard_input_service_test.dart` | Test    | Unit + integration tests |

### ⚠️ CRITICAL: Files to Modify

| File                                                                                  | Exact Change                                                                                   |
| ------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| `tkd_brackets/lib/features/participant/domain/services/csv_parser_service.dart`       | Add 8 space-separated entries to `_columnAliases` map (lines 21-44)                            |
| `tkd_brackets/lib/features/participant/domain/services/services.dart`                 | Add `export 'clipboard_input_service.dart';`                                                   |
| `tkd_brackets/lib/features/participant/presentation/bloc/csv_import_bloc.dart`        | Add `ClipboardInputService` constructor param + field + import + call in `_onPreviewRequested` |
| `tkd_brackets/lib/features/participant/presentation/pages/csv_import_page.dart`       | Update `BlocProvider` create (line 23) + import + hint text (line 110-111)                     |
| `tkd_brackets/test/features/participant/presentation/bloc/csv_import_bloc_test.dart`  | Add mock, update `buildBloc()`, add default stub, add new test group                           |
| `tkd_brackets/test/features/participant/domain/services/csv_parser_service_test.dart` | Add space-separated header tests                                                               |

### ⚠️ CRITICAL: Do NOT Modify These Files

- `csv_parser_service.dart` — ONLY add aliases to `_columnAliases` map. Do NOT modify `_parseCSVLine`, `_splitLines`, `parseCSV`, or any other method. The entire point is that tab→CSV conversion happens upstream.
- `bulk_import_usecase.dart` — No changes needed. It receives CSV string from BLoC.

### EXACT ClipboardInputService Implementation

```dart
import 'package:injectable/injectable.dart';

/// Converts tab-delimited spreadsheet paste data to comma-delimited CSV.
///
/// Detects if input is tab-delimited (from spreadsheet copy-paste) and
/// converts to standard CSV format compatible with [CSVParserService].
/// If input is already comma-delimited, returns it unchanged.
@lazySingleton
class ClipboardInputService {
  /// Normalizes [rawInput] to comma-delimited CSV.
  ///
  /// Detection: If the first non-empty line contains a tab character,
  /// the entire input is treated as tab-delimited and converted.
  /// Otherwise returns [rawInput] unchanged.
  String normalizeToCSV(String rawInput) {
    if (rawInput.trim().isEmpty) return rawInput;

    // Split on line breaks, preserving structure
    final lines = rawInput.split(RegExp(r'\r?\n'));

    // Find first non-empty line for delimiter detection
    final firstNonEmpty = lines.firstWhere(
      (l) => l.trim().isNotEmpty,
      orElse: () => '',
    );

    // If no tabs found, assume already CSV — return unchanged
    if (!firstNonEmpty.contains('\t')) return rawInput;

    // Convert tab-delimited → comma-delimited CSV with RFC 4180 quoting
    final buffer = StringBuffer();
    for (final line in lines) {
      // Preserve empty lines as-is (CSVParserService._splitLines skips them)
      if (line.trim().isEmpty) continue;
      final cells = line.split('\t');
      for (var i = 0; i < cells.length; i++) {
        if (i > 0) buffer.write(',');
        buffer.write(_quoteIfNeeded(cells[i]));
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  /// Wraps [cell] in double quotes if it contains special characters
  /// per RFC 4180: comma, double quote, or newline.
  /// Existing double quotes are escaped as "".
  String _quoteIfNeeded(String cell) {
    if (cell.contains(',') || cell.contains('"') || cell.contains('\n')) {
      return '"${cell.replaceAll('"', '""')}"';
    }
    return cell;
  }
}
```

### EXACT CSVImportBloc Changes

```dart
// File: lib/features/participant/presentation/bloc/csv_import_bloc.dart
// 
// ADD import at top (after existing imports):
import 'package:tkd_brackets/features/participant/domain/services/clipboard_input_service.dart';

// CHANGE constructor (line 9-17):
@injectable
class CSVImportBloc extends Bloc<CSVImportEvent, CSVImportState> {
  CSVImportBloc(this._bulkImportUseCase, this._clipboardInputService)
      : super(const CSVImportInitial()) {
    on<CSVImportContentChanged>(_onContentChanged);
    on<CSVImportPreviewRequested>(_onPreviewRequested);
    on<CSVImportRowSelectionToggled>(_onRowSelectionToggled);
    on<CSVImportSelectAllToggled>(_onSelectAllToggled);
    on<CSVImportImportRequested>(_onImportRequested);
    on<CSVImportResetRequested>(_onResetRequested);
  }

  final BulkImportUseCase _bulkImportUseCase;
  final ClipboardInputService _clipboardInputService;

// CHANGE _onPreviewRequested (line 32-73):
  Future<void> _onPreviewRequested(
    CSVImportPreviewRequested event,
    Emitter<CSVImportState> emit,
  ) async {
    final csvContent = _getCurrentCsvContent();
    if (csvContent.isEmpty) return;

    // Normalize tab-delimited spreadsheet paste to comma-delimited CSV
    final normalizedContent = _clipboardInputService.normalizeToCSV(csvContent);

    emit(CSVImportPreviewInProgress(csvContent: csvContent));

    final result = await _bulkImportUseCase.generatePreview(
      csvContent: normalizedContent,  // ← Pass NORMALIZED content
      divisionId: event.divisionId,
      tournamentId: event.tournamentId,
    );
    // ... rest of method is UNCHANGED (result.fold etc.)
  }
}
```

### EXACT CSVImportPage Changes

```dart
// File: lib/features/participant/presentation/pages/csv_import_page.dart
//
// ADD import (after line 8):
import 'package:tkd_brackets/features/participant/domain/services/clipboard_input_service.dart';

// CHANGE line 23 (BlocProvider create):
create: (context) => CSVImportBloc(
  getIt<BulkImportUseCase>(),
  getIt<ClipboardInputService>(),
),

// CHANGE hint text (lines 110-111):
hintText: 'Paste CSV or spreadsheet data here.\n'
    'Example: first_name,last_name,school,belt\n'
    'John,Doe,Academy,red',
```

### EXACT CSVParserService Alias Additions

```dart
// File: lib/features/participant/domain/services/csv_parser_service.dart
// ADD these entries to _columnAliases map (after line 43, before closing brace):
    'first name': 'firstName',
    'last name': 'lastName',
    'date of birth': 'dateOfBirth',
    'belt rank': 'beltRank',
    'weight kg': 'weightKg',
    'registration number': 'registrationNumber',
    'school name': 'schoolOrDojangName',
    'dojang name': 'schoolOrDojangName',
```

### EXACT services.dart Change

```dart
// File: lib/features/participant/domain/services/services.dart
// ADD after line 1 (or anywhere in the export list):
export 'clipboard_input_service.dart';
```

### Testing Patterns

- `ClipboardInputService` is **synchronous and stateless** — no mocking needed for its own unit tests. Instantiate directly: `final service = ClipboardInputService();`
- For BLoC tests, mock both dependencies:
  ```dart
  class MockClipboardInputService extends Mock implements ClipboardInputService {}
  class MockBulkImportUseCase extends Mock implements BulkImportUseCase {}
  ```
- **Default stub for existing tests to pass:** In `setUp()`, stub `normalizeToCSV` to return its input unchanged. This ensures CSV passthrough behavior and all pre-existing BLoC tests pass without modification:
  ```dart
  when(() => mockClipboardInputService.normalizeToCSV(any()))
      .thenAnswer((inv) => inv.positionalArguments[0] as String);
  ```
- Use `mocktail` — NOT `mockito`. NO `@GenerateMocks`.

### DI Registration

`@lazySingleton` on `ClipboardInputService` + `@injectable` on `CSVImportBloc` → both auto-registered by `injectable`. `injectable` resolves `CSVImportBloc`'s constructor dependencies automatically. **BUT** `CSVImportPage` manually creates the BLoC, so it must explicitly pass `getIt<ClipboardInputService>()`.

After creating the file, run: `dart run build_runner build --delete-conflicting-outputs` to regenerate `injection.config.dart`.

### Project Structure Notes

- `ClipboardInputService` is placed in `domain/services/` alongside `CSVParserService` — same layer, same pattern
- No new routes, pages, or BLoC event/state classes needed
- No freezed files to generate for this story (ClipboardInputService is a plain Dart class, no freezed annotation)

### References

- [Source: lib/features/participant/domain/services/csv_parser_service.dart] — CSV parsing, `_columnAliases` map (lines 21-44), `_parseCSVLine` comma delimiter (line 314), `_mapColumnName` lowercasing (line 296)
- [Source: lib/features/participant/domain/usecases/bulk_import_usecase.dart] — `generatePreview()` signature, calls `_csvParserService.parseCSV(csvContent: csvContent, divisionId: divisionId)` at line 39
- [Source: lib/features/participant/presentation/bloc/csv_import_bloc.dart] — constructor (line 10), `_onPreviewRequested` (lines 32-73), `_getCurrentCsvContent` (lines 160-166)
- [Source: lib/features/participant/presentation/pages/csv_import_page.dart] — manual BLoC creation (line 23), hint text (lines 110-111)
- [Source: lib/features/participant/domain/services/services.dart] — barrel file, 9 exports currently
- [Source: test/features/participant/presentation/bloc/csv_import_bloc_test.dart] — `buildBloc()` helper (line 54), mock setup
- [Source: _bmad-output/planning-artifacts/epics.md#Story 4.13] — FR15, acceptance criteria
- [Source: _bmad-output/implementation-artifacts/4-12-participant-management-ui.md] — BLoC patterns, testing patterns, DI patterns

---

## Dev Agent Record

### Agent Model Used

Antigravity (code review pass)

### Debug Log References

N/A

### Completion Notes List

- All 10 ACs verified as implemented and passing
- 1608/1608 tests pass (full suite)
- `dart analyze` clean — 0 errors
- DI generation verified — `injection.config.dart` includes `ClipboardInputService`

### Change Log

- **2026-03-05 (Review):** Code review by Antigravity. Fixed: removed unnecessary doc-only import of `csv_parser_service.dart` from `clipboard_input_service.dart`. All ACs/Tasks checked. Story status → done.

### File List

**Created:**
- `tkd_brackets/lib/features/participant/domain/services/clipboard_input_service.dart` — Tab→CSV conversion service
- `tkd_brackets/test/features/participant/domain/services/clipboard_input_service_test.dart` — Unit + integration tests

**Modified:**
- `tkd_brackets/lib/features/participant/domain/services/csv_parser_service.dart` — Added 8 space-separated column aliases
- `tkd_brackets/lib/features/participant/domain/services/services.dart` — Added barrel export
- `tkd_brackets/lib/features/participant/presentation/bloc/csv_import_bloc.dart` — Added ClipboardInputService injection + normalizeToCSV call
- `tkd_brackets/lib/features/participant/presentation/pages/csv_import_page.dart` — Updated BlocProvider + hint text
- `tkd_brackets/test/features/participant/domain/services/csv_parser_service_test.dart` — Added space-separated header tests
- `tkd_brackets/test/features/participant/presentation/bloc/csv_import_bloc_test.dart` — Added mock, updated buildBloc, added normalization test
