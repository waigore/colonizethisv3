// Fog-respecting Blockade harbor intel for DLG31002. SPEC/ui/naval-mission-target-dialog.md (#4340).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

enum NavalMissionHarborIntelLevel { unknown, full }

/// Player-legal port / in-port fleet summary for one Blockade target.
class NavalMissionHarborIntelSummary {
  const NavalMissionHarborIntelSummary({
    required this.intelLevel,
    this.portPresent,
    this.hostileFleetsInPortCount,
  });

  final NavalMissionHarborIntelLevel intelLevel;
  final bool? portPresent;
  final int? hostileFleetsInPortCount;

  bool get emptyHarbor =>
      intelLevel == NavalMissionHarborIntelLevel.full &&
      portPresent == true &&
      hostileFleetsInPortCount == 0;
}

bool navalMissionProvinceHasAnyPort({
  required Game game,
  required String prefixedProvinceId,
}) {
  final localProvinceId = ProvinceId.localIdFrom(prefixedProvinceId);
  final prefix = '$prefixedProvinceId|';
  final localPrefix = '$localProvinceId|';
  return game.worldState.portsByProvinceSeaboard.keys.any(
    (key) => key.startsWith(prefix) || key.startsWith(localPrefix),
  );
}

NavalMissionHarborIntelSummary computeNavalMissionHarborIntelSummary({
  required Game game,
  required PlayerView? playerView,
  required String humanPlayerId,
  required String targetProvinceId,
}) {
  if (playerView == null) {
    return const NavalMissionHarborIntelSummary(
      intelLevel: NavalMissionHarborIntelLevel.unknown,
    );
  }

  final regionId = ProvinceId.regionIdFrom(targetProvinceId);
  final tileKeys =
      game.worldState.tileKeysByRegionAndProvince[regionId]?[targetProvinceId] ??
      const <String>[];

  final showsFullIntel = provincePanelShowsFullTileDerivedIntel(
    game: game,
    view: playerView,
    humanPlayerId: humanPlayerId,
    provinceId: targetProvinceId,
    provinceTileKeys: tileKeys,
  );

  if (!showsFullIntel) {
    return const NavalMissionHarborIntelSummary(
      intelLevel: NavalMissionHarborIntelLevel.unknown,
    );
  }

  final portPresent = navalMissionProvinceHasAnyPort(
    game: game,
    prefixedProvinceId: targetProvinceId,
  );
  final fleetsInPort = fleetsInPortAtProvince(game.worldState, targetProvinceId);
  final enemies = enemiesOf(game, humanPlayerId);
  var hostileCount = 0;
  for (final fleet in fleetsInPort) {
    if (enemies.contains(fleet.ownerId)) {
      hostileCount++;
    }
  }

  return NavalMissionHarborIntelSummary(
    intelLevel: NavalMissionHarborIntelLevel.full,
    portPresent: portPresent,
    hostileFleetsInPortCount: hostileCount,
  );
}
