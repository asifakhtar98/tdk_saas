/// Seeding strategy types available for bracket generation.
enum SeedingStrategy {
  /// Random placement with constraint satisfaction.
  random('random'),

  /// Based on external ranking points (imported).
  ranked('ranked'),

  /// Based on historical win rates within the system.
  performanceBased('performance_based'),

  /// User-defined positions with constraint validation.
  manual('manual');

  const SeedingStrategy(this.value);
  final String value;
}
