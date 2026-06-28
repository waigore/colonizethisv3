import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'province_lookup.dart';

/// Minor military parity step. SPEC/game/factions.md, SPEC/program/turn-resolution-phases.md.
///
/// In the Minor Regiment Upgrade phase: compute maxGreatPowerMilitaryLevel from
/// all GPs; set each MinorNation effectiveMilitaryLevel = max; upgrade eligible
/// minor land regiments in place to that era; set each Tribe
/// effectiveMilitaryLevel = 1 (no parity).
Game applyMinorMilitaryParity(Game game) {
  int maxLevel = 1;
  for (final player in game.players) {
    final level = player.militaryLevel ?? 1;
    if (level > maxLevel) maxLevel = level;
  }

  final updatedMinors = <MinorNation>[];
  for (final m in game.minorNations) {
    updatedMinors.add(m.copyWith(effectiveMilitaryLevel: maxLevel));
  }
  final minorIds = {for (final m in updatedMinors) m.id};

  Unit upgradeMinorLandRegiment(Unit unit) {
    if (!minorIds.contains(unit.ownerId)) return unit;
    final stats = regimentStatsById(unit.type);
    if (stats == null || stats.era >= maxLevel) return unit;
    final upgraded = _regimentIdForCategoryAndEra(stats.category, maxLevel);
    if (upgraded == null || upgraded == unit.type) return unit;
    return unit.copyWith(type: upgraded);
  }

  const tribeEffectiveLevel = 1;
  final updatedTribes = <Tribe>[];
  for (final t in game.tribes) {
    updatedTribes.add(t.copyWith(effectiveMilitaryLevel: tribeEffectiveLevel));
  }

  if (updatedMinors.isEmpty && updatedTribes.isEmpty) return game;

  return game.copyWith(
    minorNations: updatedMinors.isEmpty ? game.minorNations : updatedMinors,
    tribes: updatedTribes.isEmpty ? game.tribes : updatedTribes,
    worldState: game.worldState.mapBothRegionUnits(
      (_, units) => units.map(upgradeMinorLandRegiment).toList(growable: false),
    ),
  );
}

String? _regimentIdForCategoryAndEra(RegimentCategory category, int era) {
  for (final regiment in regimentCatalog) {
    if (regiment.category == category && regiment.era == era) {
      return regiment.id;
    }
  }
  return null;
}
