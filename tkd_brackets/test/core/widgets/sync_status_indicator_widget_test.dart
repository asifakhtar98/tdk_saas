import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/sync/sync_service.dart';
import 'package:tkd_brackets/core/sync/sync_status.dart';
import 'package:tkd_brackets/core/widgets/sync_status_indicator_widget.dart';

// Mock for SyncService using mocktail
class MockSyncService extends Mock implements SyncService {}

void main() {
  late MockSyncService mockSyncService;
  late StreamController<SyncStatus> statusController;

  setUp(() {
    mockSyncService = MockSyncService();
    statusController = StreamController<SyncStatus>.broadcast();

    // Register mock with GetIt
    GetIt.instance.registerSingleton<SyncService>(mockSyncService);

    // Default mock setup
    when(() => mockSyncService.statusStream)
        .thenAnswer((_) => statusController.stream);
    when(() => mockSyncService.currentStatus).thenReturn(SyncStatus.synced);
    when(() => mockSyncService.currentError).thenReturn(null);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await statusController.close();
  });

  Widget buildTestWidget({bool showLabel = false}) {
    return MaterialApp(
      home: Scaffold(
        body: SyncStatusIndicatorWidget(showLabel: showLabel),
      ),
    );
  }

  group('SyncStatusIndicatorWidget', () {
    testWidgets('displays cloud_done icon when synced', (tester) async {
      when(() => mockSyncService.currentStatus).thenReturn(SyncStatus.synced);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('displays CircularProgressIndicator when syncing',
        (tester) async {
      when(() => mockSyncService.currentStatus).thenReturn(SyncStatus.syncing);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays cloud_upload icon when pendingChanges',
        (tester) async {
      when(() => mockSyncService.currentStatus)
          .thenReturn(SyncStatus.pendingChanges);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
    });

    testWidgets('displays cloud_off icon when error', (tester) async {
      when(() => mockSyncService.currentStatus).thenReturn(SyncStatus.error);
      when(() => mockSyncService.currentError).thenReturn(
        const SyncError(message: 'Test error'),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('shows label when showLabel is true', (tester) async {
      when(() => mockSyncService.currentStatus).thenReturn(SyncStatus.synced);

      await tester.pumpWidget(buildTestWidget(showLabel: true));
      await tester.pump();

      expect(find.text('Synced'), findsOneWidget);
    });

    testWidgets('hides label when showLabel is false', (tester) async {
      when(() => mockSyncService.currentStatus).thenReturn(SyncStatus.synced);

      await tester.pumpWidget(buildTestWidget(showLabel: false));
      await tester.pump();

      expect(find.text('Synced'), findsNothing);
    });

    testWidgets('has Semantics widget for accessibility', (tester) async {
      when(() => mockSyncService.currentStatus).thenReturn(SyncStatus.synced);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final semantics = find.byWidgetPredicate((widget) =>
          widget is Semantics && widget.properties.label != null);
      expect(semantics, findsOneWidget);
    });

    testWidgets('has Tooltip widget for hover details', (tester) async {
      when(() => mockSyncService.currentStatus).thenReturn(SyncStatus.synced);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('updates when status stream emits new value', (tester) async {
      when(() => mockSyncService.currentStatus).thenReturn(SyncStatus.synced);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);

      // Emit syncing status
      statusController.add(SyncStatus.syncing);
      // Use pump with duration since CircularProgressIndicator animates
      // indefinitely, which causes pumpAndSettle to timeout
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
