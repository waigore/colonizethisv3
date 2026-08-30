/// WorldState JSON encode helper (Refs #4136, #4571).
library;

import 'world_state.dart';

Map<String, dynamic> encodeWorldStateToJson(WorldState worldState) {
  return {
    'turnState': worldState.turnState.toJson(),
    'oldWorld': worldState.oldWorld.toJson(),
    'newWorld': worldState.newWorld.toJson(),
    'tileState': worldState.tileState.toJson(),
    'portsByProvinceSeaboard': worldState.portsByProvinceSeaboard,
    if (worldState.playerVisibilityByTile.isNotEmpty)
      'playerVisibilityByTile': worldState.playerVisibilityByTile,
    if (worldState.playerProspectedTiles.isNotEmpty)
      'playerProspectedTiles': worldState.playerProspectedTiles.map(
        (playerId, tiles) => MapEntry(playerId, tiles.toList()),
      ),
    if (worldState.fleets.isNotEmpty)
      'fleets': worldState.fleets.map((e) => e.toJson()).toList(),
    if (worldState.tileKeysByRegionAndProvince.isNotEmpty)
      'tileKeysByRegionAndProvince':
          worldState.tileKeysByRegionAndProvince.map(
        (regionId, byProvince) => MapEntry(
          regionId,
          byProvince.map((provinceId, keys) => MapEntry(provinceId, keys)),
        ),
      ),
    if (worldState.spyRevealTurnsByPlayer.isNotEmpty)
      'spyRevealTurnsByPlayer': worldState.spyRevealTurnsByPlayer,
    if (worldState.purchasedTilesByTileKey.isNotEmpty)
      'purchasedTilesByTileKey': worldState.purchasedTilesByTileKey,
    if (worldState.resourceByTileKey.isNotEmpty)
      'resourceByTileKey': worldState.resourceByTileKey,
    if (worldState.seaZoneDisplayNameById.isNotEmpty)
      'seaZoneDisplayNameById': worldState.seaZoneDisplayNameById,
    'nextShipInstanceSeq': worldState.nextShipInstanceSeq,
    if (worldState.armies.isNotEmpty)
      'armies': worldState.armies.map((e) => e.toJson()).toList(),
    if (worldState.nextArmySeq != 1) 'nextArmySeq': worldState.nextArmySeq,
    if (worldState.newsDigestProvinceRevealDoneIds.isNotEmpty)
      'newsDigestProvinceRevealDoneIds':
          worldState.newsDigestProvinceRevealDoneIds,
    if (worldState.newsDigestSeaZoneFleetDoneIds.isNotEmpty)
      'newsDigestSeaZoneFleetDoneIds':
          worldState.newsDigestSeaZoneFleetDoneIds,
  };
}
