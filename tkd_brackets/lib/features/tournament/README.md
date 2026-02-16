# Tournament Feature

Manages tournaments, divisions, and tournament configuration for TKD Brackets.

## FRs Covered
- FR1-FR12 (Epic 3)

## Structure
- `data/` - Datasources, models, repository implementations, services
- `domain/` - Entities, repository interfaces, use cases
- `presentation/` - BLoC, pages, widgets

## Dependencies (Planned)
- `drift` - Local database (for Stories 3.2+)
- `supabase_flutter` - Remote backend (for Stories 3.2+)
- `flutter_bloc` - State management (for Stories 3.4+)
- `fpdart` - Functional error handling (for Stories 3.2+)
