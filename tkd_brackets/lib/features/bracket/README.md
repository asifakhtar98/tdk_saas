# Bracket Feature

Handles bracket generation, seeding algorithms, match tree construction, and bracket visualization for TKD Brackets.

## FRs Covered
- FR20-FR31 (Epic 5)

## Structure
- `data/` - Datasources, models, repository implementations
- `domain/` - Entities, repository interfaces, use cases
- `presentation/` - BLoC, pages, widgets

## Dependencies (Planned)
- `drift` - Local database (for Stories 5.2-5.3)
- `supabase_flutter` - Remote backend (for Stories 5.2-5.3)
- `flutter_bloc` - State management (for Story 5.13)
- `fpdart` - Functional error handling (for Stories 5.2+)
- `freezed` - Code generation for entities/events/states (for Stories 5.2+)

## Related Infrastructure
- `lib/core/database/tables/brackets_table.dart` - Drift table (to be created in Story 5.2)
- `lib/core/database/tables/matches_table.dart` - Drift table (to be created in Story 5.3)
- `lib/features/division/domain/entities/division_entity.dart` - BracketFormat enum (created in Epic 3)
- `lib/features/participant/domain/entities/participant_entity.dart` - ParticipantEntity (created in Epic 4)
- `lib/core/algorithms/seeding/` - Seeding algorithms (to be created in Story 5.7)
