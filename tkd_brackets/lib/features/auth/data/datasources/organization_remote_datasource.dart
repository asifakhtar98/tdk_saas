import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/features/auth/data/models/organization_model.dart';

/// Remote datasource for organization operations using Supabase.
///
/// All queries go through RLS-protected tables.
abstract class OrganizationRemoteDatasource {
  Future<OrganizationModel?> getOrganizationById(
    String id,
  );
  Future<OrganizationModel?> getOrganizationBySlug(
    String slug,
  );
  Future<List<OrganizationModel>> getActiveOrganizations();
  Future<OrganizationModel> insertOrganization(
    OrganizationModel organization,
  );
  Future<OrganizationModel> updateOrganization(
    OrganizationModel organization,
  );
  Future<void> deleteOrganization(String id);
}

@LazySingleton(as: OrganizationRemoteDatasource)
class OrganizationRemoteDatasourceImplementation
    implements OrganizationRemoteDatasource {
  OrganizationRemoteDatasourceImplementation(
    this._supabase,
  );

  final SupabaseClient _supabase;

  static const String _tableName = 'organizations';

  @override
  Future<OrganizationModel?> getOrganizationById(
    String id,
  ) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('id', id)
        .eq('is_deleted', false)
        .maybeSingle();

    if (response == null) return null;
    return OrganizationModel.fromJson(response);
  }

  @override
  Future<OrganizationModel?> getOrganizationBySlug(
    String slug,
  ) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('slug', slug)
        .eq('is_deleted', false)
        .maybeSingle();

    if (response == null) return null;
    return OrganizationModel.fromJson(response);
  }

  @override
  Future<List<OrganizationModel>>
      getActiveOrganizations() async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('is_deleted', false)
        .order('name');

    return response
        .map<OrganizationModel>(
          OrganizationModel.fromJson,
        )
        .toList();
  }

  @override
  Future<OrganizationModel> insertOrganization(
    OrganizationModel organization,
  ) async {
    final response = await _supabase
        .from(_tableName)
        .insert(organization.toJson())
        .select()
        .single();

    return OrganizationModel.fromJson(response);
  }

  @override
  Future<OrganizationModel> updateOrganization(
    OrganizationModel organization,
  ) async {
    final response = await _supabase
        .from(_tableName)
        .update(organization.toJson())
        .eq('id', organization.id)
        .select()
        .single();

    return OrganizationModel.fromJson(response);
  }

  @override
  Future<void> deleteOrganization(String id) async {
    // Soft delete by setting is_deleted = true
    await _supabase.from(_tableName).update({
      'is_deleted': true,
      'deleted_at_timestamp':
          DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
