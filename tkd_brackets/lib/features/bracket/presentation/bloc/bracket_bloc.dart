import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_layout.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/services/bracket_layout_engine.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/lock_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/lock_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/unlock_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/unlock_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_event.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_state.dart';

@injectable
class BracketBloc extends Bloc<BracketEvent, BracketState> {
  BracketBloc(
    this._bracketRepository,
    this._matchRepository,
    this._layoutEngine,
    this._lockBracketUseCase,
    this._unlockBracketUseCase,
  ) : super(const BracketInitial()) {
    on<BracketLoadRequested>(_onLoadRequested);
    on<BracketRefreshRequested>(_onRefreshRequested);
    on<BracketMatchSelected>(_onMatchSelected);
    on<BracketLockRequested>(_onLockRequested);
    on<BracketUnlockRequested>(_onUnlockRequested);
  }

  final BracketRepository _bracketRepository;
  final MatchRepository _matchRepository;
  final BracketLayoutEngine _layoutEngine;
  final LockBracketUseCase _lockBracketUseCase;
  final UnlockBracketUseCase _unlockBracketUseCase;

  String _currentBracketId = '';

  Future<void> _onLoadRequested(
    BracketLoadRequested event,
    Emitter<BracketState> emit,
  ) async {
    emit(const BracketLoadInProgress());
    _currentBracketId = event.bracketId;

    final bracketResult = await _bracketRepository.getBracketById(
      event.bracketId,
    );
    await bracketResult.fold(
      (failure) async => emit(
        BracketLoadFailure(
          userFriendlyMessage: failure.userFriendlyMessage,
          technicalDetails: failure.technicalDetails,
        ),
      ),
      (bracket) async {
        final matchesResult = await _matchRepository.getMatchesForBracket(
          event.bracketId,
        );
        matchesResult.fold(
          (failure) => emit(
            BracketLoadFailure(
              userFriendlyMessage: failure.userFriendlyMessage,
              technicalDetails: failure.technicalDetails,
            ),
          ),
          (matches) {
            final layout = _layoutEngine.calculateLayout(
              bracket: bracket,
              matches: matches,
              options: const BracketLayoutOptions(),
            );
            emit(
              BracketLoadSuccess(
                bracket: bracket,
                matches: matches,
                layout: layout,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onRefreshRequested(
    BracketRefreshRequested event,
    Emitter<BracketState> emit,
  ) async {
    if (_currentBracketId.isEmpty) return;
    add(BracketLoadRequested(bracketId: _currentBracketId));
  }

  void _onMatchSelected(
    BracketMatchSelected event,
    Emitter<BracketState> emit,
  ) {
    if (state is BracketLoadSuccess) {
      emit(
        (state as BracketLoadSuccess).copyWith(selectedMatchId: event.matchId),
      );
    }
  }

  Future<void> _onLockRequested(
    BracketLockRequested event,
    Emitter<BracketState> emit,
  ) async {
    final currentState = state;
    if (currentState is BracketLoadSuccess) {
      emit(const BracketLockInProgress());
      final result = await _lockBracketUseCase(
        LockBracketParams(bracketId: currentState.bracket.id),
      );
      result.fold(
        (failure) => emit(
          BracketLoadFailure(
            userFriendlyMessage: failure.userFriendlyMessage,
            technicalDetails: failure.technicalDetails,
          ),
        ),
        (_) => add(const BracketRefreshRequested()),
      );
    }
  }

  Future<void> _onUnlockRequested(
    BracketUnlockRequested event,
    Emitter<BracketState> emit,
  ) async {
    final currentState = state;
    if (currentState is BracketLoadSuccess) {
      emit(const BracketUnlockInProgress());
      final result = await _unlockBracketUseCase(
        UnlockBracketParams(bracketId: currentState.bracket.id),
      );
      result.fold(
        (failure) => emit(
          BracketLoadFailure(
            userFriendlyMessage: failure.userFriendlyMessage,
            technicalDetails: failure.technicalDetails,
          ),
        ),
        (_) => add(const BracketRefreshRequested()),
      );
    }
  }
}
