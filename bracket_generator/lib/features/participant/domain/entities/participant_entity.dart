class ParticipantEntity {
  final String id;
  final String divisionId;
  final String firstName;
  final String lastName;
  final String? schoolOrDojangName;
  final String? beltRank;
  final int? seedNumber;
  final bool isBye;

  const ParticipantEntity({
    required this.id,
    required this.divisionId,
    required this.firstName,
    required this.lastName,
    this.schoolOrDojangName,
    this.beltRank,
    this.seedNumber,
    this.isBye = false,
  });
}
