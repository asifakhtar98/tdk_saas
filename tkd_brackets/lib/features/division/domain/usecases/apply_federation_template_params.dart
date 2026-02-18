import 'package:freezed_annotation/freezed_annotation.dart';

part 'apply_federation_template_params.freezed.dart';

@freezed
class ApplyFederationTemplateParams with _$ApplyFederationTemplateParams {
  const factory ApplyFederationTemplateParams({
    required String tournamentId,
    required List<String> templateIds,
    required String organizationId,
  }) = _ApplyFederationTemplateParams;
}
