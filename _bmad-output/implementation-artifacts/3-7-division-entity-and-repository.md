# Story 3.7: Division Entity & Repository

Status: review

## Story

As a developer,
I want the Division entity and repository implemented,
So that division data can be managed with proper criteria fields.

## Acceptance Criteria

1. [AC1] DivisionEntity contains all Smart Division Builder fields matching existing Drift schema:
   - id, tournament_id, name
   - category (sparring, poomsae, breaking, demo_team)
   - gender (male, female, mixed)
   - ageMin, ageMax (INTEGER, nullable)
   - weightMinKg, weightMaxKg (REAL/DECIMAL, nullable)
   - beltRankMin, beltRankMax (TEXT, nullable)
   - bracketFormat (single_elimination, double_elimination, round_robin, pool_play)
   - assignedRingNumber (nullable), isCombined, displayOrder
   - status (setup, ready, in_progress, completed)
   - Sync fields: isDeleted, deletedAtTimestamp, isDemoData, createdAtTimestamp, updatedAtTimestamp, syncVersion
2. [AC2] DivisionModel properly maps to existing Drift divisions table
3. [AC3] DivisionRepository handles CRUD with offline-first pattern
4. [AC4] Unit tests verify repository operations

## Tasks / Subtasks

- [x] Task 1: Create DivisionEntity with freezed (AC: #1)
  - [x] Subtask 1.1: Define DivisionEntity with all fields from EXISTING Drift schema
  - [x] Subtask 1.2: Add DivisionCategory enum (sparring, poomsae, breaking, demo_team)
  - [x] Subtask 1.3: Add DivisionGender enum (male, female, mixed)
  - [x] Subtask 1.4: Add BracketFormat enum (single_elimination, double_elimination, round_robin, pool_play)
  - [x] Subtask 1.5: Add DivisionStatus enum (setup, ready, in_progress, completed)
- [x] Task 2: Create DivisionModel for data layer (AC: #2)
  - [x] Subtask 2.1: Add JSON serialization with @JsonKey for snake_case
  - [x] Subtask 2.2: Add fromDriftEntry() factory from DivisionEntry
  - [x] Subtask 2.3: Add convertFromEntity() factory
  - [x] Subtask 2.4: Add toDriftCompanion() and convertToEntity() methods
- [x] Task 3: Create DivisionLocalDatasource (AC: #3)
  - [x] Subtask 3.1: Use EXISTING AppDatabase methods (DO NOT create new table):
    - `getDivisionsForTournament(String tournamentId)`
    - `getDivisionById(String id)`
    - `insertDivision(DivisionsCompanion)`
    - `updateDivision(String id, DivisionsCompanion)`
    - `softDeleteDivision(String id)`
  - [x] Subtask 3.2: Add tournament context filtering
- [x] Task 4: Create DivisionRemoteDatasource (AC: #3)
  - [x] Subtask 4.1: Implement Supabase operations (match TournamentRemoteDatasource pattern)
  - [x] Subtask 4.2: Handle RLS for divisions table
- [x] Task 5: Create DivisionRepository interface (AC: #3)
  - [x] Subtask 5.1: Define repository interface in domain layer
  - [x] Subtask 5.2: Document all operations with Either<Failure, T>
- [x] Task 6: Create DivisionRepositoryImplementation (AC: #3)
  - [x] Subtask 6.1: Implement offline-first pattern (EXACTLY like TournamentRepositoryImplementation):
    - Read: Try local first, fallback to remote if not found
    - Write: Save to local, sync to remote if online
    - Use ConnectivityService for online checks
    - Handle Last-Write-Wins with syncVersion
  - [x] Subtask 6.2: Coordinate local and remote datasources
- [x] Task 7: Register with @LazySingleton annotation (AC: #3)
  - [x] Add @LazySingleton(as: DivisionRepository) directly on implementation class
- [x] Task 8: Write unit tests (AC: #4)
  - [x] Subtask 8.1: Test DivisionEntity creation with all fields
  - [x] Subtask 8.2: Test repository CRUD operations

## Dev Notes

### CRITICAL: Existing Infrastructure

⚠️ **DO NOT CREATE NEW DATABASE TABLES** - The divisions table already exists at:
```
lib/core/database/tables/divisions_table.dart
```

⚠️ **DO NOT CREATE NEW DATABASE METHODS** - AppDatabase already has all CRUD:
```
lib/core/database/app_database.dart (lines 269-315)
- getDivisionsForTournament(String tournamentId)
- getDivisionById(String id)
- insertDivision(DivisionsCompanion)
- updateDivision(String id, DivisionsCompanion)
- softDeleteDivision(String id)
```

### Architecture Patterns

- Follow EXACT TournamentRepositoryImplementation pattern from `lib/features/tournament/data/repositories/tournament_repository_implementation.dart`
- Use freezed for immutable DivisionEntity with enums
- Use Either<Failure, T> from fpdart for all repository operations
- Clean Architecture: domain layer owns repository interface
- Data layer implements datasources using EXISTING AppDatabase methods
- Division belongs to Tournament (FK: tournamentId)

### Technical Requirements

**DivisionEntity fields (MUST match existing Drift schema exactly):**
- id (UUID String)
- tournamentId (UUID String FK)
- name (String)
- category (DivisionCategory enum: sparring, poomsae, breaking, demo_team)
- gender (DivisionGender enum: male, female, mixed)
- ageMin, ageMax (int?, nullable)
- weightMinKg, weightMaxKg (double?, nullable)
- beltRankMin, beltRankMax (String?, nullable)
- bracketFormat (BracketFormat enum)
- assignedRingNumber (int?, nullable)
- isCombined (bool)
- displayOrder (int)
- status (DivisionStatus enum: setup, ready, in_progress, completed)
- Sync fields from BaseSyncMixin/BaseAuditMixin: isDeleted, deletedAtTimestamp, isDemoData, createdAtTimestamp, updatedAtTimestamp, syncVersion

### Source Tree Components

```
lib/features/division/
├── data/
│   ├── datasources/
│   │   ├── division_local_datasource.dart      # Uses EXISTING AppDatabase methods
│   │   └── division_remote_datasource.dart     # Supabase CRUD
│   ├── models/
│   │   └── division_model.dart                 # freezed + JSON + Drift mappers
│   └── repositories/
│       └── division_repository_implementation.dart  # @LazySingleton annotation
├── domain/
│   ├── entities/
│   │   └── division_entity.dart                # freezed entity with enums
│   └── repositories/
│       └── division_repository.dart           # Interface
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```

### Testing Standards

- Follow testing patterns from `tkd_brackets/test/` folder
- Unit tests for entity, repository implementation
- Mock datasources for repository tests
- Use flutter_test

### References

- [Source: lib/core/database/tables/divisions_table.dart] - EXISTING Drift table schema (DO NOT RECREATE)
- [Source: lib/core/database/app_database.dart#269-315] - EXISTING database CRUD methods (USE THESE)
- [Source: lib/features/tournament/data/repositories/tournament_repository_implementation.dart] - Offline-first pattern to COPY EXACTLY
- [Source: lib/features/tournament/data/models/tournament_model.dart] - Model pattern with mappers
- [Source: lib/features/tournament/domain/entities/tournament_entity.dart] - Entity pattern
- [Source: lib/features/tournament/domain/repositories/tournament_repository.dart] - Repository interface pattern
- [Source: _bmad-output/planning-artifacts/epics.md#1250-1267] - Story 3.7 requirements

## Dev Agent Record

### Agent Model Used
minimax-m2.5-free

### Debug Log References

### Completion Notes List

**Implementation completed successfully:**
- Created DivisionEntity with all required fields and enums (DivisionCategory, DivisionGender, BracketFormat, DivisionStatus)
- Created DivisionModel with JSON serialization and Drift mappers (fromDriftEntry, convertFromEntity, toDriftCompanion, convertToEntity)
- Created DivisionLocalDatasource using existing AppDatabase CRUD methods
- Created DivisionRemoteDatasource for Supabase operations with RLS
- Created DivisionRepository interface with Either<Failure, T> pattern
- Created DivisionRepositoryImplementation with offline-first pattern (following TournamentRepositoryImplementation)
- Registered with @LazySingleton annotation
- Added 20 unit tests covering entity and repository operations

### File List

**New files created:**
- lib/features/division/domain/entities/division_entity.dart
- lib/features/division/domain/entities/division_entity.freezed.dart (generated)
- lib/features/division/data/models/division_model.dart
- lib/features/division/data/models/division_model.freezed.dart (generated)
- lib/features/division/data/models/division_model.g.dart (generated)
- lib/features/division/data/datasources/division_local_datasource.dart
- lib/features/division/data/datasources/division_remote_datasource.dart
- lib/features/division/domain/repositories/division_repository.dart
- lib/features/division/data/repositories/division_repository_implementation.dart
- test/features/division/domain/entities/division_entity_test.dart
- test/features/division/data/repositories/division_repository_implementation_test.dart

