import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/update_tournament_settings_params.dart';

@injectable
class UpdateTournamentSettingsUseCase
    extends UseCase<TournamentEntity, UpdateTournamentSettingsParams> {
  UpdateTournamentSettingsUseCase(this._repository, this._userRepository);

  final TournamentRepository _repository;
  final UserRepository _userRepository;

  static const int minRingCount = 1;
  static const int maxRingCount = 20;
  static const int maxVenueNameLength = 200;
  static const int maxVenueAddressLength = 500;

  @override
  Future<Either<Failure, TournamentEntity>> call(
    UpdateTournamentSettingsParams params,
  ) async {
    final validationErrors = <String, String>{};

    if (params.ringCount != null) {
      if (params.ringCount! < minRingCount ||
          params.ringCount! > maxRingCount) {
        validationErrors['ringCount'] =
            'Ring count must be between $minRingCount and $maxRingCount';
      }
    }

    if (params.venueName != null &&
        params.venueName!.length > maxVenueNameLength) {
      validationErrors['venueName'] =
          'Venue name must be $maxVenueNameLength characters or less';
    }

    if (params.venueAddress != null &&
        params.venueAddress!.length > maxVenueAddressLength) {
      validationErrors['venueAddress'] =
          'Venue address must be $maxVenueAddressLength characters or less';
    }

    if (validationErrors.isNotEmpty) {
      return Left(
        InputValidationFailure(
          userFriendlyMessage: 'Please fix the validation errors',
          fieldErrors: validationErrors,
        ),
      );
    }

    final tournamentResult = await _repository.getTournamentById(
      params.tournamentId,
    );
    final tournament = tournamentResult.fold((failure) => null, (t) => t);

    if (tournament == null) {
      return Left(
        NotFoundFailure(
          userFriendlyMessage: 'Tournament not found',
          technicalDetails:
              'No tournament exists with ID: ${params.tournamentId}',
        ),
      );
    }

    final userResult = await _userRepository.getCurrentUser();
    final user = userResult.fold((failure) => null, (u) => u);

    if (user == null) {
      return const Left(
        AuthenticationFailure(
          userFriendlyMessage:
              'You must be logged in to update tournament settings',
        ),
      );
    }

    final canModify =
        user.role == UserRole.owner || user.role == UserRole.admin;
    if (!canModify) {
      return const Left(
        AuthorizationPermissionDeniedFailure(
          userFriendlyMessage:
              'Only Owners and Admins can modify tournament settings',
        ),
      );
    }

    final updatedTournament = tournament.copyWith(
      federationType: params.federationType ?? tournament.federationType,
      venueName: params.venueName?.isEmpty ?? false ? null : params.venueName,
      venueAddress: params.venueAddress?.isEmpty ?? false
          ? null
          : params.venueAddress,
      numberOfRings: params.ringCount ?? tournament.numberOfRings,
      scheduledStartTime: params.scheduledStartTime,
      scheduledEndTime: params.scheduledEndTime,
    );

    return _repository.updateTournament(updatedTournament);
  }
}
