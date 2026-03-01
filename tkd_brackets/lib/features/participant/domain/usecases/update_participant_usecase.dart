import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/update_participant_params.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

@injectable
class UpdateParticipantUseCase {
  UpdateParticipantUseCase(
    this._participantRepository,
    this._divisionRepository,
    this._tournamentRepository,
    this._userRepository,
  );

  final ParticipantRepository _participantRepository;
  final DivisionRepository _divisionRepository;
  final TournamentRepository _tournamentRepository;
  final UserRepository _userRepository;

  static const int minAge = 4;
  static const int maxAge = 80;
  static const double maxWeightKg = 150;

  Future<Either<Failure, ParticipantEntity>> call(
    UpdateParticipantParams params,
  ) async {
    // STEP 1: Validate participantId not empty
    if (params.participantId.isEmpty) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage: 'Participant ID is required',
          fieldErrors: {'participantId': 'Participant ID cannot be empty'},
        ),
      );
    }

    // STEP 2: Check at least one field provided
    if (params.firstName == null &&
        params.lastName == null &&
        params.dateOfBirth == null &&
        params.gender == null &&
        params.weightKg == null &&
        params.schoolOrDojangName == null &&
        params.beltRank == null &&
        params.registrationNumber == null &&
        params.notes == null) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage: 'At least one field must be provided for update',
          fieldErrors: {'params': 'No fields to update'},
        ),
      );
    }

    // STEP 3: Field-level validation — BEFORE any repo calls
    final validationErrors = _validateInputs(params);
    if (validationErrors.isNotEmpty) {
      return Left(
        InputValidationFailure(
          userFriendlyMessage: 'Please fix the validation errors',
          fieldErrors: validationErrors,
        ),
      );
    }

    // STEP 4: Auth — get current user
    final userResult = await _userRepository.getCurrentUser();
    final user = userResult.fold((failure) => null, (user) => user);
    if (user == null || user.organizationId.isEmpty) {
      return const Left(
        AuthorizationPermissionDeniedFailure(
          userFriendlyMessage:
              'You must be logged in with an organization to edit participants',
        ),
      );
    }

    // STEP 5: Get participant
    final participantResult = await _participantRepository.getParticipantById(
      params.participantId,
    );
    final participant = participantResult.fold((failure) => null, (p) => p);
    if (participant == null) {
      return const Left(
        NotFoundFailure(userFriendlyMessage: 'Participant not found'),
      );
    }

    // STEP 6: Get division via participant.divisionId
    final divisionResult = await _divisionRepository.getDivisionById(
      participant.divisionId,
    );
    final division = divisionResult.fold((failure) => null, (d) => d);
    if (division == null) {
      return const Left(
        NotFoundFailure(userFriendlyMessage: 'Source division not found'),
      );
    }

    // STEP 7: Get tournament via division.tournamentId
    final tournamentResult = await _tournamentRepository.getTournamentById(
      division.tournamentId,
    );
    final tournament = tournamentResult.fold((failure) => null, (t) => t);
    if (tournament == null) {
      return const Left(
        NotFoundFailure(userFriendlyMessage: 'Tournament not found'),
      );
    }

    // STEP 8: Verify org ownership
    if (tournament.organizationId != user.organizationId) {
      return const Left(
        AuthorizationPermissionDeniedFailure(
          userFriendlyMessage:
              'You do not have permission '
              'to edit participants in this tournament',
        ),
      );
    }

    // STEP 9: Division status check
    if (division.status != DivisionStatus.setup &&
        division.status != DivisionStatus.ready) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage:
              'Cannot edit participants in '
              'a division that is in progress or completed',
          fieldErrors: {
            'divisionId': 'Division is not accepting modifications',
          },
        ),
      );
    }

    // STEP 10: Apply updates with copyWith
    final updatedParticipant = participant.copyWith(
      firstName: params.firstName?.trim() ?? participant.firstName,
      lastName: params.lastName?.trim() ?? participant.lastName,
      dateOfBirth: params.dateOfBirth ?? participant.dateOfBirth,
      gender: params.gender ?? participant.gender,
      weightKg: params.weightKg ?? participant.weightKg,
      schoolOrDojangName:
          params.schoolOrDojangName?.trim() ?? participant.schoolOrDojangName,
      beltRank: params.beltRank?.trim() ?? participant.beltRank,
      registrationNumber:
          params.registrationNumber?.trim() ?? participant.registrationNumber,
      notes: params.notes?.trim() ?? participant.notes,
      syncVersion: participant.syncVersion + 1,
      updatedAtTimestamp: DateTime.now(),
    );

    // STEP 11: Persist and return
    return _participantRepository.updateParticipant(updatedParticipant);
  }

  Map<String, String> _validateInputs(UpdateParticipantParams params) {
    final errors = <String, String>{};

    if (params.firstName != null && params.firstName!.trim().isEmpty) {
      errors['firstName'] = 'First name cannot be empty';
    }

    if (params.lastName != null && params.lastName!.trim().isEmpty) {
      errors['lastName'] = 'Last name cannot be empty';
    }

    if (params.schoolOrDojangName != null &&
        params.schoolOrDojangName!.trim().isEmpty) {
      errors['schoolOrDojangName'] = 'Dojang name cannot be empty';
    }

    if (params.beltRank != null && params.beltRank!.trim().isEmpty) {
      errors['beltRank'] = 'Belt rank cannot be empty';
    } else if (params.beltRank != null &&
        !_isValidBeltRank(params.beltRank!.trim())) {
      errors['beltRank'] =
          'Invalid belt rank. Use standard TKD belt names '
          '(e.g., White, Yellow, Green, Blue, Red, Black)';
    }

    if (params.weightKg != null && params.weightKg! < 0) {
      errors['weightKg'] = 'Weight cannot be negative';
    }

    if (params.weightKg != null && params.weightKg! > maxWeightKg) {
      errors['weightKg'] = 'Weight exceeds maximum allowed (${maxWeightKg}kg)';
    }

    if (params.dateOfBirth != null) {
      final now = DateTime.now();
      if (params.dateOfBirth!.isAfter(now)) {
        errors['dateOfBirth'] = 'Date of birth cannot be in the future';
      } else {
        final age = _calculateAge(params.dateOfBirth!);
        if (age < minAge || age > maxAge) {
          errors['dateOfBirth'] =
              'Participant age must be between $minAge and $maxAge years';
        }
      }
    }

    return errors;
  }

  bool _isValidBeltRank(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll('-', '')
        .replaceAll(' ', '');
    const validBelts = [
      'white',
      'yellow',
      'orange',
      'green',
      'blue',
      'red',
      'black',
    ];
    for (final belt in validBelts) {
      if (normalized == belt) return true;
    }
    if (normalized.startsWith('black')) {
      final suffix = normalized.substring(5);
      if (RegExp(r'^[1-9]st?dan$').hasMatch(suffix) ||
          RegExp(r'^[1-9]nd?dan$').hasMatch(suffix) ||
          RegExp(r'^[1-9]rd?dan$').hasMatch(suffix) ||
          RegExp(r'^[1-9]th?dan$').hasMatch(suffix)) {
        return true;
      }
    }
    return false;
  }

  int _calculateAge(DateTime dateOfBirth) {
    final now = DateTime.now();
    var age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
}
