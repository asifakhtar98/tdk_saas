import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/participant/data/models/participant_model.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/services/duplicate_match.dart';
import 'package:tkd_brackets/features/participant/domain/services/duplicate_match_type.dart';
import 'package:tkd_brackets/features/participant/domain/services/participant_check_data.dart';

/// Confidence score constants for duplicate detection.
class DuplicateConfidence {
  static const double exactMatch = 1;
  static const double fuzzyDistance1 = 0.9;
  static const double fuzzyDistance2 = 0.7;
  static const double dobBonus = 0.1;
  static const double differentDojang = 0.1;
  static const double dobPrimaryMatch = 0.5;
}

/// Service for detecting potential duplicate participants.
///
/// Compares participant data using exact matching, fuzzy name matching
/// (Levenshtein distance), and date of birth comparison.
@lazySingleton
class DuplicateDetectionService {
  final DivisionRepository _divisionRepository;

  DuplicateDetectionService(this._divisionRepository);

  /// Checks for duplicate participants in a tournament.
  ///
  /// Returns a list of [DuplicateMatch] for each potential duplicate found,
  /// sorted by confidence score (highest first).
  ///
  /// If [existingParticipants] is provided, uses that list instead of
  /// fetching from the repository.
  Future<Either<Failure, List<DuplicateMatch>>> checkForDuplicates({
    required String tournamentId,
    required ParticipantCheckData newParticipant,
    List<ParticipantEntity>? existingParticipants,
  }) async {
    final List<ParticipantEntity> participants;

    if (existingParticipants != null) {
      participants = existingParticipants;
    } else {
      final result = await _getExistingParticipantsForTournament(tournamentId);
      if (result.isLeft()) {
        return result.fold(Left.new, (_) => const Right([]));
      }
      participants = result.getOrElse((_) => []);
    }

    final matches = <DuplicateMatch>[];
    final normalizedNewFirst = _normalizeString(newParticipant.firstName);
    final normalizedNewLast = _normalizeString(newParticipant.lastName);
    final normalizedNewDojang = newParticipant.schoolOrDojangName;

    for (final existing in participants) {
      final match = _checkParticipant(
        existing: existing,
        normalizedNewFirst: normalizedNewFirst,
        normalizedNewLast: normalizedNewLast,
        normalizedNewDojang: normalizedNewDojang,
        newDob: newParticipant.dateOfBirth,
      );
      if (match != null) {
        matches.add(match);
      }
    }

    matches.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));

    return Right(matches);
  }

  /// Batch duplicate check for CSV import preview.
  ///
  /// Returns a map of source row number to list of potential duplicates.
  /// If [sourceRowNumbers] is provided, uses those for keys; otherwise
  /// uses 1-based index.
  ///
  /// Note: If fetching existing participants fails, returns an empty map.
  /// This differs from [checkForDuplicates] which propagates the failure.
  Future<Either<Failure, Map<int, List<DuplicateMatch>>>>
  checkForDuplicatesBatch({
    required String tournamentId,
    required List<ParticipantCheckData> newParticipants,
    List<int>? sourceRowNumbers,
  }) async {
    final existingResult = await _getExistingParticipantsForTournament(
      tournamentId,
    );

    if (existingResult.isLeft()) {
      return const Right({});
    }

    final existingParticipants = existingResult.getOrElse((_) => []);

    final result = <int, List<DuplicateMatch>>{};

    for (var i = 0; i < newParticipants.length; i++) {
      final newParticipant = newParticipants[i];
      final rowNumber = sourceRowNumbers != null && i < sourceRowNumbers.length
          ? sourceRowNumbers[i]
          : i + 1;

      final checkResult = await checkForDuplicates(
        tournamentId: tournamentId,
        newParticipant: newParticipant,
        existingParticipants: existingParticipants,
      );

      checkResult.fold(
        (failure) => result[rowNumber] = [],
        (matches) => result[rowNumber] = matches,
      );
    }

    return Right(result);
  }

  Future<Either<Failure, List<ParticipantEntity>>>
  _getExistingParticipantsForTournament(String tournamentId) async {
    final divisionsResult = await _divisionRepository.getDivisionsForTournament(
      tournamentId,
    );

    final divisions = divisionsResult.fold(
      (failure) => <DivisionEntity>[],
      (divisions) => divisions,
    );

    if (divisions.isEmpty) {
      return const Right([]);
    }

    final divisionIds = divisions.map((d) => d.id).toList();

    final participantsResult = await _divisionRepository
        .getParticipantsForDivisions(divisionIds);

    return participantsResult.fold(
      Left.new,
      (entries) => Right(
        entries
            .map(
              (entry) =>
                  ParticipantModel.fromDriftEntry(entry).convertToEntity(),
            )
            .toList(),
      ),
    );
  }

  String _normalizeString(String input) {
    return input.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  int _calculateLevenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final matrix = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => 0),
    );

    for (var i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[a.length][b.length];
  }

  bool _checkDojangMatch(String? dojang1, String? dojang2) {
    if (dojang1 == null || dojang1.trim().isEmpty) return false;
    if (dojang2 == null || dojang2.trim().isEmpty) return false;
    return _normalizeString(dojang1) == _normalizeString(dojang2);
  }

  DuplicateMatch? _checkParticipant({
    required ParticipantEntity existing,
    required String normalizedNewFirst,
    required String normalizedNewLast,
    required String normalizedNewDojang,
    required DateTime? newDob,
  }) {
    final normalizedExistingFirst = _normalizeString(existing.firstName);
    final normalizedExistingLast = _normalizeString(existing.lastName);

    final sameDojang = _checkDojangMatch(
      normalizedNewDojang,
      existing.schoolOrDojangName,
    );
    final newDobExists = newDob != null;
    final existingDobExists = existing.dateOfBirth != null;
    final sameDob =
        newDobExists &&
        existingDobExists &&
        _isSameDate(newDob, existing.dateOfBirth!);

    final firstDistance = _calculateLevenshteinDistance(
      normalizedNewFirst,
      normalizedExistingFirst,
    );
    final lastDistance = _calculateLevenshteinDistance(
      normalizedNewLast,
      normalizedExistingLast,
    );

    final exactFirst = firstDistance == 0;
    final exactLast = lastDistance == 0;
    final exactNameMatch = exactFirst && exactLast;

    if (exactNameMatch && sameDojang) {
      final matchedFields = <String, String>{
        'firstName': existing.firstName,
        'lastName': existing.lastName,
        'schoolOrDojangName': existing.schoolOrDojangName ?? '',
      };
      if (sameDob) {
        matchedFields['dateOfBirth'] = _formatDate(existing.dateOfBirth!);
      }

      return DuplicateMatch(
        existingParticipant: existing,
        matchType: DuplicateMatchType.exact,
        confidenceScore: DuplicateConfidence.exactMatch,
        matchedFields: matchedFields,
      );
    }

    final fuzzyFirstMatch = !exactFirst && firstDistance <= 2 && exactLast;
    final fuzzyLastMatch = !exactLast && lastDistance <= 2 && exactFirst;

    if ((fuzzyFirstMatch || fuzzyLastMatch) && sameDojang) {
      final nameDistance = fuzzyFirstMatch ? firstDistance : lastDistance;
      final baseScore = _calculateFuzzyScore(nameDistance);
      final finalScore = sameDob
          ? (baseScore + DuplicateConfidence.dobBonus).clamp(0.0, 1.0)
          : baseScore;

      final matchedFields = <String, String>{
        'firstName': existing.firstName,
        'lastName': existing.lastName,
        'schoolOrDojangName': existing.schoolOrDojangName ?? '',
      };
      if (sameDob) {
        matchedFields['dateOfBirth'] = _formatDate(existing.dateOfBirth!);
      }

      return DuplicateMatch(
        existingParticipant: existing,
        matchType: DuplicateMatchType.fuzzy,
        confidenceScore: finalScore,
        matchedFields: matchedFields,
      );
    }

    // DOB as secondary indicator: only when same dojang AND one name matches
    if (sameDob && sameDojang && (exactFirst || exactLast)) {
      return DuplicateMatch(
        existingParticipant: existing,
        matchType: DuplicateMatchType.dateOfBirth,
        confidenceScore: DuplicateConfidence.dobPrimaryMatch,
        matchedFields: {
          'dateOfBirth': _formatDate(existing.dateOfBirth!),
          'schoolOrDojangName': existing.schoolOrDojangName ?? '',
          if (exactFirst) 'firstName': existing.firstName,
          if (exactLast) 'lastName': existing.lastName,
        },
      );
    }

    if (exactNameMatch && !sameDojang) {
      return DuplicateMatch(
        existingParticipant: existing,
        matchType: DuplicateMatchType.exact,
        confidenceScore: DuplicateConfidence.differentDojang,
        matchedFields: {
          'firstName': existing.firstName,
          'lastName': existing.lastName,
        },
      );
    }

    return null;
  }

  double _calculateFuzzyScore(int distance) {
    switch (distance) {
      case 0:
        return DuplicateConfidence.exactMatch;
      case 1:
        return DuplicateConfidence.fuzzyDistance1;
      case 2:
        return DuplicateConfidence.fuzzyDistance2;
      default:
        return 0;
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
