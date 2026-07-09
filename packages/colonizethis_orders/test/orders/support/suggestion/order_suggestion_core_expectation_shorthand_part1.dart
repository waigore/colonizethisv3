part of 'order_suggestion_core_expectation_shorthand.dart';

List<MoveOrder> oscSuggestMoves(
  Game game,
  MapTopology topology, [
  Orders orders = const Orders(),
]) =>
    suggestMoveOrders(oscView(game, topology), game, topology, orders);

List<WorkOrder> oscSuggestWork(
  Game game,
  MapTopology topology, [
  Orders orders = const Orders(),
]) =>
    suggestWorkOrders(oscView(game, topology), game, topology, orders);

List<BuildUnitOrder> oscSuggestBuild(
  Game game,
  MapTopology topology, [
  Orders orders = const Orders(),
]) =>
    suggestBuildOrders(oscView(game, topology), game, topology, orders);

Iterable<WorkOrder> oscWorkWithTarget(
  List<WorkOrder> suggestions,
  String target,
) =>
    suggestions.where((o) => o.target == target);

Game oscExplorerProvinceGame({
  String provinceLocal = 'p1',
  String? ownerId = OscIds.playerId,
  Map<String, String>? visibilityByTile,
  Map<String, List<String>>? tilesByLocal,
  List<String>? extraProvinceLocals,
  List<String>? extraOwners,
}) {
  final provinces = [
    oscProvince(provinceLocal, ownerId: ownerId),
    for (var i = 0; i < (extraProvinceLocals?.length ?? 0); i++)
      oscProvince(
        extraProvinceLocals![i],
        ownerId: extraOwners != null && i < extraOwners.length
            ? extraOwners[i]
            : ownerId,
      ),
  ];
  return oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: provinces,
        units: [oscExplorer(provinceLocal: provinceLocal)],
      ),
      playerVisibilityByTile:
          visibilityByTile != null ? oscVisibility(visibilityByTile) : null,
      tileKeysByRegionAndProvince:
          tilesByLocal != null ? oscTilesByProvince(tilesByLocal) : null,
    ),
  );
}

Game oscBuilderImprovementGame({
  required String tileNoResource,
  required String tileWithResource,
  String provinceLocal = 'p1',
  String? secondProvinceLocal,
  String? secondTile,
  String resource = 'grain',
}) {
  final provinces = [
    oscProvince(provinceLocal, ownerId: OscIds.playerId),
    if (secondProvinceLocal != null)
      oscProvince(secondProvinceLocal, ownerId: OscIds.playerId),
  ];
  final tilesByLocal = {
    provinceLocal: secondProvinceLocal == null
        ? [tileNoResource, tileWithResource]
        : [tileNoResource],
    if (secondProvinceLocal != null && secondTile != null)
      secondProvinceLocal: [secondTile],
  };
  final visibility = {
    tileNoResource: 'fullyVisible',
    tileWithResource: 'fullyVisible',
    if (secondTile != null) secondTile: 'fullyVisible',
  };
  return oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: provinces,
        units: [
          oscBuilder(provinceLocal: provinceLocal, tileKey: tileNoResource),
        ],
      ),
      playerVisibilityByTile: oscVisibility(visibility),
      tileKeysByRegionAndProvince: oscTilesByProvince(tilesByLocal),
      resourceByTileKey: {
        tileWithResource: resource,
        if (secondTile != null) secondTile: resource,
      },
      tileState: TileMapState(
        improvementByTile: {
          tileWithResource: 0,
          if (secondTile != null) secondTile: 0,
        },
      ),
    ),
    players: [oscBuilderPlayer()],
  );
}
