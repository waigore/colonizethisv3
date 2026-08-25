/// Fleet inclusion and capital-port home-fleet checks.
/// SPEC/ui/map-widget.md § Fleet tile markers. Refs #4654.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import '../tile_key_util.dart';

String homeFleetIdForMapMarker(String playerId) => 'fleet_$playerId';

bool fleetAtHumanCapital(Game game, String playerId, Fleet fleet) {
  if (!fleet.isInPort || fleet.inPortAtProvinceId == null) {
    return false;
  }
  final player = game.players.firstWhere(
    (p) => p.id == playerId,
    orElse: () => game.players.first,
  );
  if (!player.isHuman) {
    return false;
  }
  final cap = player.capitalTile;
  if (cap == null) {
    return false;
  }
  final parsed = tryParseMapTileKey(cap.toTileKey());
  if (parsed == null) {
    return false;
  }
  final capReg = parsed.regionId;
  final capProvLocal = parsed.localId;
  if (fleet.regionId != capReg) {
    return false;
  }
  final port = fleet.inPortAtProvinceId!;
  return port == capProvLocal || port == '$capReg|$capProvLocal';
}

bool includeFleetForTileMarker(
  Game game,
  Fleet fleet,
  String regionId,
  Set<String> humanIds,
) {
  if (!humanIds.contains(fleet.ownerId) || fleet.regionId != regionId) {
    return false;
  }
  if (fleet.shipTypeIds.isNotEmpty) {
    return true;
  }
  return fleet.id == homeFleetIdForMapMarker(fleet.ownerId) &&
      fleetAtHumanCapital(game, fleet.ownerId, fleet);
}
