/// Constants for demo mode data seeding.
///
/// Uses predetermined UUIDs for test reproducibility.
/// Demo data allows users to explore features without creating an account.
abstract class DemoDataConstants {
  // ─────────────────────────────────────────────────────────────────────────
  // Core Entity UUIDs
  // ─────────────────────────────────────────────────────────────────────────

  /// Demo user (owner role) UUID.
  static const String demoUserId = '00000000-0000-0000-0000-000000000000';

  /// Demo organization UUID.
  static const String demoOrganizationId =
      '00000000-0000-0000-0000-000000000001';

  /// Demo tournament UUID.
  static const String demoTournamentId = '00000000-0000-0000-0000-000000000002';

  /// Demo division UUID.
  static const String demoDivisionId = '00000000-0000-0000-0000-000000000003';

  // ─────────────────────────────────────────────────────────────────────────
  // Participant UUIDs (8 from 4 dojangs - 2 each)
  // ─────────────────────────────────────────────────────────────────────────

  /// UUIDs for 8 demo participants.
  static const List<String> demoParticipantIds = [
    '00000000-0000-0000-0000-000000000010', // Min-jun Kim, Dragon
    '00000000-0000-0000-0000-000000000011', // Seo-yeon Park, Dragon
    '00000000-0000-0000-0000-000000000012', // Ji-hoon Lee, Phoenix
    '00000000-0000-0000-0000-000000000013', // Ha-eun Choi, Phoenix
    '00000000-0000-0000-0000-000000000014', // Ethan Johnson, Tiger
    '00000000-0000-0000-0000-000000000015', // Sophia Williams, Tiger
    '00000000-0000-0000-0000-000000000016', // Jacob Martinez, Eagle
    '00000000-0000-0000-0000-000000000017', // Emma Davis, Eagle
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // Sample Dojangs
  // ─────────────────────────────────────────────────────────────────────────

  /// Sample dojang names for demo participants.
  /// 4 dojangs with 2 participants each enables dojang separation demo.
  static const List<String> sampleDojangs = [
    'Dragon Martial Arts',
    'Phoenix TKD Academy',
    'Tiger Dojang',
    "Eagle's Nest TKD",
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // Demo User Data
  // ─────────────────────────────────────────────────────────────────────────

  /// Demo user email (not a real email domain).
  static const String demoUserEmail = 'demo@tkdbrackets.local';

  /// Demo user display name.
  static const String demoUserDisplayName = 'Demo User';

  /// Demo user role.
  static const String demoUserRole = 'owner';

  // ─────────────────────────────────────────────────────────────────────────
  // Demo Organization Data
  // ─────────────────────────────────────────────────────────────────────────

  /// Demo organization name.
  static const String demoOrganizationName = 'Demo Dojang';

  /// Demo organization slug.
  static const String demoOrganizationSlug = 'demo-dojang';

  /// Demo organization subscription tier.
  static const String demoOrganizationTier = 'free';

  // ─────────────────────────────────────────────────────────────────────────
  // Demo Tournament Data
  // ─────────────────────────────────────────────────────────────────────────

  /// Demo tournament name.
  static const String demoTournamentName = 'Spring Championship 2026';

  /// Demo tournament federation type.
  static const String demoTournamentFederation = 'wt';

  /// Demo tournament status.
  static const String demoTournamentStatus = 'registration_open';

  /// Days from seed date for tournament scheduled date.
  static const int demoTournamentDaysFromNow = 30;

  // ─────────────────────────────────────────────────────────────────────────
  // Demo Division Data
  // ─────────────────────────────────────────────────────────────────────────

  /// Demo division name.
  static const String demoDivisionName = 'Cadets -45kg Male';

  /// Demo division category.
  static const String demoDivisionCategory = 'sparring';

  /// Demo division gender.
  static const String demoDivisionGender = 'male';

  /// Demo division minimum age.
  static const int demoDivisionAgeMin = 12;

  /// Demo division maximum age.
  static const int demoDivisionAgeMax = 14;

  /// Demo division minimum weight.
  static const double demoDivisionWeightMin = 0;

  /// Demo division maximum weight.
  static const double demoDivisionWeightMax = 45;

  /// Demo division bracket format.
  static const String demoDivisionBracketFormat = 'single_elimination';

  /// Demo division status.
  static const String demoDivisionStatus = 'setup';

  // ─────────────────────────────────────────────────────────────────────────
  // Demo Participant Data
  // ─────────────────────────────────────────────────────────────────────────

  /// Demo participant gender (matches division gender).
  static const String demoParticipantGender = 'male';
}
