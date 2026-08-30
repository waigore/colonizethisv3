// Local helpers for DEVELOP NW-suppression planner-set pins (Refs #2509 S4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

bool isNwProvinceId(String provinceId) =>
    ProvinceId.regionIdFrom(provinceId) == kNewWorldRegionId;

bool isNonGpFaction(Game game, String factionId) {
  if (game.tribes.any((t) => t.id == factionId)) return true;
  if (game.minorNations.any((m) => m.id == factionId)) return true;
  return false;
}

String? ownerOfProvinceContainingTile(Game game, String tileKey) {
  final provinceId = Unit.provinceIdFromTileKey(tileKey);
  if (provinceId == null) return null;
  for (final region in <RegionData>[
    game.worldState.oldWorld,
    game.worldState.newWorld,
  ]) {
    for (final p in region.provinces) {
      if (p.id == provinceId) return p.ownerId;
    }
  }
  return null;
}
