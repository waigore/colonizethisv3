part of 'order_suggestion_core_expectation_shorthand.dart';

List<T> _oscWithViewSuggest<T>(
  Game game,
  MapTopology topology,
  Orders orders,
  List<T> Function(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders orders,
  ) suggest,
) =>
    suggest(oscView(game, topology), game, topology, orders);

List<MoveOrder> oscSuggestMoves(
  Game game,
  MapTopology topology, [
  Orders orders = const Orders(),
]) =>
    _oscWithViewSuggest(game, topology, orders, suggestMoveOrders);

List<WorkOrder> oscSuggestWork(
  Game game,
  MapTopology topology, [
  Orders orders = const Orders(),
]) =>
    _oscWithViewSuggest(game, topology, orders, suggestWorkOrders);

List<BuildUnitOrder> oscSuggestBuild(
  Game game,
  MapTopology topology, [
  Orders orders = const Orders(),
]) =>
    _oscWithViewSuggest(game, topology, orders, suggestBuildOrders);

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

Game oscSpyInOwnedProvinceGame() {
  final tileKey = OscIds.tile('p1', 0, 0);
  return oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [oscProvince('p1', ownerId: OscIds.playerId)],
        units: [
          Unit(
            id: 'u1',
            type: kUnitTypeSpy,
            ownerId: OscIds.playerId,
            locationProvinceId: OscIds.prov('p1'),
          ),
        ],
      ),
      playerVisibilityByTile: oscVisibility({tileKey: 'fullyVisible'}),
      tileKeysByRegionAndProvince: oscTilesByProvince({'p1': [tileKey]}),
    ),
  );
}

Game oscFoggedDestinationMoveGame() {
  final p1 = oscProvince('p1', ownerId: OscIds.playerId);
  final p2 = oscProvince('p2');
  return oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(provinces: [p1, p2], units: [oscExplorer()]),
      tileKeysByRegionAndProvince: oscTilesByProvince({
        'p2': [OscIds.tile('p2', 0, 0)],
      }),
      playerVisibilityByTile: oscVisibility({
        OscIds.tile('p1', 0, 0): 'fullyVisible',
        OscIds.tile('p2', 0, 0): 'fogged',
      }),
    ),
  );
}

Game oscMislocatedExplorerMoveGame() {
  final unit = oscExplorer(provinceLocal: 'p1', tileKey: OscIds.tile('p2', 0, 0));
  return oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [
          oscProvince('p1', ownerId: OscIds.playerId),
          oscProvince('p2', ownerId: OscIds.playerId),
          oscProvince('p3', ownerId: OscIds.playerId),
        ],
        units: [unit],
      ),
      tileKeysByRegionAndProvince: oscTilesByProvince({
        'p3': [OscIds.tile('p3', 0, 0)],
      }),
      playerVisibilityByTile: oscVisibility({
        OscIds.tile('p2', 0, 0): 'fullyVisible',
        OscIds.tile('p3', 0, 0): 'fogged',
      }),
    ),
  );
}

MapTopology oscMislocatedExplorerTopology() => oscProvinceTopology(
  ['p1', 'p2', 'p3'],
  edges: const [TopologyEdge(id1: 'p2', id2: 'p3')],
);

Game oscTwoProvinceExplorerUnknownVisibilityGame() => oscGame(
      worldState: oscWorld(
        oldWorld: RegionData(
          provinces: [
            oscProvince('p1', ownerId: OscIds.playerId),
            oscProvince('p2', ownerId: OscIds.playerId),
          ],
          units: [oscExplorer()],
        ),
      ),
    );

Game oscBuilderWorkerSuggestGame() {
  final tileKey = OscIds.tile('p1', 0, 0);
  return oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [oscProvince('p1', ownerId: OscIds.playerId)],
        units: [oscBuilder()],
      ),
      playerVisibilityByTile: oscVisibility({tileKey: 'fullyVisible'}),
      tileKeysByRegionAndProvince: oscTilesByProvince({'p1': [tileKey]}),
    ),
    players: [oscBuilderPlayer()],
  );
}

Game oscMerchantPurchaseLandGame() {
  final tileKey = OscIds.tile('minor1', 0, 0);
  return oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [
          oscProvince('p1', ownerId: OscIds.playerId),
          oscProvince('minor1', ownerId: 'minor1'),
        ],
        units: [
          Unit(
            id: 'u1',
            type: kUnitTypeMerchant,
            ownerId: OscIds.playerId,
            locationProvinceId: OscIds.prov('p1'),
          ),
        ],
      ),
      playerVisibilityByTile: oscVisibility({
        OscIds.tile('p1', 0, 0): 'fullyVisible',
        tileKey: 'fullyVisible',
      }),
      tileKeysByRegionAndProvince: oscTilesByProvince({
        'p1': [OscIds.tile('p1', 0, 0)],
        'minor1': [tileKey],
      }),
      resourceByTileKey: {tileKey: 'grain'},
    ),
    players: [oscPlayer(treasury: 500)],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
    overtureStates: const [
      OvertureState(
        gpId: OscIds.playerId,
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
  );
}
