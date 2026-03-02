import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tkd_brackets/core/services/logger_service.dart';

/// [BlocObserver] that logs all [Bloc] activity.
/// This includes [onEvent], [onChange], [onTransition], [onClose], and [onError] events.
///
/// It uses the [LoggerService] to provide formatted, readable logs for debugging.
class AppBlocObserver extends BlocObserver {
  /// Default constructor for [AppBlocObserver].
  AppBlocObserver(this._logger);

  final LoggerService _logger;

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    _logger.info('onEvent(${bloc.runtimeType}, $event)');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    _logger.info('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _logger.error('onError(${bloc.runtimeType}, $error)', error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    _logger.info('onTransition(${bloc.runtimeType}, $transition)');
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    _logger.info('onClose(${bloc.runtimeType})');
  }
}
