import 'package:freezed_annotation/freezed_annotation.dart';

part 'assign_to_ring_params.freezed.dart';
part 'assign_to_ring_params.g.dart';

@freezed
class AssignToRingParams with _$AssignToRingParams {
  const factory AssignToRingParams({
    required String divisionId,
    required int ringNumber,
    int? displayOrder,
  }) = _AssignToRingParams;
  const AssignToRingParams._();

  factory AssignToRingParams.fromJson(Map<String, dynamic> json) =>
      _$AssignToRingParamsFromJson(json);
}
