/// Authentication feature - exports public APIs.
library;

// Data - Datasources (for DI visibility)
export 'data/datasources/invitation_local_datasource.dart';
export 'data/datasources/invitation_remote_datasource.dart';
export 'data/datasources/organization_local_datasource.dart';
export 'data/datasources/organization_remote_datasource.dart';
export 'data/datasources/supabase_auth_datasource.dart';
export 'data/datasources/user_local_datasource.dart';
export 'data/datasources/user_remote_datasource.dart';

// Data - Models
export 'data/models/invitation_model.dart';
export 'data/models/organization_model.dart';
export 'data/models/user_model.dart';

// Data - Repositories
export 'data/repositories/auth_repository_implementation.dart';
export 'data/repositories/invitation_repository_implementation.dart';
export 'data/repositories/organization_repository_implementation.dart';
export 'data/repositories/user_repository_implementation.dart';

// Domain - Entities
export 'domain/entities/invitation_entity.dart';
export 'domain/entities/organization_entity.dart';
export 'domain/entities/permission.dart';
export 'domain/entities/rbac_permission_service.dart';
export 'domain/entities/user_entity.dart';

// Domain - Repositories
export 'domain/repositories/auth_repository.dart';
export 'domain/repositories/invitation_repository.dart';
export 'domain/repositories/organization_repository.dart';
export 'domain/repositories/user_repository.dart';

// Domain - Use Cases
export 'domain/usecases/accept_invitation_params.dart';
export 'domain/usecases/accept_invitation_use_case.dart';
export 'domain/usecases/create_organization_params.dart';
export 'domain/usecases/create_organization_use_case.dart';
export 'domain/usecases/get_current_user_use_case.dart';
export 'domain/usecases/remove_organization_member_params.dart';
export 'domain/usecases/remove_organization_member_use_case.dart';
export 'domain/usecases/send_invitation_params.dart';
export 'domain/usecases/send_invitation_use_case.dart';
export 'domain/usecases/sign_in_with_email_params.dart';
export 'domain/usecases/sign_in_with_email_use_case.dart';
export 'domain/usecases/sign_out_use_case.dart';
export 'domain/usecases/sign_up_with_email_params.dart';
export 'domain/usecases/sign_up_with_email_use_case.dart';
export 'domain/usecases/update_user_role_params.dart';
export 'domain/usecases/update_user_role_use_case.dart';
export 'domain/usecases/verify_magic_link_params.dart';
export 'domain/usecases/verify_magic_link_use_case.dart';

// Presentation - BLoC
export 'presentation/bloc/authentication_bloc.dart';
export 'presentation/bloc/authentication_event.dart';
export 'presentation/bloc/authentication_state.dart';
