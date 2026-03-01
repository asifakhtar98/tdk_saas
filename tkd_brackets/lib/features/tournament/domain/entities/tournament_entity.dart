import 'package:freezed_annotation/freezed_annotation.dart';

part 'tournament_entity.freezed.dart';

/// Immutable domain entity representing a tournament.
///
/// A tournament belongs to an organization and contains divisions
/// with participants and brackets.
@freezed
class TournamentEntity with _$TournamentEntity {
  /// Creates a [TournamentEntity] instance.
  const factory TournamentEntity({
    /// Unique identifier (UUID).
    required String id,

    /// Foreign key to the organization that owns this tournament.
    required String organizationId,

    /// Foreign key to the user who created this tournament.
    required String createdByUserId,

    /// Tournament display name.
    required String name,

    /// Federation type (WT, ITF, ATA, or custom).
    required FederationType federationType,

    /// Current tournament status.
    required TournamentStatus status,

    /// Number of rings/courts available for the tournament.
    required int numberOfRings,

    /// JSON blob for additional tournament settings.
    required Map<String, dynamic> settingsJson,

    /// Whether this tournament is a template for creating new tournaments.
    required bool isTemplate,

    /// When the tournament was created.
    required DateTime createdAt,

    /// When the tournament was last updated.
    required DateTime updatedAtTimestamp,

    /// Scheduled date for the tournament.
    DateTime? scheduledDate,

    /// Optional tournament description.
    String? description,

    /// Venue name for the tournament location.
    String? venueName,

    /// Venue address for the tournament location.
    String? venueAddress,

    /// Optional start time for the tournament (stored as DateTime).
    DateTime? scheduledStartTime,

    /// Optional end time for the tournament (stored as DateTime).
    DateTime? scheduledEndTime,

    /// Foreign key to template tournament if created from template.
    String? templateId,

    /// When the tournament was completed (null if not completed).
    DateTime? completedAtTimestamp,

    /// Whether this tournament has been soft-deleted.
    @Default(false) bool isDeleted,

    /// Timestamp when the tournament was deleted (null if not deleted).
    DateTime? deletedAtTimestamp,

    /// Sync version for conflict resolution in offline-first sync.
    @Default(0) int syncVersion,
  }) = _TournamentEntity;
}

/// Enum for federation types.
enum FederationType {
  wt('wt'),
  itf('itf'),
  ata('ata'),
  custom('custom');

  const FederationType(this.value);

  final String value;

  /// Parse federation type from database string value.
  static FederationType fromString(String value) {
    return FederationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => FederationType.wt,
    );
  }
}

/// Enum for tournament statuses.
enum TournamentStatus {
  draft('draft'),
  active('active'),
  completed('completed'),
  archived('archived'),
  cancelled('cancelled');

  const TournamentStatus(this.value);

  final String value;

  /// Parse status from database string value.
  static TournamentStatus fromString(String value) {
    return TournamentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TournamentStatus.draft,
    );
  }
}
