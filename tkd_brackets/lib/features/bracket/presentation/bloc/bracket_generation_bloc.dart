import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/double_elimination_bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';

import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_round_robin_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_round_robin_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_single_elimination_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_single_elimination_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/regenerate_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/regenerate_bracket_use_case.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart'
    as seeding;
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_generation_event.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_generation_state.dart';

@injectable
class BracketGenerationBloc
    extends Bloc<BracketGenerationEvent, BracketGenerationState> {
  BracketGenerationBloc(
    this._divisionRepository,
    this._participantRepository,
    this._bracketRepository,
    this._generateSingleEliminationUseCase,
    this._generateDoubleEliminationUseCase,
    this._generateRoundRobinUseCase,
    this._regenerateBracketUseCase,
  ) : super(const BracketGenerationState.initial()) {
    on<BracketGenerationLoadRequested>(_onLoadRequested);
    on<BracketGenerationFormatSelected>(_onFormatSelected);
    on<BracketGenerationGenerateRequested>(_onGenerateRequested);
    on<BracketGenerationRegenerateRequested>(_onRegenerateRequested);
    on<BracketGenerationNavigateToBracketRequested>(_onNavigateToBracketRequested);
  }

  final DivisionRepository _divisionRepository;
  final ParticipantRepository _participantRepository;
  final BracketRepository _bracketRepository;
  final GenerateSingleEliminationBracketUseCase
      _generateSingleEliminationUseCase;
  final GenerateDoubleEliminationBracketUseCase
      _generateDoubleEliminationUseCase;
  final GenerateRoundRobinBracketUseCase _generateRoundRobinUseCase;
  final RegenerateBracketUseCase _regenerateBracketUseCase;


  Future<void> _onLoadRequested(
    BracketGenerationLoadRequested event,
    Emitter<BracketGenerationState> emit,
  ) async {
    emit(const BracketGenerationState.loadInProgress());

    final divisionResult =
        await _divisionRepository.getDivisionById(event.divisionId);

    await divisionResult.fold(
      (failure) async => emit(BracketGenerationState.loadFailure(
        userFriendlyMessage: failure.userFriendlyMessage,
        technicalDetails: failure.technicalDetails,
      )),
      (division) async {
        final participantResult = await _participantRepository
            .getParticipantsForDivision(event.divisionId);

        await participantResult.fold(
          (failure) async => emit(BracketGenerationState.loadFailure(
            userFriendlyMessage: failure.userFriendlyMessage,
            technicalDetails: failure.technicalDetails,
          )),
          (participants) async {
            final bracketResult = await _bracketRepository
                .getBracketsForDivision(event.divisionId);

            bracketResult.fold(
              (failure) => emit(BracketGenerationState.loadFailure(
                userFriendlyMessage: failure.userFriendlyMessage,
                technicalDetails: failure.technicalDetails,
              )),
              (brackets) => emit(BracketGenerationState.loadSuccess(
                division: division,
                participants: participants,
                existingBrackets: brackets,
              )),
            );
          },
        );
      },
    );
  }

  void _onFormatSelected(
    BracketGenerationFormatSelected event,
    Emitter<BracketGenerationState> emit,
  ) {
    if (state is BracketGenerationLoadSuccess) {
      emit((state as BracketGenerationLoadSuccess)
          .copyWith(selectedFormat: event.format));
    }
  }

  Future<void> _onGenerateRequested(
    BracketGenerationGenerateRequested event,
    Emitter<BracketGenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BracketGenerationLoadSuccess) return;

    final divisionId = currentState.division.id;
    final selectedFormat = currentState.selectedFormat ?? currentState.division.bracketFormat;
    final participants = currentState.participants;

    emit(const BracketGenerationState.generationInProgress());

    final activeParticipantIds = participants
        .where((p) =>
            !p.isDeleted &&
            p.checkInStatus != ParticipantStatus.noShow &&
            p.checkInStatus != ParticipantStatus.disqualified &&
            p.checkInStatus != ParticipantStatus.withdrawn)
        .map((p) => p.id)
        .toList();

    if (activeParticipantIds.isEmpty) {
      emit(const BracketGenerationState.loadFailure(
        userFriendlyMessage: 'At least 1 participant is required to generate a bracket.',
      ));
      return;
    }

    switch (selectedFormat) {
      case BracketFormat.singleElimination:
        final result = await _generateSingleEliminationUseCase(
          GenerateSingleEliminationBracketParams(
            divisionId: divisionId,
            participantIds: activeParticipantIds,
          ),
        );

        result.fold(
          (failure) => emit(BracketGenerationState.loadFailure(
            userFriendlyMessage: failure.userFriendlyMessage,
            technicalDetails: failure.technicalDetails,
          )),
          (res) => emit(BracketGenerationState.generationSuccess(
            generatedBracketId: res.bracket.id,
          )),
        );
      case BracketFormat.doubleElimination:
        final result = await _generateDoubleEliminationUseCase(
          GenerateDoubleEliminationBracketParams(
            divisionId: divisionId,
            participantIds: activeParticipantIds,
          ),
        );
        result.fold(
          (failure) => emit(BracketGenerationState.loadFailure(
            userFriendlyMessage: failure.userFriendlyMessage,
            technicalDetails: failure.technicalDetails,
          )),
          (res) => emit(BracketGenerationState.generationSuccess(
            generatedBracketId: res.winnersBracket.id,
          )),
        );
      case BracketFormat.roundRobin:
        final result = await _generateRoundRobinUseCase(
          GenerateRoundRobinBracketParams(
            divisionId: divisionId,
            participantIds: activeParticipantIds,
          ),
        );
        result.fold(
          (failure) => emit(BracketGenerationState.loadFailure(
            userFriendlyMessage: failure.userFriendlyMessage,
            technicalDetails: failure.technicalDetails,
          )),
          (res) => emit(BracketGenerationState.generationSuccess(
            generatedBracketId: res.bracket.id,
          )),
        );
      case BracketFormat.poolPlay:
        emit(const BracketGenerationState.loadFailure(
          userFriendlyMessage: 'Pool play format is not yet available.',
        ));
    }
  }

  Future<void> _onRegenerateRequested(
    BracketGenerationRegenerateRequested event,
    Emitter<BracketGenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BracketGenerationLoadSuccess ||
        currentState.existingBrackets.isEmpty) {
      return;
    }

    final division = currentState.division;
    final participants = currentState.participants;

    emit(const BracketGenerationState.generationInProgress());

    final activeParticipantIds = participants
        .where((p) =>
            !p.isDeleted &&
            p.checkInStatus != ParticipantStatus.noShow &&
            p.checkInStatus != ParticipantStatus.disqualified &&
            p.checkInStatus != ParticipantStatus.withdrawn)
        .map((p) => p.id)
        .toList();

    final seedingFormat = _mapToSeedingFormat(division.bracketFormat);

    final result = await _regenerateBracketUseCase(
      RegenerateBracketParams(
        divisionId: division.id,
        participantIds: activeParticipantIds,
        bracketFormat: seedingFormat,
      ),
    );

    result.fold(
      (failure) => emit(BracketGenerationState.loadFailure(
        userFriendlyMessage: failure.userFriendlyMessage,
        technicalDetails: failure.technicalDetails,
      )),
      (res) {
        final genResult = res.generationResult;
        String bracketId;
        if (genResult is BracketGenerationResult) {
          bracketId = genResult.bracket.id;
        } else if (genResult is DoubleEliminationBracketGenerationResult) {
          bracketId = genResult.winnersBracket.id;
        } else {
          emit(const BracketGenerationState.loadFailure(
            userFriendlyMessage: 'Unexpected generation result type.',
          ));
          return;
        }
        emit(BracketGenerationState.generationSuccess(
          generatedBracketId: bracketId,
        ));
      },
    );
  }

  seeding.BracketFormat _mapToSeedingFormat(BracketFormat format) {
    return switch (format) {
      BracketFormat.singleElimination => seeding.BracketFormat.singleElimination,
      BracketFormat.doubleElimination => seeding.BracketFormat.doubleElimination,
      BracketFormat.roundRobin => seeding.BracketFormat.roundRobin,
      BracketFormat.poolPlay => seeding.BracketFormat.singleElimination,
    };
  }

  void _onNavigateToBracketRequested(
    BracketGenerationNavigateToBracketRequested event,
    Emitter<BracketGenerationState> emit,
  ) {
    emit(BracketGenerationState.generationSuccess(
      generatedBracketId: event.bracketId,
    ));
  }
}
