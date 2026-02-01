/// Application-wide constants.
abstract class AppConstants {
  /// Application display name.
  static const String appName = 'TKD Brackets';
  
  /// Minimum supported participants for a bracket.
  static const int minBracketParticipants = 2;
  
  /// Maximum participants per bracket (free tier).
  static const int maxParticipantsFreeTier = 32;
  
  /// Maximum rings per tournament.
  static const int maxRingsPerTournament = 20;
}
