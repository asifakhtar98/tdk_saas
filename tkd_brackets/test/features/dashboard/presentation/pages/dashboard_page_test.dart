import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/features/dashboard/dashboard.dart';

void main() {
  Widget buildTestWidget() {
    return const MaterialApp(
      home: Scaffold(
        body: DashboardPage(),
      ),
    );
  }

  group('DashboardPage', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('displays dashboard title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('displays placeholder message', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Tournament overview coming in Epic 3'), findsOneWidget);
    });

    testWidgets('displays dashboard icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
    });

    testWidgets('icon has semantic label for accessibility', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final icon =
          tester.widget<Icon>(find.byIcon(Icons.dashboard_outlined));
      expect(icon.semanticLabel, equals('Dashboard icon'));
    });
  });
}
