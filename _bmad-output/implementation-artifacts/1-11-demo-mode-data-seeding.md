# Story 1.11: Demo Mode Data Seeding

Status: ready-for-dev

## Story

**As a** potential customer,
**I want** sample TKD tournament data seeded when I first use the app,
**so that** I can explore features without entering my own data.

## Acceptance Criteria

1. **AC1:** Demo data is seeded on first app launch when no existing data is detected:
   - 1 demo user (owner role)
   - 1 sample organization ("Demo Dojang")
   - 1 sample tournament ("Spring Championship 2026")
   - 1 sample division ("Cadets -45kg Male")
   - 8 sample participants with varied dojangs

2. **AC2:** All demo data has `isDemoData = true` flag set

3. **AC3:** Demo data uses predetermined UUIDs for test reproducibility

4. **AC4:** A `DemoDataService` exists at `lib/core/demo/demo_data_service.dart` with:
   - `Future<bool> shouldSeedDemoData()` - checks if first launch (no data)
   - `Future<void> seedDemoData()` - seeds all demo data
   - `Future<bool> hasDemoData()` - checks if demo data exists

5. **AC5:** Demo data seeding is triggered during app bootstrap (inside Sentry appRunner, before UI loads)

6. **AC6:** Unit tests verify seeding creates expected records and is idempotent

## Tasks / Subtasks

- [ ] Task 1: Create Tournaments table (AC: #1)
  - [ ] 1.1 Create `lib/core/database/tables/tournaments_table.dart` with schema matching architecture:
    - `id` (TEXT PRIMARY KEY)
    - `organizationId` (TEXT FK → organizations, `.named('organization_id')`)
    - `createdByUserId` (TEXT FK → users, nullable, `.named('created_by_user_id')`)
    - `name` (TEXT NOT NULL, max 255)
    - `description` (TEXT nullable)
    - `venueName` (TEXT nullable, `.named('venue_name')`)
    - `venueAddress` (TEXT nullable, `.named('venue_address')`)
    - `scheduledDate` (DateTime NOT NULL, `.named('scheduled_date')`)
    - `scheduledStartTime` (DateTime nullable, `.named('scheduled_start_time')`)
    - `scheduledEndTime` (DateTime nullable, `.named('scheduled_end_time')`)
    - `federationType` (TEXT DEFAULT 'wt', `.named('federation_type')`)
      - CHECK: 'wt', 'itf', 'ata', 'custom'
    - `status` (TEXT DEFAULT 'draft')
      - CHECK: 'draft', 'registration_open', 'registration_closed', 'in_progress', 'completed', 'cancelled'
    - `isTemplate` (BOOLEAN DEFAULT false, `.named('is_template')`)
    - `templateId` (TEXT nullable FK → tournaments, `.named('template_id')`)
    - `numberOfRings` (INTEGER DEFAULT 1, `.named('number_of_rings')`)
    - `settingsJson` (TEXT DEFAULT '{}', `.named('settings_json')`)
    - Include `BaseSyncMixin` and `BaseAuditMixin`
  - [ ] 1.2 Add annotation: `@DataClassName('TournamentEntry')`
  - [ ] 1.3 Add `Tournaments` to `tables.dart` barrel file
  - [ ] 1.4 Register table in `AppDatabase` @DriftDatabase annotation
  - [ ] 1.5 Add basic CRUD methods to `AppDatabase` for tournaments

- [ ] Task 2: Create Divisions table (AC: #1)
  - [ ] 2.1 Create `lib/core/database/tables/divisions_table.dart` with schema:
    - `id` (TEXT PRIMARY KEY)
    - `tournamentId` (TEXT FK → tournaments, `.named('tournament_id')`)
    - `name` (TEXT NOT NULL)
    - `category` (TEXT NOT NULL DEFAULT 'sparring')
      - CHECK: 'sparring', 'poomsae', 'breaking', 'demo_team'
    - `gender` (TEXT NOT NULL, CHECK: 'male', 'female', 'mixed')
    - `ageMin` (INTEGER nullable, `.named('age_min')`)
    - `ageMax` (INTEGER nullable, `.named('age_max')`)
    - `weightMinKg` (REAL nullable, `.named('weight_min_kg')`)
    - `weightMaxKg` (REAL nullable, `.named('weight_max_kg')`)
    - `beltRankMin` (TEXT nullable, `.named('belt_rank_min')`)
    - `beltRankMax` (TEXT nullable, `.named('belt_rank_max')`)
    - `bracketFormat` (TEXT DEFAULT 'single_elimination', `.named('bracket_format')`)
      - CHECK: 'single_elimination', 'double_elimination', 'round_robin', 'pool_play'
    - `assignedRingNumber` (INTEGER nullable, `.named('assigned_ring_number')`)
    - `isCombined` (BOOLEAN DEFAULT false, `.named('is_combined')`)
    - `displayOrder` (INTEGER DEFAULT 0, `.named('display_order')`)
    - `status` (TEXT DEFAULT 'setup')
      - CHECK: 'setup', 'ready', 'in_progress', 'completed'
    - Include `BaseSyncMixin` and `BaseAuditMixin`
  - [ ] 2.2 Add annotation: `@DataClassName('DivisionEntry')`
  - [ ] 2.3 Add `Divisions` to `tables.dart` barrel file
  - [ ] 2.4 Register table in `AppDatabase` @DriftDatabase annotation
  - [ ] 2.5 Add basic CRUD methods to `AppDatabase` for divisions

- [ ] Task 3: Create Participants table (AC: #1)
  - [ ] 3.1 Create `lib/core/database/tables/participants_table.dart` with schema:
    - `id` (TEXT PRIMARY KEY)
    - `divisionId` (TEXT FK → divisions, `.named('division_id')`)
    - `firstName` (TEXT NOT NULL, `.named('first_name')`)
    - `lastName` (TEXT NOT NULL, `.named('last_name')`)
    - `dateOfBirth` (DateTime nullable, `.named('date_of_birth')`)
    - `gender` (TEXT nullable, CHECK: 'male', 'female')
    - `weightKg` (REAL nullable, `.named('weight_kg')`)
    - `schoolOrDojangName` (TEXT nullable, `.named('school_or_dojang_name')`) ← CRITICAL for dojang separation
    - `beltRank` (TEXT nullable, `.named('belt_rank')`)
    - `seedNumber` (INTEGER nullable, `.named('seed_number')`)
    - `registrationNumber` (TEXT nullable, `.named('registration_number')`)
    - `isBye` (BOOLEAN DEFAULT false, `.named('is_bye')`)
    - `checkInStatus` (TEXT DEFAULT 'pending', `.named('check_in_status')`)
      - CHECK: 'pending', 'checked_in', 'no_show', 'withdrawn'
    - `checkInAtTimestamp` (DateTime nullable, `.named('check_in_at_timestamp')`)
    - `photoUrl` (TEXT nullable, `.named('photo_url')`)
    - `notes` (TEXT nullable)
    - Include `BaseSyncMixin` and `BaseAuditMixin`
  - [ ] 3.2 Add annotation: `@DataClassName('ParticipantEntry')`
  - [ ] 3.3 Add `Participants` to `tables.dart` barrel file
  - [ ] 3.4 Register table in `AppDatabase` @DriftDatabase annotation
  - [ ] 3.5 Add basic CRUD methods to `AppDatabase` for participants

- [ ] Task 4: Update AppDatabase schema version (AC: #1)
  - [ ] 4.1 Verify current schemaVersion is 2 (from Story 1.10)
  - [ ] 4.2 Increment schemaVersion from 2 to 3
  - [ ] 4.3 Add migration callback:
    ```dart
    if (from < 3) {
      await m.createTable(tournaments);
      await m.createTable(divisions);
      await m.createTable(participants);
    }
    ```
  - [ ] 4.4 Run `dart run build_runner build --delete-conflicting-outputs`

- [ ] Task 5: Create Demo Data Constants (AC: #2, #3)
  - [ ] 5.1 Create `lib/core/demo/demo_data_constants.dart`:
    ```dart
    /// Constants for demo mode data seeding.
    /// Uses predetermined UUIDs for test reproducibility.
    abstract class DemoDataConstants {
      // Demo user (owner)
      static const String demoUserId = '00000000-0000-0000-0000-000000000000';
      
      // Core entities
      static const String demoOrganizationId = '00000000-0000-0000-0000-000000000001';
      static const String demoTournamentId = '00000000-0000-0000-0000-000000000002';
      static const String demoDivisionId = '00000000-0000-0000-0000-000000000003';
      
      // 8 participants from 4 dojangs (2 each)
      static const List<String> demoParticipantIds = [
        '00000000-0000-0000-0000-000000000010', // Min-jun Kim, Dragon
        '00000000-0000-0000-0000-000000000011', // Seo-yeon Park, Dragon
        '00000000-0000-0000-0000-000000000012', // Ji-hoon Lee, Phoenix
        '00000000-0000-0000-0000-000000000013', // Ha-eun Choi, Phoenix
        '00000000-0000-0000-0000-000000000014', // Ethan Johnson, Tiger
        '00000000-0000-0000-0000-000000000015', // Sophia Williams, Tiger
        '00000000-0000-0000-0000-000000000016', // Jacob Martinez, Eagle
        '00000000-0000-0000-0000-000000000017', // Emma Davis, Eagle
      ];
      
      static const List<String> sampleDojangs = [
        'Dragon Martial Arts',
        'Phoenix TKD Academy',
        'Tiger Dojang',
        "Eagle's Nest TKD",
      ];
    }
    ```

- [ ] Task 6: Create Demo Data Service (AC: #4)
  - [ ] 6.1 Create `lib/core/demo/demo_data_service.dart` with abstract interface:
    ```dart
    abstract class DemoDataService {
      Future<bool> shouldSeedDemoData();
      Future<void> seedDemoData();
      Future<bool> hasDemoData();
    }
    ```
  - [ ] 6.2 Implement `DemoDataServiceImplementation`:
    - Inject `AppDatabase` dependency
    - `shouldSeedDemoData()` - returns true if organizations table is empty:
      ```dart
      Future<bool> shouldSeedDemoData() async {
        final orgs = await _db.getActiveOrganizations();
        return orgs.isEmpty;
      }
      ```
    - `hasDemoData()` - delegates to `_db.hasDemoData()`
    - `seedDemoData()` - creates all demo records in transaction
  - [ ] 6.3 Register in DI: `@LazySingleton(as: DemoDataService)`

- [ ] Task 7: Implement Demo Data Seeding Logic (AC: #1, #2)
  - [ ] 7.1 Create demo user (owner):
    - ID: `DemoDataConstants.demoUserId`
    - Email: "demo@tkdbrackets.local"
    - Display name: "Demo User"
    - Role: "owner"
    - Organization ID: `DemoDataConstants.demoOrganizationId`
    - isDemoData: true
  - [ ] 7.2 Create demo organization:
    - ID: `DemoDataConstants.demoOrganizationId`
    - Name: "Demo Dojang"
    - Slug: "demo-dojang"
    - Subscription tier: "free"
    - isDemoData: true
  - [ ] 7.3 Create demo tournament:
    - ID: `DemoDataConstants.demoTournamentId`
    - Name: "Spring Championship 2026"
    - Organization ID: `DemoDataConstants.demoOrganizationId`
    - Created by user ID: `DemoDataConstants.demoUserId`
    - Federation: "wt" (World Taekwondo)
    - Status: "registration_open"
    - Scheduled date: 30 days from seed date
    - isDemoData: true
  - [ ] 7.4 Create demo division:
    - ID: `DemoDataConstants.demoDivisionId`
    - Name: "Cadets -45kg Male"
    - Tournament ID: `DemoDataConstants.demoTournamentId`
    - Category: "sparring"
    - Age range: 12-14
    - Weight: 0-45kg
    - Gender: "male"
    - Bracket format: "single_elimination"
    - Status: "setup"
    - isDemoData: true
  - [ ] 7.5 Create 8 demo participants (2 from each of 4 dojangs):
    - Use `DemoDataConstants.demoParticipantIds`
    - Division ID: `DemoDataConstants.demoDivisionId`
    - Calculate actual birthdates (ages 12-14 from seed date)
    - Check-in status: "pending"
    - isDemoData: true

    | #   | First    | Last     | Dojang              | Birth Year Offset | Weight |
    | --- | -------- | -------- | ------------------- | ----------------- | ------ |
    | 1   | Min-jun  | Kim      | Dragon Martial Arts | -13               | 42.0   |
    | 2   | Seo-yeon | Park     | Dragon Martial Arts | -14               | 44.0   |
    | 3   | Ji-hoon  | Lee      | Phoenix TKD Academy | -12               | 38.0   |
    | 4   | Ha-eun   | Choi     | Phoenix TKD Academy | -13               | 41.0   |
    | 5   | Ethan    | Johnson  | Tiger Dojang        | -14               | 43.0   |
    | 6   | Sophia   | Williams | Tiger Dojang        | -12               | 39.0   |
    | 7   | Jacob    | Martinez | Eagle's Nest TKD    | -13               | 44.0   |
    | 8   | Emma     | Davis    | Eagle's Nest TKD    | -14               | 45.0   |

- [ ] Task 8: Integrate with App Bootstrap (AC: #5)
  - [ ] 8.1 Update `bootstrap.dart` inside Sentry `appRunner` callback:
    ```dart
    appRunner: () async {
      // Initialize DI container
      configureDependencies(environment);
      
      // Seed demo data on first launch (after DI, before UI)
      final demoService = getIt<DemoDataService>();
      if (await demoService.shouldSeedDemoData()) {
        await demoService.seedDemoData();
      }
      
      runApp(const App());
    },
    ```
  - [ ] 8.2 Add import for `DemoDataService` and `getIt`

- [ ] Task 9: Create Barrel File (AC: all)
  - [ ] 9.1 Create `lib/core/demo/demo.dart` barrel file:
    ```dart
    export 'demo_data_constants.dart';
    export 'demo_data_service.dart';
    ```

- [ ] Task 10: Write Unit Tests (AC: #6)
  - [ ] 10.1 Create `test/core/demo/demo_data_constants_test.dart`:
    - All UUIDs are valid format (regex match)
    - No duplicate UUIDs across all constants
    - Correct count: 8 participant IDs
    - Correct count: 4 sample dojangs
  - [ ] 10.2 Create `test/core/demo/demo_data_service_test.dart`:
    - `shouldSeedDemoData()` returns true for empty database
    - `shouldSeedDemoData()` returns false after seeding
    - `seedDemoData()` creates: 1 user, 1 org, 1 tournament, 1 division, 8 participants
    - All records have `isDemoData = true`
    - Idempotency: calling twice doesn't duplicate
  - [ ] 10.3 Create `test/core/database/tables/tournaments_table_test.dart`
  - [ ] 10.4 Create `test/core/database/tables/divisions_table_test.dart`
  - [ ] 10.5 Create `test/core/database/tables/participants_table_test.dart`

- [ ] Task 11: Verification
  - [ ] 11.1 Run `dart analyze` - must pass with no errors
  - [ ] 11.2 Run `flutter test` - all tests must pass
  - [ ] 11.3 Run `flutter build web --release` - must complete successfully

## Dev Notes

### Project Location

**CRITICAL:** All code changes are in:
```
/Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/
```

### Architecture Context

**Location:** `lib/core/demo/` - Core infrastructure for demo mode
**Database Tables:** `lib/core/database/tables/` - Drift table definitions

**Dependencies:**
- `AppDatabase` (Story 1.5) - Drift database for table definitions
- `get_it`/`injectable` (Story 1.2) - DI registration

**Data Flow:**
```
App startup → bootstrap.dart → Sentry.appRunner()
                                    ↓
                        configureDependencies()
                                    ↓
                        DemoDataService.shouldSeedDemoData()
                                    ↓
                (if empty) → DemoDataService.seedDemoData()
                                    ↓
                              runApp(const App())
```

### Column Naming Convention

Drift uses camelCase in Dart but maps to snake_case in database:
```dart
TextColumn get organizationId => 
    text().named('organization_id').references(Organizations, #id)();
```

**Always use `.named('snake_case')` for multi-word columns!**

### Demo Mode Limits (Per Architecture)

Demo mode is more restrictive than Free tier:
- **1 tournament** (Free tier: 2/month)
- **1 division** (vs multiple in Free)
- **8 participants** (Free tier: 32/bracket)
- **Local-only** - no cloud sync until signup

### Table Schema Reference (from Architecture)

All tables include mixins from `base_tables.dart`:
- `BaseSyncMixin`: `syncVersion`, `isDeleted`, `deletedAtTimestamp`, `isDemoData`
- `BaseAuditMixin`: `createdAtTimestamp`, `updatedAtTimestamp`

### Foreign Key Pattern

```dart
TextColumn get tournamentId => 
    text().named('tournament_id').references(Tournaments, #id)();
```

### Testing Strategy

**Mocking Requirements:**
```dart
// Use in-memory Drift database for testing
final testDb = AppDatabase.forTesting(NativeDatabase.memory());
```

### Code Patterns from Previous Stories

From Story 1.5 (Drift Database):
- Use `@DataClassName('XxxEntry')` annotation
- Use `Set<Column> get primaryKey => {id};`
- Use TEXT for UUID columns (SQLite compatibility)
- Use `.named('snake_case')` for multi-word column names

From Story 1.10 (Sync Service):
- Use transactions for multi-record operations
- Follow existing CRUD patterns in AppDatabase

### NOT Creating in This Story

- **Tournament entity/repository** - Epic 3 (Story 3.2)
- **Division entity/repository** - Epic 3 (Story 3.7)
- **Participant entity/repository** - Epic 4 (Story 4.2)
- **Demo-to-production migration** - Epic 2 (Story 2.10)

This story creates only:
1. Database tables (schema definition)
2. Demo data seeding service
3. Basic AppDatabase CRUD methods

Full Clean Architecture layers (domain entities, repositories, use cases) come in later epics.

### Project Structure

```
lib/core/
├── database/
│   └── tables/
│       ├── tournaments_table.dart    # NEW
│       ├── divisions_table.dart       # NEW
│       └── participants_table.dart    # NEW
├── demo/
│   ├── demo.dart                      # NEW barrel file
│   ├── demo_data_constants.dart       # NEW
│   └── demo_data_service.dart         # NEW
```

### References

- **Architecture:** `_bmad-output/planning-artifacts/architecture.md`
  - Demo Mode Implementation (lines 404-409)
  - Tournaments Schema (lines 1295-1330)
  - Divisions Schema (lines 1353-1383)
  - Participants Schema (lines 1386-1413)
  - Demo Mode Migration Architecture (lines 1952-2103)
- **PRD:** Pre-signup demo mode, FR65-FR69 (Offline & Reliability)
- **UX Spec:** Pre-Signup Demo (lines 127-132) - "Builds trust before commitment"
- **Epic:** Story 1.11 from `_bmad-output/planning-artifacts/epics.md` (lines 870-888)
- **Previous Stories:**
  - 1.5 (Drift Database) - table patterns, migrations, AppDatabase
  - 1.10 (Sync Service) - transaction patterns, BaseSyncMixin usage

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
