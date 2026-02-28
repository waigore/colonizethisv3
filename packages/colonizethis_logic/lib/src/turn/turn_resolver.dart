import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import '../combat/combat_mode_selection.dart';
import '../orders/order_engine.dart';
import '../orders/order_merge.dart';
import '../constants.dart';
import '../combat/conflict_detection.dart';
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
import '../dossier/evidence_rules.dart';
import '../dossier/event_dialogue.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';
import 'combat_phase_helpers.dart';
import 'end_of_turn_resolver.dart';

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
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
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
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
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
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
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
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
  );
}

Game resolveTurnForGame({
  required Game game,
  required MapTopology topology,
  required Orders orders,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  /// Per-player production assignments; when set, used for that player instead of [defaultAssignments]. SPEC/ai/economy-planner.md.
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  void Function(DialogueEvent)? onDialogue,

  /// Called after production phase with playerId → (recipeId → quantity produced). For projection API. SPEC/program/order-projections.md.
  void Function(Map<String, Map<String, int>> productionByRecipeByPlayerId)?
      onProductionComplete,
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
        state = _runProductionPhase(
          state,
          defaultAssignments,
          defaultAssignmentsByPlayerId,
          onProductionComplete,
        );
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
        state = _runNavalInterceptionCombatPhase(
          state,
          topology,
          orders.navalMoveOrdersByPlayerId,
          onDialogue: onDialogue,
        );
        break;
      case TurnPhase.combat:
        state = _runCombatPhase(
          state,
          orders,
          feedingCoverageByPlayerId,
          topology,
          tileMapByRegion,
          onDialogue: onDialogue,
        );
        break;
      case TurnPhase.buildWork:
        state = applyBuildAndWorkOrders(
          state,
          orders,
          topology: topology,
          tileMapByRegion: tileMapByRegion,
          onDialogue: onDialogue,
        );
        break;
      case TurnPhase.endOfTurn:
        state = runEndOfTurnPhase(state, onDialogue: onDialogue);
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
    final diplo = original.diplomaticOrdersByPlayerId[playerId] ??
        const <DiplomaticOrder>[];

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
        buildByPlayer.putIfAbsent(playerId, () => <BuildUnitOrder>[]).add(b);
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
  var extractionSeed = (state.globalGameSeed ?? 0) ^
      (state.worldState.turnState.turnNumber * 0x9E3779B1);
  for (final player in state.players) {
    var stockpile = player.stockpile;
    final tot = extraction[player.id];
    if (tot != null) {
      stockpile = applyExtractionToStockpile(stockpile, tot.land);
      var overseasDelivered = allocateOverseasToStockpile(
        tot.overseas,
        cargoHolds: cargoHoldsForHomeFleet(state, player.id),
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
          worldState: currentState.worldState
              .copyWith(fleets: interception.updatedFleets),
        );
      }
      stockpile = applyExtractionToStockpile(stockpile, overseasDelivered);
    }
    updatedPlayers.add(player.copyWith(stockpile: stockpile));
  }
  return currentState.copyWith(players: updatedPlayers);
}

Game _runProductionPhase(
  Game game,
  List<AssignedRecipe> defaultAssignments,
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  void Function(Map<String, Map<String, int>> productionByRecipeByPlayerId)?
      onProductionComplete,
) {
  final updatedPlayers = <Player>[];
  final productionByRecipeByPlayerId = <String, Map<String, int>>{};

  for (final player in game.players) {
    final assignments = defaultAssignmentsByPlayerId?[player.id] ?? defaultAssignments;
    final result = resolveProduction(
      stockpile: player.stockpile,
      workers: player.workerPool,
      assignments: assignments,
    );
    if (result.productionByRecipe.isNotEmpty) {
      productionByRecipeByPlayerId[player.id] =
          Map<String, int>.from(result.productionByRecipe);
    }
    updatedPlayers.add(
      player.copyWith(
        stockpile: result.stockpile,
        workerPool: result.workerPool,
      ),
    );
  }

  onProductionComplete?.call(productionByRecipeByPlayerId);
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
  final multiplier = game.richesCashMultiplier;

  for (final player in game.players) {
    final result = resolveRichesToTreasury(
      stockpile: player.stockpile,
      richesCashMultiplier: multiplier,
    );
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
    // Province ownership lookup for Spy timers (other-faction only).
    final ownerByProvinceId = <String, String?>{
      for (final p in state.worldState.oldWorld.provinces) p.id: p.ownerId,
      for (final p in state.worldState.newWorld.provinces) p.id: p.ownerId,
    };
    // Movement within own provinces: no adjacency and no region restriction. SPEC/program/movement.md.
    bool isDestinationOwnedByPlayer(String playerId, String destFullProvinceId) =>
        tryGetProvince(state.worldState, destFullProvinceId)?.ownerId == playerId;

    final originalOldWorld = state.worldState.oldWorld;
    final originalNewWorld = state.worldState.newWorld;

    // First apply cross-region moves within the player's own provinces (OldWorld ↔ NewWorld).
    final crossRegionResult = _applyCrossRegionOwnProvinceMoves(
      state,
      moveOrders,
      tileKeysByRegion,
    );

    // Then apply remaining land moves within each region using adjacency.
    final oldWorld = applyMoveOrdersToRegion(
      crossRegionResult.oldWorld,
      topology,
      crossRegionResult.remainingMoveOrdersByPlayerId,
      regionId: kRegionOldWorld,
      tileKeysByRegionAndProvince: tileKeysByRegion,
      isDestinationOwnedByPlayer: isDestinationOwnedByPlayer,
    );
    final newWorld = applyMoveOrdersToRegion(
      crossRegionResult.newWorld,
      topology,
      crossRegionResult.remainingMoveOrdersByPlayerId,
      regionId: kRegionNewWorld,
      tileKeysByRegionAndProvince: tileKeysByRegion,
      isDestinationOwnedByPlayer: isDestinationOwnedByPlayer,
    );
    // Spy leave province: set 5-turn reveal timer for (owner, left province). SPEC/program/fog-and-exploration-resolution.md.
    final spyTimers = Map<String, Map<String, int>>.from(
      state.worldState.spyRevealTurnsByPlayer.map(
        (k, v) => MapEntry(k, Map<String, int>.from(v)),
      ),
    );
    void recordSpyLeft(String ownerId, String provinceId) {
      // Only start timers for provinces owned by another faction; own provinces never decay.
      final provinceOwner = ownerByProvinceId[provinceId];
      if (provinceOwner == null || provinceOwner == ownerId) {
        return;
      }
      spyTimers.putIfAbsent(ownerId, () => {})[provinceId] = 5;
    }

    for (final u in originalOldWorld.units) {
      if (!isSpyUnit(u.type)) continue;
      final after = oldWorld.units.where((x) => x.id == u.id).firstOrNull;
      if (after != null && after.locationProvinceId != u.locationProvinceId) {
        recordSpyLeft(u.ownerId, u.locationProvinceId);
      }
    }
    for (final u in originalNewWorld.units) {
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

/// Apply cross-region land moves within a player's own provinces (OldWorld ↔ NewWorld).
/// These moves ignore adjacency and complete in a single Movement phase. SPEC/program/movement.md.
({
  RegionData oldWorld,
  RegionData newWorld,
  Map<String, List<MoveOrder>> remainingMoveOrdersByPlayerId,
}) _applyCrossRegionOwnProvinceMoves(
  Game game,
  Map<String, List<MoveOrder>> moveOrdersByPlayerId,
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince,
) {
  var oldUnits = List<Unit>.from(game.worldState.oldWorld.units);
  var newUnits = List<Unit>.from(game.worldState.newWorld.units);

  final unitRegionById = <String, String>{
    for (final u in oldUnits) u.id: kRegionOldWorld,
    for (final u in newUnits) u.id: kRegionNewWorld,
  };
  final unitsById = <String, Unit>{
    for (final u in oldUnits) u.id: u,
    for (final u in newUnits) u.id: u,
  };

  String? _firstTileFor(String regionId, String fullProvinceId) {
    final byProvince = tileKeysByRegionAndProvince[regionId];
    if (byProvince == null) return null;
    final tiles = byProvince[fullProvinceId];
    if (tiles == null || tiles.isEmpty) return null;
    return tiles.first;
  }

  final remaining = <String, List<MoveOrder>>{};

  moveOrdersByPlayerId.forEach((playerId, orders) {
    final remainingForPlayer = <MoveOrder>[];
    for (final o in orders) {
      final unit = unitsById[o.unitId];
      if (unit == null || unit.ownerId != playerId) {
        remainingForPlayer.add(o);
        continue;
      }
      final currentRegion = unitRegionById[unit.id];
      if (currentRegion == null) {
        remainingForPlayer.add(o);
        continue;
      }
      final destFullId =
          resolveToFullProvinceId(game.worldState, o.destinationProvinceId);
      final destRegion = ProvinceId.regionIdFrom(destFullId);
      if (destRegion == currentRegion) {
        remainingForPlayer.add(o);
        continue;
      }
      final destProvince = tryGetProvince(game.worldState, destFullId);
      if (destProvince == null || destProvince.ownerId != playerId) {
        remainingForPlayer.add(o);
        continue;
      }

      // Cross-region own-province move: apply immediately.
      final isCivilian =
          unit.tileKey != null && unit.tileKey!.isNotEmpty;
      final firstTile =
          isCivilian ? _firstTileFor(destRegion, destFullId) : null;
      final movedUnit = isCivilian && firstTile != null
          ? unit.copyWith(provinceId: destFullId, tileKey: firstTile)
          : unit.copyWith(provinceId: destFullId);

      unitsById[unit.id] = movedUnit;
      unitRegionById[unit.id] = destRegion;

      if (currentRegion == kRegionOldWorld) {
        oldUnits = oldUnits.where((u) => u.id != unit.id).toList();
      } else if (currentRegion == kRegionNewWorld) {
        newUnits = newUnits.where((u) => u.id != unit.id).toList();
      }

      if (destRegion == kRegionOldWorld) {
        oldUnits = [...oldUnits, movedUnit];
      } else if (destRegion == kRegionNewWorld) {
        newUnits = [...newUnits, movedUnit];
      }
    }
    if (remainingForPlayer.isNotEmpty) {
      remaining[playerId] = remainingForPlayer;
    }
  });

  return (
    oldWorld: RegionData(
      provinces: game.worldState.oldWorld.provinces,
      units: oldUnits,
    ),
    newWorld: RegionData(
      provinces: game.worldState.newWorld.provinces,
      units: newUnits,
    ),
    remainingMoveOrdersByPlayerId: remaining,
  );
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
      final homeFleetId = 'fleet_$playerId';

      // Special mission: join home fleet. Only allowed when fleet is in the same
      // sea zone as the player's home fleet; moves ships back into the home fleet.
      if (order.mission == 'join_home_fleet') {
        final homeFleet = fleetById[homeFleetId];
        if (homeFleet == null) {
          continue;
        }
        if (homeFleet.seaZoneId != fleet.seaZoneId) {
          continue;
        }
        if (fleet.shipTypeIds.isEmpty) {
          continue;
        }
        // Move all ships from this fleet into the home fleet.
        final updatedHome = homeFleet.copyWith(
          shipTypeIds: [...homeFleet.shipTypeIds, ...fleet.shipTypeIds],
        );
        fleets = fleets
            .where((f) => f.id != fleet.id)
            .map((f) => f.id == homeFleetId ? updatedHome : f)
            .toList();
        fleetById[homeFleetId] = updatedHome;
        continue;
      }

      // Home fleet cannot receive active missions; keep mission as none.
      if (fleet.id == homeFleetId) {
        continue;
      }
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
  var visibilityByTile = Map<String, Map<String, String>>.from(
      game.worldState.playerVisibilityByTile);
  final fleetById = {for (final f in fleets) f.id: f};
  final nodesById = {for (final n in topology.nodes) n.id: n};

  for (final entry in navalMoveOrdersByPlayerId.entries) {
    final playerId = entry.key;
    for (final order in entry.value) {
      final fleet = fleetById[order.fleetId];
      if (fleet == null || fleet.ownerId != playerId) continue;
      final homeFleetId = 'fleet_$playerId';

      // Home fleet cannot move; a move targeting it is ignored.
      if (fleet.id == homeFleetId) {
        continue;
      }
      if (!isAdjacentSeaZone(
          topology, fleet.seaZoneId, order.destinationSeaZoneId)) continue;

      final newFleet = fleet.copyWith(seaZoneId: order.destinationSeaZoneId);
      final idx = fleets.indexWhere((f) => f.id == fleet.id);
      if (idx >= 0) {
        fleets = List<Fleet>.from(fleets)..[idx] = newFleet;
        fleetById[fleet.id] = newFleet;
      }

      // Ship reveal: coastal provinces of destination sea zone -> revealed for owner.
      final provinceIds =
          provinceIdsAdjacentToSeaZone(topology, order.destinationSeaZoneId);
      final vis = Map<String, String>.from(visibilityByTile[playerId] ?? {});
      for (final localProvinceId in provinceIds) {
        final node = nodesById[localProvinceId];
        if (node == null) continue;
        final regionId = node.regionId;
        if (regionId.isEmpty) continue;
        final fullProvinceId = ProvinceId.full(regionId, localProvinceId);
        final tileKeys = game.worldState.tileKeysByRegionAndProvince[regionId]
                ?[fullProvinceId] ??
            [];
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
  Map<String, List<NavalMoveOrder>> navalMoveOrdersByPlayerId, {
  void Function(DialogueEvent)? onDialogue,
}) {
  var battles = detectNavalConflicts(game);
  final movedFleetIds = <String>{
    for (final list in navalMoveOrdersByPlayerId.values)
      for (final order in list) order.fleetId,
  };
  var seed = (game.globalGameSeed ?? 0) ^
      (game.worldState.turnState.turnNumber * 0x9E3779B1);
  battles = filterBattlesByInterception(game, battles, movedFleetIds, seed);
  seed = (seed * 1103515245 + 12345) & 0x7fffffff;
  var state = game;
  final turn = game.worldState.turnState.turnNumber;
  var battleIndex = 0;
  for (final battle in battles) {
    final result = resolveSeaBattle(battle, seed);
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    final regionId = regionIdForSeaZone(topology, battle.seaZoneId);
    state = applyNavalBattleResults(state, battle, result, regionId,
        topology: topology);
    // Evidence: AI won naval battle (one side eliminated). SPEC/ai/hidden-agendas.md, ai-events-and-dossier.md.
    String? victorId;
    String? loserId;
    if (result.survivingShipTypeIdsSide1.isEmpty &&
        result.survivingShipTypeIdsSide2.isNotEmpty) {
      victorId = battle.side2.ownerId;
      loserId = battle.side1.ownerId;
    } else if (result.survivingShipTypeIdsSide2.isEmpty &&
        result.survivingShipTypeIdsSide1.isNotEmpty) {
      victorId = battle.side1.ownerId;
      loserId = battle.side2.ownerId;
    }
    if (victorId != null && loserId != null) {
      final evidence =
          evidenceForNavalBattleVictory(state, victorId, loserId, turn);
      if (evidence.isNotEmpty) {
        state = state.copyWith(dossierEvidenceEntries: [
          ...state.dossierEvidenceEntries,
          ...evidence
        ]);
      }
      final dialogueSeed = (seed ^ (battleIndex * 0x9E3779B1)) & 0x7fffffff;
      final events = dialogueEventsForNavalBattleResult(
          state, victorId, loserId, turn, dialogueSeed);
      if (onDialogue != null && events.isNotEmpty) {
        for (final e in events) onDialogue(e);
      }
    }
    battleIndex++;
  }
  return state;
}

Game _runCombatPhase(
  Game game,
  Orders orders,
  Map<String, double> feedingCoverageByPlayerId,
  MapTopology topology,
  Map<String, TileMapResult>? tileMapByRegion, {
  void Function(DialogueEvent)? onDialogue,
}) {
  // When tileMapByRegion is null (e.g. tests), skip capital reassignment.
  final previousCapitalByPlayer = {
    for (final p in game.players) p.id: p.capitalProvinceId,
  };
  Game state = applyMinorMilitaryParity(game);
  final battles = detectConflicts(state, orders);
  final defaultMode = game.defaultCombatMode ?? CombatMode.autoResolve;
  final turn = state.worldState.turnState.turnNumber;
  var seed = (game.globalGameSeed ?? 0) ^ (turn * 0x9E3779B1);
  var battleIndex = 0;
  for (final ctx in battles) {
    final mode = resolveCombatModeForBattle(
      state,
      ctx,
      defaultMode: defaultMode,
      perBattleOverrides: game.combatModeByProvinceId.isNotEmpty
          ? game.combatModeByProvinceId
          : null,
    );
    state = runOneLandBattle(
      state,
      ctx,
      mode,
      feedingCoverageByPlayerId,
      turn,
      battleIndex,
      seed,
      onDialogue: onDialogue,
    );
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    battleIndex++;
  }
  // Capital reassignment: any GP that no longer owns their capital province. SPEC/game/capital-and-connectivity § Capital loss and reassignment.
  if (tileMapByRegion != null && tileMapByRegion.isNotEmpty) {
    state =
        _applyCapitalReassignmentAfterCombat(state, topology, tileMapByRegion);
  }
  // Great Power fall: any GP that lost its original capital and has no port provinces left forfeits.
  state = _applyGreatPowerFall(state, previousCapitalByPlayer);
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
    final province =
        region.provinces.where((p) => p.id == capProvinceId).firstOrNull;
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
      _log.i(
          'logic: player ${player.id} lost capital and has no provinces in $regionId; capital cleared');
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
      _log.i(
          'logic: player ${player.id} capital reassigned to $newProvinceId after loss');
    } catch (e, st) {
      _log.w('logic: capital reassignment failed for ${player.id}',
          error: e, stackTrace: st);
    }
  }
  return game;
}

/// Apply Great Power fall rule after combat and capital reassignment.
///
/// For each Great Power:
/// - Determine whether they lost their original capital province during this combat step.
/// - If they have **no remaining port provinces**, all of their provinces transfer
///   to the owner of the original capital province and their fleets/units are disbanded.
Game _applyGreatPowerFall(
  Game state,
  Map<String, String?> previousCapitalByPlayer,
) {
  var game = state;

  // Province owner lookup.
  final provinceOwnerById = <String, String?>{
    for (final p in game.worldState.oldWorld.provinces) p.id: p.ownerId,
    for (final p in game.worldState.newWorld.provinces) p.id: p.ownerId,
  };

  // Map provinceId -> list of port keys for that province.
  final portsByProvince = <String, List<String>>{};
  game.worldState.portsByProvinceSeaboard.forEach((key, _) {
    // key format: fullProvinceId|seaZoneId
    final parts = key.split('|');
    if (parts.length >= 3) {
      final provinceId = '${parts[0]}|${parts[1]}';
      portsByProvince.putIfAbsent(provinceId, () => []).add(key);
    }
  });

  for (final player in game.players) {
    final playerId = player.id;
    final prevCapitalId = previousCapitalByPlayer[playerId];
    if (prevCapitalId == null || prevCapitalId.isEmpty) continue;

    final prevCapitalOwner = provinceOwnerById[prevCapitalId];
    // Player must have lost their original capital.
    if (prevCapitalOwner == null || prevCapitalOwner == playerId) {
      continue;
    }

    // Check if player still has any port provinces.
    var hasPortProvince = false;
    provinceOwnerById.forEach((provId, ownerId) {
      if (ownerId == playerId && portsByProvince.containsKey(provId)) {
        hasPortProvince = true;
      }
    });
    if (hasPortProvince) continue;

    final conquerorId = prevCapitalOwner;

    // Transfer all provinces owned by this GP to the conqueror and disband its units.
    RegionData _transferRegion(RegionData region) {
      final updatedProvinces = region.provinces
          .map((p) =>
              p.ownerId == playerId ? p.copyWith(ownerId: conquerorId) : p)
          .toList();
      final remainingUnits =
          region.units.where((u) => u.ownerId != playerId).toList();
      return RegionData(
        provinces: updatedProvinces,
        units: remainingUnits,
      );
    }

    final newOldWorld = _transferRegion(game.worldState.oldWorld);
    final newNewWorld = _transferRegion(game.worldState.newWorld);

    // Disband fleets owned by this GP.
    final remainingFleets = game.worldState.fleets
        .where((f) => f.ownerId != playerId)
        .toList();

    game = game.copyWith(
      worldState: game.worldState.copyWith(
        oldWorld: newOldWorld,
        newWorld: newNewWorld,
        fleets: remainingFleets,
      ),
      players: game.players
          .map((p) => p.id == playerId
              ? p.copyWith(capitalProvinceId: null, capitalTile: null)
              : p)
          .toList(),
    );
  }

  return game;
}
