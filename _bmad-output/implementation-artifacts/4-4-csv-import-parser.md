# Story 4.4: CSV Import Parser

Status: done

**Created:** 2026-02-20

**Epic:** 4 - Participant Management

**FRs Covered:** FR14 (Import participants via CSV upload)

**Dependencies:** Story 4.3 (Manual Participant Entry) - COMPLETE | Story 4.2 (Participant Entity & Repository) - COMPLETE | Story 4.1 (Participant Feature Structure) - COMPLETE | Epic 3 (Tournament & Division) - COMPLETE | Epic 2 (Auth) - COMPLETE | Epic 1 (Foundation) - COMPLETE

---

## TL;DR — Critical Facts

**CURRENT STATE:**
- ✅ `lib/features/participant/domain/entities/participant_entity.dart` — ParticipantEntity exists with all fields
- ✅ `lib/features/participant/domain/usecases/create_participant_usecase.dart` — CreateParticipantUseCase exists with validation patterns
- ✅ `lib/features/participant/domain/usecases/create_participant_params.dart` — CreateParticipantParams exists
- ✅ `lib/features/division/domain/entities/belt_rank.dart` — BeltRank enum with `fromString()` normalization
- ✅ `lib/core/error/failures.dart` — InputValidationFailure, ValidationFailure exist
- ✅ `Gender` enum exists in participant_entity.dart with `fromString()` method
- ❌ `CSVParserService` — **DOES NOT EXIST** — Create in this story
- ❌ `CSVImportResult` — **DOES NOT EXIST** — Create in this story
- ❌ `CSVRowData` — **DOES NOT EXIST** — Create in this story
- ❌ `CSVRowError` — **DOES NOT EXIST** — Create in this story
- ❌ Unit tests for CSV parser — **DOES NOT EXIST** — Create in this story

**TARGET STATE:** Create CSVParserService in domain/services/ that parses CSV files into validated participant data with per-row error collection.

**KEY PREVIOUS STORY (4.3) LESSONS — APPLY ALL:**
1. Use `@lazySingleton` for services (CSVParserService is stateless utility)
2. Validation errors collected in `Map<String, String>` pattern
3. Belt rank normalization uses `BeltRank.fromString()` - handles case-insensitive, spaces, hyphens
4. Date validation: age 4-80, no future dates
5. Gender parsing: `Gender.fromString()` - case-insensitive
6. Weight validation: 0-150kg
7. Required fields: firstName, lastName, schoolOrDojangName, beltRank
8. Run `build_runner build --delete-conflicting-outputs` after ANY generated file changes
9. Failure types: `ValidationFailure` for CSV parsing errors, `InputValidationFailure` for field errors

**⚠️ CRITICAL ENUM FALLBACK BEHAVIOR — MUST PRE-VALIDATE:**
- `BeltRank.fromString()` returns `BeltRank.white` as fallback (NOT null) for invalid input
- `Gender.fromString()` returns `Gender.male` as fallback (NOT null) for invalid input
- **DO NOT call these methods directly** — use pre-validation helpers that return nullable types
- Invalid belt ranks and genders MUST be detected and reported as errors, NOT silently accepted

---

## Story

**As an** organizer,
**I want** to import participants from a CSV file,
**So that** I can bulk-register athletes from a spreadsheet (FR14).

---

## Acceptance Criteria

- [x] **AC1:** `CSVParserService` created in `lib/features/participant/domain/services/` with `@lazySingleton` annotation

- [x] **AC2:** Service method signature: `Future<Either<Failure, CSVImportResult>> parseCSV({required String csvContent, required String divisionId})`

- [x] **AC3:** Standard column headers supported (case-insensitive):
  - `FirstName`, `LastName` (required)
  - `DOB`, `DateOfBirth`, `Birthday` (optional - date of birth)
  - `Gender`, `Sex` (optional - male/female)
  - `Dojang`, `School`, `SchoolOrDojangName` (required)
  - `Belt`, `BeltRank`, `Rank` (required)
  - `Weight`, `WeightKg` (optional - in kg)
  - `RegNumber`, `RegistrationNumber` (optional)
  - `Notes` (optional)

- [x] **AC4:** Flexible column mapping:
  - Headers are case-insensitive
  - Support common aliases (e.g., "Dojang" or "School" → schoolOrDojangName)
  - Missing required columns → return `ValidationFailure` listing missing columns

- [x] **AC5:** Date format detection (try in order):
  - `YYYY-MM-DD` (ISO format - preferred)
  - `MM/DD/YYYY` (US format)
  - `DD-MM-YYYY` (European format)
  - Invalid dates → add to row errors, continue parsing

- [x] **AC6:** Belt rank normalization:
  - ⚠️ **DO NOT call `BeltRank.fromString()` directly** — it returns `BeltRank.white` as fallback for invalid input
  - Use `_tryParseBeltRank()` helper method that returns `BeltRank?` (null for invalid)
  - Common formats: "White", "Yellow", "Green", "Blue", "Red", "Black", "Black 1st Dan", "1st Dan"
  - Invalid belt ranks → add to row errors, continue parsing

- [x] **AC7:** Gender normalization:
  - ⚠️ **DO NOT call `Gender.fromString()` directly** — it returns `Gender.male` as fallback for invalid input
  - Use `_tryParseGender()` helper method that returns `Gender?` (null for invalid)
  - Accept: "M", "Male", "F", "Female" (case-insensitive)

- [x] **AC8:** Per-row error collection (don't fail entire import):
  - Each row parsed independently
  - **Collect ALL validation errors per row** (not just first error per field)
  - Errors collected in `CSVRowError` with row number, field name, error message, and optional raw value
  - Valid rows returned as `CSVRowData` for downstream processing
  - **Row numbering convention:** Header row is NOT counted; first data row = Row 1

- [x] **AC9:** Result structure `CSVImportResult` (freezed class):
  ```dart
  @freezed
  class CSVImportResult with _$CSVImportResult {
    const factory CSVImportResult({
      required List<CSVRowData> validRows,
      required List<CSVRowError> errors,
      required int totalRows,
    }) = _CSVImportResult;
    
    const CSVImportResult._();
    
    int get successCount => validRows.length;
    int get errorCount => errors.length;
    bool get hasErrors => errors.isNotEmpty;
    bool get isEmpty => totalRows == 0;
  }
  ```

- [x] **AC10:** `CSVRowData` (freezed class) with conversion method:
  ```dart
  @freezed
  class CSVRowData with _$CSVRowData {
    const factory CSVRowData({
      required String firstName,
      required String lastName,
      required String schoolOrDojangName,
      required String beltRank,
      DateTime? dateOfBirth,
      Gender? gender,
      double? weightKg,
      String? registrationNumber,
      String? notes,
      required int sourceRowNumber,
    }) = _CSVRowData;
    
    const CSVRowData._();
    
    /// Converts to CreateParticipantParams for use case invocation.
    CreateParticipantParams toCreateParticipantParams(String divisionId) {
      return CreateParticipantParams(
        divisionId: divisionId,
        firstName: firstName,
        lastName: lastName,
        schoolOrDojangName: schoolOrDojangName,
        beltRank: beltRank,
        dateOfBirth: dateOfBirth,
        gender: gender,
        weightKg: weightKg,
        registrationNumber: registrationNumber,
        notes: notes,
      );
    }
  }
  ```

- [x] **AC10b:** `CSVRowError` (freezed class):
  ```dart
  @freezed
  class CSVRowError with _$CSVRowError {
    const factory CSVRowError({
      required int rowNumber,
      required String fieldName,
      required String errorMessage,
      String? rawValue,
    }) = _CSVRowError;
  }
  ```

- [x] **AC11:** Unit tests verify (use test fixtures from Dev Notes):
  - Standard CSV parsing (all fields)
  - Alternative column headers/aliases (first_name, last_name, etc.)
  - All date formats (ISO, US MM/DD/YYYY, European DD-MM-YYYY)
  - Belt rank normalization (including dan formats: "1st Dan", "Black 2nd Dan")
  - Invalid belt rank detection (Purple, Invalid, etc.)
  - Gender normalization (M, Male, F, Female)
  - Invalid gender detection (X, Unknown, etc.)
  - Missing required columns (no Belt column, etc.)
  - Per-row error collection (multiple errors per row)
  - Empty CSV handling (returns empty result, not error)
  - CSV with only header row (returns empty result)
  - RFC 4180 quoted values (commas within quotes)
  - Escaped quotes within quoted values
  - Weight validation (negative, >150kg)
  - Date validation (future dates, age <4, age >80)
  - Row numbering convention (first data row = Row 1)

- [x] **AC12:** `flutter analyze` passes with zero new errors

- [x] **AC13:** Existing infrastructure UNTOUCHED — no modifications to ParticipantEntity, CreateParticipantUseCase, BeltRank, Gender, or failures

---

## Tasks / Subtasks

### Task 1: Verify Current State (AC: #13)

- [x] 1.1: Verify `CreateParticipantUseCase` validation patterns in `lib/features/participant/domain/usecases/create_participant_usecase.dart`
- [x] 1.2: Verify `BeltRank.fromString()` fallback behavior in `lib/features/division/domain/entities/belt_rank.dart` — returns white, NOT null
- [x] 1.3: Verify `Gender.fromString()` fallback behavior in `lib/features/participant/domain/entities/participant_entity.dart` — returns male, NOT null
- [x] 1.4: Verify Failure types in `lib/core/error/failures.dart`
- [x] 1.5: Verify `CreateParticipantParams` fields in `lib/features/participant/domain/usecases/create_participant_params.dart`
- [x] 1.6: Check if domain/services directory exists in participant feature — create if needed

### Task 2: Create Data Classes (AC: #9, #10)

- [x] 2.1: Create `lib/features/participant/domain/services/csv_row_error.dart` with freezed class
- [x] 2.2: Create `lib/features/participant/domain/services/csv_row_data.dart` with freezed class and `toCreateParticipantParams()` method
- [x] 2.3: Create `lib/features/participant/domain/services/csv_import_result.dart` with freezed class and computed properties

### Task 3: Create CSVParserService (AC: #1, #2, #3, #4, #5, #6, #7, #8)

- [x] 3.1: Create `lib/features/participant/domain/services/csv_parser_service.dart` with `@lazySingleton`
- [x] 3.2: Implement `_columnAliases` map and `_mapColumnName()` helper
- [x] 3.3: Implement `_parseCSVLine()` RFC 4180 parser for quoted values
- [x] 3.4: Implement `_parseDate()` with ISO/US/EU format support
- [x] 3.5: Implement `_tryParseBeltRank()` helper that returns null for invalid (NOT using fromString directly!)
- [x] 3.6: Implement `_tryParseGender()` helper that returns null for invalid (NOT using fromString directly!)
- [x] 3.7: Implement `_validateDateOfBirth()` and `_validateWeight()` helpers
- [x] 3.8: Implement `parseCSV()` main method with per-row error collection
- [x] 3.9: Implement missing required columns detection (returns ValidationFailure)

### Task 4: Update Barrel Files (AC: #13)

- [x] 4.1: Create `lib/features/participant/domain/services/services.dart` barrel file
- [x] 4.2: Update `lib/features/participant/participant.dart` to export services

### Task 5: Run Code Generation (AC: #12)

- [x] 5.1: Run `dart run build_runner build --delete-conflicting-outputs` from `tkd_brackets/`
- [x] 5.2: Verify generated files:
  - `csv_row_error.freezed.dart`
  - `csv_row_data.freezed.dart`
  - `csv_import_result.freezed.dart`

### Task 6: Create Unit Tests (AC: #11)

- [x] 6.1: Create `test/features/participant/domain/services/csv_parser_service_test.dart`
- [x] 6.2: Add test fixtures (standardCSVFixture, quotedValueFixture, etc.)
- [x] 6.3: Test standard CSV parsing (all fields populated)
- [x] 6.4: Test alternative column headers (first_name, school, etc.)
- [x] 6.5: Test ISO date format (YYYY-MM-DD)
- [x] 6.6: Test US date format (MM/DD/YYYY)
- [x] 6.7: Test European date format (DD-MM-YYYY)
- [x] 6.8: Test belt rank normalization (White, Yellow, Black 1st Dan, 2nd Dan)
- [x] 6.9: Test invalid belt rank detection (Purple → error)
- [x] 6.10: Test gender normalization (M, Male, F, Female)
- [x] 6.11: Test invalid gender detection (X → error)
- [x] 6.12: Test missing required columns → ValidationFailure
- [x] 6.13: Test per-row error collection (row with multiple errors)
- [x] 6.14: Test empty CSV → empty result (not error)
- [x] 6.15: Test header-only CSV → empty result
- [x] 6.16: Test RFC 4180 quoted values with commas
- [x] 6.17: Test escaped quotes within quoted values
- [x] 6.18: Test weight validation (negative, >150kg)
- [x] 6.19: Test date validation (future, age <4, age >80)
- [x] 6.20: Test row numbering (first data row = Row 1)

### Task 7: Verify Project Integrity (AC: #12, #13)

- [x] 7.1: Run `flutter analyze` from `tkd_brackets/` — zero new issues
- [x] 7.2: Run `dart run build_runner build --delete-conflicting-outputs` — succeeds
- [x] 7.3: Run all participant tests: `flutter test test/features/participant/` — all pass
- [x] 7.4: Verify existing files unchanged:
  - `participant_entity.dart` — NO CHANGES
  - `create_participant_usecase.dart` — NO CHANGES
  - `create_participant_params.dart` — NO CHANGES
  - `belt_rank.dart` — NO CHANGES
  - `failures.dart` — NO CHANGES

---

## Dev Notes

### Architecture Patterns — MANDATORY

**Service Pattern:**
- Use `@lazySingleton` annotation (stateless utility service)
- Place in `domain/services/` (domain layer, no external dependencies)
- Return `Either<Failure, Result>` pattern
- No Drift, Supabase, or Flutter dependencies in domain layer

**CSV Parsing Approach:**
- No external CSV package needed — use Dart's built-in string handling
- Parse line by line, handle quoted values per RFC 4180
- Skip empty lines
- First row is always header (not counted in row numbers)

**Row Numbering Convention:**
- Header row is NOT counted
- First data row = Row 1
- Row number stored in `CSVRowError.rowNumber` and `CSVRowData.sourceRowNumber`

---

### Column Header Mapping

```dart
static const Map<String, String> _columnAliases = {
  'firstname': 'firstName',
  'first_name': 'firstName',
  'lastname': 'lastName',
  'last_name': 'lastName',
  'dob': 'dateOfBirth',
  'dateofbirth': 'dateOfBirth',
  'date_of_birth': 'dateOfBirth',
  'birthday': 'dateOfBirth',
  'gender': 'gender',
  'sex': 'gender',
  'dojang': 'schoolOrDojangName',
  'school': 'schoolOrDojangName',
  'schoolordojangname': 'schoolOrDojangName',
  'belt': 'beltRank',
  'beltrank': 'beltRank',
  'rank': 'beltRank',
  'weight': 'weightKg',
  'weightkg': 'weightKg',
  'regnumber': 'registrationNumber',
  'registrationnumber': 'registrationNumber',
  'notes': 'notes',
};

String? _mapColumnName(String header) {
  return _columnAliases[header.toLowerCase().trim()];
}
```

---

### ⚠️ CRITICAL: Belt Rank Pre-Validation (DO NOT SKIP)

**`BeltRank.fromString()` returns `BeltRank.white` as fallback for invalid input!**

You MUST use a pre-validation helper that returns `null` for invalid belts:

```dart
/// Returns BeltRank if valid, null if invalid.
/// DO NOT call BeltRank.fromString() directly!
BeltRank? _tryParseBeltRank(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll('-', '')
      .replaceAll(' ', '');

  // Base color belts
  const validBaseBelts = ['white', 'yellow', 'orange', 'green', 'blue', 'red', 'black'];
  if (validBaseBelts.contains(normalized)) {
    return BeltRank.fromString(value);
  }

  // Dan ranks: "1stdan", "2nddan", "black1stdan", "black2nddan", etc.
  // Patterns: "1stdan", "1nddan", "1rddan", "1thdan", "black1stdan"
  final danPattern = RegExp(r'^(black)?([1-9])(st|nd|rd|th)?dan$');
  if (danPattern.hasMatch(normalized)) {
    return BeltRank.black;
  }

  // Invalid belt rank
  return null;
}
```

**Usage in row parsing:**
```dart
final beltRank = _tryParseBeltRank(beltValue);
if (beltRank == null) {
  errors.add(CSVRowError(
    rowNumber: rowNumber,
    fieldName: 'beltRank',
    errorMessage: 'Invalid belt rank. Use: White, Yellow, Orange, Green, Blue, Red, Black, or "Black Nth Dan"',
    rawValue: beltValue,
  ));
}
```

---

### ⚠️ CRITICAL: Gender Pre-Validation (DO NOT SKIP)

**`Gender.fromString()` returns `Gender.male` as fallback for invalid input!**

You MUST use a pre-validation helper that returns `null` for invalid genders:

```dart
/// Returns Gender if valid, null if invalid.
/// DO NOT call Gender.fromString() directly!
Gender? _tryParseGender(String value) {
  final normalized = value.trim().toLowerCase();
  
  switch (normalized) {
    case 'm':
    case 'male':
      return Gender.male;
    case 'f':
    case 'female':
      return Gender.female;
    default:
      return null; // Invalid gender
  }
}
```

**Usage in row parsing:**
```dart
if (genderValue.isNotEmpty) {
  final gender = _tryParseGender(genderValue);
  if (gender == null) {
    errors.add(CSVRowError(
      rowNumber: rowNumber,
      fieldName: 'gender',
      errorMessage: 'Invalid gender. Use: M, Male, F, or Female',
      rawValue: genderValue,
    ));
  }
}
```

---

### Date Parsing Implementation

```dart
/// Parses date in multiple formats. Returns null if unparseable.
DateTime? _parseDate(String value) {
  final trimmed = value.trim();
  
  if (trimmed.isEmpty) return null;

  // Try ISO format: YYYY-MM-DD (preferred)
  final isoRegex = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  if (isoRegex.hasMatch(trimmed)) {
    return DateTime.tryParse(trimmed);
  }
  
  // Try US format: MM/DD/YYYY
  final usRegex = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
  final usMatch = usRegex.firstMatch(trimmed);
  if (usMatch != null) {
    final month = int.parse(usMatch.group(1)!);
    final day = int.parse(usMatch.group(2)!);
    final year = int.parse(usMatch.group(3)!);
    final parsed = DateTime.tryParse(
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
    );
    if (parsed != null && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
      return parsed;
    }
  }
  
  // Try European format: DD-MM-YYYY
  final euRegex = RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$');
  final euMatch = euRegex.firstMatch(trimmed);
  if (euMatch != null) {
    final day = int.parse(euMatch.group(1)!);
    final month = int.parse(euMatch.group(2)!);
    final year = int.parse(euMatch.group(3)!);
    final parsed = DateTime.tryParse(
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
    );
    if (parsed != null && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
      return parsed;
    }
  }
  
  return null;
}

/// Validates date of birth: not future, age 4-80.
/// Returns error message if invalid, null if valid.
String? _validateDateOfBirth(DateTime dateOfBirth) {
  final now = DateTime.now();
  
  if (dateOfBirth.isAfter(now)) {
    return 'Date of birth cannot be in the future';
  }
  
  final age = _calculateAge(dateOfBirth);
  if (age < 4 || age > 80) {
    return 'Participant age must be between 4 and 80 years (calculated: $age)';
  }
  
  return null;
}

int _calculateAge(DateTime dateOfBirth) {
  final now = DateTime.now();
  var age = now.year - dateOfBirth.year;
  if (now.month < dateOfBirth.month ||
      (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
    age--;
  }
  return age;
}
```

---

### ⚠️ CRITICAL: RFC 4180 Quoted CSV Value Parsing

CSV values containing commas MUST be properly handled. Do NOT simply split on commas.

```dart
/// Parses a single CSV line, handling quoted values per RFC 4180.
/// 
/// Rules:
/// - Fields containing commas, quotes, or newlines must be quoted
/// - Quotes within quoted fields are escaped by doubling ("")
/// - Empty fields become empty strings
List<String> _parseCSVLine(String line) {
  final result = <String>[];
  var current = StringBuffer();
  var inQuotes = false;
  
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    
    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        // Escaped quote - add single quote and skip next
        current.write('"');
        i++;
      } else {
        // Toggle quote mode
        inQuotes = !inQuotes;
      }
    } else if (char == ',' && !inQuotes) {
      // Field separator (only outside quotes)
      result.add(current.toString().trim());
      current = StringBuffer();
    } else {
      current.write(char);
    }
  }
  
  // Add final field
  result.add(current.toString().trim());
  
  return result;
}
```

**Example CSV with quoted values:**
```csv
FirstName,LastName,Dojang,Belt,Notes
John,"Smith, Jr.",Kim's TKD,Blue,"Allergy: peanuts, shellfish"
Jane,O'Brien,Elite TKD,Green,"Uses ""nickname"" in competition"
```

---

### Weight Validation

```dart
/// Validates weight in kg. Returns error message if invalid, null if valid.
String? _validateWeight(double weightKg) {
  if (weightKg < 0) {
    return 'Weight cannot be negative';
  }
  if (weightKg > 150) {
    return 'Weight exceeds maximum allowed (150kg)';
  }
  return null;
}
```

---

### File Structure After This Story

```
lib/features/participant/
├── participant.dart                                    ← Updated barrel
├── domain/
│   ├── entities/                                       ← Unchanged
│   ├── repositories/                                   ← Unchanged
│   ├── usecases/                                       ← Unchanged
│   └── services/
│       ├── services.dart                               ← NEW barrel
│       ├── csv_parser_service.dart                     ← NEW
│       ├── csv_import_result.dart                      ← NEW
│       ├── csv_import_result.freezed.dart              ← GENERATED
│       ├── csv_row_data.dart                           ← NEW
│       ├── csv_row_data.freezed.dart                   ← GENERATED
│       ├── csv_row_error.dart                          ← NEW
│       └── csv_row_error.freezed.dart                  ← GENERATED
├── data/                                               ← Unchanged
└── presentation/                                       ← Empty (Story 4.12)
```

---

### Sample CSV Format

```csv
FirstName,LastName,DOB,Gender,Dojang,Belt,Weight,RegNumber,Notes
John,Smith,2010-05-15,M,Kim's TKD,Blue,45.5,,
Jane,Doe,2012-08-22,F,Elite TKD,Green,38.0,REG001,Allergy note
Mike,Johnson,2008-03-10,M,Champion TKD,Black 1st Dan,55.0,,
```

**With quoted values:**
```csv
FirstName,LastName,Dojang,Belt,Notes
John,"Smith, Jr.",Kim's TKD,Blue,"Allergy: peanuts"
```

---

### Test Fixtures (Use in Unit Tests)

```dart
// Standard CSV with all fields
const standardCSVFixture = '''FirstName,LastName,DOB,Gender,Dojang,Belt,Weight,RegNumber,Notes
John,Smith,2010-05-15,M,Kim's TKD,Blue,45.5,,
Jane,Doe,2012-08-22,F,Elite TKD,Green,38.0,REG001,Allergy note''';

// Alternative column headers
const alternateHeadersFixture = '''first_name,last_name,birthday,sex,school,rank,weight_kg
Jane,Doe,2012-08-22,F,Elite TKD,Green,38.0''';

// CSV with quoted values containing commas
const quotedValueFixture = '''FirstName,LastName,Dojang,Belt,Notes
John,"Smith, Jr.",Kim's TKD,Blue,"Allergy: peanuts, shellfish"''';

// CSV with escaped quotes
const escapedQuotesFixture = '''FirstName,LastName,Dojang,Belt,Notes
Jane,O'Brien,Elite TKD,Green,"Uses ""nickname"" in competition"''';

// US date format
const usDateFormatFixture = '''FirstName,LastName,DOB,Dojang,Belt
John,Smith,05/15/2010,Kim's TKD,Blue''';

// European date format
const euDateFormatFixture = '''FirstName,LastName,DOB,Dojang,Belt
Hans,Mueller,15-05-2010,Berlin TKD,Blue''';

// Missing required columns (should fail)
const missingColumnsFixture = '''FirstName,LastName,Dojang
John,Smith,Kim's TKD''';

// Header only (no data rows)
const headerOnlyFixture = '''FirstName,LastName,DOB,Gender,Dojang,Belt,Weight,RegNumber,Notes''';

// Empty CSV
const emptyCSVFixture = '';

// Invalid belt rank
const invalidBeltFixture = '''FirstName,LastName,Dojang,Belt
John,Smith,Kim's TKD,Purple''';

// Invalid gender
const invalidGenderFixture = '''FirstName,LastName,Gender,Dojang,Belt
John,Smith,X,Kim's TKD,Blue''';

// Multiple errors per row
const multipleErrorsFixture = '''FirstName,LastName,DOB,Gender,Dojang,Belt
,Smith,2099-01-01,X,,Purple''';

// Various dan formats (all valid)
const danFormatsFixture = '''FirstName,LastName,Dojang,Belt
John,Smith,Kim's TKD,Black 1st Dan
Jane,Doe,Elite TKD,2nd Dan
Mike,Johnson,Champion TKD,Black 3rd Dan''';
```

---

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 4, Story 4.4]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Clean Architecture, Service Pattern]
- [Source: `_bmad-output/implementation-artifacts/4-3-manual-participant-entry.md` — Previous story, validation patterns]
- [Source: `tkd_brackets/lib/features/participant/domain/usecases/create_participant_usecase.dart` — Validation logic reference]
- [Source: `tkd_brackets/lib/features/division/domain/entities/belt_rank.dart` — BeltRank.fromString() with fallback]
- [Source: `tkd_brackets/lib/features/participant/domain/entities/participant_entity.dart` — Gender.fromString() with fallback]
- [Source: `tkd_brackets/lib/core/error/failures.dart` — ValidationFailure, InputValidationFailure]
- [Source: RFC 4180 — CSV format specification for quoted values]

---

## Anti-Patterns — WHAT NOT TO DO

| ❌ Don't Do This | ✅ Do This Instead | Source |
|-----------------|---------------------|--------|
| Import external CSV package | Use Dart's built-in string handling | Keep dependencies minimal |
| Place service in data layer | Place in domain/services/ | Clean Architecture |
| Use `@injectable` for service | Use `@lazySingleton` for stateless service | DI pattern |
| Fail entire import on one bad row | Collect errors per-row, continue parsing | AC8 |
| Hardcode column names | Use flexible mapping with aliases | AC4 |
| Skip belt rank validation | Use `_tryParseBeltRank()` helper that returns null for invalid | Critical for seeding |
| Call `BeltRank.fromString()` directly | Use `_tryParseBeltRank()` — fromString returns white as fallback! | AC6 |
| Call `Gender.fromString()` directly | Use `_tryParseGender()` — fromString returns male as fallback! | AC7 |
| Create new Gender/BeltRank enums | Reuse existing enums with pre-validation helpers | Don't reinvent |
| Import Flutter or Drift in domain | Domain layer = pure Dart only | Architecture |
| Split CSV on comma without handling quotes | Use `_parseCSVLine()` RFC 4180 parser | CSV spec |
| Only collect first error per field | Collect ALL validation errors per row | AC8 |
| Assume row numbers start at 0 | First data row = Row 1 (header not counted) | AC8 |
| Return belt rank string from service | Return `BeltRank` enum, convert to string via `.name` | Type safety |

---

## Previous Story Intelligence

### From Story 4.3: Manual Participant Entry

**Key Learnings:**
1. **Validation pattern:** Collect errors in Map, return InputValidationFailure with fieldErrors
2. **Belt rank validation:** Use normalization (lowercase, no spaces/hyphens) and match against valid belts
3. **Date validation:** Check future dates, calculate age, validate 4-80 range
4. **Weight validation:** 0-150kg range
5. **Required fields:** firstName, lastName, schoolOrDojangName, beltRank
6. **Optional fields:** dateOfBirth, gender, weightKg, registrationNumber, notes
7. **Failure types:** ValidationFailure for general errors, InputValidationFailure for field-specific

**Constants from CreateParticipantUseCase (reuse these):**
```dart
static const int minAge = 4;
static const int maxAge = 80;
static const double maxWeightKg = 150;
```

### From Story 4.2: Participant Entity & Repository

**Key Learnings:**
1. **DI Registration:** Use `@lazySingleton` for services/repositories
2. **Freezed pattern:** Entity uses `@freezed` with `const factory` constructor
3. **Enum fallbacks:** Both `BeltRank.fromString()` and `Gender.fromString()` return fallback values, NOT null

### From Story 3.3: Create Tournament Use Case

**Key Learnings:**
1. **Use case pattern:** `@injectable`, extends `UseCase<Entity, Params>`
2. **Validation returns:** `Left(InputValidationFailure(...))` with `fieldErrors` map
3. **Organization verification:** Always verify resources belong to user's organization

---

## Dev Agent Record

### Agent Model Used

opencode/glm-5-free

### Debug Log References

None required.

### Completion Notes List

- Created CSVParserService with @lazySingleton annotation in domain/services/
- Implemented full RFC 4180 CSV parsing with quoted value support
- Added date parsing for ISO, US (MM/DD/YYYY), and European (DD-MM-YYYY) formats
- Implemented belt rank pre-validation with _tryParseBeltRank() helper (returns null for invalid instead of fallback)
- Implemented gender pre-validation with _tryParseGender() helper (returns null for invalid instead of fallback)
- Added per-row error collection with CSVRowError tracking
- Created CSVImportResult, CSVRowData, and CSVRowError freezed classes
- Added 27 comprehensive unit tests covering all AC requirements
- All 103 participant tests pass
- Zero new lint errors in new code

### File List

**New Files:**
- `tkd_brackets/lib/features/participant/domain/services/csv_parser_service.dart`
- `tkd_brackets/lib/features/participant/domain/services/csv_import_result.dart`
- `tkd_brackets/lib/features/participant/domain/services/csv_import_result.freezed.dart` (generated)
- `tkd_brackets/lib/features/participant/domain/services/csv_row_data.dart`
- `tkd_brackets/lib/features/participant/domain/services/csv_row_data.freezed.dart` (generated)
- `tkd_brackets/lib/features/participant/domain/services/csv_row_error.dart`
- `tkd_brackets/lib/features/participant/domain/services/csv_row_error.freezed.dart` (generated)
- `tkd_brackets/lib/features/participant/domain/services/services.dart`
- `tkd_brackets/test/features/participant/domain/services/csv_parser_service_test.dart`

**Modified Files:**
- `tkd_brackets/lib/features/participant/participant.dart` (added services export)

---

## Senior Developer Review (AI)

**Reviewer:** opencode/glm-5-free
**Date:** 2026-02-21

### Review Outcome: ✅ APPROVED

All Acceptance Criteria verified. Code quality review found minor issues, all fixed.

### Issues Found & Fixed

| # | Severity | Issue | Resolution |
|---|----------|-------|------------|
| 1 | MEDIUM | Dead code: `_buildColumnMap()` method defined but never called | Removed |
| 2 | MEDIUM | Unused parameter `divisionId` not documented | Added doc comment |
| 3 | MEDIUM | RFC 4180 multiline limitation not documented | Added to class docs |
| 4 | MEDIUM | Test assertion imprecise (`greaterThanOrEqualTo(4)` vs exact count) | Fixed to `equals(5)` |
| 5 | LOW | Missing class-level documentation | Added comprehensive docs |
| 6 | LOW | No test for row with fewer columns than headers | Added edge case test |
| 7 | LOW | Duplicated constants not documented | Added comment |

### Final Verification

- ✅ `flutter analyze` — 0 issues
- ✅ All 28 tests pass (27 original + 1 new edge case)
- ✅ Existing infrastructure unchanged (verified via git diff)
- ✅ All ACs implemented correctly
