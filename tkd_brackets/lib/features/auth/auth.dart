/// Authentication feature - exports public APIs.
library;

// Data - Datasources (for DI visibility)
export 'data/datasources/supabase_auth_datasource.dart';
export 'data/datasources/user_local_datasource.dart';
export 'data/datasources/user_remote_datasource.dart';

// Data - Models
export 'data/models/user_model.dart';

// Data - Repositories
export 'data/repositories/auth_repository_implementation.dart';
export 'data/repositories/user_repository_implementation.dart';

// Domain - Entities
export 'domain/entities/user_entity.dart';

// Domain - Repositories
export 'domain/repositories/auth_repository.dart';
export 'domain/repositories/user_repository.dart';

// Domain - Use Cases
export 'domain/usecases/sign_up_with_email_params.dart';
export 'domain/usecases/sign_up_with_email_use_case.dart';
