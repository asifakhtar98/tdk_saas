enum ScoringMethod {
  sparringPoints('sparring_points'),
  sparringContinuous('sparring_continuous'),
  formsScoreAverage('forms_score_average'),
  formsScoreDropHighLow('forms_score_drop_high_low'),
  breakingPassFail('breaking_pass_fail'),
  breakingScore('breaking_score'),
  demoTeamRanking('demo_team_ranking');

  const ScoringMethod(this.value);

  final String value;

  static ScoringMethod? fromString(String value) {
    return ScoringMethod.values.firstWhere(
      (m) => m.value == value,
      orElse: () => ScoringMethod.sparringPoints,
    );
  }
}
