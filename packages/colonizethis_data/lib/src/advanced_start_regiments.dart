import 'combat_config.dart';
import 'tech_extraction.dart';

/// Macro military branch for advanced-start regiment composition.
/// SPEC/game/advanced-starts.md — best buildable type per branch, balanced count.
enum AdvancedStartMilitaryBranch {
  infantry,
  cavalry,
  artillery,
}

AdvancedStartMilitaryBranch advancedStartMilitaryBranchForCategory(
  RegimentCategory category,
) {
  return switch (category) {
    RegimentCategory.lightInfantry ||
    RegimentCategory.regularInfantry ||
    RegimentCategory.heavyInfantry ||
    RegimentCategory.bowmen =>
      AdvancedStartMilitaryBranch.infantry,
    RegimentCategory.lightCavalry ||
    RegimentCategory.spearCavalry ||
    RegimentCategory.heavyCavalry =>
      AdvancedStartMilitaryBranch.cavalry,
    RegimentCategory.lightArtillery ||
    RegimentCategory.heavyArtillery =>
      AdvancedStartMilitaryBranch.artillery,
  };
}

bool isRegimentBuildableWithTechs(
  RegimentStats regiment,
  Map<String, bool>? techUnlocked,
) {
  final unlockingTech = unlockingTechByRegimentId[regiment.id];
  return unlockingTech == null || (techUnlocked?[unlockingTech] ?? false);
}

int regimentPowerScore(RegimentStats regiment) => regiment.fpn + regiment.fpm;

/// Best buildable regiment in [branch] for [techUnlocked]: highest era, then FPN+FPM.
RegimentStats? bestBuildableRegimentInBranch(
  AdvancedStartMilitaryBranch branch,
  Map<String, bool>? techUnlocked,
) {
  RegimentStats? best;
  for (final regiment in regimentCatalog) {
    if (advancedStartMilitaryBranchForCategory(regiment.category) != branch) {
      continue;
    }
    if (!isRegimentBuildableWithTechs(regiment, techUnlocked)) continue;
    if (best == null ||
        regiment.era > best.era ||
        (regiment.era == best.era &&
            regimentPowerScore(regiment) > regimentPowerScore(best))) {
      best = regiment;
    }
  }
  return best;
}

/// Balanced regiment type ids for advanced start: equal split across infantry,
/// cavalry, and artillery using the best buildable type per branch.
List<String> advancedStartRegimentTypeIds({
  required Map<String, bool>? techUnlocked,
  required int totalCount,
}) {
  if (totalCount <= 0) return const [];
  const branches = AdvancedStartMilitaryBranch.values;
  final typeByBranch = <AdvancedStartMilitaryBranch, String>{};
  for (final branch in branches) {
    final best = bestBuildableRegimentInBranch(branch, techUnlocked);
    if (best == null) {
      throw StateError('advanced start: no buildable regiment for $branch');
    }
    typeByBranch[branch] = best.id;
  }

  final base = totalCount ~/ branches.length;
  var remainder = totalCount % branches.length;
  final out = <String>[];
  for (final branch in branches) {
    var count = base;
    if (remainder > 0) {
      count++;
      remainder--;
    }
    final typeId = typeByBranch[branch]!;
    for (var i = 0; i < count; i++) {
      out.add(typeId);
    }
  }
  return out;
}
