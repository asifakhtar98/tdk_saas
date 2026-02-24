import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/auth/data/models/organization_model.dart';

/// Local datasource for organization operations using Drift
/// database.
///
/// Wraps existing [AppDatabase] methods with model conversion.
abstract class OrganizationLocalDatasource {
  Future<OrganizationModel?> getOrganizationById(String id);
  Future<OrganizationModel?> getOrganizationBySlug(String slug);
  Future<List<OrganizationModel>> getActiveOrganizations();
  Future<void> insertOrganization(OrganizationModel organization);
  Future<void> updateOrganization(OrganizationModel organization);
  Future<void> deleteOrganization(String id);
}

@LazySingleton(as: OrganizationLocalDatasource)
class OrganizationLocalDatasourceImplementation
    implements OrganizationLocalDatasource {
  OrganizationLocalDatasourceImplementation(this._database);

  final AppDatabase _database;

  @override
  Future<OrganizationModel?> getOrganizationById(String id) async {
    final entry = await _database.getOrganizationById(id);
    if (entry == null) return null;
    return OrganizationModel.fromDriftEntry(entry);
  }

  @override
  Future<OrganizationModel?> getOrganizationBySlug(String slug) async {
    final entry = await _database.getOrganizationBySlug(slug);
    if (entry == null) return null;
    return OrganizationModel.fromDriftEntry(entry);
  }

  @override
  Future<List<OrganizationModel>> getActiveOrganizations() async {
    final entries = await _database.getActiveOrganizations();
    return entries.map(OrganizationModel.fromDriftEntry).toList();
  }

  @override
  Future<void> insertOrganization(OrganizationModel organization) async {
    await _database.insertOrganization(organization.toDriftCompanion());
  }

  @override
  Future<void> updateOrganization(OrganizationModel organization) async {
    await _database.updateOrganization(
      organization.id,
      organization.toDriftCompanion(),
    );
  }

  @override
  Future<void> deleteOrganization(String id) async {
    await _database.softDeleteOrganization(id);
  }
}
