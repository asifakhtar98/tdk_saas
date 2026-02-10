import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';

/// Use case to sign out the current user.
///
/// Clears the Supabase auth session.
/// Does NOT clear local Drift database (demo data preserved).
@injectable
class SignOutUseCase extends UseCase<Unit, NoParams> {
  SignOutUseCase(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    return _authRepository.signOut();
  }
}
