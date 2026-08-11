import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

/// Pure display helpers for regiment category, combat-role gist, and food upkeep
/// on Train Military rows. SPEC/ui/train-military-dialog.md; sibling pattern:
/// [TrainNavalShipRoleDisplay].
class TrainMilitaryRegimentRoleDisplay {
  TrainMilitaryRegimentRoleDisplay._();

  static String categoryLabel(AppLocalizations l10n, RegimentCategory category) {
    switch (category) {
      case RegimentCategory.lightInfantry:
        return l10n.trainMilitary_categoryLightInfantry;
      case RegimentCategory.regularInfantry:
        return l10n.trainMilitary_categoryRegularInfantry;
      case RegimentCategory.heavyInfantry:
        return l10n.trainMilitary_categoryHeavyInfantry;
      case RegimentCategory.bowmen:
        return l10n.trainMilitary_categoryBowmen;
      case RegimentCategory.lightCavalry:
        return l10n.trainMilitary_categoryLightCavalry;
      case RegimentCategory.spearCavalry:
        return l10n.trainMilitary_categorySpearCavalry;
      case RegimentCategory.heavyCavalry:
        return l10n.trainMilitary_categoryHeavyCavalry;
      case RegimentCategory.lightArtillery:
        return l10n.trainMilitary_categoryLightArtillery;
      case RegimentCategory.heavyArtillery:
        return l10n.trainMilitary_categoryHeavyArtillery;
    }
  }

  /// Category-level combat-role gist (not per-type stat dumps).
  static String combatRoleGist(
    AppLocalizations l10n,
    RegimentCategory category,
  ) {
    switch (category) {
      case RegimentCategory.lightInfantry:
        return l10n.trainMilitary_combatGistLightInfantry;
      case RegimentCategory.regularInfantry:
        return l10n.trainMilitary_combatGistRegularInfantry;
      case RegimentCategory.heavyInfantry:
        return l10n.trainMilitary_combatGistHeavyInfantry;
      case RegimentCategory.bowmen:
        return l10n.trainMilitary_combatGistBowmen;
      case RegimentCategory.lightCavalry:
        return l10n.trainMilitary_combatGistLightCavalry;
      case RegimentCategory.spearCavalry:
        return l10n.trainMilitary_combatGistSpearCavalry;
      case RegimentCategory.heavyCavalry:
        return l10n.trainMilitary_combatGistHeavyCavalry;
      case RegimentCategory.lightArtillery:
        return l10n.trainMilitary_combatGistLightArtillery;
      case RegimentCategory.heavyArtillery:
        return l10n.trainMilitary_combatGistHeavyArtillery;
    }
  }

  static String categoryRoleLine(
    AppLocalizations l10n,
    RegimentCategory category,
  ) {
    return l10n.trainNaval_roleCapabilityGist(
      categoryLabel(l10n, category),
      combatRoleGist(l10n, category),
    );
  }

  static String foodUpkeepLine(AppLocalizations l10n, int foodUpkeep) =>
      l10n.trainMilitary_foodUpkeepPerTurn(foodUpkeep);

  static String? categoryRoleLineForRegiment(
    AppLocalizations l10n,
    String regimentTypeId,
  ) {
    final stats = regimentStatsById(regimentTypeId);
    if (stats == null) return null;
    return categoryRoleLine(l10n, stats.category);
  }

  static int? foodUpkeepForRegiment(String regimentTypeId) {
    for (final econ in RegimentEconomyCatalog.all) {
      if (econ.id == regimentTypeId) return econ.foodUpkeep;
    }
    return null;
  }
}
