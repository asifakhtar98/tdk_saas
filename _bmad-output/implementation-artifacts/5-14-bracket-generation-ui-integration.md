# Story 5.14: Bracket Generation UI Integration

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an organizer,
I want a UI to generate, regenerate, and manage bracket seeding from the division view,
so that I can apply bracket algorithms to my divisions and navigate to bracket visualization (FR23-FR31).

## Acceptance Criteria

1. **AC1:** A `BracketGenerationRoute` is added to `routes.dart` with path `/tournaments/:tournamentId/divisions/:divisionId/brackets` and registered in the app router shell routes. It renders `BracketGenerationPage`.
2. **AC2:** `BracketGenerationPage` is created at `lib/features/bracket/presentation/pages/bracket_generation_page.dart`. It loads the division's participants and existing brackets on init. Shows loading/error/success states using `BlocBuilder`.
3. **AC3:** `BracketGenerationBloc` is created at `lib/features/bracket/presentation/bloc/bracket_generation_bloc.dart` using `@injectable`. It manages the full generation workflow: loading division data, selecting bracket format, triggering generation, regeneration, and navigation to bracket viewer.
4. **AC4:** `BracketGenerationEvent` includes: `loadRequested({required String divisionId})`, `formatSelected(BracketFormat format)`, `generateRequested()`, `regenerateRequested()`, `navigateToBracketRequested(String bracketId)`.
5. **AC5:** `BracketGenerationState` includes: `initial()`, `loadInProgress()`, `loadSuccess({required DivisionEntity division, required List<ParticipantEntity> participants, required List<BracketEntity> existingBrackets, BracketFormat? selectedFormat})`, `generationInProgress()`, `generationSuccess({required String generatedBracketId})`, `loadFailure({required String userFriendlyMessage, String? technicalDetails})`.
6. **AC6:** A "Generate Bracket" bottom sheet or dialog (`BracketFormatSelectionDialog`) is shown when no brackets exist, allowing the user to choose Single Elimination, Double Elimination, or Round Robin format. The dialog dispatches `formatSelected` then `generateRequested`.
7. **AC7:** When brackets already exist, a "Regenerate Bracket" action is available via an AppBar action button. It prompts for confirmation, then dispatches `regenerateRequested` which calls `RegenerateBracketUseCase`.
8. **AC8:** After successful generation/regeneration, the page navigates to `BracketPage` (from Story 5.13) with the newly created bracket ID.
9. **AC9:** If existing brackets are found on load, the page displays a list of brackets (winners bracket, losers bracket, pools) with tap-to-navigate to `BracketPage`.
10. **AC10:** Lock/Unlock actions are accessible from the bracket list items or delegated to `BracketPage`.
11. **AC11:** Unit tests for `BracketGenerationBloc` verify: emits correct states for load → format selection → generation flow; handles generation failures; handles regeneration flow; emits correct states when existing brackets are found.
12. **AC12:** Widget tests for `BracketGenerationPage` verify: renders loading indicator; renders participant count; renders format selection dialog; renders existing bracket list.
13. **AC13:** `BracketViewerRoute` is added to `routes.dart` with path `/tournaments/:tournamentId/divisions/:divisionId/brackets/:bracketId` rendering `BracketPage`.
14. **AC14:** The barrel file `bracket.dart` is updated with exports for all new presentation files.

## Tasks / Subtasks

- [x] Task 1: Create `BracketGenerationEvent` (AC: #4)
  - [x] 1.1 Create `lib/features/bracket/presentation/bloc/bracket_generation_event.dart`
  - [x] 1.2 Add imports: `import 'package:freezed_annotation/freezed_annotation.dart';` and `import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';`
  - [x] 1.3 Add `part 'bracket_generation_event.freezed.dart';`
  - [x] 1.4 Define `@freezed class BracketGenerationEvent with _$BracketGenerationEvent`:
    ```dart
    const factory BracketGenerationEvent.loadRequested({
      required String divisionId,
    }) = BracketGenerationLoadRequested;
    const factory BracketGenerationEvent.formatSelected(
      BracketFormat format,
    ) = BracketGenerationFormatSelected;
    const factory BracketGenerationEvent.generateRequested() =
        BracketGenerationGenerateRequested;
    const factory BracketGenerationEvent.regenerateRequested() =
        BracketGenerationRegenerateRequested;
    const factory BracketGenerationEvent.navigateToBracketRequested(
      String bracketId,
    ) = BracketGenerationNavigateToBracketRequested;
    ```
  - [x] 1.5 DO NOT run build_runner yet — wait until Task 2 is also complete

- [x] Task 2: Create `BracketGenerationState` and run build_runner (AC: #5)
  - [x] 2.1 Create `lib/features/bracket/presentation/bloc/bracket_generation_state.dart`
  - [x] 2.2 Add imports:
    ```dart
    import 'package:freezed_annotation/freezed_annotation.dart';
    import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
    import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
    import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
    ```
  - [x] 2.3 Add `part 'bracket_generation_state.freezed.dart';`
  - [x] 2.4 Define `@freezed class BracketGenerationState with _$BracketGenerationState`:
    ```dart
    const factory BracketGenerationState.initial() = BracketGenerationInitial;
    const factory BracketGenerationState.loadInProgress() =
        BracketGenerationLoadInProgress;
    const factory BracketGenerationState.loadSuccess({
      required DivisionEntity division,
      required List<ParticipantEntity> participants,
      required List<BracketEntity> existingBrackets,
      BracketFormat? selectedFormat,
    }) = BracketGenerationLoadSuccess;
    const factory BracketGenerationState.generationInProgress() =
        BracketGenerationInProgress;
    const factory BracketGenerationState.generationSuccess({
      required String generatedBracketId,
    }) = BracketGenerationSuccess;
    const factory BracketGenerationState.loadFailure({
      required String userFriendlyMessage,
      String? technicalDetails,
    }) = BracketGenerationLoadFailure;
    ```
    **WHY `generatedBracketId` (String) instead of `BracketGenerationResult`?** Because double-elimination returns `DoubleEliminationBracketGenerationResult` (different type) and regeneration returns `RegenerateBracketResult` with `Object generationResult`. Storing just the bracketId avoids freezed union-type conflicts and simplifies navigation.
  - [x] 2.5 Run `dart run build_runner build --delete-conflicting-outputs` — generates BOTH `.freezed.dart` files

- [x] Task 3: Create `BracketGenerationBloc` (AC: #3)
  - [x] 3.1 Create `lib/features/bracket/presentation/bloc/bracket_generation_bloc.dart`
  - [x] 3.2 Add imports:
    ```dart
    import 'package:flutter_bloc/flutter_bloc.dart';
    import 'package:injectable/injectable.dart';
    import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
    import 'package:tkd_brackets/features/bracket/domain/entities/bracket_generation_result.dart';
    import 'package:tkd_brackets/features/bracket/domain/entities/double_elimination_bracket_generation_result.dart';
    import 'package:tkd_brackets/features/bracket/domain/entities/regenerate_bracket_result.dart';
    import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
    import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_params.dart';
    import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_use_case.dart';
    import 'package:tkd_brackets/features/bracket/domain/usecases/generate_round_robin_bracket_params.dart';
    import 'package:tkd_brackets/features/bracket/domain/usecases/generate_round_robin_bracket_use_case.dart';
    import 'package:tkd_brackets/features/bracket/domain/usecases/generate_single_elimination_bracket_params.dart';
    import 'package:tkd_brackets/features/bracket/domain/usecases/generate_single_elimination_bracket_use_case.dart';
    import 'package:tkd_brackets/features/bracket/domain/usecases/regenerate_bracket_params.dart';
    import 'package:tkd_brackets/features/bracket/domain/usecases/regenerate_bracket_use_case.dart';
    import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
    import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
    import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
    import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart' as seeding;
    import 'bracket_generation_event.dart';
    import 'bracket_generation_state.dart';
    ```
  - [x] 3.3 `@injectable`, extends `Bloc<BracketGenerationEvent, BracketGenerationState>`
  - [x] 3.4 Constructor injects 7 dependencies:
    - `DivisionRepository _divisionRepository`
    - `ParticipantRepository _participantRepository`
    - `BracketRepository _bracketRepository`
    - `GenerateSingleEliminationBracketUseCase _generateSingleEliminationUseCase`
    - `GenerateDoubleEliminationBracketUseCase _generateDoubleEliminationUseCase`
    - `GenerateRoundRobinBracketUseCase _generateRoundRobinUseCase`
    - `RegenerateBracketUseCase _regenerateBracketUseCase`
  - [x] 3.5 Store `String _currentDivisionId = ''` instance field
  - [x] 3.6 Register event handlers in constructor:
    ```dart
    on<BracketGenerationLoadRequested>(_onLoadRequested);
    on<BracketGenerationFormatSelected>(_onFormatSelected);
    on<BracketGenerationGenerateRequested>(_onGenerateRequested);
    on<BracketGenerationRegenerateRequested>(_onRegenerateRequested);
    ```
  - [x] 3.7 Implement `_onLoadRequested`:
    - `emit(const BracketGenerationLoadInProgress())`
    - `_currentDivisionId = event.divisionId`
    - Fetch division via `_divisionRepository.getDivisionById(event.divisionId)`
    - On failure → `emit(BracketGenerationLoadFailure(...))`
    - On success → fetch participants via `_participantRepository.getParticipantsForDivision(event.divisionId)`
    - On failure → `emit(BracketGenerationLoadFailure(...))`
    - On success → fetch existing brackets via `_bracketRepository.getBracketsForDivision(event.divisionId)`
    - On failure → `emit(BracketGenerationLoadFailure(...))`
    - On success → `emit(BracketGenerationLoadSuccess(division: division, participants: participants, existingBrackets: brackets))`
  - [x] 3.8 Implement `_onFormatSelected`:
    - Guard: `state is BracketGenerationLoadSuccess`
    - `emit((state as BracketGenerationLoadSuccess).copyWith(selectedFormat: event.format))`
  - [x] 3.9 Implement `_onGenerateRequested`:
    - Guard: `state is BracketGenerationLoadSuccess` AND `selectedFormat != null`
    - Get `loadSuccess` state, extract `participants`, `division`, `selectedFormat`
    - `emit(const BracketGenerationInProgress())`
    - Build `participantIds = participants.where((p) => !p.isDeleted && p.checkInStatus != ParticipantStatus.noShow && p.checkInStatus != ParticipantStatus.disqualified && p.checkInStatus != ParticipantStatus.withdrawn).map((p) => p.id).toList()`
    - Switch on `selectedFormat`:
      - `BracketFormat.singleElimination` → call `_generateSingleEliminationUseCase(GenerateSingleEliminationBracketParams(divisionId: division.id, participantIds: participantIds))`
        - On success → `emit(BracketGenerationSuccess(generatedBracketId: result.bracket.id))`
      - `BracketFormat.doubleElimination` → call `_generateDoubleEliminationUseCase(GenerateDoubleEliminationBracketParams(divisionId: division.id, participantIds: participantIds))`
        - **DIFFERENT return type!** `DoubleEliminationBracketGenerationResult` → On success → `emit(BracketGenerationSuccess(generatedBracketId: result.winnersBracket.id))`
      - `BracketFormat.roundRobin` → call `_generateRoundRobinUseCase(GenerateRoundRobinBracketParams(divisionId: division.id, participantIds: participantIds))`
        - On success → `emit(BracketGenerationSuccess(generatedBracketId: result.bracket.id))`
      - `BracketFormat.poolPlay` → not implemented yet (Story 5.15), emit `BracketGenerationLoadFailure(userFriendlyMessage: 'Pool play format is not yet available.')`
    - On failure (any use case) → `emit(BracketGenerationLoadFailure(userFriendlyMessage: failure.userFriendlyMessage, technicalDetails: failure.technicalDetails))`
  - [x] 3.10 Implement `_onRegenerateRequested`:
    - Guard: `state is BracketGenerationLoadSuccess` AND `existingBrackets.isNotEmpty`
    - Get `loadSuccess` state, extract `participants`, `division`, `existingBrackets`
    - `emit(const BracketGenerationInProgress())`
    - Determine format from `division.bracketFormat`
    - Build participantIds (same filter as generate)
    - Map `DivisionEntity.BracketFormat` → `seeding.BracketFormat` using `_mapToSeedingFormat()` helper
    - Call `_regenerateBracketUseCase(RegenerateBracketParams(divisionId: division.id, participantIds: participantIds, bracketFormat: seedingFormat))`
    - On success → **MUST type-check `result.generationResult` (it's `Object`):**
      ```dart
      final genResult = result.generationResult;
      String bracketId;
      if (genResult is BracketGenerationResult) {
        bracketId = genResult.bracket.id;
      } else if (genResult is DoubleEliminationBracketGenerationResult) {
        bracketId = genResult.winnersBracket.id;
      } else {
        emit(const BracketGenerationLoadFailure(
          userFriendlyMessage: 'Unexpected generation result type.',
        ));
        return;
      }
      emit(BracketGenerationSuccess(generatedBracketId: bracketId));
      ```
    - On failure → `emit(BracketGenerationLoadFailure(...))`

- [x] Task 4: Create `BracketFormatSelectionDialog` widget (AC: #6)
  - [x] 4.1 Create `lib/features/bracket/presentation/widgets/bracket_format_selection_dialog.dart`
  - [x] 4.2 `StatelessWidget` that shows a dialog/bottom sheet with format options
  - [x] 4.3 Three `ListTile` options:
    - Single Elimination — icon: `Icons.account_tree`, subtitle: "Standard knockout format"
    - Double Elimination — icon: `Icons.account_tree_outlined`, subtitle: "Winners + losers bracket"
    - Round Robin — icon: `Icons.grid_view`, subtitle: "Everyone plays everyone"
  - [x] 4.4 Each tile calls `Navigator.of(context).pop(BracketFormat.xxx)` returning the selected format
  - [x] 4.5 Helper: `static Future<BracketFormat?> show(BuildContext context)` that displays as `showModalBottomSheet`

- [x] Task 5: Create `BracketGenerationPage` (AC: #2, #6, #7, #8, #9)
  - [x] 5.1 Create `lib/features/bracket/presentation/pages/bracket_generation_page.dart`
  - [x] 5.2 `StatelessWidget` with constructor params: `{required String tournamentId, required String divisionId}`
  - [x] 5.3 In `build()`: wrap with `BlocProvider<BracketGenerationBloc>(create: (context) => getIt<BracketGenerationBloc>()..add(BracketGenerationLoadRequested(divisionId: divisionId)))`
  - [x] 5.4 Add `BlocListener<BracketGenerationBloc, BracketGenerationState>` to handle navigation on `BracketGenerationSuccess`: navigate to bracket viewer route with `context.go('/tournaments/$tournamentId/divisions/$divisionId/brackets/${state.generatedBracketId}')`
  - [x] 5.5 Use `BlocBuilder` with pattern matching:
    - `BracketGenerationInitial || BracketGenerationLoadInProgress || BracketGenerationInProgress` → `Center(child: CircularProgressIndicator())`
    - `BracketGenerationLoadFailure` → error UI with retry button
    - `BracketGenerationLoadSuccess` → render main content
    - `BracketGenerationSuccess` → handled by listener (navigation), show loading as fallback
  - [x] 5.6 Main content for `BracketGenerationLoadSuccess`:
    - AppBar title: division name
    - AppBar actions: refresh button, regenerate button (visible only if `existingBrackets.isNotEmpty`)
    - Body: if `existingBrackets.isEmpty` → show empty state with "Generate Bracket" button that opens `BracketFormatSelectionDialog`
    - Body: if `existingBrackets.isNotEmpty` → show `ListView` of existing brackets with `ListTile` for each: title = bracket type label, subtitle = "Created: ${bracket.createdAtTimestamp}", trailing icon, onTap → navigate to `BracketPage`
    - FAB: "Generate New" button (only if no brackets or regenerate scenario)
  - [x] 5.7 Regenerate confirmation: show `AlertDialog` asking "Regenerate bracket? This will replace the existing bracket." with Cancel/Regenerate buttons
  - [x] 5.8 Format selection flow: when user taps "Generate Bracket", show `BracketFormatSelectionDialog`, on result dispatch `BracketGenerationFormatSelected(format)` then `BracketGenerationGenerateRequested()`

- [x] Task 6: Add routes (AC: #1, #13)
  - [x] 6.1 Add `BracketGenerationRoute` to `lib/core/router/routes.dart`:
    ```dart
    @TypedGoRoute<BracketGenerationRoute>(
      path: '/tournaments/:tournamentId/divisions/:divisionId/brackets',
    )
    class BracketGenerationRoute extends GoRouteData {
      const BracketGenerationRoute({
        required this.tournamentId,
        required this.divisionId,
      });
      final String tournamentId;
      final String divisionId;

      @override
      Widget build(BuildContext context, GoRouterState state) =>
          BracketGenerationPage(
            tournamentId: tournamentId,
            divisionId: divisionId,
          );
    }
    ```
  - [x] 6.2 Add `BracketViewerRoute` to `lib/core/router/routes.dart`:
    ```dart
    @TypedGoRoute<BracketViewerRoute>(
      path: '/tournaments/:tournamentId/divisions/:divisionId/brackets/:bracketId',
    )
    class BracketViewerRoute extends GoRouteData {
      const BracketViewerRoute({
        required this.tournamentId,
        required this.divisionId,
        required this.bracketId,
      });
      final String tournamentId;
      final String divisionId;
      final String bracketId;

      @override
      Widget build(BuildContext context, GoRouterState state) =>
          BracketPage(bracketId: bracketId);
    }
    ```
  - [x] 6.3 Add imports to `routes.dart`:
    ```dart
    import 'package:tkd_brackets/features/bracket/presentation/pages/bracket_generation_page.dart';
    import 'package:tkd_brackets/features/bracket/presentation/pages/bracket_page.dart';
    ```
  - [x] 6.4 Register `$bracketGenerationRoute` and `$bracketViewerRoute` in `app_router.dart` shell routes list
  - [x] 6.5 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `routes.g.dart`

- [x] Task 7: Update barrel file (AC: #14)
  - [x] 7.1 Add to `lib/features/bracket/bracket.dart` in the presentation exports section:
    ```dart
    export 'presentation/bloc/bracket_generation_bloc.dart';
    export 'presentation/bloc/bracket_generation_event.dart';
    export 'presentation/bloc/bracket_generation_state.dart';
    export 'presentation/pages/bracket_generation_page.dart';
    export 'presentation/widgets/bracket_format_selection_dialog.dart';
    ```
  - [x] 7.2 DO NOT export `.freezed.dart` files

- [x] Task 8: Write `BracketGenerationBloc` tests (AC: #11)
  - [x] 8.1 Create `test/features/bracket/presentation/bloc/bracket_generation_bloc_test.dart`
  - [x] 8.2 Define mock classes:
    ```dart
    class MockDivisionRepository extends Mock implements DivisionRepository {}
    class MockParticipantRepository extends Mock implements ParticipantRepository {}
    class MockBracketRepository extends Mock implements BracketRepository {}
    class MockGenerateSingleEliminationBracketUseCase extends Mock implements GenerateSingleEliminationBracketUseCase {}
    class MockGenerateDoubleEliminationBracketUseCase extends Mock implements GenerateDoubleEliminationBracketUseCase {}
    class MockGenerateRoundRobinBracketUseCase extends Mock implements GenerateRoundRobinBracketUseCase {}
    class MockRegenerateBracketUseCase extends Mock implements RegenerateBracketUseCase {}
    class FakeGenerateSingleEliminationBracketParams extends Fake implements GenerateSingleEliminationBracketParams {}
    class FakeGenerateDoubleEliminationBracketParams extends Fake implements GenerateDoubleEliminationBracketParams {}
    class FakeGenerateRoundRobinBracketParams extends Fake implements GenerateRoundRobinBracketParams {}
    class FakeRegenerateBracketParams extends Fake implements RegenerateBracketParams {}
    ```
  - [x] 8.3 Register fallback values in `setUpAll`
  - [x] 8.4 Create test fixtures:
    - `testDivision` — `DivisionEntity(id: 'd1', tournamentId: 't1', name: 'Test Division', category: DivisionCategory.sparring, gender: DivisionGender.male, bracketFormat: BracketFormat.singleElimination, status: DivisionStatus.setup, createdAtTimestamp: DateTime(2026), updatedAtTimestamp: DateTime(2026))`
    - `testParticipants` — 4 `ParticipantEntity` records with unique IDs, divisionId: 'd1'
    - `testBracket` — `BracketEntity(id: 'b1', divisionId: 'd1', bracketType: BracketType.winners, totalRounds: 2, createdAtTimestamp: DateTime(2026), updatedAtTimestamp: DateTime(2026))`
    - `testGenerationResult` — `BracketGenerationResult(bracket: testBracket, matches: [])` — bracket: use `testBracket` from above
    - `testBracketId` — `'b1'` (matches `testBracket.id`) — used to verify `BracketGenerationSuccess.generatedBracketId`
  - [x] 8.5 Use `bloc_test` package with `blocTest<BracketGenerationBloc, BracketGenerationState>(...)`
  - [x] 8.6 Tests:
    - Initial state is `BracketGenerationInitial`
    - `loadRequested` success → emits `[BracketGenerationLoadInProgress, BracketGenerationLoadSuccess]`
    - `loadRequested` with division repo failure → emits `[..., BracketGenerationLoadFailure]`
    - `loadRequested` with participant repo failure → emits `[..., BracketGenerationLoadFailure]`
    - `formatSelected` → seed with `BracketGenerationLoadSuccess`, emits updated state with `selectedFormat`
    - `generateRequested` with single elimination → emits `[BracketGenerationInProgress, BracketGenerationSuccess(generatedBracketId: 'b1')]`
    - `generateRequested` with generation failure → emits `[..., BracketGenerationLoadFailure]`
    - `regenerateRequested` → emits `[BracketGenerationInProgress, BracketGenerationSuccess(generatedBracketId: ...)]`
    - `regenerateRequested` with failure → emits `[..., BracketGenerationLoadFailure]`

- [x] Task 9: Write widget tests (AC: #12)
  - [x] 9.1 Create `test/features/bracket/presentation/pages/bracket_generation_page_test.dart`
  - [x] 9.2 Test: renders loading indicator on initial state
  - [x] 9.3 Test: renders "Generate Bracket" button when no existing brackets
  - [x] 9.4 Test: renders bracket list when existing brackets present
  - [x] 9.5 Create `test/features/bracket/presentation/widgets/bracket_format_selection_dialog_test.dart`
  - [x] 9.6 Test: renders three format options
  - [x] 9.7 Test: tapping an option returns the correct `BracketFormat`

- [x] Task 10: Run analysis and verify all tests pass (AC: all)
  - [x] 10.1 Run `dart run build_runner build --delete-conflicting-outputs`
  - [x] 10.2 Run `dart analyze` — zero errors, zero warnings
  - [x] 10.3 Run all new tests — all pass
  - [x] 10.4 Run full test suite — no regressions

## Dev Notes

### ⚠️ Scope Boundary: UI Integration for Bracket Generation

This story connects the bracket generation algorithms (Stories 5.4-5.6) to the UI. It creates:
- **1 new BLoC** (`BracketGenerationBloc` with events/states)
- **1 new page** (`BracketGenerationPage`)
- **1 new widget** (`BracketFormatSelectionDialog`)
- **2 new routes** (`BracketGenerationRoute`, `BracketViewerRoute`)
- **Updates to barrel file and router**

**This story does NOT:**
- Implement manual seed override drag-and-drop UI (FR29 — separate future story)
- Add pool play → elimination hybrid generation (Story 5.15)
- Add random seeding UI (Story 5.16)
- Add ranked seeding import UI (Story 5.17)
- Modify any existing domain use cases or services
- Add participant name resolution on match cards (deferred to future)

### ⚠️ THREE BracketFormat Enums — Know the Difference!

There are **THREE** distinct `BracketFormat` enums in the codebase. Confusing them causes compile errors:

1. **`division_entity.BracketFormat`** at `lib/features/division/domain/entities/division_entity.dart`:
   - Values: `singleElimination`, `doubleElimination`, `roundRobin`, `poolPlay`
   - Used by: `DivisionEntity.bracketFormat`, the UI selection dialog, this BLoC's event/state
   - This is what the **user selects** in the format picker
   - **Import:** `import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';`

2. **`seeding.BracketFormat`** at `lib/core/algorithms/seeding/bracket_format.dart`:
   - Values: `singleElimination`, `doubleElimination`, `roundRobin` (NO `poolPlay`)
   - Used by: `RegenerateBracketParams.bracketFormat`, seeding engine
   - This is the **algorithm-level** concept
   - **Import:** `import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart' as seeding;`

3. **`bracket_layout.BracketFormat`** at `lib/features/bracket/domain/entities/bracket_layout.dart`:
   - Values: `singleElimination`, `doubleElimination`, `roundRobin` (NO `poolPlay`)
   - Used by: `BracketLayout.format` field only
   - This is the **layout-level** concept for the visualization engine
   - **DO NOT import this one** in the generation BLoC. Only the visualization `BracketBloc` uses it.

**Rule:** In `BracketGenerationBloc`, always use `division_entity.BracketFormat` for user-facing format selection and `seeding.BracketFormat` for the `RegenerateBracketParams`. Never import `bracket_layout.BracketFormat` here.

**Mapping rule (private helper in `BracketGenerationBloc`):**
```dart
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart' as seeding;

seeding.BracketFormat _mapToSeedingFormat(BracketFormat format) {
  return switch (format) {
    BracketFormat.singleElimination => seeding.BracketFormat.singleElimination,
    BracketFormat.doubleElimination => seeding.BracketFormat.doubleElimination,
    BracketFormat.roundRobin => seeding.BracketFormat.roundRobin,
    BracketFormat.poolPlay => seeding.BracketFormat.singleElimination, // fallback
  };
}
```

### ⚠️ Generation Use Cases Return Different Types — VERIFIED FIELD NAMES

- `GenerateSingleEliminationBracketUseCase` → `Either<Failure, BracketGenerationResult>` (extends `UseCase<BracketGenerationResult, GenerateSingleEliminationBracketParams>`)
- `GenerateDoubleEliminationBracketUseCase` → `Either<Failure, DoubleEliminationBracketGenerationResult>` (extends `UseCase<DoubleEliminationBracketGenerationResult, GenerateDoubleEliminationBracketParams>`)
- `GenerateRoundRobinBracketUseCase` → `Either<Failure, BracketGenerationResult>` (extends `UseCase<BracketGenerationResult, GenerateRoundRobinBracketParams>`)
- `RegenerateBracketUseCase` → `Either<Failure, RegenerateBracketResult>` (extends `UseCase<RegenerateBracketResult, RegenerateBracketParams>`)

**`DoubleEliminationBracketGenerationResult` EXACT field names** (verified from source):
```dart
class DoubleEliminationBracketGenerationResult {
  final BracketEntity winnersBracket;      // NOT winnersBracketResult
  final BracketEntity losersBracket;       // NOT losersBracketResult
  final MatchEntity grandFinalsMatch;
  final MatchEntity? resetMatch;
  final List<MatchEntity> allMatches;
}
```
For navigation after double elim generation: use `result.winnersBracket.id` as the `bracketId`.

**`RegenerateBracketResult` EXACT field names** (verified from source):
```dart
class RegenerateBracketResult {
  final int deletedBracketCount;
  final int deletedMatchCount;
  final Object generationResult;  // ⚠️ TYPE IS Object, NOT BracketGenerationResult
}
```

**⚠️ CRITICAL:** `RegenerateBracketResult.generationResult` is typed as `Object`, not `BracketGenerationResult`. This is because regeneration delegates to different generators that return different types. You MUST use runtime type checking:
```dart
final genResult = result.generationResult;
String bracketId;
if (genResult is BracketGenerationResult) {
  bracketId = genResult.bracket.id;
} else if (genResult is DoubleEliminationBracketGenerationResult) {
  bracketId = genResult.winnersBracket.id;
} else {
  // Should not happen — emit failure
  emit(BracketGenerationLoadFailure(userFriendlyMessage: 'Unexpected generation result type.'));
  return;
}
```

### Existing Repository Interfaces (DO NOT MODIFY)

#### DivisionRepository
```dart
abstract class DivisionRepository {
  Future<Either<Failure, List<DivisionEntity>>> getDivisionsForTournament(String tournamentId);
  Future<Either<Failure, DivisionEntity>> getDivisionById(String id);
  Future<Either<Failure, DivisionEntity>> createDivision(DivisionEntity division);
  Future<Either<Failure, DivisionEntity>> updateDivision(DivisionEntity division);
  Future<Either<Failure, Unit>> deleteDivision(String id);
}
```

#### ParticipantRepository
```dart
abstract class ParticipantRepository {
  Future<Either<Failure, List<ParticipantEntity>>> getParticipantsForDivision(String divisionId);
  ...
}
```

#### BracketRepository
```dart
abstract class BracketRepository {
  Future<Either<Failure, List<BracketEntity>>> getBracketsForDivision(String divisionId);
  Future<Either<Failure, BracketEntity>> getBracketById(String id);
  ...
}
```

### BLoC Pattern — Follow Existing Conventions

- `@injectable` (NOT `@lazySingleton`) — BLoCs are feature-scoped
- Positional constructor params for DI injection
- Store `_currentDivisionId` for refresh support
- Nested fold pattern for sequential repo calls (see `BracketBloc._onLoadRequested` pattern)
- Guard against incorrect state before processing events

### Route Pattern — Follow Existing Conventions

The router uses `go_router_builder` with `@TypedGoRoute` annotations:
```dart
@TypedGoRoute<RouteName>(path: '/path/:param')
class RouteName extends GoRouteData {
  const RouteName({required this.param});
  final String param;
  @override
  Widget build(BuildContext context, GoRouterState state) => Page(param: param);
}
```

After adding new route classes:
1. Add route variable `$bracketGenerationRoute` and `$bracketViewerRoute` to the `createAppShellRoute` list in `app_router.dart`
2. Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `routes.g.dart`

### Participant Filtering for Generation

When building `participantIds` for generation, filter out inappropriate participants:
```dart
final activeParticipantIds = participants
    .where((p) =>
        !p.isDeleted &&
        p.checkInStatus != ParticipantStatus.noShow &&
        p.checkInStatus != ParticipantStatus.disqualified &&
        p.checkInStatus != ParticipantStatus.withdrawn)
    .map((p) => p.id)
    .toList();
```

### Navigation Pattern

Use `context.go(...)` for navigation within the app shell (not `context.push`) to maintain proper back navigation within the shell scaffold. The navigation after generation success happens in a `BlocListener`:

```dart
BlocListener<BracketGenerationBloc, BracketGenerationState>(
  listener: (context, state) {
    if (state is BracketGenerationSuccess) {
      context.go(
        '/tournaments/$tournamentId/divisions/$divisionId/brackets/${state.generatedBracketId}',
      );
    }
  },
  child: BlocBuilder<BracketGenerationBloc, BracketGenerationState>(...),
)
```

### Theme Integration

Use Material Design 3 theme from `AppTheme`:
- Primary seed color: `Color(0xFF1E3A5F)` (Navy)
- Use `Theme.of(context).colorScheme` for all colors
- Format selection dialog: use `ListTile` with leading icons
- Bracket list items: `Card` with `ListTile` content
- FAB: `FloatingActionButton.extended` for "Generate Bracket" action

**BLoC Tests — Use `bloc_test` package (match existing `bracket_bloc_test.dart` pattern):**
```dart
// Use setUp param for mock setup, build param for BLoC construction
blocTest<BracketGenerationBloc, BracketGenerationState>(
  'emits [loadInProgress, loadSuccess] when loadRequested succeeds',
  setUp: () {
    when(() => mockDivisionRepo.getDivisionById('d1'))
        .thenAnswer((_) async => Right(testDivision));
    when(() => mockParticipantRepo.getParticipantsForDivision('d1'))
        .thenAnswer((_) async => Right(testParticipants));
    when(() => mockBracketRepo.getBracketsForDivision('d1'))
        .thenAnswer((_) async => const Right([]));
  },
  build: buildBloc,
  act: (bloc) => bloc.add(const BracketGenerationLoadRequested(divisionId: 'd1')),
  expect: () => [
    const BracketGenerationLoadInProgress(),
    isA<BracketGenerationLoadSuccess>()
        .having((s) => s.division.id, 'division.id', 'd1')
        .having((s) => s.participants.length, 'participants.length', 4)
        .having((s) => s.existingBrackets, 'existingBrackets', isEmpty),
  ],
);

// Generation success test — uses seed for initial loaded state
blocTest<BracketGenerationBloc, BracketGenerationState>(
  'emits [generationInProgress, generationSuccess] when single elim generation succeeds',
  setUp: () {
    when(() => mockSingleElimUseCase(any()))
        .thenAnswer((_) async => Right(testGenerationResult));
  },
  build: buildBloc,
  seed: () => BracketGenerationLoadSuccess(
    division: testDivision,
    participants: testParticipants,
    existingBrackets: const [],
    selectedFormat: BracketFormat.singleElimination,
  ),
  act: (bloc) => bloc.add(const BracketGenerationGenerateRequested()),
  expect: () => [
    const BracketGenerationInProgress(),
    const BracketGenerationSuccess(generatedBracketId: 'b1'),
  ],
);
```

### Project Structure Notes

New files created by this story:
```
lib/features/bracket/
└── presentation/
    ├── bloc/
    │   ├── bracket_generation_bloc.dart                 # NEW
    │   ├── bracket_generation_event.dart                # NEW
    │   ├── bracket_generation_event.freezed.dart        # GENERATED
    │   ├── bracket_generation_state.dart                # NEW
    │   └── bracket_generation_state.freezed.dart        # GENERATED
    ├── pages/
    │   └── bracket_generation_page.dart                 # NEW
    └── widgets/
        └── bracket_format_selection_dialog.dart          # NEW

test/features/bracket/
└── presentation/
    ├── bloc/
    │   └── bracket_generation_bloc_test.dart             # NEW
    ├── pages/
    │   └── bracket_generation_page_test.dart             # NEW
    └── widgets/
        └── bracket_format_selection_dialog_test.dart     # NEW
```

Modified files:
```
lib/core/router/routes.dart          # MODIFIED — add 2 new route classes
lib/core/router/routes.g.dart        # REGENERATED by build_runner
lib/core/router/app_router.dart      # MODIFIED — add route registrations
lib/features/bracket/bracket.dart    # MODIFIED — add new exports
```

### ⚠️ Common LLM Mistakes — Prevention Rules

| #   | Mistake                                                                  | Correct Approach                                                                                                                                                                                                                                            |
| --- | ------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Using `@lazySingleton` for `BracketGenerationBloc`                       | BLoCs MUST use `@injectable` (NOT `@lazySingleton`). They are feature-scoped and disposed on navigation via `BlocProvider`                                                                                                                                  |
| 2   | Confusing the THREE `BracketFormat` enums                                | `division_entity.BracketFormat` (4 values incl. `poolPlay`) is UI. `seeding.BracketFormat` (3 values) is algorithms. `bracket_layout.BracketFormat` (3 values) is visualization. Only import the first two in this BLoC. Use `import ... as seeding` for #2 |
| 3   | Not handling `DoubleEliminationBracketGenerationResult` return type      | Double elimination returns a *different* result type than single elim. Extract `result.winnersBracket.id` (NOT `winnersBracketResult`). Also `RegenerateBracketResult.generationResult` is `Object` — must use `is` type check                              |
| 4   | Not filtering participants before generation                             | Filter out `isDeleted`, `noShow`, `disqualified`, `withdrawn` participants. A generation use case will reject empty participant lists                                                                                                                       |
| 5   | Using `context.push` instead of `context.go` for shell navigation        | `context.go` maintains shell scaffold. `context.push` creates a new full-screen route stack                                                                                                                                                                 |
| 6   | Forgetting `registerFallbackValue` for all `Fake` types in BLoC tests    | Each use case param type needs a `Fake` registered in `setUpAll`                                                                                                                                                                                            |
| 7   | Importing `.freezed.dart` files directly                                 | NEVER import `.freezed.dart` files. Only import the source file which has the `part` directive                                                                                                                                                              |
| 8   | Not running `build_runner` after adding routes                           | `@TypedGoRoute` requires code generation. Must run `dart run build_runner build --delete-conflicting-outputs` after adding route classes                                                                                                                    |
| 9   | Handling `BracketGenerationSuccess` in `BlocBuilder` instead of listener | Navigation side-effects go in `BlocListener`, not `BlocBuilder`. Builder should show a loading fallback for this state                                                                                                                                      |
| 10  | Not adding route to `createAppShellRoute`                                | The `$bracketGenerationRoute` and `$bracketViewerRoute` must be added to the `routes` list inside `createAppShellRoute(...)` in `app_router.dart`                                                                                                           |
| 11  | Creating separate file for `BracketFormat` mapping                       | Put the `_mapToSeedingFormat` helper as a private method in `BracketGenerationBloc` — no need for a separate file                                                                                                                                           |
| 12  | Using `fail('Should have failed')` incorrectly                           | Use `fail(...)` in test fold error paths. Use `Left.new` tear-off for error propagation in production code                                                                                                                                                  |
| 13  | Not type-checking `RegenerateBracketResult.generationResult`             | `generationResult` is `Object`, NOT `BracketGenerationResult`. MUST use `is BracketGenerationResult` / `is DoubleEliminationBracketGenerationResult` check before accessing `.bracket.id` or `.winnersBracket.id`                                           |
| 14  | Using wrong field name `winnersBracketResult` on double elim result      | The correct field name is `winnersBracket` (type `BracketEntity`), NOT `winnersBracketResult`. Verified from `double_elimination_bracket_generation_result.dart` source                                                                                     |

### Previous Story Intelligence

Learnings from Story 5.13 (Bracket Visualization Renderer):

1. **`Left.new` tear-off**: Project standard for error propagation in `.fold()`. Do NOT use `(failure) => Left(failure)` — use `Left.new`
2. **`registerFallbackValue` pattern**: Must register in `setUpAll`, not `setUp`. Use `Fake` classes that extend `Fake implements X`
3. **`BracketType.winners`**: Used in test fixtures when creating `BracketEntity`. Import from `bracket_entity.dart`
4. **`MatchStatus.pending`**: Default value for `MatchEntity.status`. Import from `match_entity.dart`
5. **Test assertion pattern**: Use `isA<Type>().having(...)` for complex matcher chains
6. **`copyWith` on freezed**: Works correctly for nullable fields
7. **Params import pattern**: Param classes are in separate files from use cases
8. **`getIt` import**: `import 'package:tkd_brackets/core/di/injection.dart';` — exports `getIt`

### References

- [Source: epics.md#Story 5.14] — User story, acceptance criteria
- [Source: architecture.md#Frontend Architecture] — BLoC scoping, feature-scoped BLoCs
- [Source: architecture.md#Implementation Patterns] — Naming conventions, file structure
- [Source: routes.dart] — Existing route patterns with `@TypedGoRoute`
- [Source: app_router.dart] — Shell route registration pattern
- [Source: bracket_bloc.dart] — Existing BLoC pattern for bracket feature
- [Source: bracket_page.dart] — Existing page pattern with `BlocProvider` + `getIt`
- [Source: 5-13-bracket-visualization-renderer.md] — Previous story learnings
- [Source: division_entity.dart] — `BracketFormat` enum with `poolPlay` value
- [Source: bracket_format.dart (seeding)] — Algorithm-level `BracketFormat` without `poolPlay`
- [Source: generate_single_elimination_bracket_use_case.dart] — Generation use case pattern
- [Source: regenerate_bracket_params.dart] — Regeneration params with `seeding.BracketFormat`
- [Source: participant_entity.dart] — `ParticipantStatus`, `checkInStatus`, filtering

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
