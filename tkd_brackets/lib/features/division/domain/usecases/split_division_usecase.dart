import 'dart:math';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:tkd_brackets/core/database/app_database.dart'
    show ParticipantEntry;
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/division/domain/usecases/split_division_params.dart';

@injectable
class SplitDivisionUseCase
    extends UseCase<List<DivisionEntity>, SplitDivisionParams> {
  SplitDivisionUseCase(this._divisionRepository, this._uuid);

  final DivisionRepository _divisionRepository;
  final Uuid _uuid;

  @override
  Future<Either<Failure, List<DivisionEntity>>> call(
    SplitDivisionParams params,
  ) async {
    final validationFailure = await _validateParams(params);
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    final divisionResult = await _divisionRepository.getDivision(
      params.divisionId,
    );
    final sourceDivision = divisionResult.fold(
      (failure) => null,
      (division) => division,
    );

    if (sourceDivision == null) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Division not found',
          fieldErrors: {'divisionId': 'Invalid division ID'},
        ),
      );
    }

    final participantsResult = await _divisionRepository
        .getParticipantsForDivision(params.divisionId);
    final participants = participantsResult.fold(
      (failure) => <ParticipantEntry>[],
      (list) => list,
    );

    if (participants.length < 4) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage:
              'Division must have at least 4 participants to split',
          fieldErrors: {
            'participants': 'Minimum 4 participants required for split',
          },
        ),
      );
    }

    final distributed = _distributeParticipants(
      participants,
      params.distributionMethod,
    );
    final poolAParticipants = distributed[0];
    final poolBParticipants = distributed[1];

    final baseName = params.baseName ?? sourceDivision.name;
    final poolAName = '$baseName Pool A';
    final poolBName = '$baseName Pool B';

    final poolADivision = _buildPoolDivision(
      sourceDivision,
      poolAName,
      sourceDivision.displayOrder,
    );
    final poolBDivision = _buildPoolDivision(
      sourceDivision,
      poolBName,
      sourceDivision.displayOrder + 1,
    );

    final deletedSourceDivision = sourceDivision.copyWith(
      isDeleted: true,
      syncVersion: sourceDivision.syncVersion + 1,
      updatedAtTimestamp: DateTime.now(),
    );

    final results = await _divisionRepository.splitDivision(
      poolADivision: poolADivision,
      poolBDivision: poolBDivision,
      sourceDivision: deletedSourceDivision,
      poolAParticipants: poolAParticipants,
      poolBParticipants: poolBParticipants,
    );

    return results;
  }

  Future<ValidationFailure?> _validateParams(SplitDivisionParams params) async {
    final divisionResult = await _divisionRepository.getDivision(
      params.divisionId,
    );
    final division = divisionResult.fold((l) => null, (d) => d);

    if (division == null) {
      return const ValidationFailure(
        userFriendlyMessage: 'Division not found',
        fieldErrors: {'divisionId': 'Invalid division ID'},
      );
    }

    if (division.isDeleted) {
      return const ValidationFailure(
        userFriendlyMessage: 'Cannot split an already split/merged division',
        fieldErrors: {'divisionId': 'Division is no longer active'},
      );
    }

    if (division.isCombined) {
      return const ValidationFailure(
        userFriendlyMessage: 'Cannot split a merged division',
        fieldErrors: {'divisionId': 'Merged divisions cannot be split'},
      );
    }

    return null;
  }

  DivisionEntity _buildPoolDivision(
    DivisionEntity source,
    String name,
    int displayOrder,
  ) {
    return DivisionEntity(
      id: _uuid.v4(),
      tournamentId: source.tournamentId,
      name: name,
      category: source.category,
      gender: source.gender,
      ageMin: source.ageMin,
      ageMax: source.ageMax,
      weightMinKg: source.weightMinKg,
      weightMaxKg: source.weightMaxKg,
      beltRankMin: source.beltRankMin,
      beltRankMax: source.beltRankMax,
      bracketFormat: source.bracketFormat,
      isCustom: true,
      status: DivisionStatus.setup,
      isCombined: false,
      displayOrder: displayOrder,
      syncVersion: 1,
      isDeleted: false,
      isDemoData: source.isDemoData,
      createdAtTimestamp: DateTime.now(),
      updatedAtTimestamp: DateTime.now(),
    );
  }

  List<List<ParticipantEntry>> _distributeParticipants(
    List<ParticipantEntry> participants,
    SplitDistributionMethod method,
  ) {
    final shuffled = List<ParticipantEntry>.from(participants);

    if (method == SplitDistributionMethod.alphabetical) {
      shuffled.sort((a, b) => a.lastName.compareTo(b.lastName));
    } else {
      shuffled.shuffle(Random());
    }

    final midpoint = (shuffled.length / 2).ceil();
    return [shuffled.sublist(0, midpoint), shuffled.sublist(midpoint)];
  }
}
