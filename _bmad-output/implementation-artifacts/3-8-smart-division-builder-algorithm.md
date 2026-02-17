# Story 3.8: Smart Division Builder Algorithm

Status: done

## Story

As an organizer,
I want the system to auto-generate divisions based on age/belt/weight/gender axes,
So that I can quickly set up proper competition categories (FR6).

## Acceptance Criteria

1. [AC1] **SmartDivisionBuilderUseCase** generates divisions from configuration:
   - Age groups: 6-8, 9-10, 11-12, 13-14, 15-17, 18-32, 33+ (configurable)
   - Belt groups: white-yellow, green-blue, red-black (configurable)
   - Weight classes: federation-specific (WT, ITF, ATA)
   - Gender: male, female, or mixed
2. [AC2] Divisions are named automatically per federation conventions:
   - WT Male: "Cadet -54kg" (no age prefix)
   - WT Female: "Cadet -53kg"
   - ITF: "U21 Male Sparring -80kg"
   - With age prefix: "Cadet (12-14) -45kg Male"
3. [AC3] Empty divisions (no matching participants) are optionally created or skipped via `includeEmptyDivisions` flag and `minimumParticipants` threshold
4. [AC4] Unit tests verify division generation for all axes and federations
5. [AC5] Generated divisions are saved using offline-first pattern (local first, sync to Supabase when online)
6. [AC6] Performance: Division generation completes in <500ms for up to 500 participants

## Tasks / Subtasks

- [x] Task 1: Create SmartDivisionBuilderUseCase following UseCase base class pattern (AC: #1, #5, #6)
  - [x] Subtask 1.1: Create `SmartDivisionBuilderParams` class with all configuration options
  - [x] Subtask 1.2: Extend `UseCase<List<DivisionEntity>, SmartDivisionBuilderParams>` 
  - [x] Subtask 1.3: Implement axis-based division generation algorithm with performance optimization
  - [x] Subtask 1.4: Add federation-specific weight class lookup (WT, ITF, ATA)
  - [x] Subtask 1.5: Register with `@injectable` annotation
- [x] Task 2: Create automatic division naming (AC: #2)
  - [x] Subtask 2.1: Implement `DivisionNamingService` with federation-specific conventions
  - [x] Subtask 2.2: Add belt rank enum and ordering logic
  - [x] Subtask 2.3: Support configurable naming templates (age prefix, gender suffix, etc.)
- [x] Task 3: Add empty division handling (AC: #3)
  - [x] Subtask 3.1: Add `includeEmptyDivisions: bool` parameter to params
  - [x] Subtask 3.2: Add `minimumParticipants: int?` threshold parameter
  - [x] Subtask 3.3: Skip divisions below threshold
- [x] Task 4: Handle Participant Dependency (AC: #1, #5)
  - [x] Subtask 4.1: Query existing participants from ParticipantRepository (when available)
  - [x] Subtask 4.2: Fallback to demo data from Story 1.11 if in demo mode
  - [x] Subtask 4.3: Handle case where no participants exist yet (generate empty divisions)
- [x] Task 5: Write unit tests (AC: #4)
  - [x] Subtask 5.1: Test age group generation
  - [x] Subtask 5.2: Test belt group generation
  - [x] Subtask 5.3: Test WT weight class generation (male and female)
  - [x] Subtask 5.4: Test ITF weight class generation
  - [x] Subtask 5.5: Test ATA custom weight classes
  - [x] Subtask 5.6: Test combined axis generation
  - [x] Subtask 5.7: Test empty division filtering
  - [x] Subtask 5.8: Test performance <500ms

## Dev Notes

### CRITICAL: Existing Infrastructure

**1. Division Entity (EXISTS - Story 3.7):**
```
lib/features/division/domain/entities/division_entity.dart
```
Fields: id, tournamentId, name, category, gender, ageMin, ageMax, weightMinKg, weightMaxKg, beltRankMin, beltRankMax, bracketFormat, status, isCombined, displayOrder, sync fields

**2. Division Repository (EXISTS - Story 3.7):**
```
lib/features/division/domain/repositories/division_repository.dart
lib/features/division/data/repositories/division_repository_implementation.dart
```
- Interface defines CRUD operations returning `Either<Failure, T>`
- Implementation uses offline-first pattern: local first, sync when online
- Use this to persist generated divisions

**3. Tournament Entity (EXISTS - Story 3.2):**
```
lib/features/tournament/domain/entities/tournament_entity.dart
```
FederationType enum: wt, itf, ata, custom (lines 67-84)
TournamentStatus enum: draft, registration_open, registration_closed, in_progress, completed, cancelled (lines 87-106)

**4. UseCase Base Class (EXISTS - Epic 1):**
```
lib/core/usecases/use_case.dart
```
- All use cases MUST extend `UseCase<T, Params>`
- Return `Future<Either<Failure, T>>`
- Use `@injectable` annotation for DI registration

**5. Error Handling Pattern (EXISTS - Epic 1):**
```
lib/core/error/failures.dart
```
- Use Failure subclasses: ServerFailure, CacheFailure, ValidationFailure, etc.
- All repository and use case operations return Either<Failure, T>

### Architecture Patterns

**SMART DIVISION BUILDER MUST FOLLOW:**

1. **Use Case Pattern (MANDATORY):**
```dart
// lib/features/division/domain/usecases/smart_division_builder_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';

@injectable
class SmartDivisionBuilderUseCase extends UseCase<List<DivisionEntity>, SmartDivisionBuilderParams> {
  SmartDivisionBuilderUseCase(this._divisionRepository);
  
  final DivisionRepository _divisionRepository;

  @override
  Future<Either<Failure, List<DivisionEntity>>> call(SmartDivisionBuilderParams params) async {
    // Implementation here
  }
}
```

2. **Offline-First Persistence Pattern (MANDATORY):**
- Read: Try local first, fallback to remote
- Write: Save to local immediately, sync to Supabase when online
- Use ConnectivityService for online checks
- Handle Last-Write-Wins with syncVersion
- Reference: `lib/features/tournament/data/repositories/tournament_repository_implementation.dart`

### Technical Requirements

**1. BeltRank Enum (REQUIRED - Define in division_entity.dart or new file):**
```dart
enum BeltRank {
  white(1), yellow(2), orange(3), green(4), blue(5), red(6), black(7);
  const BeltRank(this.order);
  final int order;
  
  static BeltRank? fromString(String value) {
    return BeltRank.values.firstWhere(
      (b) => b.name == value.toLowerCase(),
      orElse: () => BeltRank.white,
    );
  }
}
```

**2. Federation Weight Classes (REQUIRED - Hardcode in service):**

| Federation | Gender | Weight Classes (kg) |
|------------|--------|---------------------|
| WT | Male | -54, -58, -63, -68, -74, -80, +80 |
| WT | Female | -46, -49, -53, -57, -62, -67, +67 |
| ITF | Male | -54, -58, -62, -67, -72, -77, -82, +82 |
| ITF | Female | -46, -49, -53, -57, -62, -67, +67 |
| ATA | Custom | Per school configuration |

**3. Age Groups (Configurable with Defaults):**
```
- Pediatric: 5-7, 8-9, 10-11
- Youth: 12-13, 14-15
- Cadet: 16-17
- Junior: 18-21
- Senior: 22-34
- Veterans: 35+
```

**4. Division Category Mapping:**
- `category` field from DivisionEntity must be set: sparring, poomsae, breaking, demo_team
- Sparring divisions: apply weight classes
- Poomsae/Breaking: no weight classes needed
- Determine from tournament settings or user selection

**5. Performance Requirements (NFR Compliance):**
- Division generation < 500ms (matching NFR2 from PRD)
- Must handle up to 500 participants efficiently
- Use efficient algorithms, avoid O(n²) where possible

### Source Tree Components

```
lib/features/division/
├── domain/
│   ├── entities/
│   │   ├── division_entity.dart          # EXISTS from 3.7
│   │   └── belt_rank.dart               # NEW - belt enum with ordering
│   ├── repositories/
│   │   └── division_repository.dart      # EXISTS from 3.7
│   └── usecases/
│       ├── smart_division_builder_params.dart    # NEW - params class
│       ├── smart_division_builder_params.freezed.dart  # GENERATED
│       ├── smart_division_builder_usecase.dart   # NEW - main use case
│       └── smart_division_naming_service.dart     # NEW - naming logic
├── data/
│   ├── datasources/
│   │   ├── division_local_datasource.dart   # EXISTS from 3.7
│   │   └── division_remote_datasource.dart # EXISTS from 3.7
│   └── repositories/
│       └── division_repository_implementation.dart  # EXISTS from 3.7
```

### Testing Standards

- Follow patterns from `tkd_brackets/test/` folder
- Unit tests for SmartDivisionBuilderUseCase
- Test all axis combinations
- Test federation-specific weight class variations
- Test empty division filtering
- Mock DivisionRepository for persistence tests
- **PERFORMANCE TEST**: Verify generation < 500ms with 500 participants

### Project Structure Notes

- **MUST** follow Clean Architecture: domain layer owns business logic
- **MUST** use UseCase base class pattern (see CreateTournamentUseCase as reference)
- **MUST** use Either<Failure, T> from fpdart for all return types
- **MUST** register with @injectable for DI
- **MUST** use offline-first persistence via DivisionRepository

### References

- [Source: _bmad-output/planning-artifacts/epics.md#1269-1286] - Story 3.8 requirements
- [Source: lib/features/division/domain/entities/division_entity.dart] - Existing entity (Story 3.7)
- [Source: lib/features/division/domain/repositories/division_repository.dart] - Existing repo (Story 3.7)
- [Source: lib/features/tournament/domain/entities/tournament_entity.dart#67-84] - FederationType enum
- [Source: lib/core/usecases/use_case.dart] - UseCase base class pattern
- [Source: lib/features/tournament/domain/usecases/create_tournament_usecase.dart] - UseCase implementation example
- [Source: lib/features/tournament/data/repositories/tournament_repository_implementation.dart] - Offline-first pattern reference
- [Source: _bmad-output/planning-artifacts/prd.md] - FR6 Smart Division Builder
- [Source: _bmad-output/planning-artifacts/architecture.md#NFR2] - Performance NFR: bracket generation < 500ms

## Dev Agent Record

### Agent Model Used
- minimax-m2.5-free

### Debug Log References

### Completion Notes List

**Implementation completed on 2026-02-17**

**Summary:**
- Created SmartDivisionBuilderUseCase with configurable parameters for age groups, belt groups, and weight classes
- Implemented DivisionNamingService supporting WT, ITF, and ATA federation-specific naming conventions
- Added performance optimization with 500ms threshold checking
- Created comprehensive unit tests covering all acceptance criteria
- All 35 division-related tests pass

**Key Implementation Details:**
- Uses freezed for immutable params class with proper copyWith support
- Follows Clean Architecture with domain layer business logic
- Offline-first persistence via DivisionRepository
- Supports all federation types: WT, ITF, ATA, and custom
- Multiple naming conventions: federationDefault, withAgePrefix, withoutAgePrefix, short

### File List

**New Files:**
- `tkd_brackets/lib/features/division/domain/entities/belt_rank.dart`
- `tkd_brackets/lib/features/division/domain/usecases/smart_division_builder_params.dart`
- `tkd_brackets/lib/features/division/domain/usecases/smart_division_builder_params.freezed.dart` (auto-generated)
- `tkd_brackets/lib/features/division/domain/usecases/smart_division_builder_usecase.dart`
- `tkd_brackets/lib/features/division/domain/usecases/smart_division_naming_service.dart`
- `tkd_brackets/test/features/division/domain/usecases/smart_division_builder_usecase_test.dart`

**Modified Files:**
- (none - all new implementations)

**Change Log**

- 2026-02-17: Initial implementation of Smart Division Builder Algorithm - Story 3.8 complete