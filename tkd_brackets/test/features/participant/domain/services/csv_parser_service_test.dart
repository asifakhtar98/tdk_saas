import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/division/domain/entities/belt_rank.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_import_result.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_parser_service.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_row_data.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_row_error.dart';

void main() {
  late CSVParserService service;

  setUp(() {
    service = CSVParserService();
  });

  const standardCSVFixture =
      '''FirstName,LastName,DOB,Gender,Dojang,Belt,Weight,RegNumber,Notes
John,Smith,2010-05-15,M,Kim's TKD,Blue,45.5,,
Jane,Doe,2012-08-22,F,Elite TKD,Green,38.0,REG001,Allergy note''';

  const alternateHeadersFixture =
      '''first_name,last_name,birthday,sex,school,rank,weight_kg
Jane,Doe,2012-08-22,F,Elite TKD,Green,38.0''';

  const quotedValueFixture = '''FirstName,LastName,Dojang,Belt,Notes
John,"Smith, Jr.",Kim's TKD,Blue,"Allergy: peanuts, shellfish"''';

  const escapedQuotesFixture = '''FirstName,LastName,Dojang,Belt,Notes
Jane,O'Brien,Elite TKD,Green,"Uses ""nickname"" in competition"''';

  const usDateFormatFixture = '''FirstName,LastName,DOB,Dojang,Belt
John,Smith,05/15/2010,Kim's TKD,Blue''';

  const euDateFormatFixture = '''FirstName,LastName,DOB,Dojang,Belt
Hans,Mueller,15-05-2010,Berlin TKD,Blue''';

  const missingColumnsFixture = '''FirstName,LastName,Dojang
John,Smith,Kim's TKD''';

  const headerOnlyFixture =
      '''FirstName,LastName,DOB,Gender,Dojang,Belt,Weight,RegNumber,Notes''';

  const emptyCSVFixture = '';

  const invalidBeltFixture = '''FirstName,LastName,Dojang,Belt
John,Smith,Kim's TKD,Purple''';

  const invalidGenderFixture = '''FirstName,LastName,Gender,Dojang,Belt
John,Smith,X,Kim's TKD,Blue''';

  const multipleErrorsFixture = '''FirstName,LastName,DOB,Gender,Dojang,Belt
,Smith,2099-01-01,X,,Purple''';

  const danFormatsFixture = '''FirstName,LastName,Dojang,Belt
John,Smith,Kim's TKD,Black 1st Dan
Jane,Doe,Elite TKD,2nd Dan
Mike,Johnson,Champion TKD,Black 3rd Dan''';

  group('standard CSV parsing', () {
    test('parses standard CSV with all fields', () async {
      final result = await service.parseCSV(
        csvContent: standardCSVFixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.totalRows, equals(2));
        expect(importResult.successCount, equals(2));
        expect(importResult.errorCount, equals(0));
        expect(importResult.validRows[0].firstName, equals('John'));
        expect(importResult.validRows[0].lastName, equals('Smith'));
        expect(
          importResult.validRows[0].schoolOrDojangName,
          equals("Kim's TKD"),
        );
        expect(importResult.validRows[0].beltRank, equals('blue'));
        expect(
          importResult.validRows[0].dateOfBirth,
          equals(DateTime(2010, 5, 15)),
        );
        expect(importResult.validRows[0].gender, equals(Gender.male));
        expect(importResult.validRows[0].weightKg, equals(45.5));
        expect(importResult.validRows[1].registrationNumber, equals('REG001'));
        expect(importResult.validRows[1].notes, equals('Allergy note'));
      });
    });
  });

  group('alternative column headers', () {
    test('parses CSV with alternative column headers', () async {
      final result = await service.parseCSV(
        csvContent: alternateHeadersFixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.successCount, equals(1));
        expect(importResult.validRows[0].firstName, equals('Jane'));
        expect(importResult.validRows[0].lastName, equals('Doe'));
        expect(
          importResult.validRows[0].schoolOrDojangName,
          equals('Elite TKD'),
        );
        expect(importResult.validRows[0].beltRank, equals('green'));
        expect(
          importResult.validRows[0].dateOfBirth,
          equals(DateTime(2012, 8, 22)),
        );
        expect(importResult.validRows[0].gender, equals(Gender.female));
        expect(importResult.validRows[0].weightKg, equals(38.0));
      });
    });
  });

  group('date format parsing', () {
    test('parses ISO date format YYYY-MM-DD', () async {
      final result = await service.parseCSV(
        csvContent: standardCSVFixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(
          importResult.validRows[0].dateOfBirth,
          equals(DateTime(2010, 5, 15)),
        );
      });
    });

    test('parses US date format MM/DD/YYYY', () async {
      final result = await service.parseCSV(
        csvContent: usDateFormatFixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(
          importResult.validRows[0].dateOfBirth,
          equals(DateTime(2010, 5, 15)),
        );
      });
    });

    test('parses European date format DD-MM-YYYY', () async {
      final result = await service.parseCSV(
        csvContent: euDateFormatFixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(
          importResult.validRows[0].dateOfBirth,
          equals(DateTime(2010, 5, 15)),
        );
      });
    });
  });

  group('belt rank normalization', () {
    test('normalizes standard belt ranks', () async {
      const fixture = '''FirstName,LastName,Dojang,Belt
John,Smith,Kim's TKD,White
Jane,Doe,Elite TKD,Yellow
Bob,Jones,Test TKD,Green
Alice,Wong,Test TKD,Blue
Tom,Lee,Test TKD,Red
Sam,Kim,Test TKD,Black''';

      final result = await service.parseCSV(
        csvContent: fixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.successCount, equals(6));
        expect(importResult.validRows[0].beltRank, equals('white'));
        expect(importResult.validRows[1].beltRank, equals('yellow'));
        expect(importResult.validRows[2].beltRank, equals('green'));
        expect(importResult.validRows[3].beltRank, equals('blue'));
        expect(importResult.validRows[4].beltRank, equals('red'));
        expect(importResult.validRows[5].beltRank, equals('black'));
      });
    });

    test('parses dan formats (1st Dan, 2nd Dan, Black 3rd Dan)', () async {
      final result = await service.parseCSV(
        csvContent: danFormatsFixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.successCount, equals(3));
        expect(importResult.validRows[0].beltRank, equals('black'));
        expect(importResult.validRows[1].beltRank, equals('black'));
        expect(importResult.validRows[2].beltRank, equals('black'));
      });
    });

    test('detects invalid belt ranks', () async {
      final result = await service.parseCSV(
        csvContent: invalidBeltFixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.errorCount, equals(1));
        expect(importResult.errors[0].fieldName, equals('beltRank'));
        expect(importResult.errors[0].rawValue, equals('Purple'));
      });
    });
  });

  group('gender normalization', () {
    test('normalizes gender values (M, Male, F, Female)', () async {
      const fixture = '''FirstName,LastName,Gender,Dojang,Belt
John,Smith,M,Kim's TKD,Blue
Jane,Doe,Male,Elite TKD,Green
Bob,Jones,F,Test TKD,Blue
Alice,Wong,Female,Test TKD,Green''';

      final result = await service.parseCSV(
        csvContent: fixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.successCount, equals(4));
        expect(importResult.validRows[0].gender, equals(Gender.male));
        expect(importResult.validRows[1].gender, equals(Gender.male));
        expect(importResult.validRows[2].gender, equals(Gender.female));
        expect(importResult.validRows[3].gender, equals(Gender.female));
      });
    });

    test('detects invalid gender values', () async {
      final result = await service.parseCSV(
        csvContent: invalidGenderFixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.errorCount, equals(1));
        expect(importResult.errors[0].fieldName, equals('gender'));
        expect(importResult.errors[0].rawValue, equals('X'));
      });
    });
  });

  group('missing required columns', () {
    test(
      'returns ValidationFailure when required columns are missing',
      () async {
        final result = await service.parseCSV(
          csvContent: missingColumnsFixture,
          divisionId: 'division-1',
        );

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          final validationFailure = failure as ValidationFailure;
          expect(
            validationFailure.userFriendlyMessage,
            contains('Missing required columns'),
          );
          expect(validationFailure.fieldErrors!.keys, contains('beltRank'));
        }, (importResult) => fail('Should fail with ValidationFailure'));
      },
    );
  });

  group('per-row error collection', () {
    test('collects multiple errors per row', () async {
      final result = await service.parseCSV(
        csvContent: multipleErrorsFixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.errorCount, equals(5));
        final fieldNames = importResult.errors.map((e) => e.fieldName).toList();
        expect(fieldNames, contains('firstName'));
        expect(fieldNames, contains('dateOfBirth'));
        expect(fieldNames, contains('gender'));
        expect(fieldNames, contains('schoolOrDojangName'));
        expect(fieldNames, contains('beltRank'));
      });
    });
  });

  group('empty CSV handling', () {
    test('returns empty result for empty CSV', () async {
      final result = await service.parseCSV(
        csvContent: emptyCSVFixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.isEmpty, isTrue);
        expect(importResult.totalRows, equals(0));
        expect(importResult.successCount, equals(0));
        expect(importResult.errorCount, equals(0));
      });
    });

    test('returns empty result for header-only CSV', () async {
      final result = await service.parseCSV(
        csvContent: headerOnlyFixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.isEmpty, isTrue);
        expect(importResult.totalRows, equals(0));
        expect(importResult.successCount, equals(0));
      });
    });
  });

  group('RFC 4180 quoted values', () {
    test('handles quoted values with commas', () async {
      final result = await service.parseCSV(
        csvContent: quotedValueFixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.successCount, equals(1));
        expect(importResult.validRows[0].lastName, equals('Smith, Jr.'));
        expect(
          importResult.validRows[0].notes,
          equals('Allergy: peanuts, shellfish'),
        );
      });
    });

    test('handles escaped quotes within quoted values', () async {
      final result = await service.parseCSV(
        csvContent: escapedQuotesFixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.successCount, equals(1));
        expect(
          importResult.validRows[0].notes,
          equals('Uses "nickname" in competition'),
        );
      });
    });
  });

  group('weight validation', () {
    test('rejects negative weight', () async {
      const fixture = '''FirstName,LastName,Dojang,Belt,Weight
John,Smith,Kim's TKD,Blue,-10''';

      final result = await service.parseCSV(
        csvContent: fixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.errorCount, equals(1));
        expect(importResult.errors[0].fieldName, equals('weightKg'));
        expect(importResult.errors[0].errorMessage, contains('negative'));
      });
    });

    test('rejects weight exceeding 150kg', () async {
      const fixture = '''FirstName,LastName,Dojang,Belt,Weight
John,Smith,Kim's TKD,Blue,200''';

      final result = await service.parseCSV(
        csvContent: fixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.errorCount, equals(1));
        expect(importResult.errors[0].fieldName, equals('weightKg'));
        expect(importResult.errors[0].errorMessage, contains('maximum'));
      });
    });
  });

  group('date validation', () {
    test('rejects future dates', () async {
      const fixture = '''FirstName,LastName,DOB,Dojang,Belt
John,Smith,2099-01-01,Kim's TKD,Blue''';

      final result = await service.parseCSV(
        csvContent: fixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.errorCount, equals(1));
        expect(importResult.errors[0].fieldName, equals('dateOfBirth'));
        expect(importResult.errors[0].errorMessage, contains('future'));
      });
    });

    test('rejects age below 4', () async {
      final now = DateTime.now();
      final tooYoung = DateTime(now.year - 2, now.month, now.day);
      final dobStr =
          '${tooYoung.year}-${tooYoung.month.toString().padLeft(2, '0')}-${tooYoung.day.toString().padLeft(2, '0')}';
      final fixture = '''FirstName,LastName,DOB,Dojang,Belt
John,Smith,$dobStr,Kim's TKD,Blue''';

      final result = await service.parseCSV(
        csvContent: fixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.errorCount, equals(1));
        expect(importResult.errors[0].fieldName, equals('dateOfBirth'));
        expect(importResult.errors[0].errorMessage, contains('4'));
      });
    });

    test('rejects age above 80', () async {
      final now = DateTime.now();
      final tooOld = DateTime(now.year - 85, now.month, now.day);
      final dobStr =
          '${tooOld.year}-${tooOld.month.toString().padLeft(2, '0')}-${tooOld.day.toString().padLeft(2, '0')}';
      final fixture = '''FirstName,LastName,DOB,Dojang,Belt
John,Smith,$dobStr,Kim's TKD,Blue''';

      final result = await service.parseCSV(
        csvContent: fixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.errorCount, equals(1));
        expect(importResult.errors[0].fieldName, equals('dateOfBirth'));
        expect(importResult.errors[0].errorMessage, contains('80'));
      });
    });
  });

  group('row numbering convention', () {
    test('first data row is numbered as Row 1', () async {
      final result = await service.parseCSV(
        csvContent: standardCSVFixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.validRows[0].sourceRowNumber, equals(1));
        expect(importResult.validRows[1].sourceRowNumber, equals(2));
      });
    });

    test('error row numbers start at 1', () async {
      final result = await service.parseCSV(
        csvContent: invalidBeltFixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.errors[0].rowNumber, equals(1));
      });
    });
  });

  group('edge cases', () {
    test('handles row with fewer columns than headers', () async {
      const fixture = '''FirstName,LastName,Dojang,Belt,Notes
John,Smith,Kim's TKD,Blue''';

      final result = await service.parseCSV(
        csvContent: fixture,
        divisionId: 'division-1',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (importResult) {
        expect(importResult.successCount, equals(1));
        expect(importResult.validRows[0].firstName, equals('John'));
        expect(importResult.validRows[0].notes, isNull);
      });
    });
  });

  group('CSVImportResult', () {
    test('computed properties work correctly', () {
      final result = CSVImportResult(
        validRows: [
          CSVRowData(
            firstName: 'John',
            lastName: 'Smith',
            schoolOrDojangName: "Kim's TKD",
            beltRank: 'blue',
            sourceRowNumber: 1,
          ),
        ],
        errors: [
          const CSVRowError(
            rowNumber: 2,
            fieldName: 'beltRank',
            errorMessage: 'Invalid belt rank',
          ),
        ],
        totalRows: 2,
      );

      expect(result.successCount, equals(1));
      expect(result.errorCount, equals(1));
      expect(result.hasErrors, isTrue);
      expect(result.isEmpty, isFalse);
    });

    test('isEmpty is true when totalRows is 0', () {
      final result = CSVImportResult(validRows: [], errors: [], totalRows: 0);

      expect(result.isEmpty, isTrue);
      expect(result.hasErrors, isFalse);
    });
  });

  group('CSVRowData', () {
    test('toCreateParticipantParams converts correctly', () {
      final rowData = CSVRowData(
        firstName: 'John',
        lastName: 'Smith',
        schoolOrDojangName: "Kim's TKD",
        beltRank: 'blue',
        sourceRowNumber: 1,
        dateOfBirth: DateTime(2010, 5, 15),
        gender: Gender.male,
        weightKg: 45.5,
        registrationNumber: 'REG001',
        notes: 'Test note',
      );

      final params = rowData.toCreateParticipantParams('division-1');

      expect(params.divisionId, equals('division-1'));
      expect(params.firstName, equals('John'));
      expect(params.lastName, equals('Smith'));
      expect(params.schoolOrDojangName, equals("Kim's TKD"));
      expect(params.beltRank, equals('blue'));
      expect(params.dateOfBirth, equals(DateTime(2010, 5, 15)));
      expect(params.gender, equals(Gender.male));
      expect(params.weightKg, equals(45.5));
      expect(params.registrationNumber, equals('REG001'));
      expect(params.notes, equals('Test note'));
    });
  });

  group('CSVRowError', () {
    test('stores error information correctly', () {
      const error = CSVRowError(
        rowNumber: 5,
        fieldName: 'beltRank',
        errorMessage: 'Invalid belt rank',
        rawValue: 'Purple',
      );

      expect(error.rowNumber, equals(5));
      expect(error.fieldName, equals('beltRank'));
      expect(error.errorMessage, equals('Invalid belt rank'));
      expect(error.rawValue, equals('Purple'));
    });
  });
}
