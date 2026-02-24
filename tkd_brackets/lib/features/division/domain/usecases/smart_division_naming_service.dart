import 'package:tkd_brackets/features/division/domain/usecases/smart_division_builder_params.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';

class DivisionNamingService {
  String generateDivisionName({
    required FederationType federationType,
    required NamingConventionType convention,
    required AgeGroupConfig? ageGroup,
    required BeltGroupConfig? beltGroup,
    required WeightClass? weightClass,
    required DivisionGenderType gender,
    required DivisionCategoryType category,
  }) {
    switch (convention) {
      case NamingConventionType.federationDefault:
        return _federationDefault(
          federationType,
          ageGroup,
          weightClass,
          gender,
          category,
          beltGroup,
        );
      case NamingConventionType.withAgePrefix:
        return _withAgePrefix(
          ageGroup,
          beltGroup,
          weightClass,
          gender,
          category,
        );
      case NamingConventionType.withoutAgePrefix:
        return _withoutAgePrefix(weightClass, gender, category);
      case NamingConventionType.short:
        return _shortFormat(weightClass, gender, category);
    }
  }

  String _federationDefault(
    FederationType federation,
    AgeGroupConfig? ageGroup,
    WeightClass? weightClass,
    DivisionGenderType gender,
    DivisionCategoryType category,
    BeltGroupConfig? beltGroup,
  ) {
    final genderStr = gender == DivisionGenderType.male ? 'Male' : 'Female';

    if (category == DivisionCategoryType.poomsae ||
        category == DivisionCategoryType.breaking) {
      final parts = <String>[];
      if (ageGroup != null) parts.add(ageGroup.name);
      parts.add(category.name[0].toUpperCase() + category.name.substring(1));
      if (beltGroupName(beltGroup) != null) {
        parts.add(beltGroupName(beltGroup)!);
      }
      parts.add(genderStr);
      return parts.join(' ');
    }

    switch (federation) {
      case FederationType.wt:
        if (weightClass != null) {
          final agePrefix = ageGroup != null && _requiresAgePrefix(ageGroup)
              ? '${ageGroup.name} '
              : '';
          return '$agePrefix${weightClass.name}';
        }
        return '${ageGroup?.name ?? ''} $genderStr'.trim();

      case FederationType.itf:
        if (weightClass != null) {
          final agePrefix = ageGroup != null
              ? 'U${_getItfAgePrefix(ageGroup)} '
              : '';
          return '$agePrefix$genderStr ${category.name} ${weightClass.name}';
        }
        return '${ageGroup?.name ?? ''} $genderStr ${category.name}'.trim();

      case FederationType.ata:
        if (weightClass != null) {
          return '${ageGroup?.name ?? ''} $genderStr ${weightClass.name}'
              .trim();
        }
        return '${ageGroup?.name ?? ''} $genderStr'.trim();

      case FederationType.custom:
        return '${ageGroup?.name ?? ''} ${beltGroupName(beltGroup)} $genderStr ${weightClass?.name ?? ''}'
            .trim();
    }
  }

  String _withAgePrefix(
    AgeGroupConfig? ageGroup,
    BeltGroupConfig? beltGroup,
    WeightClass? weightClass,
    DivisionGenderType gender,
    DivisionCategoryType category,
  ) {
    final parts = <String>[];

    if (ageGroup != null) {
      parts.add(
        '(${ageGroup.minAge}-${ageGroup.maxAge == 99 ? '' : ageGroup.maxAge})',
      );
    }

    if (weightClass != null) {
      parts.add(weightClass.name);
    }

    final genderStr = gender == DivisionGenderType.male
        ? 'Male'
        : gender == DivisionGenderType.female
        ? 'Female'
        : '';
    if (genderStr.isNotEmpty) parts.add(genderStr);

    final beltName = beltGroupName(beltGroup);
    if (beltName != null) parts.add(beltName);

    return parts.join(' ');
  }

  String _withoutAgePrefix(
    WeightClass? weightClass,
    DivisionGenderType gender,
    DivisionCategoryType category,
  ) {
    final parts = <String>[];

    if (weightClass != null) {
      parts.add(weightClass.name);
    }

    final genderStr = gender == DivisionGenderType.male
        ? 'Male'
        : gender == DivisionGenderType.female
        ? 'Female'
        : '';
    if (genderStr.isNotEmpty) parts.add(genderStr);

    return parts.join(' ');
  }

  String _shortFormat(
    WeightClass? weightClass,
    DivisionGenderType gender,
    DivisionCategoryType category,
  ) {
    final genderAbbr = gender == DivisionGenderType.male
        ? 'M'
        : gender == DivisionGenderType.female
        ? 'F'
        : 'X';

    if (weightClass != null) {
      return '$genderAbbr${weightClass.name.replaceAll('kg', '')}';
    }

    return '$genderAbbr${category.name.substring(0, 1).toUpperCase()}';
  }

  bool _requiresAgePrefix(AgeGroupConfig ageGroup) {
    return ageGroup.maxAge < 15;
  }

  String _getItfAgePrefix(AgeGroupConfig ageGroup) {
    if (ageGroup.maxAge <= 12) return '12';
    if (ageGroup.maxAge <= 14) return '15';
    if (ageGroup.maxAge <= 17) return '18';
    if (ageGroup.maxAge <= 21) return '21';
    if (ageGroup.maxAge <= 34) return '30';
    return '35';
  }

  String? beltGroupName(BeltGroupConfig? beltGroup) {
    if (beltGroup == null) return null;
    final name = beltGroup.name;
    return name
        .split('-')
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join('-');
  }
}
