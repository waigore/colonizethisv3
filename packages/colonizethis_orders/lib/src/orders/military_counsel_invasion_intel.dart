/// Fog-respecting invasion intel for military counsel. SPEC/program/military-counsel-ranking.md.
library;

import 'package:colonizethis_data/colonizethis_data.dart'
    show canUnitInitiateCombat;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'military_counsel_types.dart';

MilitaryCounselInvasionIntelSummary militaryCounselInvasionIntelSummary({
  required Game game,
  required PlayerView view,
  required String playerId,
  required String destinationProvinceId,
}) {
  final regionId = ProvinceId.regionIdFrom(destinationProvinceId);
  final tileKeys =
      game.worldState.tileKeysByRegionAndProvince[regionId]?[
          ProvinceId.localIdFrom(destinationProvinceId)] ??
      const <String>[];

  final showsFullIntel = provincePanelShowsFullTileDerivedIntel(
    game: game,
    view: view,
    humanPlayerId: playerId,
    provinceId: destinationProvinceId,
    provinceTileKeys: tileKeys,
  );

  if (!showsFullIntel) {
    return const MilitaryCounselInvasionIntelSummary(
      intelLevel: MilitaryCounselInvasionIntelLevel.unknown,
    );
  }

  final regionData = regionId == kRegionNewWorld
      ? game.worldState.newWorld
      : game.worldState.oldWorld;

  var combatCapableCount = 0;
  for (final unit in regionData.units) {
    if (unit.locationProvinceId != destinationProvinceId) continue;
    if (!canUnitInitiateCombat(unit.type)) continue;
    combatCapableCount++;
  }

  final province = game.worldState.tryGetProvince(destinationProvinceId);
  final fortLevel = province?.fortLevel ?? 0;

  return MilitaryCounselInvasionIntelSummary(
    intelLevel: MilitaryCounselInvasionIntelLevel.full,
    defenderCombatCapableCount: combatCapableCount,
    fortLevel: fortLevel,
  );
}
