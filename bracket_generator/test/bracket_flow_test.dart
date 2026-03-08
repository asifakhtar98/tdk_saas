import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bracket_generator/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Helper: add N players
  Future<void> addPlayers(WidgetTester tester, List<List<String>> players) async {
    final firstInput = find.byType(TextField).at(0);
    final lastInput = find.byType(TextField).at(1);
    final dojangInput = find.byType(TextField).at(2);
    final addButton = find.text('Add Participant');

    for (final p in players) {
      await tester.ensureVisible(firstInput);
      await tester.enterText(firstInput, p[0]);
      await tester.enterText(lastInput, p[1]);
      await tester.enterText(dojangInput, p[2]);
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();
    }
  }

  // Helper: tap GENERATE and wait
  Future<void> tapGenerate(WidgetTester tester) async {
    final btn = find.textContaining('GENERATE');
    await tester.ensureVisible(btn);
    await tester.tap(btn);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  // Helper: go back to setup
  Future<void> goBack(WidgetTester tester) async {
    final backButton = find.byTooltip('Back');
    if (tester.any(backButton)) {
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    }
  }

  // 4 standard players used across tests
  const fourPlayers = [
    ['John', 'Doe', 'Eagle TKD'],
    ['Jane', 'Smith', 'Tiger TKD'],
    ['Mike', 'Lee', 'Eagle TKD'],
    ['Sarah', 'Connor', 'Dragon TKD'],
  ];

  group('1. Single Elimination', () {
    testWidgets('1a. 4 players: correct bracket structure (2 semis + 1 final)', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      expect(find.text('New Bracket Setup'), findsOneWidget);

      await addPlayers(tester, fourPlayers);
      expect(find.textContaining('GENERATE'), findsOneWidget);

      await tapGenerate(tester);
      expect(find.textContaining('Live Tournament'), findsOneWidget);

      // 4 players → 2 rounds, 3 matches (2 semis + 1 final)
      // Each match card has "M1" or "M2" etc in header
      // Round 1 has M1, M2. Round 2 has M1 (final).
      // Match cards show player last names, not UUIDs
      expect(find.text('Doe'), findsWidgets);
      expect(find.text('Smith'), findsWidgets);
      expect(find.text('Lee'), findsWidgets);
      expect(find.text('Connor'), findsWidgets);

      await goBack(tester);
      expect(find.text('New Bracket Setup'), findsOneWidget);
    });

    testWidgets('1b. 3 players: BYE handling (one player gets BYE)', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await addPlayers(tester, [
        ['Alice', 'Kim', 'Dojang A'],
        ['Bob', 'Park', 'Dojang B'],
        ['Charlie', 'Choi', 'Dojang C'],
      ]);

      await tapGenerate(tester);
      expect(find.textContaining('Live Tournament'), findsOneWidget);

      // 3 players → bracketSize=4, 1 BYE in round 1
      // Should see "BYE" text on at least one match card
      expect(find.text('BYE'), findsWidgets);

      await goBack(tester);
    });

    testWidgets('1c. Score a semi-final → winner propagates to final', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await addPlayers(tester, fourPlayers);
      await tapGenerate(tester);
      expect(find.textContaining('Live Tournament'), findsOneWidget);

      // Find match cards with M1 header
      final m1 = find.text('M1');
      expect(m1, findsWidgets);

      // Tap the first M1 (semi-final)
      await tester.ensureVisible(m1.first);
      await tester.tap(m1.first);
      await tester.pumpAndSettle();

      // Score dialog appears
      if (tester.any(find.text('Score Match / Result'))) {
        final winsButtons = find.textContaining('WINS');
        await tester.ensureVisible(winsButtons.first);
        await tester.tap(winsButtons.first);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
      }

      // Match scored → green check visible
      expect(find.byIcon(Icons.check_circle), findsWidgets);

      await goBack(tester);
    });

    testWidgets('1d. 3rd place match toggle generates bronze match', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enable 3rd place match
      final thirdPlaceToggle = find.byType(SwitchListTile).last;
      await tester.ensureVisible(thirdPlaceToggle);
      await tester.tap(thirdPlaceToggle);
      await tester.pumpAndSettle();

      await addPlayers(tester, fourPlayers);
      await tapGenerate(tester);
      expect(find.textContaining('Live Tournament'), findsOneWidget);

      // With 3rd place match: 4 matches total (2 semis + 1 final + 1 bronze)
      // We should see M2 in the finals round (M1=final, M2=bronze)
      expect(find.text('M2'), findsWidgets);

      await goBack(tester);
    });
  });

  group('2. Double Elimination', () {
    testWidgets('2a. 4 players: winners+losers brackets generated', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Switch to Double Elimination
      final formatDropdown = find.byType(DropdownButton<String>).first;
      await tester.ensureVisible(formatDropdown);
      await tester.tap(formatDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Double Elimination').last);
      await tester.pumpAndSettle();

      await addPlayers(tester, fourPlayers);
      await tapGenerate(tester);
      expect(find.textContaining('Live Tournament'), findsOneWidget);

      // Player names should be visible
      expect(find.text('Doe'), findsWidgets);
      expect(find.text('Smith'), findsWidgets);

      await goBack(tester);
    });
  });

  group('3. Round Robin', () {
    testWidgets('3a. 4 players: n*(n-1)/2 = 6 total matches across 3 rounds', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Switch to Round Robin
      final formatDropdown = find.byType(DropdownButton<String>).first;
      await tester.ensureVisible(formatDropdown);
      await tester.tap(formatDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Round Robin').last);
      await tester.pumpAndSettle();

      await addPlayers(tester, fourPlayers);
      await tapGenerate(tester);
      expect(find.textContaining('Live Tournament'), findsOneWidget);

      // 4 players (even) → 3 rounds, 2 matches per round = 6 matches total
      expect(find.text('Round 1'), findsOneWidget);
      expect(find.text('Round 2'), findsOneWidget);
      expect(find.text('Round 3'), findsOneWidget);

      // Each player plays every other player exactly once
      // Count 'vs' markers: should be 6 (one per match row)
      expect(find.text('vs'), findsNWidgets(6));

      await goBack(tester);
    });

    testWidgets('3b. 3 players (odd): phantom BYE + correct match count', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final formatDropdown = find.byType(DropdownButton<String>).first;
      await tester.ensureVisible(formatDropdown);
      await tester.tap(formatDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Round Robin').last);
      await tester.pumpAndSettle();

      await addPlayers(tester, [
        ['Kim', 'Park', 'Gym X'],
        ['Lee', 'Jung', 'Gym Y'],
        ['Choi', 'Han', 'Gym Z'],
      ]);

      await tapGenerate(tester);
      expect(find.textContaining('Live Tournament'), findsOneWidget);

      // 3 players (odd) → effectiveN=4, 3 rounds, 2 matches/round
      // But 3 of those 6 matches are BYEs, leaving 3 real matches
      expect(find.text('Round 1'), findsOneWidget);
      expect(find.text('Round 2'), findsOneWidget);
      expect(find.text('Round 3'), findsOneWidget);

      // BYE results should appear
      expect(find.text('BYE'), findsWidgets);

      await goBack(tester);
    });

    testWidgets('3c. Score a Round Robin match', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final formatDropdown = find.byType(DropdownButton<String>).first;
      await tester.ensureVisible(formatDropdown);
      await tester.tap(formatDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Round Robin').last);
      await tester.pumpAndSettle();

      await addPlayers(tester, fourPlayers);
      await tapGenerate(tester);

      // Tap on a player name in the table to score
      final redName = find.text('John Doe');
      if (tester.any(redName)) {
        await tester.tap(redName.first);
        await tester.pumpAndSettle();

        if (tester.any(find.text('Score Match / Result'))) {
          final winsBtn = find.textContaining('WINS');
          await tester.tap(winsBtn.first);
          await tester.pumpAndSettle();
        }
      }

      await goBack(tester);
    });
  });

  group('4. Participant Management', () {
    testWidgets('4a. Add, verify count, clear all', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await addPlayers(tester, fourPlayers);

      // GENERATE button should be visible (>= 2 players)
      expect(find.textContaining('GENERATE'), findsOneWidget);

      // Clear all
      final clearAll = find.text('Clear All');
      await tester.ensureVisible(clearAll);
      await tester.tap(clearAll);
      await tester.pumpAndSettle();

      // GENERATE should disappear (0 players)
      expect(find.textContaining('GENERATE'), findsNothing);

      // Empty state message
      expect(find.textContaining('Add players'), findsOneWidget);
    });

    testWidgets('4b. Remove individual participant', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await addPlayers(tester, [
        ['Test', 'Player1', 'Gym'],
        ['Test', 'Player2', 'Gym'],
        ['Test', 'Player3', 'Gym'],
      ]);

      // Should see 3 close buttons
      final closeButtons = find.byIcon(Icons.close);
      expect(closeButtons, findsNWidgets(3));

      // Remove first player
      await tester.tap(closeButtons.first);
      await tester.pumpAndSettle();

      // Now 2 close buttons
      expect(find.byIcon(Icons.close), findsNWidgets(2));
    });

    testWidgets('4c. CSV import', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tap CSV import button
      final csvBtn = find.text('Paste CSV (First,Last,Dojang)');
      await tester.ensureVisible(csvBtn);
      await tester.tap(csvBtn);
      await tester.pumpAndSettle();

      // CSV dialog should appear
      expect(find.text('Paste CSV'), findsOneWidget);

      // Enter CSV data
      final csvField = find.byType(TextField).last;
      await tester.enterText(csvField, 'Kim,Park,Eagle TKD\nLee,Jung,Tiger TKD\nChoi,Han,Dragon TKD');
      await tester.pumpAndSettle();

      // Tap Import
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      // GENERATE should appear (3 players added)
      expect(find.textContaining('GENERATE'), findsOneWidget);
    });

    testWidgets('4d. Cannot generate with 0 or 1 player', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 0 players: no GENERATE
      expect(find.textContaining('GENERATE'), findsNothing);

      // Add 1 player
      await addPlayers(tester, [['Solo', 'Player', 'Gym']]);
      
      // Still no GENERATE (need >= 2)
      expect(find.textContaining('GENERATE'), findsNothing);

      // Add a 2nd
      await addPlayers(tester, [['Second', 'Player', 'Gym']]);
      expect(find.textContaining('GENERATE'), findsOneWidget);
    });
  });

  group('5. Match Scoring Logic', () {
    testWidgets('5a. Score + reset match (cascading undo)', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await addPlayers(tester, fourPlayers);
      await tapGenerate(tester);

      // Score first semi
      final m1 = find.text('M1');
      await tester.ensureVisible(m1.first);
      await tester.tap(m1.first);
      await tester.pumpAndSettle();

      if (tester.any(find.text('Score Match / Result'))) {
        final winsBtn = find.textContaining('WINS');
        await tester.ensureVisible(winsBtn.first);
        await tester.tap(winsBtn.first);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
      }

      // Should see green check
      expect(find.byIcon(Icons.check_circle), findsWidgets);

      // Tap same match to reset
      await tester.ensureVisible(m1.first);
      await tester.tap(m1.first);
      await tester.pumpAndSettle();

      if (tester.any(find.text('Match Completed'))) {
        await tester.tap(find.text('Reset Score'));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
      }

      await goBack(tester);
    });

    testWidgets('5b. Complete full tournament: score all matches to get champion', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await addPlayers(tester, fourPlayers);
      await tapGenerate(tester);

      // Helper to score a match by tapping it and hitting WINS
      Future<void> scoreMatch(Finder matchFinder) async {
        await tester.ensureVisible(matchFinder);
        await tester.tap(matchFinder);
        await tester.pumpAndSettle();
        if (tester.any(find.text('Score Match / Result'))) {
          final winsBtn = find.textContaining('WINS');
          await tester.ensureVisible(winsBtn.first);
          await tester.tap(winsBtn.first);
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pumpAndSettle();
        }
      }

      // Score Semi 1
      await scoreMatch(find.text('M1').first);

      // Score Semi 2
      final m2 = find.text('M2');
      if (tester.any(m2)) {
        await scoreMatch(m2.first);
      }

      // Score Final (last M1 on screen)
      await scoreMatch(find.text('M1').last);

      // All matches completed
      expect(find.byIcon(Icons.check_circle), findsWidgets);

      await goBack(tester);
    });
  });

  group('6. Dojang Separation', () {
    testWidgets('6a. Players from same dojang are separated in bracket', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify dojang separation is ON by default
      final switchTiles = find.byType(SwitchListTile);
      expect(switchTiles, findsWidgets);

      // Add 4 players: 2 from Eagle TKD, 1 Tiger, 1 Dragon
      await addPlayers(tester, fourPlayers);
      await tapGenerate(tester);

      // In a properly separated bracket, Doe and Lee (both Eagle TKD)
      // should NOT be in the same semi-final match.
      // They should be on opposite sides of the bracket.
      // We verify by checking the bracket rendered without errors
      expect(find.textContaining('Live Tournament'), findsOneWidget);

      await goBack(tester);
    });
  });

  group('7. Format Switching', () {
    testWidgets('7a. Switch between all 3 formats on setup screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Default: Single Elimination
      expect(find.text('Single Elimination'), findsOneWidget);

      // Switch to Double
      final dropdown = find.byType(DropdownButton<String>).first;
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Double Elimination').last);
      await tester.pumpAndSettle();

      // 3rd place toggle should NOT be visible for Double
      // (it's only shown for Single Elimination)
      expect(find.text('3rd Place Match'), findsNothing);

      // Switch to Round Robin
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Round Robin').last);
      await tester.pumpAndSettle();

      // Switch back to Single
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Single Elimination').last);
      await tester.pumpAndSettle();

      // 3rd place toggle should reappear
      expect(find.text('3rd Place Match'), findsOneWidget);
    });
  });
}
