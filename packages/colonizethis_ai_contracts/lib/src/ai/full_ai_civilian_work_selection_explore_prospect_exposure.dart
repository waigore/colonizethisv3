import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';

import '../constants.dart';

// Mineral-exposure accounting for Full AI explorer/prospect candidate scoring
// (Refs #4368 Slice B). Split from explore_prospect.dart by concern.

bool observationEligibleForExposure(
  PlayerView view,
  Game game,
  String playerId,
  String tileKey,
  Province province,
) {
  if (view.visibilityForTile(tileKey) == VisibilityLevel.fullyVisible) {
    return true;
  }
  if (province.ownerId == playerId) return true;
  return false;
}

bool tileShowsMineralForExposure(
  Game game,
  String playerId,
  String tileKey,
  String mineralId,
) {
  final res = game.worldState.resourceByTileKey[tileKey];
  if (res == mineralId) return true;
  final prospected =
      game.worldState.playerProspectedTiles[playerId] ?? const <String>{};
  return prospected.contains(tileKey) && res == mineralId;
}

void bumpExposureForTile(
  Game game,
  PlayerView view,
  String playerId,
  String tileKey,
  Province province,
  Map<String, int> counts,
) {
  if (!observationEligibleForExposure(view, game, playerId, tileKey, province)) {
    return;
  }
  for (final m in kMineralResourceIds) {
    if (!tileShowsMineralForExposure(game, playerId, tileKey, m)) continue;
    counts[m] = (counts[m] ?? 0) + 1;
  }
}

void bumpExposureForProvinceEntry(
  Game game,
  PlayerView view,
  String playerId,
  MapEntry<String, List<String>> entry,
  Map<String, int> counts,
) {
  final province = game.worldState.tryGetProvince(entry.key);
  if (province == null) return;
  for (final tk in entry.value) {
    bumpExposureForTile(game, view, playerId, tk, province, counts);
  }
}

Map<String, int> exposureCountsByMineral(
  Game game,
  PlayerView view,
  String playerId,
) {
  final counts = <String, int>{for (final m in kMineralResourceIds) m: 0};
  for (final byProvince in game.worldState.tileKeysByRegionAndProvince.values) {
    for (final entry in byProvince.entries) {
      bumpExposureForProvinceEntry(game, view, playerId, entry, counts);
    }
  }
  return counts;
}

Set<String> mineralsWithMinExposure(Map<String, int> exposure) {
  if (exposure.isEmpty) return {};
  var minV = 1 << 30;
  for (final v in exposure.values) {
    if (v < minV) minV = v;
  }
  return exposure.entries
      .where((e) => e.value == minV)
      .map((e) => e.key)
      .toSet();
}
