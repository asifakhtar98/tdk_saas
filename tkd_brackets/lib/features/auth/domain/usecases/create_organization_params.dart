import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/auth/auth.dart' show CreateOrganizationUseCase;
import 'package:tkd_brackets/features/auth/domain/usecases/create_organization_use_case.dart' show CreateOrganizationUseCase;

part 'create_organization_params.freezed.dart';

/// Parameters for the [CreateOrganizationUseCase].
///
/// [name] — The display name for the organization (e.g., "Dragon Martial Arts").
/// [userId] — The authenticated user's ID who is creating the organization.
@freezed
class CreateOrganizationParams with _$CreateOrganizationParams {
  const factory CreateOrganizationParams({
    /// Organization display name.
    required String name,

    /// The ID of the user creating the organization.
    required String userId,
  }) = _CreateOrganizationParams;
}
