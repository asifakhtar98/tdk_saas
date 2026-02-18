import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/division/domain/entities/conflict_warning.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';

@injectable
class ConflictDetectionService {
  ConflictDetectionService(this._divisionRepository);

  final DivisionRepository _divisionRepository;

  String _getParticipantKey(ParticipantEntry participant) {
    return participant.id;
  }

  Future<Either<Failure, List<ConflictWarning>>> detectConflicts(
    String tournamentId,
  ) async {
    final divisionsResult = await _divisionRepository.getDivisionsForTournament(
      tournamentId,
    );

    final divisions = divisionsResult.fold(
      (failure) => <DivisionEntity>[],
      (divs) => divs
          .where((d) => d.isDeleted == false && d.assignedRingNumber != null)
          .toList(),
    );

    if (divisions.isEmpty) {
      return const Right([]);
    }

    final allParticipantsResult = await _getAllParticipantsForDivisions(
      divisions.map((d) => d.id).toList(),
    );

    final allParticipants = allParticipantsResult.fold(
      (failure) => <ParticipantEntry>[],
      (participants) =>
          participants.where((p) => p.isDeleted == false).toList(),
    );

    final participantDivisions = _buildParticipantDivisionsMap(
      allParticipants,
      divisions,
    );

    final List<ConflictWarning> conflicts = [];
    int conflictId = 1;

    for (final entry in participantDivisions.entries) {
      final participantKey = entry.key;
      final participantDivs = entry.value;

      final firstParticipant = allParticipants.firstWhere(
        (p) => _getParticipantKey(p) == participantKey,
      );
      final participantName =
          '${firstParticipant.firstName} ${firstParticipant.lastName}';

      final ringGroups = <int?, List<DivisionEntity>>{};

      for (final div in participantDivs) {
        final ring = div.assignedRingNumber;
        ringGroups.putIfAbsent(ring, () => []).add(div);
      }

      for (final ringEntry in ringGroups.entries) {
        if (ringEntry.value.length >= 2) {
          final divs = ringEntry.value;

          for (int i = 0; i < divs.length; i++) {
            for (int j = i + 1; j < divs.length; j++) {
              conflicts.add(
                ConflictWarning(
                  id: 'conflict-$conflictId',
                  participantId: firstParticipant.id,
                  participantName: participantName,
                  dojangName: firstParticipant.schoolOrDojangName,
                  divisionId1: divs[i].id,
                  divisionName1: divs[i].name,
                  ringNumber1: divs[i].assignedRingNumber,
                  divisionId2: divs[j].id,
                  divisionName2: divs[j].name,
                  ringNumber2: divs[j].assignedRingNumber,
                  conflictType: ConflictType.sameRing,
                ),
              );
              conflictId++;
            }
          }
        }
      }
    }

    return Right(conflicts);
  }

  Future<Either<Failure, List<ParticipantEntry>>>
  _getAllParticipantsForDivisions(List<String> divisionIds) async {
    if (divisionIds.isEmpty) {
      return const Right([]);
    }

    try {
      final result = await _divisionRepository.getParticipantsForDivisions(
        divisionIds,
      );
      return result;
    } catch (e) {
      return Left(LocalCacheAccessFailure(technicalDetails: e.toString()));
    }
  }

  Map<String, List<DivisionEntity>> _buildParticipantDivisionsMap(
    List<ParticipantEntry> participants,
    List<DivisionEntity> divisions,
  ) {
    final Map<String, List<DivisionEntity>> participantDivisions = {};

    for (final participant in participants) {
      final key = _getParticipantKey(participant);
      final matchingDivisions = divisions.where(
        (d) => d.id == participant.divisionId,
      );

      if (matchingDivisions.isEmpty) continue;

      final division = matchingDivisions.first;
      participantDivisions.putIfAbsent(key, () => []).add(division);
    }

    return participantDivisions;
  }

  Future<Either<Failure, bool>> hasConflicts(String tournamentId) async {
    final result = await detectConflicts(tournamentId);

    return result.fold(
      (failure) => Left(failure),
      (conflicts) => Right(conflicts.isNotEmpty),
    );
  }

  Future<Either<Failure, int>> getConflictCount(String tournamentId) async {
    final result = await detectConflicts(tournamentId);

    return result.fold(
      (failure) => Left(failure),
      (conflicts) => Right(conflicts.length),
    );
  }

  Future<Either<Failure, List<ConflictWarning>>> detectConflictsForParticipant(
    String tournamentId,
    String participantId,
  ) async {
    final divisionsResult = await _divisionRepository.getDivisionsForTournament(
      tournamentId,
    );

    final divisionsList = divisionsResult.fold(
      (failure) => <DivisionEntity>[],
      (divs) => divs
          .where((d) => d.isDeleted == false && d.assignedRingNumber != null)
          .toList(),
    );

    if (divisionsList.isEmpty) {
      return const Right([]);
    }

    final participantsResult = await _getAllParticipantsForDivisions(
      divisionsList.map((d) => d.id).toList(),
    );

    final participantList = participantsResult.fold(
      (failure) => <ParticipantEntry>[],
      (participants) =>
          participants.where((p) => p.id == participantId).toList(),
    );

    if (participantList.isEmpty) {
      return const Right([]);
    }

    final participant = participantList.first;
    final participantDivs = divisionsList
        .where((d) => d.id == participant.divisionId)
        .toList();

    final ringGroups = <int?, List<DivisionEntity>>{};

    for (final div in participantDivs) {
      final ring = div.assignedRingNumber;
      ringGroups.putIfAbsent(ring, () => []).add(div);
    }

    final List<ConflictWarning> conflicts = [];
    int conflictId = 1;
    final participantName = '${participant.firstName} ${participant.lastName}';

    for (final ringEntry in ringGroups.entries) {
      if (ringEntry.value.length >= 2) {
        final divs = ringEntry.value;

        for (int i = 0; i < divs.length; i++) {
          for (int j = i + 1; j < divs.length; j++) {
            conflicts.add(
              ConflictWarning(
                id: 'conflict-$conflictId',
                participantId: participantId,
                participantName: participantName,
                dojangName: participant.schoolOrDojangName,
                divisionId1: divs[i].id,
                divisionName1: divs[i].name,
                ringNumber1: divs[i].assignedRingNumber,
                divisionId2: divs[j].id,
                divisionName2: divs[j].name,
                ringNumber2: divs[j].assignedRingNumber,
                conflictType: ConflictType.sameRing,
              ),
            );
            conflictId++;
          }
        }
      }
    }

    return Right(conflicts);
  }
}
