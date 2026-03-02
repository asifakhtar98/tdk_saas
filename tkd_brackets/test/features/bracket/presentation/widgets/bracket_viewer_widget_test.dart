import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_layout.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/presentation/widgets/bracket_viewer_widget.dart';
import 'package:tkd_brackets/features/bracket/presentation/widgets/match_card_widget.dart';

void main() {
  final testMatch = MatchEntity(
    id: 'm1',
    bracketId: 'b1',
    roundNumber: 1,
    matchNumberInRound: 1,
    status: MatchStatus.pending,
    createdAtTimestamp: DateTime.now(),
    updatedAtTimestamp: DateTime.now(),
  );

  const testLayout = BracketLayout(
    format: BracketFormat.singleElimination,
    canvasSize: Size(1000, 1000),
    rounds: [
      BracketRound(
        roundNumber: 1,
        roundLabel: 'Finals',
        xPosition: 0,
        matchSlots: [
          MatchSlot(
            matchId: 'm1',
            position: Offset(10, 10),
            size: Size(200, 80),
          ),
        ],
      ),
    ],
  );

  testWidgets('BracketViewerWidget renders InteractiveViewer and MatchCard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BracketViewerWidget(
            layout: testLayout,
            matches: [testMatch],
            onMatchTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byType(MatchCardWidget), findsOneWidget);
    expect(find.text('Finals'), findsOneWidget);
  });

  testWidgets('BracketViewerWidget triggers onMatchTap', (
    WidgetTester tester,
  ) async {
    String? tappedId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BracketViewerWidget(
            layout: testLayout,
            matches: [testMatch],
            onMatchTap: (id) => tappedId = id,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(MatchCardWidget));
    expect(tappedId, 'm1');
  });
}
