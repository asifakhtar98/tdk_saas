import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_layout.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';

part 'bracket_state.freezed.dart';

@freezed
class BracketState with _$BracketState {
  const factory BracketState.initial() = BracketInitial;
  const factory BracketState.loadInProgress() = BracketLoadInProgress;
  const factory BracketState.loadSuccess({
    required BracketEntity bracket,
    required List<MatchEntity> matches,
    required BracketLayout layout,
    String? selectedMatchId,
  }) = BracketLoadSuccess;
  const factory BracketState.loadFailure({
    required String userFriendlyMessage,
    String? technicalDetails,
  }) = BracketLoadFailure;
  const factory BracketState.lockInProgress() = BracketLockInProgress;
  const factory BracketState.unlockInProgress() = BracketUnlockInProgress;
}
