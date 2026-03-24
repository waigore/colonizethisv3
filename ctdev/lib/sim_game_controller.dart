import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';

import 'ctdev_log.dart';

/// One order entry in the sim game order history (for UI display).
class SimOrderHistoryEntry {
  const SimOrderHistoryEntry({
    required this.turnNumber,
    required this.playerId,
    required this.playerName,
    required this.orderType,
    required this.summary,
    required this.status,
    this.reason,
  });

  final int turnNumber;
  final String playerId;
  final String playerName;
  final String orderType;
  final String summary;
  final OrderValidationStatus status;
  final String? reason;
}

/// Ensures every Great Power has an aiSeed so turnSeed[P, T] is well-defined (Option A).
Game _ensureAiSeedsForSim(Game game, int baseSeed) {
  final byGp = Map<String, int>.from(game.aiSeedByGpId);
  for (final p in game.players) {
    byGp.putIfAbsent(p.id, () => baseSeed);
  }
  return game.copyWith(aiSeedByGpId: byGp);
}

/// In sim game all GPs are AI-controlled; no human player.
Game _forceAllGpsAiControlled(Game game) {
  return game.copyWith(
    aiControlByGpId: {for (final p in game.players) p.id: true},
  );
}

/// In-memory controller for Sim Game mode used by ctdev.
class SimGameController {
  SimGameController({
    required Game initialGame,
    required MapTopology topology,
    required Map<String, TileMapResult> tileMapByRegion,
    required int baseSeed,
    this.useSimGameAi = true,
    this.useFullAI = false,
  })  : _game = _forceAllGpsAiControlled(
            _ensureAiSeedsForSim(initialGame, baseSeed)),
        _topology = topology,
        _tileMapByRegion = tileMapByRegion,
        _baseSeed = baseSeed {
    if (!useSimGameAi && useFullAI) {
      _game = assignHiddenAgendasForGame(_game);
    }
  }

  Game _game;
  final MapTopology _topology;
  final Map<String, TileMapResult> _tileMapByRegion;
  final int _baseSeed;

  /// When true, use Sim Game AI (defaultSimGameAi) for all GPs. When false, use AI Planner (minimal or full).
  final bool useSimGameAi;

  /// When true and useSimGameAi is false, use Phase 6 full AI (personalities, hidden agendas, naval orders). When false, use Phase 4 simple AI.
  final bool useFullAI;

  /// Base seed used for sim; also fallback for turnSeed when a GP has no aiSeed.
  int get baseSeed => _baseSeed;

  final Map<String, Orders> _pendingOrdersByPlayerId = {};
  /// When using full AI, economy plans per player for production phase. Cleared on resolve.
  final Map<String, EconomyPlan> _pendingEconomyPlansByPlayerId = {};
  final List<SimOrderHistoryEntry> _orderHistory = [];
  final List<String> _lastTurnCombatSummaries = [];

  Game get game => _game;
  Map<String, Orders> get pendingOrdersByPlayerId =>
      Map.unmodifiable(_pendingOrdersByPlayerId);
  MapTopology get topology => _topology;
  Map<String, TileMapResult> get tileMapByRegion => _tileMapByRegion;
  Map<String, MapTopology> get topologyByRegion => {
        'oldWorld': MapTopology(
          nodes:
              _topology.nodes.where((n) => n.regionId == 'oldWorld').toList(),
          edges: _topology.edges,
        ),
        'newWorld': MapTopology(
          nodes:
              _topology.nodes.where((n) => n.regionId == 'newWorld').toList(),
          edges: _topology.edges,
        ),
      };

  List<SimOrderHistoryEntry> get orderHistory =>
      List.unmodifiable(_orderHistory);

  /// Land + naval combat lines from the last resolved turn (Overview tab).
  List<String> get lastTurnCombatSummaries =>
      List.unmodifiable(_lastTurnCombatSummaries);

  /// True when at least one GP has non-empty pending orders (for projections).
  bool get hasPendingOrdersForProjection {
    for (final p in _game.players) {
      final o = _pendingOrdersByPlayerId[p.id];
      if (o != null && !_isOrdersEffectivelyEmpty(o)) return true;
    }
    return false;
  }

  /// Dry-run effects for [playerId] from merged pending orders; null if no pending.
  ProjectedEffects? projectedEffectsForPlayer(String playerId) {
    if (!hasPendingOrdersForProjection) return null;
    return projectOrderEffects(
      game: _game,
      orders: mergePendingOrdersForProjection(),
      topology: _topology,
      tileMapByRegion: _tileMapByRegion,
      playerId: playerId,
    );
  }

  /// Merges per-GP pending orders with empty [Orders] for GPs not yet filled.
  Orders mergePendingOrdersForProjection() {
    final list = <Orders>[
      for (final p in _game.players)
        _pendingOrdersByPlayerId[p.id] ?? const Orders(),
    ];
    return _combineOrders(list);
  }

  bool get allPlayersHaveOrders {
    final ids = _game.players.map((p) => p.id).toList();
    return ids.every(_pendingOrdersByPlayerId.containsKey);
  }

  /// Generates orders for the next Great Power that does not yet have orders
  /// for the current turn (player-by-player mode). All GPs use the selected AI.
  void generateOrdersForNextPlayer() {
    final currentTurn = _game.worldState.turnState.turnNumber;
    for (final player in _game.players) {
      if (_pendingOrdersByPlayerId.containsKey(player.id)) continue;
      if (useSimGameAi) {
        final orders = defaultSimGameAi(
          game: _game,
          player: player,
          topology: _topology,
          baseSeed: _baseSeed,
        );
        _pendingOrdersByPlayerId[player.id] = orders;
      } else if (useFullAI) {
        final result = generateOrdersForPlayerFullAI(_game, _topology, player.id);
        _pendingOrdersByPlayerId[player.id] = result.orders;
        _pendingEconomyPlansByPlayerId[player.id] = result.economyPlan;
      } else {
        final orders = generateOrdersForPlayer(_game, _topology, player.id);
        _pendingOrdersByPlayerId[player.id] = orders;
      }
      Logger().i(
        'ctdev: Turn $currentTurn: generated orders for ${player.displayName} (${player.id})',
      );
      break;
    }
  }

  /// Resolves one full turn from the currently accumulated per-player orders.
  void resolveFromPendingOrders() {
    if (!allPlayersHaveOrders) return;
    clearUiLog();
    final combined = _combineOrders(_pendingOrdersByPlayerId.values.toList());
    final defaultAssignmentsByPlayerId = _pendingEconomyPlansByPlayerId.isEmpty
        ? null
        : _pendingEconomyPlansByPlayerId.map(
            (pid, plan) => MapEntry(pid, plan.productionAssignments),
          );
    _pendingOrdersByPlayerId.clear();
    _pendingEconomyPlansByPlayerId.clear();
    _advanceOneTurnFromOrders(
      combined,
      defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
    );
  }

  /// Generates orders for all Great Powers and advances one full turn.
  /// All GPs use the selected AI (Sim Game AI or AI Planner).
  void stepFullTurn() {
    clearUiLog();
    if (useSimGameAi) {
      final ordersList = [
        for (final player in _game.players)
          defaultSimGameAi(
            game: _game,
            player: player,
            topology: _topology,
            baseSeed: _baseSeed,
          ),
      ];
      final combined = _combineOrders(ordersList);
      _pendingOrdersByPlayerId.clear();
      _advanceOneTurnFromOrders(combined);
    } else if (useFullAI) {
      final result = generateOrdersForGameFullAI(_game, _topology);
      final defaultAssignmentsByPlayerId = result.economyPlansByPlayerId.map(
        (pid, plan) => MapEntry(pid, plan.productionAssignments),
      );
      _pendingOrdersByPlayerId.clear();
      _advanceOneTurnFromOrders(
        result.orders,
        defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
      );
    } else {
      final combined = generateOrdersForGame(_game, _topology);
      _pendingOrdersByPlayerId.clear();
      _advanceOneTurnFromOrders(combined);
    }
  }

  /// Advances the game by [turns] full turns using the default AI.
  void fastForward({required int turns}) {
    for (var i = 0; i < turns; i++) {
      stepFullTurn();
    }
  }

  /// Resolves one turn from explicit [orders] (tests and scripted runs).
  @visibleForTesting
  void advanceTurnForTesting(Orders orders) {
    _advanceOneTurnFromOrders(orders);
  }

  Orders _combineOrders(List<Orders> all) {
    final moveByPlayer = <String, List<MoveOrder>>{};
    final buildByPlayer = <String, List<BuildUnitOrder>>{};
    final workByPlayer = <String, List<WorkOrder>>{};
    final diploByPlayer = <String, List<DiplomaticOrder>>{};
    final researchByPlayer = <String, List<ResearchOrder>>{};
    final navalByPlayer = <String, List<NavalMoveOrder>>{};
    final missionByPlayer = <String, List<NavalMissionOrder>>{};

    for (final o in all) {
      o.moveOrdersByPlayerId.forEach((pid, list) {
        moveByPlayer.putIfAbsent(pid, () => <MoveOrder>[]).addAll(list);
      });
      o.buildUnitOrdersByPlayerId.forEach((pid, list) {
        buildByPlayer.putIfAbsent(pid, () => <BuildUnitOrder>[]).addAll(list);
      });
      o.workOrdersByPlayerId.forEach((pid, list) {
        workByPlayer.putIfAbsent(pid, () => <WorkOrder>[]).addAll(list);
      });
      o.diplomaticOrdersByPlayerId.forEach((pid, list) {
        diploByPlayer.putIfAbsent(pid, () => <DiplomaticOrder>[]).addAll(list);
      });
      o.researchOrdersByPlayerId.forEach((pid, list) {
        researchByPlayer.putIfAbsent(pid, () => <ResearchOrder>[]).addAll(list);
      });
      o.navalMoveOrdersByPlayerId.forEach((pid, list) {
        navalByPlayer.putIfAbsent(pid, () => <NavalMoveOrder>[]).addAll(list);
      });
      o.navalMissionOrdersByPlayerId.forEach((pid, list) {
        missionByPlayer.putIfAbsent(pid, () => <NavalMissionOrder>[]).addAll(list);
      });
    }

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

  void _advanceOneTurnFromOrders(
    Orders orders, {
    Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  }) {
    _recordOrderHistory(orders);
    _lastTurnCombatSummaries.clear();
    final before = _game;
    final next = requireTurnResolutionComplete(validateOrdersAndResolveTurn(
      game: _game,
      topology: _topology,
      orders: orders,
      tileMapByRegion: _tileMapByRegion,
      defaultAssignments: const [],
      defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
      onGameEvent: _recordCombatGameEvent,
    ));
    _game = next;
    _recordTurnLog(before: before, after: next);
  }

  void _recordCombatGameEvent(GameEvent event) {
    final line = _combatEventUiLine(event);
    if (line == null) return;
    _lastTurnCombatSummaries.add(line);
    Logger().i('ctdev: $line');
  }

  bool _isOrdersEffectivelyEmpty(Orders o) =>
      o.moveOrdersByPlayerId.isEmpty &&
      o.buildUnitOrdersByPlayerId.isEmpty &&
      o.workOrdersByPlayerId.isEmpty &&
      o.diplomaticOrdersByPlayerId.isEmpty &&
      o.researchOrdersByPlayerId.isEmpty &&
      o.navalMoveOrdersByPlayerId.isEmpty &&
      o.navalMissionOrdersByPlayerId.isEmpty;

  void _recordOrderHistory(Orders orders) {
    if (orders.moveOrdersByPlayerId.isEmpty &&
        orders.buildUnitOrdersByPlayerId.isEmpty &&
        orders.workOrdersByPlayerId.isEmpty &&
        orders.diplomaticOrdersByPlayerId.isEmpty &&
        orders.researchOrdersByPlayerId.isEmpty &&
        orders.navalMoveOrdersByPlayerId.isEmpty &&
        orders.navalMissionOrdersByPlayerId.isEmpty) {
      return;
    }

    final currentTurn = _game.worldState.turnState.turnNumber;

    final unitsById = <String, Unit>{};
    for (final u in _game.worldState.oldWorld.units) {
      unitsById[u.id] = u;
    }
    for (final u in _game.worldState.newWorld.units) {
      unitsById[u.id] = u;
    }

    final provinceNamesByRegionAndId = <String, String>{};
    for (final p in _game.worldState.oldWorld.provinces) {
      provinceNamesByRegionAndId['${p.regionId}|${p.id}'] = p.displayName ?? p.id;
    }
    for (final p in _game.worldState.newWorld.provinces) {
      provinceNamesByRegionAndId['${p.regionId}|${p.id}'] = p.displayName ?? p.id;
    }
    String provinceLabelInRegion(String regionId, String id) =>
        provinceNamesByRegionAndId['$regionId|$id'] ?? id;

    for (final player in _game.players) {
      final playerId = player.id;
      final moves = orders.moveOrdersByPlayerId[playerId] ?? const [];
      final builds = orders.buildUnitOrdersByPlayerId[playerId] ?? const [];
      final works = orders.workOrdersByPlayerId[playerId] ?? const [];
      final diplo =
          orders.diplomaticOrdersByPlayerId[playerId] ?? const <DiplomaticOrder>[];
      final research =
          orders.researchOrdersByPlayerId[playerId] ?? const <ResearchOrder>[];
      final naval =
          orders.navalMoveOrdersByPlayerId[playerId] ?? const <NavalMoveOrder>[];
      final mission =
          orders.navalMissionOrdersByPlayerId[playerId] ?? const <NavalMissionOrder>[];

      if (moves.isEmpty &&
          builds.isEmpty &&
          works.isEmpty &&
          diplo.isEmpty &&
          research.isEmpty &&
          naval.isEmpty &&
          mission.isEmpty) {
        continue;
      }

      final engine = OrderEngine(
        initialOrders: Orders(
          moveOrdersByPlayerId:
              moves.isEmpty ? const {} : {playerId: List.of(moves)},
          buildUnitOrdersByPlayerId:
              builds.isEmpty ? const {} : {playerId: List.of(builds)},
          workOrdersByPlayerId:
              works.isEmpty ? const {} : {playerId: List.of(works)},
          diplomaticOrdersByPlayerId:
              diplo.isEmpty ? const {} : {playerId: List.of(diplo)},
          researchOrdersByPlayerId:
              research.isEmpty ? const {} : {playerId: List.of(research)},
          navalMoveOrdersByPlayerId:
              naval.isEmpty ? const {} : {playerId: List.of(naval)},
          navalMissionOrdersByPlayerId:
              mission.isEmpty ? const {} : {playerId: List.of(mission)},
        ),
      );

      final results =
          engine.validatePlayerOrdersWithContext(_game, _topology, playerId);
      var resultIndex = 0;

      OrderValidationResult nextResult() {
        if (resultIndex >= results.length) {
          return const OrderValidationResult(
            status: OrderValidationStatus.accepted,
          );
        }
        final r = results[resultIndex];
        resultIndex++;
        return r;
      }

      for (final o in moves) {
        final unit = unitsById[o.unitId];
        final unitLabel = unit != null
            ? '${unit.id} (${unit.type})'
            : o.unitId;
        final regionId = unit != null
            ? (Unit.regionIdFromTileKey(unit.tileKey) ?? 'oldWorld')
            : 'oldWorld';
        final origin = unit != null
            ? provinceLabelInRegion(regionId, unit.locationProvinceId)
            : '?';
        final dest = provinceLabelInRegion(regionId, o.destinationProvinceId);
        final validation = nextResult();
        _orderHistory.add(
          SimOrderHistoryEntry(
            turnNumber: currentTurn,
            playerId: playerId,
            playerName: player.displayName,
            orderType: 'move',
            summary: 'Move $unitLabel: $origin → $dest',
            status: validation.status,
            reason: validation.reason,
          ),
        );
      }

      for (final o in builds) {
        final location = provinceLabelInRegion('oldWorld', o.spawnProvinceId);
        final kind = o.isMilitary ? 'military' : 'civilian';
        final validation = nextResult();
        _orderHistory.add(
          SimOrderHistoryEntry(
            turnNumber: currentTurn,
            playerId: playerId,
            playerName: player.displayName,
            orderType: 'build',
            summary: 'Build ${o.unitType} ($kind) at $location',
            status: validation.status,
            reason: validation.reason,
          ),
        );
      }

      for (final o in works) {
        final unit = unitsById[o.unitId];
        final unitLabel = unit != null
            ? '${unit.id} (${unit.type})'
            : o.unitId;
        final unitRegion = unit != null
            ? (Unit.regionIdFromTileKey(unit.tileKey) ?? 'oldWorld')
            : 'oldWorld';
        final targetRegion = Unit.regionIdFromTileKey(o.targetTileKey) ?? unitRegion;
        final currentProvince = unit != null
            ? provinceLabelInRegion(unitRegion, unit.locationProvinceId)
            : '?';
        final targetProvince = provinceLabelInRegion(
            targetRegion, Unit.provinceIdFromTileKey(o.targetTileKey) ?? '');
        final currentTile = (unit != null && unit.tileKey != null && unit.tileKey!.isNotEmpty)
            ? formatTileKey(unit.tileKey!)
            : '?';
        final targetTile = o.targetTileKey.isNotEmpty ? formatTileKey(o.targetTileKey) : '?';
        final validation = nextResult();
        _orderHistory.add(
          SimOrderHistoryEntry(
            turnNumber: currentTurn,
            playerId: playerId,
            playerName: player.displayName,
            orderType: 'work',
            summary: 'Work $unitLabel at $currentTile ($currentProvince) → ${o.target} at $targetTile ($targetProvince)',
            status: validation.status,
            reason: validation.reason,
          ),
        );
      }

      for (final o in diplo) {
        final typeLabel = o.type.name;
        final target = o.targetFactionId;
        final extra = o.amount != null ? ' amount=${o.amount}' : '';
        final validation = nextResult();
        _orderHistory.add(
          SimOrderHistoryEntry(
            turnNumber: currentTurn,
            playerId: playerId,
            playerName: player.displayName,
            orderType: 'diplomatic',
            summary: 'Diplomacy $typeLabel → $target$extra',
            status: validation.status,
            reason: validation.reason,
          ),
        );
      }

      // Research is not part of [OrderEngine.validatePlayerOrdersWithContext] results;
      // resolution applies rules in the research phase. Log submissions for the Orders tab.
      for (final o in research) {
        final techLabel = o.techId.isEmpty
            ? 'cancel slot'
            : techDisplayName(o.techId);
        _orderHistory.add(
          SimOrderHistoryEntry(
            turnNumber: currentTurn,
            playerId: playerId,
            playerName: player.displayName,
            orderType: 'research',
            summary:
                'Research slot ${o.slotIndex}: $techLabel (${o.funding.name})',
            status: OrderValidationStatus.accepted,
            reason: null,
          ),
        );
      }

      for (final o in naval) {
        final dest = o.isDock
            ? 'dock ${o.destinationPortProvinceId}'
            : 'sea ${o.destinationSeaZoneId}';
        final validation = nextResult();
        _orderHistory.add(
          SimOrderHistoryEntry(
            turnNumber: currentTurn,
            playerId: playerId,
            playerName: player.displayName,
            orderType: 'naval_move',
            summary: 'Naval move fleet ${o.fleetId} → $dest',
            status: validation.status,
            reason: validation.reason,
          ),
        );
      }

      for (final o in mission) {
        final target = o.targetProvinceId ?? o.targetPortId ?? '—';
        final validation = nextResult();
        _orderHistory.add(
          SimOrderHistoryEntry(
            turnNumber: currentTurn,
            playerId: playerId,
            playerName: player.displayName,
            orderType: 'naval_mission',
            summary: 'Naval mission fleet ${o.fleetId}: ${o.mission} ($target)',
            status: validation.status,
            reason: validation.reason,
          ),
        );
      }
    }
  }

  void _recordTurnLog({required Game before, required Game after}) {
    final turn = after.worldState.turnState.turnNumber;
    final year = turnToYear(turn, after.turnTimeMapping);

    final beforeOwners = <String, String?>{};
    for (final p in before.worldState.oldWorld.provinces) {
      beforeOwners[p.id] = p.ownerId;
    }
    for (final p in before.worldState.newWorld.provinces) {
      beforeOwners[p.id] = p.ownerId;
    }

    final flips = <String>[];
    for (final p in after.worldState.oldWorld.provinces) {
      final prev = beforeOwners[p.id];
      if (prev != p.ownerId) {
        flips.add('${p.id}: ${prev ?? '—'} → ${p.ownerId ?? '—'}');
      }
    }
    for (final p in after.worldState.newWorld.provinces) {
      final prev = beforeOwners[p.id];
      if (prev != p.ownerId) {
        flips.add('${p.id}: ${prev ?? '—'} → ${p.ownerId ?? '—'}');
      }
    }

    if (flips.isEmpty) {
      Logger().i('ctdev: Turn $turn ($year): no province ownership changes');
    } else {
      Logger().i(
        'ctdev: Turn $turn ($year): province ownership changes: ${flips.join(', ')}',
      );
    }
  }
}

String? _combatEventUiLine(GameEvent event) {
  switch (event) {
    case CombatResultEvent(
        :final provinceId,
        :final attackerId,
        :final defenderId,
        :final winnerId,
        :final casualties,
      ):
      final cas = casualties.isEmpty ? '' : ' casualties=$casualties';
      return 'Land combat $provinceId: $attackerId vs $defenderId → '
          '$winnerId$cas';
    case NavalCombatResultEvent(
        :final seaZoneId,
        :final side1OwnerId,
        :final side2OwnerId,
        :final outcomeName,
        :final winnerOwnerId,
        :final side1Retreated,
        :final side2Retreated,
      ):
      final w = winnerOwnerId != null ? ' winner=$winnerOwnerId' : '';
      final r = (side1Retreated || side2Retreated)
          ? ' retreat=${[
              if (side1Retreated) 'side1',
              if (side2Retreated) 'side2',
            ].join(',')}'
          : '';
      return 'Naval combat sea $seaZoneId: $side1OwnerId vs '
          '$side2OwnerId → $outcomeName$w$r';
    default:
      return null;
  }
}
