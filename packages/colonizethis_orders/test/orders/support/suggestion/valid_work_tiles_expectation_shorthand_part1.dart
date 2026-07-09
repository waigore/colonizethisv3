part of 'valid_work_tiles_expectation_shorthand.dart';


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
  final valid = vwtVisKeys(game, 'u1', kWorkTargetBuildImprovement);
  for (final tile in included) {
    expect(valid.contains(tile), isTrue);
  }
  for (final tile in excluded) {
    expect(valid.contains(tile), isFalse);
  }
}

List<WorkOrder> vwtPartialRevealSuggestions(
  NwPartialRevealHomeTarget fx,
  Game game,
  String workTarget,
) =>
    suggestedWorkOrders(game: game, topology: fx.topology())
        .where((o) => o.target == workTarget)
        .toList();

void vwtExpectPartialRevealSuggestions({
  required NwPartialRevealHomeTarget fx,
  required Game game,
  required String workTarget,
  required bool expectNonEmpty,
  String? provinceId,
  String? tileKey,
}) {
  var orders = vwtPartialRevealSuggestions(fx, game, workTarget);
  if (provinceId != null) {
    orders = orders
        .where((o) => Unit.provinceIdFromTileKey(o.targetTileKey) == provinceId)
        .toList();
  }
  if (tileKey != null && expectNonEmpty) {
    expect(orders.any((o) => o.targetTileKey == tileKey), isTrue);
    return;
  }
  expect(orders, expectNonEmpty ? isNotEmpty : isEmpty);
}

Set<String> vwtProspectVisKeys(
  Game game, {
  Map<String, TileMapResult>? tileMapByRegion,
}) =>
    validWorkTilesWithVisibility(
      game: game,
      topology: owSingleProvinceTopology('p1'),
      unitId: 'u1',
      workTarget: kWorkTargetProspect,
      tileMapByRegion: tileMapByRegion,
    );

void vwtExpectProspectVisContains(
  Game game,
  String tile, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  expect(vwtProspectVisKeys(game, tileMapByRegion: tileMapByRegion), contains(tile));
}

void vwtExpectProspectVisExcludesAll(
  Game game,
  Iterable<String> tiles, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final valid = vwtProspectVisKeys(game, tileMapByRegion: tileMapByRegion);
  for (final tile in tiles) {
    expect(valid.contains(tile), isFalse);
  }
}

void vwtExpectMineralBuildVisBeforeAfterProspect() {
  final grainTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
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

void vwtExpectControlledTilesWithResourcesOnly() {
  final tileWithResource = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tileWithoutResource = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final foreignTileWithResource = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
  vwtExpectBuildVisMembership(
    owBuilderVisibilityGame(
      provinces: [vwtOwnedProvince('p1'), vwtProvince('p2', 'other')],
      tilesByProvince: {
        ValidWorkTilesTestSupport.provinceId('p1'): [
          tileWithResource,
          tileWithoutResource,
        ],
        ValidWorkTilesTestSupport.provinceId('p2'): [foreignTileWithResource],
      },
      resourceByTileKey: {
        tileWithResource: 'grain',
        foreignTileWithResource: 'iron',
      },
      builderTileKey: tileWithResource,
      improvementByTile: {tileWithResource: 0},
      extraPlayers: const [
        Player(id: 'other', displayName: 'Other', isHuman: false),
      ],
    ),
    included: [tileWithResource],
    excluded: [tileWithoutResource, foreignTileWithResource],
  );
}

void vwtExpectPurchasedTilesIncluded() {
  final purchased = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
  final unpurchased = ValidWorkTilesTestSupport.tileKey('p2', 1, 0);
  final ownTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  vwtExpectBuildVisMembership(
    owBuilderVisibilityGame(
      provinces: [vwtOwnedProvince('p1'), vwtProvince('p2', 'minor1')],
      tilesByProvince: {
        ValidWorkTilesTestSupport.provinceId('p1'): [ownTile],
        ValidWorkTilesTestSupport.provinceId('p2'): [purchased, unpurchased],
      },
      resourceByTileKey: {purchased: 'grain', unpurchased: 'grain'},
      builderTileKey: ownTile,
      improvementByTile: {purchased: 0},
      purchasedTilesByTileKey: {
        purchased: ValidWorkTilesTestSupport.playerId,
      },
      minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
    ),
    included: [purchased],
    excluded: [unpurchased],
  );
}

void vwtExpectSeaZoneExcludedFromBuild() {
  final landTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  const seaZoneId = 's1';
  final seaTile = ValidWorkTilesTestSupport.tileKey(seaZoneId, 0, 0);
  vwtExpectBuildVisMembership(
    owBuilderVisibilityGame(
      provinces: [vwtOwnedProvince('p1')],
      tilesByProvince: {
        ValidWorkTilesTestSupport.provinceId('p1'): [landTile],
      },
      resourceByTileKey: {landTile: 'grain', seaTile: 'fish'},
      builderTileKey: landTile,
      improvementByTile: {landTile: 0},
      seaZoneId: seaZoneId,
      seaTiles: [seaTile],
    ),
    included: [landTile],
    excluded: [seaTile],
  );
}

void vwtExpectExplorePartialProvinceScan() {
  final fx = owTribeExploreMultiProvinceFixture();
  final exploreValid = validWorkTilesWithVisibility(
    game: fx.game,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    unitId: 'u1',
    workTarget: kWorkTargetExplore,
  );
  for (final tile in [fx.partialKnownTile]) {
    expect(exploreValid, contains(tile));
  }
  for (final tile in [fx.fullTile, fx.unknownTile]) {
    expect(exploreValid, isNot(contains(tile)));
  }
}

void vwtExpectExploreLatencyUnderOneSecond() {
  final latencyGame = owTribeExploreLatencyGame();
  final sw = Stopwatch()..start();
  final valid = validWorkTilesWithVisibility(
    game: latencyGame,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    unitId: 'u1',
    workTarget: kWorkTargetExplore,
  );
  sw.stop();
  expect(valid, isNotEmpty);
  expect(sw.elapsedMilliseconds, lessThan(1000));
}

void vwtExpectMoveExcludesGpProvince() {
  final fx = owGpAdjacentMoveFixture();
  final suggestions = suggestMoveOrders(
    buildPlayerView(
      fx.game,
      fx.topology,
      ValidWorkTilesTestSupport.playerId,
    ),
    fx.game,
    fx.topology,
    const Orders(),
  );
  expect(
    suggestions.where(
      (m) =>
          Unit.provinceIdFromTileKey(m.destinationTileKey) ==
          fx.otherGpProvinceId,
    ),
    isEmpty,
  );
}

void vwtExpectBuildSuggestSortedByTileKey() {
  final tileKeys = [
    ValidWorkTilesTestSupport.tileKey('p1', 0, 0),
    ValidWorkTilesTestSupport.tileKey('p1', 1, 0),
    ValidWorkTilesTestSupport.tileKey('p1', 2, 0),
  ];
  final buildSuggestions = suggestedWorkOrders(
    game: owGrainBuildSuggestGame(tileKeys: tileKeys),
    topology: owSingleProvinceTopology('p1'),
  ).where((o) => o.target == kWorkTargetBuildImprovement).toList();
  if (buildSuggestions.length > 1) {
    for (var i = 0; i < buildSuggestions.length - 1; i++) {
      expect(
        buildSuggestions[i].targetTileKey.compareTo(
          buildSuggestions[i + 1].targetTileKey,
        ),
        lessThanOrEqualTo(0),
      );
    }
  }
}

void vwtExpectBuildSuggestExcludesReservedTile() {
  final tile0 = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tile1 = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final buildSuggestions = suggestedWorkOrders(
    game: owGrainBuildSuggestGame(tileKeys: [tile0, tile1]),
    topology: owSingleProvinceTopology('p1'),
    currentOrders: Orders(
      workOrdersByPlayerId: {
        ValidWorkTilesTestSupport.playerId: [
          WorkOrder(
            unitId: 'u1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: tile0,
          ),
        ],
      },
    ),
  ).where(
    (o) =>
        o.target == kWorkTargetBuildImprovement && o.targetTileKey == tile0,
  );
  expect(buildSuggestions, isEmpty);
}
