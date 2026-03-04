# Division Feature

Manages divisions, templates, and tournament-division relations for TKD Brackets.

## FRs Covered
- FR5-FR9 (Epic 3)
- Smart Division Builder

## Structure
- `data/` - Datasources, models, repository implementations
- `domain/` - Entities, repository interfaces, use cases
- `presentation/` - (Planned) BLoC, pages, widgets
- `services/` - Feature-level services (FederationTemplateRegistry)

## Dependencies
- `drift` - Local database
- `supabase_flutter` - Remote backend
- `flutter_bloc` - State management
- `fpdart` - Functional error handling
