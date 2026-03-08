# TKD Bracket Generator: Architecture Decision Document

## Project Context
The TKD Bracket generator MVP is a standalone, offline-first application designed for Taekwondo tournament organizers. It was built with a "YOLO" (fast, lightweight, highly actionable) iteration strategy. 

While the initial system planning (`_bmad-output/planning-artifacts/architecture.md`) envisioned a full-stack SaaS application using Supabase, Drift, and complex Clean Architecture injection, the pragmatic MVP requirement mandated a rapid, client-only approach.

This document outlines the **Current Architecture (v1.0)** and how it maps against the **Planned Target Architecture** for future phases.

---

## 1. Current Architecture (v1.0 MVP)

### Domain
- **Core Focus**: Flutter Web (Tablet-optimized, locked to Landscape mode)
- **Data Persistence**: Ephemeral (In-memory `StatefulWidget` state during run time)
- **Backend/Auth**: None (Offline standalone utility)

### Structural Decisions
For speed and immediate visual feedback, the application utilizes a condensed Clean Architecture:
- **`core/`**: Utility functions and enums.
- **`features/`**:
  - `bracket/`: Contains mathematical layout algorithms, generators (Single/Double Elim, Round Robin), and Domain Entities (`BracketEntity`, `MatchEntity`).
  - `participant/`: Contains `ParticipantEntity` Domain Entity.
- **Presentation**: UI and state are bundled into `main.dart` directly to avoid wiring boilerplate for the initial prototype. 

### Key Engine Components
1. **Generators**: Standalone mathematical services (e.g., `SingleEliminationBracketGeneratorServiceImplementation`) that output deterministic `[MatchEntity]` trees with seeded UUIDs. Dojang Separation is applied *prior* to feeding participants into the generators.
2. **Layout Engine**: `BracketLayoutEngineImplementation` calculates absolute `(x, y)` Cartesian coordinates (`Offset`) for every match, enabling the Flutter `CustomPainter` and `InteractiveViewer` to draw bezier curves between slots regardless of bracket complexity.

### Identified Technical Debt (Intentional tradeoffs)
1. **God Widget**: `main.dart` holds `_ParticipantEntryScreenState` and `_BracketViewerScreenState`, managing all state (arrays of arrays, match updates, formatting).
2. **Data Volatility**: Since there is no `drift` local database implemented yet, closing the browser/app destroys the tournament.
3. **Null Sentinel Pattern**: Because of Dart's standard `copyWith(value: newValue ?? this.value)`, standard data classes cannot revert a nullable field to `null`. We implemented a Sentinel Pattern (`const _sentinel = Object();`) in `MatchEntity` to safely support cascading undo behaviors.

---

## 2. Target Architecture Patterns (For Expansion)

As defined in the original planning artifacts, to scale this into a full SaaS product (v1.1+), the codebase must transition strictly into the standard **Clean Architecture** patterns previously outlined.

### Critical Transition Rules

1. **State Management Extraction**
   - The state currently in `main.dart` MUST be extracted into `flutter_bloc`.
   - Creation of `TournamentBloc` and `ScoringBloc` is the next mandatory refactor.

2. **Presentation vs Domain Rule**
   - `Presentation` (BLoC) -> `Domain` (Use Case) -> `Data` (Repository Impl).
   - The UI widgets shall no longer call generator services directly.

3. **Database & Sync Implementation**
   - **Local Database**: Introduce `drift` (SQLite) to store `BracketEntity` and `MatchEntity` changes instantly upon scoring to prevent data loss.
   - **Cloud Sync**: Integrate `supabase_flutter` for multi-device sync across rings once cloud access is enabled. 

### Data Class & Naming Conventions
When introducing new entities and refactoring strings, the following rules apply from the old planning spec:
- All Models, Events, and States must use `freezed`.
- Files: `snake_case.dart` (e.g., `match_scoring_bloc.dart`).
- Classes: verbose `PascalCase` (e.g., `UpdateMatchScoreUseCase`).

### Testing Organization
The project currently relies heavily on Integration E2E passing (e.g., `integration_test/bracket_flow_test.dart`). 
When moving to Clean Architecture, mirror testing layers:
```text
test/
├── features/
│   └── bracket/
│       ├── data/
│       ├── domain/
│       └── presentation/
```

## 3. Deployment Constraints

- The MVP relies on printing output (PDF Generation via `pdf` and `printing` packages). 
- All standard views MUST be responsive but explicitly optimized for Landscape bounds.
- If deployed to the web, the app should leverage deep-linking via `go_router` (e.g., `/tournament/:id/ring/:number`), replacing the current nested `Navigator.push` implementation in `main.dart`.
