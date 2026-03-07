import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/ranked_seeding_entry.dart';
import 'package:tkd_brackets/core/error/failures.dart';

/// Parses ranked seeding data from CSV or JSON string content.
///
/// Supports two formats:
/// - **CSV:** Header row required with columns `Name`, `Club`, `Rank`
///   (case-insensitive). Club column is optional.
/// - **JSON:** Array of objects: `[{"name": "...", "club": "...", "rank": N}]`
///   Club field is optional.
@injectable
class RankedSeedingFileParser {
  /// Attempts to parse the given [content] as ranked seeding data.
  ///
  /// Automatically detects format:
  /// - If content starts with `[` (trimmed), treats as JSON
  /// - Otherwise treats as CSV
  ///
  /// Returns [Left(ValidationFailure)] if parsing fails.
  /// Returns [Right(List<RankedSeedingEntry>)] on success.
  Either<Failure, List<RankedSeedingEntry>> parse(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Ranking file content is empty.',
        ),
      );
    }

    if (trimmed.startsWith('[')) {
      return _parseJson(trimmed);
    }
    return _parseCsv(trimmed);
  }

  Either<Failure, List<RankedSeedingEntry>> _parseJson(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! List) {
        return const Left(
          ValidationFailure(
            userFriendlyMessage: 'JSON ranking data must be an array.',
          ),
        );
      }

      final entries = <RankedSeedingEntry>[];
      for (var i = 0; i < decoded.length; i++) {
        final item = decoded[i];
        if (item is! Map<String, dynamic>) {
          return Left(
            ValidationFailure(
              userFriendlyMessage: 'Invalid entry at index $i: expected object.',
            ),
          );
        }
        final name = item['name'];
        final rank = item['rank'];
        if (name is! String || name.trim().isEmpty) {
          return Left(
            ValidationFailure(
              userFriendlyMessage: 'Missing or empty "name" at index $i.',
            ),
          );
        }
        if (rank is! int) {
          return Left(
            ValidationFailure(
              userFriendlyMessage: 'Missing or non-integer "rank" at index $i.',
            ),
          );
        }
        final club = item['club'];
        entries.add(RankedSeedingEntry(
          name: name.trim(),
          rank: rank,
          club: (club is String && club.trim().isNotEmpty) ? club.trim() : null,
        ));
      }

      if (entries.isEmpty) {
        return const Left(
          ValidationFailure(
            userFriendlyMessage: 'JSON ranking array is empty.',
          ),
        );
      }
      return Right(entries);
    } on FormatException catch (e) {
      return Left(
        ValidationFailure(
          userFriendlyMessage: 'Invalid JSON format.',
          technicalDetails: e.message,
        ),
      );
    }
  }

  Either<Failure, List<RankedSeedingEntry>> _parseCsv(String content) {
    // Normalize line endings
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n').where((l) => l.trim().isNotEmpty).toList();

    if (lines.isEmpty) {
      return const Left(
        ValidationFailure(userFriendlyMessage: 'CSV content has no data rows.'),
      );
    }

    // Parse header row (case-insensitive)
    final headers = lines.first.split(',').map((h) => h.trim().toLowerCase()).toList();
    final nameIdx = headers.indexOf('name');
    final rankIdx = headers.indexOf('rank');
    final clubIdx = headers.indexOf('club'); // -1 if not present = OK

    if (nameIdx < 0) {
      return const Left(
        ValidationFailure(userFriendlyMessage: 'CSV header missing required "Name" column.'),
      );
    }
    if (rankIdx < 0) {
      return const Left(
        ValidationFailure(userFriendlyMessage: 'CSV header missing required "Rank" column.'),
      );
    }

    final entries = <RankedSeedingEntry>[];
    for (var i = 1; i < lines.length; i++) {
      final values = lines[i].split(',').map((v) => v.trim()).toList();
      // Skip rows with insufficient columns
      if (values.length <= nameIdx || values.length <= rankIdx) continue;

      final name = values[nameIdx];
      if (name.isEmpty) continue; // Skip rows with empty name

      final rankStr = values[rankIdx];
      final rank = int.tryParse(rankStr);
      if (rank == null) {
        return Left(
          ValidationFailure(
            userFriendlyMessage: 'Invalid rank "$rankStr" at row ${i + 1}.',
          ),
        );
      }

      final club = (clubIdx >= 0 && values.length > clubIdx && values[clubIdx].isNotEmpty)
          ? values[clubIdx]
          : null;

      entries.add(RankedSeedingEntry(name: name, rank: rank, club: club));
    }

    if (entries.isEmpty) {
      return const Left(
        ValidationFailure(userFriendlyMessage: 'CSV contains no valid data rows.'),
      );
    }
    return Right(entries);
  }
}
