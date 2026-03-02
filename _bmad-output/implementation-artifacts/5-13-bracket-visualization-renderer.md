# Story 5.13: Bracket Visualization Renderer

**Status:** done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an organizer,
I want to see a visual representation of the bracket,
so that I can verify structure, track match progress, and manage live competition (FR20-FR22, FR29, FR39).

## Acceptance Criteria

1. **AC1:** `BracketLayout` domain entity is created at `lib/features/bracket/domain/entities/bracket_layout.dart` containing: `BracketFormat format`, `List<BracketRound> rounds`, `Size canvasSize`. `BracketRound` contains: `int roundNumber`, `String roundLabel`, `List<MatchSlot> matchSlots`, `double xPosition`. `MatchSlot` contains: `String matchId`, `Offset position`, `Size size`, `MatchSlot? advancesToSlot`.
2. **AC2:** `BracketLayoutOptions` is created at `lib/features/bracket/domain/entities/bracket_layout.dart` with configurable `matchCardWidth` (default 200.0), `matchCardHeight` (default 80.0), `horizontalSpacing` (default 60.0), `verticalSpacing` (default 20.0), `connectorLineWidth` (default 2.0), `showByes` (default true).
3. **AC3:** `BracketLayoutEngine` abstract service is created at `lib/features/bracket/domain/services/bracket_layout_engine.dart` with method `BracketLayout calculateLayout({required BracketEntity bracket, required List<MatchEntity> matches, required BracketLayoutOptions options})`.
4. **AC4:** `BracketLayoutEngineImplementation` is created at `lib/features/bracket/data/services/bracket_layout_engine_implementation.dart` with `@LazySingleton(as: BracketLayoutEngine)`. Computes position for single elimination (standard binary-tree), double elimination (winners + losers bracket stacked), and round robin (table grid). Round labels use localized names: "Round 1", "Quarterfinals", "Semifinals", "Finals" for elimination brackets.
5. **AC5:** `BracketBloc` is created at `lib/features/bracket/presentation/bloc/bracket_bloc.dart` using `@injectable`, extending `Bloc<BracketEvent, BracketState>`. Constructor injects: `BracketRepository`, `MatchRepository`, `BracketLayoutEngine`, `LockBracketUseCase`, `UnlockBracketUseCase`.
6. **AC6:** `BracketEvent` is `@freezed` at `lib/features/bracket/presentation/bloc/bracket_event.dart` with events: `loadRequested({required String bracketId})`, `refreshRequested()`, `matchSelected(String matchId)`, `lockRequested()`, `unlockRequested()`.
7. **AC7:** `BracketState` is `@freezed` at `lib/features/bracket/presentation/bloc/bracket_state.dart` with states: `initial()`, `loadInProgress()`, `loadSuccess({required BracketEntity bracket, required List<MatchEntity> matches, required BracketLayout layout, String? selectedMatchId})`, `loadFailure({required String userFriendlyMessage, String? technicalDetails})`, `lockInProgress()`, `unlockInProgress()`.
8. **AC8:** `BracketViewerWidget` is created at `lib/features/bracket/presentation/widgets/bracket_viewer_widget.dart` — renders the bracket inside `InteractiveViewer` with `constrained: false`, `minScale: 0.25`, `maxScale: 2.0`, `boundaryMargin: EdgeInsets.all(100)`. Uses `Stack` with `Positioned` children for match cards and `CustomPaint` for connector lines.
9. **AC9:** `MatchCardWidget` is created at `lib/features/bracket/presentation/widgets/match_card_widget.dart` — shows match number, participant names (red/blue), status indicator, score if completed. Visual distinction: pending (gray border), ready (blue border), in-progress (amber/gold border), completed (green border with winner highlighted), bye (dashed gray border).
10. **AC10:** `BracketConnectionLinesWidget` is created using `CustomPainter` at `lib/features/bracket/presentation/widgets/bracket_connection_lines_widget.dart` — draws horizontal and vertical connector lines between match slots showing advancement paths.
11. **AC11:** `RoundLabelWidget` is created at `lib/features/bracket/presentation/widgets/round_label_widget.dart` — shows round header text above each column of matches.
12. **AC12:** `RoundRobinTableWidget` is created at `lib/features/bracket/presentation/widgets/round_robin_table_widget.dart` — renders round robin brackets as a matrix/table showing all participants vs. all participants with match results in cells.
13. **AC13:** `BracketPage` is created at `lib/features/bracket/presentation/pages/bracket_page.dart` — scaffolds the `BracketBloc` provider, shows loading/error/success states, renders `BracketViewerWidget` (for elimination) or `RoundRobinTableWidget` (for round robin) based on `BracketType`, and provides lock/unlock button in the app bar.
14. **AC14:** Unit tests for `BracketLayoutEngineImplementation` verify: correct position calculations for 4-, 8-, and 16-participant single elimination brackets; correct round label assignment; correct canvas size computation; correct `advancesToSlot` linkage; double elimination layout includes winners + losers sections; round robin returns grid layout.
15. **AC15:** Unit tests for `BracketBloc` verify: emits `loadInProgress` then `loadSuccess` on `loadRequested`; emits `loadFailure` on repository error; updates `selectedMatchId` on `matchSelected`; calls `LockBracketUseCase` on `lockRequested` and refreshes state; calls `UnlockBracketUseCase` on `unlockRequested` and refreshes state.
16. **AC16:** Widget tests for `BracketViewerWidget` verify: renders `InteractiveViewer` with match cards; match card shows participant names and status; connector lines are rendered; tapping a match card triggers `matchSelected` event.
17. **AC17:** The `bracket.dart` barrel file is updated with exports for all new presentation files (BLoC, widgets, pages) and the new domain entities/services.

## Tasks / Subtasks

- [x] Task 1: Create `BracketLayout` and `BracketLayoutOptions` entities (AC: #1, #2)
  - [x] 1.1 Create `lib/features/bracket/domain/entities/bracket_layout.dart`
  - [x] 1.2 Define `BracketFormat` enum: `singleElimination`, `doubleElimination`, `roundRobin` — NOTE: This is separate from `BracketType` in `bracket_entity.dart`. `BracketFormat` is a layout concept; `BracketType` is a data concept (`winners`, `losers`, `pool`)
  - [x] 1.3 Define `BracketLayout`, `BracketRound`, `MatchSlot`, `BracketLayoutOptions` as `@immutable` classes with `const` constructors and `final` fields — do NOT use `@freezed` for these (they are simple value objects, not domain entities)
  - [x] 1.4 Import `dart:ui` for `Size` and `Offset` — Flutter provides this automatically, no package needed. Add `import 'dart:ui';` at the top of the file
  - [x] 1.5 Add `==` operator and `hashCode` overrides to `BracketLayout`, `BracketRound`, `MatchSlot` — required for BLoC state equality checks (BLoC uses `==` to decide whether to emit). Use `listEquals` from `package:flutter/foundation.dart` for `List` comparisons

- [x] Task 2: Create `BracketLayoutEngine` abstract service (AC: #3)
  - [x] 2.1 Create `lib/features/bracket/domain/services/bracket_layout_engine.dart`
  - [x] 2.2 Single method: `BracketLayout calculateLayout({...})`

- [ ] Task 3: Create `BracketLayoutEngineImplementation` (AC: #4)
  - [ ] 3.1 Create `lib/features/bracket/data/services/bracket_layout_engine_implementation.dart`
  - [ ] 3.2 `@LazySingleton(as: BracketLayoutEngine)`, inject nothing (pure computation). Import `package:injectable/injectable.dart`
  - [ ] 3.3 Determine `BracketFormat` from `BracketEntity.bracketType`: `BracketType.winners` → `BracketFormat.singleElimination` (default), `BracketType.losers` → SKIP (losers bracket is part of double elimination, handled by the parent winners bracket call), `BracketType.pool` → `BracketFormat.roundRobin`. NOTE: Double elimination produces TWO `BracketEntity` records (one `winners`, one `losers`). The layout engine receives the `winners` bracket and its matches. For double elimination detection, check if ANY match has `loserAdvancesToMatchId != null`
  - [ ] 3.4 Implement single elimination layout: group matches by `roundNumber`, sort each group by `matchNumberInRound`. For each round, compute `xPosition = (roundNumber - 1) * (matchCardWidth + horizontalSpacing)`. For round 1: distribute matches evenly. For subsequent rounds: y-center between the two feeding matches (find matches where `winnerAdvancesToMatchId == currentMatch.id`)
  - [ ] 3.5 Implement double elimination layout: apply single elimination layout to winners matches, then apply separate layout to losers matches offset below by `winnersCanvasHeight + 2 * verticalSpacing`. Add grand finals match at rightmost position centered vertically
  - [ ] 3.6 Implement round robin layout: return `BracketLayout(format: BracketFormat.roundRobin, rounds: [], canvasSize: Size.zero)` — the actual rendering is handled by `RoundRobinTableWidget` which uses `List<MatchEntity>` directly, NOT the layout engine
  - [ ] 3.7 Compute `canvasSize` based on: `width = totalRounds * (matchCardWidth + horizontalSpacing) + matchCardWidth`, `height = firstRoundMatchCount * (matchCardHeight + verticalSpacing) - verticalSpacing` (subtract one spacing to avoid trailing gap)
  - [ ] 3.8 Assign round labels: `_getRoundLabel(roundNumber, totalRounds)` → "Round 1", ..., "Quarterfinals", "Semifinals", "Finals" using `switch (totalRounds - roundNumber)` — see Dev Notes for exact implementation
  - [ ] 3.9 Link `advancesToSlot` — for each match with `winnerAdvancesToMatchId != null`, find the target match's `MatchSlot` and set `advancesToSlot` to reference it. This enables connector line drawing
  - [ ] 3.10 Handle edge cases: empty matches list → return empty layout; matches with no advancement links → terminal matches (finals); matches with only 1 participant → bye match (still rendered)

- [ ] Task 4: Create `BracketEvent` (AC: #6)
  - [ ] 4.1 Create `lib/features/bracket/presentation/bloc/bracket_event.dart`
  - [ ] 4.2 Add imports: `import 'package:freezed_annotation/freezed_annotation.dart';` and `part 'bracket_event.freezed.dart';`
  - [ ] 4.3 `@freezed` class with `loadRequested`, `refreshRequested`, `matchSelected`, `lockRequested`, `unlockRequested` events — see exact code in Dev Notes → Event/State Design
  - [ ] 4.4 DO NOT run build_runner yet — wait until Task 5 is also complete

- [ ] Task 5: Create `BracketState` and run build_runner (AC: #7)
  - [ ] 5.1 Create `lib/features/bracket/presentation/bloc/bracket_state.dart`
  - [ ] 5.2 Add imports: `import 'package:freezed_annotation/freezed_annotation.dart';`, `import 'bracket_entity.dart';`, `import 'match_entity.dart';`, `import 'bracket_layout.dart';` and `part 'bracket_state.freezed.dart';`
  - [ ] 5.3 `@freezed` class with `initial`, `loadInProgress`, `loadSuccess`, `loadFailure`, `lockInProgress`, `unlockInProgress` states — see exact code in Dev Notes → Event/State Design
  - [ ] 5.4 Run `dart run build_runner build --delete-conflicting-outputs` — this generates BOTH `bracket_event.freezed.dart` AND `bracket_state.freezed.dart` in a single run. Verify both files were generated before proceeding to Task 6

- [ ] Task 6: Create `BracketBloc` (AC: #5)
  - [ ] 6.1 Create `lib/features/bracket/presentation/bloc/bracket_bloc.dart`
  - [ ] 6.2 Add imports: `flutter_bloc`, `injectable`, `BracketRepository`, `MatchRepository`, `BracketLayoutEngine`, `LockBracketUseCase`, `UnlockBracketUseCase`, `LockBracketParams`, `UnlockBracketParams`, `BracketEntity`, `MatchEntity`, `BracketLayout`, `BracketLayoutOptions`, event file, state file
  - [ ] 6.3 `@injectable`, extends `Bloc<BracketEvent, BracketState>`. Constructor takes 5 positional params (see Dev Notes pattern)
  - [ ] 6.4 Store `String _currentBracketId = ''` as instance field for refresh support
  - [ ] 6.5 Implement `_onLoadRequested`: nested fold pattern — fetch bracket via `_bracketRepository.getBracketById(event.bracketId)`, on failure emit `loadFailure`, on success fetch matches via `_matchRepository.getMatchesForBracket(event.bracketId)`, on failure emit `loadFailure`, on success compute layout via `_layoutEngine.calculateLayout(bracket: bracket, matches: matches, options: const BracketLayoutOptions())`, emit `loadSuccess`. Store `_currentBracketId = event.bracketId` BEFORE the async calls. Full pattern:
    ```dart
    emit(const BracketLoadInProgress());
    _currentBracketId = event.bracketId;
    final bracketResult = await _bracketRepository.getBracketById(event.bracketId);
    await bracketResult.fold(
      (failure) async => emit(BracketLoadFailure(userFriendlyMessage: failure.userFriendlyMessage, technicalDetails: failure.technicalDetails)),
      (bracket) async {
        final matchesResult = await _matchRepository.getMatchesForBracket(event.bracketId);
        matchesResult.fold(
          (failure) => emit(BracketLoadFailure(userFriendlyMessage: failure.userFriendlyMessage, technicalDetails: failure.technicalDetails)),
          (matches) {
            final layout = _layoutEngine.calculateLayout(bracket: bracket, matches: matches, options: const BracketLayoutOptions());
            emit(BracketLoadSuccess(bracket: bracket, matches: matches, layout: layout));
          },
        );
      },
    );
    ```
  - [ ] 6.6 Implement `_onRefreshRequested`: guard against empty `_currentBracketId`, then `add(BracketLoadRequested(bracketId: _currentBracketId))`
  - [ ] 6.7 Implement `_onMatchSelected`: check `state is BracketLoadSuccess`, if so emit `(state as BracketLoadSuccess).copyWith(selectedMatchId: event.matchId)`. If not in loadSuccess, do nothing
  - [ ] 6.8 Implement `_onLockRequested`: check `state is BracketLoadSuccess`, get bracket from state, call `_lockBracketUseCase(LockBracketParams(bracketId: state.bracket.id))`, on success add `BracketRefreshRequested()`, on failure emit `BracketLoadFailure`
  - [ ] 6.9 Implement `_onUnlockRequested`: same pattern as lock but with `_unlockBracketUseCase(UnlockBracketParams(bracketId: state.bracket.id))`
  - [ ] 6.10 NO need to run build_runner again — BLoC file uses no code generation annotations beyond `@injectable` which is resolved at compile time by `injectable_generator`

- [ ] Task 7: Create `MatchCardWidget` (AC: #9)
  - [ ] 7.1 Create `lib/features/bracket/presentation/widgets/match_card_widget.dart`
  - [ ] 7.2 `StatelessWidget` with constructor params: `{required MatchEntity match, required bool isHighlighted, VoidCallback? onTap, Size? size}`. The `size` param allows the `BracketViewerWidget` to pass `matchSlot.size` for explicit sizing. If null, use defaults from `BracketLayoutOptions`
  - [ ] 7.3 Wrap in `GestureDetector(onTap: onTap)` with a `Card` inside. Card dimensions: `SizedBox(width: size?.width ?? 200, height: size?.height ?? 80)`
  - [ ] 7.4 Card border color based on `match.status`: `pending` → `Colors.grey.shade400`, `ready` → `colorScheme.primary`, `inProgress` → `Colors.amber`, `completed` → `Colors.green`, `cancelled` → `Colors.red`
  - [ ] 7.5 Card content: Column with 3 sections: header row (match number "M${match.matchNumberInRound}" + status dot), red participant row, blue participant row
  - [ ] 7.6 Winner row: if `match.winnerId == match.participantRedId`, highlight red row with bold text and subtle gold background. Same for blue
  - [ ] 7.7 Bye detection: if `match.resultType == MatchResultType.bye` OR (one participant is null and the other is not null), show dashed border and "BYE" text in empty participant slot
  - [ ] 7.8 Highlighted match: if `isHighlighted`, add elevated border with `colorScheme.primary` and slight elevation increase


- [ ] Task 8: Create `BracketConnectionLinesWidget` (AC: #10)
  - [ ] 8.1 Create `lib/features/bracket/presentation/widgets/bracket_connection_lines_widget.dart`
  - [ ] 8.2 Create `BracketConnectionLinesPainter extends CustomPainter` (NOT a widget — it's a painter used by `CustomPaint` widget)
  - [ ] 8.3 Constructor takes: `BracketLayout layout`, `Color lineColor`, `double lineWidth`
  - [ ] 8.4 In `paint()`: iterate over all rounds, for each `MatchSlot` where `advancesToSlot != null`, draw a connector: horizontal line from `(slot.position.dx + slot.size.width, slot.position.dy + slot.size.height / 2)` to midpoint X, then vertical to target Y, then horizontal to target slot left edge
  - [ ] 8.5 Override `shouldRepaint(covariant BracketConnectionLinesPainter oldDelegate) => layout != oldDelegate.layout || lineColor != oldDelegate.lineColor`
  - [ ] 8.6 Create wrapper `BracketConnectionLinesWidget extends StatelessWidget` that returns `CustomPaint(painter: BracketConnectionLinesPainter(...), size: layout.canvasSize)`

- [ ] Task 9: Create `RoundLabelWidget` (AC: #11)
  - [ ] 9.1 Create `lib/features/bracket/presentation/widgets/round_label_widget.dart`
  - [ ] 9.2 Simple `Text` widget with round name, styled with theme typography

- [ ] Task 10: Create `BracketViewerWidget` (AC: #8)
  - [ ] 10.1 Create `lib/features/bracket/presentation/widgets/bracket_viewer_widget.dart`
  - [ ] 10.2 `StatelessWidget` with constructor params: `{required BracketLayout layout, required List<MatchEntity> matches, String? selectedMatchId, required ValueChanged<String> onMatchTap}`
  - [ ] 10.3 Create a `Map<String, MatchEntity>` lookup from `matches` for O(1) access by matchId: `final matchMap = {for (final m in matches) m.id: m};`
  - [ ] 10.4 Wrap entire content in `InteractiveViewer(constrained: false, minScale: 0.25, maxScale: 2.0, boundaryMargin: const EdgeInsets.all(100))`
  - [ ] 10.5 Inside `InteractiveViewer`: `SizedBox(width: layout.canvasSize.width, height: layout.canvasSize.height)`
  - [ ] 10.6 Inside `SizedBox`: `Stack` with children:
    - First child: `BracketConnectionLinesWidget(layout: layout, lineColor: Theme.of(context).colorScheme.outlineVariant, lineWidth: 2.0)` — bottom layer
    - Then for each round in `layout.rounds`, for each `matchSlot` in round: `Positioned(left: matchSlot.position.dx, top: matchSlot.position.dy, child: MatchCardWidget(match: matchMap[matchSlot.matchId]!, isHighlighted: matchSlot.matchId == selectedMatchId, onTap: () => onMatchTap(matchSlot.matchId), size: matchSlot.size))`
    - Then for each round: `Positioned(left: round.xPosition, top: 0, child: RoundLabelWidget(label: round.roundLabel))`

- [ ] Task 11: Create `RoundRobinTableWidget` (AC: #12)
  - [ ] 11.1 Create `lib/features/bracket/presentation/widgets/round_robin_table_widget.dart`
  - [ ] 11.2 `StatelessWidget` accepting `List<MatchEntity>`, participant names map
  - [ ] 11.3 Render as `Table` or `DataTable` with participants as row/column headers, match results in cells

- [ ] Task 12: Create `BracketPage` (AC: #13)
  - [ ] 12.1 Create `lib/features/bracket/presentation/pages/bracket_page.dart`
  - [ ] 12.2 `StatelessWidget` that takes `bracketId` as constructor param
  - [ ] 12.3 In `build()`: wrap with `BlocProvider<BracketBloc>(create: (context) => getIt<BracketBloc>()..add(BracketLoadRequested(bracketId: bracketId)))` — use `getIt` from `injectable` for DI resolution
  - [ ] 12.4 Use `BlocBuilder<BracketBloc, BracketState>(builder: (context, state) => switch (state) { ... })` with pattern matching:
    - `BracketInitial() || BracketLoadInProgress() || BracketLockInProgress() || BracketUnlockInProgress()` → `Center(child: CircularProgressIndicator())`
    - `BracketLoadFailure(:final userFriendlyMessage)` → error column with message + retry button (`context.read<BracketBloc>().add(const BracketRefreshRequested())`)
    - `BracketLoadSuccess(:final bracket, :final matches, :final layout, :final selectedMatchId)` → check bracket type for rendering
  - [ ] 12.5 Bracket type routing: `bracket.bracketType == BracketType.pool` → render `RoundRobinTableWidget(matches: matches)`, otherwise render `BracketViewerWidget(layout: layout, matches: matches, selectedMatchId: selectedMatchId, onMatchTap: (id) => context.read<BracketBloc>().add(BracketMatchSelected(id)))`
  - [ ] 12.6 AppBar actions: `IconButton(icon: Icon(bracket.isFinalized ? Icons.lock : Icons.lock_open), onPressed: () => context.read<BracketBloc>().add(bracket.isFinalized ? const BracketUnlockRequested() : const BracketLockRequested()))`, tooltip: bracket.isFinalized ? 'Unlock Bracket' : 'Lock Bracket'

- [ ] Task 13: Update barrel file (AC: #17)
  - [ ] 13.1 Add these domain exports to `lib/features/bracket/bracket.dart` after line 21 (after `match_entity.dart`):
    ```dart
    export 'domain/entities/bracket_layout.dart';
    export 'domain/services/bracket_layout_engine.dart';
    ```
  - [ ] 13.1b Also add these use case exports after line 32 (after the last usecase export) — these were created in Stories 5.11-5.12 but not yet exported:
    ```dart
    export 'domain/usecases/lock_bracket_params.dart';
    export 'domain/usecases/lock_bracket_use_case.dart';
    export 'domain/usecases/unlock_bracket_params.dart';
    export 'domain/usecases/unlock_bracket_use_case.dart';
    export 'domain/usecases/regenerate_bracket_params.dart';
    export 'domain/usecases/regenerate_bracket_result.dart';
    export 'domain/usecases/regenerate_bracket_use_case.dart';
    ```
  - [ ] 13.2 Add these exports under the data section (after the existing service exports):
    ```dart
    export 'data/services/bracket_layout_engine_implementation.dart';
    ```
  - [ ] 13.3 Add these exports under the `// Presentation exports` comment (currently empty):
    ```dart
    export 'presentation/bloc/bracket_bloc.dart';
    export 'presentation/bloc/bracket_event.dart';
    export 'presentation/bloc/bracket_state.dart';
    export 'presentation/pages/bracket_page.dart';
    export 'presentation/widgets/bracket_connection_lines_widget.dart';
    export 'presentation/widgets/bracket_viewer_widget.dart';
    export 'presentation/widgets/match_card_widget.dart';
    export 'presentation/widgets/round_label_widget.dart';
    export 'presentation/widgets/round_robin_table_widget.dart';
    ```
  - [ ] 13.4 DO NOT export `.freezed.dart` files — they are `part` files and must NOT be exported

- [ ] Task 14: Write `BracketLayoutEngineImplementation` tests (AC: #14)
  - [ ] 14.1 Create `test/features/bracket/data/services/bracket_layout_engine_implementation_test.dart`
  - [ ] 14.2 Test: 4-participant single elimination → 2 rounds, 3 matches, correct positions
  - [ ] 14.3 Test: 8-participant single elimination → 3 rounds, 7 matches, correct vertical centering
  - [ ] 14.4 Test: 16-participant single elimination → 4 rounds, 15 matches, correct canvas size
  - [ ] 14.5 Test: round labels → last round = "Finals", second-to-last = "Semifinals"
  - [ ] 14.6 Test: canvas size = correct width/height based on options
  - [ ] 14.7 Test: advancesToSlot linkage is correct (winner of R1M1 → R2M1)
  - [ ] 14.8 Test: round robin layout → flat grid with no advancement slots

- [ ] Task 15: Write `BracketBloc` tests (AC: #15)
  - [ ] 15.1 Create `test/features/bracket/presentation/bloc/bracket_bloc_test.dart`
  - [ ] 15.2 Define mock classes at file top:
    ```dart
    class MockBracketRepository extends Mock implements BracketRepository {}
    class MockMatchRepository extends Mock implements MatchRepository {}
    class MockBracketLayoutEngine extends Mock implements BracketLayoutEngine {}
    class MockLockBracketUseCase extends Mock implements LockBracketUseCase {}
    class MockUnlockBracketUseCase extends Mock implements UnlockBracketUseCase {}
    class FakeBracketEntity extends Fake implements BracketEntity {}
    class FakeLockBracketParams extends Fake implements LockBracketParams {}
    class FakeUnlockBracketParams extends Fake implements UnlockBracketParams {}
    ```
  - [ ] 15.3 In `setUpAll`, register fallback values:
    ```dart
    setUpAll(() {
      registerFallbackValue(FakeBracketEntity());
      registerFallbackValue(FakeLockBracketParams());
      registerFallbackValue(FakeUnlockBracketParams());
    });
    ```
  - [ ] 15.4 Create helper `BracketBloc buildBloc()` that returns `BracketBloc(mockBracketRepo, mockMatchRepo, mockLayoutEngine, mockLockUseCase, mockUnlockUseCase)`
  - [ ] 15.5 Create test fixtures: `testBracket` (BracketEntity with `id: 'b1'`, `bracketType: BracketType.winners`, `totalRounds: 2`), `testMatches` (3 MatchEntity records), `testLayout` (BracketLayout with 2 rounds)
  - [ ] 15.6 Use `bloc_test` package: `blocTest<BracketBloc, BracketState>(...)`
  - [ ] 15.7 Test: initial state is `BracketInitial`
  - [ ] 15.8 Test: `loadRequested` → emits `[BracketLoadInProgress, BracketLoadSuccess]` — mock both repos to return `Right`, mock layout engine to return `testLayout`
  - [ ] 15.9 Test: `loadRequested` with bracketRepo failure → emits `[BracketLoadInProgress, BracketLoadFailure]`
  - [ ] 15.10 Test: `loadRequested` with matchRepo failure → emits `[BracketLoadInProgress, BracketLoadFailure]` — bracketRepo succeeds but matchRepo fails
  - [ ] 15.11 Test: `matchSelected` → seed with `BracketLoadSuccess`, emits `BracketLoadSuccess` with `selectedMatchId` updated. Use `seed: () => BracketLoadSuccess(bracket: testBracket, matches: testMatches, layout: testLayout)`
  - [ ] 15.12 Test: `matchSelected` when NOT in loadSuccess → emits nothing
  - [ ] 15.13 Test: `lockRequested` success → calls `LockBracketUseCase`, verify via `verify(() => mockLockUseCase(any())).called(1)`
  - [ ] 15.14 Test: `unlockRequested` success → calls `UnlockBracketUseCase`
  - [ ] 15.15 Test: `lockRequested` failure → emits `BracketLoadFailure`

- [ ] Task 16: Write widget tests (AC: #16)
  - [ ] 16.1 Create `test/features/bracket/presentation/widgets/bracket_viewer_widget_test.dart`
  - [ ] 16.2 Test: renders `InteractiveViewer`
  - [ ] 16.3 Test: renders match cards for each match in layout
  - [ ] 16.4 Test: tapping match card invokes `onMatchTap` callback
  - [ ] 16.5 Create `test/features/bracket/presentation/widgets/match_card_widget_test.dart`
  - [ ] 16.6 Test: shows participant names when provided
  - [ ] 16.7 Test: shows correct border color per match status
  - [ ] 16.8 Test: winner row is highlighted

- [ ] Task 17: Run analysis and verify all tests pass (AC: all)
  - [ ] 17.1 Run `dart run build_runner build --delete-conflicting-outputs`
  - [ ] 17.2 Run `dart analyze` — zero errors, zero warnings
  - [ ] 17.3 Run all new tests — all pass
  - [ ] 17.4 Run full test suite — all pass (regression check)

## Dev Notes

### ⚠️ Scope Boundary: Presentation Layer + Layout Engine

This story introduces the **first presentation layer code** in the bracket feature. It creates:
- **1 domain entity** (`BracketLayout` with supporting classes)
- **1 domain service** (`BracketLayoutEngine` interface)
- **1 data service** (`BracketLayoutEngineImplementation`)
- **3 BLoC files** (events, states, bloc)
- **6 widget files** (viewer, match card, connection lines, round label, round robin table, bracket page)
- **Updates to 1 barrel file**

**This story does NOT:**
- Add routing/navigation to the bracket page (that's a separate integration story)
- Add participant name resolution from `ParticipantEntity` (match cards show `participantRedId`/`participantBlueId` values for now; future stories will resolve names)
- Add drag-and-drop seed override UI (FR29 — separate story)
- Add scoring modal or score entry (Epic 6)
- Add venue display mode (separate story)
- Add PDF export (Epic 7)
- Add animations for match progression (enhancement story)
- Add real-time updates via Supabase Realtime (Epic 6)

### Architecture Decision: Widget-Based Rendering

Per the architecture document (Section 4: "Bracket Visualization Rendering Architecture"):
- **Widget-based rendering** using `InteractiveViewer` for zoom/pan
- Widgets integrate naturally with BLoC state updates
- `InteractiveViewer` provides zoom/pan out of the box
- Easier accessibility (Semantics) than Canvas-based approaches
- For very large brackets (128+ participants), consider `CustomPainter` optimization later (NOT this story)

The `BracketConnectionLinesWidget` is the ONLY component using `CustomPainter` — it draws connector lines between matches. All match cards and labels use standard Flutter widgets.

### BLoC Pattern — Follow TournamentBloc Exactly

The existing `TournamentBloc` at `lib/features/tournament/presentation/bloc/tournament_bloc.dart` establishes the pattern:

```dart
// Pattern from TournamentBloc:
@injectable
class BracketBloc extends Bloc<BracketEvent, BracketState> {
  BracketBloc(
    this._bracketRepository,
    this._matchRepository,
    this._layoutEngine,
    this._lockBracketUseCase,
    this._unlockBracketUseCase,
  ) : super(const BracketInitial()) {
    on<BracketLoadRequested>(_onLoadRequested);
    on<BracketRefreshRequested>(_onRefreshRequested);
    on<BracketMatchSelected>(_onMatchSelected);
    on<BracketLockRequested>(_onLockRequested);
    on<BracketUnlockRequested>(_onUnlockRequested);
  }
  
  final BracketRepository _bracketRepository;
  final MatchRepository _matchRepository;
  final BracketLayoutEngine _layoutEngine;
  final LockBracketUseCase _lockBracketUseCase;
  final UnlockBracketUseCase _unlockBracketUseCase;
  
  String _currentBracketId = '';
```

**⚠️ Event/State Naming Convention:** Use `BracketLoadRequested`, `BracketLoadInProgress`, `BracketLoadSuccess`, `BracketLoadFailure` — following the same `Feature` + `Action` + `Status` pattern as `TournamentLoadRequested`, `TournamentLoadInProgress`, etc.

**⚠️ `@freezed` for Events and States:** Both `BracketEvent` and `BracketState` use `@freezed` with `part 'bracket_event.freezed.dart'` / `part 'bracket_state.freezed.dart'`. This requires `dart run build_runner` after creating these files.

**⚠️ Injectable Registration:** The BLoC uses `@injectable` (NOT `@lazySingleton`). BLoCs are feature-scoped and disposed on navigation — they must be created fresh each time via `BlocProvider`.

### Event/State Design

#### BracketEvent

```dart
@freezed
class BracketEvent with _$BracketEvent {
  const factory BracketEvent.loadRequested({required String bracketId}) =
      BracketLoadRequested;
  const factory BracketEvent.refreshRequested() = BracketRefreshRequested;
  const factory BracketEvent.matchSelected(String matchId) =
      BracketMatchSelected;
  const factory BracketEvent.lockRequested() = BracketLockRequested;
  const factory BracketEvent.unlockRequested() = BracketUnlockRequested;
}
```

#### BracketState

```dart
@freezed
class BracketState with _$BracketState {
  const factory BracketState.initial() = BracketInitial;
  const factory BracketState.loadInProgress() = BracketLoadInProgress;
  const factory BracketState.loadSuccess({
    required BracketEntity bracket,
    required List<MatchEntity> matches,
    required BracketLayout layout,
    String? selectedMatchId,
  }) = BracketLoadSuccess;
  const factory BracketState.loadFailure({
    required String userFriendlyMessage,
    String? technicalDetails,
  }) = BracketLoadFailure;
  const factory BracketState.lockInProgress() = BracketLockInProgress;
  const factory BracketState.unlockInProgress() = BracketUnlockInProgress;
}
```

### Layout Engine — Position Calculation Algorithm

**Single Elimination (Binary Tree Layout):**

```
Round 1       Round 2       Semifinals    Finals
┌─────┐
│ M1  │───┐
└─────┘   │  ┌─────┐
          ├──│ M5  │───┐
┌─────┐   │  └─────┘   │
│ M2  │───┘            │  ┌─────┐
└─────┘                ├──│ M7  │
                       │  └─────┘
┌─────┐                │
│ M3  │───┐            │
└─────┘   │  ┌─────┐   │
          ├──│ M6  │───┘
┌─────┐   │  └─────┘
│ M4  │───┘
└─────┘
```

**Position Formulas (for each match in round `r`, match index `m`):**
- `xPosition = r * (matchCardWidth + horizontalSpacing)`
- `yPosition` = center of the two feeding matches' y-positions (or evenly distributed for round 1)
- `canvasWidth = totalRounds * (matchCardWidth + horizontalSpacing) + matchCardWidth`
- `canvasHeight = firstRoundMatchCount * (matchCardHeight + verticalSpacing)`

**Round Labels:**
```dart
String _getRoundLabel(int roundNumber, int totalRounds) {
  final roundsFromEnd = totalRounds - roundNumber;
  return switch (roundsFromEnd) {
    0 => 'Finals',
    1 => 'Semifinals',
    2 => 'Quarterfinals',
    _ => 'Round $roundNumber',
  };
}
```

**Double Elimination:**
- Winners bracket rendered on top (using single elimination layout)
- Losers bracket rendered below with a gap of `2 * verticalSpacing`
- Losers bracket has `2 * (totalRounds - 1)` rounds (each losers round has fewer matches)
- Grand Finals match positioned at the rightmost column, vertically centered between winners and losers

**Round Robin:**
- No tree layout — return a `BracketLayout` with `format: BracketFormat.roundRobin`
- `canvasSize` based on participant count × cell dimensions
- Each `MatchSlot` represents a cell in the NxN matrix
- The `BracketViewerWidget` checks `format` and delegates to `RoundRobinTableWidget` instead

### Existing Repository Interfaces (DO NOT MODIFY)

#### BracketRepository

```dart
abstract class BracketRepository {
  Future<Either<Failure, List<BracketEntity>>> getBracketsForDivision(String divisionId);
  Future<Either<Failure, BracketEntity>> getBracketById(String id);       // ← USED
  Future<Either<Failure, BracketEntity>> createBracket(BracketEntity bracket);
  Future<Either<Failure, BracketEntity>> updateBracket(BracketEntity bracket);
  Future<Either<Failure, Unit>> deleteBracket(String id);
}
```

#### MatchRepository

```dart
abstract class MatchRepository {
  Future<Either<Failure, List<MatchEntity>>> getMatchesForBracket(String bracketId);  // ← USED
  Future<Either<Failure, List<MatchEntity>>> getMatchesForRound(String bracketId, int roundNumber);
  Future<Either<Failure, MatchEntity>> getMatchById(String id);
  Future<Either<Failure, MatchEntity>> createMatch(MatchEntity match);
  Future<Either<Failure, List<MatchEntity>>> createMatches(List<MatchEntity> matches);
  Future<Either<Failure, MatchEntity>> updateMatch(MatchEntity match);
  Future<Either<Failure, Unit>> deleteMatch(String id);
}
```

### Existing Entities (DO NOT MODIFY)

#### BracketEntity

```dart
@freezed
class BracketEntity with _$BracketEntity {
  const factory BracketEntity({
    required String id,
    required String divisionId,
    required BracketType bracketType,    // winners, losers, pool
    required int totalRounds,
    required DateTime createdAtTimestamp,
    required DateTime updatedAtTimestamp,
    String? poolIdentifier,
    @Default(false) bool isFinalized,    // Lock mechanism
    DateTime? generatedAtTimestamp,
    DateTime? finalizedAtTimestamp,
    Map<String, dynamic>? bracketDataJson,
    @Default(1) int syncVersion,
    @Default(false) bool isDeleted,
    DateTime? deletedAtTimestamp,
    @Default(false) bool isDemoData,
  }) = _BracketEntity;
  const BracketEntity._();
}

enum BracketType { winners('winners'), losers('losers'), pool('pool'); ... }
```

**⚠️ `BracketType` is in the SAME file as `BracketEntity`.** Import `bracket_entity.dart` to get both.

#### MatchEntity

```dart
@freezed
class MatchEntity with _$MatchEntity {
  const factory MatchEntity({
    required String id,
    required String bracketId,
    required int roundNumber,
    required int matchNumberInRound,
    required DateTime createdAtTimestamp,
    required DateTime updatedAtTimestamp,
    String? participantRedId,
    String? participantBlueId,
    String? winnerId,
    String? winnerAdvancesToMatchId,    // ← CRITICAL for connector lines
    String? loserAdvancesToMatchId,     // ← For double elimination
    int? scheduledRingNumber,
    DateTime? scheduledTime,
    @Default(MatchStatus.pending) MatchStatus status,
    MatchResultType? resultType,
    String? notes,
    DateTime? startedAtTimestamp,
    DateTime? completedAtTimestamp,
    @Default(1) int syncVersion,
    @Default(false) bool isDeleted,
    DateTime? deletedAtTimestamp,
    @Default(false) bool isDemoData,
  }) = _MatchEntity;
  const MatchEntity._();
}

enum MatchStatus { pending, ready, inProgress, completed, cancelled; ... }
enum MatchResultType { points, knockout, disqualification, withdrawal, refereeDecision, bye; ... }
```

**⚠️ `MatchStatus` and `MatchResultType` are in the SAME file as `MatchEntity`.** Import `match_entity.dart` to get all three.

### Lock/Unlock Use Cases (Already Exist from Story 5.12)

```dart
// lib/features/bracket/domain/usecases/lock_bracket_use_case.dart
@injectable
class LockBracketUseCase extends UseCase<BracketEntity, LockBracketParams> { ... }

// lib/features/bracket/domain/usecases/unlock_bracket_use_case.dart
@injectable
class UnlockBracketUseCase extends UseCase<BracketEntity, UnlockBracketParams> { ... }
```

The `BracketBloc` uses these directly. Parameters contain only `bracketId` (String).

### UX Requirements from Spec

From UX Design Specification:
- **Bracket View Mode:** Canvas-based bracket display, zoom/pan controls, match detail popups, clear visual hierarchy for rounds
- **States:** Default (full view), Focused (selected match highlighted), Completed (winner path highlighted)
- **Variants:** Single Elimination, Double Elimination, Round Robin
- **Layout:** Horizontal tree structure, left-to-right progression
- **Interaction:** Pan, zoom, click match for details
- **Accessibility:** Keyboard navigation, screen reader announcements, focus indicators

### Match Card Visual Design

```
┌──────────────────────────┐
│  M1                ●     │  ← Match number + status dot
├──────────────────────────┤
│  🔴 Participant Red ID   │  ← Red side (top)
│  Score: --               │
├──────────────────────────┤
│  🔵 Participant Blue ID  │  ← Blue side (bottom)
│  Score: --               │
└──────────────────────────┘

Status dot colors:
  ● Gray    = pending
  ● Blue    = ready
  ● Amber   = in_progress
  ● Green   = completed
  ● Red     = cancelled
  ◌ Dashed  = bye
```

### Theme Integration

Use Material Design 3 theme from `AppTheme`:
- Primary seed color: `Color(0xFF1E3A5F)` (Navy)
- Use `Theme.of(context).colorScheme` for all colors
- Match cards: `Card` widget with `elevation: 1`, rounded corners (8px per UX spec)
- Round labels: `Theme.of(context).textTheme.titleMedium`
- Connector lines: `Theme.of(context).colorScheme.outlineVariant`

### Testing Patterns

**BLoC Tests — Use `bloc_test` package:**

```dart
import 'package:bloc_test/bloc_test.dart';

blocTest<BracketBloc, BracketState>(
  'emits [loadInProgress, loadSuccess] when loadRequested succeeds',
  build: () {
    when(() => mockBracketRepo.getBracketById('b1'))
        .thenAnswer((_) async => Right(testBracket));
    when(() => mockMatchRepo.getMatchesForBracket('b1'))
        .thenAnswer((_) async => Right(testMatches));
    when(() => mockLayoutEngine.calculateLayout(
          bracket: any(named: 'bracket'),
          matches: any(named: 'matches'),
          options: any(named: 'options'),
        )).thenReturn(testLayout);
    return BracketBloc(mockBracketRepo, mockMatchRepo, mockLayoutEngine, 
                        mockLockUseCase, mockUnlockUseCase);
  },
  act: (bloc) => bloc.add(const BracketLoadRequested(bracketId: 'b1')),
  expect: () => [
    const BracketLoadInProgress(),
    isA<BracketLoadSuccess>()
        .having((s) => s.bracket.id, 'bracket.id', 'b1'),
  ],
);
```

**⚠️ `bloc_test` dependency** — verify it's in `dev_dependencies` of `pubspec.yaml`. It should already be there since `TournamentBloc` was tested.

**Widget Tests:**

```dart
testWidgets('MatchCardWidget shows participant IDs', (tester) async {
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
  
  expect(find.text('participant-red-id'), findsOneWidget);
  expect(find.text('participant-blue-id'), findsOneWidget);
});
```

**Layout Engine Tests (Unit — No Flutter dependencies needed for pure computation):**

```dart
test('4-participant single elimination → 2 rounds, 3 matches', () {
  final engine = BracketLayoutEngineImplementation();
  final bracket = BracketEntity(
    id: 'b1', divisionId: 'd1', bracketType: BracketType.winners,
    totalRounds: 2, createdAtTimestamp: DateTime(2026), updatedAtTimestamp: DateTime(2026),
  );
  final matches = [
    // 2 first-round matches + 1 final
    _makeMatch('m1', roundNumber: 1, matchNumberInRound: 1, winnerAdvancesToMatchId: 'm3'),
    _makeMatch('m2', roundNumber: 1, matchNumberInRound: 2, winnerAdvancesToMatchId: 'm3'),
    _makeMatch('m3', roundNumber: 2, matchNumberInRound: 1),
  ];
  
  final layout = engine.calculateLayout(
    bracket: bracket, matches: matches, options: const BracketLayoutOptions(),
  );
  
  expect(layout.rounds.length, 2);
  expect(layout.rounds[0].matchSlots.length, 2);
  expect(layout.rounds[1].matchSlots.length, 1);
  expect(layout.rounds[1].roundLabel, 'Finals');
});
```

### build_runner Requirement

This story creates multiple `@freezed` files (events, states). After creating Tasks 4 and 5, you **MUST** run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates:
- `bracket_event.freezed.dart`
- `bracket_state.freezed.dart`

Do NOT proceed to Task 6 (BracketBloc implementation) until the generated files exist.

### Project Structure Notes

New files created by this story:
```
lib/features/bracket/
├── domain/
│   ├── entities/
│   │   └── bracket_layout.dart                          # NEW
│   └── services/
│       └── bracket_layout_engine.dart                   # NEW
├── data/
│   └── services/
│       └── bracket_layout_engine_implementation.dart     # NEW
└── presentation/
    ├── bloc/
    │   ├── bracket_bloc.dart                            # NEW
    │   ├── bracket_event.dart                           # NEW
    │   ├── bracket_event.freezed.dart                   # GENERATED
    │   ├── bracket_state.dart                           # NEW
    │   └── bracket_state.freezed.dart                   # GENERATED
    ├── pages/
    │   └── bracket_page.dart                            # NEW
    └── widgets/
        ├── bracket_viewer_widget.dart                   # NEW
        ├── bracket_connection_lines_widget.dart          # NEW
        ├── match_card_widget.dart                        # NEW
        ├── round_label_widget.dart                       # NEW
        └── round_robin_table_widget.dart                 # NEW

test/features/bracket/
├── data/
│   └── services/
│       └── bracket_layout_engine_implementation_test.dart  # NEW
├── presentation/
│   ├── bloc/
│   │   └── bracket_bloc_test.dart                         # NEW
│   └── widgets/
│       ├── bracket_viewer_widget_test.dart                 # NEW
│       └── match_card_widget_test.dart                     # NEW
```

Modified files:
```
lib/features/bracket/bracket.dart   # MODIFIED — add new exports
```

### ⚠️ Common LLM Mistakes — Prevention Rules

| #   | Mistake                                                                    | Correct Approach                                                                                                                                                                                        |
| --- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Using `@freezed` for `BracketLayout`, `BracketRound`, `MatchSlot`          | These are simple value objects — use `@immutable` annotation with manual `const` constructors and `final` fields. `@freezed` is only for domain entities and BLoC events/states                         |
| 2   | Confusing `BracketType` (data model) with `BracketFormat` (layout concept) | `BracketType` has values `winners`, `losers`, `pool` — it's in `bracket_entity.dart`. `BracketFormat` has values `singleElimination`, `doubleElimination`, `roundRobin` — it's in `bracket_layout.dart` |
| 3   | Using `@lazySingleton` for `BracketBloc`                                   | BLoCs MUST use `@injectable` (NOT `@lazySingleton`). They are feature-scoped and disposed on navigation via `BlocProvider`                                                                              |
| 4   | Importing `.freezed.dart` files directly                                   | NEVER import `.freezed.dart` or `.g.dart` files — only import the source file which has the `part` directive                                                                                            |
| 5   | Exporting `.freezed.dart` files in barrel                                  | NEVER export `.freezed.dart` files — they are `part` files. Only export the source `.dart` file                                                                                                         |
| 6   | Using `context.read<BracketBloc>()` outside of callbacks                   | `context.read` is fine in `onPressed` callbacks and `BlocListener`. For build-time access, use `context.watch` or `BlocBuilder`                                                                         |
| 7   | Creating `BracketBloc()` directly in widget                                | Use `getIt<BracketBloc>()` via `injectable` for DI resolution. The BLoC has 5 injected dependencies resolved by the DI container                                                                        |
| 8   | Forgetting `registerFallbackValue` in BLoC tests                           | `any()` matchers require fallback values. Register `FakeBracketEntity`, `FakeLockBracketParams`, `FakeUnlockBracketParams` in `setUpAll`                                                                |
| 9   | Not handling BOTH repo failures in `_onLoadRequested`                      | `_onLoadRequested` calls TWO repos sequentially. BOTH can fail. Must emit `loadFailure` if either fails — use nested fold pattern                                                                       |
| 10  | Using `BlocProvider.value` instead of `BlocProvider(create:)`              | Use `BlocProvider(create: (context) => getIt<BracketBloc>()..add(...))` — the `create` form manages BLoC lifecycle. `.value` is for re-providing an existing BLoC                                       |
| 11  | Forgetting `part` directive in event/state files                           | `bracket_event.dart` MUST have `part 'bracket_event.freezed.dart';` and `bracket_state.dart` MUST have `part 'bracket_state.freezed.dart';`                                                             |
| 12  | Using `Offset` from wrong import                                           | `Offset` is from `dart:ui` — this is automatically available in Flutter projects. Import `'dart:ui'` at the top of `bracket_layout.dart`                                                                |
| 13  | Making `BracketLayoutEngine` a widget or BLoC                              | It's a pure computation service — `@LazySingleton`. It takes data in, returns data out. No side effects, no async operations, no state                                                                  |
| 14  | Not linking `advancesToSlot` correctly                                     | Use `MatchEntity.winnerAdvancesToMatchId` to find the target match. Then look up that match's `MatchSlot` by ID. Set `advancesToSlot` to the found `MatchSlot`                                          |
| 15  | Using `throw Exception()` in fold error handling in tests                  | Use `fail('Should have failed')` — matches existing test pattern across the codebase                                                                                                                    |
| 16  | Forgetting `..add(BracketLoadRequested(...))` in BlocProvider create       | The BLoC must be initialized with data: `getIt<BracketBloc>()..add(BracketLoadRequested(bracketId: bracketId))`. Without this, the page shows `BracketInitial` forever                                  |
| 17  | Using `Size` from `dart:ui` in non-Flutter test files                      | Layout engine tests import `dart:ui` for `Size` and `Offset`. This works in Flutter test runner but NOT in plain Dart tests. Use `flutter test` (not `dart test`) for these tests                       |

### Exact Import Paths for All New Files

**bracket_layout.dart:**
```dart
import 'dart:ui' show Offset, Size;
import 'package:flutter/foundation.dart' show immutable, listEquals;
```

**bracket_layout_engine.dart:**
```dart
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_layout.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
```

**bracket_layout_engine_implementation.dart:**
```dart
import 'dart:ui' show Offset, Size;
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_layout.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/services/bracket_layout_engine.dart';
```

**bracket_event.dart:**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'bracket_event.freezed.dart';
```

**bracket_state.dart:**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_layout.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
part 'bracket_state.freezed.dart';
```

**bracket_bloc.dart:**
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_layout.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/services/bracket_layout_engine.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/lock_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/lock_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/unlock_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/unlock_bracket_use_case.dart';
import 'bracket_event.dart';
import 'bracket_state.dart';
```

**bracket_page.dart:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tkd_brackets/core/di/injection.dart'; // getIt lives here
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_bloc.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_event.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_state.dart';
import 'package:tkd_brackets/features/bracket/presentation/widgets/bracket_viewer_widget.dart';
import 'package:tkd_brackets/features/bracket/presentation/widgets/round_robin_table_widget.dart';
```

### Dependency Injection — `getIt` Pattern

The project uses `injectable` + `get_it` for DI. The `getIt` instance is at `lib/core/di/injection.dart`:

```dart
import 'package:tkd_brackets/core/di/injection.dart'; // exports `getIt`

// In BracketPage.build():
BlocProvider<BracketBloc>(
  create: (context) => getIt<BracketBloc>()
    ..add(BracketLoadRequested(bracketId: bracketId)),
  child: BlocBuilder<BracketBloc, BracketState>(
    builder: (context, state) => switch (state) { ... },
  ),
)
```

### Previous Story Intelligence

Learnings from Stories 5.10-5.12 that impact this story:

1. **`Left.new` tear-off**: The project standard for error propagation in `.fold()`. Do NOT use `(failure) => Left(failure)` — use `Left.new`
2. **`registerFallbackValue` pattern**: Must register in `setUpAll`, not `setUp`. Use `Fake` classes that extend `Fake implements X`
3. **`BracketType.winners`**: Used in test fixtures when creating `BracketEntity`. Import from `bracket_entity.dart`
4. **`MatchStatus.pending`**: Default value for `MatchEntity.status`. Used in test fixtures. Import from `match_entity.dart`
5. **Test file assertion pattern**: Use `isA<Type>().having(...)` for complex matcher chains — see TournamentBloc tests for examples
6. **`copyWith` on freezed**: Works correctly for nullable fields. `copyWith(selectedMatchId: 'new-id')` will update correctly
7. **`fail('Should have failed')` in test fold**: Project standard instead of `throw Exception('unexpected')`
8. **Params import pattern**: `LockBracketParams` is in `lock_bracket_params.dart` (separate file from use case). `UnlockBracketParams` is in `unlock_bracket_params.dart`

### References

- [Source: architecture.md#4. Bracket Visualization Rendering Architecture] — Widget architecture, layout engine, animation system, venue display
- [Source: ux-design-specification.md#1. Bracket Visualization Widget] — Component specification, states, variants, accessibility
- [Source: epics.md#Story 5.13] — User story, acceptance criteria
- [Source: architecture.md#Feature-Scoped BLoCs] — BracketBloc listed as feature-scoped (disposed on navigation)
- [Source: architecture.md#Technology Stack] — flutter_bloc ^9.0.0, InteractiveViewer for zoom/pan
- [Source: 5-12-bracket-lock-and-unlock.md] — LockBracketUseCase, UnlockBracketUseCase patterns
- [Source: lib/core/di/injection.dart] — getIt DI container setup
- [Source: lib/core/error/failures.dart] — All failure types: ValidationFailure, LocalCacheAccessFailure, LocalCacheWriteFailure, NotFoundFailure, ServerConnectionFailure
- [Source: test/features/tournament/presentation/bloc/tournament_bloc_test.dart] — BLoC test pattern with bloc_test, mocktail, registerFallbackValue

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
