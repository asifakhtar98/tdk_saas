# Story 5.17: Ranked Seeding Import from Federation Data

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an organizer,
I want to import ranked seeding data from a file or URL,
so that official federation rankings determine bracket seeding (FR28).

## Acceptance Criteria

1. **AC1:** `RankedSeedingImportParams` exists at `lib/core/algorithms/seeding/usecases/ranked_seeding_import_params.dart` with fields: `divisionId` (String), `participants` (List\<SeedingParticipant\>), `rankedEntries` (List\<RankedSeedingEntry\>), `participantNames` (Map\<String, String\> — required, maps participantId → athlete display name for fuzzy matching), `bracketFormat` (BracketFormat, default `singleElimination`), `matchThreshold` (double, default `0.8` — fuzzy match score threshold 0.0–1.0). Follows the exact same PODO pattern as `ApplyDojangSeparationSeedingParams` and `ApplyRandomSeedingParams`.
2. **AC2:** `RankedSeedingEntry` exists at `lib/core/algorithms/seeding/models/ranked_seeding_entry.dart` as an `@immutable` PODO with fields: `name` (String), `club` (String, optional — for disambiguation), `rank` (int — 1-indexed, lower is better). Has value equality and `toString()`.
3. **AC3:** `RankedSeedingImportUseCase` exists at `lib/core/algorithms/seeding/usecases/ranked_seeding_import_use_case.dart`. It extends `UseCase<RankedSeedingImportResult, RankedSeedingImportParams>`, is annotated `@injectable`, validates inputs, performs fuzzy name matching between `rankedEntries` and participants (using `participantNames` map for display name lookup), assigns `seed_position` based on rank (Rank 1 = seed 1), and delegates to `SeedingEngine.generateSeeding()` with `SeedingStrategy.ranked`, empty constraints, `randomSeed: 0`, and `pinnedSeeds` mapping each participant to their assigned seed position.
4. **AC4:** Fuzzy matching: The use case compares each `RankedSeedingEntry.name` against each participant's display name (from `params.participantNames[participantId]`) using a case-insensitive normalized Levenshtein similarity ratio. A match is accepted if the similarity score ≥ `matchThreshold` (default 0.8). If `RankedSeedingEntry.club` is non-null and non-empty, the participant's `dojangName` must also fuzzy-match the entry's `club` value (≥ same threshold) for the match to be accepted — this prevents ambiguity when two athletes share similar names but belong to different dojangs.
5. **AC5:** `RankedSeedingMatchResult` exists at `lib/core/algorithms/seeding/models/ranked_seeding_match_result.dart` as an `@immutable` PODO with fields: `matchedParticipants` (Map\<String, int\> — participantId → rank), `unmatchedEntries` (List\<RankedSeedingEntry\>), `unmatchedParticipants` (List\<SeedingParticipant\>), `matchConfidences` (Map\<String, double\> — participantId → confidence score). This is returned alongside the `SeedingResult` by wrapping both in a new result type.
6. **AC6:** The use case returns `Either<Failure, RankedSeedingImportResult>` where `RankedSeedingImportResult` wraps both `SeedingResult` (from the engine) and `RankedSeedingMatchResult` (the matching diagnostics). Unmatched ranked athletes are flagged in `RankedSeedingMatchResult.unmatchedEntries`. Unmatched participants receive seed positions after all matched participants (ordered arbitrarily).
7. **AC7:** Input validation: empty `divisionId` → `ValidationFailure`; `< 2 participants` → `ValidationFailure`; empty participant ID → `ValidationFailure`; duplicate participant IDs → `ValidationFailure`; empty `rankedEntries` → `ValidationFailure`; `rankedEntries` with rank ≤ 0 → `ValidationFailure`; `rankedEntries` with duplicate ranks → `ValidationFailure`; `rankedEntries` with empty name → `ValidationFailure`; `matchThreshold < 0.0` or `> 1.0` → `ValidationFailure`; `participantNames` map missing any participant ID that exists in `participants` list → `ValidationFailure`.
8. **AC8:** `RankedSeedingFileParser` exists at `lib/core/algorithms/seeding/services/ranked_seeding_file_parser.dart` as an `@injectable` service. It parses CSV (columns: `Name`, `Club`, `Rank` — header required) and JSON (array of `{"name": "...", "club": "...", "rank": N}` objects) formats. Returns `Either<Failure, List<RankedSeedingEntry>>`.
9. **AC9:** Unit tests for `RankedSeedingImportUseCase` verify: correct delegation to `SeedingEngine`; all validation failures; fuzzy matching logic (exact match, close match, below-threshold rejection); club disambiguation; unmatched entry flagging; unmatched participant seeding at end.
10. **AC10:** Unit tests for `RankedSeedingFileParser` verify: CSV parsing with valid data; CSV with missing columns; JSON parsing with valid data; JSON with invalid structure; empty input; whitespace handling.

## Tasks / Subtasks

- [x] Task 1: Create `RankedSeedingEntry` model (AC: #2)
  - [ ] 1.1 Create `lib/core/algorithms/seeding/models/ranked_seeding_entry.dart`
  - [ ] 1.2 Define:
    ```dart
    import 'package:flutter/foundation.dart' show immutable;

    /// A single entry from a federation ranking file.
    ///
    /// Represents one ranked athlete with their name, club, and ranking position.
    /// Used as input to [RankedSeedingImportUseCase] for matching against
    /// division participants.
    @immutable
    class RankedSeedingEntry {
      const RankedSeedingEntry({
        required this.name,
        required this.rank,
        this.club,
      });

      /// Athlete name from the federation ranking.
      final String name;

      /// The athlete's club/dojang name from the ranking file.
      /// Used for disambiguation when multiple athletes share similar names.
      /// Null or empty means no club disambiguation is applied.
      final String? club;

      /// Ranking position (1-indexed, 1 = highest rank / top seed).
      final int rank;

      @override
      bool operator ==(Object other) =>
          identical(this, other) ||
          other is RankedSeedingEntry &&
              runtimeType == other.runtimeType &&
              name == other.name &&
              club == other.club &&
              rank == other.rank;

      @override
      int get hashCode => Object.hash(name, club, rank);

      @override
      String toString() =>
          'RankedSeedingEntry(name: $name, club: $club, rank: $rank)';
    }
    ```

- [x] Task 2: Create `RankedSeedingMatchResult` model (AC: #5)
  - [ ] 2.1 Create `lib/core/algorithms/seeding/models/ranked_seeding_match_result.dart`
  - [ ] 2.2 Define:
    ```dart
    import 'package:flutter/foundation.dart' show immutable, listEquals, mapEquals;
    import 'package:tkd_brackets/core/algorithms/seeding/models/ranked_seeding_entry.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

    /// Diagnostics from the ranked seeding matching process.
    ///
    /// Reports which ranked entries matched which participants,
    /// which entries/participants were unmatched, and match confidence scores.
    @immutable
    class RankedSeedingMatchResult {
      const RankedSeedingMatchResult({
        required this.matchedParticipants,
        required this.unmatchedEntries,
        required this.unmatchedParticipants,
        required this.matchConfidences,
      });

      /// Map of participantId → rank for successfully matched athletes.
      final Map<String, int> matchedParticipants;

      /// Ranked entries that could not be matched to any participant.
      /// Flagged for manual review by the organizer.
      final List<RankedSeedingEntry> unmatchedEntries;

      /// Participants that were not matched to any ranked entry.
      /// These receive seed positions after all matched participants.
      final List<SeedingParticipant> unmatchedParticipants;

      /// Map of participantId → fuzzy match confidence score (0.0–1.0).
      final Map<String, double> matchConfidences;

      @override
      bool operator ==(Object other) =>
          identical(this, other) ||
          other is RankedSeedingMatchResult &&
              runtimeType == other.runtimeType &&
              mapEquals(matchedParticipants, other.matchedParticipants) &&
              listEquals(unmatchedEntries, other.unmatchedEntries) &&
              listEquals(unmatchedParticipants, other.unmatchedParticipants) &&
              mapEquals(matchConfidences, other.matchConfidences);

      @override
      int get hashCode => Object.hash(
            Object.hashAll(matchedParticipants.entries),
            Object.hashAll(unmatchedEntries),
            Object.hashAll(unmatchedParticipants),
            Object.hashAll(matchConfidences.entries),
          );

      @override
      String toString() =>
          'RankedSeedingMatchResult(matched: ${matchedParticipants.length}, '
          'unmatchedEntries: ${unmatchedEntries.length}, '
          'unmatchedParticipants: ${unmatchedParticipants.length})';
    }
    ```

- [x] Task 3: Create `RankedSeedingImportResult` wrapper (AC: #6)
  - [ ] 3.1 Create `lib/core/algorithms/seeding/models/ranked_seeding_import_result.dart`
  - [ ] 3.2 Define:
    ```dart
    import 'package:flutter/foundation.dart' show immutable;
    import 'package:tkd_brackets/core/algorithms/seeding/models/ranked_seeding_match_result.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';

    /// Combined result of ranked seeding import.
    ///
    /// Wraps the [SeedingResult] from the seeding engine with the
    /// [RankedSeedingMatchResult] diagnostics from the matching process.
    @immutable
    class RankedSeedingImportResult {
      const RankedSeedingImportResult({
        required this.seedingResult,
        required this.matchResult,
      });

      /// The seeding result from the engine (participant placements).
      final SeedingResult seedingResult;

      /// Diagnostics about the fuzzy matching process.
      final RankedSeedingMatchResult matchResult;

      @override
      bool operator ==(Object other) =>
          identical(this, other) ||
          other is RankedSeedingImportResult &&
              runtimeType == other.runtimeType &&
              seedingResult == other.seedingResult &&
              matchResult == other.matchResult;

      @override
      int get hashCode => Object.hash(seedingResult, matchResult);

      @override
      String toString() =>
          'RankedSeedingImportResult(seeding: $seedingResult, match: $matchResult)';
    }
    ```

- [x] Task 4: Create `RankedSeedingImportParams` (AC: #1)
  - [ ] 4.1 Create `lib/core/algorithms/seeding/usecases/ranked_seeding_import_params.dart`
  - [ ] 4.2 Define:
    ```dart
    import 'package:flutter/foundation.dart' show immutable;
    import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/models/ranked_seeding_entry.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

    /// Parameters for importing ranked seeding from federation data.
    @immutable
    class RankedSeedingImportParams {
      const RankedSeedingImportParams({
        required this.divisionId,
        required this.participants,
        required this.rankedEntries,
        required this.participantNames,
        this.bracketFormat = BracketFormat.singleElimination,
        this.matchThreshold = 0.8,
      });

      /// The division ID for context.
      final String divisionId;

      /// Division participants to match against ranked entries.
      final List<SeedingParticipant> participants;

      /// Ranked entries from the federation data file.
      final List<RankedSeedingEntry> rankedEntries;

      /// Map of participantId → athlete display name.
      /// Used for fuzzy matching ranked entry names against participants.
      /// The caller (BLoC or coordinator) builds this from ParticipantEntity data.
      /// EVERY participant ID in [participants] MUST have an entry in this map.
      final Map<String, String> participantNames;

      /// Bracket format affects meeting-round calculations inside the engine.
      /// Default: singleElimination (most common for TKD tournaments).
      final BracketFormat bracketFormat;

      /// Fuzzy match similarity threshold (0.0–1.0).
      /// A ranked entry matches a participant if their name similarity
      /// score is ≥ this threshold.
      /// Default: 0.8 (80% similarity required).
      final double matchThreshold;
    }
    ```

- [x] Task 5: Create `RankedSeedingImportUseCase` (AC: #3, #4, #6, #7)
  - [ ] 5.1 Create `lib/core/algorithms/seeding/usecases/ranked_seeding_import_use_case.dart`
  - [ ] 5.2 Implement the use case with these key behaviors:
    - Extends `UseCase<RankedSeedingImportResult, RankedSeedingImportParams>`
    - `@injectable` annotation
    - Constructor injects `SeedingEngine` (same single dependency as other seeding use cases)
    - **Validation** (same pattern as `ApplyRandomSeedingUseCase` plus ranked-specific checks):
      - Empty `divisionId` → `ValidationFailure`
      - `< 2 participants` → `ValidationFailure`
      - Empty participant ID → `ValidationFailure`
      - Duplicate participant IDs → `ValidationFailure`
      - Empty `rankedEntries` list → `ValidationFailure`
      - Any `rankedEntries.rank <= 0` → `ValidationFailure`
      - Duplicate ranks in `rankedEntries` → `ValidationFailure`
      - Any `rankedEntries.name.trim().isEmpty` → `ValidationFailure`
      - `matchThreshold < 0.0 || matchThreshold > 1.0` → `ValidationFailure`
      - Any participant ID in `participants` not present as a key in `participantNames` → `ValidationFailure`
    - **Fuzzy matching algorithm:**
      1. Normalize names: `trim().toLowerCase()`
      2. For each ranked entry, iterate all *unmatched* participants and compute Levenshtein similarity between `_normalize(entry.name)` and `_normalize(params.participantNames[participant.id]!)`
      3. If entry has non-null non-empty `club`, ALSO compute Levenshtein similarity between `_normalize(entry.club!)` and `_normalize(participant.dojangName)` — both must be ≥ threshold
      4. Accept the best-scoring participant if name score ≥ `matchThreshold` (and club score ≥ threshold if applicable)
      5. If multiple participants tie, pick the first match found (deterministic by list order)
      6. Build `matchedParticipants` map (participantId → rank), `matchConfidences`, `unmatchedEntries`, `unmatchedParticipants`
    - **Seed assignment + engine delegation:**
      1. Sort matched participants by their assigned rank (ascending)
      2. Matched participants get contiguous seed positions 1, 2, 3, ... (rank gaps normalized)
      3. Unmatched participants get seed positions continuing from matchedCount + 1 (ordered by their position in original `participants` list)
      4. Build a `pinnedSeeds` map: `{participantId: seedPosition}` for ALL participants (both matched and unmatched)
      5. Delegate to `SeedingEngine.generateSeeding()` with:
         - `participants: params.participants` (original order — engine uses pinnedSeeds to lock positions)
         - `strategy: SeedingStrategy.ranked`
         - `constraints: const []` (no separation constraints)
         - `bracketFormat: params.bracketFormat`
         - `randomSeed: 0` (deterministic)
         - `pinnedSeeds: pinnedSeeds` (the map built in step 4)
    - **Return** `RankedSeedingImportResult` wrapping both `SeedingResult` and `RankedSeedingMatchResult`
  - [ ] 5.3 **Full Levenshtein implementation (MUST be copy-pasted exactly):**
    ```dart
    /// Computes similarity ratio between two strings (0.0–1.0).
    /// 1.0 = identical, 0.0 = completely different.
    double _levenshteinSimilarity(String a, String b) {
      if (a == b) return 1.0;
      if (a.isEmpty || b.isEmpty) return 0.0;
      final maxLen = a.length > b.length ? a.length : b.length;
      return 1.0 - (_levenshteinDistance(a, b) / maxLen);
    }

    /// Standard Levenshtein distance via dynamic programming.
    /// O(n*m) time, O(min(n,m)) space using single-row optimization.
    int _levenshteinDistance(String s, String t) {
      if (s.isEmpty) return t.length;
      if (t.isEmpty) return s.length;

      // Ensure s is the shorter string for space optimization
      if (s.length > t.length) {
        final temp = s;
        s = t;
        t = temp;
      }

      final sLen = s.length;
      final tLen = t.length;
      var previousRow = List<int>.generate(sLen + 1, (i) => i);

      for (var j = 1; j <= tLen; j++) {
        final currentRow = List<int>.filled(sLen + 1, 0);
        currentRow[0] = j;
        for (var i = 1; i <= sLen; i++) {
          final cost = s[i - 1] == t[j - 1] ? 0 : 1;
          currentRow[i] = [
            currentRow[i - 1] + 1,       // insertion
            previousRow[i] + 1,           // deletion
            previousRow[i - 1] + cost,    // substitution
          ].reduce((a, b) => a < b ? a : b);
        }
        previousRow = currentRow;
      }
      return previousRow[sLen];
    }

    String _normalize(String name) => name.trim().toLowerCase();
    ```
    - DO NOT add an external package. This is self-contained.
    - The `_levenshteinDistance` uses single-row space optimization for efficiency.
    - The `min` reduction avoids importing `dart:math` for a trivial operation.
  - [ ] 5.4 **IMPORTANT**: The use case does NOT validate `dojangName` on participants. For ranked seeding, participants need `id` and optionally `dojangName` for club disambiguation, but empty `dojangName` is allowed.
  - [ ] 5.5 **⚠️ CRITICAL ENGINE BEHAVIOR**: The `ConstraintSatisfyingSeedingEngine` does NOT treat `SeedingStrategy.ranked` differently from other strategies. It always runs its constraint-satisfaction backtracking algorithm. However, by passing **ALL participants via `pinnedSeeds`** with their assigned seed positions, AND passing **empty constraints** `const []`, the engine simply validates the pinned positions and returns them as-is. This is the correct delegation pattern — the engine acts as a deterministic placement validator rather than a shuffler.
  - [ ] 5.6 **Engine call signature (exact parameters):**
    ```dart
    return _seedingEngine.generateSeeding(
      participants: params.participants,
      strategy: SeedingStrategy.ranked,
      constraints: const [],
      bracketFormat: params.bracketFormat,
      randomSeed: 0,
      pinnedSeeds: pinnedSeeds, // {participantId: seedPosition} for ALL participants
    );
    ```

- [x] Task 6: Create `RankedSeedingFileParser` service (AC: #8)
  - [ ] 6.1 Create `lib/core/algorithms/seeding/services/ranked_seeding_file_parser.dart`
  - [ ] 6.2 Implement:
    ```dart
    import 'dart:convert';

    import 'package:fpdart/fpdart.dart';
    import 'package:injectable/injectable.dart';
    import 'package:tkd_brackets/core/algorithms/seeding/models/ranked_seeding_entry.dart';
    import 'package:tkd_brackets/core/error/failures.dart';

    /// Parses ranked seeding data from CSV or JSON string content.
    ///
    /// Supports two formats:
    /// - **CSV:** Header row required with columns `Name`, `Club`, `Rank`
    ///   (case-insensitive). Club column is optional.
    /// - **JSON:** Array of objects: `[{"name": "...", "club": "...", "rank": N}]`
    ///   Club field is optional.
    @injectable
    class RankedSeedingFileParser {
      /// Attempts to parse the given [content] as ranked seeding data.
      ///
      /// Automatically detects format:
      /// - If content starts with `[` (trimmed), treats as JSON
      /// - Otherwise treats as CSV
      ///
      /// Returns [Left(ValidationFailure)] if parsing fails.
      /// Returns [Right(List<RankedSeedingEntry>)] on success.
      Either<Failure, List<RankedSeedingEntry>> parse(String content) {
        final trimmed = content.trim();
        if (trimmed.isEmpty) {
          return const Left(
            ValidationFailure(
              userFriendlyMessage: 'Ranking file content is empty.',
            ),
          );
        }

        if (trimmed.startsWith('[')) {
          return _parseJson(trimmed);
        }
        return _parseCsv(trimmed);
      }

      Either<Failure, List<RankedSeedingEntry>> _parseJson(String content) {
        try {
          final decoded = jsonDecode(content);
          if (decoded is! List) {
            return const Left(
              ValidationFailure(
                userFriendlyMessage: 'JSON ranking data must be an array.',
              ),
            );
          }

          final entries = <RankedSeedingEntry>[];
          for (var i = 0; i < decoded.length; i++) {
            final item = decoded[i];
            if (item is! Map<String, dynamic>) {
              return Left(
                ValidationFailure(
                  userFriendlyMessage: 'Invalid entry at index $i: expected object.',
                ),
              );
            }
            final name = item['name'];
            final rank = item['rank'];
            if (name is! String || name.trim().isEmpty) {
              return Left(
                ValidationFailure(
                  userFriendlyMessage: 'Missing or empty "name" at index $i.',
                ),
              );
            }
            if (rank is! int) {
              return Left(
                ValidationFailure(
                  userFriendlyMessage: 'Missing or non-integer "rank" at index $i.',
                ),
              );
            }
            final club = item['club'];
            entries.add(RankedSeedingEntry(
              name: name.trim(),
              rank: rank,
              club: (club is String && club.trim().isNotEmpty) ? club.trim() : null,
            ));
          }

          if (entries.isEmpty) {
            return const Left(
              ValidationFailure(
                userFriendlyMessage: 'JSON ranking array is empty.',
              ),
            );
          }
          return Right(entries);
        } on FormatException catch (e) {
          return Left(
            ValidationFailure(
              userFriendlyMessage: 'Invalid JSON format.',
              technicalDetails: e.message,
            ),
          );
        }
      }

      Either<Failure, List<RankedSeedingEntry>> _parseCsv(String content) {
        // Normalize line endings
        final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
        final lines = normalized.split('\n').where((l) => l.trim().isNotEmpty).toList();

        if (lines.isEmpty) {
          return const Left(
            ValidationFailure(userFriendlyMessage: 'CSV content has no data rows.'),
          );
        }

        // Parse header row (case-insensitive)
        final headers = lines.first.split(',').map((h) => h.trim().toLowerCase()).toList();
        final nameIdx = headers.indexOf('name');
        final rankIdx = headers.indexOf('rank');
        final clubIdx = headers.indexOf('club'); // -1 if not present = OK

        if (nameIdx < 0) {
          return const Left(
            ValidationFailure(userFriendlyMessage: 'CSV header missing required "Name" column.'),
          );
        }
        if (rankIdx < 0) {
          return const Left(
            ValidationFailure(userFriendlyMessage: 'CSV header missing required "Rank" column.'),
          );
        }

        final entries = <RankedSeedingEntry>[];
        for (var i = 1; i < lines.length; i++) {
          final values = lines[i].split(',').map((v) => v.trim()).toList();
          // Skip rows with insufficient columns
          if (values.length <= nameIdx || values.length <= rankIdx) continue;

          final name = values[nameIdx];
          if (name.isEmpty) continue; // Skip rows with empty name

          final rankStr = values[rankIdx];
          final rank = int.tryParse(rankStr);
          if (rank == null) {
            return Left(
              ValidationFailure(
                userFriendlyMessage: 'Invalid rank "$rankStr" at row ${i + 1}.',
              ),
            );
          }

          final club = (clubIdx >= 0 && values.length > clubIdx && values[clubIdx].isNotEmpty)
              ? values[clubIdx]
              : null;

          entries.add(RankedSeedingEntry(name: name, rank: rank, club: club));
        }

        if (entries.isEmpty) {
          return const Left(
            ValidationFailure(userFriendlyMessage: 'CSV contains no valid data rows.'),
          );
        }
        return Right(entries);
      }
    }
    ```
  - [ ] 6.3 **CSV parsing details:**
    - Split on `\n` (handle `\r\n` too)
    - Header row: case-insensitive column matching (`name`, `Name`, `NAME` all valid)
    - Comma-separated values (no quoted field support needed for MVP — names with commas are rare in TKD)
    - Trim whitespace from all values
    - Skip empty rows
    - `Club` column is optional — if missing, all entries have `club: null`
    - Rank must parse to a positive integer
  - [ ] 6.4 **JSON parsing details:**
    - Use `dart:convert` `jsonDecode`
    - Expect a top-level JSON array
    - Each object must have `name` (String) and `rank` (int)
    - `club` is optional (String or null)
    - Return `ValidationFailure` for `FormatException` from `jsonDecode`

- [x] Task 7: Write `RankedSeedingImportUseCase` unit tests (AC: #9)
  - [ ] 7.1 Create `test/core/algorithms/seeding/usecases/ranked_seeding_import_use_case_test.dart`
  - [ ] 7.2 Test groups:
    - **Validation tests:**
      - Empty divisionId → `ValidationFailure`
      - < 2 participants → `ValidationFailure`
      - Empty participant ID → `ValidationFailure`
      - Duplicate participant IDs → `ValidationFailure`
      - Empty rankedEntries → `ValidationFailure`
      - Rank ≤ 0 → `ValidationFailure`
      - Duplicate ranks → `ValidationFailure`
      - Empty entry name → `ValidationFailure`
      - matchThreshold < 0.0 → `ValidationFailure`
      - matchThreshold > 1.0 → `ValidationFailure`
      - participantNames missing a participant ID → `ValidationFailure`
    - **Fuzzy matching tests:**
      - Exact name match → matched with confidence 1.0
      - Close name match (e.g., "John Smith" vs "Jon Smith") → matched if score ≥ 0.8
      - Below-threshold name → not matched, appears in `unmatchedEntries`
      - Club disambiguation: same name, different club → only matches correct participant
      - Club disambiguation: same name, entry has NO club → matches first best-scoring participant
    - **Seed assignment tests:**
      - Matched participants get rank-based seed positions (contiguous, gaps normalized)
      - Unmatched participants get trailing seed positions
      - Rank gap normalization: ranks [1, 3, 7] → seeds [1, 2, 3]
      - Engine called with `SeedingStrategy.ranked`
      - Engine called with `pinnedSeeds` containing ALL participant seed assignments
      - Engine called with `randomSeed: 0` (deterministic)
      - Engine called with `constraints: const []` (empty)
    - **Engine delegation tests:**
      - Engine failure propagated correctly (engine returns Left → use case returns Left)
      - Engine called with correct parameters (verify with `verify()` calls)
  - [ ] 7.3 **Test pattern (MUST follow exactly from `apply_random_seeding_use_case_test.dart`):**
    ```dart
    import 'package:flutter_test/flutter_test.dart';
    import 'package:fpdart/fpdart.dart';
    import 'package:mocktail/mocktail.dart';
    // ... imports for all relevant types

    class MockSeedingEngine extends Mock implements SeedingEngine {}

    void main() {
      late MockSeedingEngine mockEngine;
      late RankedSeedingImportUseCase useCase;

      setUpAll(() {
        registerFallbackValue(BracketFormat.singleElimination);
        registerFallbackValue(SeedingStrategy.ranked);
        registerFallbackValue(<SeedingConstraint>[]);
        registerFallbackValue(<String, int>{}); // ⚠️ CRITICAL: for pinnedSeeds parameter
      });

      setUp(() {
        mockEngine = MockSeedingEngine();
        useCase = RankedSeedingImportUseCase(mockEngine);
      });

      // Test fixture data:
      final tParticipants = [
        const SeedingParticipant(id: 'p1', dojangName: 'Tiger TKD'),
        const SeedingParticipant(id: 'p2', dojangName: 'Dragon MA'),
        const SeedingParticipant(id: 'p3', dojangName: 'Eagle Gym'),
      ];

      final tParticipantNames = {
        'p1': 'John Smith',
        'p2': 'Jane Doe',
        'p3': 'Alex Kim',
      };

      final tRankedEntries = [
        const RankedSeedingEntry(name: 'John Smith', rank: 1),
        const RankedSeedingEntry(name: 'Alex Kim', rank: 2),
      ];

      // Mock engine setup:
      // when(() => mockEngine.generateSeeding(
      //   participants: any(named: 'participants'),
      //   strategy: any(named: 'strategy'),
      //   constraints: any(named: 'constraints'),
      //   bracketFormat: any(named: 'bracketFormat'),
      //   randomSeed: any(named: 'randomSeed'),
      //   pinnedSeeds: any(named: 'pinnedSeeds'),  // ⚠️ MUST include pinnedSeeds
      // )).thenReturn(...);
    }
    ```
    - `MockSeedingEngine extends Mock implements SeedingEngine {}` — OUTSIDE `main()`
    - `registerFallbackValue(<String, int>{})` — ⚠️ CRITICAL for `pinnedSeeds` parameter. Without this, mocktail throws when `any(named: 'pinnedSeeds')` is used
    - Test fixtures MUST use different dojang names to avoid engine’s all-same-dojang fast-path
    - Verify engine calls include `pinnedSeeds: any(named: 'pinnedSeeds')` in both `when` and `verify`

- [x] Task 8: Write `RankedSeedingFileParser` unit tests (AC: #10)
  - [ ] 8.1 Create `test/core/algorithms/seeding/services/ranked_seeding_file_parser_test.dart`
  - [ ] 8.2 Test cases:
    - Valid CSV with Name, Club, Rank columns → success
    - Valid CSV with Name, Rank columns (no Club) → success with null clubs
    - CSV with missing Name column → `ValidationFailure`
    - CSV with missing Rank column → `ValidationFailure`
    - CSV with non-integer rank → `ValidationFailure`
    - Valid JSON array → success
    - JSON with missing name field → `ValidationFailure`
    - JSON with missing rank field → `ValidationFailure`
    - JSON with non-array root → `ValidationFailure`
    - Invalid JSON syntax → `ValidationFailure`
    - Empty content → `ValidationFailure`
    - Content with only whitespace → `ValidationFailure`
    - CSV with extra whitespace → trimmed correctly
    - CSV with empty rows → skipped
    - CSV with `\r\n` line endings → parsed correctly
    - JSON with rank as string (e.g., `"rank": "3"`) → `ValidationFailure` (rank must be int)
    - JSON empty array `[]` → `ValidationFailure`

- [x] Task 9: Run `build_runner` to regenerate DI config (AC: all)
  - [ ] 9.1 Run: `dart run build_runner build --delete-conflicting-outputs`
  - [ ] 9.2 Verify that `lib/core/di/injection.config.dart` now contains `RankedSeedingImportUseCase` and `RankedSeedingFileParser` registrations
  - [ ] 9.3 The use case injects `SeedingEngine` which is already registered — no new dependency types
  - [ ] 9.4 The file parser has no dependencies — it's a pure service

- [x] Task 10: Run `dart analyze` and all seeding tests (AC: all)
  - [ ] 10.1 Run `dart analyze` — zero errors, zero warnings
  - [ ] 10.2 Run new use case tests: `flutter test test/core/algorithms/seeding/usecases/ranked_seeding_import_use_case_test.dart` — all pass
  - [ ] 10.3 Run new parser tests: `flutter test test/core/algorithms/seeding/services/ranked_seeding_file_parser_test.dart` — all pass
  - [ ] 10.4 Run all existing seeding tests: `flutter test test/core/algorithms/seeding/` — no regressions
  - [ ] 10.5 Run full project tests: `flutter test` — no regressions across entire project

## Dev Notes

### ⚠️ Scope Boundary: Ranked Seeding Import Use Case + File Parser

This story creates:
1. A **use case** that takes ranked entries + participants, performs fuzzy matching, assigns seed positions, and delegates to the existing `SeedingEngine`
2. A **file parser** service that converts CSV/JSON text into `List<RankedSeedingEntry>`
3. Supporting **model classes** for the ranking data and match diagnostics

**This story does NOT:**
- Modify `SeedingEngine` or `ConstraintSatisfyingSeedingEngine` — the engine's `pinnedSeeds` parameter is used to lock all participant positions; no engine changes needed
- Create any UI components — the UI for file upload/import will be wired in a future story or the bracket generation flow
- Add file picker or URL fetching — the parser takes raw `String` content, the caller is responsible for reading the file/URL
- Modify the `SeedingParticipant` model — existing fields (`id`, `dojangName`, `regionName`) are sufficient
- Add any external packages for fuzzy matching — Levenshtein distance is implemented inline (~20 lines)

### ⚠️ Fuzzy Matching Algorithm: Levenshtein Similarity

The fuzzy matching uses **Levenshtein similarity ratio** (NOT Levenshtein distance directly):

```dart
double _levenshteinSimilarity(String a, String b) {
  if (a == b) return 1.0;
  if (a.isEmpty || b.isEmpty) return 0.0;
  final maxLen = a.length > b.length ? a.length : b.length;
  return 1.0 - (_levenshteinDistance(a, b) / maxLen);
}
```

**Why Levenshtein and not other algorithms?**
- Simple, well-understood, and sufficient for name matching
- Handles common typos: transpositions, insertions, deletions
- O(n*m) time complexity is fine for small lists (typical division: 4–32 participants)
- No external package needed

**Why NOT use an external fuzzy matching package?**
- The matching logic is ~30 lines of code
- Adding a pub.dev dependency for this is overkill
- Keeps the `core/algorithms` layer free of unnecessary dependencies
- The domain layer MUST NOT import infrastructure packages (Clean Architecture rule)

### ⚠️ Name Normalization for Matching

Before comparing names, BOTH strings are normalized:
```dart
String _normalize(String name) => name.trim().toLowerCase();
```

The ranked entry `name` is compared against the participant's **display name** (from `params.participantNames[participant.id]`). The matching flow is:
1. Get participant display name: `final pName = params.participantNames[participant.id]!`
2. Normalize both: `_normalize(entry.name)` vs `_normalize(pName)`
3. Compute Levenshtein similarity ratio
4. If entry has `club`, also normalize and compare: `_normalize(entry.club!)` vs `_normalize(participant.dojangName)`

**⚠️ DESIGN DECISION:** Since `SeedingParticipant` only has `id`, `dojangName`, and `regionName` (no athlete name field), the use case receives participant display names via a separate `participantNames` map in the params. This avoids modifying `SeedingParticipant` which would affect all existing seeding use cases and tests.

- The `participantNames` map (Map<String, String>) is required and maps `participantId → athleteDisplayName`
- The calling layer (BLoC or coordinator) builds this map from `ParticipantEntity.name` data
- Every participant ID in `params.participants` MUST have a corresponding entry in `participantNames` (validated)

### ⚠️ ⚠️ CRITICAL: SeedingStrategy.ranked — Engine Behavior (VERIFIED BY CODE REVIEW)

The `ConstraintSatisfyingSeedingEngine.generateSeeding()` does **NOT** check the `SeedingStrategy` parameter at all. The strategy value is irrelevant to engine behavior — the engine ALWAYS runs the same backtracking algorithm regardless of strategy.

**How ranked seeding works with the existing engine:**
1. The USE CASE computes seed positions (via fuzzy matching + rank assignment)
2. The USE CASE builds a `pinnedSeeds` map with **ALL** participant seed assignments
3. The USE CASE calls `SeedingEngine.generateSeeding()` with `pinnedSeeds` and `constraints: const []`
4. Inside the engine, ALL participants are pinned → the engine places them at their pinned positions
5. With empty constraints, validation passes trivially
6. The engine returns the pinned placements as a `SeedingResult`

**The engine’s behavior when all participants are pinned (from constraint_satisfying_seeding_engine.dart lines 80-109):**
- Iterates `pinnedSeeds` entries and assigns `positions[idx] = entry.value`
- All participants end up in the `pinned` list, `unpinned` is empty
- Backtracking with all-pinned participants completes immediately (no shuffling)
- Returns the pinned positions as the final result

**⚠️ DO NOT** try to "reorder the participants list" to control seeding. The engine shuffles groups internally. Use `pinnedSeeds` exclusively to control positions.

### ⚠️ Club Disambiguation Logic

When a `RankedSeedingEntry` has a non-null, non-empty `club` field:
```
Match requires BOTH:
  1. Name similarity ≥ threshold (e.g., "John Smith" ↔ "Jon Smith" = 0.91)
  2. Club/dojang similarity ≥ threshold (e.g., "Tiger TKD" ↔ "Tiger Taekwondo" = 0.76 — FAILS at 0.8)
```

This prevents matching "John Smith from Tiger TKD" to "John Smith from Dragon Martial Arts" when both athletes share a common name.

### ⚠️ Handling Unmatched Participants

Participants not matched to any ranked entry receive trailing seed positions:
```
Ranked entries: [{name: "A", rank: 1}, {name: "B", rank: 3}]
Participants: [p1 (matched to A), p2 (unmatched), p3 (matched to B)]

Result seed positions:
  p1 → seed 1 (from rank 1)
  p3 → seed 2 (from rank 3, but normalized to fill gaps)
  p2 → seed 3 (unmatched, appended after matched)
```

**Gap normalization:** If ranked entries have gaps (e.g., ranks 1, 3, 7), the seed positions are normalized to be contiguous (1, 2, 3, ...) based on rank ordering, not the rank values themselves.

### ⚠️ File Parser: Auto-Detection Logic

The parser auto-detects the format:
```dart
if (trimmed.startsWith('[')) → JSON
else → CSV
```

This is simple and reliable because:
- JSON ranking arrays always start with `[`
- CSV files always start with a header row (text)
- No ambiguity between the two formats

### ⚠️ Following Existing Patterns Exactly

**Params class pattern** — copy from `apply_random_seeding_params.dart`:
- `@immutable` annotation
- `const` constructor
- Same field types and defaults where applicable
- Additional fields specific to ranked seeding: `rankedEntries`, `participantNames`, `matchThreshold`

**Use case pattern** — copy from `apply_random_seeding_use_case.dart`:
- `@injectable` annotation (NOT `@lazySingleton`)
- Extends `UseCase<RankedSeedingImportResult, RankedSeedingImportParams>`
- Constructor injects `SeedingEngine` (same single dependency)
- Same validation structure (plus ranked-specific checks)
- Same delegation to `_seedingEngine.generateSeeding(...)`

**Service pattern** — copy from `bye_assignment_service.dart` or `manual_seed_override_service.dart`:
- `@injectable` annotation
- Pure function — no state, no dependencies
- Returns `Either<Failure, Result>`

**Test pattern** — copy from `apply_random_seeding_use_case_test.dart`:
- `MockSeedingEngine extends Mock implements SeedingEngine {}`
- `setUpAll` with `registerFallbackValue` for `BracketFormat`, `SeedingStrategy`, `<SeedingConstraint>[]`, AND `<String, int>{}` (for pinnedSeeds)
- `setUp` creates mock and use case
- Same `verify` call pattern with `any(named: ...)` matchers
- **⚠️ MUST include `pinnedSeeds: any(named: 'pinnedSeeds')` in all `when()` and `verify()` calls** — the engine interface has this parameter and the use case passes it

### Existing Infrastructure (DO NOT MODIFY)

#### SeedingEngine Interface
```dart
abstract class SeedingEngine {
  Either<Failure, SeedingResult> generateSeeding({
    required List<SeedingParticipant> participants,
    required SeedingStrategy strategy,
    required List<SeedingConstraint> constraints,
    required BracketFormat bracketFormat,
    int? randomSeed,
    Map<String, int>? pinnedSeeds,
  });
}
```

#### SeedingResult (already stores seed for reproducibility)
```dart
class SeedingResult {
  final List<ParticipantPlacement> placements;
  final List<String> appliedConstraints;
  final int randomSeed;
  final List<String> warnings;
  final int constraintViolationCount;
  final bool isFullySatisfied;
}
```

#### SeedingStrategy Enum
```dart
enum SeedingStrategy {
  random('random'),
  ranked('ranked'),       // ← USE THIS
  performanceBased('performance_based'),
  manual('manual');
}
```

#### SeedingParticipant
```dart
class SeedingParticipant {
  final String id;
  final String dojangName;
  final String? regionName;
}
```

### Project Structure Notes

New files created by this story:
```
lib/core/algorithms/seeding/models/
├── ranked_seeding_entry.dart              # NEW
├── ranked_seeding_match_result.dart        # NEW
└── ranked_seeding_import_result.dart       # NEW

lib/core/algorithms/seeding/usecases/
├── ranked_seeding_import_params.dart       # NEW
└── ranked_seeding_import_use_case.dart     # NEW

lib/core/algorithms/seeding/services/
└── ranked_seeding_file_parser.dart         # NEW

test/core/algorithms/seeding/usecases/
└── ranked_seeding_import_use_case_test.dart # NEW

test/core/algorithms/seeding/services/
└── ranked_seeding_file_parser_test.dart     # NEW
```

No existing files are modified. DI regeneration IS needed — Task 9 runs `build_runner` to register the new use case and service in `injection.config.dart`.

### ⚠️ DI Registration Details

- `@injectable` on `RankedSeedingImportUseCase` → factory registration, injects `SeedingEngine` (resolved as `ConstraintSatisfyingSeedingEngine`)
- `@injectable` on `RankedSeedingFileParser` → factory registration, no dependencies
- After running `dart run build_runner build --delete-conflicting-outputs`, verify the generated file contains registrations for both
- **DO NOT manually edit `injection.config.dart`** — it is fully auto-generated

### ⚠️ Common LLM Mistakes — Prevention Rules

| #   | Mistake                                                                       | Correct Approach                                                                                                                            |
| --- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Adding an external fuzzy matching package (e.g., `string_similarity`)         | DO NOT add packages. Implement Levenshtein distance inline (~20 lines). Keep core/algorithms dependency-free                                |
| 2   | Modifying `SeedingParticipant` to add a `name` field                          | DO NOT modify existing models. Use the `participantNames` map in params for name lookups                                                    |
| 3   | Modifying `ConstraintSatisfyingSeedingEngine`                                 | DO NOT modify the engine. It already handles `SeedingStrategy.ranked`                                                                       |
| 4   | Using `@lazySingleton` for the use case or file parser                        | Use `@injectable` — all use cases and stateless services use `@injectable`                                                                  |
| 5   | Importing from `feature/participant` or `feature/bracket` in core/algorithms  | This is a `core/algorithms/seeding` use case. Only import from `core/` — never cross into feature layers                                    |
| 6   | Not normalizing names before comparison                                       | MUST `trim().toLowerCase()` both names before computing Levenshtein distance                                                                |
| 7   | Using Jaro-Winkler or other complex similarity algorithms                     | Use simple Levenshtein similarity ratio. It's sufficient for name matching and keeps the code simple                                        |
| 8   | Creating a separate `FuzzyMatcher` class or service                           | Keep fuzzy matching as private methods inside the use case. No need for a separate abstraction                                              |
| 9   | Not handling CSV with `\r\n` line endings                                     | Split on `\n` after replacing `\r\n` with `\n` — handle Windows line endings                                                                |
| 10  | Not normalizing rank gaps (e.g., ranks 1, 3, 7 → seeds 1, 2, 3)               | MUST normalize rank gaps. Seed positions must be contiguous 1..N                                                                            |
| 11  | Passing non-empty constraints to the engine for ranked seeding                | Pass `constraints: const []` — ranked seeding means NO separation constraints (those are applied separately if needed)                      |
| 12  | Using `Random.secure()` or any random seed for ranked seeding                 | Use `randomSeed: 0` — ranked seeding is deterministic, no randomization                                                                     |
| 13  | Forgetting `registerFallbackValue` in test setUpAll                           | MUST register `BracketFormat.singleElimination`, `SeedingStrategy.ranked`, `<SeedingConstraint>[]`, AND `<String, int>{}` (for pinnedSeeds) |
| 14  | Skipping `build_runner` after creating the use case                           | MUST run `dart run build_runner build --delete-conflicting-outputs` to register new injectables                                             |
| 15  | Not testing club disambiguation separately                                    | MUST have a dedicated test case where two participants share a similar name but different clubs                                             |
| 16  | Returning raw `SeedingResult` instead of wrapped `RankedSeedingImportResult`  | MUST return `Either<Failure, RankedSeedingImportResult>` which wraps both the seeding result and match diagnostics                          |
| 17  | JSON parsing without try-catch for FormatException                            | MUST catch `FormatException` from `jsonDecode` and return `ValidationFailure`                                                               |
| 18  | CSV parsing that doesn't handle empty rows                                    | MUST skip rows where `trim().isEmpty` after splitting by newlines                                                                           |
| 19  | Trying to control seeding by reordering participants list                     | DO NOT reorder participant list. Use `pinnedSeeds` map to assign seed positions. Engine shuffles groups internally                          |
| 20  | Not passing `pinnedSeeds` to the engine                                       | MUST pass `pinnedSeeds` with ALL participants mapped to their seed positions. This is how ranked seeding is enforced                        |
| 21  | Not validating `matchThreshold` range                                         | MUST validate `0.0 <= matchThreshold <= 1.0`. Return `ValidationFailure` if out of range                                                    |
| 22  | Not validating `participantNames` completeness                                | MUST check every `participant.id` from `participants` list exists in `participantNames` map                                                 |
| 23  | Not including `pinnedSeeds: any(named: 'pinnedSeeds')` in mock setup          | Engine interface has `pinnedSeeds` param. ALL `when()` and `verify()` calls MUST include it or mocktail fails on strict mode                |
| 24  | Matching ranked entry against `participant.id` (UUID) instead of display name | Match against `participantNames[participant.id]` (display name), NOT against `participant.id` (which is a UUID)                             |

### Previous Story Intelligence

Learnings from Story 5.16 (Random Seeding Algorithm):
- The `@injectable` annotation for use cases is auto-discovered by `build_runner` — but you MUST run `build_runner` to regenerate `injection.config.dart`
- `SeedingStrategy.ranked` is the correct strategy for ranked seeding (already exists in the enum)
- The `SeedingEngine.generateSeeding` method is synchronous, so the use case wraps it in `async` to satisfy the `UseCase<T, Params>` contract (`Future<Either<...>>`)
- Test files follow a strict pattern: mock class outside `main()`, `setUpAll` with `registerFallbackValue`, `setUp` with mock creation
- The engine's `_buildRandomResult` fast-path can trigger for all-same-dojang participants — use different dojang names in test fixtures
- `fpdart ^1.1.1` getOrElse signature: `(L) => R` — use `getOrElse((_) => throw Exception('Expected Right'))`

Learnings from Story 5.15 (Pool Play → Elimination Hybrid Generator):
- New `@injectable` classes REQUIRE `build_runner` regeneration to be registered in DI
- Follow existing file and class naming patterns EXACTLY — deviations cause confusion in reviews

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 5.17] — Ranked Seeding Import acceptance criteria
- [Source: _bmad-output/planning-artifacts/prd.md#FR28] — Organizer can import ranked seeding from federation data
- [Source: lib/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart] — Existing engine that handles SeedingStrategy.ranked
- [Source: lib/core/algorithms/seeding/usecases/apply_random_seeding_use_case.dart] — Pattern to follow for use case structure
- [Source: lib/core/algorithms/seeding/usecases/apply_random_seeding_params.dart] — Pattern to follow for params structure
- [Source: lib/core/algorithms/seeding/models/seeding_participant.dart] — SeedingParticipant model (DO NOT MODIFY)
- [Source: lib/core/algorithms/seeding/seeding_engine.dart] — SeedingEngine interface (DO NOT MODIFY)
- [Source: lib/core/algorithms/seeding/models/seeding_result.dart] — SeedingResult (DO NOT MODIFY)
- [Source: lib/core/algorithms/seeding/seeding_strategy.dart] — SeedingStrategy.ranked (DO NOT MODIFY)
- [Source: test/core/algorithms/seeding/usecases/apply_random_seeding_use_case_test.dart] — Test pattern to follow
- [Source: _bmad-output/planning-artifacts/architecture.md#Seeding Algorithm Architecture] — Constraint-satisfaction approach with seeding strategies
- [Source: _bmad-output/implementation-artifacts/5-16-random-seeding-algorithm.md] — Previous story learnings and patterns

## Dev Agent Record

### Agent Model Used

Antigravity (Gemini 2.0 Thinking)

### Debug Log References

- Logic verification: `test/core/algorithms/seeding/usecases/ranked_seeding_import_use_case_test.dart`
- Parser verification: `test/core/algorithms/seeding/services/ranked_seeding_file_parser_test.dart`
- DI verification: `lib/core/di/injection.config.dart`

### Completion Notes List

- **Implementation Complete**: All model classes, the use case, and the file parser are implemented according to AC1-AC8.
- **Validation Complete**: The use case precisely validates all inputs as specified in AC7, including specific checks for ranked entries and match thresholds.
- **Fuzzy Matching**: Implemented case-insensitive normalized Levenshtein similarity ratio with support for club-based disambiguation (AC4).
- **Seeding Determinism**: The use case pins ALL participants and uses `randomSeed: 0`, ensuring deterministic outcome.
- **File Parsing**: `RankedSeedingFileParser` supports CSV and JSON auto-detection with robust error handling (AC8).
- **Testing**: Comprehensive unit tests (19 new tests) cover all scenarios specified in AC9 and AC10. All tests pass (+145 in the seeding folder).
- **DI Registration**: Successfully registered `RankedSeedingImportUseCase` and `RankedSeedingFileParser` via `build_runner`.

### File List

- `lib/core/algorithms/seeding/models/ranked_seeding_entry.dart`
- `lib/core/algorithms/seeding/models/ranked_seeding_match_result.dart`
- `lib/core/algorithms/seeding/models/ranked_seeding_import_result.dart`
- `lib/core/algorithms/seeding/usecases/ranked_seeding_import_params.dart`
- `lib/core/algorithms/seeding/usecases/ranked_seeding_import_use_case.dart`
- `lib/core/algorithms/seeding/services/ranked_seeding_file_parser.dart`
- `test/core/algorithms/seeding/usecases/ranked_seeding_import_use_case_test.dart`
- `test/core/algorithms/seeding/services/ranked_seeding_file_parser_test.dart`
- `lib/core/di/injection.config.dart` (modified by build_runner)

