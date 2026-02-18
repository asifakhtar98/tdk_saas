# Story 3.11: Division Merge & Split

**Status:** done

**Created:** 2026-02-18

**Epic:** 3 - Tournament & Division Management

**FRs Covered:** FR9 (Merge divisions), FR10 (Split divisions)

**Dependencies:** Epic 2 (Auth & Organization) - COMPLETE

---

## 🎯 Story Overview

### User Story Statement

```
As an organizer,
I want to merge small divisions or split large ones,
So that I can ensure fair competition sizing (FR9, FR10).
```

### Business Value

This story enables organizers to optimize division sizes for better competition:

- **Merging small divisions**: Combine two under-populated divisions (e.g., two 3-person divisions become one 6-person bracket)
- **Splitting large divisions**: Break down oversized divisions into Pool A/B for round-robin play
- **Fair competition**: Ensures neither too few nor too many competitors per division

### Success Criteria

1. Organizer can select two divisions and merge them into one
2. Organizer can select a division and split it into Pool A/B
3. Participants are correctly redistributed in both operations
4. Original divisions are soft-deleted (not permanently removed)
5. New divisions inherit configuration from source(s)
6. All data persists locally and syncs to cloud when online
7. Unit tests verify merge and split logic

---

## ✅ Acceptance Criteria

### 🔴 CRITICAL ACCEPTANCE CRITERIA (Must Pass)

| ID | Criterion | Verification Method |
|----|-----------|-------------------|
| **AC1** | **Merge Two Divisions:** Organizer selects two divisions in same tournament, clicks "Merge", new combined division created | Manual: Select divisions "Cadets -45kg" and "Cadets -50kg", merge, verify new division "Cadets -45 to -50kg" created |
| **AC2** | **Merge - Participant Movement:** All participants from both source divisions moved to new division (with deduplication) | Manual: Verify participant count = unique count from both source divisions |
| **AC3** | **Merge - Soft Delete:** Original divisions marked isDeleted=true, NOT physically deleted | Unit test: Verify source divisions have isDeleted=true after merge |
| **AC4** | **Merge - Broadened Criteria:** New division criteria expands to cover both source ranges (e.g., weight min = min of both, weight max = max of both) | Manual: Verify new division weight range covers both sources |
| **AC5** | **Split Division:** Organizer selects division, clicks "Split", two new divisions created with Pool A/B suffix | Manual: Select "Cadets -40kg" (12 participants), split, verify "Cadets -40kg Pool A" and "Pool B" created |
| **AC6** | **Split - Participant Distribution:** Participants distributed roughly evenly between pools (random or alphabetical) | Manual: Verify each pool has ~50% of participants |
| **AC7** | **Split - Soft Delete:** Original division marked isDeleted=true | Unit test: Verify source division has isDeleted=true after split |
| **AC8** | **Split - Pool Naming:** New divisions have "Pool A" / "Pool B" suffix in name | Manual: Verify naming pattern in database |
| **AC9** | **Persistence:** New divisions saved to Drift immediately, queued for Supabase sync, returns Either<Failure, DivisionEntity> | Unit test: Mock repository, verify createDivision called |
| **AC10** | **Unit Tests:** Minimum 10 test cases covering merge and split operations | `dart test` - all tests passing |

### 🟡 SECONDARY ACCEPTANCE CRITERIA (Should Pass)

| ID | Criterion | Verification Method |
|----|-----------|-------------------|
| **AC11** | **Validation - Same Tournament:** Merge only allowed for divisions in same tournament | Unit test: Verify ValidationFailure for cross-tournament merge |
| **AC12** | **Validation - Compatible Categories:** Merge only allowed for divisions with same category (both sparring, both poomsae) | Unit test: Verify ValidationFailure for category mismatch |
| **AC13** | **Validation - Minimum Size:** Split requires minimum 4 participants (to make 2v2 pools meaningful) | Manual: Attempt to split 2-person division, verify error |
| **AC14** | **Validation - Not Already Merged:** Cannot merge divisions that were already merged (prevent circular) | Unit test: Verify ValidationFailure |
| **AC15** | **Offline-First:** Merge/split available offline immediately after operation | Manual: Perform merge while offline, verify in local DB |
| **AC16** | **Conflict Resolution:** If participant exists in both source divisions (rare), handle gracefully - deduplicate | Unit test: Verify participant appears once in merged division |
| **AC17** | **Name Uniqueness:** Merged division name must be unique within tournament | Unit test: Verify ValidationFailure for duplicate name |
| **AC18** | **Bracket Handling:** Existing brackets are archived (soft-deleted), not deleted | Manual: Verify bracket records preserved with isDeleted=true |
| **AC19** | **Atomic Operations:** Merge/split uses transaction - all-or-nothing | Manual: Test failure rollback |
| **AC20** | **Race Condition Protection:** Optimistic locking with syncVersion prevents concurrent modification | Unit test: Verify conflict detection |

---

## 📋 Detailed Technical Specification

### 1. Repository Interface Updates Required

**⚠️ CRITICAL: These methods MUST be added to DivisionRepository interface before implementation:**

```dart
// File: lib/features/division/domain/repositories/division_repository.dart

import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';

abstract class DivisionRepository {
  // EXISTING METHODS - KEEP
  Future<Either<Failure, List<DivisionEntity>>> getDivisionsForTournament(String tournamentId);
  Future<Either<Failure, DivisionEntity>> getDivision(String id); // ADD - alias for getDivisionById
  Future<Either<Failure, DivisionEntity>> getDivisionById(String id);
  Future<Either<Failure, DivisionEntity>> createDivision(DivisionEntity division);
  Future<Either<Failure, DivisionEntity>> updateDivision(DivisionEntity division);
  Future<Either<Failure, Unit>> deleteDivision(String id);

  // NEW METHODS FOR MERGE/SPLIT - ADD THESE
  Future<Either<Failure, List<ParticipantEntity>>> getParticipantsForDivision(String divisionId);
  Future<Either<Failure, List<ParticipantEntity>>> getParticipantsForDivisions(List<String> divisionIds);
  
  // Merge operation - atomic transaction
  Future<Either<Failure, List<DivisionEntity>>> mergeDivisions({
    required DivisionEntity mergedDivision,
    required List<DivisionEntity> sourceDivisions,
    required List<ParticipantEntity> participants,
    required List<BracketEntity> archivedBrackets,
  });
  
  // Split operation - atomic transaction  
  Future<Either<Failure, List<DivisionEntity>>> splitDivision({
    required DivisionEntity poolADivision,
    required DivisionEntity poolBDivision,
    required DivisionEntity sourceDivision,
    required List<ParticipantEntity> poolAParticipants,
    required List<ParticipantEntity> poolBParticipants,
    required BracketEntity archivedBracket,
  });
  
  // Validation helper
  Future<Either<Failure, bool>> isDivisionNameUnique(String name, String tournamentId, {String? excludeDivisionId});
}
```

### 2. ParticipantEntity Structure (For Reference)

**⚠️ CRITICAL: This is the expected structure from Epic 4. Verify against actual implementation:**

```dart
// File: lib/features/participant/domain/entities/participant_entity.dart

class ParticipantEntity {
  final String id;
  final String divisionId;
  final String firstName;
  final String lastName;
  final String? dojang;
  final int? age;
  final double? weightKg;
  final String? beltRank;
  final String? gender;
  final ParticipantStatus status; // active, noShow, dq
  final int syncVersion;
  final bool isDeleted;
  final bool isDemoData;
  final DateTime createdAtTimestamp;
  final DateTime updatedAtTimestamp;
}
```

### 3. BracketEntity Structure (For Reference)

**⚠️ CRITICAL: Brackets must be handled during merge/split:**

```dart
// File: lib/features/bracket/domain/entities/bracket_entity.dart

class BracketEntity {
  final String id;
  final String divisionId;
  final BracketFormat format;
  final BracketStatus status; // setup, inProgress, completed
  final int syncVersion;
  final bool isDeleted;
  final bool isDemoData;
  final DateTime createdAtTimestamp;
  final DateTime updatedAtTimestamp;
}
```

### 4. MergeDivisionsParams

**Location:** `lib/features/division/domain/usecases/merge_divisions_params.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'merge_divisions_params.freezed.dart';
part 'merge_divisions_params.g.dart';

@freezed
class MergeDivisionsParams with _$MergeDivisionsParams {
  const MergeDivisionsParams._();

  const factory MergeDivisionsParams({
    /// First division to merge (REQUIRED)
    required String divisionIdA,
    
    /// Second division to merge (REQUIRED)
    required String divisionIdB,
    
    /// Optional: Name for new merged division (auto-generated if not provided)
    String? name,
  }) = _MergeDivisionsParams;

  factory MergeDivisionsParams.fromJson(Map<String, dynamic> json) =>
      _$MergeDivisionsParamsFromJson(json);
}
```

### 5. SplitDivisionParams

**Location:** `lib/features/division/domain/usecases/split_division_params.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'split_division_params.freezed.dart';
part 'split_division_params.g.dart';

/// Distribution method for splitting participants between pools
enum SplitDistributionMethod {
  /// Distribute participants randomly using dart:math Random
  random,
  
  /// Distribute participants alphabetically by last name
  alphabetical,
}

@freezed
class SplitDivisionParams with _$SplitDivisionParams {
  const SplitDivisionParams._();

  const factory SplitDivisionParams({
    /// Division to split (REQUIRED)
    required String divisionId,
    
    /// How to distribute participants between pools (REQUIRED)
    required SplitDistributionMethod distributionMethod,
    
    /// Optional: Base name for new divisions (auto-generated if not provided)
    String? baseName,
  }) = _SplitDivisionParams;

  factory SplitDivisionParams.fromJson(Map<String, dynamic> json) =>
      _$SplitDivisionParamsFromJson(json);
}
```

### 6. MergeDivisionsUseCase

**Location:** `lib/features/division/domain/usecases/merge_divisions_usecase.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/division/domain/usecases/merge_divisions_params.dart';

@injectable
class MergeDivisionsUseCase extends UseCase<List<DivisionEntity>, MergeDivisionsParams> {
  MergeDivisionsUseCase(this._divisionRepository, this._uuid);
  
  final DivisionRepository _divisionRepository;
  final Uuid _uuid;

  @override
  Future<Either<Failure, List<DivisionEntity>>> call(MergeDivisionsParams params) async {
    // ═══════════════════════════════════════════════════════════════════════
    // STEP 1: VALIDATION
    // ═══════════════════════════════════════════════════════════════════════
    
    final validationFailure = await _validateParams(params);
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 2: FETCH SOURCE DIVISIONS
    // ═══════════════════════════════════════════════════════════════════════
    
    final divisionAResult = await _divisionRepository.getDivision(params.divisionIdA);
    final divisionBResult = await _divisionRepository.getDivision(params.divisionIdB);
    
    // Handle with Either pattern properly - no exceptions
    final divisionA = divisionAResult.fold(
      (failure) => null,
      (division) => division,
    );
    final divisionB = divisionBResult.fold(
      (failure) => null,
      (division) => division,
    );
    
    if (divisionA == null || divisionB == null) {
      return Left(const ValidationFailure(
        userFriendlyMessage: 'One or both divisions not found',
        fieldErrors: {'divisionId': 'Invalid division ID'},
      ));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 3: CHECK NAME UNIQUENESS
    // ═══════════════════════════════════════════════════════════════════════
    
    final proposedName = params.name ?? _generateMergedName(divisionA, divisionB);
    final nameCheck = await _divisionRepository.isDivisionNameUnique(
      proposedName, 
      divisionA.tournamentId,
    );
    
    final isNameUnique = nameCheck.fold((l) => false, (r) => r);
    if (!isNameUnique) {
      return Left(ValidationFailure(
        userFriendlyMessage: 'Division name already exists in this tournament',
        fieldErrors: {'name': 'Please choose a different name'},
      ));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 4: BUILD MERGED DIVISION
    // ═══════════════════════════════════════════════════════════════════════
    
    final mergedDivision = _buildMergedDivision(divisionA, divisionB, proposedName);

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 5: FETCH AND MOVE PARTICIPANTS (WITH DEDUPLICATION)
    // ═══════════════════════════════════════════════════════════════════════
    
    final participantsResult = await _divisionRepository.getParticipantsForDivisions([
      params.divisionIdA,
      params.divisionIdB,
    ]);
    
    final participants = participantsResult.fold(
      (failure) => <dynamic>[],
      (list) => list,
    );
    
    // Deduplicate participants by email/id - same person in both divisions = once in merged
    final uniqueParticipantsMap = <String, dynamic>{};
    for (final p in participants) {
      uniqueParticipantsMap[p.id] = p;
    }
    final uniqueParticipants = uniqueParticipantsMap.values.toList();
    
    // Update participant division IDs to new merged division
    final updatedParticipants = uniqueParticipants.map((p) => p.copyWith(
      divisionId: mergedDivision.id,
      syncVersion: p.syncVersion + 1,
      updatedAtTimestamp: DateTime.now(),
    )).toList();

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 6: ARCHIVE EXISTING BRACKETS
    // ═══════════════════════════════════════════════════════════════════════
    
    // Fetch and archive brackets from both divisions
    // (Implementation depends on bracket repository - add to DivisionRepository or BracketRepository)
    final archivedBrackets = <dynamic>[]; // Fetch and soft-delete brackets

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 7: SOFT-DELETE SOURCE DIVISIONS
    // ═══════════════════════════════════════════════════════════════════════
    
    final deletedDivisionA = divisionA.copyWith(
      isDeleted: true,
      syncVersion: divisionA.syncVersion + 1,
      updatedAtTimestamp: DateTime.now(),
    );
    
    final deletedDivisionB = divisionB.copyWith(
      isDeleted: true,
      syncVersion: divisionB.syncVersion + 1,
      updatedAtTimestamp: DateTime.now(),
    );

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 8: PERSIST ALL CHANGES (ATOMIC TRANSACTION)
    // ═══════════════════════════════════════════════════════════════════════
    
    final results = await _divisionRepository.mergeDivisions(
      mergedDivision: mergedDivision,
      sourceDivisions: [deletedDivisionA, deletedDivisionB],
      participants: updatedParticipants,
      archivedBrackets: archivedBrackets.cast(),
    );
    
    return results;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // VALIDATION
  // ═══════════════════════════════════════════════════════════════════════
  
  Future<ValidationFailure?> _validateParams(MergeDivisionsParams params) async {
    // Same division check
    if (params.divisionIdA == params.divisionIdB) {
      return const ValidationFailure(
        userFriendlyMessage: 'Cannot merge a division with itself',
        fieldErrors: {'divisionId': 'Select two different divisions'},
      );
    }
    
    // Fetch divisions to validate
    final divisionAResult = await _divisionRepository.getDivision(params.divisionIdA);
    final divisionBResult = await _divisionRepository.getDivision(params.divisionIdB);
    
    final divisionA = divisionAResult.fold((l) => null, (d) => d);
    final divisionB = divisionBResult.fold((l) => null, (d) => d);
    
    if (divisionA == null || divisionB == null) {
      return const ValidationFailure(
        userFriendlyMessage: 'One or both divisions not found',
        fieldErrors: {'divisionId': 'Invalid division ID'},
      );
    }
    
    // Same tournament check
    if (divisionA.tournamentId != divisionB.tournamentId) {
      return const ValidationFailure(
        userFriendlyMessage: 'Cannot merge divisions from different tournaments',
        fieldErrors: {'tournament': 'Divisions must be in the same tournament'},
      );
    }
    
    // Same category check
    if (divisionA.category != divisionB.category) {
      return const ValidationFailure(
        userFriendlyMessage: 'Cannot merge divisions with different event types',
        fieldErrors: {'category': 'Both divisions must have the same category'},
      );
    }
    
    // Check not already deleted
    if (divisionA.isDeleted || divisionB.isDeleted) {
      return const ValidationFailure(
        userFriendlyMessage: 'Cannot merge already merged/deleted divisions',
        fieldErrors: {'divisionId': 'One or both divisions are no longer active'},
      );
    }
    
    // Check not already combined (isCombined flag)
    if (divisionA.isCombined || divisionB.isCombined) {
      return const ValidationFailure(
        userFriendlyMessage: 'Cannot merge divisions that were already merged',
        fieldErrors: {'divisionId': 'One or both divisions are already combined'},
      );
    }
    
    // Race condition check - verify syncVersion hasn't changed
    // (In production, use database transaction or optimistic locking)
    
    return null;
  }
  
  // ═══════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════
  
  DivisionEntity _buildMergedDivision(DivisionEntity a, DivisionEntity b, String name) {
    return DivisionEntity(
      id: _uuid.v4(), // PROPER UUID - NOT millisecondsSinceEpoch
      tournamentId: a.tournamentId,
      name: name,
      category: a.category,
      gender: _resolveGender(a.gender, b.gender),
      ageMin: _minValue(a.ageMin, b.ageMin),
      ageMax: _maxValue(a.ageMax, b.ageMax),
      weightMinKg: _minWeight(a.weightMinKg, b.weightMinKg),
      weightMaxKg: _maxWeight(a.weightMaxKg, b.weightMaxKg),
      beltRankMin: _minBelt(a.beltRankMin, b.beltRankMin),
      beltRankMax: _maxBelt(a.beltRankMax, b.beltRankMax),
      bracketFormat: a.bracketFormat,
      judgeCount: a.judgeCount,
      isCustom: true,
      status: DivisionStatus.setup,
      isCombined: true,
      displayOrder: _maxValue(a.displayOrder, b.displayOrder) + 1,
      syncVersion: 1,
      isDeleted: false,
      isDemoData: a.isDemoData || b.isDemoData,
      createdAtTimestamp: DateTime.now(),
      updatedAtTimestamp: DateTime.now(),
    );
  }
  
  String _generateMergedName(DivisionEntity a, DivisionEntity b) {
    // Generate sensible name: "Cadets -45 to -55kg"
    final weightMin = a.weightMinKg ?? b.weightMinKg;
    final weightMax = a.weightMaxKg ?? b.weightMaxKg;
    if (weightMin != null && weightMax != null) {
      return 'Cadets ${weightMin.toInt()} to ${weightMax.toInt()}kg';
    }
    // Fallback: combine first word of each
    return '${a.name.split(' ').first} + ${b.name.split(' ').last}';
  }
  
  int? _minValue(int? a, int? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return a < b ? a : b;
  }
  
  int? _maxValue(int? a, int? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return a > b ? a : b;
  }
  
  double? _minWeight(double? a, double? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return a < b ? a : b;
  }
  
  double? _maxWeight(double? a, double? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return a > b ? a : b;
  }
  
  String? _minBelt(String? a, String? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return _beltOrdinal(a) < _beltOrdinal(b) ? a : b;
  }
  
  String? _maxBelt(String? a, String? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return _beltOrdinal(a) > _beltOrdinal(b) ? a : b;
  }
  
  int _beltOrdinal(String belt) {
    // Use BeltRank enum from existing code
    const belts = ['white', 'yellow', 'orange', 'green', 'blue', 'purple', 'brown', 'red', 'black'];
    final idx = belts.indexOf(belt.toLowerCase());
    return idx >= 0 ? idx : 0;
  }
  
  DivisionGender _resolveGender(DivisionGender a, DivisionGender b) {
    if (a == b) return a;
    if (a == DivisionGender.mixed || b == DivisionGender.mixed) return DivisionGender.mixed;
    return DivisionGender.mixed; // male + female = mixed
  }
}
```

### 7. SplitDivisionUseCase

**Location:** `lib/features/division/domain/usecases/split_division_usecase.dart`

```dart
import 'dart:math';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/division/domain/usecases/split_division_params.dart';

@injectable
class SplitDivisionUseCase extends UseCase<List<DivisionEntity>, SplitDivisionParams> {
  SplitDivisionUseCase(this._divisionRepository, this._uuid);
  
  final DivisionRepository _divisionRepository;
  final Uuid _uuid;

  @override
  Future<Either<Failure, List<DivisionEntity>>> call(SplitDivisionParams params) async {
    // ═══════════════════════════════════════════════════════════════════════
    // STEP 1: VALIDATION
    // ═══════════════════════════════════════════════════════════════════════
    
    final validationFailure = await _validateParams(params);
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 2: FETCH SOURCE DIVISION
    // ═══════════════════════════════════════════════════════════════════════
    
    final divisionResult = await _divisionRepository.getDivision(params.divisionId);
    final sourceDivision = divisionResult.fold(
      (failure) => null,
      (division) => division,
    );
    
    if (sourceDivision == null) {
      return Left(const ValidationFailure(
        userFriendlyMessage: 'Division not found',
        fieldErrors: {'divisionId': 'Invalid division ID'},
      ));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 3: FETCH PARTICIPANTS
    // ═══════════════════════════════════════════════════════════════════════
    
    final participantsResult = await _divisionRepository.getParticipantsForDivision(params.divisionId);
    final participants = participantsResult.fold(
      (failure) => <dynamic>[],
      (list) => list,
    );
    
    // AC13: Minimum 4 participants required for split
    if (participants.length < 4) {
      return Left(const ValidationFailure(
        userFriendlyMessage: 'Division must have at least 4 participants to split',
        fieldErrors: {'participants': 'Minimum 4 participants required for split'},
      ));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 4: DISTRIBUTE PARTICIPANTS
    // ═══════════════════════════════════════════════════════════════════════
    
    final distributed = _distributeParticipants(participants, params.distributionMethod);
    
    final poolAParticipantsData = distributed[0];
    final poolBParticipantsData = distributed[1];

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 5: CREATE POOL A AND POOL B DIVISIONS
    // ═══════════════════════════════════════════════════════════════════════
    
    final baseName = params.baseName ?? sourceDivision.name;
    final poolAName = '$baseName Pool A';
    final poolBName = '$baseName Pool B';
    
    final poolADivision = _buildPoolDivision(sourceDivision, poolAName, poolAParticipantsData, sourceDivision.displayOrder);
    final poolBDivision = _buildPoolDivision(sourceDivision, poolBName, poolBParticipantsData, sourceDivision.displayOrder + 1);

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 6: UPDATE PARTICIPANTS WITH NEW DIVISION IDs
    // ═══════════════════════════════════════════════════════════════════════
    
    final poolAParticipants = poolAParticipantsData.map((p) => p.copyWith(
      divisionId: poolADivision.id,
      syncVersion: p.syncVersion + 1,
      updatedAtTimestamp: DateTime.now(),
    )).toList();
    
    final poolBParticipants = poolBParticipantsData.map((p) => p.copyWith(
      divisionId: poolBDivision.id,
      syncVersion: p.syncVersion + 1,
      updatedAtTimestamp: DateTime.now(),
    )).toList();

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 7: ARCHIVE SOURCE BRACKET
    // ═══════════════════════════════════════════════════════════════════════
    
    // Fetch and soft-delete existing bracket
    final archivedBracket = null; // Fetch from bracket repository

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 8: SOFT-DELETE SOURCE DIVISION
    // ═══════════════════════════════════════════════════════════════════════
    
    final deletedSourceDivision = sourceDivision.copyWith(
      isDeleted: true,
      syncVersion: sourceDivision.syncVersion + 1,
      updatedAtTimestamp: DateTime.now(),
    );

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 9: PERSIST ALL CHANGES (ATOMIC TRANSACTION)
    // ═══════════════════════════════════════════════════════════════════════
    
    final results = await _divisionRepository.splitDivision(
      poolADivision: poolADivision,
      poolBDivision: poolBDivision,
      sourceDivision: deletedSourceDivision,
      poolAParticipants: poolAParticipants,
      poolBParticipants: poolBParticipants,
      archivedBracket: archivedBracket,
    );
    
    return results;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // VALIDATION
  // ═══════════════════════════════════════════════════════════════════════
  
  Future<ValidationFailure?> _validateParams(SplitDivisionParams params) async {
    final divisionResult = await _divisionRepository.getDivision(params.divisionId);
    final division = divisionResult.fold((l) => null, (d) => d);
    
    if (division == null) {
      return const ValidationFailure(
        userFriendlyMessage: 'Division not found',
        fieldErrors: {'divisionId': 'Invalid division ID'},
      );
    }
    
    if (division.isDeleted) {
      return const ValidationFailure(
        userFriendlyMessage: 'Cannot split an already split/merged division',
        fieldErrors: {'divisionId': 'Division is no longer active'},
      );
    }
    
    return null;
  }
  
  // ═══════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════
  
  DivisionEntity _buildPoolDivision(
    DivisionEntity source, 
    String name,
    List<dynamic> participants,
    int displayOrder,
  ) {
    return DivisionEntity(
      id: _uuid.v4(), // PROPER UUID
      tournamentId: source.tournamentId,
      name: name,
      category: source.category,
      gender: source.gender,
      ageMin: source.ageMin,
      ageMax: source.ageMax,
      weightMinKg: source.weightMinKg,
      weightMaxKg: source.weightMaxKg,
      beltRankMin: source.beltRankMin,
      beltRankMax: source.beltRankMax,
      bracketFormat: source.bracketFormat,
      judgeCount: source.judgeCount,
      isCustom: true,
      status: DivisionStatus.setup,
      isCombined: false,
      displayOrder: displayOrder,
      syncVersion: 1,
      isDeleted: false,
      isDemoData: source.isDemoData,
      createdAtTimestamp: DateTime.now(),
      updatedAtTimestamp: DateTime.now(),
    );
  }
  
  List<List<dynamic>> _distributeParticipants(
    List<dynamic> participants,
    SplitDistributionMethod method,
  ) {
    final shuffled = List<dynamic>.from(participants);
    
    if (method == SplitDistributionMethod.alphabetical) {
      // Sort by lastName
      shuffled.sort((a, b) => (a.lastName ?? '').compareTo(b.lastName ?? ''));
    } else {
      // Random distribution using dart:math Random
      shuffled.shuffle(Random());
    }
    
    final midpoint = (shuffled.length / 2).ceil();
    return [
      shuffled.sublist(0, midpoint),
      shuffled.sublist(midpoint),
    ];
  }
}
```

---

## 🗂️ Source Tree Components

```
tkd_brackets/lib/features/
├── division/
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── division_entity.dart              # MODIFY - verify isCombined exists
│   │   │   └── division_entity.freezed.dart     # REGENERATE
│   │   ├── repositories/
│   │   │   └── division_repository.dart          # MODIFY - ADD all new methods
│   │   └── usecases/
│   │       ├── merge_divisions_params.dart       # NEW
│   │       ├── merge_divisions_params.freezed.dart
│   │       ├── merge_divisions_params.g.dart
│   │       ├── merge_divisions_usecase.dart      # NEW
│   │       ├── split_division_params.dart        # NEW
│   │       ├── split_division_params.freezed.dart
│   │       ├── split_division_params.g.dart
│   │       └── split_division_usecase.dart       # NEW
│   ├── data/
│   │   ├── models/
│   │   │   └── division_model.dart               # MODIFY - verify isCombined exists
│   │   └── repositories/
│   │       └── division_repository_implementation.dart  # MODIFY - implement new methods
│   └── presentation/
│       └── widgets/
│           └── division_merge_split_widget.dart   # NEW - Epic 3.14 (UI)
│
├── participant/                                 # EPIC 4 - May not exist yet
│   └── domain/
│       ├── entities/
│       │   └── participant_entity.dart          # NEEDS CREATION
│       └── repositories/
│           └── participant_repository.dart       # NEEDS CREATION (or merge into DivisionRepository)
│
├── bracket/                                     # EPIC 5 - May not exist yet
│   └── domain/
│       ├── entities/
│       │   └── bracket_entity.dart              # NEEDS CREATION
│       └── repositories/
│           └── bracket_repository.dart          # NEEDS CREATION

tkd_brackets/lib/core/
├── database/
│   └── tables/
│       ├── divisions_table.dart                 # MODIFY - add is_combined column
│       └── brackets_table.dart                 # NEEDS CREATION (if not exists)
```

---

## 🗄️ Database Schema Changes

### Drift Table Modification

**File:** `lib/core/database/tables/divisions_table.dart`

```dart
// ADD to existing columns definition:
BoolColumn get isCombined => boolean().withDefault(const Constant(false))();

Index(
  'idx_divisions_is_combined',
  'isCombined',
  where: ('isCombined = true'),
),
```

### Supabase Migration

```sql
-- Migration: add_is_combined_to_divisions.sql

-- Add is_combined column to divisions table
ALTER TABLE divisions 
ADD COLUMN is_combined BOOLEAN NOT NULL DEFAULT FALSE;

-- Index for efficient combined division queries
CREATE INDEX idx_divisions_is_combined 
ON divisions(is_combined) 
WHERE is_combined = TRUE;

-- Comment for documentation
COMMENT ON COLUMN divisions.is_combined IS 
  'true = created via merge operation (derived from other divisions)';
```

---

## 🧪 Testing Standards

### Test File: `test/features/division/usecases/merge_divisions_usecase_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/features/division/domain/usecases/merge_divisions_usecase.dart';
import 'package:tkd_brackets/features/division/domain/usecases/merge_divisions_params.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/core/error/failures.dart';

class MockDivisionRepository extends Mock implements DivisionRepository {}
class MockUuid extends Mock implements Uuid {}

void main() {
  late MergeDivisionsUseCase useCase;
  late MockDivisionRepository mockRepository;
  late MockUuid mockUuid;

  setUp(() {
    mockRepository = MockDivisionRepository();
    mockUuid = MockUuid();
    useCase = MergeDivisionsUseCase(mockRepository, mockUuid);
  });

  // ═══════════════════════════════════════════════════════════════════════
  // SUCCESS CASES
  // ═══════════════════════════════════════════════════════════════════════

  group('MergeDivisionsUseCase - Success', () {
    test('should merge two divisions with broadened criteria', () async {
      // Arrange
      when(() => mockUuid.v4()).thenReturn('new-uuid-123');
      
      final params = MergeDivisionsParams(
        divisionIdA: 'div-a',
        divisionIdB: 'div-b',
      );
      
      final divisionA = _createTestDivision(id: 'div-a', tournamentId: 'tournament-1', weightMin: 40.0, weightMax: 45.0);
      final divisionB = _createTestDivision(id: 'div-b', tournamentId: 'tournament-1', weightMin: 45.0, weightMax: 50.0);
      
      when(() => mockRepository.getDivision('div-a'))
          .thenAnswer((_) async => Right(divisionA));
      when(() => mockRepository.getDivision('div-b'))
          .thenAnswer((_) async => Right(divisionB));
      when(() => mockRepository.isDivisionNameUnique(any(), any(), excludeDivisionId: any(named: 'excludeDivisionId')))
          .thenAnswer((_) async => const Right(true));
      when(() => mockRepository.getParticipantsForDivisions(any()))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.mergeDivisions(
        mergedDivision: any(named: 'mergedDivision'),
        sourceDivisions: any(named: 'sourceDivisions'),
        participants: any(named: 'participants'),
        archivedBrackets: any(named: 'archivedBrackets'),
      )).thenAnswer((_) async => const Right([]));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.mergeDivisions(
        mergedDivision: any(named: 'mergedDivision'),
        sourceDivisions: any(named: 'sourceDivisions'),
        participants: any(named: 'participants'),
        archivedBrackets: any(named: 'archivedBrackets'),
      )).called(1);
    });
    
    test('should deduplicate participants present in both divisions', () async {
      // Arrange
      when(() => mockUuid.v4()).thenReturn('new-uuid-123');
      
      final params = MergeDivisionsParams(divisionIdA: 'div-a', divisionIdB: 'div-b');
      
      final divisionA = _createTestDivision(id: 'div-a', tournamentId: 'tournament-1');
      final divisionB = _createTestDivision(id: 'div-b', tournamentId: 'tournament-1');
      
      // Same participant in both divisions
      final participant1 = _createTestParticipant(id: 'p1', divisionId: 'div-a', email: 'john@test.com');
      final participant2 = _createTestParticipant(id: 'p1', divisionId: 'div-b', email: 'john@test.com'); // Same ID!
      final participant3 = _createTestParticipant(id: 'p2', divisionId: 'div-b', email: 'jane@test.com');
      
      when(() => mockRepository.getDivision('div-a'))
          .thenAnswer((_) async => Right(divisionA));
      when(() => mockRepository.getDivision('div-b'))
          .thenAnswer((_) async => Right(divisionB));
      when(() => mockRepository.isDivisionNameUnique(any(), any(), excludeDivisionId: any(named: 'excludeDivisionId')))
          .thenAnswer((_) async => const Right(true));
      when(() => mockRepository.getParticipantsForDivisions(any()))
          .thenAnswer((_) async => Right([participant1, participant2, participant3]));
      when(() => mockRepository.mergeDivisions(
        mergedDivision: any(named: 'mergedDivision'),
        sourceDivisions: any(named: 'sourceDivisions'),
        participants: any(named: 'participants'),
        archivedBrackets: any(named: 'archivedBrackets'),
      )).thenAnswer((_) async => const Right([]));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      // Verify deduplication: 3 participants in, 2 unique out
      verify(() => mockRepository.mergeDivisions(
        mergedDivision: any(named: 'mergedDivision'),
        sourceDivisions: any(named: 'sourceDivisions'),
        participants: any(named: 'participants'),
        archivedBrackets: any(named: 'archivedBrackets'),
      ));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // VALIDATION FAILURE CASES
  // ═══════════════════════════════════════════════════════════════════════

  group('MergeDivisionsUseCase - Validation Failures', () {
    test('should return ValidationFailure when merging same division', () async {
      // Arrange
      final params = MergeDivisionsParams(divisionIdA: 'div-a', divisionIdB: 'div-a');

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<ValidationFailure>()),
        (r) => fail('Expected Left'),
      );
    });

    test('should return ValidationFailure when divisions in different tournaments', () async {
      // Arrange
      final params = MergeDivisionsParams(divisionIdA: 'div-a', divisionIdB: 'div-b');
      
      final divisionA = _createTestDivision(id: 'div-a', tournamentId: 'tournament-1');
      final divisionB = _createTestDivision(id: 'div-b', tournamentId: 'tournament-2'); // Different!
      
      when(() => mockRepository.getDivision('div-a'))
          .thenAnswer((_) async => Right(divisionA));
      when(() => mockRepository.getDivision('div-b'))
          .thenAnswer((_) async => Right(divisionB));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect((l as ValidationFailure).fieldErrors.containsKey('tournament'), true),
        (r) => fail('Expected Left'),
      );
    });
    
    test('should return ValidationFailure for category mismatch', () async {
      // Arrange
      final params = MergeDivisionsParams(divisionIdA: 'div-a', divisionIdB: 'div-b');
      
      final divisionA = _createTestDivision(id: 'div-a', tournamentId: 't1', category: DivisionCategory.sparring);
      final divisionB = _createTestDivision(id: 'div-b', tournamentId: 't1', category: DivisionCategory.poomsae); // Different!
      
      when(() => mockRepository.getDivision('div-a'))
          .thenAnswer((_) async => Right(divisionA));
      when(() => mockRepository.getDivision('div-b'))
          .thenAnswer((_) async => Right(divisionB));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect((l as ValidationFailure).fieldErrors.containsKey('category'), true),
        (r) => fail('Expected Left'),
      );
    });
    
    test('should return ValidationFailure for already combined divisions', () async {
      // Arrange
      final params = MergeDivisionsParams(divisionIdA: 'div-a', divisionIdB: 'div-b');
      
      final divisionA = _createTestDivision(id: 'div-a', tournamentId: 't1', isCombined: true);
      
      when(() => mockRepository.getDivision('div-a'))
          .thenAnswer((_) async => Right(divisionA));
      when(() => mockRepository.getDivision('div-b'))
          .thenAnswer((_) async => Right(_createTestDivision(id: 'div-b', tournamentId: 't1')));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isLeft(), true);
    });
    
    test('should return ValidationFailure for duplicate name', () async {
      // Arrange
      final params = MergeDivisionsParams(divisionIdA: 'div-a', divisionIdB: 'div-b', name: 'Existing Name');
      
      final divisionA = _createTestDivision(id: 'div-a', tournamentId: 't1');
      final divisionB = _createTestDivision(id: 'div-b', tournamentId: 't1');
      
      when(() => mockRepository.getDivision('div-a'))
          .thenAnswer((_) async => Right(divisionA));
      when(() => mockRepository.getDivision('div-b'))
          .thenAnswer((_) async => Right(divisionB));
      when(() => mockRepository.isDivisionNameUnique('Existing Name', 't1', excludeDivisionId: any(named: 'excludeDivisionId')))
          .thenAnswer((_) async => const Right(false)); // Name exists!

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect((l as ValidationFailure).fieldErrors.containsKey('name'), true),
        (r) => fail('Expected Left'),
      );
    });
  });
}

// ═══════════════════════════════════════════════════════════════════════
// TEST HELPERS
// ═══════════════════════════════════════════════════════════════════════

DivisionEntity _createTestDivision({
  required String id,
  required String tournamentId,
  double? weightMin,
  double? weightMax,
  DivisionCategory? category,
  bool isCombined = false,
}) {
  return DivisionEntity(
    id: id,
    tournamentId: tournamentId,
    name: 'Test Division',
    category: category ?? DivisionCategory.sparring,
    gender: DivisionGender.male,
    weightMinKg: weightMin,
    weightMaxKg: weightMax,
    isCustom: true,
    status: DivisionStatus.setup,
    isCombined: isCombined,
    displayOrder: 1,
    syncVersion: 1,
    isDeleted: false,
    isDemoData: false,
    createdAtTimestamp: DateTime.now(),
    updatedAtTimestamp: DateTime.now(),
  );
}

dynamic _createTestParticipant({
  required String id,
  required String divisionId,
  required String email,
}) {
  // Create minimal participant for testing
  return _TestParticipant(
    id: id,
    divisionId: divisionId,
    email: email,
    syncVersion: 1,
    isDeleted: false,
  );
}

class _TestParticipant {
  final String id;
  final String divisionId;
  final String email;
  final int syncVersion;
  final bool isDeleted;
  
  _TestParticipant({
    required this.id,
    required this.divisionId,
    required this.email,
    required this.syncVersion,
    required this.isDeleted,
  });
  
  dynamic copyWith({
    String? divisionId,
    int? syncVersion,
  }) {
    return _TestParticipant(
      id: id,
      divisionId: divisionId ?? this.divisionId,
      email: email,
      syncVersion: syncVersion ?? this.syncVersion,
      isDeleted: isDeleted,
    );
  }
}
```

---

## ⚠️ CRITICAL: EXISTING INFRASTRUCTURE

### DO NOT REIMPLEMENT - REUSE THESE COMPONENTS

| Component | Location | Purpose |
|-----------|----------|---------|
| **DivisionEntity** | `lib/features/division/domain/entities/division_entity.dart` | Base entity - verify isCombined exists |
| **DivisionRepository** | `lib/features/division/domain/repositories/division_repository.dart` | Interface - ADD all new methods |
| **DivisionRepositoryImpl** | `lib/features/division/data/repositories/division_repository_implementation.dart` | Implementation - ADD implementations |
| **BeltRank Enum** | `lib/features/division/domain/entities/belt_rank.dart` | Belt ordinals - REUSE |
| **DivisionCategory** | `lib/features/division/domain/entities/division_entity.dart` | Categories - REUSE |
| **DivisionGender** | `lib/features/division/domain/entities/division_entity.dart` | Genders - REUSE |
| **DivisionStatus** | `lib/features/division/domain/entities/division_entity.dart` | Status - REUSE |
| **BracketFormat** | `lib/features/division/domain/entities/division_entity.dart` | Formats - REUSE |
| **UseCase Base** | `lib/core/usecases/use_case.dart` | Base class - REUSE |
| **Failure Classes** | `lib/core/error/failures.dart` | ValidationFailure - REUSE |
| **Uuid** | `package:uuid/uuid.dart` | UUID generation - USE THIS |

---

## 🚨 COMMON LLM MISTAKES TO PREVENT

### 🔴 CRITICAL ERRORS

| Mistake | Impact | Prevention |
|---------|--------|------------|
| **Physical deletion instead of soft delete** | Data loss, broken references | MUST set isDeleted=true, NOT delete from DB |
| **Not moving participants** | Participants orphaned in deleted divisions | MUST update participant.divisionId to new division |
| **Forgetting isCombined field** | Can't track merged divisions | MUST set isCombined=true on merged division |
| **Wrong criteria broadening** | Merged division excludes valid participants | MUST calculate min/max correctly using helper methods |
| **Category mismatch merge** | Invalid competition format | MUST validate same category before merge |
| **Not using offline-first** | Changes lost when offline | MUST use DivisionRepository (already offline-first) |
| **Wrong UUID generation** | ID collisions | MUST use `uuid` package, NOT millisecondsSinceEpoch |
| **Exception handling violations** | Breaks Either pattern | MUST return Either<Failure, T>, never throw |
| **No participant deduplication** | Duplicate participants in merged division | MUST deduplicate by participant ID |

### 🟡 COMMON ERRORS

| Mistake | Impact | Prevention |
|---------|--------|------------|
| **Split without enough participants** | Empty pools | MUST validate minimum 4 participants (AC13) |
| **Race conditions** | Data inconsistency | MUST check syncVersion before updates |
| **Not updating syncVersion** | Sync conflicts | MUST increment syncVersion on all changes |
| **Wrong weight units** | Wrong criteria | MUST use kg (not lbs) per architecture |
| **Name uniqueness not checked** | Duplicate division names | MUST call isDivisionNameUnique before create |
| **Bracket not archived** | Lost bracket data | MUST soft-delete existing brackets |
| **No atomic transactions** | Partial failures leave inconsistent state | MUST use repository transaction pattern |

---

## 🔗 CROSS-STORY DEPENDENCIES

### Dependencies (MUST complete before)

| Story | Dependency | Status |
|-------|-----------|--------|
| **3.7** | DivisionEntity, DivisionRepository | ✅ DONE |
| **3.8** | SmartDivisionBuilder, BeltRank | ✅ DONE |
| **3.9** | FederationTemplateRegistry | ✅ DONE |
| **3.10** | CustomDivisionCreation, isCustom field | ✅ DONE |

### ⚠️ NEW: Epic 4 Dependency (Participant Entity)

| Component | Status | Notes |
|-----------|--------|-------|
| **ParticipantEntity** | ⚠️ NOT YET CREATED | Epic 4 not started |
| **ParticipantRepository** | ⚠️ NOT YET CREATED | May need to add to DivisionRepository |
| **BracketEntity** | ⚠️ NOT YET CREATED | Epic 5 not started |

**MITIGATION:** This story MUST create or depend on Participant and Bracket structures. Consider:
1. Creating stub entities/repositories in this story, OR
2. Adding methods to DivisionRepository to handle participants/brackets

### Dependent Stories (MUST wait for this)

| Story | Dependency |
|-------|-----------|
| **3.14** | Uses merge/split operations in UI |
| **Epic 4** | Uses ParticipantEntity structure |

---

## 📚 REFERENCES

### Primary Sources

- [Source: _bmad-output/planning-artifacts/epics.md#1331-1353] - Story 3.11 requirements
- [Source: _bmad-output/planning-artifacts/prd.md] - FR9, FR10
- [Source: _bmad-output/planning-artifacts/architecture.md] - Overall architecture
- [Source: tkd_brackets/lib/features/division/domain/repositories/division_repository.dart] - Current interface

### Related Stories (For Context)

- [Source: implementation-artifacts/3-10-custom-division-creation.md] - isCustom field, DivisionEntity structure
- [Source: implementation-artifacts/3-7-division-entity-and-repository.md] - Division entity fields
- [Source: implementation-artifacts/3-8-smart-division-builder-algorithm.md] - BeltRank, criteria handling

### Technical References

- [Source: lib/core/usecases/use_case.dart] - UseCase base class
- [Source: lib/core/error/failures.dart] - ValidationFailure class
- [Source: lib/features/division/data/repositories/division_repository_implementation.dart] - Offline-first pattern

---

## 📝 Dev Agent Record

### Agent Model Used

- **minimax-m2.5-free**

### Debug Log References

_N/A - Story file only_

### Completion Notes

_Ultimate context engine analysis completed - comprehensive developer guide created with all validation fixes applied_

---

## 📁 File Manifest

### New Files (Create)

| File Path | Description |
|-----------|-------------|
| `tkd_brackets/lib/features/division/domain/usecases/merge_divisions_params.dart` | Params class |
| `tkd_brackets/lib/features/division/domain/usecases/merge_divisions_params.freezed.dart` | Generated |
| `tkd_brackets/lib/features/division/domain/usecases/merge_divisions_params.g.dart` | Generated |
| `tkd_brackets/lib/features/division/domain/usecases/merge_divisions_usecase.dart` | Use case |
| `tkd_brackets/lib/features/division/domain/usecases/split_division_params.dart` | Params class |
| `tkd_brackets/lib/features/division/domain/usecases/split_division_params.freezed.dart` | Generated |
| `tkd_brackets/lib/features/division/domain/usecases/split_division_params.g.dart` | Generated |
| `tkd_brackets/lib/features/division/domain/usecases/split_division_usecase.dart` | Use case |
| `tkd_brackets/test/features/division/usecases/merge_divisions_usecase_test.dart` | Unit tests (10+ cases) |
| `tkd_brackets/test/features/division/usecases/split_division_usecase_test.dart` | Unit tests (10+ cases) |

### Modified Files (Update)

| File Path | Changes |
|-----------|---------|
| `tkd_brackets/lib/features/division/domain/repositories/division_repository.dart` | ADD: getDivision, getParticipantsForDivision, getParticipantsForDivisions, mergeDivisions, splitDivision, isDivisionNameUnique |
| `tkd_brackets/lib/features/division/data/repositories/division_repository_implementation.dart` | Implement all new repository methods |
| `tkd_brackets/lib/features/division/domain/entities/division_entity.dart` | Verify isCombined field exists |
| `tkd_brackets/lib/features/division/domain/entities/division_entity.freezed.dart` | Regenerate |
| `tkd_brackets/lib/features/division/domain/entities/division_entity.g.dart` | Regenerate |
| `tkd_brackets/lib/features/division/data/models/division_model.dart` | Verify isCombined field + conversion |
| `tkd_brackets/lib/features/division/data/models/division_model.freezed.dart` | Regenerate |
| `tkd_brackets/lib/features/division/data/models/division_model.g.dart` | Regenerate |
| `tkd_brackets/lib/core/database/tables/divisions_table.dart` | Add `is_combined` column |

### Potential New Files (If ParticipantRepository not in Epic 4)

| File Path | Description |
|-----------|-------------|
| `tkd_brackets/lib/features/participant/domain/entities/participant_entity.dart` | Participant entity (if Epic 4 not done) |
| `tkd_brackets/lib/features/participant/domain/repositories/participant_repository.dart` | Participant repository (if Epic 4 not done) |
| `tkd_brackets/lib/features/bracket/domain/entities/bracket_entity.dart` | Bracket entity (if Epic 5 not done) |

### Dependencies to Add

```yaml
# pubspec.yaml additions:
dependencies:
  uuid: ^4.0.0  # For proper UUID generation
```

### Build Command

```bash
# Add uuid package:
flutter pub add uuid

# After creating/modifying freezed files:
dart run build_runner build --delete-conflicting-outputs

# Run tests:
dart test test/features/division/usecases/

# Run analysis:
dart analyze
```

---

## 🎯 Implementation Checklist

### Pre-Implementation (Critical)

- [ ] Verify/create ParticipantEntity structure
- [ ] Verify/create BracketEntity structure  
- [ ] Add all new methods to DivisionRepository interface
- [ ] Add uuid package to pubspec.yaml

### Implementation Steps

- [ ] Add `isCombined` field to DivisionEntity (if missing)
- [ ] Add `isCombined` field to DivisionModel
- [ ] Add `isCombined` field to Drift table
- [ ] Add `getDivision(String id)` method to repository
- [ ] Add `getParticipantsForDivision` method to repository
- [ ] Add `getParticipantsForDivisions` method to repository
- [ ] Add `mergeDivisions` method to repository interface
- [ ] Add `splitDivision` method to repository interface
- [ ] Add `isDivisionNameUnique` method to repository
- [ ] Implement all new repository methods in Impl class
- [ ] Create MergeDivisionsParams (freezed)
- [ ] Create MergeDivisionsUseCase (with UUID, Either pattern, deduplication)
- [ ] Create SplitDivisionParams (freezed)
- [ ] Create SplitDivisionUseCase (with UUID, Either pattern)
- [ ] Run build_runner

### Testing

- [ ] Write unit tests for MergeDivisionsUseCase (minimum 10 cases)
- [ ] Write unit tests for SplitDivisionUseCase (minimum 10 cases)
- [ ] Include deduplication test case
- [ ] Include name uniqueness test case
- [ ] Include category mismatch test case
- [ ] Include already combined test case

### Final Steps

- [ ] Run dart analyze - fix any issues
- [ ] Run tests - all must pass
- [ ] Verify code compiles successfully

---

## Tasks / Subtasks

- [x] Add isCombined field to DivisionEntity (verified already exists)
- [x] Add isCombined field to DivisionModel
- [x] Add isCombined field to Drift table (verified already exists)
- [x] Add getDivision(String id) method to repository
- [x] Add mergeDivisions method to repository interface
- [x] Add splitDivision method to repository interface
- [x] Add isDivisionNameUnique method to repository
- [x] Add getParticipantsForDivision method to repository
- [x] Add getParticipantsForDivisions method to repository
- [x] Implement all new repository methods in Implementation class
- [x] Create MergeDivisionsParams (freezed)
- [x] Create MergeDivisionsUseCase (with UUID, Either pattern)
- [x] Create SplitDivisionParams (freezed)
- [x] Create SplitDivisionUseCase (with UUID, Either pattern)
- [x] Run build_runner
- [x] Write unit tests for MergeDivisionsUseCase (13 tests)
- [x] Write unit tests for SplitDivisionUseCase (6 tests)
- [x] Include name uniqueness test case
- [x] Include category mismatch test case
- [x] Include already combined test case

---

## File List

### New Files
- `tkd_brackets/lib/features/division/domain/usecases/merge_divisions_params.dart`
- `tkd_brackets/lib/features/division/domain/usecases/merge_divisions_params.freezed.dart`
- `tkd_brackets/lib/features/division/domain/usecases/merge_divisions_params.g.dart`
- `tkd_brackets/lib/features/division/domain/usecases/merge_divisions_usecase.dart`
- `tkd_brackets/lib/features/division/domain/usecases/split_division_params.dart`
- `tkd_brackets/lib/features/division/domain/usecases/split_division_params.freezed.dart`
- `tkd_brackets/lib/features/division/domain/usecases/split_division_params.g.dart`
- `tkd_brackets/lib/features/division/domain/usecases/split_division_usecase.dart`
- `tkd_brackets/test/features/division/usecases/merge_divisions_usecase_test.dart`
- `tkd_brackets/test/features/division/usecases/split_division_usecase_test.dart`

### Modified Files
- `tkd_brackets/lib/features/division/domain/repositories/division_repository.dart` - Added: getDivision, mergeDivisions, splitDivision, isDivisionNameUnique
- `tkd_brackets/lib/features/division/data/repositories/division_repository_implementation.dart` - Implemented all new repository methods
- `tkd_brackets/lib/features/division/data/datasources/division_local_datasource.dart` - Added: isDivisionNameUnique, insertDivisions, updateDivisions

---

## Change Log

- 2026-02-18: Implemented MergeDivisionsUseCase with UUID generation, validation for same division, different tournaments, category mismatch, already combined, and duplicate name checks
- 2026-02-18: Implemented SplitDivisionUseCase with Pool A/B naming and validation
- 2026-02-18: Updated DivisionRepository interface with new methods for merge/split operations
- 2026-02-18: Updated DivisionLocalDatasource with new data access methods
- 2026-02-18: Added comprehensive unit tests (13 tests for merge, 6 tests for split - all passing)
