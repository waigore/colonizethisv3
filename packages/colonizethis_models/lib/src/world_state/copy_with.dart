/// [WorldState.copyWith] extracted so the host stays under the models
/// physical-line cap (Refs #4571).
///
/// Provided as a [mixin] (not an extension) so `import … show WorldState`
/// still resolves `worldState.copyWith(...)` — extensions are invisible
/// under `show`.
part of '../world_state.dart';

WorldState worldStateCopyWith(
  WorldState state, {
  TurnState? turnState,
  RegionData? oldWorld,
  RegionData? newWorld,
  TileMapState? tileState,
  Map<String, String>? portsByProvinceSeaboard,
  Map<String, Map<String, String>>? playerVisibilityByTile,
  Map<String, Set<String>>? playerProspectedTiles,
  List<Fleet>? fleets,
  Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
  Map<String, Map<String, int>>? spyRevealTurnsByPlayer,
  Map<String, String>? purchasedTilesByTileKey,
  Map<String, String>? resourceByTileKey,
  Map<String, String>? seaZoneDisplayNameById,
  int? nextShipInstanceSeq,
  List<Army>? armies,
  int? nextArmySeq,
  List<String>? newsDigestProvinceRevealDoneIds,
  List<String>? newsDigestSeaZoneFleetDoneIds,
}) {
  return WorldState(
    turnState: turnState ?? state.turnState,
    oldWorld: oldWorld ?? state.oldWorld,
    newWorld: newWorld ?? state.newWorld,
    tileState: tileState ?? state.tileState,
    portsByProvinceSeaboard:
        portsByProvinceSeaboard ?? state.portsByProvinceSeaboard,
    playerVisibilityByTile:
        playerVisibilityByTile ?? state.playerVisibilityByTile,
    playerProspectedTiles:
        playerProspectedTiles ?? state.playerProspectedTiles,
    fleets: fleets ?? state.fleets,
    tileKeysByRegionAndProvince:
        tileKeysByRegionAndProvince ?? state.tileKeysByRegionAndProvince,
    spyRevealTurnsByPlayer:
        spyRevealTurnsByPlayer ?? state.spyRevealTurnsByPlayer,
    purchasedTilesByTileKey:
        purchasedTilesByTileKey ?? state.purchasedTilesByTileKey,
    resourceByTileKey: resourceByTileKey ?? state.resourceByTileKey,
    seaZoneDisplayNameById:
        seaZoneDisplayNameById ?? state.seaZoneDisplayNameById,
    nextShipInstanceSeq: nextShipInstanceSeq ?? state.nextShipInstanceSeq,
    armies: armies ?? state.armies,
    nextArmySeq: nextArmySeq ?? state.nextArmySeq,
    newsDigestProvinceRevealDoneIds:
        newsDigestProvinceRevealDoneIds ??
        state.newsDigestProvinceRevealDoneIds,
    newsDigestSeaZoneFleetDoneIds:
        newsDigestSeaZoneFleetDoneIds ?? state.newsDigestSeaZoneFleetDoneIds,
  );
}

/// Instance [WorldState.copyWith] via mixin so `show WorldState` importers
/// keep access (Refs #4571). Unconstrained mixin avoids recursive
/// `on WorldState` inheritance.
mixin WorldStateCopyWith {
  WorldState copyWith({
    TurnState? turnState,
    RegionData? oldWorld,
    RegionData? newWorld,
    TileMapState? tileState,
    Map<String, String>? portsByProvinceSeaboard,
    Map<String, Map<String, String>>? playerVisibilityByTile,
    Map<String, Set<String>>? playerProspectedTiles,
    List<Fleet>? fleets,
    Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
    Map<String, Map<String, int>>? spyRevealTurnsByPlayer,
    Map<String, String>? purchasedTilesByTileKey,
    Map<String, String>? resourceByTileKey,
    Map<String, String>? seaZoneDisplayNameById,
    int? nextShipInstanceSeq,
    List<Army>? armies,
    int? nextArmySeq,
    List<String>? newsDigestProvinceRevealDoneIds,
    List<String>? newsDigestSeaZoneFleetDoneIds,
  }) =>
      worldStateCopyWith(
        this as WorldState,
        turnState: turnState,
        oldWorld: oldWorld,
        newWorld: newWorld,
        tileState: tileState,
        portsByProvinceSeaboard: portsByProvinceSeaboard,
        playerVisibilityByTile: playerVisibilityByTile,
        playerProspectedTiles: playerProspectedTiles,
        fleets: fleets,
        tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
        spyRevealTurnsByPlayer: spyRevealTurnsByPlayer,
        purchasedTilesByTileKey: purchasedTilesByTileKey,
        resourceByTileKey: resourceByTileKey,
        seaZoneDisplayNameById: seaZoneDisplayNameById,
        nextShipInstanceSeq: nextShipInstanceSeq,
        armies: armies,
        nextArmySeq: nextArmySeq,
        newsDigestProvinceRevealDoneIds: newsDigestProvinceRevealDoneIds,
        newsDigestSeaZoneFleetDoneIds: newsDigestSeaZoneFleetDoneIds,
      );
}
