# Story 4.12: Participant Management UI

Status: done

**Created:** 2026-02-25

**Epic:** 4 - Participant Management

**FRs Covered:** FR13 (Add participants manually — UI), FR14 (CSV import — UI), FR15 (Paste from spreadsheet — UI), FR16 (Auto-assign to divisions — UI), FR17 (Move participant between divisions — UI), FR18 (Remove participant / no-show — UI), FR19 (DQ participant — UI)

**Dependencies:** Story 4.1 (Participant Feature Structure) - COMPLETE | Story 4.2 (Participant Entity & Repository) - COMPLETE | Story 4.3 (Manual Participant Entry) - COMPLETE | Story 4.4 (CSV Import Parser) - COMPLETE | Story 4.5 (Duplicate Detection) - COMPLETE | Story 4.6 (Bulk Import with Validation) - COMPLETE | Story 4.7 (Participant Status Management) - COMPLETE | Story 4.8 (Assign Participants to Divisions) - COMPLETE | Story 4.9 (Auto-Assignment Algorithm) - COMPLETE | Story 4.10 (Division Participant View) - COMPLETE | Story 4.11 (Participant Edit & Transfer) - COMPLETE | Epic 3 (Tournament & Division Management) - COMPLETE

---

## TL;DR — Critical Facts

**CURRENT STATE:**
- ✅ ALL domain logic is COMPLETE — 11 prior stories implemented and tested
- ✅ `tkd_brackets/lib/features/participant/presentation/bloc/` — empty directory EXISTS
- ✅ `tkd_brackets/lib/features/participant/presentation/pages/` — empty directory EXISTS
- ✅ `tkd_brackets/lib/features/participant/presentation/widgets/` — empty directory EXISTS
- ✅ `tkd_brackets/lib/features/participant/domain/usecases/usecases.dart` — barrel file with 21 exports
- ✅ `tkd_brackets/lib/features/participant/domain/entities/participant_entity.dart` — ParticipantEntity (freezed) with ALL fields: `id`, `divisionId`, `firstName`, `lastName`, `dateOfBirth`, `gender`, `weightKg`, `schoolOrDojangName`, `beltRank`, `seedNumber`, `registrationNumber`, `isBye`, `checkInStatus` (ParticipantStatus enum), `checkInAtTimestamp`, `dqReason`, `photoUrl`, `notes`, `syncVersion`, `isDeleted`, `deletedAtTimestamp`, `isDemoData`, `createdAtTimestamp`, `updatedAtTimestamp`. Has computed `age` getter.
- ✅ `tkd_brackets/lib/features/participant/domain/entities/participant_entity.dart` — `ParticipantStatus` enum: `pending`, `checkedIn`, `noShow`, `withdrawn`, `disqualified`
- ✅ `tkd_brackets/lib/features/participant/domain/entities/participant_entity.dart` — `Gender` enum: `male`, `female`
- ✅ `tkd_brackets/lib/features/division/domain/entities/division_entity.dart` — DivisionEntity with fields incl. `DivisionStatus` enum: `setup`, `ready`, `inProgress`, `completed`
- ✅ `tkd_brackets/lib/core/error/failures.dart` — Full failure hierarchy: `Failure` (abstract, Equatable), `InputValidationFailure` (fieldErrors Map), `NotFoundFailure`, `AuthorizationPermissionDeniedFailure`, `AuthenticationFailure`, `LocalCacheAccessFailure`, `LocalCacheWriteFailure`, `ValidationFailure`, `ServerConnectionFailure`, `ServerResponseFailure`
- ✅ Existing BLoC pattern reference: `tkd_brackets/lib/features/tournament/presentation/bloc/` — `TournamentBloc` (list), `TournamentDetailBloc` (detail) with freezed events/states
- ✅ Existing page pattern reference: `tkd_brackets/lib/features/tournament/presentation/pages/` — `TournamentListPage`, `TournamentDetailPage`, `DivisionBuilderWizard`
- ✅ Existing widget pattern reference: `tkd_brackets/lib/features/tournament/presentation/widgets/` — `TournamentCard`, `TournamentFormDialog`, `ConflictWarningBanner`, `RingAssignmentWidget`
- ✅ Router: `tkd_brackets/lib/core/router/routes.dart` — type-safe GoRouter with `@TypedGoRoute` annotations, `part 'routes.g.dart'`

**AVAILABLE USE CASES — EXACT CALL SIGNATURES (source of truth):**

> ⚠️ **CRITICAL:** Some use cases use NAMED parameters, others use positional params classes. The exact signatures below are copied from source code. Do NOT guess.

| Use Case                         | EXACT Call Signature                                                                                                                | Purpose                              |
| -------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| `CreateParticipantUseCase`       | `call(CreateParticipantParams params)` — POSITIONAL params class                                                                    | Add single participant               |
| `UpdateParticipantUseCase`       | `call(UpdateParticipantParams params)` — POSITIONAL params class                                                                    | Edit participant (PATCH)             |
| `TransferParticipantUseCase`     | `call(TransferParticipantParams params)` — POSITIONAL params class                                                                  | Move between divisions               |
| `GetDivisionParticipantsUseCase` | `call(String divisionId)` — POSITIONAL String                                                                                       | Get division participants            |
| `UpdateParticipantStatusUseCase` | `call({required String participantId, required ParticipantStatus newStatus, String? dqReason})` — **NAMED params, NO params class** | ALL status changes incl. DQ          |
| `DisqualifyParticipantUseCase`   | `call({required String participantId, required String dqReason})` — **NAMED params, NO params class**                               | DQ with reason (simpler alternative) |
| `BulkImportUseCase`              | `.generatePreview({required String csvContent, required String divisionId, required String tournamentId})` — **NAMED params**       | CSV preview                          |
| `BulkImportUseCase`              | `.importSelected({required List<BulkImportPreviewRow> selectedRows, required String divisionId})` — **NAMED params**                | Import selected rows                 |
| `AssignToDivisionUseCase`        | `call({required String participantId, required String divisionId})` — **NAMED params, NO params class**                             | Assign to division                   |
| `AutoAssignParticipantsUseCase`  | `call({required String tournamentId, required List<String> participantIds, bool dryRun = false})` — **NAMED params**                | Auto-assign                          |

**PARAMS CLASS EXACT FIELDS (freezed):**

```dart
// CreateParticipantParams — all fields:
class CreateParticipantParams {
  required String divisionId,
  required String firstName,
  required String lastName,
  required String schoolOrDojangName,
  required String beltRank,
  DateTime? dateOfBirth,
  Gender? gender,
  double? weightKg,
  String? registrationNumber,
  String? notes,
}

// UpdateParticipantParams — PATCH semantics, null = no change:
class UpdateParticipantParams {
  required String participantId,  // REQUIRED — identifies which participant
  String? firstName,              // null = no change
  String? lastName,
  DateTime? dateOfBirth,
  Gender? gender,
  double? weightKg,
  String? schoolOrDojangName,
  String? beltRank,
  String? registrationNumber,
  String? notes,
}

// TransferParticipantParams:
class TransferParticipantParams {
  required String participantId,
  required String targetDivisionId,
}
```

**DOMAIN ENTITIES — EXACT FIELDS (freezed):**

```dart
// DivisionParticipantView (returned by GetDivisionParticipantsUseCase):
class DivisionParticipantView {
  required DivisionEntity division,
  required List<ParticipantEntity> participants,  // sorted by seedNumber ASC, lastName ASC
  required int participantCount,
}

// BulkImportPreview (returned by BulkImportUseCase.generatePreview):
class BulkImportPreview {
  required List<BulkImportPreviewRow> rows,
  required int validCount,
  required int warningCount,
  required int errorCount,
  required int totalRows,
  // Computed getters: hasAnyIssues, canProceed
}

// BulkImportPreviewRow:
class BulkImportPreviewRow {
  required int sourceRowNumber,
  required CSVRowData rowData,
  required BulkImportRowStatus status,  // enum: valid, warning, error
  required List<DuplicateMatch> duplicateMatches,
  required Map<String, String> validationErrors,
  // Computed: hasDuplicates, hasErrors, isHighConfidenceDuplicate
}

// CSVRowData (the parsed row data):
class CSVRowData {
  required String firstName,
  required String lastName,
  required String schoolOrDojangName,
  required String beltRank,
  required int sourceRowNumber,
  DateTime? dateOfBirth,
  Gender? gender,
  double? weightKg,
  String? registrationNumber,
  String? notes,
}

// BulkImportResult (returned by BulkImportUseCase.importSelected):
class BulkImportResult {
  required int successCount,
  required int failureCount,
  required List<String> errorMessages,
}

// BulkImportRowStatus enum:
enum BulkImportRowStatus { valid, warning, error }

// DuplicateMatch:
class DuplicateMatch {
  required String existingParticipantId,
  required String existingName,
  required String matchField,
  required double confidence,
  required bool isHighConfidence,
}

// AutoAssignmentResult:
class AutoAssignmentResult {
  required List<AutoAssignmentMatch> matchedAssignments,
  required List<UnmatchedParticipant> unmatchedParticipants,
  required int totalParticipantsProcessed,
  required int totalDivisionsEvaluated,
}
```

**STATUS TRANSITION RULES (from `UpdateParticipantStatusUseCase._validTransitions`):**
```
pending     → checkedIn, noShow, withdrawn, disqualified
checkedIn   → withdrawn, disqualified
noShow      → pending  (reverse only)
withdrawn   → pending  (reverse only)
disqualified → pending (reverse only)
```
Use this to DISABLE invalid status menu items in the UI.

**TARGET STATE:** Create the full presentation layer for participant management: BLoC (events/states), pages (participant list, CSV import wizard, division assignment view), and reusable widgets (participant card, import preview, search/filter bar). This is the **MOST COMPLEX** story in Epic 4 — it ties together ALL previous domain stories into a cohesive UI.

**FILES TO CREATE:**
| File                                                                                       | Type   | Description                                        |
| ------------------------------------------------------------------------------------------ | ------ | -------------------------------------------------- |
| `tkd_brackets/lib/features/participant/presentation/bloc/participant_list_event.dart`      | Event  | Freezed events for participant list BLoC           |
| `tkd_brackets/lib/features/participant/presentation/bloc/participant_list_state.dart`      | State  | Freezed states for participant list BLoC           |
| `tkd_brackets/lib/features/participant/presentation/bloc/participant_list_bloc.dart`       | BLoC   | Main participant list management BLoC              |
| `tkd_brackets/lib/features/participant/presentation/bloc/csv_import_event.dart`            | Event  | Freezed events for CSV import BLoC                 |
| `tkd_brackets/lib/features/participant/presentation/bloc/csv_import_state.dart`            | State  | Freezed states for CSV import BLoC                 |
| `tkd_brackets/lib/features/participant/presentation/bloc/csv_import_bloc.dart`             | BLoC   | CSV import wizard state management                 |
| `tkd_brackets/lib/features/participant/presentation/pages/participant_list_page.dart`      | Page   | Main participant list page with search/filter/sort |
| `tkd_brackets/lib/features/participant/presentation/pages/csv_import_page.dart`            | Page   | CSV import wizard (upload, preview, confirm)       |
| `tkd_brackets/lib/features/participant/presentation/widgets/participant_card.dart`         | Widget | Reusable participant display card                  |
| `tkd_brackets/lib/features/participant/presentation/widgets/participant_form_dialog.dart`  | Widget | Dialog for add/edit participant                    |
| `tkd_brackets/lib/features/participant/presentation/widgets/participant_search_bar.dart`   | Widget | Search + filter bar (name, dojang, belt)           |
| `tkd_brackets/lib/features/participant/presentation/widgets/import_preview_table.dart`     | Widget | Table showing CSV import preview rows              |
| `tkd_brackets/test/features/participant/presentation/bloc/participant_list_bloc_test.dart` | Test   | Unit tests for ParticipantListBloc                 |
| `tkd_brackets/test/features/participant/presentation/bloc/csv_import_bloc_test.dart`       | Test   | Unit tests for CSVImportBloc                       |

**FILES TO MODIFY:**
| File                                                                                  | Change                                                                                             |
| ------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `tkd_brackets/lib/core/router/routes.dart`                                            | Add `ParticipantListRoute` and `CsvImportRoute` with `@TypedGoRoute` annotations                   |
| `tkd_brackets/lib/core/router/app_router.dart`                                        | Register new routes in shell routes list                                                           |
| `tkd_brackets/lib/features/tournament/presentation/pages/tournament_detail_page.dart` | Add `onTap` to division `ListTile` in `_buildDivisionsTab()` to navigate to participant list route |

**KEY PREVIOUS STORY LESSONS — APPLY ALL:**
1. Use `@injectable` for BLoCs — NOT `@lazySingleton`
2. Use `freezed` for BLoC events and states — `part '<filename>.freezed.dart'` directive
3. Run `dart run build_runner build --delete-conflicting-outputs` after ANY freezed file changes
4. Use `package:bloc_test/bloc_test.dart` for BLoC testing — `blocTest<B, S>()` function
5. Use `mocktail` for mocks — NOT `mockito`. NO `@GenerateMocks`. Manual mocks: `class MockFoo extends Mock implements Foo {}`
6. Register fallback values for use case mocks: `registerFallbackValue(FakeEntity())`
7. Use `Either<Failure, T>` pattern in BLoC event handlers — `result.fold(failure => ..., success => ...)`
8. Failure display in UI: access `failure.userFriendlyMessage` and `failure.technicalDetails`
9. Use `BlocProvider` / `BlocBuilder` / `BlocListener` / `BlocConsumer` from `flutter_bloc` — NOT raw StreamBuilder
10. Use `getIt<BlocType>()` to obtain BLoC instances from DI container — the DI module is at `tkd_brackets/lib/core/di/injection.dart` using `@InjectableInit`
11. Use `context.go()` / `context.push()` for navigation via `go_router`
12. State naming: `{Feature}Initial`, `{Feature}LoadInProgress`, `{Feature}LoadSuccess`, `{Feature}LoadFailure`
13. Event naming: `{Feature}{Action}Requested` (e.g., `ParticipantListLoadRequested`)
14. Material Design 3 — use `Theme.of(context)` for colors, text styles. Color scheme: Navy (#1A237E) primary, Gold (#F9A825) secondary
15. Use `InteractiveViewer` or `SingleChildScrollView` for scrollable content — NOT unbounded Column in Scaffold body
16. **Testing uses `mocktail` package** — NOT `mockito`

---

## Story

**As an** organizer,
**I want** a UI to manage participants with CSV import and assignment,
**So that** I can visually manage my tournament roster (FR13-FR19).

---

## Acceptance Criteria

### AC1: ParticipantListBloc Events & States

- [ ] **AC1.1:** `ParticipantListEvent` freezed class created at `tkd_brackets/lib/features/participant/presentation/bloc/participant_list_event.dart`
- [ ] **AC1.2:** Events include: `loadRequested({required String divisionId})`, `refreshRequested()`, `searchQueryChanged(String query)`, `filterChanged(ParticipantFilter filter)`, `sortChanged(ParticipantSort sort)`, `participantDeleteRequested(String participantId)`, `createRequested(CreateParticipantParams params)`, `editRequested(UpdateParticipantParams params)`, `transferRequested(TransferParticipantParams params)`, `statusChangeRequested({required String participantId, required ParticipantStatus newStatus, String? dqReason})`
- [ ] **AC1.3:** `ParticipantListState` freezed class created at `tkd_brackets/lib/features/participant/presentation/bloc/participant_list_state.dart`
- [ ] **AC1.4:** States use EMBEDDED `ActionStatus` to prevent UI flashing. States: `initial()`, `loadInProgress()`, `loadSuccess({required DivisionParticipantView view, required String searchQuery, required ParticipantFilter currentFilter, required ParticipantSort currentSort, required List<ParticipantEntity> filteredParticipants, @Default(ActionStatus.idle) ActionStatus actionStatus, String? actionMessage})`, `loadFailure({required String userFriendlyMessage, String? technicalDetails})`
- [ ] **AC1.4b:** `ActionStatus` enum defined in state file: `idle`, `inProgress`, `success`, `failure`

> ⚠️ **WHY embedded ActionStatus?** If action states (`actionInProgress`, `actionSuccess`) are TOP-LEVEL states, the BlocBuilder replaces the entire participant list with a spinner when the user clicks "Edit". By embedding ActionStatus inside `loadSuccess`, the list stays visible while a loading overlay shows. The BlocListener reacts to `actionStatus` changes for snackbar feedback.
- [ ] **AC1.5:** `ParticipantFilter` enum defined: `all`, `active`, `noShow`, `disqualified`, `checkedIn`
- [ ] **AC1.6:** `ParticipantSort` enum defined: `nameAsc`, `nameDesc`, `dojangAsc`, `beltAsc`, `seedAsc`
- [ ] **AC1.7:** `part 'participant_list_event.freezed.dart'` and `part 'participant_list_state.freezed.dart'` directives present
- [ ] **AC1.8:** Code generation runs without errors

### AC2: ParticipantListBloc Implementation

- [ ] **AC2.1:** `ParticipantListBloc` created at `tkd_brackets/lib/features/participant/presentation/bloc/participant_list_bloc.dart`
- [ ] **AC2.2:** Class annotated with `@injectable`
- [ ] **AC2.3:** Constructor injects use cases: `GetDivisionParticipantsUseCase`, `CreateParticipantUseCase`, `UpdateParticipantUseCase`, `TransferParticipantUseCase`, `UpdateParticipantStatusUseCase`, `DisqualifyParticipantUseCase`, **AND** `GetDivisionsUseCase` (from `features/division/domain/usecases/`) for loading available divisions in the transfer dialog
- [ ] **AC2.4:** `_onLoadRequested` calls `GetDivisionParticipantsUseCase(event.divisionId)` and emits `loadInProgress` → `loadSuccess` or `loadFailure`
- [ ] **AC2.5:** `_onSearchQueryChanged` filters participants in-memory by name, dojang, or belt containing the query (case-insensitive)
- [ ] **AC2.6:** `_onFilterChanged` filters participants by `checkInStatus` matching the filter
- [ ] **AC2.7:** `_onSortChanged` sorts the filtered participant list according to the sort enum value
- [ ] **AC2.8:** `_onCreateRequested` calls `CreateParticipantUseCase(params)` — emits `loadSuccess.copyWith(actionStatus: ActionStatus.inProgress)` → on success `copyWith(actionStatus: ActionStatus.success, actionMessage: 'Participant added')` → triggers `_onRefreshRequested`
- [ ] **AC2.9:** `_onEditRequested` calls `UpdateParticipantUseCase(params)` — same embedded action pattern as AC2.8
- [ ] **AC2.10:** `_onTransferRequested` calls `TransferParticipantUseCase(params)` — same embedded action pattern as AC2.8
- [ ] **AC2.11:** `_onStatusChangeRequested` — uses `UpdateParticipantStatusUseCase` for ALL status changes. Call: `_updateParticipantStatusUseCase(participantId: event.participantId, newStatus: event.newStatus, dqReason: event.dqReason)`. The use case handles DQ validation internally (requires non-empty dqReason when newStatus is `disqualified`).
- [ ] **AC2.12:** Stores `_currentDivisionId` and `_currentTournamentId` for refresh and transfer capabilities
- [ ] **AC2.13:** All action handlers use EMBEDDED ActionStatus pattern: `emit(currentLoadSuccess.copyWith(actionStatus: ActionStatus.inProgress))` → success/failure → auto-refresh on success. The list remains visible during actions.
- [ ] **AC2.14:** `_onLoadAvailableDivisions` event calls `GetDivisionsUseCase(tournamentId)` to populate division list for transfer dialog

### AC3: CSVImportBloc Events, States, and Implementation

- [ ] **AC3.1:** `CSVImportEvent` and `CSVImportState` freezed classes created in separate files
- [ ] **AC3.2:** Events include: `csvContentSubmitted({required String csvContent, required String divisionId, required String tournamentId})`, `rowSelectionToggled(int rowNumber)`, `selectAllToggled()`, `importConfirmed({required String divisionId})`
- [ ] **AC3.3:** States include: `initial()`, `previewInProgress()`, `previewSuccess({required BulkImportPreview preview, required Set<int> selectedRows})`, `previewFailure({required String message})`, `importInProgress()`, `importSuccess({required BulkImportResult result})`, `importFailure({required String message})`
- [ ] **AC3.4:** `CSVImportBloc` created, annotated `@injectable`, injects `BulkImportUseCase`
- [ ] **AC3.5:** `_onCsvContentSubmitted` calls `BulkImportUseCase.generatePreview()` and emits preview state
- [ ] **AC3.6:** `_onRowSelectionToggled` toggles row in `selectedRows` set and re-emits preview state
- [ ] **AC3.7:** `_onSelectAllToggled` selects/deselects all valid+warning rows
- [ ] **AC3.8:** `_onImportConfirmed` filters preview rows by `selectedRows`, calls `BulkImportUseCase.importSelected()`, emits result

### AC4: Participant List Page

- [ ] **AC4.1:** `ParticipantListPage` created at `tkd_brackets/lib/features/participant/presentation/pages/participant_list_page.dart`
- [ ] **AC4.2:** Extends `StatelessWidget`, wraps with `BlocProvider<ParticipantListBloc>`
- [ ] **AC4.3:** Page header shows division name from `DivisionParticipantView` and participant count badge
- [ ] **AC4.4:** Contains `ParticipantSearchBar` widget for search/filter/sort controls
- [ ] **AC4.5:** Renders participant list using `ParticipantCard` widgets
- [ ] **AC4.6:** Search filters participants by firstName, lastName, schoolOrDojangName, beltRank (case-insensitive)
- [ ] **AC4.7:** FAB (FloatingActionButton) for "Add Participant" opens `ParticipantFormDialog` in create mode
- [ ] **AC4.8:** AppBar actions include "Import CSV" button that navigates to `CsvImportPage`
- [ ] **AC4.9:** Empty state shown when no participants match (illustration/icon + helpful CTA)
- [ ] **AC4.10:** Loading state uses `CircularProgressIndicator` (centered)
- [ ] **AC4.11:** Error state shows `userFriendlyMessage` with retry button
- [ ] **AC4.12:** Uses `BlocConsumer` — `listener` for success/failure snackbar toasts, `builder` for UI state

### AC5: CSV Import Page

- [ ] **AC5.1:** `CsvImportPage` created at `tkd_brackets/lib/features/participant/presentation/pages/csv_import_page.dart`
- [ ] **AC5.2:** Wraps with `BlocProvider<CSVImportBloc>`
- [ ] **AC5.3:** Step 1: Text area for pasting CSV content (or file upload via `FilePicker` — can use a simple `TextField` with `maxLines: null` for MVP)
- [ ] **AC5.4:** Step 2: Preview table showing parsed rows with status indicators (green=valid, yellow=warning/duplicate, red=error)
- [ ] **AC5.5:** Row selection via checkboxes — error rows are disabled/unchecked
- [ ] **AC5.6:** "Select All" checkbox for batch selection
- [ ] **AC5.7:** "Import Selected" button with count badge, disabled when no rows selected
- [ ] **AC5.8:** Import result display: "N imported successfully, M failed" with error details

### AC6: Participant Card Widget

- [ ] **AC6.1:** `ParticipantCard` created at `tkd_brackets/lib/features/participant/presentation/widgets/participant_card.dart`
- [ ] **AC6.2:** Displays: full name, dojang, belt rank, age (computed), weight, status badge, seed number
- [ ] **AC6.3:** Status badge uses semantic colors: pending=gray, checkedIn=green, noShow=amber, withdrawn=blueGrey, disqualified=red
- [ ] **AC6.4:** Action menu (PopupMenuButton) dynamically shows ONLY valid transitions based on current status. Use `_validTransitions` map from Status Transition Rules. Example: if status is `checkedIn`, show only "Withdraw" and "Disqualify" (not "Check-In" or "Mark No-Show")
- [ ] **AC6.5:** Edit action opens `ParticipantFormDialog` in edit mode with pre-filled data
- [ ] **AC6.6:** Transfer action opens a dialog that loads available divisions via `GetDivisionsUseCase` → shows a dropdown/list of other divisions in the same tournament (excluding current division). Submits `TransferParticipantParams(participantId: participant.id, targetDivisionId: selectedDivision.id)`
- [ ] **AC6.7:** DQ action opens dialog with `TextField` for reason → submits `statusChangeRequested(participantId: participant.id, newStatus: ParticipantStatus.disqualified, dqReason: reason)`
- [ ] **AC6.8:** Destructive actions (no-show, DQ, withdraw) show confirmation dialog before executing
- [ ] **AC6.9:** Card receives `divisionId` and `tournamentId` as parameters for transfer context

### AC7: Participant Form Dialog

- [ ] **AC7.1:** `ParticipantFormDialog` created at `tkd_brackets/lib/features/participant/presentation/widgets/participant_form_dialog.dart`
- [ ] **AC7.2:** Supports both CREATE mode (empty fields) and EDIT mode (pre-filled with existing participant data)
- [ ] **AC7.3:** Form fields: firstName (required), lastName (required), schoolOrDojangName (required), beltRank (required, dropdown or validated text), dateOfBirth (DatePicker), gender (dropdown: male/female/unset), weightKg (number input), registrationNumber (text), notes (multiline text)
- [ ] **AC7.4:** Client-side validation matches domain validation: firstName/lastName/dojang/belt non-empty, weight >= 0 and <= 150, age 4-80 if DOB provided
- [ ] **AC7.5:** Uses `Form` with `GlobalKey<FormState>` and `TextFormField` validators
- [ ] **AC7.6:** Submit constructs either `CreateParticipantParams` or `UpdateParticipantParams` and adds corresponding BLoC event

### AC8: Search & Filter Bar Widget

- [ ] **AC8.1:** `ParticipantSearchBar` created at `tkd_brackets/lib/features/participant/presentation/widgets/participant_search_bar.dart`
- [ ] **AC8.2:** Contains `SearchBar` (Material 3) or `TextField` with search icon and debounced input
- [ ] **AC8.3:** Filter chips for status: All, Active (pending+checkedIn), No-Show, DQ
- [ ] **AC8.4:** Sort dropdown: Name A-Z, Name Z-A, Dojang A-Z, Belt, Seed #

### AC9: Route Registration

- [ ] **AC9.1:** `ParticipantListRoute` added to `routes.dart` with path `/tournaments/:tournamentId/divisions/:divisionId/participants`
- [ ] **AC9.2:** `CsvImportRoute` added to `routes.dart` with path `/tournaments/:tournamentId/divisions/:divisionId/participants/import`
- [ ] **AC9.3:** Both routes use `@TypedGoRoute` annotations with proper parameter types
- [ ] **AC9.4:** Routes registered in `app_router.dart` shell routes list
- [ ] **AC9.5:** `dart run build_runner build` generates `routes.g.dart` successfully

### AC10: Unit Tests — ParticipantListBloc

- [ ] **AC10.1:** Test file at `tkd_brackets/test/features/participant/presentation/bloc/participant_list_bloc_test.dart`
- [ ] **AC10.2:** Tests initial state is `ParticipantListInitial`
- [ ] **AC10.3:** Tests load success: emits [loadInProgress, loadSuccess] with correct DivisionParticipantView
- [ ] **AC10.4:** Tests load failure: emits [loadInProgress, loadFailure] with error message
- [ ] **AC10.5:** Tests search filtering: emits [loadSuccess with updated filteredParticipants] — filters by name, dojang, belt (case-insensitive)
- [ ] **AC10.6:** Tests filter by status: emits [loadSuccess with updated filteredParticipants]
- [ ] **AC10.7:** Tests sort: emits [loadSuccess with re-sorted filteredParticipants]
- [ ] **AC10.8:** Tests create: emits [loadSuccess(actionStatus: inProgress), loadSuccess(actionStatus: success), loadInProgress, loadSuccess] — action + refresh
- [ ] **AC10.9:** Tests create failure: emits [loadSuccess(actionStatus: inProgress), loadSuccess(actionStatus: failure)]
- [ ] **AC10.10:** Tests edit participant: same embedded action pattern as AC10.8
- [ ] **AC10.11:** Tests transfer participant: same embedded action pattern as AC10.8
- [ ] **AC10.12:** Tests status change: verifies `UpdateParticipantStatusUseCase` called with correct named params `(participantId: ..., newStatus: ..., dqReason: ...)`

### AC11: Unit Tests — CSVImportBloc

- [ ] **AC11.1:** Test file at `tkd_brackets/test/features/participant/presentation/bloc/csv_import_bloc_test.dart`
- [ ] **AC11.2:** Tests initial state is `CSVImportInitial`
- [ ] **AC11.3:** Tests preview success: emits [previewInProgress, previewSuccess] with preview data
- [ ] **AC11.4:** Tests preview failure: emits [previewInProgress, previewFailure]
- [ ] **AC11.5:** Tests row selection toggle
- [ ] **AC11.6:** Tests select all toggle
- [ ] **AC11.7:** Tests import success: emits [importInProgress, importSuccess]
- [ ] **AC11.8:** Tests import failure: emits [importInProgress, importFailure]

### AC12: Build Verification

- [ ] **AC12.1:** `dart run build_runner build --delete-conflicting-outputs` completes without errors
- [ ] **AC12.2:** `dart analyze` shows no errors in modified/created files
- [ ] **AC12.3:** All new tests pass (`flutter test test/features/participant/presentation/`)
- [ ] **AC12.4:** All existing tests still pass (`flutter test`)
- [ ] **AC12.5:** UI renders correctly with Material Design 3 theme

---


## Tasks/Subtasks

### Task 1: BLoC Infrastructure & Events/States
- [ ] **1.1:** Create `ParticipantListEvent` at `tkd_brackets/lib/features/participant/presentation/bloc/participant_list_event.dart`
- [ ] **1.2:** Create `ParticipantListState` at `tkd_brackets/lib/features/participant/presentation/bloc/participant_list_state.dart`
- [ ] **1.3:** Create `ParticipantListBloc` at `tkd_brackets/lib/features/participant/presentation/bloc/participant_list_bloc.dart`
- [ ] **1.4:** Create `CSVImportEvent` and `CSVImportState`
- [ ] **1.5:** Create `CSVImportBloc` at `tkd_brackets/lib/features/participant/presentation/bloc/csv_import_bloc.dart`
- [ ] **1.6:** Run `build_runner` to generate freezed files

### Task 2: Unit Testing - BLoCs
- [ ] **2.1:** Create `ParticipantListBloc` tests at `tkd_brackets/test/features/participant/presentation/bloc/participant_list_bloc_test.dart`
- [ ] **2.2:** Create `CSVImportBloc` tests at `tkd_brackets/test/features/participant/presentation/bloc/csv_import_bloc_test.dart`
- [ ] **2.3:** Verify all BLoC tests pass

### Task 3: Route Registration & Navigation
- [ ] **3.1:** Register `ParticipantListRoute` and `CsvImportRoute` in `routes.dart`
- [ ] **3.2:** Update `app_router.dart` with new routes
- [ ] **3.3:** Add navigation from `TournamentDetailPage` to `ParticipantListPage`
- [ ] **3.4:** Run `build_runner` for route generation

### Task 4: Reusable Presentation Widgets
- [ ] **4.1:** Implement `ParticipantCard`
- [ ] **4.2:** Implement `ParticipantSearchBar` with debounce
- [ ] **4.3:** Implement `ParticipantFormDialog` (Create/Edit modes)
- [ ] **4.4:** Implement `ImportPreviewTable`

### Task 5: Participant Management Pages
- [ ] **5.1:** Implement `ParticipantListPage`
- [ ] **5.2:** Implement `CsvImportPage` wizard

### Task 6: Final Validation & Fixes
- [ ] **6.1:** Run full test suite
- [ ] **6.2:** Perform code analysis
- [ ] **6.3:** Verify AC compliance

## Dev Notes


### ⚠️ CRITICAL: BLoC Pattern — Follow `TournamentBloc` Exactly

The existing `TournamentBloc` at `tkd_brackets/lib/features/tournament/presentation/bloc/tournament_bloc.dart` is the **REFERENCE IMPLEMENTATION** for all BLoCs.

**Key patterns to copy:**
```dart
// 1. Class declaration — NOTE: includes GetDivisionsUseCase for transfer dialog
@injectable
class ParticipantListBloc extends Bloc<ParticipantListEvent, ParticipantListState> {
  ParticipantListBloc(
    this._getDivisionParticipantsUseCase,
    this._createParticipantUseCase,
    this._updateParticipantUseCase,
    this._transferParticipantUseCase,
    this._updateParticipantStatusUseCase,
    this._disqualifyParticipantUseCase,
    this._getDivisionsUseCase,  // For loading divisions in transfer dialog
  ) : super(const ParticipantListInitial()) {
    on<ParticipantListLoadRequested>(_onLoadRequested);
    on<ParticipantListRefreshRequested>(_onRefreshRequested);
    on<ParticipantListSearchQueryChanged>(_onSearchQueryChanged);
    on<ParticipantListFilterChanged>(_onFilterChanged);
    on<ParticipantListSortChanged>(_onSortChanged);
    on<ParticipantListCreateRequested>(_onCreateRequested);
    on<ParticipantListEditRequested>(_onEditRequested);
    on<ParticipantListTransferRequested>(_onTransferRequested);
    on<ParticipantListStatusChangeRequested>(_onStatusChangeRequested);
  }

  final GetDivisionParticipantsUseCase _getDivisionParticipantsUseCase;
  final CreateParticipantUseCase _createParticipantUseCase;
  final UpdateParticipantUseCase _updateParticipantUseCase;
  final TransferParticipantUseCase _transferParticipantUseCase;
  final UpdateParticipantStatusUseCase _updateParticipantStatusUseCase;
  final DisqualifyParticipantUseCase _disqualifyParticipantUseCase;
  final GetDivisionsUseCase _getDivisionsUseCase;

  String? _currentDivisionId;
  String? _currentTournamentId;

// 2. Load handler — EXACT pattern from TournamentBloc
  Future<void> _onLoadRequested(
    ParticipantListLoadRequested event,
    Emitter<ParticipantListState> emit,
  ) async {
    emit(const ParticipantListLoadInProgress());
    _currentDivisionId = event.divisionId;

    final result = await _getDivisionParticipantsUseCase(event.divisionId);

    result.fold(
      (failure) => emit(
        ParticipantListLoadFailure(
          userFriendlyMessage: failure.userFriendlyMessage,
          technicalDetails: failure.technicalDetails,
        ),
      ),
      (view) {
        _currentTournamentId = view.division.tournamentId;
        emit(
          ParticipantListLoadSuccess(
            view: view,
            searchQuery: '',
            currentFilter: ParticipantFilter.all,
            currentSort: ParticipantSort.nameAsc,
            filteredParticipants: _sortParticipants(
              view.participants, ParticipantSort.nameAsc,
            ),
          ),
        );
      },
    );
  }

// 3. Action handler — EMBEDDED ActionStatus pattern (prevents UI flashing)
  Future<void> _onCreateRequested(
    ParticipantListCreateRequested event,
    Emitter<ParticipantListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ParticipantListLoadSuccess) return;

    emit(currentState.copyWith(actionStatus: ActionStatus.inProgress));

    final result = await _createParticipantUseCase(event.params);

    result.fold(
      (failure) => emit(currentState.copyWith(
        actionStatus: ActionStatus.failure,
        actionMessage: failure.userFriendlyMessage,
      )),
      (_) {
        emit(currentState.copyWith(
          actionStatus: ActionStatus.success,
          actionMessage: 'Participant added successfully',
        ));
        // Auto-refresh after successful action
        add(const ParticipantListRefreshRequested());
      },
    );
  }

// 4. Status change handler — uses NAMED params, NOT a params class
  Future<void> _onStatusChangeRequested(
    ParticipantListStatusChangeRequested event,
    Emitter<ParticipantListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ParticipantListLoadSuccess) return;

    emit(currentState.copyWith(actionStatus: ActionStatus.inProgress));

    // UpdateParticipantStatusUseCase handles ALL status changes including DQ
    // It validates dqReason internally when newStatus is disqualified
    final result = await _updateParticipantStatusUseCase(
      participantId: event.participantId,
      newStatus: event.newStatus,
      dqReason: event.dqReason,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(
        actionStatus: ActionStatus.failure,
        actionMessage: failure.userFriendlyMessage,
      )),
      (_) {
        emit(currentState.copyWith(
          actionStatus: ActionStatus.success,
          actionMessage: 'Status updated',
        ));
        add(const ParticipantListRefreshRequested());
      },
    );
  }
}
```

### ⚠️ CRITICAL: Freezed Event/State Pattern

Events and states MUST use `freezed` — exact pattern from `tournament_event.dart`:

```dart
// participant_list_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/create_participant_params.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/update_participant_params.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/transfer_participant_params.dart';

part 'participant_list_event.freezed.dart';

// Define enums HERE, BEFORE the @freezed class (same as TournamentFilter in tournament_event.dart)
enum ParticipantFilter { all, active, noShow, disqualified, checkedIn }
enum ParticipantSort { nameAsc, nameDesc, dojangAsc, beltAsc, seedAsc }

@freezed
class ParticipantListEvent with _$ParticipantListEvent {
  const factory ParticipantListEvent.loadRequested({
    required String divisionId,
  }) = ParticipantListLoadRequested;
  const factory ParticipantListEvent.refreshRequested() =
      ParticipantListRefreshRequested;
  const factory ParticipantListEvent.searchQueryChanged(String query) =
      ParticipantListSearchQueryChanged;
  // ... etc
}
```

```dart
// participant_list_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/division_participant_view.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/participant_list_event.dart';

part 'participant_list_state.freezed.dart';

// ActionStatus enum — embedded in loadSuccess to prevent UI flashing
enum ActionStatus { idle, inProgress, success, failure }

@freezed
class ParticipantListState with _$ParticipantListState {
  const factory ParticipantListState.initial() = ParticipantListInitial;
  const factory ParticipantListState.loadInProgress() =
      ParticipantListLoadInProgress;
  const factory ParticipantListState.loadSuccess({
    required DivisionParticipantView view,
    required String searchQuery,
    required ParticipantFilter currentFilter,
    required ParticipantSort currentSort,
    required List<ParticipantEntity> filteredParticipants,
    @Default(ActionStatus.idle) ActionStatus actionStatus,
    String? actionMessage,
  }) = ParticipantListLoadSuccess;
  const factory ParticipantListState.loadFailure({
    required String userFriendlyMessage,
    String? technicalDetails,
  }) = ParticipantListLoadFailure;
}
```

> ⚠️ **NO separate `actionInProgress`, `actionSuccess`, `actionFailure` top-level states!** Use `loadSuccess.copyWith(actionStatus: ...)` instead. The BlocListener checks for `actionStatus` changes to show snackbars:
```dart
// In page: BlocListener pattern for action feedback
BlocListener<ParticipantListBloc, ParticipantListState>(
  listenWhen: (prev, curr) {
    if (prev is ParticipantListLoadSuccess && curr is ParticipantListLoadSuccess) {
      return prev.actionStatus != curr.actionStatus;
    }
    return false;
  },
  listener: (context, state) {
    if (state is ParticipantListLoadSuccess) {
      if (state.actionStatus == ActionStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.actionMessage ?? 'Success')),
        );
      } else if (state.actionStatus == ActionStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.actionMessage ?? 'An error occurred'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  },
)
```

### ⚠️ CRITICAL: BLoC Testing Pattern — Use `bloc_test` Package

Follow the exact pattern from `tournament_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/usecases/get_divisions_usecase.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/create_participant_params.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/create_participant_usecase.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/disqualify_participant_usecase.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/division_participant_view.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/get_division_participants_usecase.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/transfer_participant_params.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/transfer_participant_usecase.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/update_participant_params.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/update_participant_status_usecase.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/update_participant_usecase.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/participant_list_bloc.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/participant_list_event.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/participant_list_state.dart';

// Mock classes — one per injected use case
class MockGetDivisionParticipantsUseCase extends Mock
    implements GetDivisionParticipantsUseCase {}
class MockCreateParticipantUseCase extends Mock
    implements CreateParticipantUseCase {}
class MockUpdateParticipantUseCase extends Mock
    implements UpdateParticipantUseCase {}
class MockTransferParticipantUseCase extends Mock
    implements TransferParticipantUseCase {}
class MockUpdateParticipantStatusUseCase extends Mock
    implements UpdateParticipantStatusUseCase {}
class MockDisqualifyParticipantUseCase extends Mock
    implements DisqualifyParticipantUseCase {}
class MockGetDivisionsUseCase extends Mock
    implements GetDivisionsUseCase {}

// Fake classes — ONLY for use cases that accept positional Params objects
// UpdateParticipantStatusUseCase and DisqualifyParticipantUseCase use NAMED params
// so they do NOT need Fake classes. Use `any(named: 'participantId')` etc.
class FakeCreateParticipantParams extends Fake
    implements CreateParticipantParams {}
class FakeUpdateParticipantParams extends Fake
    implements UpdateParticipantParams {}
class FakeTransferParticipantParams extends Fake
    implements TransferParticipantParams {}

void main() {
  late MockGetDivisionParticipantsUseCase mockGetParticipants;
  late MockCreateParticipantUseCase mockCreate;
  late MockUpdateParticipantUseCase mockUpdate;
  late MockTransferParticipantUseCase mockTransfer;
  late MockUpdateParticipantStatusUseCase mockUpdateStatus;
  late MockDisqualifyParticipantUseCase mockDisqualify;
  late MockGetDivisionsUseCase mockGetDivisions;

  setUpAll(() {
    registerFallbackValue('test-division-id');
    registerFallbackValue(FakeCreateParticipantParams());
    registerFallbackValue(FakeUpdateParticipantParams());
    registerFallbackValue(FakeTransferParticipantParams());
    // NO registerFallbackValue for UpdateParticipantStatusUseCase or
    // DisqualifyParticipantUseCase — they use named params, not positional
  });

  setUp(() {
    mockGetParticipants = MockGetDivisionParticipantsUseCase();
    mockCreate = MockCreateParticipantUseCase();
    mockUpdate = MockUpdateParticipantUseCase();
    mockTransfer = MockTransferParticipantUseCase();
    mockUpdateStatus = MockUpdateParticipantStatusUseCase();
    mockDisqualify = MockDisqualifyParticipantUseCase();
    mockGetDivisions = MockGetDivisionsUseCase();
  });

  // ⚠️ ALL REQUIRED FIELDS must be present — bracketFormat is REQUIRED
  final tDivision = DivisionEntity(
    id: 'division-456',
    tournamentId: 'tournament-789',
    name: 'Junior Boys -45kg',
    category: DivisionCategory.sparring,
    gender: DivisionGender.male,
    bracketFormat: BracketFormat.singleElimination,  // ← REQUIRED!
    status: DivisionStatus.setup,
    createdAtTimestamp: DateTime(2026),
    updatedAtTimestamp: DateTime(2026),
  );

  final tParticipant = ParticipantEntity(
    id: 'participant-123',
    divisionId: 'division-456',
    firstName: 'John',
    lastName: 'Kim',
    createdAtTimestamp: DateTime(2026),
    updatedAtTimestamp: DateTime(2026),
  );

  final tDivisionParticipantView = DivisionParticipantView(
    division: tDivision,
    participants: [tParticipant],
    participantCount: 1,
  );

  ParticipantListBloc buildBloc() {
    return ParticipantListBloc(
      mockGetParticipants,
      mockCreate,
      mockUpdate,
      mockTransfer,
      mockUpdateStatus,
      mockDisqualify,
      mockGetDivisions,
    );
  }

  group('ParticipantListBloc', () {
    test('initial state is ParticipantListInitial', () {
      final bloc = buildBloc();
      expect(bloc.state, const ParticipantListInitial());
      bloc.close();
    });

    group('ParticipantListLoadRequested', () {
      blocTest<ParticipantListBloc, ParticipantListState>(
        'emits [loadInProgress, loadSuccess] when loaded successfully',
        build: () {
          when(() => mockGetParticipants(any())).thenAnswer(
            (_) async => Right(tDivisionParticipantView),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          const ParticipantListLoadRequested(divisionId: 'div-123'),
        ),
        expect: () => [
          const ParticipantListLoadInProgress(),
          isA<ParticipantListLoadSuccess>()
              .having((s) => s.view, 'view', tDivisionParticipantView)
              .having((s) => s.actionStatus, 'actionStatus', ActionStatus.idle),
        ],
      );
    });

    group('StatusChangeRequested', () {
      // Mock UpdateParticipantStatusUseCase with NAMED params
      blocTest<ParticipantListBloc, ParticipantListState>(
        'calls UpdateParticipantStatusUseCase with named params',
        seed: () => ParticipantListLoadSuccess(
          view: tDivisionParticipantView,
          searchQuery: '',
          currentFilter: ParticipantFilter.all,
          currentSort: ParticipantSort.nameAsc,
          filteredParticipants: [tParticipant],
        ),
        build: () {
          when(() => mockUpdateStatus(
            participantId: any(named: 'participantId'),
            newStatus: any(named: 'newStatus'),
            dqReason: any(named: 'dqReason'),
          )).thenAnswer((_) async => Right(tParticipant));
          when(() => mockGetParticipants(any())).thenAnswer(
            (_) async => Right(tDivisionParticipantView),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          const ParticipantListStatusChangeRequested(
            participantId: 'participant-123',
            newStatus: ParticipantStatus.noShow,
          ),
        ),
        verify: (_) {
          verify(() => mockUpdateStatus(
            participantId: 'participant-123',
            newStatus: ParticipantStatus.noShow,
          )).called(1);
        },
      );
    });
  });
}
```

### ⚠️ CRITICAL: Page Pattern — Follow `TournamentListPage`

The `TournamentListPage` is the reference for all list pages:

```dart
// Pattern: StatelessWidget that creates BlocProvider
class ParticipantListPage extends StatelessWidget {
  const ParticipantListPage({
    required this.divisionId,
    super.key,
  });

  final String divisionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ParticipantListBloc>()
        ..add(ParticipantListLoadRequested(divisionId: divisionId)),
      child: _ParticipantListView(divisionId: divisionId),
    );
  }
}

class _ParticipantListView extends StatelessWidget {
  // ... uses BlocConsumer for reactive UI
}
```

### ⚠️ CRITICAL: Route Registration Pattern

Follow the exact pattern from `routes.dart`:

```dart
// Add to routes.dart
@TypedGoRoute<ParticipantListRoute>(
  path: '/tournaments/:tournamentId/divisions/:divisionId/participants',
)
class ParticipantListRoute extends GoRouteData {
  const ParticipantListRoute({
    required this.tournamentId,
    required this.divisionId,
  });

  final String tournamentId;
  final String divisionId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ParticipantListPage(divisionId: divisionId);
}

@TypedGoRoute<CsvImportRoute>(
  path: '/tournaments/:tournamentId/divisions/:divisionId/participants/import',
)
class CsvImportRoute extends GoRouteData {
  const CsvImportRoute({
    required this.tournamentId,
    required this.divisionId,
  });

  final String tournamentId;
  final String divisionId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CsvImportPage(divisionId: divisionId, tournamentId: tournamentId);
}
```

**⚠️ IMPORTANT:** After adding routes to `routes.dart`, add them to the shell routes list in `app_router.dart`:
```dart
// In app_router.dart, add to createAppShellRoute routes list:
$participantListRoute,
$csvImportRoute,
```

### Search/Filter/Sort — In-Memory Operations

Search, filter, and sort operate on the ALREADY-LOADED participants list from `DivisionParticipantView`. No additional use case calls needed. This keeps the UI responsive.

**Search:** Case-insensitive contains match against: `firstName`, `lastName`, `schoolOrDojangName`, `beltRank`

**Filter:**
- `all` — exclude soft-deleted only (`!isDeleted`)
- `active` — `checkInStatus == pending || checkInStatus == checkedIn`
- `noShow` — `checkInStatus == noShow`
- `disqualified` — `checkInStatus == disqualified`
- `checkedIn` — `checkInStatus == checkedIn`

**Sort:** Sort the filtered list. For name sorts, combine `lastName + firstName`. For dojang, sort by `schoolOrDojangName ?? ''`.

### Material Design 3 — Design Tokens

From UX spec — use these design tokens:
- **Primary:** Deep Navy (#1A237E) — main CTAs, headers
- **Secondary:** Warm Gold (#F9A825) — accents, highlights
- **Success:** Green (#388E3C) — check-in, completed
- **Warning:** Amber (#F57C00) — byes, attention
- **Error:** Red (#D32F2F) — DQ, errors
- **Surface:** Light Gray (#F5F5F5) — cards
- **Font:** Inter (already configured in app theme)

### Participant Card — Status Badge Colors

```dart
Color _statusColor(ParticipantStatus status) => switch (status) {
  ParticipantStatus.pending => Colors.grey,
  ParticipantStatus.checkedIn => const Color(0xFF388E3C),
  ParticipantStatus.noShow => const Color(0xFFF57C00),
  ParticipantStatus.withdrawn => Colors.blueGrey,
  ParticipantStatus.disqualified => const Color(0xFFD32F2F),
};
```

### CSV Import Page — Wizard Steps

The CSV import follows a simple 2-step flow:
1. **Input:** Paste/type CSV content into a large text area
2. **Preview & Import:** Show preview table, select rows, confirm import

This is NOT a multi-page wizard. It's a single page with state transitions managed by the CSVImportBloc. The state determines which content is shown.

### Entity Constructor Required Fields Reference

When creating test participants, ALL required fields MUST be provided:

```dart
final tParticipant = ParticipantEntity(
  id: 'participant-123',
  divisionId: 'division-456',
  firstName: 'John',
  lastName: 'Kim',
  createdAtTimestamp: DateTime(2026),
  updatedAtTimestamp: DateTime(2026),
);

// ⚠️ bracketFormat is REQUIRED — omitting it causes a compile error!
final tDivision = DivisionEntity(
  id: 'division-456',
  tournamentId: 'tournament-789',
  name: 'Junior Boys -45kg',
  category: DivisionCategory.sparring,
  gender: DivisionGender.male,
  bracketFormat: BracketFormat.singleElimination,  // REQUIRED!
  ageMin: 10,
  ageMax: 14,
  status: DivisionStatus.setup,
  createdAtTimestamp: DateTime(2026),
  updatedAtTimestamp: DateTime(2026),
);

// DivisionParticipantView (freezed)
final tView = DivisionParticipantView(
  division: tDivision,
  participants: [tParticipant],
  participantCount: 1,
);
```

### Import Paths — Full Package Paths ONLY

Use full package imports, never relative. Key imports for this story:

```dart
// BLoC files
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/usecases.dart';
import 'package:tkd_brackets/features/division/domain/usecases/get_divisions_usecase.dart'; // For transfer dialog

// Page files
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tkd_brackets/core/di/injection.dart';

// Test files
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
```

### Project Structure Notes

- All source files are under `tkd_brackets/lib/features/participant/presentation/`
- All test files are under `tkd_brackets/test/features/participant/presentation/`
- The project root for Flutter commands is `tkd_brackets/` (the Flutter project is a subdirectory of the repo)
- Run `dart run build_runner build --delete-conflicting-outputs` from `tkd_brackets/` directory
- Run `flutter test` from `tkd_brackets/` directory

### References

- [Source: tkd_brackets/lib/features/tournament/presentation/bloc/tournament_bloc.dart] — BLoC reference implementation
- [Source: tkd_brackets/lib/features/tournament/presentation/bloc/tournament_event.dart] — Freezed event pattern
- [Source: tkd_brackets/lib/features/tournament/presentation/bloc/tournament_state.dart] — Freezed state pattern
- [Source: tkd_brackets/lib/features/tournament/presentation/pages/tournament_list_page.dart] — List page pattern
- [Source: tkd_brackets/lib/features/tournament/presentation/pages/tournament_detail_page.dart] — Detail page pattern with tabs
- [Source: tkd_brackets/lib/features/tournament/presentation/widgets/tournament_card.dart] — Card widget pattern
- [Source: tkd_brackets/lib/features/tournament/presentation/widgets/tournament_form_dialog.dart] — Form dialog pattern
- [Source: tkd_brackets/test/features/tournament/presentation/bloc/tournament_bloc_test.dart] — BLoC test pattern with bloc_test
- [Source: tkd_brackets/lib/core/router/routes.dart] — Route registration pattern
- [Source: tkd_brackets/lib/core/router/app_router.dart] — Router shell configuration
- [Source: tkd_brackets/lib/features/participant/domain/usecases/usecases.dart] — All available participant use cases
- [Source: tkd_brackets/lib/features/participant/domain/entities/participant_entity.dart] — ParticipantEntity definition
- [Source: tkd_brackets/lib/features/participant/domain/usecases/get_division_participants_usecase.dart] — Read use case
- [Source: tkd_brackets/lib/features/participant/domain/usecases/create_participant_usecase.dart] — Create use case
- [Source: tkd_brackets/lib/features/participant/domain/usecases/update_participant_usecase.dart] — Update use case
- [Source: tkd_brackets/lib/features/participant/domain/usecases/transfer_participant_usecase.dart] — Transfer use case
- [Source: tkd_brackets/lib/features/participant/domain/usecases/bulk_import_usecase.dart] — CSV import use case
- [Source: tkd_brackets/lib/features/participant/domain/usecases/division_participant_view.dart] — DivisionParticipantView entity
- [Source: tkd_brackets/lib/features/participant/domain/usecases/update_participant_status_usecase.dart] — Status change use case with valid transition map
- [Source: tkd_brackets/lib/features/participant/domain/usecases/disqualify_participant_usecase.dart] — DQ use case (named params)
- [Source: tkd_brackets/lib/features/participant/domain/usecases/bulk_import_preview.dart] — BulkImportPreview entity
- [Source: tkd_brackets/lib/features/participant/domain/usecases/bulk_import_preview_row.dart] — BulkImportPreviewRow entity
- [Source: tkd_brackets/lib/features/participant/domain/usecases/bulk_import_result.dart] — BulkImportResult entity
- [Source: tkd_brackets/lib/features/participant/domain/usecases/bulk_import_row_status.dart] — BulkImportRowStatus enum
- [Source: tkd_brackets/lib/features/participant/domain/services/csv_row_data.dart] — CSVRowData entity
- [Source: tkd_brackets/lib/features/division/domain/usecases/get_divisions_usecase.dart] — GetDivisionsUseCase for transfer
- [Source: tkd_brackets/lib/features/division/domain/entities/division_entity.dart] — DivisionEntity with ALL required fields incl. bracketFormat
- [Source: tkd_brackets/lib/core/error/failures.dart] — Failure types
- [Source: _bmad-output/planning-artifacts/epics.md#Story 4.12] — Original story requirements
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md] — UX patterns (Athlete Card, navigation, feedback patterns)
- [Source: _bmad-output/planning-artifacts/architecture.md] — Naming conventions, layer dependency rules

### ⚠️ IMPORTANT: Search Debounce Pattern

The search bar MUST debounce input to avoid excessive BLoC events. Use a `Timer` in the `_ParticipantSearchBarState`:

```dart
class _ParticipantSearchBarState extends State<ParticipantSearchBar> {
  Timer? _debounceTimer;

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      context.read<ParticipantListBloc>().add(
        ParticipantListSearchQueryChanged(query),
      );
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
```

### ⚠️ IMPORTANT: ParticipantFormDialog Context

- **CREATE mode:** The dialog receives `divisionId` from the `ParticipantListPage` parameter. It constructs `CreateParticipantParams(divisionId: divisionId, firstName: ..., ...)` and adds `ParticipantListCreateRequested(params: params)` to the BLoC.
- **EDIT mode:** The dialog receives the existing `ParticipantEntity` to pre-fill fields. It constructs `UpdateParticipantParams(participantId: participant.id, firstName: ...)` (only changed fields are non-null) and adds `ParticipantListEditRequested(params: params)`.

### ⚠️ IMPORTANT: TournamentDetailPage Navigation Integration

The existing `TournamentDetailPage._buildDivisionsTab()` (line ~340-357) shows division `ListTile` items without `onTap` navigation. This story MUST add `onTap` to navigate to the participant list:

```dart
// In TournamentDetailPage._buildDivisionsTab, add to the ListTile:
onTap: () {
  context.go('/tournaments/${widget.tournamentId}/divisions/${division.id}/participants');
},
```

This connects the existing division list to the new participant management pages.

### 📌 SCOPE NOTE: Division Assignment View

The epics AC mentions "Division Assignment view (drag-and-drop or checkbox selection)". This story implements:
- **Transfer between divisions** via the participant card action menu (AC6.6)
- **Auto-assignment** is available via `AutoAssignParticipantsUseCase` but a dedicated assignment UI is **DEFERRED** to a future story as it requires additional UX design for drag-and-drop interaction.

The core assignment functionality is fully covered by the transfer dialog and the existing `AssignToDivisionUseCase`.

### ⚠️ DivisionEntity REQUIRED FIELDS — COMPILE ERROR PREVENTION

`DivisionEntity` requires ALL of these fields. Missing any one causes a compile error:
```
id, tournamentId, name, category, gender, bracketFormat, status,
createdAtTimestamp, updatedAtTimestamp
```
The most commonly forgotten field is `bracketFormat: BracketFormat.singleElimination`.

---

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
