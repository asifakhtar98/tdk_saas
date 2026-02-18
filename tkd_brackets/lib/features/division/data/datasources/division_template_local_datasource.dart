import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/division/data/models/division_template_model.dart';

abstract class DivisionTemplateLocalDatasource {
  Future<List<DivisionTemplateModel>> getCustomTemplatesForOrganization(
    String organizationId,
  );
  Future<List<DivisionTemplateModel>> getTemplatesByFederation(
    String federationType,
  );
  Future<DivisionTemplateModel?> getTemplateById(String id);
  Future<void> insertTemplate(DivisionTemplateModel template);
  Future<void> updateTemplate(DivisionTemplateModel template);
  Future<void> deleteTemplate(String id);
}

@LazySingleton(as: DivisionTemplateLocalDatasource)
class DivisionTemplateLocalDatasourceImplementation
    implements DivisionTemplateLocalDatasource {
  DivisionTemplateLocalDatasourceImplementation(this._database);

  final AppDatabase _database;

  @override
  Future<List<DivisionTemplateModel>> getCustomTemplatesForOrganization(
    String organizationId,
  ) async {
    final entries = await _database.getCustomTemplatesForOrganization(
      organizationId,
    );
    return entries.map(DivisionTemplateModel.fromDriftEntry).toList();
  }

  @override
  Future<List<DivisionTemplateModel>> getTemplatesByFederation(
    String federationType,
  ) async {
    final entries = await _database.getTemplatesByFederation(federationType);
    return entries.map(DivisionTemplateModel.fromDriftEntry).toList();
  }

  @override
  Future<DivisionTemplateModel?> getTemplateById(String id) async {
    final entry = await _database.getDivisionTemplateById(id);
    if (entry == null) return null;
    return DivisionTemplateModel.fromDriftEntry(entry);
  }

  @override
  Future<void> insertTemplate(DivisionTemplateModel template) async {
    await _database.insertDivisionTemplate(template.toDriftCompanion());
  }

  @override
  Future<void> updateTemplate(DivisionTemplateModel template) async {
    await _database.updateDivisionTemplate(
      template.id,
      template.toDriftCompanion(),
    );
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _database.deleteDivisionTemplate(id);
  }
}
