import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/bye_assignment_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/bye_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/bye_assignment_params.dart';
import 'package:tkd_brackets/core/error/failures.dart';

/// Pure algorithm service for determining optimal bye positions
/// in elimination brackets.
///
/// Uses standard tournament seeding positions to distribute byes
/// across the bracket, ensuring top seeds receive byes and
/// bye positions are not clustered in one half.
@injectable
class ByeAssignmentService {
  /// Computes bye assignments for the given parameters.
  ///
  /// Returns [Right] with [ByeAssignmentResult] on success.
  /// Returns [Left] with [ValidationFailure] if params are invalid.
  ///
  /// This is a **synchronous** operation.
  Either<Failure, ByeAssignmentResult> assignByes(
    ByeAssignmentParams params,
  ) {
    final n = params.participantCount;

    // Validation
    if (n < 2) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'At least 2 participants required for bye assignment.',
        ),
      );
    }

    if (params.seedOrder != null && params.seedOrder!.length != n) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Seed order length must match participant count.',
        ),
      );
    }

    // Calculate bracketSize using bitLength (matches seeding engine pattern)
    // 1 << (n - 1).bitLength is the next power of 2 >= n
    final totalRounds = (n - 1).bitLength;
    final bracketSize = 1 << totalRounds; // pow(2, totalRounds)
    final numByes = bracketSize - n;

    // Zero byes — return immediately
    if (numByes == 0) {
      return Right(ByeAssignmentResult(
        byeCount: 0,
        bracketSize: bracketSize,
        totalRounds: totalRounds,
        byePlacements: const [],
        byeSlots: const <int>{},
      ));
    }

    // Build seed → slot mapping
    final seedToSlot = _buildSeedToSlotMap(bracketSize);
    final byePlacements = <ByePlacement>[];
    final byeSlots = <int>{};

    // Missing seeds are the lowest-ranked: bracketSize, bracketSize-1, etc.
    // Their paired opponent (the top seed getting the bye) is: bracketSize+1 - missingSeed
    for (var byeIdx = 0; byeIdx < numByes; byeIdx++) {
      final missingSeed = bracketSize - byeIdx;           // e.g., 8, 7, 6...
      final byeSlot = seedToSlot[missingSeed]!;            // Where the missing seed WOULD be
      byeSlots.add(byeSlot);

      final pairedSeed = bracketSize + 1 - missingSeed;    // The top seed getting bye (1, 2, 3...)
      final participantSlot = seedToSlot[pairedSeed]!;     // Where the top seed sits

      final participantId = (params.seedOrder != null && byeIdx < params.seedOrder!.length)
          ? params.seedOrder![byeIdx]
          : null;

      byePlacements.add(ByePlacement(
        participantId: participantId,
        seedPosition: pairedSeed,
        bracketSlot: participantSlot,
        byeSlot: byeSlot,
      ));
    }

    return Right(ByeAssignmentResult(
      byeCount: numByes,
      bracketSize: bracketSize,
      totalRounds: totalRounds,
      byePlacements: byePlacements,
      byeSlots: byeSlots,
    ));
  }

  /// Builds a map from seed number (1-indexed) to bracket slot (1-indexed).
  /// Uses standard tournament seeding pattern.
  Map<int, int> _buildSeedToSlotMap(int bracketSize) {
    // Build the ordered list of seeds as they appear in bracket slots.
    // seedOrder[i] = seed number in slot (i+1).
    final seedOrder = _standardSeedOrder(bracketSize);

    // Invert: seed → slot
    final map = <int, int>{};
    for (var slot = 0; slot < seedOrder.length; slot++) {
      map[seedOrder[slot]] = slot + 1; // 1-indexed slots
    }
    return map;
  }

  /// Returns standard seed ordering for bracket slots.
  /// Index 0 = slot 1, index 1 = slot 2, etc.
  /// 
  /// Recursive: base case [1, 2], then interleave with mirrors.
  List<int> _standardSeedOrder(int bracketSize) {
    if (bracketSize == 2) return [1, 2];

    final half = bracketSize ~/ 2;
    final halfOrder = _standardSeedOrder(half);

    final result = <int>[];
    for (final seed in halfOrder) {
      result.add(seed);                      // Upper half seed
      result.add(bracketSize + 1 - seed);    // Mirror (opponent)
    }
    return result;
  }
}
