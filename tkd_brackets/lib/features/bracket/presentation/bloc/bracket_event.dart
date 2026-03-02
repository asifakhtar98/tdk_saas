import 'package:freezed_annotation/freezed_annotation.dart';

part 'bracket_event.freezed.dart';

@freezed
class BracketEvent with _$BracketEvent {
  const factory BracketEvent.loadRequested({required String bracketId}) =
      BracketLoadRequested;
  const factory BracketEvent.refreshRequested() = BracketRefreshRequested;
  const factory BracketEvent.matchSelected(String matchId) =
      BracketMatchSelected;
  const factory BracketEvent.lockRequested() = BracketLockRequested;
  const factory BracketEvent.unlockRequested() = BracketUnlockRequested;
}
