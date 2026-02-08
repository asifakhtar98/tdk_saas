import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/features/tournament/tournament.dart';

void main() {
  Widget buildTestWidget() {
    return const MaterialApp(
      home: Scaffold(
        body: TournamentListPage(),
      ),
    );
  }

  group('TournamentListPage', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(TournamentListPage), findsOneWidget);
    });

    testWidgets('displays tournaments title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Tournaments'), findsOneWidget);
    });

    testWidgets('displays placeholder message', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(
        find.text('Tournament management coming in Epic 3'),
        findsOneWidget,
      );
    });

    testWidgets('displays trophy icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
    });

    testWidgets('icon has semantic label for accessibility', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final icon =
          tester.widget<Icon>(find.byIcon(Icons.emoji_events_outlined));
      expect(icon.semanticLabel, equals('Tournaments icon'));
    });
  });
}
