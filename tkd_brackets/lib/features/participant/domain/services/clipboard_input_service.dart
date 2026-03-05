import 'package:injectable/injectable.dart';

/// Converts tab-delimited spreadsheet paste data to comma-delimited CSV.
///
/// Detects if input is tab-delimited (from spreadsheet copy-paste) and
/// converts to standard CSV format compatible with `CSVParserService`.
/// If input is already comma-delimited, returns it unchanged.
@lazySingleton
class ClipboardInputService {
  /// Normalizes [rawInput] to comma-delimited CSV.
  ///
  /// Detection: If the first non-empty line contains a tab character,
  /// the entire input is treated as tab-delimited and converted.
  /// Otherwise returns [rawInput] unchanged.
  String normalizeToCSV(String rawInput) {
    if (rawInput.trim().isEmpty) return rawInput;

    // Split on line breaks, preserving structure
    final lines = rawInput.split(RegExp(r'\r?\n'));

    // Find first non-empty line for delimiter detection
    final firstNonEmpty = lines.firstWhere(
      (l) => l.trim().isNotEmpty,
      orElse: () => '',
    );

    // If no tabs found, assume already CSV — return unchanged
    if (!firstNonEmpty.contains('\t')) return rawInput;

    // Convert tab-delimited → comma-delimited CSV with RFC 4180 quoting
    final buffer = StringBuffer();
    for (final line in lines) {
      // Preserve empty lines as-is (CSVParserService._splitLines skips them)
      if (line.trim().isEmpty) continue;
      final cells = line.split('\t');
      for (var i = 0; i < cells.length; i++) {
        if (i > 0) buffer.write(',');
        buffer.write(_quoteIfNeeded(cells[i]));
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  /// Wraps [cell] in double quotes if it contains special characters
  /// per RFC 4180: comma, double quote, or newline.
  /// Existing double quotes are escaped as "".
  String _quoteIfNeeded(String cell) {
    if (cell.contains(',') || cell.contains('"') || cell.contains('\n')) {
      return '"${cell.replaceAll('"', '""')}"';
    }
    return cell;
  }
}
