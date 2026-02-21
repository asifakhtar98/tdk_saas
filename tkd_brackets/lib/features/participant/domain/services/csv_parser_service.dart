import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/division/domain/entities/belt_rank.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_import_result.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_row_data.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_row_error.dart';

/// Parses CSV content into validated participant data with per-row
/// error collection.
///
/// Supports standard CSV column headers (case-insensitive) with flexible
/// aliases. Handles RFC 4180 quoted values but does NOT support multiline
/// fields (newlines within quoted values).
///
/// The divisionId parameter is passed through to CSVRowData's
/// toCreateParticipantParams for downstream use case invocation.
@lazySingleton
class CSVParserService {
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
    'weight_kg': 'weightKg',
    'regnumber': 'registrationNumber',
    'registrationnumber': 'registrationNumber',
    'notes': 'notes',
  };

  /// Validation constants (mirrored from CreateParticipantUseCase
  /// for domain isolation).
  static const int minAge = 4;
  static const int maxAge = 80;
  static const double maxWeightKg = 150;

  Future<Either<Failure, CSVImportResult>> parseCSV({
    required String csvContent,
    required String divisionId,
  }) async {
    if (csvContent.trim().isEmpty) {
      return const Right(
        CSVImportResult(validRows: [], errors: [], totalRows: 0),
      );
    }

    final lines = _splitLines(csvContent);
    if (lines.isEmpty) {
      return const Right(
        CSVImportResult(validRows: [], errors: [], totalRows: 0),
      );
    }

    final headerLine = lines.first;
    final headers = _parseCSVLine(headerLine);
    final normalizedHeaders = headers.map(_mapColumnName).toSet();

    final requiredColumns = [
      'firstName',
      'lastName',
      'schoolOrDojangName',
      'beltRank',
    ];
    final missingColumns = requiredColumns
        .where((col) => !normalizedHeaders.contains(col))
        .toList();

    if (missingColumns.isNotEmpty) {
      return Left(
        ValidationFailure(
          userFriendlyMessage:
              'Missing required columns: ${missingColumns.join(', ')}',
          fieldErrors: {
            for (final col in missingColumns) col: 'Column is required',
          },
        ),
      );
    }

    final validRows = <CSVRowData>[];
    final errors = <CSVRowError>[];
    var totalRows = 0;

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      totalRows++;
      final rowNumber = totalRows;
      final values = _parseCSVLine(line);
      final rowErrors = <CSVRowError>[];
      final rowData = <String, dynamic>{};

      for (var j = 0; j < headers.length && j < values.length; j++) {
        final normalizedHeader = _mapColumnName(headers[j]);
        if (normalizedHeader != null) {
          rowData[normalizedHeader] = values[j];
        }
      }

      final firstName = (rowData['firstName'] as String?)?.trim() ?? '';
      final lastName = (rowData['lastName'] as String?)?.trim() ?? '';
      final schoolOrDojangName =
          (rowData['schoolOrDojangName'] as String?)?.trim() ?? '';
      final beltRankRaw = (rowData['beltRank'] as String?)?.trim() ?? '';

      if (firstName.isEmpty) {
        rowErrors.add(
          CSVRowError(
            rowNumber: rowNumber,
            fieldName: 'firstName',
            errorMessage: 'First name is required',
            rawValue: null,
          ),
        );
      }

      if (lastName.isEmpty) {
        rowErrors.add(
          CSVRowError(
            rowNumber: rowNumber,
            fieldName: 'lastName',
            errorMessage: 'Last name is required',
            rawValue: null,
          ),
        );
      }

      if (schoolOrDojangName.isEmpty) {
        rowErrors.add(
          CSVRowError(
            rowNumber: rowNumber,
            fieldName: 'schoolOrDojangName',
            errorMessage: 'Dojang name is required',
            rawValue: null,
          ),
        );
      }

      final beltRank = _tryParseBeltRank(beltRankRaw);
      if (beltRankRaw.isEmpty) {
        rowErrors.add(
          CSVRowError(
            rowNumber: rowNumber,
            fieldName: 'beltRank',
            errorMessage: 'Belt rank is required',
            rawValue: null,
          ),
        );
      } else if (beltRank == null) {
        rowErrors.add(
          CSVRowError(
            rowNumber: rowNumber,
            fieldName: 'beltRank',
            errorMessage:
                'Invalid belt rank. Use: White, Yellow, Orange, Green, '
                'Blue, Red, Black, or "Black Nth Dan"',
            rawValue: beltRankRaw,
          ),
        );
      }

      DateTime? dateOfBirth;
      final dobRaw = (rowData['dateOfBirth'] as String?)?.trim() ?? '';
      if (dobRaw.isNotEmpty) {
        dateOfBirth = _parseDate(dobRaw);
        if (dateOfBirth == null) {
          rowErrors.add(
            CSVRowError(
              rowNumber: rowNumber,
              fieldName: 'dateOfBirth',
              errorMessage:
                  'Invalid date format. Use YYYY-MM-DD, MM/DD/YYYY, or DD-MM-YYYY',
              rawValue: dobRaw,
            ),
          );
        } else {
          final dobError = _validateDateOfBirth(dateOfBirth);
          if (dobError != null) {
            rowErrors.add(
              CSVRowError(
                rowNumber: rowNumber,
                fieldName: 'dateOfBirth',
                errorMessage: dobError,
                rawValue: dobRaw,
              ),
            );
            dateOfBirth = null;
          }
        }
      }

      Gender? gender;
      final genderRaw = (rowData['gender'] as String?)?.trim() ?? '';
      if (genderRaw.isNotEmpty) {
        gender = _tryParseGender(genderRaw);
        if (gender == null) {
          rowErrors.add(
            CSVRowError(
              rowNumber: rowNumber,
              fieldName: 'gender',
              errorMessage: 'Invalid gender. Use: M, Male, F, or Female',
              rawValue: genderRaw,
            ),
          );
        }
      }

      double? weightKg;
      final weightRaw = (rowData['weightKg'] as String?)?.trim() ?? '';
      if (weightRaw.isNotEmpty) {
        weightKg = double.tryParse(weightRaw);
        if (weightKg == null) {
          rowErrors.add(
            CSVRowError(
              rowNumber: rowNumber,
              fieldName: 'weightKg',
              errorMessage: 'Invalid weight value',
              rawValue: weightRaw,
            ),
          );
        } else {
          final weightError = _validateWeight(weightKg);
          if (weightError != null) {
            rowErrors.add(
              CSVRowError(
                rowNumber: rowNumber,
                fieldName: 'weightKg',
                errorMessage: weightError,
                rawValue: weightRaw,
              ),
            );
            weightKg = null;
          }
        }
      }

      final registrationNumber = (rowData['registrationNumber'] as String?)
          ?.trim();
      final notes = (rowData['notes'] as String?)?.trim();

      if (rowErrors.isEmpty && beltRank != null) {
        validRows.add(
          CSVRowData(
            firstName: firstName,
            lastName: lastName,
            schoolOrDojangName: schoolOrDojangName,
            beltRank: beltRank.name,
            sourceRowNumber: rowNumber,
            dateOfBirth: dateOfBirth,
            gender: gender,
            weightKg: weightKg,
            registrationNumber: (registrationNumber?.isNotEmpty ?? false)
                ? registrationNumber
                : null,
            notes: (notes?.isNotEmpty ?? false) ? notes : null,
          ),
        );
      } else {
        errors.addAll(rowErrors);
      }
    }

    return Right(
      CSVImportResult(
        validRows: validRows,
        errors: errors,
        totalRows: totalRows,
      ),
    );
  }

  List<String> _splitLines(String content) {
    return content
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();
  }

  String? _mapColumnName(String header) {
    return _columnAliases[header.toLowerCase().trim()];
  }

  List<String> _parseCSVLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }

    result.add(current.toString().trim());
    return result;
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) return null;

    final isoRegex = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    if (isoRegex.hasMatch(trimmed)) {
      return DateTime.tryParse(trimmed);
    }

    final usRegex = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
    final usMatch = usRegex.firstMatch(trimmed);
    if (usMatch != null) {
      final month = int.parse(usMatch.group(1)!);
      final day = int.parse(usMatch.group(2)!);
      final year = int.parse(usMatch.group(3)!);
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        final parsed = DateTime.tryParse(
          '$year-'
          '${month.toString().padLeft(2, '0')}-'
          '${day.toString().padLeft(2, '0')}',
        );
        return parsed;
      }
    }

    final euRegex = RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$');
    final euMatch = euRegex.firstMatch(trimmed);
    if (euMatch != null) {
      final day = int.parse(euMatch.group(1)!);
      final month = int.parse(euMatch.group(2)!);
      final year = int.parse(euMatch.group(3)!);
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        final parsed = DateTime.tryParse(
          '$year-'
          '${month.toString().padLeft(2, '0')}-'
          '${day.toString().padLeft(2, '0')}',
        );
        return parsed;
      }
    }

    return null;
  }

  BeltRank? _tryParseBeltRank(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll('-', '')
        .replaceAll(' ', '');

    const validBaseBelts = [
      'white',
      'yellow',
      'orange',
      'green',
      'blue',
      'red',
      'black',
    ];
    if (validBaseBelts.contains(normalized)) {
      return BeltRank.fromString(value);
    }

    final danPattern = RegExp(r'^(black)?([1-9])(st|nd|rd|th)?dan$');
    if (danPattern.hasMatch(normalized)) {
      return BeltRank.black;
    }

    return null;
  }

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
        return null;
    }
  }

  String? _validateDateOfBirth(DateTime dateOfBirth) {
    final now = DateTime.now();

    if (dateOfBirth.isAfter(now)) {
      return 'Date of birth cannot be in the future';
    }

    final age = _calculateAge(dateOfBirth);
    if (age < minAge || age > maxAge) {
      return 'Participant age must be between $minAge and $maxAge years '
          '(calculated: $age)';
    }

    return null;
  }

  String? _validateWeight(double weightKg) {
    if (weightKg < 0) {
      return 'Weight cannot be negative';
    }
    if (weightKg > maxWeightKg) {
      return 'Weight exceeds maximum allowed (${maxWeightKg}kg)';
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
}
