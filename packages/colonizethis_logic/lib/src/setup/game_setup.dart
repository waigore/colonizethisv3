// SPEC/program/game-setup-pipeline.md. Builds Game from generated maps and config.
// Map generation is done by the caller (app/colonizethis_map); this module does
// province assignment, build state, and capital auto-choice.

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'capital_choice.dart';
import 'gp_land_connectivity_repair.dart';
import '../constants.dart';
import '../diplomacy/diplomacy_relation_lookup.dart';
import 'initial_visibility.dart';
import '../world/naval.dart';
import 'province_assignment.dart';
import 'province_name_fallback.dart';

final _log = logicLogger();

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
  final perturbBase =
      assignmentPerturbationBase ?? namingSeed ?? config.seed;

  Map<String, String> owOwner = {};
  var owAssignmentOk = false;
  if (config.enforceFairGpOldWorldAssignment) {
    for (var attempt = 0; attempt < kMaxOldWorldAssignmentAttempts; attempt++) {
      final assignmentRandom =
          attempt == 0 ? null : Random(Object.hash(0x47504f77, perturbBase, attempt));
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
        _log.w('logic: OW assignment attempt $attempt failed: $e');
        _log.d('logic: stack $st');
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
    _log.i('logic: OW assignment fast path (no GP land connectivity repair)');
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
  game = _assignProvinceTowns(game: game);

  // Apply historically inspired naming from default ruleset (after capitals are set).
  game = _applyNaming(
    game: game,
    selectedGreatPowerIds: config.selectedGreatPowerIds,
    leaderVariantByGpId: config.leaderVariantByGpId,
    namingSeed: namingSeed ?? config.seed,
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

Map<String, String> _buildPoliticalGlyphByPlayerId({
  required Game game,
  required List<String> greatPowerIds,
  required List<String> minorNationIds,
  required List<String> tribeIds,
}) {
  final glyphs = <String, String>{};

  String pickUpperForGp(String name, Set<String> used) {
    final upper = name.toUpperCase();
    for (var i = 0; i < upper.length; i++) {
      final ch = upper[i];
      if (ch.codeUnitAt(0) >= 'A'.codeUnitAt(0) &&
          ch.codeUnitAt(0) <= 'Z'.codeUnitAt(0) &&
          !used.contains(ch)) {
        return ch;
      }
    }
    for (var code = 'A'.codeUnitAt(0); code <= 'Z'.codeUnitAt(0); code++) {
      final ch = String.fromCharCode(code);
      if (!used.contains(ch)) return ch;
    }
    return 'X';
  }

  final usedUpper = <String>{};
  for (final gpId in greatPowerIds) {
    final player = game.players.firstWhere(
      (p) => p.id == gpId,
      orElse: () => game.players.first,
    );
    final glyph = pickUpperForGp(player.displayName, usedUpper);
    glyphs[gpId] = glyph;
    usedUpper.add(glyph);
  }

  final nonGpIds = <String>[...minorNationIds, ...tribeIds]..sort();

  const digitGlyphs = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
  for (var i = 0; i < nonGpIds.length; i++) {
    String glyph;
    if (i < digitGlyphs.length) {
      glyph = digitGlyphs[i];
    } else {
      final letterIndex = i - digitGlyphs.length;
      final baseCode = 'a'.codeUnitAt(0);
      glyph = String.fromCharCode(baseCode + letterIndex);
    }
    glyphs[nonGpIds[i]] = glyph;
  }

  return glyphs;
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
      nodes.add(
        TopologyNode(id: '$regionId|${n.id}', regionId: regionId, type: n.type),
      );
    }
    for (final e in topo.edges) {
      edges.add(
        TopologyEdge(id1: '$regionId|${e.id1}', id2: '$regionId|${e.id2}'),
      );
    }
  }
  for (final link in warpLinks) {
    edges.add(TopologyEdge(id1: link.prefixedKey, id2: link.otherPrefixedKey));
  }
  return MapTopology(nodes: nodes, edges: edges);
}

List<String> _provinceIdsFromTopology(MapTopology topology) {
  return topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toList();
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
    final sameRegion =
        capProvinceId != null &&
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
  var proceduralFallbackCount = 0;

  String generateFallback(int seedOffset) {
    proceduralFallbackCount++;
    return generateUniqueProvinceName(namingSeed + seedOffset, usedProvinceNames);
  }

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
    final variantId =
        leaderVariantByGpId[semanticId] ??
        naming.defaultLeaderVariantId(semanticId);
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
        ? generateFallback(namingSeed + minor.id.hashCode)
        : (namingMinor.provinceNamePool.isNotEmpty
              ? namingMinor.provinceNamePool.first
              : namingMinor.displayName);
    final fallbackPrefix = namingMinor.id.isEmpty
        ? 'Territory'
        : namingMinor.displayName;
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
      orElse: () =>
          const TribeNaming(id: '', displayName: '', provinceNamePool: []),
    );
    final owned = nwProvinces.where((p) => p.ownerId == tribe.id).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (owned.isEmpty) continue;
    final capitalProvId = tribe.capitalProvinceId;
    final capitalName = namingTribe.id.isEmpty
        ? generateFallback(namingSeed + tribe.id.hashCode)
        : (namingTribe.provinceNamePool.isNotEmpty
              ? namingTribe.provinceNamePool.first
              : namingTribe.displayName);
    final fallbackPrefix = namingTribe.id.isEmpty
        ? 'Territory'
        : '${namingTribe.displayName} Territory';
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
    final variantId =
        leaderVariantByGpId[semanticId] ??
        naming.defaultLeaderVariantId(semanticId);
    final variant = gpNaming.variantById(variantId);
    updatedPlayers.add(
      p.copyWith(
        displayName: gpNaming.countryName,
        leaderKey: variant.leaderKey,
      ),
    );
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
      orElse: () =>
          const TribeNaming(id: '', displayName: '', provinceNamePool: []),
    );
    if (namingTribe.id.isEmpty) return t;
    return t.copyWith(displayName: namingTribe.displayName);
  }).toList();

  final updatedWorld = game.worldState.copyWith(
    oldWorld: RegionData(
      provinces: owById.values.toList()..sort((a, b) => a.id.compareTo(b.id)),
      units: game.worldState.oldWorld.units,
    ),
    newWorld: RegionData(
      provinces: nwById.values.toList()..sort((a, b) => a.id.compareTo(b.id)),
      units: game.worldState.newWorld.units,
    ),
  );

  _log.i(
    'logic: naming applied ow=${updatedWorld.oldWorld.provinces.length} '
    'nw=${updatedWorld.newWorld.provinces.length} players=${game.players.length} '
    'minors=${game.minorNations.length} tribes=${game.tribes.length}',
  );
  if (proceduralFallbackCount > 0) {
    _log.d('logic: naming procedural fallback used count=$proceduralFallbackCount');
  }

  return game.copyWith(
    worldState: updatedWorld,
    players: updatedPlayers,
    minorNations: updatedMinors,
    tribes: updatedTribes,
  );
}

/// Adds starting civilian units for each Great Power in their capital provinces.
Game _addStartingUnits({required Game game, required GameSetupConfig config}) {
  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
  var oldWorldUnits = List<Unit>.from(game.worldState.oldWorld.units);
  var newWorldUnits = List<Unit>.from(game.worldState.newWorld.units);

  for (final player in game.players) {
    final capitalProvinceId = player.capitalProvinceId;
    if (capitalProvinceId == null) continue;

    final capitalRegionId = ProvinceId.regionIdFrom(capitalProvinceId);
    final tilesInCapital =
        tileKeysByRegion[capitalRegionId]?[capitalProvinceId];
    final firstTileInCapital =
        (tilesInCapital != null && tilesInCapital.isNotEmpty)
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
          locationProvinceId: capitalProvinceId,
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
          locationProvinceId: capitalProvinceId,
          status: UnitStatus.idle,
        );
        if (regionId == kRegionOldWorld) {
          oldWorldUnits.add(unit);
        } else {
          newWorldUnits.add(unit);
        }
      }
    }

    // Starting merchant ships in the home fleet (in port at capital province). SPEC/game/ships-and-naval.md.
    if (shipCount > 0 && regionId == kRegionOldWorld) {
      final fullProvinceId = '$regionId|$localProvinceId';

      final homeFleetId = homeFleetIdFor(player.id);
      final existingIndex = fleets.indexWhere((f) => f.id == homeFleetId);
      final existingFleet = existingIndex >= 0 ? fleets[existingIndex] : null;

      final shipTypeId = _startingShipTypeForPlayer(player);
      final newShipTypes = <String>[
        if (existingFleet != null) ...existingFleet.shipTypeIds,
        for (var i = 0; i < shipCount; i++) shipTypeId,
      ];

      final homeFleet = Fleet(
        id: homeFleetId,
        ownerId: player.id,
        seaZoneId: null,
        inPortAtProvinceId: fullProvinceId,
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
    final requiredTech = unlockingTechByShipId[typeId];
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
Map<String, int> _landmassIdsFromNeighbours(
  Map<String, Set<String>> neighbours,
) {
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
  required Game Function(
    Game,
    String,
    String,
    CapitalTile,
    MapTopology,
    Map<String, TileMapResult>,
  )
  setCapitalFn,
}) {
  for (final factionId in factionIds) {
    final owned = provinces
        .where((p) => p.ownerId == factionId)
        .map((p) => p.id)
        .toList();
    if (owned.isEmpty) continue;
    final (provinceId, tile) = pickCapitalForFaction(
      owned,
      regionId,
      topology,
      tileMap,
      requireSeaBound: requireSeaBound,
    );
    game = setCapitalFn(
      game,
      factionId,
      provinceId,
      tile,
      topology,
      tileMapByRegion,
    );
  }
  return game;
}

/// Upper bound on how many OW provinces all Great Powers can own together when each GP
/// is confined to one P–P landmass and each GP needs a sea-bound seed on that landmass.
/// Uses the union of landmasses that receive at least one GP; spreading GPs across
/// separate landmasses maximizes that union (see SPEC/game/game-setup.md).
int _maxFeasibleGpProvinceBudgetOnLandmasses({
  required Map<int, int> landmassSizes,
  required Map<int, int> seaBoundCountByLandmass,
  required int gpCount,
}) {
  final eligible =
      landmassSizes.keys
          .where((lm) => (seaBoundCountByLandmass[lm] ?? 0) >= 1)
          .toList()
        ..sort((a, b) => landmassSizes[b]!.compareTo(landmassSizes[a]!));

  if (eligible.isEmpty) {
    return 0;
  }

  final totalSeaSlots = eligible.fold<int>(
    0,
    (sum, lm) => sum + (seaBoundCountByLandmass[lm] ?? 0),
  );
  if (totalSeaSlots < gpCount) {
    return 0;
  }

  if (gpCount <= eligible.length) {
    return eligible
        .take(gpCount)
        .fold<int>(0, (sum, lm) => sum + landmassSizes[lm]!);
  }

  return eligible.fold<int>(0, (sum, lm) => sum + landmassSizes[lm]!);
}

/// Result of greedy GP→landmass assignment (largest-targets first).
typedef _GpLandmassPackResult = ({
  Map<String, int> gpLandmassAssignments,
  Map<String, int> targetPerGp,
  List<String> sortedGpIds,
});

/// Tries to place each GP on one landmass with sea-cap and per-landmass target sums.
_GpLandmassPackResult? _tryPackGpsOntoLandmassesGreedy({
  required List<String> gpIds,
  required int gpProvinceBudget,
  required Map<int, int> landmassSizes,
  required List<int> sortedLandmasses,
  required Map<int, int> seaBoundCountByLandmass,
}) {
  final targetPerGp = computeFairTargets(gpIds, gpProvinceBudget);
  final gpLandmassAssignments = <String, int>{};
  final targetUsedOnLandmass = <int, int>{
    for (final lm in landmassSizes.keys) lm: 0,
  };
  final gpCountOnLandmass = <int, int>{
    for (final lm in landmassSizes.keys) lm: 0,
  };

  final sortedGpIds = gpIds.toList()
    ..sort((a, b) => targetPerGp[b]!.compareTo(targetPerGp[a]!));

  for (final gpId in sortedGpIds) {
    final target = targetPerGp[gpId]!;
    int? bestLm;
    var bestSlack = 1 << 30;
    for (final lm in sortedLandmasses) {
      final seaCap = seaBoundCountByLandmass[lm] ?? 0;
      if (gpCountOnLandmass[lm]! >= seaCap) continue;
      if (targetUsedOnLandmass[lm]! + target > landmassSizes[lm]!) continue;
      final slack = landmassSizes[lm]! - (targetUsedOnLandmass[lm]! + target);
      if (slack < bestSlack) {
        bestSlack = slack;
        bestLm = lm;
      }
    }
    if (bestLm == null) {
      return null;
    }
    gpLandmassAssignments[gpId] = bestLm;
    targetUsedOnLandmass[bestLm] = targetUsedOnLandmass[bestLm]! + target;
    gpCountOnLandmass[bestLm] = gpCountOnLandmass[bestLm]! + 1;
  }

  return (
    gpLandmassAssignments: gpLandmassAssignments,
    targetPerGp: targetPerGp,
    sortedGpIds: sortedGpIds,
  );
}

/// Largest budget in [gpCount, cap] for which [computeFairTargets] + greedy packing succeeds.
int _largestFeasibleGpProvinceBudgetByPacking({
  required List<String> gpIds,
  required int gpCount,
  required int cap,
  required Map<int, int> landmassSizes,
  required List<int> sortedLandmasses,
  required Map<int, int> seaBoundCountByLandmass,
}) {
  var lo = gpCount;
  var hi = cap;
  var best = gpCount - 1;
  while (lo <= hi) {
    final mid = (lo + hi) ~/ 2;
    final pack = _tryPackGpsOntoLandmassesGreedy(
      gpIds: gpIds,
      gpProvinceBudget: mid,
      landmassSizes: landmassSizes,
      sortedLandmasses: sortedLandmasses,
      seaBoundCountByLandmass: seaBoundCountByLandmass,
    );
    if (pack != null) {
      best = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return best;
}

Map<String, String> _assignOldWorldOwnershipContiguous({
  required Map<String, Set<String>> neighbours,
  required List<String> provinceIds,
  required List<String> seaBoundProvinceIds,
  required List<String> gpIds,
  required List<String> minorIds,
  required int minProvincesPerMinor,
  Random? assignmentRandom,
}) {
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

  // Compute landmass sizes and map landmassId -> list of province IDs
  final landmassToProvinces = <int, List<String>>{};
  for (final pid in provinceIds) {
    final lm = landmassIds[pid]!;
    landmassToProvinces.putIfAbsent(lm, () => <String>[]).add(pid);
  }
  final landmassSizes = landmassToProvinces.map(
    (k, v) => MapEntry(k, v.length),
  );
  final sortedLandmasses = landmassSizes.keys.toList()
    ..sort((a, b) => landmassSizes[b]!.compareTo(landmassSizes[a]!));

  // Sea-bound slots per landmass (each GP needs one sea-bound seed on its landmass).
  final seaBoundCountByLandmass = <int, int>{};
  for (final pid in seaBoundProvinceIds) {
    final lm = landmassIds[pid]!;
    seaBoundCountByLandmass[lm] = (seaBoundCountByLandmass[lm] ?? 0) + 1;
  }

  final maxGpProvincesByTopology = _maxFeasibleGpProvinceBudgetOnLandmasses(
    landmassSizes: landmassSizes,
    seaBoundCountByLandmass: seaBoundCountByLandmass,
    gpCount: gpCount,
  );
  if (maxGpProvincesByTopology < gpCount) {
    throw ArgumentError(
      'Old World GP assignment infeasible: topology allows at most '
      '$maxGpProvincesByTopology province(s) for $gpCount Great Power(s) under the '
      'one-landmass-per-GP rule (sea-bound slots per landmass: $seaBoundCountByLandmass)',
    );
  }

  final cap = min(availableForGps, maxGpProvincesByTopology);
  // Fair targets must pack into landmasses: sum of targets per landmass ≤ |L|, and
  // (# GPs on L) ≤ sea-bound slots on L. Union-only caps are insufficient when
  // gpCount > landmassCount (e.g. three GPs on two continents).
  final gpProvinceBudget = _largestFeasibleGpProvinceBudgetByPacking(
    gpIds: gpIds,
    gpCount: gpCount,
    cap: cap,
    landmassSizes: landmassSizes,
    sortedLandmasses: sortedLandmasses,
    seaBoundCountByLandmass: seaBoundCountByLandmass,
  );
  if (gpProvinceBudget < gpCount) {
    throw ArgumentError(
      'Old World GP landmass packing failed: no feasible fair target budget for '
      '$gpCount Great Power(s) within cap $cap. Landmass sizes: $landmassSizes, '
      'sea-bound per landmass: $seaBoundCountByLandmass',
    );
  }

  final pack = _tryPackGpsOntoLandmassesGreedy(
    gpIds: gpIds,
    gpProvinceBudget: gpProvinceBudget,
    landmassSizes: landmassSizes,
    sortedLandmasses: sortedLandmasses,
    seaBoundCountByLandmass: seaBoundCountByLandmass,
  );
  if (pack == null) {
    throw StateError(
      'logic: GP landmass pack unexpectedly null at budget $gpProvinceBudget',
    );
  }
  final gpLandmassAssignments = pack.gpLandmassAssignments;
  final targetPerGp = pack.targetPerGp;
  final sortedGpIds = pack.sortedGpIds;

  // Seed selection for Great Powers: one sea-bound province per GP, from their assigned landmass
  final gpSeeds = _selectGpSeedsForLandmass(
    gpIdsInAssignmentOrder: sortedGpIds,
    seaBoundProvinceIds: seaBoundProvinceIds,
    landmassIds: landmassIds,
    gpLandmassAssignments: gpLandmassAssignments,
    seedShuffleRandom: assignmentRandom,
  );

  final gpAvailable = provinceIds.toSet();

  // Pass faction landmass constraints to BFS for strict per-landmass assignment
  final gpOwners = assignTerritoriesByBfsGrowth(
    neighbours: neighbours,
    landmassIds: landmassIds,
    factionLandmassIds: gpLandmassAssignments,
    factionIds: gpIds,
    seeds: gpSeeds,
    targetPerFaction: targetPerGp,
    available: gpAvailable,
    maxTotal: gpProvinceBudget,
    neighborShuffleRandom: assignmentRandom,
  );

  for (final gpId in gpIds) {
    final expectedLm = gpLandmassAssignments[gpId];
    if (expectedLm == null) continue;
    for (final e in gpOwners.entries) {
      if (e.value != gpId) continue;
      final pidLm = landmassIds[e.key];
      if (pidLm != expectedLm) {
        throw StateError(
          'GP $gpId violates one-continent rule: province ${e.key} is on '
          'landmass $pidLm but GP is assigned to $expectedLm',
        );
      }
    }
  }

  // Remaining provinces go to minors.
  final owners = Map<String, String>.from(gpOwners);
  if (minorCount > 0 && gpAvailable.isNotEmpty) {
    final remainingForMinors = gpAvailable.toList()..sort();
    if (assignmentRandom != null) remainingForMinors.shuffle(assignmentRandom);
    final targetPerMinor = computeFairTargets(
      minorIds,
      remainingForMinors.length,
    );
    final minorSeeds = pickSimpleSeeds(
      factionIds: minorIds,
      candidateIds: remainingForMinors,
      available: gpAvailable,
    );
    final minorOwners = assignTerritoriesByBfsGrowth(
      neighbours: neighbours,
      landmassIds: landmassIds,
      factionIds: minorIds,
      seeds: minorSeeds,
      targetPerFaction: targetPerMinor,
      available: gpAvailable,
      neighborShuffleRandom: assignmentRandom,
    );
    owners.addAll(minorOwners);
  }

  return owners;
}

/// Selects GP seeds: one sea-bound province per GP, from their assigned landmass.
/// [gpIdsInAssignmentOrder] must match the order used when building [gpLandmassAssignments]
/// so sea-bound consumption is deterministic.
Map<String, String> _selectGpSeedsForLandmass({
  required List<String> gpIdsInAssignmentOrder,
  required List<String> seaBoundProvinceIds,
  required Map<String, int> landmassIds,
  required Map<String, int> gpLandmassAssignments,
  Random? seedShuffleRandom,
}) {
  final gpCount = gpIdsInAssignmentOrder.length;

  // Group sea-bound provinces by landmass (sorted lists; we remove from front).
  final seaBoundByLandmass = <int, List<String>>{};
  for (final pid in seaBoundProvinceIds) {
    final lm = landmassIds[pid]!;
    seaBoundByLandmass.putIfAbsent(lm, () => <String>[]).add(pid);
  }
  for (final list in seaBoundByLandmass.values) {
    list.sort();
    if (seedShuffleRandom != null) list.shuffle(seedShuffleRandom);
  }

  final gpSeeds = <String, String>{};

  for (final gpId in gpIdsInAssignmentOrder) {
    final assignedLandmass = gpLandmassAssignments[gpId];
    if (assignedLandmass == null) {
      throw ArgumentError(
        'Great Power $gpId has no landmass assignment; cannot pick sea-bound seed',
      );
    }
    final seaBoundOnLandmass = seaBoundByLandmass[assignedLandmass];
    if (seaBoundOnLandmass == null || seaBoundOnLandmass.isEmpty) {
      throw ArgumentError(
        'No sea-bound province left on landmass $assignedLandmass for Great Power $gpId',
      );
    }
    final seedProv = seaBoundOnLandmass.removeAt(0);
    gpSeeds[seedProv] = gpId;
  }

  if (gpSeeds.length != gpCount) {
    throw ArgumentError(
      'Not enough sea-bound provinces to seed all Great Powers on their landmasses: '
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
