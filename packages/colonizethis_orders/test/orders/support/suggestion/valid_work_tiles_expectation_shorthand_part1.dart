part of 'valid_work_tiles_expectation_shorthand.dart';


NwPartialRevealHomeTarget vwtTribePartialFx({
  Map<String, String> resourceByTileKey = const {},
  Map<String, Set<String>> playerProspectedTiles = const {},
}) =>
    NwPartialRevealHomeTarget(
      homeLocalId: 'home',
      targetLocalId: 'tribe1',
      targetOwnerId: 'tribe1',
      resourceByTileKey: resourceByTileKey,
      playerProspectedTiles: playerProspectedTiles,
    );

NwPartialRevealHomeTarget vwtTribeGrainIronFx({bool prospectedIron = false}) {
  final base = vwtTribePartialFx();
  return vwtTribePartialFx(
    resourceByTileKey: {base.t0: 'grain', base.t1: 'iron'},
    playerProspectedTiles: prospectedIron
        ? {ValidWorkTilesTestSupport.playerId: {base.t1}}
        : const {},
  );
}

Game vwtTribeConsulateGame(NwPartialRevealHomeTarget fx, {required String id}) =>
    fx.game(
      id: id,
      tribes: const [ValidWorkTilesTestSupport.defaultTribe],
      overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
    );

NwPartialRevealHomeTarget vwtMinorPurchaseFx({
  Map<String, String> resourceByTileKey = const {},
}) {
  final base = NwPartialRevealHomeTarget(
    homeLocalId: 'own',
    targetLocalId: 'm1',
    targetOwnerId: 'minor1',
  );
  return NwPartialRevealHomeTarget(
    homeLocalId: 'own',
    targetLocalId: 'm1',
    targetOwnerId: 'minor1',
    resourceByTileKey: resourceByTileKey.isEmpty
        ? {base.t1: 'grain'}
        : resourceByTileKey,
  );
}

Game vwtMinorPurchaseGame(
  NwPartialRevealHomeTarget fx, {
  required String id,
  List<OvertureState>? overtureStates,
}) =>
    fx.game(
      id: id,
      players: [ValidWorkTilesTestSupport.playerWithTreasury()],
      minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
      overtureStates: overtureStates,
      unit: Unit(
        id: 'u1',
        type: kUnitTypeMerchant,
        ownerId: ValidWorkTilesTestSupport.playerId,
        locationProvinceId: fx.provHome,
        tileKey: fx.tileHome,
      ),
    );

Iterable<WorkOrder> vwtSuggestExplore(Game game, MapTopology topology) =>
    suggestedWorkOrders(game: game, topology: topology).where(
      (o) => o.target == kWorkTargetExplore,
    );

Iterable<WorkOrder> vwtSuggestProspect(Game game, MapTopology topology) =>
    suggestedWorkOrders(game: game, topology: topology).where(
      (o) => o.target == kWorkTargetProspect,
    );

Iterable<WorkOrder> vwtSuggestPurchaseLand(
  Game game,
  MapTopology topology,
  String targetProvinceId,
) =>
    suggestedWorkOrders(game: game, topology: topology).where(
      (o) =>
          o.target == kWorkTargetPurchaseLand &&
          Unit.provinceIdFromTileKey(o.targetTileKey) == targetProvinceId,
    );

void vwtExpectVisProspectContains(
  Game game,
  MapTopology topology,
  String tile, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  expect(
    validWorkTilesWithVisibility(
      game: game,
      topology: topology,
      unitId: 'u1',
      workTarget: kWorkTargetProspect,
      tileMapByRegion: tileMapByRegion,
    ),
    contains(tile),
  );
}

void vwtExpectVisProspectExcludes(
  Game game,
  MapTopology topology,
  String tile, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  expect(
    validWorkTilesWithVisibility(
      game: game,
      topology: topology,
      unitId: 'u1',
      workTarget: kWorkTargetProspect,
      tileMapByRegion: tileMapByRegion,
    ).contains(tile),
    isFalse,
  );
}

void vwtExpectVisExplore({
  required Game game,
  required MapTopology topology,
  required Iterable<String> includedTiles,
  Iterable<String> excludedTiles = const [],
}) {
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: topology,
    unitId: 'u1',
    workTarget: kWorkTargetExplore,
  );
  for (final tile in includedTiles) {
    expect(valid, contains(tile));
  }
  for (final tile in excludedTiles) {
    expect(valid, isNot(contains(tile)));
  }
}

void vwtExpectVisExploreLatencyUnder({
  required Game game,
  required MapTopology topology,
  int maxMs = 1000,
}) {
  final sw = Stopwatch()..start();
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: topology,
    unitId: 'u1',
    workTarget: kWorkTargetExplore,
  );
  sw.stop();
  expect(valid, isNotEmpty);
  expect(sw.elapsedMilliseconds, lessThan(maxMs));
}

void vwtExpectNoMovesToProvince(
  Game game,
  MapTopology topology,
  String provinceId,
) {
  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );
  final suggestions = suggestMoveOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  expect(
    suggestions.where(
      (m) => Unit.provinceIdFromTileKey(m.destinationTileKey) == provinceId,
    ),
    isEmpty,
  );
}

void vwtExpectKeysEmpty(
  Game game,
  String unitId,
  String workTarget, {
  bool withVisibility = false,
}) {
  final keys = withVisibility
      ? vwtVisKeys(game, unitId, workTarget)
      : vwtPlainKeys(game, unitId, workTarget);
  expect(keys, isEmpty);
}

void vwtExpectBuildVisMembership(
  Game game, {
  required Iterable<String> included,
  Iterable<String> excluded = const [],
}) {
  final valid = vwtBuildVisKeys(game);
  for (final tile in included) {
    expect(valid.contains(tile), isTrue);
  }
  for (final tile in excluded) {
    expect(valid.contains(tile), isFalse);
  }
}

void vwtExpectMineralBuildGate({
  required String grainTile,
  required String ironTile,
}) {
  final p1 = ValidWorkTilesTestSupport.provinceId('p1');
  final provinces = [vwtOwnedProvince('p1')];
  final tiles = {p1: [grainTile, ironTile]};
  final resources = {grainTile: 'grain', ironTile: 'iron'};
  final improvements = {grainTile: 0, ironTile: 0};
  vwtExpectBuildVisMembership(
    owBuilderVisibilityGame(
      provinces: provinces,
      tilesByProvince: tiles,
      resourceByTileKey: resources,
      builderTileKey: grainTile,
      improvementByTile: improvements,
    ),
    included: [grainTile],
    excluded: [ironTile],
  );
  vwtExpectBuildVisMembership(
    owBuilderVisibilityGame(
      provinces: provinces,
      tilesByProvince: tiles,
      resourceByTileKey: resources,
      builderTileKey: grainTile,
      improvementByTile: improvements,
      playerProspectedTiles: {
        ValidWorkTilesTestSupport.playerId: {ironTile},
      },
    ),
    included: [grainTile, ironTile],
  );
}

void vwtExpectBuildResourceFilter({
  required List<Province> provinces,
  required Map<String, List<String>> tilesByProvince,
  required Map<String, String> resourceByTileKey,
  required String builderTileKey,
  required List<String> included,
  required List<String> excluded,
  Map<String, int>? improvementByTile,
  List<Player>? extraPlayers,
  Map<String, String>? purchasedTilesByTileKey,
  List<MinorNation>? minorNations,
  String? seaZoneId,
  List<String>? seaTiles,
}) {
  vwtExpectBuildVisMembership(
    owBuilderVisibilityGame(
      provinces: provinces,
      tilesByProvince: tilesByProvince,
      resourceByTileKey: resourceByTileKey,
      builderTileKey: builderTileKey,
      improvementByTile: improvementByTile ?? const {},
      extraPlayers: extraPlayers,
      purchasedTilesByTileKey: purchasedTilesByTileKey,
      minorNations: minorNations,
      seaZoneId: seaZoneId,
      seaTiles: seaTiles,
    ),
    included: included,
    excluded: excluded,
  );
}

void vwtExpectNoBuildSuggestionForReservedTile({
  required List<String> tileKeys,
  required String reservedTile,
}) {
  final game = owGrainBuildSuggestGame(tileKeys: tileKeys);
  final topology = owSingleProvinceTopology('p1');
  final buildSuggestions = suggestedWorkOrders(
    game: game,
    topology: topology,
    currentOrders: Orders(
      workOrdersByPlayerId: {
        ValidWorkTilesTestSupport.playerId: [
          WorkOrder(
            unitId: 'u1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: reservedTile,
          ),
        ],
      },
    ),
  ).where(
    (o) =>
        o.target == kWorkTargetBuildImprovement && o.targetTileKey == reservedTile,
  );
  expect(buildSuggestions, isEmpty);
}

void vwtExpectPurchaseLandIncluded(
  NwPartialRevealHomeTarget fx, {
  required String gameId,
  List<OvertureState>? overtureStates,
}) {
  expect(
    vwtSuggestPurchaseLand(
      vwtMinorPurchaseGame(
        fx,
        id: gameId,
        overtureStates: overtureStates,
      ),
      fx.topology(),
      fx.provTarget,
    ),
    isNotEmpty,
  );
}

void vwtExpectPurchaseLandExcluded(
  NwPartialRevealHomeTarget fx, {
  required String gameId,
}) {
  expect(
    vwtSuggestPurchaseLand(
      vwtMinorPurchaseGame(fx, id: gameId),
      fx.topology(),
      fx.provTarget,
    ),
    isEmpty,
  );
}

void vwtExpectVisProspectExcludesAll(
  Game game,
  MapTopology topology,
  Iterable<String> tiles, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: topology,
    unitId: 'u1',
    workTarget: kWorkTargetProspect,
    tileMapByRegion: tileMapByRegion,
  );
  for (final tile in tiles) {
    expect(valid.contains(tile), isFalse);
  }
}

void vwtExpectSuggestExploreTargetsProvince(
  Game game,
  MapTopology topology,
  String provinceId,
) {
  final explore = vwtSuggestExplore(game, topology).toList();
  expect(explore, isNotEmpty);
  expect(
    explore.any(
      (o) => Unit.provinceIdFromTileKey(o.targetTileKey) == provinceId,
    ),
    isTrue,
  );
}

void vwtExpectSuggestExploreExcludesProvince(
  Game game,
  MapTopology topology,
  String provinceId,
) {
  expect(
    vwtSuggestExplore(game, topology).where(
      (o) => Unit.provinceIdFromTileKey(o.targetTileKey) == provinceId,
    ),
    isEmpty,
  );
}

void vwtExpectSuggestProspectIncludesTile(
  Game game,
  MapTopology topology,
  String tileKey,
) {
  final prospect = vwtSuggestProspect(game, topology).toList();
  expect(prospect, isNotEmpty);
  expect(prospect.any((o) => o.targetTileKey == tileKey), isTrue);
}
