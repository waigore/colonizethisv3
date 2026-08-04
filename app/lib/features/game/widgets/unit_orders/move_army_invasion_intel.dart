// Fog-respecting invasion intel for DLG20001. SPEC/ui/move-army-dialog.md (#4216).

import 'package:colonizethis_data/colonizethis_data.dart'
    show canUnitInitiateCombat;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

enum MoveArmyInvasionIntelLevel { unknown, full }

/// Player-legal military summary for one invasion destination province.
class MoveArmyInvasionIntelSummary {
  const MoveArmyInvasionIntelSummary({
    required this.intelLevel,
    this.defenderCombatCapableCount,
    this.defenderTypesByRegimentId = const {},
    this.fortLevel,
  });

  final MoveArmyInvasionIntelLevel intelLevel;
  final int? defenderCombatCapableCount;
  final Map<String, int> defenderTypesByRegimentId;
  final int? fortLevel;

  bool get unopposed =>
      intelLevel == MoveArmyInvasionIntelLevel.full &&
      defenderCombatCapableCount == 0;
}

int moveArmyOwnRegimentCount(Army army) => army.regimentUnitIds.length;

Map<String, int> moveArmyOwnRegimentTypesById({
  required Army army,
  required Game game,
}) {
  final byType = <String, int>{};
  final unitsById = game.worldState.allUnitsById;
  for (final unitId in army.regimentUnitIds) {
    final type = unitsById[unitId]?.type;
    if (type == null) continue;
    byType[type] = (byType[type] ?? 0) + 1;
  }
  return byType;
}

MoveArmyInvasionIntelSummary computeMoveArmyInvasionIntelSummary({
  required Game game,
  required PlayerView? playerView,
  required String humanPlayerId,
  required String destinationProvinceId,
}) {
  if (playerView == null) {
    return const MoveArmyInvasionIntelSummary(
      intelLevel: MoveArmyInvasionIntelLevel.unknown,
    );
  }

  final regionId = ProvinceId.regionIdFrom(destinationProvinceId);
  final tileKeys =
      game.worldState.tileKeysByRegionAndProvince[regionId]?[destinationProvinceId] ??
      const <String>[];

  final showsFullIntel = provincePanelShowsFullTileDerivedIntel(
    game: game,
    view: playerView,
    humanPlayerId: humanPlayerId,
    provinceId: destinationProvinceId,
    provinceTileKeys: tileKeys,
  );

  if (!showsFullIntel) {
    return const MoveArmyInvasionIntelSummary(
      intelLevel: MoveArmyInvasionIntelLevel.unknown,
    );
  }

  final regionData = regionId == kRegionNewWorld
      ? game.worldState.newWorld
      : game.worldState.oldWorld;

  var combatCapableCount = 0;
  final typesByRegiment = <String, int>{};
  for (final unit in regionData.units) {
    if (unit.locationProvinceId != destinationProvinceId) continue;
    if (!canUnitInitiateCombat(unit.type)) continue;
    combatCapableCount++;
    typesByRegiment[unit.type] = (typesByRegiment[unit.type] ?? 0) + 1;
  }

  final province = game.worldState.tryGetProvince(destinationProvinceId);
  final fortLevel = province?.fortLevel ?? 0;

  return MoveArmyInvasionIntelSummary(
    intelLevel: MoveArmyInvasionIntelLevel.full,
    defenderCombatCapableCount: combatCapableCount,
    defenderTypesByRegimentId: typesByRegiment,
    fortLevel: fortLevel,
  );
}
