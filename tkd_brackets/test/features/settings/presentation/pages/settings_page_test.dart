import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/features/settings/settings.dart';

void main() {
  Widget buildTestWidget() {
    return const MaterialApp(
      home: Scaffold(
        body: SettingsPage(),
      ),
    );
  }

  group('SettingsPage', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('displays settings title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('displays placeholder message', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('App settings coming in Epic 2'), findsOneWidget);
    });

    testWidgets('displays settings icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('icon has semantic label for accessibility', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final icon =
          tester.widget<Icon>(find.byIcon(Icons.settings_outlined));
      expect(icon.semanticLabel, equals('Settings icon'));
    });
  });
}
