import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/auth/auth.dart' show MigrateDemoDataUseCase;
import 'package:tkd_brackets/features/auth/domain/usecases/migrate_demo_data_use_case.dart' show MigrateDemoDataUseCase;

part 'migrate_demo_data_params.freezed.dart';

/// Parameters for the [MigrateDemoDataUseCase].
///
/// [newOrganizationId] — The production organization ID created during signup
/// that will replace the demo organization ID.
@freezed
class MigrateDemoDataParams with _$MigrateDemoDataParams {
  const factory MigrateDemoDataParams({
    /// The new production organization ID to replace demo organization.
    required String newOrganizationId,
  }) = _MigrateDemoDataParams;
}
