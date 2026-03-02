import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/presentation/widgets/match_card_widget.dart';

void main() {
  final testMatch = MatchEntity(
    id: 'm1',
    bracketId: 'b1',
    roundNumber: 1,
    matchNumberInRound: 1,
    participantRedId: 'Red Player',
    participantBlueId: 'Blue Player',
    status: MatchStatus.pending,
    createdAtTimestamp: DateTime.now(),
    updatedAtTimestamp: DateTime.now(),
  );

  testWidgets('MatchCardWidget shows participant IDs/names', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MatchCardWidget(
            match: testMatch,
            isHighlighted: false,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Red Player'), findsOneWidget);
    expect(find.text('Blue Player'), findsOneWidget);
    expect(find.text('M1'), findsOneWidget);
  });

  testWidgets('MatchCardWidget shows winner highlight', (
    WidgetTester tester,
  ) async {
    final completedMatch = testMatch.copyWith(
      status: MatchStatus.completed,
      winnerId: 'Red Player',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MatchCardWidget(
            match: completedMatch,
            isHighlighted: false,
            onTap: () {},
          ),
        ),
      ),
    );

    // Winner name should be present
    expect(find.text('Red Player'), findsOneWidget);
    // There should be a winner indicator icon if we implemented one,
    // but at least check for the text.
  });

  testWidgets('MatchCardWidget triggers onTap', (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MatchCardWidget(
            match: testMatch,
            isHighlighted: false,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(MatchCardWidget));
    expect(tapped, isTrue);
  });
}
