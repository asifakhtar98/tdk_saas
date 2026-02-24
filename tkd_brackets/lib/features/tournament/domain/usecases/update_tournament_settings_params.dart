import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/update_tournament_settings_usecase.dart' show UpdateTournamentSettingsUseCase;
import 'package:tkd_brackets/features/tournament/tournament.dart' show UpdateTournamentSettingsUseCase;

part 'update_tournament_settings_params.freezed.dart';

/// Parameters for [UpdateTournamentSettingsUseCase].
///
/// [tournamentId] — Required ID of tournament to update
/// [federationType] — Optional: federation type (WT, ITF, ATA, custom)
/// [venueName] — Optional: venue name (empty string removes value)
/// [venueAddress] — Optional: venue address (empty string removes value)
/// [ringCount] — Optional: number of rings (1-20)
/// [scheduledStartTime] — Optional: tournament start time
/// [scheduledEndTime] — Optional: tournament end time
@freezed
class UpdateTournamentSettingsParams with _$UpdateTournamentSettingsParams {
  const factory UpdateTournamentSettingsParams({
    required String tournamentId,
    FederationType? federationType,
    String? venueName,
    String? venueAddress,
    int? ringCount,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
  }) = _UpdateTournamentSettingsParams;
}
