import 'package:freezed_annotation/freezed_annotation.dart';

part 'merge_divisions_params.freezed.dart';
part 'merge_divisions_params.g.dart';

@freezed
class MergeDivisionsParams with _$MergeDivisionsParams {
  const factory MergeDivisionsParams({
    required String divisionIdA,
    required String divisionIdB,
    String? name,
  }) = _MergeDivisionsParams;
  const MergeDivisionsParams._();

  factory MergeDivisionsParams.fromJson(Map<String, dynamic> json) =>
      _$MergeDivisionsParamsFromJson(json);
}
