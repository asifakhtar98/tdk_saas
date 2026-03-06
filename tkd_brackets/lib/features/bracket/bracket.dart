/// Bracket feature - exports public APIs.
library;

// Data exports
export 'data/datasources/bracket_local_datasource.dart';
export 'data/datasources/bracket_remote_datasource.dart';
export 'data/datasources/match_local_datasource.dart';
export 'data/datasources/match_remote_datasource.dart';
export 'data/models/bracket_model.dart';
export 'data/models/match_model.dart';
export 'data/repositories/bracket_repository_implementation.dart';
export 'data/repositories/match_repository_implementation.dart';
export 'data/services/bracket_layout_engine_implementation.dart';
export 'data/services/double_elimination_bracket_generator_service_implementation.dart';
export 'data/services/round_robin_bracket_generator_service_implementation.dart';
export 'data/services/single_elimination_bracket_generator_service_implementation.dart';

// Domain exports
export 'domain/entities/bracket_entity.dart';
export 'domain/entities/bracket_generation_result.dart';
export 'domain/entities/bracket_layout.dart';
export 'domain/entities/double_elimination_bracket_generation_result.dart';
export 'domain/entities/match_entity.dart';
export 'domain/entities/regenerate_bracket_result.dart';
export 'domain/repositories/bracket_repository.dart';
export 'domain/repositories/match_repository.dart';
export 'domain/services/bracket_layout_engine.dart';
export 'domain/services/double_elimination_bracket_generator_service.dart';
export 'domain/services/round_robin_bracket_generator_service.dart';
export 'domain/services/single_elimination_bracket_generator_service.dart';
export 'domain/usecases/generate_double_elimination_bracket_params.dart';
export 'domain/usecases/generate_double_elimination_bracket_use_case.dart';
export 'domain/usecases/generate_round_robin_bracket_params.dart';
export 'domain/usecases/generate_round_robin_bracket_use_case.dart';
export 'domain/usecases/generate_single_elimination_bracket_params.dart';
export 'domain/usecases/generate_single_elimination_bracket_use_case.dart';
export 'domain/usecases/lock_bracket_params.dart';
export 'domain/usecases/lock_bracket_use_case.dart';
export 'domain/usecases/regenerate_bracket_params.dart';
export 'domain/usecases/regenerate_bracket_use_case.dart';
export 'domain/usecases/unlock_bracket_params.dart';
export 'domain/usecases/unlock_bracket_use_case.dart';

// Presentation exports
export 'presentation/bloc/bracket_bloc.dart';
export 'presentation/bloc/bracket_event.dart';
export 'presentation/bloc/bracket_state.dart';
export 'presentation/bloc/bracket_generation_bloc.dart';
export 'presentation/bloc/bracket_generation_event.dart';
export 'presentation/bloc/bracket_generation_state.dart';
export 'presentation/pages/bracket_page.dart';
export 'presentation/pages/bracket_generation_page.dart';
export 'presentation/widgets/bracket_connection_lines_widget.dart';
export 'presentation/widgets/bracket_viewer_widget.dart';
export 'presentation/widgets/bracket_format_selection_dialog.dart';
export 'presentation/widgets/match_card_widget.dart';
export 'presentation/widgets/round_label_widget.dart';
export 'presentation/widgets/round_robin_table_widget.dart';
