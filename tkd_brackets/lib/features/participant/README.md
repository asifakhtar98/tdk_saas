# Participant Feature

Manages tournament participants — registration, CSV import, division assignment, and status tracking for TKD Brackets.

## FRs Covered
- FR13-FR19 (Epic 4)

## Structure
- `data/` - Datasources, models, repository implementations
- `domain/` - Entities, repository interfaces, use cases
- `presentation/` - BLoC, pages, widgets

## Dependencies (Planned)
- `drift` - Local database (for Stories 4.2+)
- `supabase_flutter` - Remote backend (for Stories 4.2+)
- `flutter_bloc` - State management (for Story 4.12)
- `fpdart` - Functional error handling (for Stories 4.2+)
- `freezed` - Code generation for entities/events/states (for Stories 4.2+)

## Related Infrastructure
- `lib/core/database/tables/participants_table.dart` - Drift table (created in Epic 1)
- `lib/features/division/domain/repositories/division_repository.dart` - Cross-feature participant queries
