import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'combat_mode_selection.dart';
import 'order_engine.dart';
import 'order_merge.dart';
import 'combat_resolver.dart';
import 'conflict_detection.dart';
import 'quick_battle_input_builder.dart';
import 'quick_battle_resolver.dart';
import 'connectivity_resolver.dart';
import 'economy_consumption.dart';
import 'economy_extraction.dart';
import 'economy_production.dart';
import 'economy_riches_to_treasury.dart';
import 'diplomacy_resolver.dart';
import 'minor_military_parity.dart';
import 'movement.dart';
import 'orders_application.dart';
import 'resource_extractor.dart';
import 'sea_transport.dart';
import 'research_resolver.dart';

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
}) {
  final merged = mergeOrderLists(
    humanOrders: orderEngine.orders,
    aiOrders: aiOrders,
  );
  return validateOrdersAndResolveTurn(
    game: game,
    topology: topology,
    orders: merged,
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
}) {
  final engine = OrderEngine(initialOrders: orders);
  final filtered = _filterAcceptedOrdersForAllPlayers(
    engine: engine,
    game: game,
    topology: topology,
  );
  return resolveTurnForGame(
    game: game,
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
}) {
  Game state = game;
  final feedingCoverageByPlayerId = <String, double>{};

  for (final phase in turnResolutionSequence) {
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
        state = resolveDiplomacyPhase(state, orders);
        break;
      case TurnPhase.movement:
        state = _runMovementPhase(state, topology, orders);
        break;
      case TurnPhase.combat:
        state = _runCombatPhase(state, orders, feedingCoverageByPlayerId);
        break;
      case TurnPhase.buildWork:
        state = applyBuildAndWorkOrders(state, orders);
        break;
      case TurnPhase.endOfTurn:
        state = _runEndOfTurnPhase(state);
        break;
    }
  }

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

  return Orders(
    moveOrdersByPlayerId: moveByPlayer,
    buildUnitOrdersByPlayerId: buildByPlayer,
    workOrdersByPlayerId: workByPlayer,
    diplomaticOrdersByPlayerId: diploByPlayer,
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

  // Advance turn number; visibility updates from exploration/prospection and
  // fog-of-war can be handled in dedicated resolvers in future phases.
  return game.copyWith(
    worldState: game.worldState.copyWith(
      turnState: game.worldState.turnState.copyWith(
        turnNumber: game.worldState.turnState.turnNumber + 1,
        phase: TurnPhase.orders,
      ),
    ),
  );
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
      final player = state.players.cast<Player?>().firstWhere(
            (p) => p?.id == playerId,
            orElse: () => null,
          );
      return extractionCapForUnlocked(player?.techUnlocked);
    },
  );
  final updatedPlayers = <Player>[];
  for (final player in state.players) {
    var stockpile = player.stockpile;
    final tot = extraction[player.id];
    if (tot != null) {
      stockpile = applyExtractionToStockpile(stockpile, tot.land);
      final overseasDelivered = allocateOverseasToStockpile(
        tot.overseas,
        cargoHolds: defaultCargoHoldsStub,
      );
      stockpile = applyExtractionToStockpile(stockpile, overseasDelivered);
    }
    updatedPlayers.add(player.copyWith(stockpile: stockpile));
  }
  return state.copyWith(players: updatedPlayers);
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
  final moveOrders = orders.moveOrdersByPlayerId;
  if (moveOrders.isEmpty) return game;

  final oldWorld = applyMoveOrdersToRegion(
    game.worldState.oldWorld,
    topology,
    moveOrders,
  );

  // In Phase 2, New World uses same adjacency rules; reuse the same topology.
  final newWorld = applyMoveOrdersToRegion(
    game.worldState.newWorld,
    topology,
    moveOrders,
  );

  return game.copyWith(
    worldState: game.worldState.copyWith(
      oldWorld: oldWorld,
      newWorld: newWorld,
    ),
  );
}

Game _runCombatPhase(
  Game game,
  Orders orders,
  Map<String, double> feedingCoverageByPlayerId,
) {
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
  return state;
}
