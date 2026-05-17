import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/ai/ai_planner.dart'
    show generateOrdersForGame, generateOrdersForPlayer;
import 'package:colonizethis_logic/src/ai/sim_game_ai.dart'
    show defaultSimGameAi;
import 'package:colonizethis_logic/src/setup/hidden_agenda_assignment.dart'
    show assignHiddenAgendasForGame;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:ctdev/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:meta/meta.dart';

import 'ctdev_log.dart';

final _ctdevSimLog = packageLogger();

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
    this.turnTraceEnabled = false,
    this.turnTraceRootDirectory = 'tmp',
  }) : _game = _forceAllGpsAiControlled(
         _ensureAiSeedsForSim(initialGame, baseSeed),
       ),
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
  final bool turnTraceEnabled;
  final String turnTraceRootDirectory;

  /// Base seed used for sim; also fallback for turnSeed when a GP has no aiSeed.
  int get baseSeed => _baseSeed;

  final Map<String, Orders> _pendingOrdersByPlayerId = {};

  /// When using full AI, economy plans per player for production phase. Cleared on resolve.
  final Map<String, EconomyPlan> _pendingEconomyPlansByPlayerId = {};
  final Map<String, TurnTraceAiSection> _pendingAiTraceSectionsByPlayerId = {};
  final List<SimOrderHistoryEntry> _orderHistory = [];
  final List<String> _lastTurnCombatSummaries = [];

  Game get game => _game;
  Map<String, Orders> get pendingOrdersByPlayerId =>
      Map.unmodifiable(_pendingOrdersByPlayerId);
  MapTopology get topology => _topology;
  Map<String, TileMapResult> get tileMapByRegion => _tileMapByRegion;
  Map<String, MapTopology> get topologyByRegion => {
    'oldWorld': MapTopology(
      nodes: _topology.nodes.where((n) => n.regionId == 'oldWorld').toList(),
      edges: _topology.edges,
    ),
    'newWorld': MapTopology(
      nodes: _topology.nodes.where((n) => n.regionId == 'newWorld').toList(),
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
    if (_campaignTerminal) return;
    final nextPlayer = _nextPlayerWithoutPendingOrders();
    if (nextPlayer == null) return;

    final currentTurn = _game.worldState.turnState.turnNumber;
    if (useSimGameAi) {
      final orders = defaultSimGameAi(
        game: _game,
        player: nextPlayer,
        topology: _topology,
        baseSeed: _baseSeed,
        tileMapByRegion: _tileMapByRegion,
      );
      _pendingOrdersByPlayerId[nextPlayer.id] = orders;
    } else if (useFullAI) {
      final result = generateOrdersForPlayerFullAIWithTrace(
        _game,
        _topology,
        nextPlayer.id,
        tileMapByRegion: _tileMapByRegion,
      );
      _pendingOrdersByPlayerId[nextPlayer.id] = result.result.orders;
      _pendingEconomyPlansByPlayerId[nextPlayer.id] = result.result.economyPlan;
      final aiTraceSection = result.aiTraceSection;
      if (aiTraceSection != null) {
        _pendingAiTraceSectionsByPlayerId[nextPlayer.id] = aiTraceSection;
      }
    } else {
      final orders = generateOrdersForPlayer(
        _game,
        _topology,
        nextPlayer.id,
        tileMapByRegion: _tileMapByRegion,
      );
      _pendingOrdersByPlayerId[nextPlayer.id] = orders;
    }
    _ctdevSimLog.i(
      'Turn $currentTurn: generated orders for ${nextPlayer.displayName} (${nextPlayer.id})',
    );
  }

  Player? _nextPlayerWithoutPendingOrders() {
    for (final player in _game.players) {
      if (!_pendingOrdersByPlayerId.containsKey(player.id)) {
        return player;
      }
    }
    return null;
  }

  bool get _campaignTerminal =>
      _game.victory != null || _game.calendarCampaignHalted;

  /// Resolves one full turn from the currently accumulated per-player orders.
  void resolveFromPendingOrders() {
    if (!allPlayersHaveOrders) return;
    if (_campaignTerminal) {
      _pendingOrdersByPlayerId.clear();
      _pendingEconomyPlansByPlayerId.clear();
      _pendingAiTraceSectionsByPlayerId.clear();
      return;
    }
    clearUiLog();
    final combined = _combineOrders(_pendingOrdersByPlayerId.values.toList());
    final defaultAssignmentsByPlayerId = _pendingEconomyPlansByPlayerId.isEmpty
        ? null
        : _pendingEconomyPlansByPlayerId.map(
            (pid, plan) => MapEntry(pid, plan.productionAssignments),
          );
    _pendingOrdersByPlayerId.clear();
    _pendingEconomyPlansByPlayerId.clear();
    final aiTraceSections = _pendingAiTraceSectionsByPlayerId.values.toList(
      growable: false,
    );
    _pendingAiTraceSectionsByPlayerId.clear();
    _advanceOneTurnFromOrders(
      combined,
      defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
      aiTraceSections: aiTraceSections,
    );
  }

  /// Generates orders for all Great Powers and advances one full turn.
  /// All GPs use the selected AI (Sim Game AI or AI Planner).
  void stepFullTurn() {
    if (_campaignTerminal) return;
    clearUiLog();
    if (useSimGameAi) {
      final ordersList = [
        for (final player in _game.players)
          defaultSimGameAi(
            game: _game,
            player: player,
            topology: _topology,
            baseSeed: _baseSeed,
            tileMapByRegion: _tileMapByRegion,
          ),
      ];
      final combined = _combineOrders(ordersList);
      _pendingOrdersByPlayerId.clear();
      _advanceOneTurnFromOrders(combined);
    } else if (useFullAI) {
      final result = generateOrdersForGameFullAI(
        _game,
        _topology,
        tileMapByRegion: _tileMapByRegion,
      );
      final defaultAssignmentsByPlayerId = result.economyPlansByPlayerId.map(
        (pid, plan) => MapEntry(pid, plan.productionAssignments),
      );
      _game = result.game;
      _pendingOrdersByPlayerId.clear();
      _advanceOneTurnFromOrders(
        result.orders,
        defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
        aiTraceSections: result.aiTraceSections,
      );
    } else {
      final combined = generateOrdersForGame(
        _game,
        _topology,
        tileMapByRegion: _tileMapByRegion,
      );
      _pendingOrdersByPlayerId.clear();
      _advanceOneTurnFromOrders(combined);
    }
  }

  /// Advances the game by [turns] full turns using the default AI.
  void fastForward({required int turns}) {
    for (var i = 0; i < turns; i++) {
      if (_campaignTerminal) break;
      stepFullTurn();
    }
  }

  /// Resolves one turn from explicit [orders] (tests and scripted runs).
  @visibleForTesting
  void advanceTurnForTesting(Orders orders) {
    if (_campaignTerminal) return;
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
        missionByPlayer
            .putIfAbsent(pid, () => <NavalMissionOrder>[])
            .addAll(list);
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
    List<TurnTraceAiSection>? aiTraceSections,
  }) {
    _recordOrderHistory(orders);
    _lastTurnCombatSummaries.clear();
    final before = _game;
    final phaseTraces = <TurnTracePhaseTrace>[];
    final traceRuntime = turnTraceEnabled ? TurnTraceRuntime() : null;
    final next = requireTurnResolutionComplete(
      validateOrdersAndResolveTurn(
        game: _game,
        topology: _topology,
        orders: orders,
        tileMapByRegion: _tileMapByRegion,
        defaultAssignments: const [],
        defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
        onGameEvent: _recordCombatGameEvent,
        onTurnTracePhase: turnTraceEnabled ? phaseTraces.add : null,
        turnTraceRuntime: traceRuntime,
      ),
    );
    _game = next;
    if (turnTraceEnabled) {
      _exportTurnTrace(
        before: before,
        after: next,
        phases: phaseTraces,
        orders: orders,
        aiTraceSections: aiTraceSections,
      );
    }
    _recordTurnLog(before: before, after: next);
  }

  void _exportTurnTrace({
    required Game before,
    required Game after,
    required List<TurnTracePhaseTrace> phases,
    required Orders orders,
    List<TurnTraceAiSection>? aiTraceSections,
  }) {
    final now = DateTime.now().toUtc();
    final document = TurnTraceMergedDocument(
      schemaVersion: kTurnTraceSchemaVersionV1,
      meta: TurnTraceMeta(
        gameId: before.id,
        turnNumber: before.worldState.turnState.turnNumber,
        traceEnabled: true,
        source: 'ctdev',
        exportedAt: now.toIso8601String(),
        turnEndAt: now.toIso8601String(),
      ),
      ai:
          aiTraceSections ??
          _buildAiTraceSections(before: before, orders: orders),
      turnResolution: TurnTraceResolutionSection(
        phases: List<TurnTracePhaseTrace>.unmodifiable(phases),
      ),
    );
    TurnTraceFileExporter(
      rootDirectory: turnTraceRootDirectory,
      pruningEnabled: false,
    )
        .export(document)
        .then((file) {
          _ctdevSimLog.d(
            'logic: turn_trace_exported gameId=${before.id} '
            'turn=${before.worldState.turnState.turnNumber} '
            'nextTurn=${after.worldState.turnState.turnNumber} '
            'path=${file.path}',
          );
        })
        .catchError((Object error, StackTrace stackTrace) {
          _ctdevSimLog.e(
            'logic: turn_trace_export_failed gameId=${before.id}',
            error: error,
            stackTrace: stackTrace,
          );
        });
  }

  List<TurnTraceAiSection> _buildAiTraceSections({
    required Game before,
    required Orders orders,
  }) {
    final aiPlayers = before.players
        .where((player) => before.aiControlByGpId[player.id] ?? false)
        .toList(growable: false);
    if (aiPlayers.isEmpty) {
      return const <TurnTraceAiSection>[];
    }
    final sections = <TurnTraceAiSection>[];
    for (final player in aiPlayers) {
      final ordersByDomain = _orderCountsByDomain(player.id, orders);
      final finalOrders = _finalAggregatedOrders(player.id, orders);
      sections.add(
        TurnTraceAiSection(
          factionId: player.id,
          state: <String, Object?>{
            'winningCandidate': <String, Object?>{
              'selection': 'submitted_orders',
              'orderCount': finalOrders.length,
            },
            'topAlternates': const <Object?>[],
            'aggregates': <String, Object?>{
              'totalOrders': finalOrders.length,
              'ordersByDomain': ordersByDomain,
            },
            'decisionContext': <String, Object?>{
              'turnNumber': before.worldState.turnState.turnNumber,
            },
          },
          thresholds: const <String, Object?>{
            'constants': <String, Object?>{},
            'derived': <String, Object?>{},
            'effective': <String, Object?>{},
            'gates': <Object?>[],
          },
          outcome: <String, Object?>{
            'domainOutputs': ordersByDomain,
            'finalAggregatedOrders': finalOrders,
            'emittedOrderCount': finalOrders.length,
          },
        ),
      );
    }
    return List<TurnTraceAiSection>.unmodifiable(sections);
  }

  Map<String, Object?> _orderCountsByDomain(String playerId, Orders orders) {
    return <String, Object?>{
      'move':
          (orders.moveOrdersByPlayerId[playerId] ?? const <MoveOrder>[]).length,
      'armyMove':
          (orders.armyMoveOrdersByPlayerId[playerId] ?? const <ArmyMoveOrder>[])
              .length,
      'build':
          (orders.buildUnitOrdersByPlayerId[playerId] ??
                  const <BuildUnitOrder>[])
              .length,
      'work':
          (orders.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[]).length,
      'diplomatic':
          (orders.diplomaticOrdersByPlayerId[playerId] ??
                  const <DiplomaticOrder>[])
              .length,
      'research':
          (orders.researchOrdersByPlayerId[playerId] ?? const <ResearchOrder>[])
              .length,
      'navalMove':
          (orders.navalMoveOrdersByPlayerId[playerId] ??
                  const <NavalMoveOrder>[])
              .length,
      'navalMission':
          (orders.navalMissionOrdersByPlayerId[playerId] ??
                  const <NavalMissionOrder>[])
              .length,
    };
  }

  List<Map<String, Object?>> _finalAggregatedOrders(
    String playerId,
    Orders orders,
  ) {
    final aggregated = <Map<String, Object?>>[];
    for (final order
        in orders.moveOrdersByPlayerId[playerId] ?? const <MoveOrder>[]) {
      aggregated.add(<String, Object?>{
        'domain': 'move',
        'unitId': order.unitId,
        'destinationTileKey': order.destinationTileKey,
      });
    }
    for (final order
        in orders.armyMoveOrdersByPlayerId[playerId] ??
            const <ArmyMoveOrder>[]) {
      aggregated.add(<String, Object?>{
        'domain': 'armyMove',
        'armyId': order.armyId,
        'destinationProvinceId': order.destinationProvinceId,
      });
    }
    for (final order
        in orders.buildUnitOrdersByPlayerId[playerId] ??
            const <BuildUnitOrder>[]) {
      aggregated.add(<String, Object?>{
        'domain': 'build',
        'unitType': order.unitType,
        'spawnProvinceId': order.spawnProvinceId,
      });
    }
    for (final order
        in orders.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[]) {
      aggregated.add(<String, Object?>{
        'domain': 'work',
        'unitId': order.unitId,
        'targetTileKey': order.targetTileKey,
        'target': order.target,
      });
    }
    for (final order
        in orders.diplomaticOrdersByPlayerId[playerId] ??
            const <DiplomaticOrder>[]) {
      aggregated.add(<String, Object?>{
        'domain': 'diplomatic',
        'type': order.type.name,
        'targetFactionId': order.targetFactionId,
        if (order.amount != null) 'amount': order.amount,
      });
    }
    for (final order
        in orders.researchOrdersByPlayerId[playerId] ??
            const <ResearchOrder>[]) {
      aggregated.add(<String, Object?>{
        'domain': 'research',
        'slotIndex': order.slotIndex,
        'techId': order.techId,
        'funding': order.funding.name,
      });
    }
    for (final order
        in orders.navalMoveOrdersByPlayerId[playerId] ??
            const <NavalMoveOrder>[]) {
      aggregated.add(<String, Object?>{
        'domain': 'navalMove',
        'fleetId': order.fleetId,
        'isDock': order.isDock,
        'destinationSeaZoneId': order.destinationSeaZoneId,
        'destinationPortProvinceId': order.destinationPortProvinceId,
      });
    }
    for (final order
        in orders.navalMissionOrdersByPlayerId[playerId] ??
            const <NavalMissionOrder>[]) {
      aggregated.add(<String, Object?>{
        'domain': 'navalMission',
        'fleetId': order.fleetId,
        'mission': order.mission,
        'targetProvinceId': order.targetProvinceId,
        'targetPortId': order.targetPortId,
      });
    }
    return List<Map<String, Object?>>.unmodifiable(aggregated);
  }

  void _recordCombatGameEvent(GameEvent event) {
    final line = _combatEventUiLine(event);
    if (line == null) return;
    _lastTurnCombatSummaries.add(line);
    _ctdevSimLog.i(line);
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
      provinceNamesByRegionAndId['${p.regionId}|${p.id}'] =
          p.displayName ?? p.id;
    }
    for (final p in _game.worldState.newWorld.provinces) {
      provinceNamesByRegionAndId['${p.regionId}|${p.id}'] =
          p.displayName ?? p.id;
    }
    String provinceLabelInRegion(String regionId, String id) =>
        provinceNamesByRegionAndId['$regionId|$id'] ?? id;

    for (final player in _game.players) {
      final playerId = player.id;
      final moves = orders.moveOrdersByPlayerId[playerId] ?? const [];
      final builds = orders.buildUnitOrdersByPlayerId[playerId] ?? const [];
      final works = orders.workOrdersByPlayerId[playerId] ?? const [];
      final diplo =
          orders.diplomaticOrdersByPlayerId[playerId] ??
          const <DiplomaticOrder>[];
      final research =
          orders.researchOrdersByPlayerId[playerId] ?? const <ResearchOrder>[];
      final naval =
          orders.navalMoveOrdersByPlayerId[playerId] ??
          const <NavalMoveOrder>[];
      final mission =
          orders.navalMissionOrdersByPlayerId[playerId] ??
          const <NavalMissionOrder>[];

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
          moveOrdersByPlayerId: moves.isEmpty
              ? const {}
              : {playerId: List.of(moves)},
          buildUnitOrdersByPlayerId: builds.isEmpty
              ? const {}
              : {playerId: List.of(builds)},
          workOrdersByPlayerId: works.isEmpty
              ? const {}
              : {playerId: List.of(works)},
          diplomaticOrdersByPlayerId: diplo.isEmpty
              ? const {}
              : {playerId: List.of(diplo)},
          researchOrdersByPlayerId: research.isEmpty
              ? const {}
              : {playerId: List.of(research)},
          navalMoveOrdersByPlayerId: naval.isEmpty
              ? const {}
              : {playerId: List.of(naval)},
          navalMissionOrdersByPlayerId: mission.isEmpty
              ? const {}
              : {playerId: List.of(mission)},
        ),
      );

      final results = engine.validatePlayerOrdersWithContext(
        _game,
        _topology,
        playerId,
      );
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
        final unitLabel = unit != null ? '${unit.id} (${unit.type})' : o.unitId;
        final regionId = unit != null
            ? (Unit.regionIdFromTileKey(unit.tileKey) ?? 'oldWorld')
            : 'oldWorld';
        final origin = unit != null
            ? provinceLabelInRegion(regionId, unit.locationProvinceId)
            : '?';
        final destTile = o.destinationTileKey;
        final destRegion = Unit.regionIdFromTileKey(destTile) ?? regionId;
        final destProv = Unit.provinceIdFromTileKey(destTile);
        final dest = destProv != null
            ? provinceLabelInRegion(destRegion, destProv)
            : destTile;
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
        final unitLabel = unit != null ? '${unit.id} (${unit.type})' : o.unitId;
        final unitRegion = unit != null
            ? (Unit.regionIdFromTileKey(unit.tileKey) ?? 'oldWorld')
            : 'oldWorld';
        final targetRegion =
            Unit.regionIdFromTileKey(o.targetTileKey) ?? unitRegion;
        final currentProvince = unit != null
            ? provinceLabelInRegion(unitRegion, unit.locationProvinceId)
            : '?';
        final targetProvince = provinceLabelInRegion(
          targetRegion,
          Unit.provinceIdFromTileKey(o.targetTileKey) ?? '',
        );
        final currentTile =
            (unit != null && unit.tileKey != null && unit.tileKey!.isNotEmpty)
            ? formatTileKey(unit.tileKey!)
            : '?';
        final targetTile = o.targetTileKey.isNotEmpty
            ? formatTileKey(o.targetTileKey)
            : '?';
        final validation = nextResult();
        _orderHistory.add(
          SimOrderHistoryEntry(
            turnNumber: currentTurn,
            playerId: playerId,
            playerName: player.displayName,
            orderType: 'work',
            summary:
                'Work $unitLabel at $currentTile ($currentProvince) → ${o.target} at $targetTile ($targetProvince)',
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
      _ctdevSimLog.i('Turn $turn ($year): no province ownership changes');
    } else {
      _ctdevSimLog.i(
        'Turn $turn ($year): province ownership changes: ${flips.join(', ')}',
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
          ? ' retreat=${[if (side1Retreated) 'side1', if (side2Retreated) 'side2'].join(',')}'
          : '';
      return 'Naval combat sea $seaZoneId: $side1OwnerId vs '
          '$side2OwnerId → $outcomeName$w$r';
    default:
      return null;
  }
}
