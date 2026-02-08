import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/router/navigation_items.dart';
import 'package:tkd_brackets/core/router/shell_routes.dart';
import 'package:tkd_brackets/core/sync/sync_service.dart';
import 'package:tkd_brackets/core/sync/sync_status.dart';

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

  Widget buildTestShell({
    required String currentLocation,
    Size viewSize = const Size(1440, 900),
  }) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQueryData(size: viewSize),
            child: SizedBox(
              width: viewSize.width,
              height: viewSize.height,
              child: AppShellScaffold(
                currentLocation: currentLocation,
                child: const Center(child: Text('Content')),
              ),
            ),
          );
        },
      ),
    );
  }

  group('AppShellScaffold', () {
    group('responsive navigation', () {
      testWidgets('shows NavigationRail on desktop (≥1280px)', (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestShell(currentLocation: '/dashboard'));
        await tester.pump();

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      });

      testWidgets(
        'shows NavigationRail on tablet (768-1279px)',
        (tester) async {
          tester.view.physicalSize = const Size(1024, 768);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester
              .pumpWidget(buildTestShell(currentLocation: '/dashboard'));
          await tester.pump();

          expect(find.byType(NavigationRail), findsOneWidget);
          expect(find.byType(NavigationBar), findsNothing);
        },
      );

      testWidgets('shows NavigationBar on mobile (<768px)', (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestShell(currentLocation: '/dashboard'));
        await tester.pump();

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);
      });
    });

    group('navigation state', () {
      testWidgets('highlights dashboard when location is /dashboard',
          (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestShell(currentLocation: '/dashboard'));
        await tester.pump();

        final rail =
            tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.selectedIndex, equals(0)); // Dashboard is index 0
      });

      testWidgets('highlights tournaments when location is /tournaments',
          (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestShell(currentLocation: '/tournaments'));
        await tester.pump();

        final rail =
            tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.selectedIndex, equals(1)); // Tournaments is index 1
      });

      testWidgets('highlights settings when location is /settings',
          (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestShell(currentLocation: '/settings'));
        await tester.pump();

        final rail =
            tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.selectedIndex, equals(2)); // Settings is index 2
      });

      testWidgets('defaults to dashboard for unknown location', (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestShell(currentLocation: '/unknown'));
        await tester.pump();

        final rail =
            tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.selectedIndex, equals(0)); // Defaults to dashboard
      });
    });

    group('app bar', () {
      testWidgets('displays AppBar with title', (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestShell(currentLocation: '/dashboard'));
        await tester.pump();

        expect(find.byType(AppBar), findsOneWidget);
        // Text appears in app bar and navigation rail label
        expect(find.text('Dashboard'), findsAtLeastNWidgets(1));
      });

      testWidgets('displays SyncStatusIndicatorWidget in app bar',
          (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestShell(currentLocation: '/dashboard'));
        await tester.pump();

        // Sync indicator should be visible in app bar actions
        expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      });

      testWidgets('updates title based on current location', (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestShell(currentLocation: '/settings'));
        await tester.pump();

        // Text appears in app bar and navigation rail label
        expect(find.text('Settings'), findsAtLeastNWidgets(1));
      });
    });

    group('rail toggle (desktop only)', () {
      testWidgets('shows toggle button only on desktop', (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestShell(currentLocation: '/dashboard'));
        await tester.pump();

        // Toggle button should be present on desktop
        expect(find.byIcon(Icons.keyboard_double_arrow_left), findsOneWidget);
      });

      testWidgets('hides toggle button on tablet', (tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestShell(currentLocation: '/dashboard'));
        await tester.pump();

        // Toggle button should not be present on tablet
        expect(find.byIcon(Icons.keyboard_double_arrow_left), findsNothing);
        expect(find.byIcon(Icons.keyboard_double_arrow_right), findsNothing);
      });

      testWidgets('toggle collapses rail when tapped', (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestShell(currentLocation: '/dashboard'));
        await tester.pump();

        // Rail should start extended
        var rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.extended, isTrue);

        // Tap the toggle
        await tester.tap(find.byIcon(Icons.keyboard_double_arrow_left));
        await tester.pump();

        // Rail should now be collapsed
        rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.extended, isFalse);
        expect(find.byIcon(Icons.keyboard_double_arrow_right), findsOneWidget);
      });

      testWidgets('toggle expands rail when collapsed', (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestShell(currentLocation: '/dashboard'));
        await tester.pump();

        // Collapse the rail first
        await tester.tap(find.byIcon(Icons.keyboard_double_arrow_left));
        await tester.pump();

        // Now expand it
        await tester.tap(find.byIcon(Icons.keyboard_double_arrow_right));
        await tester.pump();

        // Rail should be extended again
        final rail =
            tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.extended, isTrue);
      });
    });

    group('content area', () {
      testWidgets('displays child widget in content area', (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestShell(currentLocation: '/dashboard'));
        await tester.pump();

        expect(find.text('Content'), findsOneWidget);
      });
    });
  });

  group('kNavItems', () {
    test('contains 3 navigation items', () {
      expect(kNavItems.length, equals(3));
    });

    test('first item is Dashboard', () {
      expect(kNavItems[0].path, equals('/dashboard'));
      expect(kNavItems[0].label, equals('Dashboard'));
    });

    test('second item is Tournaments', () {
      expect(kNavItems[1].path, equals('/tournaments'));
      expect(kNavItems[1].label, equals('Tournaments'));
    });

    test('third item is Settings', () {
      expect(kNavItems[2].path, equals('/settings'));
      expect(kNavItems[2].label, equals('Settings'));
    });
  });
}
