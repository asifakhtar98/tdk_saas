import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/division/domain/entities/belt_rank.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/auto_assignment_match.dart';

/// Service for evaluating participant-to-division matches based on criteria.
///
/// Matching rules:
/// - **Null values on participant** = always matches (e.g., no weight = any weight class)
/// - **Null constraints on division** = no restriction (e.g., no weight limits = all weights)
/// - All criteria must pass for a match (AND logic, not OR)
@injectable
class AutoAssignmentService {
  /// Evaluates whether a participant matches a division's criteria.
  ///
  /// Returns `null` if any required criteria fails.
  /// Returns [AutoAssignmentMatch] with match details if all criteria pass.
  AutoAssignmentMatch? evaluateMatch(
    ParticipantEntity participant,
    DivisionEntity division,
  ) {
    final criteriaMatched = <String, bool>{};
    var matchScore = 0;

    if (!_checkAgeMatch(participant, division)) {
      return null;
    }
    criteriaMatched['age'] = true;
    matchScore++;

    if (!_checkGenderMatch(participant, division)) {
      return null;
    }
    criteriaMatched['gender'] = true;
    matchScore++;

    if (!_checkWeightMatch(participant, division)) {
      return null;
    }
    if (division.weightMinKg != null || division.weightMaxKg != null) {
      criteriaMatched['weight'] = true;
      matchScore++;
    }

    if (!_checkBeltMatch(participant, division)) {
      return null;
    }
    if (division.beltRankMin != null || division.beltRankMax != null) {
      criteriaMatched['belt'] = true;
      matchScore++;
    }

    return AutoAssignmentMatch(
      participantId: participant.id,
      divisionId: division.id,
      participantName: '${participant.firstName} ${participant.lastName}',
      divisionName: division.name,
      matchScore: matchScore,
      criteriaMatched: criteriaMatched,
    );
  }

  String determineUnmatchedReason(
    ParticipantEntity participant,
    List<DivisionEntity> divisions,
  ) {
    if (divisions.isEmpty) {
      return 'No divisions exist in tournament';
    }

    final hasMatchingGender = divisions.any(
      (d) =>
          d.gender == DivisionGender.mixed ||
          (participant.gender != null &&
              d.gender.value == participant.gender!.value),
    );
    if (!hasMatchingGender) {
      return 'No divisions with matching gender criteria';
    }

    final hasMatchingAge = divisions.any((d) {
      final age = participant.age;
      if (age == null) return true;
      if (d.ageMin != null && age < d.ageMin!) return false;
      if (d.ageMax != null && age > d.ageMax!) return false;
      return true;
    });
    if (!hasMatchingAge) {
      return 'No divisions with matching age range';
    }

    final hasMatchingWeight = divisions.any((d) {
      if (participant.weightKg == null) return true;
      if (d.weightMinKg != null && participant.weightKg! < d.weightMinKg!) {
        return false;
      }
      if (d.weightMaxKg != null && participant.weightKg! > d.weightMaxKg!) {
        return false;
      }
      return true;
    });
    if (!hasMatchingWeight) {
      return 'No divisions with matching weight class';
    }

    final hasMatchingBelt = divisions.any((d) {
      if (participant.beltRank == null || participant.beltRank!.isEmpty) {
        return true;
      }
      if ((d.beltRankMin == null || d.beltRankMin!.isEmpty) &&
          (d.beltRankMax == null || d.beltRankMax!.isEmpty)) {
        return true;
      }
      return _checkBeltMatch(participant, d);
    });
    if (!hasMatchingBelt) {
      return 'No divisions with matching belt rank';
    }

    return 'No suitable division found';
  }

  /// Returns true if participant's age falls within division's age range.
  /// Null age on participant = always matches.
  /// Null bounds on division = no age restriction.
  bool _checkAgeMatch(ParticipantEntity p, DivisionEntity d) {
    final age = p.age;
    if (age == null) return true;
    if (d.ageMin != null && age < d.ageMin!) return false;
    if (d.ageMax != null && age > d.ageMax!) return false;
    return true;
  }

  /// Returns true if participant's gender matches division's gender.
  /// Null gender on participant = always matches.
  /// DivisionGender.mixed accepts all participants.
  bool _checkGenderMatch(ParticipantEntity p, DivisionEntity d) {
    if (d.gender == DivisionGender.mixed) return true;
    if (p.gender == null) return true;
    return p.gender!.value == d.gender.value;
  }

  /// Returns true if participant's weight falls within division's weight range.
  /// Null weight on participant = always matches.
  /// Null bounds on division = no weight restriction.
  bool _checkWeightMatch(ParticipantEntity p, DivisionEntity d) {
    if (p.weightKg == null) return true;
    if (d.weightMinKg != null && p.weightKg! < d.weightMinKg!) return false;
    if (d.weightMaxKg != null && p.weightKg! > d.weightMaxKg!) return false;
    return true;
  }

  /// Returns true if participant's belt falls within division's belt range.
  /// Uses BeltRank.order for comparison.
  /// Null/empty belt on participant = always matches.
  /// Null/empty bounds on division = no belt restriction.
  /// Unknown belt strings (BeltRank.fromString returns null) = always matches.
  bool _checkBeltMatch(ParticipantEntity p, DivisionEntity d) {
    if (p.beltRank == null || p.beltRank!.isEmpty) return true;
    if ((d.beltRankMin == null || d.beltRankMin!.isEmpty) &&
        (d.beltRankMax == null || d.beltRankMax!.isEmpty)) {
      return true;
    }

    final participantBelt = BeltRank.fromString(p.beltRank!);
    if (participantBelt == null) return true;

    if (d.beltRankMin != null && d.beltRankMin!.isNotEmpty) {
      final minBelt = BeltRank.fromString(d.beltRankMin!);
      if (minBelt != null && participantBelt.order < minBelt.order) {
        return false;
      }
    }

    if (d.beltRankMax != null && d.beltRankMax!.isNotEmpty) {
      final maxBelt = BeltRank.fromString(d.beltRankMax!);
      if (maxBelt != null && participantBelt.order > maxBelt.order) {
        return false;
      }
    }

    return true;
  }
}
