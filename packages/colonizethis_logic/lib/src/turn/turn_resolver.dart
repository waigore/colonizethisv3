import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import '../combat/combat_mode_selection.dart';
import '../orders/order_engine.dart';
import '../orders/order_merge.dart';
import '../combat/combat_resolver.dart';
import '../constants.dart';
import '../combat/conflict_detection.dart';
import '../combat/quick_battle_input_builder.dart';
import '../combat/quick_battle_resolver.dart';
import '../setup/capital_choice.dart';
import '../world/connectivity_resolver.dart';
import '../economy/economy_consumption.dart';
import '../economy/economy_extraction.dart';
import '../economy/economy_production.dart';
import '../economy/economy_riches_to_treasury.dart';
import '../diplomacy/diplomacy_resolver.dart';
import '../world/minor_military_parity.dart';
import '../world/movement.dart';
import '../orders/orders_application.dart';
import '../economy/resource_extractor.dart';
import '../economy/sea_transport.dart';
import 'research_resolver.dart';
import '../world/naval.dart';
import '../combat/naval_combat_resolver.dart';
import '../world/player_view.dart';

final Logger _log = Logger();

/// Resolution sequence. SPEC/program/turn-resolution-phases.md
const List<TurnPhase> turnResolutionSequence = [
  TurnPhase.orders,
  TurnPhase.extraction,
  TurnPhase.richesToTreasury,
  TurnPhase.production,
  TurnPhase.consumption,
  TurnPhase.research,
  TurnPhase.diplomacy,
  TurnPhase.movement,
  TurnPhase.navalInterceptionCombat,
  TurnPhase.combat,
  TurnPhase.buildWork,
  TurnPhase.endOfTurn,
];

/// Turn resolver stub (Phase 1 compatibility). Runs phase sequence; only
/// endOfTurn advances turn number.
WorldState resolveTurn(WorldState current) {
  WorldState state = current;
  for (final phase in turnResolutionSequence) {
    state = _runWorldStatePhase(state, phase);
  }
  return state;
}

WorldState _runWorldStatePhase(WorldState state, TurnPhase phase) {
  switch (phase) {
    case TurnPhase.orders:
    case TurnPhase.extraction:
    case TurnPhase.richesToTreasury:
    case TurnPhase.production:
    case TurnPhase.consumption:
    case TurnPhase.research:
    case TurnPhase.diplomacy:
    case TurnPhase.movement:
    case TurnPhase.navalInterceptionCombat:
    case TurnPhase.combat:
    case TurnPhase.buildWork:
      return state;
    case TurnPhase.endOfTurn:
      return state.copyWith(
        turnState: state.turnState.copyWith(
          turnNumber: state.turnState.turnNumber + 1,
          phase: TurnPhase.orders,
        ),
      );
  }
}

/// Resolves turn using OrderEngine output. Merges human + AI orders (AI optional).
/// SPEC/program/order-engine.md: merge at turn resolution.
Game resolveTurnForGameFromOrderEngine({
  required Game game,
  required MapTopology topology,
  required OrderEngine orderEngine,
  Orders? aiOrders,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  void Function(DialogueEvent)? onDialogue,
}) {
  final merged = mergeOrderLists(
    humanOrders: orderEngine.orders,
    aiOrders: aiOrders,
  );
  return validateOrdersAndResolveTurn(
    game: game,
    topology: topology,
    orders: merged,
    onDialogue: onDialogue,
    tileMapByRegion: tileMapByRegion,
    extractedByPlayerId: extractedByPlayerId,
    defaultAssignments: defaultAssignments,
  );
}

/// Game-level resolver that runs the full Phase 2 sequence over [game],
/// using shared economy and movement helpers.
///
/// [topology] is the static map topology; [orders] holds per-player orders
/// for this turn. When [tileMapByRegion] is provided, extraction runs from
/// connectivity + resource extractor + sea allocation. When null and
/// [extractedByPlayerId] is empty, extraction phase leaves stockpiles unchanged.
/// [extractedByPlayerId] override (non-empty) is used for tests/sim_economy.

Game validateOrdersAndResolveTurn({
  required Game game,
  required MapTopology topology,
  required Orders orders,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  void Function(DialogueEvent)? onDialogue,
}) {
  final engine = OrderEngine(initialOrders: orders);
  final filtered = _filterAcceptedOrdersForAllPlayers(
    engine: engine,
    game: game,
    topology: topology,
  );
  return resolveTurnForGame(
    game: game,
    onDialogue: onDialogue,
    topology: topology,
    orders: filtered,
    tileMapByRegion: tileMapByRegion,
    extractedByPlayerId: extractedByPlayerId,
    defaultAssignments: defaultAssignments,
  );
}

Game resolveTurnForGame({
  required Game game,
  required MapTopology topology,
  required Orders orders,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  void Function(DialogueEvent)? onDialogue,
}) {
  final turn = game.worldState.turnState.turnNumber;
  _log.i('logic: turn $turn resolve start');
  Game state = game;
  final feedingCoverageByPlayerId = <String, double>{};

  for (final phase in turnResolutionSequence) {
    _log.d('logic: phase ${phase.name} start');
    switch (phase) {
      case TurnPhase.orders:
        // Orders are assumed to already be attached to the Game or passed in.
        break;
      case TurnPhase.extraction:
        state = _runExtractionPhase(
          state,
          topology,
          tileMapByRegion,
          extractedByPlayerId,
        );
        break;
      case TurnPhase.richesToTreasury:
        state = _runRichesToTreasuryPhase(state);
        break;
      case TurnPhase.production:
        state = _runProductionPhase(state, defaultAssignments);
        break;
      case TurnPhase.consumption:
        state = _runConsumptionPhase(state, feedingCoverageByPlayerId);
        break;
      case TurnPhase.research:
        state = resolveResearchPhase(state, orders);
        break;
      case TurnPhase.diplomacy:
        state = resolveDiplomacyPhase(state, orders, onDialogue: onDialogue);
        break;
      case TurnPhase.movement:
        state = _runMovementPhase(state, topology, orders);
        break;
      case TurnPhase.navalInterceptionCombat:
        state = _runNavalInterceptionCombatPhase(state, topology, orders.navalMoveOrdersByPlayerId);
        break;
      case TurnPhase.combat:
        state = _runCombatPhase(
          state,
          orders,
          feedingCoverageByPlayerId,
          topology,
          tileMapByRegion,
        );
        break;
      case TurnPhase.buildWork:
        state = applyBuildAndWorkOrders(state, orders, topology: topology);
        break;
      case TurnPhase.endOfTurn:
        state = _runEndOfTurnPhase(state);
        break;
    }
    _log.d('logic: phase ${phase.name} end');
  }

  _log.i('logic: turn $turn resolve end');
  return state;
}

Orders _filterAcceptedOrdersForAllPlayers({
  required OrderEngine engine,
  required Game game,
  required MapTopology topology,
}) {
  final original = engine.orders;
  final moveByPlayer = <String, List<MoveOrder>>{};
  final buildByPlayer = <String, List<BuildUnitOrder>>{};
  final workByPlayer = <String, List<WorkOrder>>{};
  final diploByPlayer = <String, List<DiplomaticOrder>>{};

  final playerIds = <String>{
    ...original.moveOrdersByPlayerId.keys,
    ...original.buildUnitOrdersByPlayerId.keys,
    ...original.workOrdersByPlayerId.keys,
    ...original.diplomaticOrdersByPlayerId.keys,
  };

  for (final playerId in playerIds) {
    final moves = original.moveOrdersByPlayerId[playerId] ?? const [];
    final builds = original.buildUnitOrdersByPlayerId[playerId] ?? const [];
    final works = original.workOrdersByPlayerId[playerId] ?? const [];
    final diplo =
        original.diplomaticOrdersByPlayerId[playerId] ?? const <DiplomaticOrder>[];

    if (moves.isEmpty && builds.isEmpty && works.isEmpty && diplo.isEmpty) {
      continue;
    }

    final results =
        engine.validatePlayerOrdersWithContext(game, topology, playerId);
    var idx = 0;

    OrderValidationResult _next() {
      if (idx >= results.length) {
        return const OrderValidationResult(
          status: OrderValidationStatus.accepted,
        );
      }
      final r = results[idx];
      idx++;
      return r;
    }

    for (final m in moves) {
      final r = _next();
      if (r.isAccepted) {
        moveByPlayer.putIfAbsent(playerId, () => <MoveOrder>[]).add(m);
      }
    }
    for (final b in builds) {
      final r = _next();
      if (r.isAccepted) {
        buildByPlayer
            .putIfAbsent(playerId, () => <BuildUnitOrder>[])
            .add(b);
      }
    }
    for (final w in works) {
      final r = _next();
      if (r.isAccepted) {
        workByPlayer.putIfAbsent(playerId, () => <WorkOrder>[]).add(w);
      }
    }

    // Diplomacy orders are not yet validated contextually; include all.
    if (diplo.isNotEmpty) {
      diploByPlayer[playerId] = List<DiplomaticOrder>.from(diplo);
    }
  }

  // Research orders are validated in the research phase; pass through from original.
  final researchByPlayer = Map<String, List<ResearchOrder>>.from(
    original.researchOrdersByPlayerId,
  );

  // Naval move orders pass through; validated when applied in movement phase.
  final navalByPlayer = Map<String, List<NavalMoveOrder>>.from(
    original.navalMoveOrdersByPlayerId,
  );

  final missionByPlayer = Map<String, List<NavalMissionOrder>>.from(
    original.navalMissionOrdersByPlayerId,
  );

  return Orders(
    moveOrdersByPlayerId: moveByPlayer,
    buildUnitOrdersByPlayerId: buildByPlayer,
    workOrdersByPlayerId: workByPlayer,
    diplomaticOrdersByPlayerId: diploByPlayer,
    researchOrdersByPlayerId: researchByPlayer,
    navalMoveOrdersByPlayerId: navalByPlayer,
    navalMissionOrdersByPlayerId: missionByPlayer,
  );
}

Game _runEndOfTurnPhase(Game game) {
  // If victory is already set, keep the turn state stable.
  if (game.victory != null) {
    return game;
  }

  final winnerId = _findMilitaryVictoryWinner(game);
  if (winnerId != null) {
    return game.copyWith(
      victory: VictoryState(
        winnerPlayerId: winnerId,
        type: VictoryType.military,
        turnNumber: game.worldState.turnState.turnNumber,
      ),
    );
  }

  // Spy 5-turn fog decay: decrement timers; where 0, set that province's tiles to fogged. SPEC/fog-and-exploration-resolution.md.
  var visibilityByTile = Map<String, Map<String, String>>.from(
    game.worldState.playerVisibilityByTile.map(
      (k, v) => MapEntry(k, Map<String, String>.from(v)),
    ),
  );
  final nextSpyTimers = <String, Map<String, int>>{};
  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
  for (final entry in game.worldState.spyRevealTurnsByPlayer.entries) {
    final playerId = entry.key;
    final byProvince = entry.value;
    final newByProvince = <String, int>{};
    final vis = Map<String, String>.from(visibilityByTile[playerId] ?? {});
    for (final provEntry in byProvince.entries) {
      final provinceId = provEntry.key;
      final turns = provEntry.value;
      if (turns <= 1) {
        final regionId = ProvinceId.regionIdFrom(provinceId);
        final tileKeys = tileKeysByRegion[regionId]?[provinceId] ?? [];
        for (final tk in tileKeys) {
          vis[tk] = VisibilityLevel.fogged.name;
        }
      } else {
        newByProvince[provinceId] = turns - 1;
      }
    }
    if (newByProvince.isNotEmpty) nextSpyTimers[playerId] = newByProvince;
    visibilityByTile[playerId] = vis;
  }
  var stateForFog = game.copyWith(
    worldState: game.worldState.copyWith(
      playerVisibilityByTile: visibilityByTile,
      spyRevealTurnsByPlayer: nextSpyTimers,
    ),
  );
  // Fog decay: other-faction provinces with no Explorer/Spy → fogged. SPEC/fog-and-exploration-resolution.md.
  final nextVisibility = _applyFogDecay(stateForFog);

  return game.copyWith(
    worldState: game.worldState.copyWith(
      turnState: game.worldState.turnState.copyWith(
        turnNumber: game.worldState.turnState.turnNumber + 1,
        phase: TurnPhase.orders,
      ),
      playerVisibilityByTile: nextVisibility,
      spyRevealTurnsByPlayer: nextSpyTimers,
    ),
  );
}

/// For each player, set tiles in other-faction provinces to fogged when no Explorer/Spy in that province.
Map<String, Map<String, String>> _applyFogDecay(Game game) {
  const explorerTypes = {'explorer', 'spy'};
  final owOwnerByProvince = {
    for (final p in game.worldState.oldWorld.provinces) p.id: p.ownerId,
  };
  final nwOwnerByProvince = {
    for (final p in game.worldState.newWorld.provinces) p.id: p.ownerId,
  };

  final provincesWithExplorerByPlayer = <String, Set<String>>{};
  for (final u in game.worldState.oldWorld.units) {
    if (explorerTypes.contains(u.type.toLowerCase())) {
      final localId = ProvinceId.localIdFrom(u.locationProvinceId);
      provincesWithExplorerByPlayer
          .putIfAbsent(u.ownerId, () => <String>{})
          .add(localId);
    }
  }
  for (final u in game.worldState.newWorld.units) {
    if (explorerTypes.contains(u.type.toLowerCase())) {
      final localId = ProvinceId.localIdFrom(u.locationProvinceId);
      provincesWithExplorerByPlayer
          .putIfAbsent(u.ownerId, () => <String>{})
          .add(localId);
    }
  }

  final result = <String, Map<String, String>>{};
  for (final entry in game.worldState.playerVisibilityByTile.entries) {
    final playerId = entry.key;
    final visibility = Map<String, String>.from(entry.value);
    final hasExplorerIn = provincesWithExplorerByPlayer[playerId] ?? const {};

    for (final tileKey in visibility.keys.toList()) {
      final parts = tileKey.split('|');
      if (parts.length != 4) continue;
      final provinceId = parts[1];
      final ownerId = owOwnerByProvince[provinceId] ?? nwOwnerByProvince[provinceId];
      if (ownerId == null || ownerId == playerId) continue;
      if (!hasExplorerIn.contains(provinceId)) {
        visibility[tileKey] = VisibilityLevel.fogged.name;
      }
    }
    result[playerId] = visibility;
  }
  return result;
}

/// Returns the id of a Great Power that controls 31+ Old World provinces,
/// or null when no military victory has been achieved.
String? _findMilitaryVictoryWinner(Game game) {
  const int requiredProvinces = 31;
  final countsByOwner = <String, int>{};
  for (final province in game.worldState.oldWorld.provinces) {
    final ownerId = province.ownerId;
    if (ownerId == null || ownerId.isEmpty) continue;
    countsByOwner.update(ownerId, (v) => v + 1, ifAbsent: () => 1);
  }

  // Only Great Powers are eligible for this victory condition.
  final gpIds = game.players.map((p) => p.id).toSet();
  String? winnerId;
  for (final entry in countsByOwner.entries) {
    final ownerId = entry.key;
    final count = entry.value;
    if (!gpIds.contains(ownerId)) continue;
    if (count >= requiredProvinces) {
      // Deterministic tie-breaking: pick the lexicographically smallest id
      // among eligible winners.
      if (winnerId == null || ownerId.compareTo(winnerId) < 0) {
        winnerId = ownerId;
      }
    }
  }
  return winnerId;
}

Game _runExtractionPhase(
  Game state,
  MapTopology topology,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId,
) {
  if (extractedByPlayerId.isNotEmpty) {
    return applyExtractionForPlayers(state, extractedByPlayerId);
  }
  if (tileMapByRegion == null || tileMapByRegion.isEmpty) {
    return state;
  }
  final connectivity = resolveConnectivity(
    game: state,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  final extraction = computeExtraction(
    game: state,
    tileMapByRegion: tileMapByRegion,
    connectivityResult: connectivity,
    techCapForPlayer: (playerId) {
      final player = state.playerById(playerId);
      return extractionCapForUnlocked(player?.techUnlocked);
    },
  );
  var currentState = state;
  final updatedPlayers = <Player>[];
  var extractionSeed = (state.globalGameSeed ?? 0) ^ (state.worldState.turnState.turnNumber * 0x9E3779B1);
  for (final player in state.players) {
    var stockpile = player.stockpile;
    final tot = extraction[player.id];
    if (tot != null) {
      stockpile = applyExtractionToStockpile(stockpile, tot.land);
      var overseasDelivered = allocateOverseasToStockpile(
        tot.overseas,
        cargoHolds: defaultCargoHoldsStub,
      );
      if (overseasDelivered.isNotEmpty) {
        extractionSeed = (extractionSeed * 1103515245 + 12345) & 0x7fffffff;
        final interception = applyTradeInterception(
          currentState,
          player.id,
          overseasDelivered,
          seed: extractionSeed ^ player.id.hashCode,
        );
        overseasDelivered = interception.reducedDelivered;
        currentState = currentState.copyWith(
          worldState: currentState.worldState.copyWith(fleets: interception.updatedFleets),
        );
      }
      stockpile = applyExtractionToStockpile(stockpile, overseasDelivered);
    }
    updatedPlayers.add(player.copyWith(stockpile: stockpile));
  }
  return currentState.copyWith(players: updatedPlayers);
}

Game _runProductionPhase(Game game, List<AssignedRecipe> defaultAssignments) {
  final updatedPlayers = <Player>[];

  for (final player in game.players) {
    final result = resolveProduction(
      stockpile: player.stockpile,
      workers: player.workerPool,
      assignments: defaultAssignments,
    );
    updatedPlayers.add(
      player.copyWith(
        stockpile: result.stockpile,
        workerPool: result.workerPool,
      ),
    );
  }

  return game.copyWith(players: updatedPlayers);
}

Game _runConsumptionPhase(
  Game game,
  Map<String, double> feedingCoverageByPlayerId,
) {
  final updatedPlayers = <Player>[];

  for (final player in game.players) {
    // Count this player's regiments across both regions.
    final regimentCounts = <String, int>{};
    for (final unit in game.worldState.oldWorld.units) {
      if (unit.ownerId != player.id) continue;
      regimentCounts.update(unit.type, (v) => v + 1, ifAbsent: () => 1);
    }
    for (final unit in game.worldState.newWorld.units) {
      if (unit.ownerId != player.id) continue;
      regimentCounts.update(unit.type, (v) => v + 1, ifAbsent: () => 1);
    }

    final result = resolveConsumption(
      stockpile: player.stockpile,
      workers: player.workerPool,
      regimentCountsById: regimentCounts,
    );

    double coverage;
    if (result.totalRegiments <= 0) {
      coverage = 1.0;
    } else {
      coverage = result.fullyFedRegiments / result.totalRegiments;
      if (coverage < 0) coverage = 0;
      if (coverage > 1) coverage = 1;
    }
    feedingCoverageByPlayerId[player.id] = coverage;
    updatedPlayers.add(
      player.copyWith(
        stockpile: result.stockpile,
        workerPool: result.workerPool,
      ),
    );
  }

  return game.copyWith(players: updatedPlayers);
}

Game _runRichesToTreasuryPhase(Game game) {
  final updatedPlayers = <Player>[];

  for (final player in game.players) {
    final result = resolveRichesToTreasury(stockpile: player.stockpile);
    updatedPlayers.add(
      player.copyWith(
        stockpile: result.stockpile,
        treasury: player.treasury + result.treasuryDelta,
      ),
    );
  }

  return game.copyWith(players: updatedPlayers);
}

Game _runMovementPhase(
  Game game,
  MapTopology topology,
  Orders orders,
) {
  var state = game;

  final moveOrders = orders.moveOrdersByPlayerId;
  final tileKeysByRegion = state.worldState.tileKeysByRegionAndProvince;
  if (moveOrders.isNotEmpty) {
    final oldWorld = applyMoveOrdersToRegion(
      state.worldState.oldWorld,
      topology,
      moveOrders,
      regionId: kRegionOldWorld,
      tileKeysByRegionAndProvince: tileKeysByRegion,
    );
    final newWorld = applyMoveOrdersToRegion(
      state.worldState.newWorld,
      topology,
      moveOrders,
      regionId: kRegionNewWorld,
      tileKeysByRegionAndProvince: tileKeysByRegion,
    );
    // Spy leave province: set 5-turn reveal timer for (owner, left province). SPEC/fog-and-exploration-resolution.md.
    final spyTimers = Map<String, Map<String, int>>.from(
      state.worldState.spyRevealTurnsByPlayer.map(
        (k, v) => MapEntry(k, Map<String, int>.from(v)),
      ),
    );
    void recordSpyLeft(String ownerId, String provinceId) {
      spyTimers.putIfAbsent(ownerId, () => {})[provinceId] = 5;
    }
    for (final u in state.worldState.oldWorld.units) {
      if (!isSpyUnit(u.type)) continue;
      final after = oldWorld.units.where((x) => x.id == u.id).firstOrNull;
      if (after != null && after.locationProvinceId != u.locationProvinceId) {
        recordSpyLeft(u.ownerId, u.locationProvinceId);
      }
    }
    for (final u in state.worldState.newWorld.units) {
      if (!isSpyUnit(u.type)) continue;
      final after = newWorld.units.where((x) => x.id == u.id).firstOrNull;
      if (after != null && after.locationProvinceId != u.locationProvinceId) {
        recordSpyLeft(u.ownerId, u.locationProvinceId);
      }
    }
    state = state.copyWith(
      worldState: state.worldState.copyWith(
        oldWorld: oldWorld,
        newWorld: newWorld,
        spyRevealTurnsByPlayer: spyTimers,
      ),
    );
  }

  // Naval movement and ship reveal. SPEC/program/naval-movement-resolution.md.
  final navalOrders = orders.navalMoveOrdersByPlayerId;
  if (navalOrders.isNotEmpty) {
    state = _applyNavalMovesAndShipReveal(state, topology, navalOrders);
  }

  // Naval mission assignment. Phase 6. Apply after moves so fleet position is final.
  final missionOrders = orders.navalMissionOrdersByPlayerId;
  if (missionOrders.isNotEmpty) {
    state = _applyNavalMissionOrders(state, missionOrders);
  }

  return state;
}

/// Apply naval mission orders: set fleet mission and optional target per order.
Game _applyNavalMissionOrders(
  Game game,
  Map<String, List<NavalMissionOrder>> navalMissionOrdersByPlayerId,
) {
  var fleets = List<Fleet>.from(game.worldState.fleets);
  final fleetById = {for (final f in fleets) f.id: f};

  for (final entry in navalMissionOrdersByPlayerId.entries) {
    final playerId = entry.key;
    for (final order in entry.value) {
      final fleet = fleetById[order.fleetId];
      if (fleet == null || fleet.ownerId != playerId) continue;
      FleetMission mission = FleetMission.none;
      for (final m in FleetMission.values) {
        if (m.name == order.mission) {
          mission = m;
          break;
        }
      }
      final newFleet = fleet.copyWith(
        mission: mission,
        targetPortId: order.targetPortId,
        targetProvinceId: order.targetProvinceId,
      );
      final idx = fleets.indexWhere((f) => f.id == fleet.id);
      if (idx >= 0) {
        fleets = List<Fleet>.from(fleets)..[idx] = newFleet;
        fleetById[fleet.id] = newFleet;
      }
    }
  }

  return game.copyWith(
    worldState: game.worldState.copyWith(fleets: fleets),
  );
}

/// Apply naval move orders: update fleet positions; on enter, set coastal province tiles to revealed.
Game _applyNavalMovesAndShipReveal(
  Game game,
  MapTopology topology,
  Map<String, List<NavalMoveOrder>> navalMoveOrdersByPlayerId,
) {
  var fleets = List<Fleet>.from(game.worldState.fleets);
  var visibilityByTile = Map<String, Map<String, String>>.from(game.worldState.playerVisibilityByTile);
  final fleetById = {for (final f in fleets) f.id: f};
  final nodesById = {for (final n in topology.nodes) n.id: n};

  for (final entry in navalMoveOrdersByPlayerId.entries) {
    final playerId = entry.key;
    for (final order in entry.value) {
      final fleet = fleetById[order.fleetId];
      if (fleet == null || fleet.ownerId != playerId) continue;
      if (!isAdjacentSeaZone(topology, fleet.seaZoneId, order.destinationSeaZoneId)) continue;

      final newFleet = fleet.copyWith(seaZoneId: order.destinationSeaZoneId);
      final idx = fleets.indexWhere((f) => f.id == fleet.id);
      if (idx >= 0) {
        fleets = List<Fleet>.from(fleets)..[idx] = newFleet;
        fleetById[fleet.id] = newFleet;
      }

      // Ship reveal: coastal provinces of destination sea zone -> revealed for owner.
      final provinceIds = provinceIdsAdjacentToSeaZone(topology, order.destinationSeaZoneId);
      final vis = Map<String, String>.from(visibilityByTile[playerId] ?? {});
      for (final localProvinceId in provinceIds) {
        final node = nodesById[localProvinceId];
        if (node == null) continue;
        final regionId = node.regionId;
        if (regionId.isEmpty) continue;
        final fullProvinceId = ProvinceId.full(regionId, localProvinceId);
        final tileKeys = game.worldState.tileKeysByRegionAndProvince[regionId]?[fullProvinceId] ?? [];
        for (final tk in tileKeys) {
          vis[tk] = VisibilityLevel.revealed.name;
        }
      }
      visibilityByTile = Map<String, Map<String, String>>.from(visibilityByTile)
        ..[playerId] = vis;
    }
  }

  return game.copyWith(
    worldState: game.worldState.copyWith(
      fleets: fleets,
      playerVisibilityByTile: visibilityByTile,
    ),
  );
}

/// Naval Interception & Naval Combat phase. SPEC/program/turn-resolution-phases.md, naval-combat-resolution.md.
/// [navalMoveOrdersByPlayerId] used to filter battles by interception (mover vs Patrol/Blockade).
Game _runNavalInterceptionCombatPhase(
  Game game,
  MapTopology topology,
  Map<String, List<NavalMoveOrder>> navalMoveOrdersByPlayerId,
) {
  var battles = detectNavalConflicts(game);
  final movedFleetIds = <String>{
    for (final list in navalMoveOrdersByPlayerId.values)
      for (final order in list) order.fleetId,
  };
  var seed = (game.globalGameSeed ?? 0) ^ (game.worldState.turnState.turnNumber * 0x9E3779B1);
  battles = filterBattlesByInterception(game, battles, movedFleetIds, seed);
  seed = (seed * 1103515245 + 12345) & 0x7fffffff;
  var state = game;
  for (final battle in battles) {
    final result = resolveSeaBattle(battle, seed);
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    final regionId = regionIdForSeaZone(topology, battle.seaZoneId);
    state = applyNavalBattleResults(state, battle, result, regionId, topology: topology);
  }
  return state;
}

Game _runCombatPhase(
  Game game,
  Orders orders,
  Map<String, double> feedingCoverageByPlayerId,
  MapTopology topology,
  Map<String, TileMapResult>? tileMapByRegion,
) {
  // When tileMapByRegion is null (e.g. tests), skip capital reassignment.
  Game state = applyMinorMilitaryParity(game);
  final battles = detectConflicts(state, orders);
  final defaultMode = game.defaultCombatMode ?? CombatMode.autoResolve;
  for (final ctx in battles) {
    final mode = resolveCombatModeForBattle(
      state,
      ctx,
      defaultMode: defaultMode,
      perBattleOverrides: game.combatModeByProvinceId.isNotEmpty
          ? game.combatModeByProvinceId
          : null,
    );
    if (mode == CombatMode.quickBattle) {
      final input = buildQuickBattleInput(state, ctx, seed: state.worldState.turnState.turnNumber);
      final qbResult = resolveQuickBattle(input);
      state = applyQuickBattleResultToGame(state, ctx, qbResult);
    } else {
      state = resolveBattleContext(
        state,
        ctx,
        feedingCoverageByPlayerId: feedingCoverageByPlayerId,
      );
    }
  }
  // Capital reassignment: any GP that no longer owns their capital province. SPEC/game/capital-and-connectivity § Capital loss and reassignment.
  if (tileMapByRegion != null && tileMapByRegion.isNotEmpty) {
    state = _applyCapitalReassignmentAfterCombat(state, topology, tileMapByRegion);
  }
  return state;
}

/// For each Great Power that lost their capital province, pick new capital in original region (prefer seaboard), apply port/road and road path. Same shared API as init.
Game _applyCapitalReassignmentAfterCombat(
  Game state,
  MapTopology topology,
  Map<String, TileMapResult> tileMapByRegion,
) {
  Game game = state;
  for (final player in state.players) {
    final capProvinceId = player.capitalProvinceId;
    if (capProvinceId == null || player.capitalTile == null) continue;
    final regionId = ProvinceId.regionIdFrom(capProvinceId);
    final region = regionId == kRegionOldWorld
        ? state.worldState.oldWorld
        : state.worldState.newWorld;
    final province = region.provinces.where((p) => p.id == capProvinceId).firstOrNull;
    if (province == null) continue;
    if (province.ownerId == player.id) continue;
    // Player lost capital. Choose new capital in original region from owned provinces; prefer seaboard.
    final ownedInRegion = region.provinces
        .where((p) => p.ownerId == player.id)
        .map((p) => p.id)
        .toList();
    if (ownedInRegion.isEmpty) {
      final updatedPlayers = game.players.map((p) {
        if (p.id != player.id) return p;
        return p.copyWith(capitalProvinceId: null, capitalTile: null);
      }).toList();
      game = game.copyWith(players: updatedPlayers);
      _log.i('logic: player ${player.id} lost capital and has no provinces in $regionId; capital cleared');
      continue;
    }
    final tileMap = tileMapByRegion[regionId];
    if (tileMap == null) continue;
    try {
      final (newProvinceId, tile) = pickCapitalForFaction(
        ownedInRegion,
        regionId,
        topology,
        tileMap,
        requireSeaBound: false,
      );
      game = setCapitalForReassignment(
        game: game,
        playerId: player.id,
        provinceId: newProvinceId,
        tile: tile,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
      );
      _log.i('logic: player ${player.id} capital reassigned to $newProvinceId after loss');
    } catch (e, st) {
      _log.w('logic: capital reassignment failed for ${player.id}', error: e, stackTrace: st);
    }
  }
  return game;
}
