import 'package:drift/drift.dart';
import 'package:tkd_brackets/core/database/tables/base_tables.dart';

@DataClassName('DivisionTemplateEntry')
class DivisionTemplates extends Table with BaseSyncMixin, BaseAuditMixin {
  TextColumn get id => text()();

  TextColumn get organizationId => text().named('organization_id').nullable()();

  TextColumn get federationType => text().named('federation_type')();

  TextColumn get category => text()();

  TextColumn get name => text()();

  TextColumn get gender => text()();

  IntColumn get ageMin => integer().named('age_min').nullable()();

  IntColumn get ageMax => integer().named('age_max').nullable()();

  RealColumn get weightMinKg => real().named('weight_min_kg').nullable()();

  RealColumn get weightMaxKg => real().named('weight_max_kg').nullable()();

  TextColumn get beltRankMin => text().named('belt_rank_min').nullable()();

  TextColumn get beltRankMax => text().named('belt_rank_max').nullable()();

  TextColumn get defaultBracketFormat => text()
      .named('default_bracket_format')
      .withDefault(const Constant('single_elimination'))();

  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  IntColumn get displayOrder =>
      integer().named('display_order').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
