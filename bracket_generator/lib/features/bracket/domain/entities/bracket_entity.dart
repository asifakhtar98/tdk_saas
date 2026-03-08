class BracketEntity {
  final String id;
  final String divisionId;
  final BracketType bracketType;
  final int totalRounds;
  final DateTime createdAtTimestamp;
  final DateTime updatedAtTimestamp;
  final String? poolIdentifier;
  final bool isFinalized;
  final DateTime? generatedAtTimestamp;
  final DateTime? finalizedAtTimestamp;
  final Map<String, dynamic>? bracketDataJson;
  final int syncVersion;
  final bool isDeleted;
  final DateTime? deletedAtTimestamp;
  final bool isDemoData;

  const BracketEntity({
    required this.id,
    required this.divisionId,
    required this.bracketType,
    required this.totalRounds,
    required this.createdAtTimestamp,
    required this.updatedAtTimestamp,
    this.poolIdentifier,
    this.isFinalized = false,
    this.generatedAtTimestamp,
    this.finalizedAtTimestamp,
    this.bracketDataJson,
    this.syncVersion = 1,
    this.isDeleted = false,
    this.deletedAtTimestamp,
    this.isDemoData = false,
  });

  BracketEntity copyWith({
    String? id,
    String? divisionId,
    BracketType? bracketType,
    int? totalRounds,
    DateTime? createdAtTimestamp,
    DateTime? updatedAtTimestamp,
    String? poolIdentifier,
    bool? isFinalized,
    DateTime? generatedAtTimestamp,
    DateTime? finalizedAtTimestamp,
    Map<String, dynamic>? bracketDataJson,
    int? syncVersion,
    bool? isDeleted,
    DateTime? deletedAtTimestamp,
    bool? isDemoData,
  }) {
    return BracketEntity(
      id: id ?? this.id,
      divisionId: divisionId ?? this.divisionId,
      bracketType: bracketType ?? this.bracketType,
      totalRounds: totalRounds ?? this.totalRounds,
      createdAtTimestamp: createdAtTimestamp ?? this.createdAtTimestamp,
      updatedAtTimestamp: updatedAtTimestamp ?? this.updatedAtTimestamp,
      poolIdentifier: poolIdentifier ?? this.poolIdentifier,
      isFinalized: isFinalized ?? this.isFinalized,
      generatedAtTimestamp: generatedAtTimestamp ?? this.generatedAtTimestamp,
      finalizedAtTimestamp: finalizedAtTimestamp ?? this.finalizedAtTimestamp,
      bracketDataJson: bracketDataJson ?? this.bracketDataJson,
      syncVersion: syncVersion ?? this.syncVersion,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAtTimestamp: deletedAtTimestamp ?? this.deletedAtTimestamp,
      isDemoData: isDemoData ?? this.isDemoData,
    );
  }
}

/// Bracket type — winners/losers for elimination, pool for round robin.
enum BracketType {
  winners('winners'),
  losers('losers'),
  pool('pool');

  const BracketType(this.value);
  final String value;
}
