import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_tournament_params.freezed.dart';

/// Parameters for creating a tournament.
///
/// [name] — Tournament name (required, 1-100 chars)
/// [scheduledDate] — Date of tournament (required, must be >= today)
/// [description] — Optional description (max 1000 chars)
@freezed
class CreateTournamentParams with _$CreateTournamentParams {
  const factory CreateTournamentParams({
    required String name,
    required DateTime scheduledDate,
    String? description,
  }) = _CreateTournamentParams;
}
