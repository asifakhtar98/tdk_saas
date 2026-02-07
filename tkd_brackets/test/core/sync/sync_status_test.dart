import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/sync/sync_status.dart';

void main() {
  group('SyncStatus', () {
    test('enum contains all expected values', () {
      expect(SyncStatus.values, hasLength(4));
      expect(SyncStatus.values, contains(SyncStatus.synced));
      expect(SyncStatus.values, contains(SyncStatus.syncing));
      expect(SyncStatus.values, contains(SyncStatus.pendingChanges));
      expect(SyncStatus.values, contains(SyncStatus.error));
    });

    test('synced represents all changes synced', () {
      expect(SyncStatus.synced.name, equals('synced'));
    });

    test('syncing represents sync in progress', () {
      expect(SyncStatus.syncing.name, equals('syncing'));
    });

    test('pendingChanges represents waiting changes', () {
      expect(SyncStatus.pendingChanges.name, equals('pendingChanges'));
    });

    test('error represents sync failure', () {
      expect(SyncStatus.error.name, equals('error'));
    });
  });

  group('SyncError', () {
    test('creates with required message', () {
      const error = SyncError(message: 'Test error');

      expect(error.message, equals('Test error'));
      expect(error.technicalDetails, isNull);
      expect(error.failedOperationCount, equals(0));
    });

    test('creates with all parameters', () {
      const error = SyncError(
        message: 'User-friendly message',
        technicalDetails: 'Technical stack trace',
        failedOperationCount: 5,
      );

      expect(error.message, equals('User-friendly message'));
      expect(error.technicalDetails, equals('Technical stack trace'));
      expect(error.failedOperationCount, equals(5));
    });

    test('toString returns formatted string', () {
      const error = SyncError(
        message: 'Test error',
        technicalDetails: 'Details',
        failedOperationCount: 3,
      );

      final result = error.toString();

      expect(result, contains('SyncError'));
      expect(result, contains('Test error'));
      expect(result, contains('Details'));
      expect(result, contains('3'));
    });

    test('equality works correctly', () {
      const error1 = SyncError(
        message: 'Error',
        technicalDetails: 'Details',
        failedOperationCount: 1,
      );
      const error2 = SyncError(
        message: 'Error',
        technicalDetails: 'Details',
        failedOperationCount: 1,
      );
      const error3 = SyncError(
        message: 'Different',
        technicalDetails: 'Details',
        failedOperationCount: 1,
      );

      expect(error1, equals(error2));
      expect(error1, isNot(equals(error3)));
    });

    test('hashCode is consistent', () {
      const error1 = SyncError(
        message: 'Error',
        technicalDetails: 'Details',
        failedOperationCount: 1,
      );
      const error2 = SyncError(
        message: 'Error',
        technicalDetails: 'Details',
        failedOperationCount: 1,
      );

      expect(error1.hashCode, equals(error2.hashCode));
    });
  });
}
