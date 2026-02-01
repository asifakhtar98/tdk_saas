import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

// TODO(story-1.2): Uncomment after running build_runner.
// import 'package:tkd_brackets/injection.config.dart';

/// Global service locator instance.
final GetIt getIt = GetIt.instance;

/// Configures the dependency injection container.
/// Call this from bootstrap.dart before runApp().
@InjectableInit()
Future<void> configureDependencies(String environment) async {
  // TODO(story-1.2): Uncomment after running build_runner.
  // getIt.init(environment: environment);
}
