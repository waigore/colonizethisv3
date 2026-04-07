part of 'game_setup.dart';

/// Result of game setup: the Game and the map data needed for turn resolution.
class GameSetupResult {
  const GameSetupResult({
    required this.game,
    required this.tileMapByRegion,
    required this.topologyByRegion,
    required this.combinedTopology,
    this.warpLinks = const [],
  });

  final Game game;
  final Map<String, TileMapResult> tileMapByRegion;
  final Map<String, MapTopology> topologyByRegion;

  /// Single topology with prefixed node ids and warp edges for resolveTurnForGame (movement, extraction). SPEC/game/map-topology.md.
  final MapTopology combinedTopology;

  /// Warp zone links between regions (OW↔NW). Empty if none generated.
  final List<WarpLink> warpLinks;
}

/// Builds a new Game from pre-generated Old World and New World maps and config.
/// Caller is responsible for generating tileMap and topology per region (e.g. via colonizethis_map).
/// Per SPEC/program/game-setup-pipeline.md: assignment (GPs, minors, tribes), build state, capital auto-choice.
GameSetupResult createGameFromGeneratedMaps({
  required GameSetupConfig config,
  required TileMapResult tileMapOldWorld,
  required MapTopology topologyOldWorld,
  required TileMapResult tileMapNewWorld,
  required MapTopology topologyNewWorld,
  required String gameId,
  int? namingSeed,

  /// Base for salted assignment perturbation on OW reassignment retries.
  /// Defaults to [namingSeed] if set, else [GameSetupConfig.seed].
  int? assignmentPerturbationBase,
  List<WarpLink>? warpLinks,
}) {
  _log.i('game setup start gameId=$gameId');
  final tileMapByRegion = {
    kRegionOldWorld: tileMapOldWorld,
    kRegionNewWorld: tileMapNewWorld,
  };
  final topologyByRegion = {
    kRegionOldWorld: topologyOldWorld,
    kRegionNewWorld: topologyNewWorld,
  };
  final links = warpLinks ?? [];

  final owProvinceIds = _provinceIdsFromTopology(topologyOldWorld);
  final nwProvinceIds = _provinceIdsFromTopology(topologyNewWorld);

  if (owProvinceIds.length < config.greatPowerCount) {
    throw ArgumentError(
      'Old World has ${owProvinceIds.length} provinces but ${config.greatPowerCount} Great Powers need at least one each',
    );
  }

  final seaBoundOW =
      owProvinceIds
          .where((id) => isProvinceSeaBound(topologyOldWorld, id))
          .toList()
        ..sort();
  if (seaBoundOW.length < config.greatPowerCount) {
    throw ArgumentError(
      'Old World has ${seaBoundOW.length} sea-bound provinces but ${config.greatPowerCount} Great Powers need one each',
    );
  }

  // Province assignment: GPs get OW (one sea-bound each + fair split of rest); minors get remaining OW; tribes get NW.
  final gpCount = config.greatPowerCount;
  final minorCount = config.minorNationCount;
  final tribeCount = config.tribeCount;

  final gpIds = List.generate(gpCount, (i) => 'gp${i + 1}');
  final minorIds = List.generate(minorCount, (i) => 'minor${i + 1}');
  final tribeIds = List.generate(tribeCount, (i) => 'tribe${i + 1}');

  // Province assignment per SPEC/program/game-setup-pipeline.md:
  // - Great Powers: each GP locked to one P–P landmass (connected component); multiple
  //   GPs may share a landmass when gpCount exceeds landmass count. Sea-bound seeds per landmass.
  // - Minor Nations: contiguous clusters on remaining OW provinces.
  // - GP land connectivity repair + reassignment on same map: gp_land_connectivity_repair.dart
  // - Tribes: contiguous clusters on NW provinces.
  final owNeighbours = _provinceNeighboursFromTopology(topologyOldWorld);
  final owLandmassIds = _landmassIdsFromNeighbours(owNeighbours);
  final owProvincesSorted = owProvinceIds.toList()..sort();
  final seaBoundOwSet = seaBoundOW.toSet();
  final perturbBase = assignmentPerturbationBase ?? namingSeed ?? config.seed;

  Map<String, String> owOwner = {};
  var owAssignmentOk = false;
  if (config.enforceFairGpOldWorldAssignment) {
    for (var attempt = 0; attempt < kMaxOldWorldAssignmentAttempts; attempt++) {
      final assignmentRandom = attempt == 0
          ? null
          : Random(Object.hash(0x47504f77, perturbBase, attempt));
      try {
        owOwner = _assignOldWorldOwnershipContiguous(
          neighbours: owNeighbours,
          provinceIds: owProvinceIds,
          seaBoundProvinceIds: seaBoundOW,
          gpIds: gpIds,
          minorIds: minorIds,
          minProvincesPerMinor: config.minProvincesPerMinor,
          assignmentRandom: assignmentRandom,
        );
      } on StateError catch (e, st) {
        _log.w('OW assignment attempt $attempt failed: $e');
        _log.d('stack $st');
        continue;
      }
      final ownersRepair = Map<String, String>.from(owOwner);
      final repaired = repairGpLandOwnershipMutating(
        owners: ownersRepair,
        gpIdsSorted: gpIds,
        neighbours: owNeighbours,
        landmassIds: owLandmassIds,
        seaBoundLocalIds: seaBoundOwSet,
        allProvinceIdsSorted: owProvincesSorted,
      );
      if (repaired) {
        owOwner = ownersRepair;
        owAssignmentOk = true;
        break;
      }
    }
    if (!owAssignmentOk) {
      throw GameSetupConnectivityFailure(
        'Old World GP land connectivity could not be satisfied after '
        '$kMaxOldWorldAssignmentAttempts assignment attempt(s) and up to '
        '$kGpLandConnectivityRepairRounds repair round(s) each.',
      );
    }
  } else {
    _log.i('OW assignment fast path (no GP land connectivity repair)');
    owOwner = _assignOldWorldOwnershipContiguous(
      neighbours: owNeighbours,
      provinceIds: owProvinceIds,
      seaBoundProvinceIds: seaBoundOW,
      gpIds: gpIds,
      minorIds: minorIds,
      minProvincesPerMinor: config.minProvincesPerMinor,
      assignmentRandom: null,
    );
  }

  final nwOwner = _assignNewWorldOwnershipContiguous(
    topologyNewWorld: topologyNewWorld,
    provinceIds: nwProvinceIds,
    tribeIds: tribeIds,
  );

  final oldWorldProvinces = owOwner.entries
      .map(
        (e) => Province(
          id: ProvinceId.full(kRegionOldWorld, e.key),
          regionId: kRegionOldWorld,
          ownerId: e.value,
        ),
      )
      .toList();
  final newWorldProvinces = nwOwner.entries
      .map(
        (e) => Province(
          id: ProvinceId.full(kRegionNewWorld, e.key),
          regionId: kRegionNewWorld,
          ownerId: e.value,
        ),
      )
      .toList();

  final worldState = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(provinces: oldWorldProvinces),
    newWorld: RegionData(provinces: newWorldProvinces),
  );

  final startingResources = config.startingResources;
  final initialGrainQuantity =
      startingResources.initialPeasants * startingResources.initialGrainTurns;

  // Base starting stockpile for each Great Power: grain for workers plus
  // enough lumber and castIron to build a small number of level-1 improvements,
  // plus starting wool and paper from config (ruleset-config / StartingResourcesConfig).
  final baseStockpileQuantities = <CommodityId, int>{};
  if (initialGrainQuantity > 0) {
    baseStockpileQuantities[CommodityCatalog.grain.id] = initialGrainQuantity;
  }
  if (startingResources.initialImprovementSlots > 0) {
    final slots = startingResources.initialImprovementSlots;
    baseStockpileQuantities[CommodityCatalog.lumber.id] =
        (baseStockpileQuantities[CommodityCatalog.lumber.id] ?? 0) + slots;
    baseStockpileQuantities[CommodityCatalog.castIron.id] =
        (baseStockpileQuantities[CommodityCatalog.castIron.id] ?? 0) + slots;
  }
  if (startingResources.initialWool > 0) {
    baseStockpileQuantities[CommodityCatalog.wool.id] =
        (baseStockpileQuantities[CommodityCatalog.wool.id] ?? 0) +
        startingResources.initialWool;
  }
  if (startingResources.initialPaper > 0) {
    baseStockpileQuantities[CommodityCatalog.paper.id] =
        (baseStockpileQuantities[CommodityCatalog.paper.id] ?? 0) +
        startingResources.initialPaper;
  }

  var players = <Player>[
    for (var i = 0; i < gpCount; i++)
      Player(
        id: gpIds[i],
        displayName: 'Power ${i + 1}',
        isHuman: i == 0,
        stockpile: Stockpile(
          quantities: baseStockpileQuantities.isEmpty
              ? const {}
              : Map<CommodityId, int>.from(baseStockpileQuantities),
        ),
        workerPool: WorkerPool(peasants: startingResources.initialPeasants),
        treasury: startingResources.initialTreasury,
        techUnlocked: const {}, // Stub until Phase 5
      ),
  ];
  var minorNations = <MinorNation>[
    for (var i = 0; i < minorCount; i++)
      MinorNation(id: minorIds[i], displayName: 'Minor ${i + 1}'),
  ];
  var tribes = <Tribe>[
    for (var i = 0; i < tribeCount; i++)
      Tribe(id: tribeIds[i], displayName: 'Tribe ${i + 1}'),
  ];

  // Initial diplomatic relations per SPEC/game/diplomacy.md:
  // - All factions start at peace with neutral relations within the SAME region
  // - Cross-region relations (Old World vs New World) are undiscovered at game start
  // - This means: GP↔GP, GP↔Minor, Minor↔Minor (Old World); Tribe↔Tribe (New World)
  final allOldWorldIds = [...gpIds, ...minorIds];
  final allNewWorldIds = [...tribeIds];

  final diplomacyRelations = <DiplomacyRelation>[
    // Old World: GP ↔ GP, GP ↔ Minor, Minor ↔ Minor
    for (var i = 0; i < allOldWorldIds.length; i++)
      for (var j = i + 1; j < allOldWorldIds.length; j++)
        DiplomacyRelation(
          factionId1: allOldWorldIds[i],
          factionId2: allOldWorldIds[j],
          score: relationScoreNeutral,
          level: RelationLevel.neutral,
          state: RelationState.atPeace,
          sinceTurn: 0,
          lastInteractionTurn: 0,
        ),
    // New World: Tribe ↔ Tribe only
    for (var i = 0; i < allNewWorldIds.length; i++)
      for (var j = i + 1; j < allNewWorldIds.length; j++)
        DiplomacyRelation(
          factionId1: allNewWorldIds[i],
          factionId2: allNewWorldIds[j],
          score: relationScoreNeutral,
          level: RelationLevel.neutral,
          state: RelationState.atPeace,
          sinceTurn: 0,
          lastInteractionTurn: 0,
        ),
  ];

  /// Explicit designation of which Great Power is human-controlled (respects game setup: slot 0 = human).
  /// Used by ctterm and other clients for visibility and input; AI uses true, human uses false.
  final aiControlByGpId = {for (final p in players) p.id: !p.isHuman};

  var game = Game(
    id: gameId,
    worldState: worldState,
    players: players,
    minorNations: minorNations,
    tribes: tribes,
    turnTimeMapping: TurnTimeMapping.gdd01,
    diplomacyRelations: diplomacyRelations,
    aiControlByGpId: aiControlByGpId,
    capitalTileGrainBonusPerTurn:
        config.startingResources.capitalTileGrainBonusPerTurn,
  );

  // Capital auto-choice: GPs (OW), then minors (OW), then tribes (NW). Must run before naming.
  game = _assignCapitalsForFactions(
    game: game,
    factionIds: gpIds,
    provinces: oldWorldProvinces,
    regionId: kRegionOldWorld,
    topology: topologyOldWorld,
    tileMap: tileMapOldWorld,
    tileMapByRegion: tileMapByRegion,
    requireSeaBound: true,
    setCapitalFn: (g, factionId, provinceId, tile, topo, tmByRegion) =>
        setCapital(
          game: g,
          playerId: factionId,
          provinceId: provinceId,
          tile: tile,
          topology: topo,
          tileMapByRegion: tmByRegion,
        ),
  );
  game = _assignCapitalsForFactions(
    game: game,
    factionIds: minorIds,
    provinces: oldWorldProvinces,
    regionId: kRegionOldWorld,
    topology: topologyOldWorld,
    tileMap: tileMapOldWorld,
    tileMapByRegion: tileMapByRegion,
    requireSeaBound: false,
    setCapitalFn: (g, factionId, provinceId, tile, topo, tmByRegion) =>
        setCapitalForMinorNation(
          game: g,
          minorId: factionId,
          provinceId: provinceId,
          tile: tile,
          topology: topo,
          tileMapByRegion: tmByRegion,
        ),
  );
  game = _assignCapitalsForFactions(
    game: game,
    factionIds: tribeIds,
    provinces: newWorldProvinces,
    regionId: kRegionNewWorld,
    topology: topologyNewWorld,
    tileMap: tileMapNewWorld,
    tileMapByRegion: tileMapByRegion,
    requireSeaBound: false,
    setCapitalFn: (g, factionId, provinceId, tile, topo, tmByRegion) =>
        setCapitalForTribe(
          game: g,
          tribeId: factionId,
          provinceId: provinceId,
          tile: tile,
          topology: topo,
          tileMapByRegion: tmByRegion,
        ),
  );

  // Apply initial per-player visibility/prospection (knowledge state) after
  // provinces, capitals, and starting units are set.
  game = applyInitialVisibility(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
  );

  // 7d. Province town assignment. SPEC/program/game-setup-pipeline.md, capital-and-connectivity.md.
  game = _assignProvinceTowns(
    game: game,
    topologyByRegion: topologyByRegion,
    tileMapByRegion: tileMapByRegion,
  );

  // Strip RNG/resources and extraction improvements from town and capital tiles only.
  // SPEC/game/tile-map-and-generation.md § Town/capital occupancy.
  final strip = stripResourcesAndExtractionImprovementsOnTileKeys(
    game,
    tileMapByRegion,
    collectTownAndCapitalTileKeys(game),
  );
  game = strip.$1;
  final strippedMaps = strip.$2;
  if (strippedMaps != null) {
    for (final e in strippedMaps.entries) {
      tileMapByRegion[e.key] = e.value;
    }
  }

  // Great Power starting grain (bootstrap). SPEC/game/tile-map-and-generation.md.
  final gpGrain = applyGreatPowerStartingGrainBootstrap(
    game: game,
    tileMapOldWorld: tileMapByRegion[kRegionOldWorld]!,
    resourceRules: ResourceRules.defaultRules,
  );
  game = gpGrain.game;
  tileMapByRegion[kRegionOldWorld] = gpGrain.tileMap;

  // 7d.bis Init town → capital roads (per-region via config). SPEC/game/capital-and-connectivity.md.
  game = applyInitTownRoadsToCapitals(
    game: game,
    config: config,
    tileMapByRegion: tileMapByRegion,
    bootstrapGrainTileKeysByPlayerId: gpGrain.grainKeysByPlayerId,
  );

  // Apply historically inspired naming from default ruleset (after capitals are set).
  game = _applyNaming(
    game: game,
    selectedGreatPowerIds: config.selectedGreatPowerIds,
    leaderVariantByGpId: config.leaderVariantByGpId,
    namingSeed: namingSeed ?? config.seed,
    topologyByRegion: topologyByRegion,
  );

  // Compute 1-character political glyphs per faction for political map layer.
  final politicalGlyphByPlayerId = _buildPoliticalGlyphByPlayerId(
    game: game,
    greatPowerIds: gpIds,
    minorNationIds: minorIds,
    tribeIds: tribeIds,
  );
  game = game.copyWith(politicalGlyphByPlayerId: politicalGlyphByPlayerId);

  // Spawn starting units for each Great Power in their capital provinces.
  game = _addStartingUnits(game: game, config: config);

  // Spawn starting land regiments and home fleets for each Great Power.
  game = _addStartingMilitaryAndNaval(
    game: game,
    config: config,
    topologyOldWorld: topologyOldWorld,
  );
  game = ensureMilitaryArmiesForGame(game);

  // Map tint / UI swatches: runtime player ids (gp1..gpN) → GDD default RGB for
  // the semantic Great Power in each setup slot (see greatPowerDefaultColorRgb).
  // Province.ownerId uses gpN; without this, factionOwnershipColorMap misses
  // greatPowerDefaultColorRgb[gpN] and falls back to regionPalette (wrong hues).
  final defaultGpColorsByPlayerId = <String, List<int>>{};
  for (var i = 0; i < gpIds.length; i++) {
    if (i >= config.selectedGreatPowerIds.length) {
      break;
    }
    final semanticId = config.selectedGreatPowerIds[i];
    final rgb = greatPowerDefaultColorRgb[semanticId];
    if (rgb != null) {
      defaultGpColorsByPlayerId[gpIds[i]] = [rgb.$1, rgb.$2, rgb.$3];
    }
  }
  if (defaultGpColorsByPlayerId.isNotEmpty) {
    game = game.copyWith(greatPowerColorOverride: defaultGpColorsByPlayerId);
  }

  final combinedTopology = buildCombinedTopology(
    topologyByRegion: topologyByRegion,
    warpLinks: links,
  );

  _log.i('game setup end gameId=${game.id}');
  return GameSetupResult(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
    combinedTopology: combinedTopology,
    warpLinks: links,
  );
}
