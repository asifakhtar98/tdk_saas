/// Authentication feature - exports public APIs.
library;

// Data layer (typically not exported, but useful for testing)
export 'data/models/user_model.dart';

// Domain layer
export 'domain/entities/user_entity.dart';
export 'domain/repositories/user_repository.dart';
