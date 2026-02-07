import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/sync/autosave_status.dart';

void main() {
  group('AutosaveStatus', () {
    test('should have all expected values', () {
      expect(AutosaveStatus.values, hasLength(4));
      expect(AutosaveStatus.values, contains(AutosaveStatus.idle));
      expect(AutosaveStatus.values, contains(AutosaveStatus.saving));
      expect(AutosaveStatus.values, contains(AutosaveStatus.saved));
      expect(AutosaveStatus.values, contains(AutosaveStatus.error));
    });

    test('should have correct index values', () {
      expect(AutosaveStatus.idle.index, equals(0));
      expect(AutosaveStatus.saving.index, equals(1));
      expect(AutosaveStatus.saved.index, equals(2));
      expect(AutosaveStatus.error.index, equals(3));
    });

    test('should have correct string representations', () {
      expect(AutosaveStatus.idle.name, equals('idle'));
      expect(AutosaveStatus.saving.name, equals('saving'));
      expect(AutosaveStatus.saved.name, equals('saved'));
      expect(AutosaveStatus.error.name, equals('error'));
    });
  });
}
