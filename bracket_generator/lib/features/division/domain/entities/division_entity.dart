class DivisionEntity {
  final String id;
  final String tournamentId;
  final String name;
  final BracketFormat bracketFormat;

  const DivisionEntity({
    required this.id,
    required this.tournamentId,
    required this.name,
    required this.bracketFormat,
  });
}

enum BracketFormat {
  singleElimination('single_elimination'),
  doubleElimination('double_elimination'),
  roundRobin('round_robin'),
  poolPlay('pool_play');

  const BracketFormat(this.value);
  final String value;
}
