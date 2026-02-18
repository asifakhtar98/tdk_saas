import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/features/division/data/models/division_template_model.dart';

abstract class DivisionTemplateRemoteDatasource {
  Future<List<DivisionTemplateModel>> getCustomTemplatesForOrganization(
    String organizationId,
  );
  Future<List<DivisionTemplateModel>> getTemplatesByFederation(
    String federationType,
  );
  Future<DivisionTemplateModel?> getTemplateById(String id);
  Future<DivisionTemplateModel> insertTemplate(DivisionTemplateModel template);
  Future<DivisionTemplateModel> updateTemplate(DivisionTemplateModel template);
  Future<void> deleteTemplate(String id);
}

@LazySingleton(as: DivisionTemplateRemoteDatasource)
class DivisionTemplateRemoteDatasourceImplementation
    implements DivisionTemplateRemoteDatasource {
  DivisionTemplateRemoteDatasourceImplementation(this._supabase);

  final SupabaseClient _supabase;

  static const String _tableName = 'division_templates';

  @override
  Future<List<DivisionTemplateModel>> getCustomTemplatesForOrganization(
    String organizationId,
  ) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('organization_id', organizationId)
        .eq('is_active', true)
        .order('display_order', ascending: true);

    return response
        .map<DivisionTemplateModel>(
          (json) => DivisionTemplateModel.fromJson(json),
        )
        .toList();
  }

  @override
  Future<List<DivisionTemplateModel>> getTemplatesByFederation(
    String federationType,
  ) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('federation_type', federationType)
        .eq('is_active', true)
        .order('display_order', ascending: true);

    return response
        .map<DivisionTemplateModel>(
          (json) => DivisionTemplateModel.fromJson(json),
        )
        .toList();
  }

  @override
  Future<DivisionTemplateModel?> getTemplateById(String id) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('id', id)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return DivisionTemplateModel.fromJson(response);
  }

  @override
  Future<DivisionTemplateModel> insertTemplate(
    DivisionTemplateModel template,
  ) async {
    final response = await _supabase
        .from(_tableName)
        .insert(template.toJson())
        .select()
        .single();

    return DivisionTemplateModel.fromJson(response);
  }

  @override
  Future<DivisionTemplateModel> updateTemplate(
    DivisionTemplateModel template,
  ) async {
    final response = await _supabase
        .from(_tableName)
        .update(template.toJson())
        .eq('id', template.id)
        .select()
        .single();

    return DivisionTemplateModel.fromJson(response);
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _supabase
        .from(_tableName)
        .update({
          'is_active': false,
          'updated_at_timestamp': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
