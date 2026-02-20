import 'package:freezed_annotation/freezed_annotation.dart';

part 'participant_entity.freezed.dart';

/// Immutable domain entity representing a tournament participant.
///
/// Each participant belongs to a division and contains personal/athletic
/// data critical for division matching and dojang separation seeding.
@freezed
class ParticipantEntity with _$ParticipantEntity {
  /// Creates a [ParticipantEntity] instance.
  const factory ParticipantEntity({
    /// Unique identifier (UUID).
    required String id,

    /// Foreign key to the division this participant belongs to.
    required String divisionId,

    /// Participant's first name.
    required String firstName,

    /// Participant's last name.
    required String lastName,

    /// Date of birth for age verification.
    DateTime? dateOfBirth,

    /// Participant gender.
    Gender? gender,

    /// Weight in kilograms.
    double? weightKg,

    /// School or dojang name — CRITICAL for dojang separation seeding.
    String? schoolOrDojangName,

    /// Belt rank (e.g., "black 1dan", "red").
    String? beltRank,

    /// Seed number for bracket placement (>= 1).
    int? seedNumber,

    /// Registration number from external system.
    String? registrationNumber,

    /// Whether this is a bye slot (placeholder for bracket structure).
    @Default(false) bool isBye,

    /// Check-in status for tournament day management.
    @Default(ParticipantStatus.pending) ParticipantStatus checkInStatus,

    /// When the participant checked in.
    DateTime? checkInAtTimestamp,

    /// Optional photo URL.
    String? photoUrl,

    /// Additional notes about the participant.
    String? notes,

    /// Sync version for offline-first conflict resolution.
    @Default(1) int syncVersion,

    /// Whether this participant has been soft-deleted.
    @Default(false) bool isDeleted,

    /// When the participant was soft-deleted.
    DateTime? deletedAtTimestamp,

    /// Whether this is demo mode data.
    @Default(false) bool isDemoData,

    /// When the participant was created.
    required DateTime createdAtTimestamp,

    /// When the participant was last updated.
    required DateTime updatedAtTimestamp,
  }) = _ParticipantEntity;

  /// Private constructor required for adding getters to freezed class.
  const ParticipantEntity._();

  /// Computed age from dateOfBirth. Returns null if dateOfBirth is null.
  /// This satisfies the epics AC requirement for `age` field without storing it.
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int years = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      years--;
    }
    return years;
  }
}

/// Check-in status for tournament day management.
enum ParticipantStatus {
  pending('pending'),
  checkedIn('checked_in'),
  noShow('no_show'),
  withdrawn('withdrawn');

  const ParticipantStatus(this.value);

  final String value;

  /// Parse status from database string value.
  static ParticipantStatus fromString(String value) {
    return ParticipantStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ParticipantStatus.pending,
    );
  }
}

/// Participant gender enum.
enum Gender {
  male('male'),
  female('female');

  const Gender(this.value);

  final String value;

  /// Parse gender from database string value.
  static Gender fromString(String value) {
    return Gender.values.firstWhere(
      (g) => g.value == value,
      orElse: () => Gender.male,
    );
  }
}
