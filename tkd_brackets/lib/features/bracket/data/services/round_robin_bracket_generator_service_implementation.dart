import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/services/round_robin_bracket_generator_service.dart';
import 'package:uuid/uuid.dart';

/// Implementation of [RoundRobinBracketGeneratorService].
@LazySingleton(as: RoundRobinBracketGeneratorService)
class RoundRobinBracketGeneratorServiceImplementation
    implements RoundRobinBracketGeneratorService {
  RoundRobinBracketGeneratorServiceImplementation(this._uuid);

  final Uuid _uuid;

  @override
  BracketGenerationResult generate({
    required String divisionId,
    required List<String> participantIds,
    required String bracketId,
    String poolIdentifier = 'A',
  }) {
    final n = participantIds.length;
    final now = DateTime.now();

    // For odd N, add a phantom BYE participant (null) to make it even.
    // For even N, use participants as-is.
    final isOdd = n.isOdd;
    final effectiveN = isOdd ? n + 1 : n;

    // Build participant list: real IDs + optional null for BYE.
    // Index into this list to get participant ID (or null for BYE).
    final participants = <String?>[
      ...participantIds,
      if (isOdd) null, // phantom BYE at the end
    ];

    final totalRounds = effectiveN - 1;
    final matchesPerRound = effectiveN ~/ 2;

    // Pre-generate ALL match IDs upfront (same pattern as Story 5.4/5.5).
    final totalMatchSlots = totalRounds * matchesPerRound;
    final matchIds = List.generate(totalMatchSlots, (_) => _uuid.v4());

    final matches = <MatchEntity>[];
    var matchIdIdx = 0;

    // Circle method: fix position 0 (pivot), rotate positions 1..effectiveN-1.
    // positions[i] is an index into the participants list.
    final positions = List<int>.generate(effectiveN, (i) => i);

    for (var round = 0; round < totalRounds; round++) {
      for (var match = 0; match < matchesPerRound; match++) {
        // Fold: pair positions[match] with positions[effectiveN - 1 - match]
        final topIdx = positions[match];
        final bottomIdx = positions[effectiveN - 1 - match];

        final topParticipant = participants[topIdx];
        final bottomParticipant = participants[bottomIdx];

        final matchId = matchIds[matchIdIdx++];
        final roundNumber = round + 1; // 1-indexed
        final matchNumber = match + 1; // 1-indexed

        // Check if this is a bye match (one participant is BYE phantom)
        final isBye = topParticipant == null || bottomParticipant == null;

        if (isBye) {
          final realParticipant = topParticipant ?? bottomParticipant;
          matches.add(
            MatchEntity(
              id: matchId,
              bracketId: bracketId,
              roundNumber: roundNumber,
              matchNumberInRound: matchNumber,
              participantRedId: realParticipant,
              // participantBlueId defaults to null (bye)
              winnerId: realParticipant,
              status: MatchStatus.completed,
              resultType: MatchResultType.bye,
              completedAtTimestamp: now,
              createdAtTimestamp: now,
              updatedAtTimestamp: now,
            ),
          );
        } else {
          matches.add(
            MatchEntity(
              id: matchId,
              bracketId: bracketId,
              roundNumber: roundNumber,
              matchNumberInRound: matchNumber,
              participantRedId: topParticipant,
              participantBlueId: bottomParticipant,
              status: MatchStatus.pending,
              createdAtTimestamp: now,
              updatedAtTimestamp: now,
              // winnerAdvancesToMatchId: null (round robin — no tree!)
              // loserAdvancesToMatchId: null (round robin — no tree!)
            ),
          );
        }
      }

      // Rotate positions[1..effectiveN-1] clockwise by one position.
      // Position 0 (pivot) is FIXED — never moves.
      // Example: [0, 1, 2, 3, 4, 5] → [0, 5, 1, 2, 3, 4]
      final last = positions[effectiveN - 1];
      for (var i = effectiveN - 1; i > 1; i--) {
        positions[i] = positions[i - 1];
      }
      positions[1] = last;
    }

    // Create the bracket entity.
    final bracket = BracketEntity(
      id: bracketId,
      divisionId: divisionId,
      bracketType: BracketType.pool,
      totalRounds: totalRounds,
      poolIdentifier: poolIdentifier,
      createdAtTimestamp: now,
      updatedAtTimestamp: now,
      generatedAtTimestamp: now,
      bracketDataJson: {'roundRobin': true, 'participantCount': n},
    );

    return BracketGenerationResult(bracket: bracket, matches: matches);
  }
}
