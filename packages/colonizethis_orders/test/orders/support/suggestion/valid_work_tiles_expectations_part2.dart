part of 'valid_work_tiles_expectations.dart';

void _getvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile() {
  final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final game = owTribeProspectGame(
    provinceLocalId: 'p1',
    tileKeys: [ironTile],
    resourceByTileKey: {ironTile: 'iron'},
    visibilityByTile: {ironTile: 'fogged'},
  );
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: owSingleProvinceTopology('p1'),
    unitId: 'u1',
    workTarget: kWorkTargetProspect,
  );
  expect(valid, contains(ironTile));
}

void _getvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility() {
  final woolTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tileMapByRegion = <String, TileMapResult>{
    ValidWorkTilesTestSupport.ow: TileMapResult(
      width: 1,
      height: 1,
      grid: const [
        ['p1'],
      ],
      terrainGrid: const [
        [TerrainType.hills],
      ],
      resourceGrid: const [
        [Resource.wool],
      ],
    ),
  };
  final game = owTribeProspectGame(
    provinceLocalId: 'p1',
    tileKeys: [woolTile],
    resourceByTileKey: {woolTile: 'wool'},
    visibilityByTile: {woolTile: 'fogged'},
  );
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: owSingleProvinceTopology('p1'),
    unitId: 'u1',
    workTarget: kWorkTargetProspect,
    tileMapByRegion: tileMapByRegion,
  );
  expect(valid.contains(woolTile), isFalse);
}

void _getvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces() {
  const partialProvince = 'oldWorld|p_partial';
  const fullProvince = 'oldWorld|p_full';
  const unknownProvince = 'oldWorld|p_unknown';
  const partialKnownTile = 'oldWorld|p_partial|0|0';
  const partialUnknownTile = 'oldWorld|p_partial|1|0';
  const fullTile = 'oldWorld|p_full|0|0';
  const unknownTile = 'oldWorld|p_unknown|0|0';

  final explorer = ValidWorkTilesTestSupport.explorerUnit(
    locationProvinceId: partialProvince,
    tileKey: partialKnownTile,
  );
  final game = ValidWorkTilesTestSupport.minimalValidWorkTilesGame(
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: explore/prospect in a Tribe province require a
    // Consulate (or higher); the suggestion path shares the work-order
    // validator, so a consulate is needed for these tiles to be valid.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
    oldWorld: RegionData(
      provinces: [
        Province(
          id: partialProvince,
          regionId: ValidWorkTilesTestSupport.ow,
          ownerId: 'tribe1',
        ),
        Province(
          id: fullProvince,
          regionId: ValidWorkTilesTestSupport.ow,
          ownerId: 'tribe1',
        ),
        Province(
          id: unknownProvince,
          regionId: ValidWorkTilesTestSupport.ow,
          ownerId: 'tribe1',
        ),
      ],
      units: [explorer],
    ),
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince({
      partialProvince: [partialKnownTile, partialUnknownTile],
      fullProvince: [fullTile],
      unknownProvince: [unknownTile],
    }),
    playerVisibilityByTile: const {
      ValidWorkTilesTestSupport.playerId: {
        partialKnownTile: 'fogged',
        fullTile: 'fullyVisible',
        unknownTile: 'unknown',
      },
    },
  );
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    unitId: 'u1',
    workTarget: kWorkTargetExplore,
  );
  expect(valid, contains(partialKnownTile));
  expect(valid, isNot(contains(fullTile)));
  expect(valid, isNot(contains(unknownTile)));
}

void _getvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture() {
  const provinceCount = 120;
  const tilesPerProvince = 12;
  final byProvince = <String, List<String>>{};
  final visibility = <String, String>{};
  final provinces = <Province>[];

  for (var p = 0; p < provinceCount; p++) {
    final provinceId = ValidWorkTilesTestSupport.provinceId('p$p');
    provinces.add(
      Province(
        id: provinceId,
        regionId: ValidWorkTilesTestSupport.ow,
        ownerId: 'tribe1',
      ),
    );
    final tiles = <String>[];
    for (var t = 0; t < tilesPerProvince; t++) {
      final tileKey = ValidWorkTilesTestSupport.tileKey('p$p', t, 0);
      tiles.add(tileKey);
      visibility[tileKey] = (p.isEven && t == 0) ? 'fogged' : 'unknown';
    }
    byProvince[provinceId] = tiles;
  }

  final startTile = ValidWorkTilesTestSupport.tileKey('p0', 0, 0);
  final explorer = ValidWorkTilesTestSupport.explorerUnit(
    locationProvinceId: ValidWorkTilesTestSupport.provinceId('p0'),
    tileKey: startTile,
  );
  final game = ValidWorkTilesTestSupport.validWorkTilesGame(
    id: 'g-latency',
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to explore Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
    oldWorld: RegionData(provinces: provinces, units: [explorer]),
    tileKeysByRegionAndProvince:
        ValidWorkTilesTestSupport.tileKeysByProvince(byProvince),
    playerVisibilityByTile: {
      ValidWorkTilesTestSupport.playerId: visibility,
    },
  );
  final sw = Stopwatch()..start();
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    unitId: 'u1',
    workTarget: kWorkTargetExplore,
  );
  sw.stop();
  expect(valid, isNotEmpty);
  expect(sw.elapsedMilliseconds, lessThan(1000));
}

void _suggestmoveordersExcludesMovesToOtherGreatPowerProvinces() {
  const otherGpId = 'gp2';
  final p1 = _ownedProvince('p1');
  final p2 = _province('p2', otherGpId);
  final unit = ValidWorkTilesTestSupport.builderUnit(
    locationProvinceId: ValidWorkTilesTestSupport.provinceId('p1'),
  );
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: [p1, p2], units: [unit]),
      newWorld: const RegionData(),
      playerVisibilityByTile: const {
        ValidWorkTilesTestSupport.playerId: {
          'oldWorld|p1|0|0': 'fullyVisible',
          'oldWorld|p2|0|0': 'fullyVisible',
        },
      },
    ),
    players: [
      ValidWorkTilesTestSupport.defaultPlayer,
      const Player(id: otherGpId, displayName: 'Other GP', isHuman: false),
    ],
  );
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'p2',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
  );
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
      (m) =>
          Unit.provinceIdFromTileKey(m.destinationTileKey) ==
          ValidWorkTilesTestSupport.provinceId('p2'),
    ),
    isEmpty,
  );
}

void _suggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch() {
  final tiles = [
    ValidWorkTilesTestSupport.tileKey('p1', 0, 0),
    ValidWorkTilesTestSupport.tileKey('p1', 1, 0),
    ValidWorkTilesTestSupport.tileKey('p1', 2, 0),
  ];
  final game = owGrainBuildSuggestGame(tileKeys: tiles);
  final topology = owSingleProvinceTopology('p1');
  final buildSuggestions = suggestedWorkOrders(game: game, topology: topology)
      .where((o) => o.target == kWorkTargetBuildImprovement)
      .toList();
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

void _suggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit() {
  final tile0 = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tile1 = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final game = owGrainBuildSuggestGame(tileKeys: [tile0, tile1]);
  final topology = owSingleProvinceTopology('p1');
  final currentOrders = Orders(
    workOrdersByPlayerId: {
      ValidWorkTilesTestSupport.playerId: [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: tile0,
        ),
      ],
    },
  );
  final buildSuggestions = suggestedWorkOrders(
    game: game,
    topology: topology,
    currentOrders: currentOrders,
  ).where(
    (o) =>
        o.target == kWorkTargetBuildImprovement && o.targetTileKey == tile0,
  );
  expect(buildSuggestions, isEmpty);
}

void _suggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut() {
  final fx = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'tribe1',
    targetOwnerId: 'tribe1',
  );
  final game = fx.game(
    id: 'g1916e1',
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to explore Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
  );
  final explore = suggestedWorkOrders(game: game, topology: fx.topology())
      .where((o) => o.target == kWorkTargetExplore)
      .toList();
  expect(explore, isNotEmpty);
  expect(
    explore.any(
      (o) => Unit.provinceIdFromTileKey(o.targetTileKey) == fx.provTarget,
    ),
    isTrue,
  );
}

void _suggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation() {
  final fx = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'gp2p',
    targetOwnerId: 'gp2',
  );
  final game = fx.game(
    id: 'g1916e2',
    players: [
      ValidWorkTilesTestSupport.defaultPlayer,
      const Player(id: 'gp2', displayName: 'P2', isHuman: false),
    ],
  );
  expect(
    suggestedWorkOrders(game: game, topology: fx.topology()).where(
      (o) =>
          o.target == kWorkTargetExplore &&
          Unit.provinceIdFromTileKey(o.targetTileKey) == fx.provTarget,
    ),
    isEmpty,
  );
}

void _suggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile() {
  final keys = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'tribe1',
    targetOwnerId: 'tribe1',
  );
  final fx = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'tribe1',
    targetOwnerId: 'tribe1',
    resourceByTileKey: {keys.t0: 'grain', keys.t1: 'iron'},
  );
  final game = fx.game(
    id: 'g1916p1',
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
  );
  final prospect = suggestedWorkOrders(
    game: game,
    topology: fx.topology(),
  ).where((o) => o.target == kWorkTargetProspect).toList();
  expect(prospect, isNotEmpty);
  expect(prospect.any((o) => o.targetTileKey == fx.t1), isTrue);
}
