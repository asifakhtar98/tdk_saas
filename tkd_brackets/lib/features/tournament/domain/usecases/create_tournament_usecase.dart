import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/create_tournament_params.dart';
import 'package:uuid/uuid.dart';

@injectable
class CreateTournamentUseCase
    extends UseCase<TournamentEntity, CreateTournamentParams> {
  CreateTournamentUseCase(this._repository, this._userRepository);

  final TournamentRepository _repository;
  final UserRepository _userRepository;

  static const _uuid = Uuid();

  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 1000;

  @override
  Future<Either<Failure, TournamentEntity>> call(
    CreateTournamentParams params,
  ) async {
    final trimmedName = params.name.trim();
    final validationErrors = <String, String>{};

    if (trimmedName.isEmpty) {
      validationErrors['name'] = 'Name is required';
    } else if (trimmedName.length > maxNameLength) {
      validationErrors['name'] =
          'Name must be $maxNameLength characters or less';
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final scheduledDate = DateTime(
      params.scheduledDate.year,
      params.scheduledDate.month,
      params.scheduledDate.day,
    );
    if (scheduledDate.isBefore(todayDate)) {
      validationErrors['scheduledDate'] =
          'Tournament date cannot be in the past';
    }

    if (params.description != null &&
        params.description!.length > maxDescriptionLength) {
      validationErrors['description'] =
          'Description must be $maxDescriptionLength characters or less';
    }

    if (validationErrors.isNotEmpty) {
      return Left(
        InputValidationFailure(
          userFriendlyMessage: 'Please fix the validation errors',
          fieldErrors: validationErrors,
        ),
      );
    }

    final userResult = await _userRepository.getCurrentUser();
    final user = userResult.fold((failure) => null, (user) => user);

    if (user == null || user.organizationId.isEmpty) {
      return const Left(
        AuthenticationFailure(
          userFriendlyMessage: 'You must be logged in with an organization',
        ),
      );
    }

    final tournamentId = _uuid.v4();

    final tournament = TournamentEntity(
      id: tournamentId,
      organizationId: user.organizationId,
      createdByUserId: user.id,
      name: trimmedName,
      scheduledDate: params.scheduledDate,
      description: params.description?.trim(),
      federationType: FederationType.wt,
      status: TournamentStatus.draft,
      numberOfRings: 1,
      isTemplate: false,
      settingsJson: const {},
      createdAt: DateTime.now(),
      updatedAtTimestamp: DateTime.now(),
    );

    return _repository.createTournament(tournament, user.organizationId);
  }
}
