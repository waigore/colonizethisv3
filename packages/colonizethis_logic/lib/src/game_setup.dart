// SPEC/program/game-setup-pipeline.md. Builds Game from generated maps and config.
// Map generation is done by the caller (app/colonizethis_map); this module does
// province assignment, build state, and capital auto-choice.

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'capital_choice.dart';
import 'player_view.dart';

const String _regionOldWorld = 'oldWorld';
const String _regionNewWorld = 'newWorld';

/// Result of game setup: the Game and the map data needed for turn resolution.
class GameSetupResult {
  const GameSetupResult({
    required this.game,
    required this.tileMapByRegion,
    required this.topologyByRegion,
    required this.combinedTopology,
  });

  final Game game;
  final Map<String, TileMapResult> tileMapByRegion;
  final Map<String, MapTopology> topologyByRegion;
  /// Single topology merging OW and NW for resolveTurnForGame (movement, extraction).
  final MapTopology combinedTopology;
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
}) {
  final tileMapByRegion = {
    _regionOldWorld: tileMapOldWorld,
    _regionNewWorld: tileMapNewWorld,
  };
  final topologyByRegion = {
    _regionOldWorld: topologyOldWorld,
    _regionNewWorld: topologyNewWorld,
  };

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
      .map((e) => Province(id: e.key, regionId: _regionOldWorld, ownerId: e.value))
      .toList();
  final newWorldProvinces = nwOwner.entries
      .map((e) => Province(id: e.key, regionId: _regionNewWorld, ownerId: e.value))
      .toList();

  final worldState = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(provinces: oldWorldProvinces),
    newWorld: RegionData(provinces: newWorldProvinces),
  );

  final startingResources = config.startingResources;
  final initialGrainQuantity = startingResources.initialPeasants * startingResources.initialGrainTurns;
  
  var players = <Player>[
    for (var i = 0; i < gpCount; i++)
      Player(
        id: gpIds[i],
        displayName: 'Power ${i + 1}',
        isHuman: i == 0,
        stockpile: Stockpile(
          quantities: initialGrainQuantity > 0
              ? {CommodityCatalog.grain.id: initialGrainQuantity}
              : const {},
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

  var game = Game(
    id: gameId,
    worldState: worldState,
    players: players,
    minorNations: minorNations,
    tribes: tribes,
    turnTimeMapping: TurnTimeMapping.gdd01,
  );

  // Capital auto-choice: GPs (OW), then minors (OW), then tribes (NW). Must run before naming.
  for (var i = 0; i < gpCount; i++) {
    final gpId = gpIds[i];
    final owned = oldWorldProvinces.where((p) => p.ownerId == gpId).map((p) => p.id).toList();
    if (owned.isEmpty) continue;
    final (provinceId, tile) = pickCapitalForFaction(
      owned,
      _regionOldWorld,
      topologyOldWorld,
      tileMapOldWorld,
    );
    game = setCapital(
      game: game,
      playerId: gpId,
      provinceId: provinceId,
      tile: tile,
      topology: topologyOldWorld,
      tileMapByRegion: tileMapByRegion,
    );
  }
  for (var i = 0; i < minorCount; i++) {
    final minorId = minorIds[i];
    final owned = oldWorldProvinces.where((p) => p.ownerId == minorId).map((p) => p.id).toList();
    if (owned.isEmpty) continue;
    final (provinceId, tile) = pickCapitalForFaction(
      owned,
      _regionOldWorld,
      topologyOldWorld,
      tileMapOldWorld,
      requireSeaBound: false,
    );
    game = setCapitalForMinorNation(
      game: game,
      minorId: minorId,
      provinceId: provinceId,
      tile: tile,
      topology: topologyOldWorld,
      tileMapByRegion: tileMapByRegion,
    );
  }
  for (var i = 0; i < tribeCount; i++) {
    final tribeId = tribeIds[i];
    final owned = newWorldProvinces.where((p) => p.ownerId == tribeId).map((p) => p.id).toList();
    if (owned.isEmpty) continue;
    final (provinceId, tile) = pickCapitalForFaction(
      owned,
      _regionNewWorld,
      topologyNewWorld,
      tileMapNewWorld,
      requireSeaBound: false,
    );
    game = setCapitalForTribe(
      game: game,
      tribeId: tribeId,
      provinceId: provinceId,
      tile: tile,
      topology: topologyNewWorld,
      tileMapByRegion: tileMapByRegion,
    );
  }

  // Apply initial per-player visibility/prospection (knowledge state) after
  // provinces, capitals, and starting units are set.
  game = _applyInitialVisibility(
    game: game,
    tileMapByRegion: tileMapByRegion,
  );

  // Apply historically inspired naming from default ruleset (after capitals are set).
  game = _applyNaming(
    game: game,
    selectedGreatPowerIds: config.selectedGreatPowerIds,
    leaderVariantByGpId: config.leaderVariantByGpId,
    topologyOldWorld: topologyOldWorld,
    topologyNewWorld: topologyNewWorld,
    namingSeed: namingSeed ?? config.seed,
  );

  // Spawn starting units for each Great Power in their capital provinces.
  game = _addStartingUnits(game: game, config: config);

  final combinedTopology = MapTopology(
    nodes: [...topologyOldWorld.nodes, ...topologyNewWorld.nodes],
    edges: [...topologyOldWorld.edges, ...topologyNewWorld.edges],
  );

  return GameSetupResult(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
    combinedTopology: combinedTopology,
  );
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
  final owMap = tileMapByRegion[_regionOldWorld];
  final nwMap = tileMapByRegion[_regionNewWorld];
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

  for (final player in game.players) {
    final playerId = player.id;
    final visibility = <String, String>{};

    // Old World: own provinces fullyVisible, others fogged.
    for (var y = 0; y < owMap.height; y++) {
      for (var x = 0; x < owMap.width; x++) {
        final provinceId = owMap.cell(x, y);
        final ownerId = owOwnerById[provinceId];
        if (ownerId == null) {
          // Sea zone or unowned; skip.
          continue;
        }
        final tileKey = '$_regionOldWorld|$provinceId|$x|$y';
        visibility[tileKey] =
            ownerId == playerId ? VisibilityLevel.fullyVisible.name : VisibilityLevel.fogged.name;
      }
    }

    // New World: start unknown (no entries; PlayerView treats missing as unknown).
    for (var y = 0; y < nwMap.height; y++) {
      for (var x = 0; x < nwMap.width; x++) {
        final provinceId = nwMap.cell(x, y);
        final ownerId = nwOwnerById[provinceId];
        if (ownerId == null) {
          // Sea or unowned; skip.
          continue;
        }
        // We do not add explicit 'unknown' entries; absence = unknown.
        final _ = provinceId; // ignore: unused_local_variable
      }
    }

    playerVisibilityByTile[playerId] = visibility;
    playerProspectedTiles[playerId] = <String>{};
  }

  final updatedWorldState = game.worldState.copyWith(
    playerVisibilityByTile: playerVisibilityByTile,
    playerProspectedTiles: playerProspectedTiles,
  );
  return game.copyWith(worldState: updatedWorldState);
}

Game _applyNaming({
  required Game game,
  required List<String> selectedGreatPowerIds,
  required Map<String, String> leaderVariantByGpId,
  required MapTopology topologyOldWorld,
  required MapTopology topologyNewWorld,
  required int namingSeed,
}) {
  final naming = defaultNamingConfig;
  final owProvinces = game.worldState.oldWorld.provinces;
  final nwProvinces = game.worldState.newWorld.provinces;
  final owById = {for (final p in owProvinces) p.id: p};
  final nwById = {for (final p in nwProvinces) p.id: p};
  final neighbours = _provinceNeighboursFromTopology(topologyOldWorld);
  final landmassIds = _landmassIdsFromNeighbours(neighbours);

  // Helper: assign names to provinces from pool (random order). Capital gets capitalName; others get shuffled pool, wrap if needed.
  void assignProvinceNames({
    required List<Province> provinces,
    required String? capitalProvinceId,
    required String capitalName,
    required List<String> pool,
    required String fallbackPrefix,
    required int rngSeed,
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
      final name = p.id == capitalProvinceId
          ? capitalName
          : (pool.isNotEmpty
              ? pool[poolIndices[poolIndex % poolIndices.length]]
              : '$fallbackPrefix ${i + 1}');
      if (p.id != capitalProvinceId && pool.isNotEmpty) poolIndex++;
      final updated = Province(
        id: p.id,
        regionId: p.regionId,
        ownerId: p.ownerId,
        displayName: name,
      );
      outById[p.id] = updated;
    }
  }

  // Great Powers: capital gets capitalCityName, others random from chosen variant's pool.
  // Map ordinal player id (gp1, gp2...) to semantic id via selectedGreatPowerIds.
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
    final capitalLandmass = landmassIds[capitalProvId];
    if (capitalLandmass == null) continue;
    final ownedOnLandmass = owProvinces
        .where((p) =>
            p.ownerId == player.id && landmassIds[p.id] == capitalLandmass)
        .toList();
    assignProvinceNames(
      provinces: ownedOnLandmass,
      capitalProvinceId: capitalProvId,
      capitalName: gpNaming.capitalCityName,
      pool: variant.provinceNamePool,
      fallbackPrefix: gpNaming.countryName,
      rngSeed: namingSeed + player.id.hashCode,
      outById: owById,
      regionId: _regionOldWorld,
    );
  }

  // Minor Nations: capital gets first from pool, others random.
  for (var i = 0; i < game.minorNations.length; i++) {
    final minor = game.minorNations[i];
    final namingMinor = naming.minorNations.firstWhere(
      (n) => n.id == minor.id,
      orElse: () => const MinorNationNaming(id: '', displayName: ''),
    );
    final owned = owProvinces
        .where((p) => p.ownerId == minor.id)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (owned.isEmpty) continue;
    final capitalProvId = minor.capitalProvinceId;
    final capitalName = namingMinor.provinceNamePool.isNotEmpty
        ? namingMinor.provinceNamePool.first
        : namingMinor.displayName;
    assignProvinceNames(
      provinces: owned,
      capitalProvinceId: capitalProvId,
      capitalName: capitalName,
      pool: namingMinor.provinceNamePool,
      fallbackPrefix: namingMinor.displayName,
      rngSeed: namingSeed + minor.id.hashCode,
      outById: owById,
      regionId: _regionOldWorld,
    );
  }

  // Tribes: capital gets first from pool, others random.
  for (var i = 0; i < game.tribes.length; i++) {
    final tribe = game.tribes[i];
    final namingTribe = naming.tribes.firstWhere(
      (n) => n.id == tribe.id,
      orElse: () => const TribeNaming(id: '', displayName: '', provinceNamePool: []),
    );
    final owned = nwProvinces
        .where((p) => p.ownerId == tribe.id)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (owned.isEmpty) continue;
    final capitalProvId = tribe.capitalProvinceId;
    final capitalName = namingTribe.provinceNamePool.isNotEmpty
        ? namingTribe.provinceNamePool.first
        : namingTribe.displayName;
    assignProvinceNames(
      provinces: owned,
      capitalProvinceId: capitalProvId,
      capitalName: capitalName,
      pool: namingTribe.provinceNamePool,
      fallbackPrefix: '${namingTribe.displayName} Territory',
      rngSeed: namingSeed + tribe.id.hashCode,
      outById: nwById,
      regionId: _regionNewWorld,
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
  final startingUnits = <Unit>[];
  
  for (final player in game.players) {
    final capitalProvinceId = player.capitalProvinceId;
    if (capitalProvinceId == null) continue;
    
    final unitConfig = config.startingResources.startingCivilianUnits;
    for (final entry in unitConfig.entries) {
      final unitType = entry.key;
      final count = entry.value;
      
      for (var k = 1; k <= count; k++) {
        final unitId = '${player.id}_${unitType.toLowerCase()}_$k';
        startingUnits.add(
          Unit(
            id: unitId,
            type: unitType,
            ownerId: player.id,
            provinceId: capitalProvinceId,
            status: UnitStatus.idle,
          ),
        );
      }
    }
  }
  
  if (startingUnits.isEmpty) return game;
  
  final updatedOldWorld = RegionData(
    provinces: game.worldState.oldWorld.provinces,
    units: [...game.worldState.oldWorld.units, ...startingUnits],
  );
  
  return game.copyWith(
    worldState: game.worldState.copyWith(oldWorld: updatedOldWorld),
  );
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

  final owners = <String, String>{};

  // Aggregate reservation: number of OW provinces the ruleset intends to leave
  // for minors. The actual minor-per-faction distribution is still driven by
  // contiguity and may vary, but this quota shapes how many provinces GPs
  // receive in total.
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
  final seaBoundByLandmass = <int, List<String>>{};
  for (final pid in seaBoundProvinceIds) {
    final lm = landmassIds[pid]!;
    seaBoundByLandmass.putIfAbsent(lm, () => <String>[]).add(pid);
  }

  final gpSeeds = <String, String>{}; // provinceId -> gpId
  final usedSeaBound = <String>{};

  // First pass: try to give each GP a seed on a distinct landmass.
  var lmIterator = seaBoundByLandmass.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  var gpIndex = 0;
  for (final entry in lmIterator) {
    if (gpIndex >= gpCount) break;
    final lmSeaBound = entry.value..sort();
    if (lmSeaBound.isEmpty) continue;
    final seedProv = lmSeaBound.removeAt(0);
    gpSeeds[seedProv] = gpIds[gpIndex];
    usedSeaBound.add(seedProv);
    gpIndex++;
  }

  // Second pass: if some GPs still lack seeds, use remaining sea-bound provinces.
  if (gpIndex < gpCount) {
    final remainingSeaBound = seaBoundProvinceIds.where((p) => !usedSeaBound.contains(p)).toList()
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

  // Target province counts per GP: fair split of the non-reserved OW share.
  final basePerGp = availableForGps ~/ gpCount;
  var remainder = availableForGps % gpCount;
  final targetPerGp = <String, int>{
    for (var i = 0; i < gpCount; i++)
      gpIds[i]: basePerGp + (remainder-- > 0 ? 1 : 0),
  };

  // Multi-source BFS growth within landmasses.
  final gpQueues = <String, List<String>>{
    for (final gpId in gpIds) gpId: <String>[],
  };
  final assignedCount = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };

  var totalAssignedToGps = 0;

  // Assign seeds.
  for (final entry in gpSeeds.entries) {
    final provinceId = entry.key;
    final gpId = entry.value;
    owners[provinceId] = gpId;
    gpQueues[gpId]!.add(provinceId);
    assignedCount[gpId] = assignedCount[gpId]! + 1;
    totalAssignedToGps++;
  }

  final unassigned = provinceIds.toSet()..removeAll(owners.keys);

  bool anyProgress;
  do {
    anyProgress = false;

    // Order GPs by currently assigned count (fewest first) to keep split fair.
    final gpOrder = gpIds.toList()
      ..sort((a, b) => assignedCount[a]!.compareTo(assignedCount[b]!));

    for (final gpId in gpOrder) {
      if (assignedCount[gpId]! >= targetPerGp[gpId]!) continue;
      if (totalAssignedToGps >= availableForGps) break;
      final queue = gpQueues[gpId]!;
      var expandedThisGp = false;

      while (queue.isNotEmpty && !expandedThisGp && totalAssignedToGps < availableForGps) {
        final from = queue.removeAt(0);
        final lm = landmassIds[from]!;
        for (final nb in neighbours[from] ?? const <String>{}) {
          if (!unassigned.contains(nb)) continue;
          if (landmassIds[nb] != lm) continue;
          owners[nb] = gpId;
          unassigned.remove(nb);
          queue.add(nb);
          assignedCount[gpId] = assignedCount[gpId]! + 1;
          totalAssignedToGps++;
          anyProgress = true;
          expandedThisGp = true;
          break;
        }
      }
    }

    // If no same-landmass neighbours can be assigned but some GPs are still under target,
    // start new seeds on other landmasses using remaining unassigned provinces.
    if (!anyProgress && unassigned.isNotEmpty && totalAssignedToGps < availableForGps) {
      final underTarget = gpIds.where((id) => assignedCount[id]! < targetPerGp[id]!).toList();
      if (underTarget.isNotEmpty) {
        final sortedUnassigned = unassigned.toList()..sort();
        for (final gpId in underTarget) {
          if (assignedCount[gpId]! >= targetPerGp[gpId]!) continue;
          if (sortedUnassigned.isEmpty) break;
          if (totalAssignedToGps >= availableForGps) break;
          final seed = sortedUnassigned.removeAt(0);
          if (!unassigned.remove(seed)) continue;
          owners[seed] = gpId;
          gpQueues[gpId]!.add(seed);
          assignedCount[gpId] = assignedCount[gpId]! + 1;
          totalAssignedToGps++;
          anyProgress = true;
        }
      }
    }
  } while (anyProgress && unassigned.isNotEmpty);

  // Any remaining unassigned OW provinces (e.g. due to extreme quotas) are left for minors.
  final remainingForMinors = unassigned.toList()..sort();

  // Contiguous clusters for minors: mirror tribe logic — equal split per minor, seed + BFS + new-seed fallback.
  if (minorCount > 0 && remainingForMinors.isNotEmpty) {
    final totalForMinors = remainingForMinors.length;
    final basePerMinor = totalForMinors ~/ minorCount;
    var remainderMinor = totalForMinors % minorCount;
    final targetPerMinor = <String, int>{
      for (var i = 0; i < minorCount; i++)
        minorIds[i]: basePerMinor + (remainderMinor-- > 0 ? 1 : 0),
    };

    final minorQueues = <String, List<String>>{
      for (final id in minorIds) id: <String>[],
    };
    final minorAssignedCount = <String, int>{
      for (final id in minorIds) id: 0,
    };

    var minorUnassigned = remainingForMinors.toSet();
    var totalAssignedToMinors = 0;

    // Initial seeds: give each minor a starting province where possible.
    for (final minorId in minorIds) {
      if (minorUnassigned.isEmpty) break;
      final seed = remainingForMinors
          .where((p) => minorUnassigned.contains(p))
          .firstWhere((p) => true, orElse: () => '');
      if (seed.isEmpty) break;
      owners[seed] = minorId;
      minorUnassigned.remove(seed);
      minorQueues[minorId]!.add(seed);
      minorAssignedCount[minorId] = minorAssignedCount[minorId]! + 1;
      totalAssignedToMinors++;
    }

    bool anyMinorProgress;
    do {
      anyMinorProgress = false;

      // Order minors by currently assigned count (fewest first) to keep split fair.
      final minorOrder = minorIds.toList()
        ..sort((a, b) => minorAssignedCount[a]!.compareTo(minorAssignedCount[b]!));

      for (final minorId in minorOrder) {
        if (minorAssignedCount[minorId]! >= targetPerMinor[minorId]!) continue;
        if (totalAssignedToMinors >= totalForMinors) break;
        final queue = minorQueues[minorId]!;
        var expandedThisMinor = false;

        while (queue.isNotEmpty &&
            !expandedThisMinor &&
            totalAssignedToMinors < totalForMinors) {
          final from = queue.removeAt(0);
          for (final nb in neighbours[from] ?? const <String>{}) {
            if (!minorUnassigned.contains(nb)) continue;
            owners[nb] = minorId;
            minorUnassigned.remove(nb);
            queue.add(nb);
            minorAssignedCount[minorId] = minorAssignedCount[minorId]! + 1;
            totalAssignedToMinors++;
            anyMinorProgress = true;
            expandedThisMinor = true;
            break;
          }
        }
      }

      // If growth stalled but unassigned provinces remain, start new seeds for
      // minors that are still under their target.
      if (!anyMinorProgress &&
          minorUnassigned.isNotEmpty &&
          totalAssignedToMinors < totalForMinors) {
        final underTarget = minorIds
            .where(
                (id) => minorAssignedCount[id]! < targetPerMinor[id]!)
            .toList();
        if (underTarget.isNotEmpty) {
          final remaining = minorUnassigned.toList()..sort();
          for (final minorId in underTarget) {
            if (minorAssignedCount[minorId]! >= targetPerMinor[minorId]!) continue;
            if (remaining.isEmpty) break;
            if (totalAssignedToMinors >= totalForMinors) break;
            final seed = remaining.removeAt(0);
            if (!minorUnassigned.remove(seed)) continue;
            owners[seed] = minorId;
            minorQueues[minorId]!.add(seed);
            minorAssignedCount[minorId] = minorAssignedCount[minorId]! + 1;
            totalAssignedToMinors++;
            anyMinorProgress = true;
          }
        }
      }
    } while (anyMinorProgress &&
        minorUnassigned.isNotEmpty &&
        totalAssignedToMinors < totalForMinors);

    // Any leftover provinces are assigned greedily to the minor with fewest.
    if (minorUnassigned.isNotEmpty) {
      final remaining = minorUnassigned.toList()..sort();
      while (remaining.isNotEmpty) {
        remaining.sort((a, b) => a.compareTo(b));
        final provinceId = remaining.removeAt(0);
        if (!minorUnassigned.remove(provinceId)) continue;
        minorIds.sort(
            (a, b) => minorAssignedCount[a]!.compareTo(minorAssignedCount[b]!));
        final minorId = minorIds.first;
        owners[provinceId] = minorId;
        minorQueues[minorId]!.add(provinceId);
        minorAssignedCount[minorId] = minorAssignedCount[minorId]! + 1;
        totalAssignedToMinors++;
      }
    }
  }

  return owners;
}

Map<String, String> _assignNewWorldOwnershipContiguous({
  required MapTopology topologyNewWorld,
  required List<String> provinceIds,
  required List<String> tribeIds,
}) {
  final neighbours = _provinceNeighboursFromTopology(topologyNewWorld);
  final owners = <String, String>{};
  final tribeCount = tribeIds.length;
  if (tribeCount == 0) {
    return {
      for (final p in provinceIds) p: '',
    };
  }

  final totalNw = provinceIds.length;
  final basePerTribe = totalNw ~/ tribeCount;
  var remainder = totalNw % tribeCount;
  final targetPerTribe = <String, int>{
    for (var i = 0; i < tribeCount; i++)
      tribeIds[i]: basePerTribe + (remainder-- > 0 ? 1 : 0),
  };

  final tribeQueues = <String, List<String>>{
    for (final id in tribeIds) id: <String>[],
  };
  final assignedCount = <String, int>{
    for (final id in tribeIds) id: 0,
  };

  final unassigned = provinceIds.toSet();
  var totalAssigned = 0;

  // Initial seeds: give each tribe a starting province where possible.
  final sorted = provinceIds.toList()..sort();
  for (final tribeId in tribeIds) {
    if (unassigned.isEmpty) break;
    final seed = sorted.firstWhere(
      (p) => unassigned.contains(p),
      orElse: () => '',
    );
    if (seed.isEmpty) break;
    owners[seed] = tribeId;
    unassigned.remove(seed);
    tribeQueues[tribeId]!.add(seed);
    assignedCount[tribeId] = assignedCount[tribeId]! + 1;
    totalAssigned++;
  }

  bool anyProgress;
  do {
    anyProgress = false;

    // Order tribes by currently assigned count (fewest first) to keep split fair.
    final tribeOrder = tribeIds.toList()
      ..sort((a, b) => assignedCount[a]!.compareTo(assignedCount[b]!));

    for (final tribeId in tribeOrder) {
      if (assignedCount[tribeId]! >= targetPerTribe[tribeId]!) continue;
      if (totalAssigned >= totalNw) break;
      final queue = tribeQueues[tribeId]!;
      var expandedThisTribe = false;

      while (queue.isNotEmpty && !expandedThisTribe && totalAssigned < totalNw) {
        final from = queue.removeAt(0);
        for (final nb in neighbours[from] ?? const <String>{}) {
          if (!unassigned.contains(nb)) continue;
          owners[nb] = tribeId;
          unassigned.remove(nb);
          queue.add(nb);
          assignedCount[tribeId] = assignedCount[tribeId]! + 1;
          totalAssigned++;
          anyProgress = true;
          expandedThisTribe = true;
          break;
        }
      }
    }

    // If growth stalled but unassigned provinces remain, start new seeds for
    // tribes that are still under their target.
    if (!anyProgress && unassigned.isNotEmpty && totalAssigned < totalNw) {
      final underTarget = tribeIds.where((id) => assignedCount[id]! < targetPerTribe[id]!).toList();
      if (underTarget.isNotEmpty) {
        final remaining = unassigned.toList()..sort();
        for (final tribeId in underTarget) {
          if (assignedCount[tribeId]! >= targetPerTribe[tribeId]!) continue;
          if (remaining.isEmpty) break;
          if (totalAssigned >= totalNw) break;
          final seed = remaining.removeAt(0);
          if (!unassigned.remove(seed)) continue;
          owners[seed] = tribeId;
          tribeQueues[tribeId]!.add(seed);
          assignedCount[tribeId] = assignedCount[tribeId]! + 1;
          totalAssigned++;
          anyProgress = true;
        }
      }
    }
  } while (anyProgress && unassigned.isNotEmpty && totalAssigned < totalNw);

  // Any leftover provinces (e.g. from extreme target combinations) are assigned
  // greedily to the tribes with the fewest provinces, preserving contiguity
  // where possible but prioritising completeness and fairness.
  if (unassigned.isNotEmpty) {
    final remaining = unassigned.toList()..sort();
    while (remaining.isNotEmpty) {
      remaining.sort((a, b) => a.compareTo(b));
      final provinceId = remaining.removeAt(0);
      if (!unassigned.remove(provinceId)) continue;
      tribeIds.sort((a, b) => assignedCount[a]!.compareTo(assignedCount[b]!));
      final tribeId = tribeIds.first;
      owners[provinceId] = tribeId;
      tribeQueues[tribeId]!.add(provinceId);
      assignedCount[tribeId] = assignedCount[tribeId]! + 1;
      totalAssigned++;
    }
  }

  return owners;
}
