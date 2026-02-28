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
export 'data/services/double_elimination_bracket_generator_service_implementation.dart';
export 'data/services/round_robin_bracket_generator_service_implementation.dart';
export 'data/services/single_elimination_bracket_generator_service_implementation.dart';

// Domain exports
export 'domain/entities/bracket_entity.dart';
export 'domain/entities/bracket_generation_result.dart';
export 'domain/entities/double_elimination_bracket_generation_result.dart';
export 'domain/entities/match_entity.dart';
export 'domain/repositories/bracket_repository.dart';
export 'domain/repositories/match_repository.dart';
export 'domain/services/double_elimination_bracket_generator_service.dart';
export 'domain/services/round_robin_bracket_generator_service.dart';
export 'domain/services/single_elimination_bracket_generator_service.dart';
export 'domain/usecases/generate_double_elimination_bracket_params.dart';
export 'domain/usecases/generate_double_elimination_bracket_use_case.dart';
export 'domain/usecases/generate_round_robin_bracket_params.dart';
export 'domain/usecases/generate_round_robin_bracket_use_case.dart';
export 'domain/usecases/generate_single_elimination_bracket_params.dart';
export 'domain/usecases/generate_single_elimination_bracket_use_case.dart';

// Presentation exports
