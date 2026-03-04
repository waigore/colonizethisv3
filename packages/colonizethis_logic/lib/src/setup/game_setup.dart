// SPEC/program/game-setup-pipeline.md. Builds Game from generated maps and config.
// Map generation is done by the caller (app/colonizethis_map); this module does
// province assignment, build state, and capital auto-choice.

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import 'capital_choice.dart';
import '../constants.dart';
import '../world/naval.dart';
import '../world/player_view.dart';
import 'province_assignment.dart';
import 'province_name_fallback.dart';

final Logger _log = Logger();

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
  List<WarpLink>? warpLinks,
}) {
  _log.i('logic: game setup start gameId=$gameId');
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

  final seaBoundOW = owProvinceIds
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
  // - Great Powers: contiguous land clusters on OW, seeded from sea-bound provinces; cross-landmass only when no unassigned neighbours remain.
  // - Minor Nations: contiguous clusters on remaining OW provinces.
  // - Tribes: contiguous clusters on NW provinces.
  final owOwner = _assignOldWorldOwnershipContiguous(
    topologyOldWorld: topologyOldWorld,
    provinceIds: owProvinceIds,
    seaBoundProvinceIds: seaBoundOW,
    gpIds: gpIds,
    minorIds: minorIds,
    minProvincesPerMinor: config.minProvincesPerMinor,
  );

  final nwOwner = _assignNewWorldOwnershipContiguous(
    topologyNewWorld: topologyNewWorld,
    provinceIds: nwProvinceIds,
    tribeIds: tribeIds,
  );

  final oldWorldProvinces = owOwner.entries
      .map((e) => Province(
            id: ProvinceId.full(kRegionOldWorld, e.key),
            regionId: kRegionOldWorld,
            ownerId: e.value,
          ))
      .toList();
  final newWorldProvinces = nwOwner.entries
      .map((e) => Province(
            id: ProvinceId.full(kRegionNewWorld, e.key),
            regionId: kRegionNewWorld,
            ownerId: e.value,
          ))
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
  // enough lumber and castIron to build a small number of level-1 improvements.
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

  // Initial GP–GP relations per SPEC/game/diplomacy.md: all Great Powers
  // start at peace with neutral relations and turn index 0 metadata.
  final diplomacyRelations = <DiplomacyRelation>[
    for (var i = 0; i < players.length; i++)
      for (var j = i + 1; j < players.length; j++)
        DiplomacyRelation(
          factionId1: players[i].id,
          factionId2: players[j].id,
          score: 50,
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
        setCapital(game: g, playerId: factionId, provinceId: provinceId, tile: tile, topology: topo, tileMapByRegion: tmByRegion),
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
        setCapitalForMinorNation(game: g, minorId: factionId, provinceId: provinceId, tile: tile, topology: topo, tileMapByRegion: tmByRegion),
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
        setCapitalForTribe(game: g, tribeId: factionId, provinceId: provinceId, tile: tile, topology: topo, tileMapByRegion: tmByRegion),
  );

  // Apply initial per-player visibility/prospection (knowledge state) after
  // provinces, capitals, and starting units are set.
  game = _applyInitialVisibility(
    game: game,
    tileMapByRegion: tileMapByRegion,
  );

  // 7d. Province town assignment. SPEC/program/game-setup-pipeline.md, capital-and-connectivity.md.
  game = _assignProvinceTowns(game: game);

  // Apply historically inspired naming from default ruleset (after capitals are set).
  game = _applyNaming(
    game: game,
    selectedGreatPowerIds: config.selectedGreatPowerIds,
    leaderVariantByGpId: config.leaderVariantByGpId,
    namingSeed: namingSeed ?? config.seed,
  );

  // Spawn starting units for each Great Power in their capital provinces.
  game = _addStartingUnits(game: game, config: config);

  // Spawn starting land regiments and home fleets for each Great Power.
  game = _addStartingMilitaryAndNaval(
    game: game,
    config: config,
    topologyOldWorld: topologyOldWorld,
  );

  final combinedTopology = buildCombinedTopology(
    topologyByRegion: topologyByRegion,
    warpLinks: links,
  );

  _log.i('logic: game setup end gameId=${game.id}');
  return GameSetupResult(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
    combinedTopology: combinedTopology,
    warpLinks: links,
  );
}

/// Builds a single topology with prefixed node ids (regionId|localId) and warp edges.
/// SPEC/game/map-topology.md: OW and NW are separate; connectivity across regions only via warp zones.
MapTopology buildCombinedTopology({
  required Map<String, MapTopology> topologyByRegion,
  List<WarpLink> warpLinks = const [],
}) {
  final nodes = <TopologyNode>[];
  final edges = <TopologyEdge>[];
  for (final entry in topologyByRegion.entries) {
    final regionId = entry.key;
    final topo = entry.value;
    for (final n in topo.nodes) {
      nodes.add(TopologyNode(
        id: '$regionId|${n.id}',
        regionId: regionId,
        type: n.type,
      ));
    }
    for (final e in topo.edges) {
      edges.add(TopologyEdge(
        id1: '$regionId|${e.id1}',
        id2: '$regionId|${e.id2}',
      ));
    }
  }
  for (final link in warpLinks) {
    edges.add(TopologyEdge(
      id1: link.prefixedKey,
      id2: link.otherPrefixedKey,
    ));
  }
  return MapTopology(nodes: nodes, edges: edges);
}

List<String> _provinceIdsFromTopology(MapTopology topology) {
  return topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toList();
}

Game _applyInitialVisibility({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final owMap = tileMapByRegion[kRegionOldWorld];
  final nwMap = tileMapByRegion[kRegionNewWorld];
  if (owMap == null || nwMap == null) return game;

  // Province ownership lookup.
  final owOwnerById = <String, String?>{
    for (final p in game.worldState.oldWorld.provinces) p.id: p.ownerId,
  };
  final nwOwnerById = <String, String?>{
    for (final p in game.worldState.newWorld.provinces) p.id: p.ownerId,
  };

  final playerVisibilityByTile = <String, Map<String, String>>{};
  final playerProspectedTiles = <String, Set<String>>{};

  // Build tile keys per region and province for explore resolution. SPEC/program/fog-and-exploration-resolution.md.
  // Build resourceByTileKey from tile map resourceGrid for build_improvement validation and extraction. SPEC/game/extraction-and-improvements.md.
  final tileKeysByRegionAndProvince = <String, Map<String, List<String>>>{
    kRegionOldWorld: <String, List<String>>{},
    kRegionNewWorld: <String, List<String>>{},
  };
  final resourceByTileKey = <String, String>{};
  for (var y = 0; y < owMap.height; y++) {
    for (var x = 0; x < owMap.width; x++) {
      final localId = owMap.cell(x, y);
      final fullId = ProvinceId.full(kRegionOldWorld, localId);
      final ownerId = owOwnerById[fullId];
      if (ownerId == null) continue;
      final tileKey = '$kRegionOldWorld|$localId|$x|$y';
      tileKeysByRegionAndProvince[kRegionOldWorld]!
          .putIfAbsent(fullId, () => <String>[])
          .add(tileKey);
      final res = owMap.resourceAt(x, y);
      if (res != null) resourceByTileKey[tileKey] = res.name;
    }
  }
  for (var y = 0; y < nwMap.height; y++) {
    for (var x = 0; x < nwMap.width; x++) {
      final localId = nwMap.cell(x, y);
      final fullId = ProvinceId.full(kRegionNewWorld, localId);
      final ownerId = nwOwnerById[fullId];
      if (ownerId == null) continue;
      final tileKey = '$kRegionNewWorld|$localId|$x|$y';
      tileKeysByRegionAndProvince[kRegionNewWorld]!
          .putIfAbsent(fullId, () => <String>[])
          .add(tileKey);
      final res = nwMap.resourceAt(x, y);
      if (res != null) resourceByTileKey[tileKey] = res.name;
    }
  }

  for (final player in game.players) {
    final playerId = player.id;
    final visibility = <String, String>{};

    // Old World: own provinces fullyVisible, others fogged.
    for (var y = 0; y < owMap.height; y++) {
      for (var x = 0; x < owMap.width; x++) {
        final localId = owMap.cell(x, y);
        final fullId = ProvinceId.full(kRegionOldWorld, localId);
        final ownerId = owOwnerById[fullId];
        if (ownerId == null) {
          // Sea zone or unowned; skip.
          continue;
        }
        final tileKey = '$kRegionOldWorld|$localId|$x|$y';
        visibility[tileKey] =
            ownerId == playerId ? VisibilityLevel.fullyVisible.name : VisibilityLevel.fogged.name;
      }
    }

    // New World: start unknown (absence = unknown in PlayerView).

    playerVisibilityByTile[playerId] = visibility;
    playerProspectedTiles[playerId] = <String>{};
  }

  final updatedWorldState = game.worldState.copyWith(
    playerVisibilityByTile: playerVisibilityByTile,
    playerProspectedTiles: playerProspectedTiles,
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    resourceByTileKey: resourceByTileKey,
  );
  return game.copyWith(worldState: updatedWorldState);
}

/// 7d. Province town assignment. For each province, set townTileKey: capital province = capital tile;
/// same region = tile with shortest path to capital; overseas = port tile or first tile. SPEC/program/game-setup-pipeline.md.
Game _assignProvinceTowns({required Game game}) {
  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
  final ports = game.worldState.portsByProvinceSeaboard;

  // Capital tile key and capital province id per faction (ownerId).
  final capitalTileKeyByOwner = <String, String>{};
  final capitalProvinceIdByOwner = <String, String>{};
  for (final p in game.players) {
    if (p.capitalProvinceId != null && p.capitalTile != null) {
      capitalProvinceIdByOwner[p.id] = p.capitalProvinceId!;
      capitalTileKeyByOwner[p.id] = p.capitalTile!.toTileKey();
    }
  }
  for (final m in game.minorNations) {
    if (m.capitalProvinceId != null && m.capitalTile != null) {
      capitalProvinceIdByOwner[m.id] = m.capitalProvinceId!;
      capitalTileKeyByOwner[m.id] = m.capitalTile!.toTileKey();
    }
  }
  for (final t in game.tribes) {
    if (t.capitalProvinceId != null && t.capitalTile != null) {
      capitalProvinceIdByOwner[t.id] = t.capitalProvinceId!;
      capitalTileKeyByOwner[t.id] = t.capitalTile!.toTileKey();
    }
  }

  // Build (regionId, x, y) -> tileKey for BFS.
  final coordToKey = <String, Map<String, String>>{};
  for (final regionEntry in tileKeysByRegion.entries) {
    final regionId = regionEntry.key;
    final byProvince = regionEntry.value;
    final m = <String, String>{};
    for (final list in byProvince.values) {
      for (final tk in list) {
        final parts = tk.split('|');
        if (parts.length >= 4) {
          final x = parts[2];
          final y = parts[3];
          m['$x|$y'] = tk;
        }
      }
    }
    coordToKey[regionId] = m;
  }

  // BFS from start tile key; returns map tileKey -> distance (in same region).
  Map<String, int> bfsDistances(String regionId, String startTileKey) {
    final result = <String, int>{};
    final parts = startTileKey.split('|');
    if (parts.length < 4) return result;
    final m = coordToKey[regionId];
    if (m == null) return result;
    int x = int.tryParse(parts[2]) ?? 0;
    int y = int.tryParse(parts[3]) ?? 0;
    final queue = <List<dynamic>>[];
    final key = '${parts[2]}|${parts[3]}';
    if (m[key] != null) {
      queue.add([x, y, 0]);
      result[m[key]!] = 0;
    }
    while (queue.isNotEmpty) {
      final item = queue.removeAt(0);
      final cx = item[0] as int;
      final cy = item[1] as int;
      final d = item[2] as int;
      for (final delta in [
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1],
      ]) {
        final nx = cx + delta[0];
        final ny = cy + delta[1];
        final nk = '$nx|$ny';
        final tileKey = m[nk];
        if (tileKey != null && !result.containsKey(tileKey)) {
          result[tileKey] = d + 1;
          queue.add([nx, ny, d + 1]);
        }
      }
    }
    return result;
  }

  // Port tile in province (any port whose key starts with provinceId|).
  String? portTileInProvince(String provinceId) {
    for (final entry in ports.entries) {
      if (entry.key.startsWith('$provinceId|')) return entry.value;
    }
    return null;
  }

  String? townTileKeyForProvince(Province p) {
    final ownerId = p.ownerId;
    if (ownerId == null) {
      final tiles = tileKeysByRegion[p.regionId]?[p.id] ?? [];
      return tiles.isNotEmpty ? tiles.first : null;
    }
    final capProvinceId = capitalProvinceIdByOwner[ownerId];
    final capTileKey = capitalTileKeyByOwner[ownerId];
    if (p.id == capProvinceId && capTileKey != null) return capTileKey;
    final tiles = tileKeysByRegion[p.regionId]?[p.id] ?? [];
    if (tiles.isEmpty) return null;
    final sameRegion = capProvinceId != null &&
        ProvinceId.regionIdFrom(capProvinceId) == p.regionId;
    if (sameRegion && capTileKey != null) {
      final distances = bfsDistances(p.regionId, capTileKey);
      String? best;
      int bestD = 999999;
      for (final tk in tiles) {
        final d = distances[tk] ?? 999999;
        if (d < bestD) {
          bestD = d;
          best = tk;
        }
      }
      return best ?? tiles.first;
    }
    final portTile = portTileInProvince(p.id);
    return portTile ?? tiles.first;
  }

  final oldProvinces = game.worldState.oldWorld.provinces.map((p) {
    final tk = townTileKeyForProvince(p);
    return tk != null ? p.copyWith(townTileKey: tk) : p;
  }).toList();
  final newProvinces = game.worldState.newWorld.provinces.map((p) {
    final tk = townTileKeyForProvince(p);
    return tk != null ? p.copyWith(townTileKey: tk) : p;
  }).toList();

  return game.copyWith(
    worldState: game.worldState.copyWith(
      oldWorld: RegionData(
        provinces: oldProvinces,
        units: game.worldState.oldWorld.units,
      ),
      newWorld: RegionData(
        provinces: newProvinces,
        units: game.worldState.newWorld.units,
      ),
    ),
  );
}

Game _applyNaming({
  required Game game,
  required List<String> selectedGreatPowerIds,
  required Map<String, String> leaderVariantByGpId,
  required int namingSeed,
}) {
  final naming = defaultNamingConfig;
  final owProvinces = game.worldState.oldWorld.provinces;
  final nwProvinces = game.worldState.newWorld.provinces;
  final owById = {for (final p in owProvinces) p.id: p};
  final nwById = {for (final p in nwProvinces) p.id: p};
  final usedProvinceNames = <String>{};

  String generateFallback(int seedOffset) =>
      generateUniqueProvinceName(namingSeed + seedOffset, usedProvinceNames);

  // Helper: assign names to provinces from pool (random order). Capital gets capitalName; others get shuffled pool, wrap if needed.
  void assignProvinceNames({
    required List<Province> provinces,
    required String? capitalProvinceId,
    required String capitalName,
    required List<String> pool,
    required String fallbackPrefix,
    required int rngSeed,
    required Set<String> usedProvinceNames,
    required String Function(int seedOffset) generateFallback,
    required Map<String, Province> outById,
    required String regionId,
  }) {
    if (provinces.isEmpty) return;
    provinces = List.of(provinces)..sort((a, b) => a.id.compareTo(b.id));
    final rng = Random(rngSeed);
    final poolIndices = List.generate(pool.length, (i) => i)..shuffle(rng);
    var poolIndex = 0;
    for (var i = 0; i < provinces.length; i++) {
      final p = provinces[i];
      var name = p.id == capitalProvinceId
          ? capitalName
          : (pool.isNotEmpty
              ? pool[poolIndices[poolIndex % poolIndices.length]]
              : '$fallbackPrefix ${i + 1}');
      if (name.isEmpty) name = generateFallback(rngSeed + i);
      if (p.id != capitalProvinceId && pool.isNotEmpty) poolIndex++;
      final updated = p.copyWith(displayName: name);
      outById[p.id] = updated;
    }
  }

  // Applies naming to a single faction type with common logic.
  // Handles Great Powers, Minor Nations, and Tribes with their specific naming sources.
  void applyNamingToFaction({
    required List<Province> ownedProvinces,
    required String? capitalProvinceId,
    required String capitalName,
    required List<String> pool,
    required String fallbackPrefix,
    required int rngSeed,
    required Map<String, Province> outById,
  }) {
    if (ownedProvinces.isEmpty) return;
    assignProvinceNames(
      provinces: ownedProvinces,
      capitalProvinceId: capitalProvinceId,
      capitalName: capitalName,
      pool: pool,
      fallbackPrefix: fallbackPrefix,
      rngSeed: rngSeed,
      usedProvinceNames: usedProvinceNames,
      generateFallback: generateFallback,
      outById: outById,
      regionId: outById == owById ? kRegionOldWorld : kRegionNewWorld,
    );
  }

  // Great Powers: capital gets capitalCityName, others from chosen variant's pool. All owned OW provinces are named (no landmass filter).
  for (var i = 0; i < game.players.length; i++) {
    final player = game.players[i];
    if (i >= selectedGreatPowerIds.length) continue;
    final semanticId = selectedGreatPowerIds[i];
    final gpNaming = naming.gpById(semanticId);
    if (gpNaming == null || gpNaming.leaderVariants.isEmpty) continue;
    final variantId = leaderVariantByGpId[semanticId] ?? naming.defaultLeaderVariantId(semanticId);
    final variant = gpNaming.variantById(variantId);
    final capitalProvId = player.capitalProvinceId;
    if (capitalProvId == null) continue;
    final owned = owProvinces.where((p) => p.ownerId == player.id).toList();
    applyNamingToFaction(
      ownedProvinces: owned,
      capitalProvinceId: capitalProvId,
      capitalName: gpNaming.capitalCityName,
      pool: variant.provinceNamePool,
      fallbackPrefix: gpNaming.countryName,
      rngSeed: namingSeed + player.id.hashCode,
      outById: owById,
    );
  }

  // Minor Nations: capital gets first from pool, others random.
  for (var i = 0; i < game.minorNations.length; i++) {
    final minor = game.minorNations[i];
    final namingMinor = naming.minorNations.firstWhere(
      (n) => n.id == minor.id,
      orElse: () => const MinorNationNaming(id: '', displayName: ''),
    );
    final owned = owProvinces.where((p) => p.ownerId == minor.id).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (owned.isEmpty) continue;
    final capitalProvId = minor.capitalProvinceId;
    final capitalName = namingMinor.id.isEmpty
        ? generateUniqueProvinceName(namingSeed + minor.id.hashCode, usedProvinceNames)
        : (namingMinor.provinceNamePool.isNotEmpty
            ? namingMinor.provinceNamePool.first
            : namingMinor.displayName);
    final fallbackPrefix = namingMinor.id.isEmpty ? 'Territory' : namingMinor.displayName;
    applyNamingToFaction(
      ownedProvinces: owned,
      capitalProvinceId: capitalProvId,
      capitalName: capitalName,
      pool: namingMinor.provinceNamePool,
      fallbackPrefix: fallbackPrefix,
      rngSeed: namingSeed + minor.id.hashCode,
      outById: owById,
    );
  }

  // Tribes: capital gets first from pool, others random.
  for (var i = 0; i < game.tribes.length; i++) {
    final tribe = game.tribes[i];
    final namingTribe = naming.tribes.firstWhere(
      (n) => n.id == tribe.id,
      orElse: () => const TribeNaming(id: '', displayName: '', provinceNamePool: []),
    );
    final owned = nwProvinces.where((p) => p.ownerId == tribe.id).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (owned.isEmpty) continue;
    final capitalProvId = tribe.capitalProvinceId;
    final capitalName = namingTribe.id.isEmpty
        ? generateUniqueProvinceName(namingSeed + tribe.id.hashCode, usedProvinceNames)
        : (namingTribe.provinceNamePool.isNotEmpty
            ? namingTribe.provinceNamePool.first
            : namingTribe.displayName);
    final fallbackPrefix = namingTribe.id.isEmpty ? 'Territory' : '${namingTribe.displayName} Territory';
    applyNamingToFaction(
      ownedProvinces: owned,
      capitalProvinceId: capitalProvId,
      capitalName: capitalName,
      pool: namingTribe.provinceNamePool,
      fallbackPrefix: fallbackPrefix,
      rngSeed: namingSeed + tribe.id.hashCode,
      outById: nwById,
    );
  }

  // Faction display names and leaderKey: GPs get countryName and leaderKey from chosen variant.
  final updatedPlayers = <Player>[];
  for (var i = 0; i < game.players.length; i++) {
    final p = game.players[i];
    if (i >= selectedGreatPowerIds.length) {
      updatedPlayers.add(p);
      continue;
    }
    final semanticId = selectedGreatPowerIds[i];
    final gpNaming = naming.gpById(semanticId);
    if (gpNaming == null || gpNaming.leaderVariants.isEmpty) {
      updatedPlayers.add(p);
      continue;
    }
    final variantId = leaderVariantByGpId[semanticId] ?? naming.defaultLeaderVariantId(semanticId);
    final variant = gpNaming.variantById(variantId);
    updatedPlayers.add(p.copyWith(
      displayName: gpNaming.countryName,
      leaderKey: variant.leaderKey,
    ));
  }

  final updatedMinors = game.minorNations.map((m) {
    final namingMinor = naming.minorNations.firstWhere(
      (n) => n.id == m.id,
      orElse: () => const MinorNationNaming(id: '', displayName: ''),
    );
    if (namingMinor.id.isEmpty) return m;
    return m.copyWith(displayName: namingMinor.displayName);
  }).toList();

  final updatedTribes = game.tribes.map((t) {
    final namingTribe = naming.tribes.firstWhere(
      (n) => n.id == t.id,
      orElse: () => const TribeNaming(id: '', displayName: '', provinceNamePool: []),
    );
    if (namingTribe.id.isEmpty) return t;
    return t.copyWith(displayName: namingTribe.displayName);
  }).toList();

  final updatedWorld = game.worldState.copyWith(
    oldWorld: RegionData(
      provinces: owById.values.toList()
        ..sort((a, b) => a.id.compareTo(b.id)),
      units: game.worldState.oldWorld.units,
    ),
    newWorld: RegionData(
      provinces: nwById.values.toList()
        ..sort((a, b) => a.id.compareTo(b.id)),
      units: game.worldState.newWorld.units,
    ),
  );

  return game.copyWith(
    worldState: updatedWorld,
    players: updatedPlayers,
    minorNations: updatedMinors,
    tribes: updatedTribes,
  );
}

/// Adds starting civilian units for each Great Power in their capital provinces.
Game _addStartingUnits({
  required Game game,
  required GameSetupConfig config,
}) {
  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
  var oldWorldUnits = List<Unit>.from(game.worldState.oldWorld.units);
  var newWorldUnits = List<Unit>.from(game.worldState.newWorld.units);

  for (final player in game.players) {
    final capitalProvinceId = player.capitalProvinceId;
    if (capitalProvinceId == null) continue;

    final capitalRegionId = ProvinceId.regionIdFrom(capitalProvinceId);
    final tilesInCapital = tileKeysByRegion[capitalRegionId]?[capitalProvinceId];
    final firstTileInCapital = (tilesInCapital != null && tilesInCapital.isNotEmpty)
        ? tilesInCapital.first
        : null;

    final unitConfig = config.startingResources.startingCivilianUnits;
    for (final entry in unitConfig.entries) {
      final unitType = entry.key;
      final count = entry.value;

      for (var k = 1; k <= count; k++) {
        final unitId = '${player.id}_${unitType.toLowerCase()}_$k';
        final unit = Unit(
          id: unitId,
          type: unitType,
          ownerId: player.id,
          provinceId: capitalProvinceId,
          status: UnitStatus.idle,
          tileKey: firstTileInCapital,
        );
        if (capitalRegionId == kRegionOldWorld) {
          oldWorldUnits.add(unit);
        } else {
          newWorldUnits.add(unit);
        }
      }
    }
  }

  return game.copyWith(
    worldState: game.worldState.copyWith(
      oldWorld: RegionData(
        provinces: game.worldState.oldWorld.provinces,
        units: oldWorldUnits,
      ),
      newWorld: RegionData(
        provinces: game.worldState.newWorld.provinces,
        units: newWorldUnits,
      ),
    ),
  );
}

/// Adds starting land regiments and home-fleet ships for each Great Power.
Game _addStartingMilitaryAndNaval({
  required Game game,
  required GameSetupConfig config,
  required MapTopology topologyOldWorld,
}) {
  final starting = config.startingResources;
  final regimentCount = starting.initialMilitaryRegiments;
  final shipCount = starting.initialNavalShips;

  if (regimentCount <= 0 && shipCount <= 0) {
    return game;
  }

  var oldWorldUnits = List<Unit>.from(game.worldState.oldWorld.units);
  var newWorldUnits = List<Unit>.from(game.worldState.newWorld.units);
  var fleets = List<Fleet>.from(game.worldState.fleets);

  for (final player in game.players) {
    final capitalProvinceId = player.capitalProvinceId;
    if (capitalProvinceId == null) continue;

    final regionId = ProvinceId.regionIdFrom(capitalProvinceId);
    final localProvinceId = ProvinceId.localIdFrom(capitalProvinceId);

    // Starting regiments in capital province.
    if (regimentCount > 0) {
      final regimentTypeId = _startingRegimentTypeForPlayer(player);
      for (var i = 0; i < regimentCount; i++) {
        final unitId = '${player.id}_${regimentTypeId}_reg${i + 1}';
        final unit = Unit(
          id: unitId,
          type: regimentTypeId,
          ownerId: player.id,
          provinceId: capitalProvinceId,
          status: UnitStatus.idle,
        );
        if (regionId == kRegionOldWorld) {
          oldWorldUnits.add(unit);
        } else {
          newWorldUnits.add(unit);
        }
      }
    }

    // Starting merchant ships in the home fleet at the capital port sea zone.
    if (shipCount > 0 && regionId == kRegionOldWorld) {
      final seaZoneId =
          seaZoneIdForProvince(topologyOldWorld, localProvinceId, regionId: kRegionOldWorld);
      if (seaZoneId == null) {
        continue;
      }

      final homeFleetId = 'fleet_${player.id}';
      final existingIndex = fleets.indexWhere((f) => f.id == homeFleetId);
      final existingFleet =
          existingIndex >= 0 ? fleets[existingIndex] : null;

      final shipTypeId = _startingShipTypeForPlayer(player);
      final newShipTypes = <String>[
        if (existingFleet != null) ...existingFleet.shipTypeIds,
        for (var i = 0; i < shipCount; i++) shipTypeId,
      ];

      final homeFleet = Fleet(
        id: homeFleetId,
        ownerId: player.id,
        seaZoneId: seaZoneId,
        regionId: regionId,
        shipTypeIds: newShipTypes,
      );

      if (existingFleet == null) {
        fleets.add(homeFleet);
      } else {
        fleets[existingIndex] = homeFleet;
      }
    }
  }

  return game.copyWith(
    worldState: game.worldState.copyWith(
      oldWorld: RegionData(
        provinces: game.worldState.oldWorld.provinces,
        units: oldWorldUnits,
      ),
      newWorld: RegionData(
        provinces: game.worldState.newWorld.provinces,
        units: newWorldUnits,
      ),
      fleets: fleets,
    ),
  );
}

/// Chooses the regiment type used for starting armies.
String _startingRegimentTypeForPlayer(Player player) {
  // MVP: fixed baseline regular-infantry regiment from era 1.
  const fallbackId = 'pikemen';
  final stats = regimentStatsById(fallbackId);
  if (stats != null) return stats.id;
  return regimentCatalog.isNotEmpty ? regimentCatalog.first.id : fallbackId;
}

/// Chooses the merchant ship type used for starting home fleets.
String _startingShipTypeForPlayer(Player player) {
  final techUnlocked = player.techUnlocked;
  bool hasTech(String techId) =>
      techUnlocked != null && techUnlocked[techId] == true;

  String? bestTypeId;
  var bestCargo = -1;

  for (final entry in ShipEconomyCatalog.all) {
    final typeId = entry.shipTypeId;
    final requiredTech = _unlockingTechForShip(typeId);
    if (requiredTech != null && !hasTech(requiredTech)) {
      continue;
    }
    final cargo = NavalStatsCatalog.get(typeId).cargoHold;
    if (cargo > bestCargo) {
      bestCargo = cargo;
      bestTypeId = typeId;
    }
  }

  // Fallback: baseline carrack if nothing matched.
  return bestTypeId ?? ShipEconomyCatalog.carrack.shipTypeId;
}

String? _unlockingTechForShip(String shipTypeId) {
  switch (shipTypeId) {
    case 'fluyte':
      return 'superior_hull_design';
    default:
      return null;
  }
}

/// Builds a map of province id -> neighbouring province ids using only P–P edges.
Map<String, Set<String>> _provinceNeighboursFromTopology(MapTopology topology) {
  final provinces = {
    for (final n in topology.nodes)
      if (n.type == TopologyNodeType.province) n.id,
  };
  final neighbours = <String, Set<String>>{
    for (final id in provinces) id: <String>{},
  };
  for (final edge in topology.edges) {
    final a = edge.id1;
    final b = edge.id2;
    if (!provinces.contains(a) || !provinces.contains(b)) continue;
    neighbours[a]!.add(b);
    neighbours[b]!.add(a);
  }
  return neighbours;
}

/// Computes a landmass id (connected component id) per province based on P–P adjacency.
Map<String, int> _landmassIdsFromNeighbours(Map<String, Set<String>> neighbours) {
  final landmassByProvince = <String, int>{};
  var currentId = 0;
  for (final province in neighbours.keys) {
    if (landmassByProvince.containsKey(province)) continue;
    final queue = <String>[province];
    landmassByProvince[province] = currentId;
    while (queue.isNotEmpty) {
      final p = queue.removeLast();
      for (final n in neighbours[p] ?? const <String>{}) {
        if (landmassByProvince.containsKey(n)) continue;
        landmassByProvince[n] = currentId;
        queue.add(n);
      }
    }
    currentId++;
  }
  return landmassByProvince;
}

Game _assignCapitalsForFactions({
  required Game game,
  required List<String> factionIds,
  required List<Province> provinces,
  required String regionId,
  required MapTopology topology,
  required TileMapResult tileMap,
  required Map<String, TileMapResult> tileMapByRegion,
  required bool requireSeaBound,
  required Game Function(Game, String, String, CapitalTile, MapTopology, Map<String, TileMapResult>) setCapitalFn,
}) {
  for (final factionId in factionIds) {
    final owned = provinces.where((p) => p.ownerId == factionId).map((p) => p.id).toList();
    if (owned.isEmpty) continue;
    final (provinceId, tile) = pickCapitalForFaction(
      owned,
      regionId,
      topology,
      tileMap,
      requireSeaBound: requireSeaBound,
    );
    game = setCapitalFn(game, factionId, provinceId, tile, topology, tileMapByRegion);
  }
  return game;
}

Map<String, String> _assignOldWorldOwnershipContiguous({
  required MapTopology topologyOldWorld,
  required List<String> provinceIds,
  required List<String> seaBoundProvinceIds,
  required List<String> gpIds,
  required List<String> minorIds,
  required int minProvincesPerMinor,
}) {
  final neighbours = _provinceNeighboursFromTopology(topologyOldWorld);
  final landmassIds = _landmassIdsFromNeighbours(neighbours);

  final gpCount = gpIds.length;
  final minorCount = minorIds.length;

  final totalOw = provinceIds.length;
  final reservedForMinors = minorCount * minProvincesPerMinor;
  final availableForGps = totalOw - reservedForMinors;
  if (availableForGps < gpCount) {
    throw ArgumentError(
      'Old World has $totalOw provinces but after reserving $reservedForMinors '
      'for $minorCount minors only $availableForGps remain for $gpCount Great Powers',
    );
  }

  // Seed selection for Great Powers: one sea-bound province per GP, spreading across landmasses.
  final gpSeeds = _selectGpSeeds(
    gpIds: gpIds,
    seaBoundProvinceIds: seaBoundProvinceIds,
    landmassIds: landmassIds,
  );

  final targetPerGp = computeFairTargets(gpIds, availableForGps);
  final gpAvailable = provinceIds.toSet();

  final gpOwners = assignTerritoriesByBfsGrowth(
    neighbours: neighbours,
    landmassIds: landmassIds,
    factionIds: gpIds,
    seeds: gpSeeds,
    targetPerFaction: targetPerGp,
    available: gpAvailable,
    maxTotal: availableForGps,
  );

  // Remaining provinces go to minors.
  final owners = Map<String, String>.from(gpOwners);
  if (minorCount > 0 && gpAvailable.isNotEmpty) {
    final remainingForMinors = gpAvailable.toList()..sort();
    final targetPerMinor =
        computeFairTargets(minorIds, remainingForMinors.length);
    final minorSeeds = pickSimpleSeeds(
      factionIds: minorIds,
      candidateIds: remainingForMinors,
      available: gpAvailable,
    );
    final minorOwners = assignTerritoriesByBfsGrowth(
      neighbours: neighbours,
      factionIds: minorIds,
      seeds: minorSeeds,
      targetPerFaction: targetPerMinor,
      available: gpAvailable,
    );
    owners.addAll(minorOwners);
  }

  return owners;
}

/// Selects GP seeds: one sea-bound province per GP, spreading across landmasses.
Map<String, String> _selectGpSeeds({
  required List<String> gpIds,
  required List<String> seaBoundProvinceIds,
  required Map<String, int> landmassIds,
}) {
  final gpCount = gpIds.length;
  final seaBoundByLandmass = <int, List<String>>{};
  for (final pid in seaBoundProvinceIds) {
    final lm = landmassIds[pid]!;
    seaBoundByLandmass.putIfAbsent(lm, () => <String>[]).add(pid);
  }

  final gpSeeds = <String, String>{};
  final usedSeaBound = <String>{};

  var lmEntries = seaBoundByLandmass.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  var gpIndex = 0;
  for (final entry in lmEntries) {
    if (gpIndex >= gpCount) break;
    final lmSeaBound = entry.value..sort();
    if (lmSeaBound.isEmpty) continue;
    final seedProv = lmSeaBound.removeAt(0);
    gpSeeds[seedProv] = gpIds[gpIndex];
    usedSeaBound.add(seedProv);
    gpIndex++;
  }

  if (gpIndex < gpCount) {
    final remainingSeaBound =
        seaBoundProvinceIds.where((p) => !usedSeaBound.contains(p)).toList()
          ..sort();
    var i = 0;
    while (gpIndex < gpCount && i < remainingSeaBound.length) {
      final seedProv = remainingSeaBound[i++];
      gpSeeds[seedProv] = gpIds[gpIndex];
      usedSeaBound.add(seedProv);
      gpIndex++;
    }
  }

  if (gpSeeds.length < gpCount) {
    throw ArgumentError(
      'Not enough sea-bound provinces to seed all Great Powers contiguously: '
      'have ${gpSeeds.length}, need $gpCount',
    );
  }

  return gpSeeds;
}

Map<String, String> _assignNewWorldOwnershipContiguous({
  required MapTopology topologyNewWorld,
  required List<String> provinceIds,
  required List<String> tribeIds,
}) {
  if (tribeIds.isEmpty) {
    return {for (final p in provinceIds) p: ''};
  }

  final neighbours = _provinceNeighboursFromTopology(topologyNewWorld);
  final sorted = provinceIds.toList()..sort();
  final available = provinceIds.toSet();
  final targetPerTribe = computeFairTargets(tribeIds, provinceIds.length);
  final seeds = pickSimpleSeeds(
    factionIds: tribeIds,
    candidateIds: sorted,
    available: available,
  );

  return assignTerritoriesByBfsGrowth(
    neighbours: neighbours,
    factionIds: tribeIds,
    seeds: seeds,
    targetPerFaction: targetPerTribe,
    available: available,
  );
}
