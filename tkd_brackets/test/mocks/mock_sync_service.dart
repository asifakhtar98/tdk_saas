import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/sync/sync_service.dart';
import 'package:tkd_brackets/core/sync/sync_status.dart';

/// Mock for SyncService using mocktail.
///
/// Shared mock for use across all tests requiring SyncService.
class MockSyncService extends Mock implements SyncService {}

/// Creates a configured mock SyncService with sensible defaults.
///
/// Returns a tuple of (MockSyncService, StreamController) so tests can
/// control the status stream.
///
/// Example usage:
/// ```dart
/// late MockSyncService mockSyncService;
/// late StreamController<SyncStatus> statusController;
///
/// setUp(() {
///   final (mock, controller) = createMockSyncService();
///   mockSyncService = mock;
///   statusController = controller;
///   GetIt.instance.registerSingleton<SyncService>(mockSyncService);
/// });
/// ```
(MockSyncService, StreamController<SyncStatus>) createMockSyncService({
  SyncStatus initialStatus = SyncStatus.synced,
  SyncError? initialError,
}) {
  final mock = MockSyncService();
  final controller = StreamController<SyncStatus>.broadcast();

  when(() => mock.statusStream).thenAnswer((_) => controller.stream);
  when(() => mock.currentStatus).thenReturn(initialStatus);
  when(() => mock.currentError).thenReturn(initialError);

  return (mock, controller);
}
