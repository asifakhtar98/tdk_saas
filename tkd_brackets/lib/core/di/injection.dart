// Explicit configuration per Story 1.2 Technical Requirements to prevent drift.


import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:tkd_brackets/core/di/injection.config.dart';

/// Global service locator instance.
final GetIt getIt = GetIt.instance;

/// Configures the dependency injection container.
/// Call this from bootstrap.dart before runApp().
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies(String environment) =>
    getIt.init(environment: environment);
