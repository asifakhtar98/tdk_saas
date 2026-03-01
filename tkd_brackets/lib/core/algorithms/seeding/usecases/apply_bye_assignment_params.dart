import 'package:flutter/foundation.dart' show immutable;
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';

/// Parameters for ApplyByeAssignmentUseCase.
@immutable
class ApplyByeAssignmentParams {
  /// Creates [ApplyByeAssignmentParams].
  const ApplyByeAssignmentParams({
    required this.divisionId,
    required this.participants,
    this.bracketFormat = BracketFormat.singleElimination,
  });

  /// Division ID this bye assignment is for.
  final String divisionId;

  /// Participants in seed order (index 0 = top seed).
  final List<SeedingParticipant> participants;

  /// Bracket format. Must be singleElimination or doubleElimination.
  /// Round robin does not use byes.
  final BracketFormat bracketFormat;
}
