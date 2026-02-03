# TKD Brackets

Tournament bracket management for Taekwondo competitions with offline-first capability.

## Getting Started

### Prerequisites

- Flutter SDK >= 3.24.0
- Dart SDK >= 3.5.0

### Setup

1. Clone the repository
2. Copy `.env.example` to `.env` and configure your environment variables
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Generate code:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
5. Run the app:
   ```bash
   flutter run -d chrome -t lib/main_development.dart
   ```

6. Test locally — Run with Supabase credentials:
```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Architecture

This project follows Clean Architecture with three layers:
- **Presentation**: UI, BLoCs, Widgets
- **Domain**: Entities, Use Cases, Repository Interfaces
- **Data**: Models, Data Sources, Repository Implementations

## Project Structure

```
lib/
├── app/           # Root app configuration
├── core/          # Shared infrastructure
├── features/      # Feature modules
└── database/      # Drift database definitions
```

## Development

### Running Tests

```bash
flutter test
```

### Building for Web

```bash
flutter build web
```

### Code Generation

After modifying files that use code generation (injectable, go_router_builder, drift):

```bash
dart run build_runner build --delete-conflicting-outputs
```

## License

Proprietary - All rights reserved.
