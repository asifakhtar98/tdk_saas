import 'package:freezed_annotation/freezed_annotation.dart';

part 'split_division_params.freezed.dart';
part 'split_division_params.g.dart';

enum SplitDistributionMethod { random, alphabetical }

@freezed
class SplitDivisionParams with _$SplitDivisionParams {
  const SplitDivisionParams._();

  const factory SplitDivisionParams({
    required String divisionId,
    required SplitDistributionMethod distributionMethod,
    String? baseName,
  }) = _SplitDivisionParams;

  factory SplitDivisionParams.fromJson(Map<String, dynamic> json) =>
      _$SplitDivisionParamsFromJson(json);
}
