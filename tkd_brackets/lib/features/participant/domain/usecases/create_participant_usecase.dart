import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/create_participant_params.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:uuid/uuid.dart';

@injectable
class CreateParticipantUseCase
    extends UseCase<ParticipantEntity, CreateParticipantParams> {
  CreateParticipantUseCase(
    this._participantRepository,
    this._divisionRepository,
    this._tournamentRepository,
    this._userRepository,
  );

  final ParticipantRepository _participantRepository;
  final DivisionRepository _divisionRepository;
  final TournamentRepository _tournamentRepository;
  final UserRepository _userRepository;

  static const _uuid = Uuid();

  static const int minAge = 4;
  static const int maxAge = 80;
  static const double maxWeightKg = 150;

  @override
  Future<Either<Failure, ParticipantEntity>> call(
    CreateParticipantParams params,
  ) async {
    final validationErrors = _validateInputs(params);
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
        AuthorizationPermissionDeniedFailure(
          userFriendlyMessage:
              'You must be logged in with an organization to add participants',
        ),
      );
    }

    final divisionResult = await _divisionRepository.getDivisionById(
      params.divisionId,
    );
    final division = divisionResult.fold(
      (failure) => null,
      (division) => division,
    );

    if (division == null) {
      return const Left(
        NotFoundFailure(userFriendlyMessage: 'Division not found'),
      );
    }

    final tournamentResult = await _tournamentRepository.getTournamentById(
      division.tournamentId,
    );
    final tournament = tournamentResult.fold(
      (failure) => null,
      (tournament) => tournament,
    );

    if (tournament == null) {
      return const Left(
        NotFoundFailure(userFriendlyMessage: 'Tournament not found'),
      );
    }

    if (tournament.organizationId != user.organizationId) {
      return const Left(
        AuthorizationPermissionDeniedFailure(
          userFriendlyMessage:
              'You do not have permission to add participants to this division',
        ),
      );
    }

    final now = DateTime.now();
    final participant = ParticipantEntity(
      id: _uuid.v4(),
      divisionId: params.divisionId,
      firstName: params.firstName.trim(),
      lastName: params.lastName.trim(),
      dateOfBirth: params.dateOfBirth,
      gender: params.gender,
      weightKg: params.weightKg,
      schoolOrDojangName: params.schoolOrDojangName.trim(),
      beltRank: params.beltRank.trim(),
      seedNumber: null,
      registrationNumber: params.registrationNumber?.trim(),
      isBye: false,
      checkInStatus: ParticipantStatus.pending,
      checkInAtTimestamp: null,
      photoUrl: null,
      notes: params.notes?.trim(),
      syncVersion: 1,
      isDeleted: false,
      deletedAtTimestamp: null,
      isDemoData: false,
      createdAtTimestamp: now,
      updatedAtTimestamp: now,
    );

    return _participantRepository.createParticipant(participant);
  }

  Map<String, String> _validateInputs(CreateParticipantParams params) {
    final errors = <String, String>{};

    if (params.firstName.trim().isEmpty) {
      errors['firstName'] = 'First name is required';
    }

    if (params.lastName.trim().isEmpty) {
      errors['lastName'] = 'Last name is required';
    }

    if (params.schoolOrDojangName.trim().isEmpty) {
      errors['schoolOrDojangName'] = 'Dojang name is required';
    }

    if (params.beltRank.trim().isEmpty) {
      errors['beltRank'] = 'Belt rank is required';
    } else if (!_isValidBeltRank(params.beltRank.trim())) {
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
      if (normalized == belt) {
        return true;
      }
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
