import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/features/bracket/presentation/widgets/bracket_format_selection_dialog.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';

void main() {
  testWidgets('BracketFormatSelectionDialog displays options', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => BracketFormatSelectionDialog.show(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Select Bracket Format'), findsOneWidget);
    expect(find.text('Single Elimination'), findsOneWidget);
    expect(find.text('Double Elimination'), findsOneWidget);
    expect(find.text('Round Robin'), findsOneWidget);
  });

  testWidgets('BracketFormatSelectionDialog returns selected format', (tester) async {
    BracketFormat? selectedFormat;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedFormat = await BracketFormatSelectionDialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Double Elimination'));
    await tester.pumpAndSettle();

    expect(selectedFormat, BracketFormat.doubleElimination);
  });
}
