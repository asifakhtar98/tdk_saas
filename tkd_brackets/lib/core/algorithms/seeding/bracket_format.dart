/// Bracket format types that affect seeding calculations.
///
/// The bracket format determines how meeting-round calculations work:
/// - Single elimination: standard binary tree
/// - Double elimination: winners + losers bracket trees
/// - Round robin: all-play-all (separation still relevant for scheduling)
enum BracketFormat {
  singleElimination('single_elimination'),
  doubleElimination('double_elimination'),
  roundRobin('round_robin');

  const BracketFormat(this.value);
  final String value;
}
