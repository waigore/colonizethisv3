import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../diplomacy/diplomacy_relation_lookup.dart';
import '../world/army_migration.dart';
import 'capital_choice.dart';
import 'game_setup_context.dart';
import 'game_setup_helpers.dart';
import 'game_setup_ownership.dart';
import 'game_setup_topology.dart';
import 'gp_old_world_resource_redistribution.dart';
import 'gp_old_world_terrain_redistribution.dart';
import 'gp_starting_grain.dart';
import 'minor_tribe_starting_development.dart';
import 'init_town_roads.dart';
import 'initial_visibility.dart';
import 'setup_exceptions.dart';
import 'town_capital_occupancy.dart';

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

const double _kNewCampaignDefaultMapZoomMultiplier = 4.0;
const double _kMapZoomMultiplierMin = 0.5;
const double _kMapZoomMultiplierMax = 8.0;

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
  gameSetupLog.i('game setup start gameId=$gameId');
  final tileMapByRegion = <String, TileMapResult>{
    kRegionOldWorld: tileMapOldWorld,
    kRegionNewWorld: tileMapNewWorld,
  };
  final topologyByRegion = <String, MapTopology>{
    kRegionOldWorld: topologyOldWorld,
    kRegionNewWorld: topologyNewWorld,
  };
  final links = warpLinks ?? [];
  final perturbBase = assignmentPerturbationBase ?? namingSeed ?? config.seed;
  final initialMapZoomMultiplier = _resolveInitialMapZoomMultiplier(config);
  final ownership = _assignInitialOwnership(
    config: config,
    topologyOldWorld: topologyOldWorld,
    topologyNewWorld: topologyNewWorld,
  );
  final oldWorldProvinces = ownership.oldWorldProvinces;
  final newWorldProvinces = ownership.newWorldProvinces;
  final gpIds = ownership.gpIds;
  final minorIds = ownership.minorIds;
  final tribeIds = ownership.tribeIds;
  var game = _buildInitialGame(
    config: config,
    gameId: gameId,
    oldWorldProvinces: oldWorldProvinces,
    newWorldProvinces: newWorldProvinces,
    gpIds: gpIds,
    minorIds: minorIds,
    tribeIds: tribeIds,
    initialMapZoomMultiplier: initialMapZoomMultiplier,
  );

  game = _assignAllCapitals(
    game: game,
    gpIds: gpIds,
    minorIds: minorIds,
    tribeIds: tribeIds,
    oldWorldProvinces: oldWorldProvinces,
    newWorldProvinces: newWorldProvinces,
    topologyOldWorld: topologyOldWorld,
    topologyNewWorld: topologyNewWorld,
    tileMapOldWorld: tileMapOldWorld,
    tileMapNewWorld: tileMapNewWorld,
    tileMapByRegion: tileMapByRegion,
  );

  // Apply initial per-player visibility/prospection (knowledge state) after
  // provinces, capitals, and starting units are set.
  game = applyInitialVisibility(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
  );

  // 7d. Province town assignment. SPEC/program/game-setup-pipeline.md, capital-and-connectivity.md.
  game = assignProvinceTowns(
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

  // §7d.terrain GP Old World terrain redistribution (always-on when OW grids exist), then §7d.redist resources.
  // SPEC/program/game-setup-pipeline.md; SPEC/game/tile-map-and-generation.md.
  final gpTerrainRedist = applyGreatPowerOldWorldTerrainRedistribution(
    game: game,
    tileMapOldWorld: tileMapByRegion[kRegionOldWorld]!,
    setupSeedBase: perturbBase,
  );
  game = gpTerrainRedist.game;
  tileMapByRegion[kRegionOldWorld] = gpTerrainRedist.tileMap;

  // §7d.redist GP Old World terrain resource redistribution (always-on when OW grids exist).
  // SPEC/program/game-setup-pipeline.md; SPEC/game/tile-map-and-generation.md.
  final gpRedist = applyGreatPowerOldWorldResourceRedistribution(
    game: game,
    tileMapOldWorld: tileMapByRegion[kRegionOldWorld]!,
    resourceRules: ResourceRules.defaultRules,
    setupSeedBase: perturbBase,
  );
  game = gpRedist.game;
  tileMapByRegion[kRegionOldWorld] = gpRedist.tileMap;

  // Great Power starting grain (bootstrap). SPEC/game/tile-map-and-generation.md.
  final gpGrain = applyGreatPowerStartingGrainBootstrap(
    game: game,
    tileMapOldWorld: tileMapByRegion[kRegionOldWorld]!,
    resourceRules: ResourceRules.defaultRules,
  );
  game = gpGrain.game;
  tileMapByRegion[kRegionOldWorld] = gpGrain.tileMap;

  // 7d.dev Minor Nation and Tribe starting developed resources.
  // SPEC/game/factions.md § Starting developed resources; SPEC/program/game-setup-pipeline.md § 7d.dev.
  final minorTribeDev = applyMinorTribeStartingDevelopment(
    game: game,
    tileMapByRegion: tileMapByRegion,
  );
  game = minorTribeDev.game;

  // 7d.bis Init town → capital roads (per-region via config). SPEC/game/capital-and-connectivity.md.
  game = applyInitTownRoadsToCapitals(
    game: game,
    config: config,
    tileMapByRegion: tileMapByRegion,
    bootstrapGrainTileKeysByPlayerId: gpGrain.grainKeysByPlayerId,
  );

  // Apply historically inspired naming from default ruleset (after capitals are set).
  game = applyNaming(
    game: game,
    selectedGreatPowerIds: config.selectedGreatPowerIds,
    leaderVariantByGpId: config.leaderVariantByGpId,
    namingSeed: namingSeed ?? config.seed,
    topologyByRegion: topologyByRegion,
  );

  // Compute 1-character political glyphs per faction for political map layer.
  final politicalGlyphByPlayerId = buildPoliticalGlyphByPlayerId(
    game: game,
    greatPowerIds: gpIds,
    minorNationIds: minorIds,
    tribeIds: tribeIds,
  );
  game = game.copyWith(politicalGlyphByPlayerId: politicalGlyphByPlayerId);

  // Spawn starting units for each Great Power in their capital provinces.
  game = addStartingUnits(game: game, config: config);

  // Spawn starting land regiments and home fleets for each Great Power.
  game = addStartingMilitaryAndNaval(
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

  gameSetupLog.i('game setup end gameId=${game.id}');
  return GameSetupResult(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
    combinedTopology: combinedTopology,
    warpLinks: links,
  );
}

({
  List<String> gpIds,
  List<String> minorIds,
  List<String> tribeIds,
  List<Province> oldWorldProvinces,
  List<Province> newWorldProvinces,
}) _assignInitialOwnership({
  required GameSetupConfig config,
  required MapTopology topologyOldWorld,
  required MapTopology topologyNewWorld,
}) {
  final owProvinceIds = provinceIdsFromTopology(topologyOldWorld);
  final nwProvinceIds = provinceIdsFromTopology(topologyNewWorld);
  if (owProvinceIds.length < config.greatPowerCount) {
    throw SetupConfigConstraintException(
      code: 'insufficient_old_world_provinces_for_great_powers',
      details:
          'Old World has ${owProvinceIds.length} provinces but ${config.greatPowerCount} Great Powers need at least one each',
    );
  }
  final seaBoundOW =
      owProvinceIds.where((id) => isProvinceSeaBound(topologyOldWorld, id)).toList()
        ..sort();
  if (seaBoundOW.length < config.greatPowerCount) {
    throw NoSeaBoundCapitalProvinceException(
      details:
          'Old World has ${seaBoundOW.length} sea-bound provinces but ${config.greatPowerCount} Great Powers need one each',
    );
  }
  final gpIds = List.generate(config.greatPowerCount, (i) => 'gp${i + 1}');
  final minorIds = List.generate(config.minorNationCount, (i) => 'minor${i + 1}');
  final tribeIds = List.generate(config.tribeCount, (i) => 'tribe${i + 1}');
  final owOwner = _assignOldWorldOwners(
    config: config,
    topologyOldWorld: topologyOldWorld,
    provinceIds: owProvinceIds,
    seaBoundOW: seaBoundOW,
    gpIds: gpIds,
    minorIds: minorIds,
  );
  final nwOwner = _assignNewWorldOwners(
    config: config,
    topologyNewWorld: topologyNewWorld,
    provinceIds: nwProvinceIds,
    tribeIds: tribeIds,
  );
  return (
    gpIds: gpIds,
    minorIds: minorIds,
    tribeIds: tribeIds,
    oldWorldProvinces: owOwner.entries
        .map(
          (e) => Province(
            id: ProvinceId.full(kRegionOldWorld, e.key),
            regionId: kRegionOldWorld,
            ownerId: e.value,
          ),
        )
        .toList(),
    newWorldProvinces: nwOwner.entries
        .map(
          (e) => Province(
            id: ProvinceId.full(kRegionNewWorld, e.key),
            regionId: kRegionNewWorld,
            ownerId: e.value,
          ),
        )
        .toList(),
  );
}

Map<String, String> _assignOldWorldOwners({
  required GameSetupConfig config,
  required MapTopology topologyOldWorld,
  required List<String> provinceIds,
  required List<String> seaBoundOW,
  required List<String> gpIds,
  required List<String> minorIds,
}) {
  final owNeighbours = provinceNeighboursFromTopology(topologyOldWorld);
  final useLockedSixMinorContinentPainting = config.isLockedFullInitProfile &&
      oldWorldPartitionMatchesLockedProfile(topologyOldWorld) &&
      lockedOldWorldRoleFeasibilityHolds(
        topology: topologyOldWorld,
        neighbours: owNeighbours,
      );
  final owAssignmentRandom = useLockedSixMinorContinentPainting
      ? Random(config.seed)
      : null;
  try {
    return assignOldWorldOwnershipContiguous(
      neighbours: owNeighbours,
      provinceIds: provinceIds,
      seaBoundProvinceIds: seaBoundOW,
      gpIds: gpIds,
      minorIds: minorIds,
      minProvincesPerMinor: config.minProvincesPerMinor,
      assignmentRandom: owAssignmentRandom,
      useLockedSixMinorContinentPainting: useLockedSixMinorContinentPainting,
    );
  } on StateError catch (e, st) {
    if (useLockedSixMinorContinentPainting) {
      gameSetupLog.e(
        'logic: OW locked assignment failed. '
        '${lockedOwAssignFailureDiagnostics(config: config, topology: topologyOldWorld, seaBoundIds: seaBoundOW)} '
        'raw=$e',
        error: e,
        stackTrace: st,
      );
    } else {
      gameSetupLog.e('logic: OW assignment failed: $e', error: e, stackTrace: st);
    }
    throw SetupTopologyDataException(
      code: 'assigner_exhausted',
      details: 'Old World locked assigner exhausted: $e',
    );
  }
}

Map<String, String> _assignNewWorldOwners({
  required GameSetupConfig config,
  required MapTopology topologyNewWorld,
  required List<String> provinceIds,
  required List<String> tribeIds,
}) {
  try {
    return assignNewWorldOwnershipContiguous(
      topologyNewWorld: topologyNewWorld,
      provinceIds: provinceIds,
      tribeIds: tribeIds,
    );
  } on StateError catch (e, st) {
    if (config.isLockedFullInitProfile) {
      gameSetupLog.e(
        'logic: NW locked assignment failed. '
        '${lockedNwAssignFailureDiagnostics(config: config, topology: topologyNewWorld)} '
        'raw=$e',
        error: e,
        stackTrace: st,
      );
    } else {
      gameSetupLog.e('logic: NW assignment failed: $e', error: e, stackTrace: st);
    }
    throw SetupTopologyDataException(
      code: 'assigner_exhausted',
      details: 'New World locked assigner exhausted: $e',
    );
  }
}

Game _buildInitialGame({
  required GameSetupConfig config,
  required String gameId,
  required List<Province> oldWorldProvinces,
  required List<Province> newWorldProvinces,
  required List<String> gpIds,
  required List<String> minorIds,
  required List<String> tribeIds,
  required double initialMapZoomMultiplier,
}) {
  final worldState = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(provinces: oldWorldProvinces),
    newWorld: RegionData(provinces: newWorldProvinces),
  );
  final baseStockpileQuantities = _buildInitialStockpileQuantities(config);
  final players = <Player>[
    for (var i = 0; i < gpIds.length; i++)
      Player(
        id: gpIds[i],
        displayName: 'Power ${i + 1}',
        isHuman: i == 0,
        stockpile: Stockpile(
          quantities: baseStockpileQuantities.isEmpty
              ? const {}
              : Map<CommodityId, int>.from(baseStockpileQuantities),
        ),
        workerPool: WorkerPool(
          peasants: config.startingResources.initialPeasants,
        ),
        treasury: config.startingResources.initialTreasury,
        techUnlocked: const {},
      ),
  ];
  final minorNations = <MinorNation>[
    for (var i = 0; i < minorIds.length; i++)
      MinorNation(id: minorIds[i], displayName: 'Minor ${i + 1}'),
  ];
  final tribes = <Tribe>[
    for (var i = 0; i < tribeIds.length; i++)
      Tribe(id: tribeIds[i], displayName: 'Tribe ${i + 1}'),
  ];
  final diplomacyRelations = _buildInitialDiplomacyRelations(
    gpIds: gpIds,
    minorIds: minorIds,
    tribeIds: tribeIds,
  );
  final aiControlByGpId = {for (final p in players) p.id: !p.isHuman};
  return Game(
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
    mapViewState: MapViewState.defaults.copyWith(
      zoomMultiplier: initialMapZoomMultiplier,
    ),
    infiniteMode: config.infiniteMode,
    worldMarketState: WorldMarketState.withDefaultPrices(
      _buildInitialMarketPrices(),
    ),
  );
}

/// Builds the initial integer market-price map seeded from
/// `ResourceRules.defaultRules.defaultMarketPriceForCommodityId` for every
/// tradeable commodity, per `SPEC/game/world-market.md` § Tradeable
/// commodities and § Initial price seeding.
///
/// Tradeable = every `CommodityCatalog.all` entry **except** the riches set
/// (`gold`, `silver`, `gems`, `diamonds`, `spices`). Riches auto-convert to
/// treasury in phase 3 and are excluded from the world market entirely.
///
/// Used by [_buildInitialGame] to populate `Game.worldMarketState.prices`
/// at game start (per #3093 § Price presentation & data model) so the
/// Trade screen never has to fall back to the canonical em-dash glyph
/// for a tradeable commodity and the validator / AI treasury planner can
/// resolve a finite integer price on turn 1. The catalog default already
/// covers every tradeable id (raw-resource entries in
/// `ResourceRules.defaultMarketPrice` plus the input-cost-derived
/// manufactured base prices), so the returned map has exactly one entry
/// per tradeable commodity (22 today: 2 food + 11 raw materials + 9
/// manufactured).
Map<CommodityId, int> _buildInitialMarketPrices() {
  final rules = ResourceRules.defaultRules;
  final result = <CommodityId, int>{};
  for (final commodity in CommodityCatalog.all) {
    if (commodity.category == CommodityCategory.riches) continue;
    if (commodity.id == 'spices') continue;
    final price = rules.defaultMarketPriceForCommodityId(commodity.id);
    if (price != null) {
      result[commodity.id] = price;
    }
  }
  return result;
}

Map<CommodityId, int> _buildInitialStockpileQuantities(GameSetupConfig config) {
  final startingResources = config.startingResources;
  final initialGrainQuantity =
      startingResources.initialPeasants * startingResources.initialGrainTurns;
  final out = <CommodityId, int>{};
  if (initialGrainQuantity > 0) {
    out[CommodityCatalog.grain.id] = initialGrainQuantity;
  }
  if (startingResources.initialImprovementSlots > 0) {
    final slots = startingResources.initialImprovementSlots;
    out[CommodityCatalog.lumber.id] = (out[CommodityCatalog.lumber.id] ?? 0) + slots;
    out[CommodityCatalog.castIron.id] =
        (out[CommodityCatalog.castIron.id] ?? 0) + slots;
  }
  if (startingResources.initialWool > 0) {
    out[CommodityCatalog.wool.id] =
        (out[CommodityCatalog.wool.id] ?? 0) + startingResources.initialWool;
  }
  if (startingResources.initialPaper > 0) {
    out[CommodityCatalog.paper.id] =
        (out[CommodityCatalog.paper.id] ?? 0) + startingResources.initialPaper;
  }
  return out;
}

List<DiplomacyRelation> _buildInitialDiplomacyRelations({
  required List<String> gpIds,
  required List<String> minorIds,
  required List<String> tribeIds,
}) {
  final allOldWorldIds = [...gpIds, ...minorIds];
  final allNewWorldIds = [...tribeIds];
  return <DiplomacyRelation>[
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
}

Game _assignAllCapitals({
  required Game game,
  required List<String> gpIds,
  required List<String> minorIds,
  required List<String> tribeIds,
  required List<Province> oldWorldProvinces,
  required List<Province> newWorldProvinces,
  required MapTopology topologyOldWorld,
  required MapTopology topologyNewWorld,
  required TileMapResult tileMapOldWorld,
  required TileMapResult tileMapNewWorld,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  var out = assignCapitalsForFactions(
    game: game,
    factionIds: gpIds,
    provinces: oldWorldProvinces,
    regionId: kRegionOldWorld,
    topology: topologyOldWorld,
    tileMap: tileMapOldWorld,
    tileMapByRegion: tileMapByRegion,
    requireSeaBound: true,
    setCapitalFn: (g, factionId, provinceId, tile, topo, tmByRegion) => setCapital(
      game: g,
      playerId: factionId,
      provinceId: provinceId,
      tile: tile,
      topology: topo,
      tileMapByRegion: tmByRegion,
    ),
  );
  out = assignCapitalsForFactions(
    game: out,
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
  return assignCapitalsForFactions(
    game: out,
    factionIds: tribeIds,
    provinces: newWorldProvinces,
    regionId: kRegionNewWorld,
    topology: topologyNewWorld,
    tileMap: tileMapNewWorld,
    tileMapByRegion: tileMapByRegion,
    requireSeaBound: false,
    setCapitalFn: (g, factionId, provinceId, tile, topo, tmByRegion) => setCapitalForTribe(
      game: g,
      tribeId: factionId,
      provinceId: provinceId,
      tile: tile,
      topology: topo,
      tileMapByRegion: tmByRegion,
    ),
  );
}

double _resolveInitialMapZoomMultiplier(GameSetupConfig config) {
  final preferred =
      config.preferredInitialMapZoomMultiplier ??
      _kNewCampaignDefaultMapZoomMultiplier;
  return preferred.clamp(_kMapZoomMultiplierMin, _kMapZoomMultiplierMax);
}
