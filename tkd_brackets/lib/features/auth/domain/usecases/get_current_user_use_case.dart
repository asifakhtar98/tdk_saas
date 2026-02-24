import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';

/// Use case to get the currently authenticated user.
///
/// Checks Supabase session, then local cache, then remote.
/// Returns [UserEntity] if authenticated, [Failure] if not.
@injectable
class GetCurrentUserUseCase extends UseCase<UserEntity, NoParams> {
  GetCurrentUserUseCase(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async {
    return _authRepository.getCurrentAuthenticatedUser();
  }
}
