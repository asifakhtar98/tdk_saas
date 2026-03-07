import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/ranked_seeding_entry.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/ranked_seeding_file_parser.dart';
import 'package:tkd_brackets/core/error/failures.dart';

void main() {
  late RankedSeedingFileParser parser;

  setUp(() {
    parser = RankedSeedingFileParser();
  });

  group('RankedSeedingFileParser - CSV', () {
    test('should parse valid CSV with all columns', () {
      const csv = 'Name,Club,Rank\nJohn Smith,Tiger TKD,1\nJane Doe,Dragon MA,2';
      final result = parser.parse(csv);

      expect(result.isRight(), isTrue);
      final entries =
          (result as Right<Failure, List<RankedSeedingEntry>>).value;
      expect(entries.length, 2);
      expect(
          entries[0],
          const RankedSeedingEntry(
              name: 'John Smith', rank: 1, club: 'Tiger TKD'));
      expect(
          entries[1],
          const RankedSeedingEntry(
              name: 'Jane Doe', rank: 2, club: 'Dragon MA'));
    });

    test('should parse valid CSV with optional Club column missing', () {
      const csv = 'Name,Rank\nJohn Smith,1\nJane Doe,2';
      final result = parser.parse(csv);

      expect(result.isRight(), isTrue);
      final entries =
          (result as Right<Failure, List<RankedSeedingEntry>>).value;
      expect(entries[0].club, isNull);
      expect(entries[1].club, isNull);
    });

    test('should return ValidationFailure when Name column is missing', () {
      const csv = 'Club,Rank\nTiger TKD,1';
      final result = parser.parse(csv);

      expect(result.isLeft(), isTrue);
    });

    test('should return ValidationFailure when Rank column is missing', () {
      const csv = 'Name,Club\nJohn Smith,Tiger TKD';
      final result = parser.parse(csv);

      expect(result.isLeft(), isTrue);
    });

    test('should return ValidationFailure for non-integer rank', () {
      const csv = 'Name,Rank\nJohn Smith,first';
      final result = parser.parse(csv);

      expect(result.isLeft(), isTrue);
    });

    test('should handle Windows line endings (\\r\\n)', () {
      const csv = 'Name,Rank\r\nJohn Smith,1\r\nJane Doe,2';
      final result = parser.parse(csv);

      expect(result.isRight(), isTrue);
      final entries =
          (result as Right<Failure, List<RankedSeedingEntry>>).value;
      expect(entries.length, 2);
    });

    test('should trim extra whitespace from values', () {
      const csv = '  Name , Rank \n  John Smith  ,  1  \n  Jane Doe  ,  2  ';
      final result = parser.parse(csv);

      expect(result.isRight(), isTrue);
      final entries =
          (result as Right<Failure, List<RankedSeedingEntry>>).value;
      expect(entries[0].name, 'John Smith');
      expect(entries[0].rank, 1);
    });

    test('should skip empty rows', () {
      const csv = 'Name,Rank\nJohn Smith,1\n\n\nJane Doe,2\n\n';
      final result = parser.parse(csv);

      expect(result.isRight(), isTrue);
      final entries =
          (result as Right<Failure, List<RankedSeedingEntry>>).value;
      expect(entries.length, 2);
    });

    test('should handle case-insensitive headers', () {
      const csv = 'NAME,CLUB,RANK\nJohn Smith,Tiger TKD,1';
      final result = parser.parse(csv);

      expect(result.isRight(), isTrue);
      final entries =
          (result as Right<Failure, List<RankedSeedingEntry>>).value;
      expect(entries[0].name, 'John Smith');
      expect(entries[0].club, 'Tiger TKD');
      expect(entries[0].rank, 1);
    });
  });

  group('RankedSeedingFileParser - JSON', () {
    test('should parse valid JSON array', () {
      const json =
          '[{"name": "John Smith", "rank": 1, "club": "Tiger TKD"}, {"name": "Jane Doe", "rank": 2}]';
      final result = parser.parse(json);

      expect(result.isRight(), isTrue);
      final entries =
          (result as Right<Failure, List<RankedSeedingEntry>>).value;
      expect(entries.length, 2);
      expect(entries[0].name, 'John Smith');
      expect(entries[0].club, 'Tiger TKD');
      expect(entries[1].name, 'Jane Doe');
      expect(entries[1].club, isNull);
    });

    test('should return ValidationFailure for non-array root', () {
      const json = '{"name": "John Smith"}';
      final result = parser.parse(json);

      expect(result.isLeft(), isTrue);
    });

    test('should return ValidationFailure for invalid JSON syntax', () {
      const json = '[{"name": "John Smith"';
      final result = parser.parse(json);

      expect(result.isLeft(), isTrue);
    });

    test('should return ValidationFailure when name is missing', () {
      const json = '[{"rank": 1, "club": "Tiger TKD"}]';
      final result = parser.parse(json);

      expect(result.isLeft(), isTrue);
    });

    test('should return ValidationFailure when rank is missing', () {
      const json = '[{"name": "John Smith", "club": "Tiger TKD"}]';
      final result = parser.parse(json);

      expect(result.isLeft(), isTrue);
    });

    test('should return ValidationFailure when rank is a string', () {
      const json = '[{"name": "John Smith", "rank": "3"}]';
      final result = parser.parse(json);

      expect(result.isLeft(), isTrue);
    });

    test('should return ValidationFailure for empty JSON array', () {
      const json = '[]';
      final result = parser.parse(json);

      expect(result.isLeft(), isTrue);
    });

    test('should trim name whitespace in JSON', () {
      const json = '[{"name": "  John Smith  ", "rank": 1}]';
      final result = parser.parse(json);

      expect(result.isRight(), isTrue);
      final entries =
          (result as Right<Failure, List<RankedSeedingEntry>>).value;
      expect(entries[0].name, 'John Smith');
    });
  });

  group('RankedSeedingFileParser - General', () {
    test('should return ValidationFailure for empty content', () {
      final result = parser.parse('');
      expect(result.isLeft(), isTrue);
    });

    test('should return ValidationFailure for whitespace-only content', () {
      final result = parser.parse('   \n  ');
      expect(result.isLeft(), isTrue);
    });
  });
}
