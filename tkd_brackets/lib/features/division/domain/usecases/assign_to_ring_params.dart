import 'package:freezed_annotation/freezed_annotation.dart';

part 'assign_to_ring_params.freezed.dart';
part 'assign_to_ring_params.g.dart';

@freezed
class AssignToRingParams with _$AssignToRingParams {
  const AssignToRingParams._();

  const factory AssignToRingParams({
    required String divisionId,
    required int ringNumber,
    int? displayOrder,
  }) = _AssignToRingParams;

  factory AssignToRingParams.fromJson(Map<String, dynamic> json) =>
      _$AssignToRingParamsFromJson(json);
}
