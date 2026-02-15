import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/auth/data/models/invitation_model.dart';

/// Local datasource for invitation operations using Drift database.
///
/// Wraps existing [AppDatabase] methods with model conversion.
abstract class InvitationLocalDatasource {
  Future<InvitationModel?> getInvitationById(String id);
  Future<InvitationModel?> getInvitationByToken(String token);
  Future<InvitationModel?> getInvitationByEmailAndOrganization(
    String email,
    String organizationId,
  );
  Future<List<InvitationModel>> getPendingInvitationsForOrganization(
    String organizationId,
  );
  Future<void> insertInvitation(InvitationModel invitation);
  Future<void> updateInvitation(InvitationModel invitation);
}

@LazySingleton(as: InvitationLocalDatasource)
class InvitationLocalDatasourceImplementation
    implements InvitationLocalDatasource {
  InvitationLocalDatasourceImplementation(this._database);

  final AppDatabase _database;

  @override
  Future<InvitationModel?> getInvitationById(String id) async {
    final entry = await _database.getInvitationById(id);
    if (entry == null) return null;
    return InvitationModel.fromDriftEntry(entry);
  }

  @override
  Future<InvitationModel?> getInvitationByToken(String token) async {
    final entry = await _database.getInvitationByToken(token);
    if (entry == null) return null;
    return InvitationModel.fromDriftEntry(entry);
  }

  @override
  Future<InvitationModel?> getInvitationByEmailAndOrganization(
    String email,
    String organizationId,
  ) async {
    final entry = await _database.getInvitationByEmailAndOrganization(
      email,
      organizationId,
    );
    if (entry == null) return null;
    return InvitationModel.fromDriftEntry(entry);
  }

  @override
  Future<List<InvitationModel>> getPendingInvitationsForOrganization(
    String organizationId,
  ) async {
    final entries = await _database.getPendingInvitationsForOrganization(
      organizationId,
    );
    return entries.map(InvitationModel.fromDriftEntry).toList();
  }

  @override
  Future<void> insertInvitation(InvitationModel invitation) async {
    await _database.insertInvitation(invitation.toDriftCompanion());
  }

  @override
  Future<void> updateInvitation(InvitationModel invitation) async {
    await _database.updateInvitation(
      invitation.id,
      invitation.toDriftCompanion(),
    );
  }
}
