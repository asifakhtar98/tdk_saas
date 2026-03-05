import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/features/participant/domain/services/clipboard_input_service.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_parser_service.dart';
import 'package:tkd_brackets/features/participant/domain/services/csv_import_result.dart';
import 'package:tkd_brackets/core/error/failures.dart';

void main() {
  group('ClipboardInputService', () {
    late ClipboardInputService service;

    setUp(() {
      service = ClipboardInputService();
    });

    group('normalizeToCSV', () {
      test('returns empty string for empty input', () {
        expect(service.normalizeToCSV(''), equals(''));
      });

      test('returns whitespace unchanged for whitespace-only input', () {
        expect(service.normalizeToCSV('   '), equals('   '));
      });

      test('returns comma-delimited CSV unchanged (passthrough)', () {
        const input = 'first_name,last_name,school,belt\nJohn,Doe,Academy,Black';
        expect(service.normalizeToCSV(input), equals(input));
      });

      test('converts tab-delimited single row to CSV', () {
        const input = 'John\tDoe\tAcademy\tBlack';
        // Note: Implementation adds a trailing newline for tab-converted rows
        expect(service.normalizeToCSV(input), equals('John,Doe,Academy,Black\n'));
      });

      test('converts tab-delimited multi-row with headers to CSV', () {
        const input = 'first_name\tlast_name\tschool\tbelt\n'
            'John\tDoe\tAcademy\tBlack\n'
            'Jane\tKim\tTiger Dojang\tRed';
        
        const expected = 'first_name,last_name,school,belt\n'
            'John,Doe,Academy,Black\n'
            'Jane,Kim,Tiger Dojang,Red\n';
            
        expect(service.normalizeToCSV(input), equals(expected));
      });

      test('quotes cells containing embedded commas', () {
        const input = 'name\tschool\nJohn\tRiver, City Dojang';
        const expected = 'name,school\nJohn,"River, City Dojang"\n';
        expect(service.normalizeToCSV(input), equals(expected));
      });

      test('quotes and escapes cells containing embedded double quotes', () {
        const input = 'name\tnotes\nJohn\tHe said "hi"';
        const expected = 'name,notes\nJohn,"He said ""hi"""\n';
        expect(service.normalizeToCSV(input), equals(expected));
      });

      test('normalizes mixed line endings to \n', () {
        const input = 'a\tb\r\n1\t2';
        const expected = 'a,b\n1,2\n';
        expect(service.normalizeToCSV(input), equals(expected));
      });

      test('handles trailing tabs by producing empty cells', () {
        const input = 'a\tb\t\n1\t2\t';
        const expected = 'a,b,\n1,2,\n';
        expect(service.normalizeToCSV(input), equals(expected));
      });
    });

    group('Integration with CSVParserService', () {
      test('tab-delimited spreadsheet paste produces valid parsed rows',
          () async {
        final clipboardService = ClipboardInputService();
        final csvParser = CSVParserService();

        const tabInput = 'First Name\tLast Name\tSchool Name\tBelt Rank\n'
            'John\tDoe\tAcademy\tBlack\n'
            'Jane\tKim\tTiger Dojang\tRed\n';

        final normalized = clipboardService.normalizeToCSV(tabInput);
        final result = await csvParser.parseCSV(
          csvContent: normalized,
          divisionId: 'div-test',
        );

        expect(result.isRight(), isTrue);
        result.fold((Failure failure) => fail('Should not fail: $failure'), (CSVImportResult r) {
          expect(r.validRows.length, equals(2));
          expect(r.validRows[0].firstName, equals('John'));
          expect(r.validRows[0].lastName, equals('Doe'));
          expect(r.validRows[0].schoolOrDojangName, equals('Academy'));
          expect(r.validRows[0].beltRank, equals('black'));

          expect(r.validRows[1].firstName, equals('Jane'));
          expect(r.validRows[1].lastName, equals('Kim'));
          expect(r.validRows[1].schoolOrDojangName, equals('Tiger Dojang'));
          expect(r.validRows[1].beltRank, equals('red'));
        });
      });
    });
  });
}
