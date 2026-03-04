/// Division feature - exports public APIs.
library;

// Data exports
export 'data/datasources/division_local_datasource.dart';
export 'data/datasources/division_remote_datasource.dart';
export 'data/datasources/division_template_local_datasource.dart';
export 'data/datasources/division_template_remote_datasource.dart';
export 'data/models/division_model.dart';
export 'data/models/division_template_model.dart';
export 'data/repositories/division_repository_implementation.dart';
export 'data/repositories/division_template_repository_implementation.dart';

// Domain exports
export 'domain/entities/belt_rank.dart';
export 'domain/entities/conflict_warning.dart';
export 'domain/entities/division_entity.dart';
export 'domain/entities/division_template.dart';
export 'domain/entities/scoring_method.dart';
export 'domain/repositories/division_repository.dart';
export 'domain/repositories/division_template_repository.dart';
export 'domain/services/conflict_detection_service.dart';

// Domain - Use Cases
export 'domain/usecases/apply_federation_template_params.dart';
export 'domain/usecases/apply_federation_template_usecase.dart';
export 'domain/usecases/assign_to_ring_params.dart';
export 'domain/usecases/assign_to_ring_usecase.dart';
export 'domain/usecases/create_custom_division_params.dart';
export 'domain/usecases/create_custom_division_usecase.dart';
export 'domain/usecases/get_divisions_usecase.dart';
export 'domain/usecases/merge_divisions_params.dart';
export 'domain/usecases/merge_divisions_usecase.dart';
export 'domain/usecases/smart_division_builder_params.dart';
export 'domain/usecases/smart_division_builder_usecase.dart';
export 'domain/usecases/smart_division_naming_service.dart';
export 'domain/usecases/split_division_params.dart';
export 'domain/usecases/split_division_usecase.dart';
export 'domain/usecases/update_custom_division_params.dart';
export 'domain/usecases/update_custom_division_usecase.dart';

// Feature Services exports
export 'services/federation_template_registry.dart';

// Presentation exports
// (Add pages/widgets/blocs here if they exist and follow the pattern)
