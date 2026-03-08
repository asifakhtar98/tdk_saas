# TKD Bracket Generator: Technical Development Guide

This document covers the architectural patterns, state management, testing strategies, and future expansion paths for the TKD Bracket Generator (MVP). 

## 1. Project Architecture

The application is built using a simplified Clean Architecture structure configured specifically for a local-first, offline MVP. 

```text
lib/
├── core/
│   ├── errors/     # Exceptions and Failure classes
│   └── utils/      # Utility functions (UUID generator, etc.)
├── features/
│   ├── bracket/    # Domain entities, Services for generating/layout
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/  # Widgets for bracket rendering
│   └── participant/# Domain entities for athletes
└── main.dart       # Root application, UI state, routing, dialogs
```

### 1.1 State Management (MVP)
To ship the initial version quickly, the app utilizes `StatefulWidget` inside `main.dart` (`_ParticipantEntryScreenState` & `_BracketViewerScreenState`). 

*   `_BracketViewerScreenState` holds the live source of truth for:
    *   `BracketEntity _bracket`
    *   `List<MatchEntity> _matches`
    *   `BracketLayout _layout` (Calculated geometrically based on `_bracket` and `_matches`)

When advancing to **v1.1**, state should be extracted into a reactive state management solution (e.g., `Bloc`, `Riverpod`, or `Provider`) to decouple UI from tournament logic and support offline persistence.

### 1.2 Domain Entities
*   **`ParticipantEntity`**: Athlete data (UUID, Name, Dojang).
*   **`BracketEntity`**: High-level bracket info (Rounds, Type).
*   **`MatchEntity`**: Critical node holding state of a match.
    *   *Warning:* Due to Dart's `??` operator, `MatchEntity.copyWith()` uses a **const Sentinel Pattern** (`_sentinel = Object()`) to properly nullify nullable fields like `winnerId` or `loserAdvancesToMatchId`. **Do not remove this pattern or cascading undos will break.**

## 2. Core Engines

### 2.1 Bracket Generators (`lib/features/bracket/data/services/`)
We use dedicated services for mathematical generation. They return a list of UUID-linked `MatchEntity` objects.
*   **Single Elimination**: Standard binary tree. Optionally injects a 3rd place match that connects to the losers of the semifinals.
*   **Double Elimination**: Creates a Winner structure and a Loser structure. Links `loserAdvancesToMatchId` from Winners bracket rounds into specific slots in the Losers bracket.
*   **Round Robin**: Uses a circle method. Handles odd numbers by injecting a phantom "BYE".

### 2.2 Layout Engine (`bracket_layout_engine_implementation.dart`)
Instead of fixed CSS/HTML, parsing tree depth in Flutter requires absolute positioning inside an `InteractiveViewer`.
*   Iterates through rounds and assigns `(x, y)` `Offset`s to `MatchSlot`s.
*   Future rounds center their Y-position based on the top/bottom feeding matches from the previous round.

## 3. Match Lifecycle & Propagation

Matches are scored via `_declareWinner` and reverted via `_resetMatch` in `main.dart`.
*   **Winner Propagation**: Winning player's ID pushes into `winnerAdvancesToMatchId`. Code explicitly checks for `null` in Red/Blue slots to avoid overwriting existing adversaries.
*   **Loser Propagation (Double Elim)**: Losing player drops into `loserAdvancesToMatchId`.
*   **Cascading Undo**: When `_resetMatch` is called over a previously scored match, `_cascadeRemove` recursively walks the `.winnerAdvancesToMatchId` (and `.loserAdvancesToMatchId`) wiping the participant from downstream matches.

## 4. Testing Strategy

The repository relies on **End-to-End (E2E) Integration Tests** via the `integration_test` package. Unit testing on the math engines exists implicitly inside the E2E verification.

*   **File:** `test/bracket_flow_test.dart`
*   **Execution:** `flutter run test/bracket_flow_test.dart -d <simulator_id>`
*   **Coverage guarantees:**
    *   Mathematical node connections (e.g., $N$ players generates $N-1$ matches in Single Elim).
    *   Widget mounting (no deactivated ancestor errors during dialog pops).
    *   Dojang separation (athletes from the same club don't meet in Round 1).
    *   Cascading undo cleans deep branch nodes.

**Important for testing:** Interactive viewers require scrolling. Use `tester.ensureVisible` and `tester.pump(const Duration(milliseconds: 500))` heavily in tests to allow pan/zoom animations to settle before tapping `MatchCardWidget`s.

## 5. Future Expansion Roadmap (Technical Debt & Scalability)

To evolve beyond MVP, implement the following architectural upgrades:

### Phase 1: Persistence & Safe State
1.  **Introduce `Riverpod` or `Bloc`**: Move `_BracketViewerScreenState` to a provider.
2.  **Local Storage via Hive or SQLite**: Serialize `BracketEntity` and `List<MatchEntity>` to disk on every match score.
3.  **App Lifecycle Hooks**: Auto-save when the app goes into the background.

### Phase 2: Multi-Division Architecture
1.  **Navigation Restructure**: Transition to a `TournamentDashboardScreen` $\to$ `DivisionListScreen` $\to$ `BracketViewerScreen` flow.
2.  **Shared Participant Pool**: Maintain a master `ParticipantRepository` so players aren't bound exclusively to manual `List<ParticipantEntity>` instances.

### Phase 3: Display & Round Robin Logic
1.  **Standings Calculation**: Write an engine that loops over `Round Robin` `MatchEntity` results counting Wins, Points, and Head-to-Head to render a standings table dynamically.
2.  **Printing Engine Optimization**: Extract the lengthy PDF generation monolithic functions in `main.dart` into a dedicated `PdfExportService`.
