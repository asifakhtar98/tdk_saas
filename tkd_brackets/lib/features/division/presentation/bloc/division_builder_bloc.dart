import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/division/domain/usecases/smart_division_builder_params.dart';
import 'package:tkd_brackets/features/division/domain/usecases/smart_division_builder_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';

part 'division_builder_bloc.freezed.dart';

@freezed
class DivisionBuilderEvent with _$DivisionBuilderEvent {
  const factory DivisionBuilderEvent.createRequested({
    required String tournamentId,
    required FederationType federationType,
    required List<AgeGroupConfig> ageGroups,
    required List<BeltGroupConfig> beltGroups,
    required WeightClassConfig weightClasses,
  }) = _CreateRequested;
}

@freezed
class DivisionBuilderState with _$DivisionBuilderState {
  const factory DivisionBuilderState.initial() = _Initial;
  const factory DivisionBuilderState.inProgress() = _InProgress;
  const factory DivisionBuilderState.success() = _Success;
  const factory DivisionBuilderState.failure(String message) = _Failure;
}

@injectable
class DivisionBuilderBloc extends Bloc<DivisionBuilderEvent, DivisionBuilderState> {
  DivisionBuilderBloc(this._smartDivisionBuilderUseCase)
      : super(const DivisionBuilderState.initial()) {
    on<_CreateRequested>(_onCreateRequested);
  }

  final SmartDivisionBuilderUseCase _smartDivisionBuilderUseCase;

  Future<void> _onCreateRequested(
    _CreateRequested event,
    Emitter<DivisionBuilderState> emit,
  ) async {
    emit(const DivisionBuilderState.inProgress());

    final params = SmartDivisionBuilderParams(
      tournamentId: event.tournamentId,
      federationType: event.federationType,
      categoryConfig: const DivisionCategoryConfig(
        category: DivisionCategoryType.sparring,
      ),
      ageGroups: event.ageGroups,
      beltGroups: event.beltGroups,
      weightClasses: event.weightClasses,
    );

    final result = await _smartDivisionBuilderUseCase(params);

    result.fold(
      (failure) => emit(DivisionBuilderState.failure(failure.userFriendlyMessage)),
      (_) => emit(const DivisionBuilderState.success()),
    );
  }
}
