import 'package:freezed_annotation/freezed_annotation.dart';

part 'bracket_entity.freezed.dart';

@freezed
class BracketEntity with _$BracketEntity {
  const factory BracketEntity({
    required String id,
    required String divisionId,
    required BracketType bracketType,
    required int totalRounds,
    required DateTime createdAtTimestamp,
    required DateTime updatedAtTimestamp,
    String? poolIdentifier,
    @Default(false) bool isFinalized,
    DateTime? generatedAtTimestamp,
    DateTime? finalizedAtTimestamp,
    Map<String, dynamic>? bracketDataJson,
    @Default(1) int syncVersion,
    @Default(false) bool isDeleted,
    DateTime? deletedAtTimestamp,
    @Default(false) bool isDemoData,
  }) = _BracketEntity;

  const BracketEntity._();
}

/// Bracket type — winners/losers for elimination, pool for round robin.
enum BracketType {
  winners('winners'),
  losers('losers'),
  pool('pool');

  const BracketType(this.value);
  final String value;

  static BracketType fromString(String value) {
    return BracketType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => BracketType.winners,
    );
  }
}
