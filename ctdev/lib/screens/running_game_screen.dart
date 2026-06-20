import 'dart:math' as math;

import 'package:colonizethis_ai_contracts/src/ai/simple_ai_heuristics.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:ctdev/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../ct_debug_console.dart';
import '../ctdev_log.dart';
import '../debug_map_painter.dart';
import '../player_view_map_painter.dart';
import '../sim_game_controller.dart';

final _runningGameLog = packageLogger('running_game');

/// Running Game Screen: sim game with control bar and tabs.
class RunningGameScreen extends StatefulWidget {
  const RunningGameScreen({
    super.key,
    required this.sessionId,
    required this.initResult,
    required this.baseSeed,
    this.useSimGameAi = true,
    this.useFullAI = false,
  });

  final String sessionId;
  final InitGameResult initResult;
  final int baseSeed;
  final bool useSimGameAi;
  final bool useFullAI;

  @override
  State<RunningGameScreen> createState() => _RunningGameScreenState();
}

class _RunningGameScreenState extends State<RunningGameScreen>
    with SingleTickerProviderStateMixin {
  late SimGameController _controller;
  late TabController _tabController;
  bool _isSimulatingBatch = false;
  late InitGameMapViewData _viewData;

  bool _showOwnership = true;
  bool _showCapitals = true;
  bool _showPorts = true;
  bool _geographicMode = false;
  bool _showImprovements = false;
  bool _showUnits = false;

  /// When set, victory overlay is hidden (View final state); game.victory still set.
  int? _dismissedVictoryTurnNumber;

  @override
  void initState() {
    super.initState();
    _controller = SimGameController(
      initialGame: widget.initResult.game,
      topology: widget.initResult.combinedTopology,
      tileMapByRegion: widget.initResult.tileMapByRegion,
      baseSeed: widget.baseSeed,
      useSimGameAi: widget.useSimGameAi,
      useFullAI: widget.useFullAI,
      turnTraceEnabled: kCtDebugConsoleEnabled,
    );
    _viewData = buildInitGameMapViewData(
      game: _controller.game,
      tileMapByRegion: _controller.tileMapByRegion,
      topologyByRegion: _controller.topologyByRegion,
      cellSize: 24,
      seed: widget.baseSeed,
      configSummary: widget.initResult.mapViewData.configSummary,
      greatPowerColorOverride: widget.initResult.greatPowerColorOverride,
      warpLinks: widget.initResult.warpLinks,
    );
    final tabCount = 3 + _controller.game.players.length;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  InitGameMapViewData get _currentViewData => buildInitGameMapViewData(
        game: _controller.game,
        tileMapByRegion: _controller.tileMapByRegion,
        topologyByRegion: _controller.topologyByRegion,
        cellSize: _viewData.oldWorld.cellSize,
        seed: _viewData.seed,
        configSummary: _viewData.configSummary,
        greatPowerColorOverride: widget.initResult.greatPowerColorOverride,
        warpLinks: widget.initResult.warpLinks,
      );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _viewData = _currentViewData;
    });
  }

  Future<void> _stepNextPlayer() async {
    if (_isSimulatingBatch) return;
    setState(() => _controller.generateOrdersForNextPlayer());
  }

  Future<void> _resolvePendingTurn() async {
    if (_isSimulatingBatch || !_controller.allPlayersHaveOrders) return;
    setState(() => _isSimulatingBatch = true);
    try {
      _controller.resolveFromPendingOrders();
      _refresh();
    } catch (e, st) {
      _runningGameLog.e('resolve turn failed', error: e, stackTrace: st);
      rethrow;
    } finally {
      if (mounted) setState(() => _isSimulatingBatch = false);
    }
  }

  Future<void> _stepFullTurn() async {
    if (_isSimulatingBatch) return;
    setState(() => _isSimulatingBatch = true);
    try {
      _controller.stepFullTurn();
      _refresh();
    } catch (e, st) {
      _runningGameLog.e('step full turn failed', error: e, stackTrace: st);
      rethrow;
    } finally {
      if (mounted) setState(() => _isSimulatingBatch = false);
    }
  }

  Future<void> _fastForwardTen() async {
    if (_isSimulatingBatch) return;
    setState(() => _isSimulatingBatch = true);
    try {
      _controller.fastForward(turns: 10);
      _refresh();
    } catch (e, st) {
      _runningGameLog.e('fast-forward failed', error: e, stackTrace: st);
      rethrow;
    } finally {
      if (mounted) setState(() => _isSimulatingBatch = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = _controller.game;
    final victory = game.victory;
    final tabs = <Tab>[
      const Tab(text: 'Map'),
      const Tab(text: 'Overview'),
      const Tab(text: 'Orders'),
      ...game.players.map((p) => Tab(text: p.displayName)),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Running Game'),
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs,
          isScrollable: true,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text('Session: ${widget.sessionId}', style: Theme.of(context).textTheme.bodySmall),
                    Text('Log: ${sessionLogPath ?? "—"}', style: Theme.of(context).textTheme.bodySmall),
                    ElevatedButton(
                      onPressed: _isSimulatingBatch ? null : _stepNextPlayer,
                      child: const Text('Next Player'),
                    ),
                    ElevatedButton(
                      onPressed: _isSimulatingBatch ||
                              !_controller.allPlayersHaveOrders
                          ? null
                          : _resolvePendingTurn,
                      child: const Text('Resolve Turn'),
                    ),
                    ElevatedButton(
                      onPressed: _isSimulatingBatch ? null : _stepFullTurn,
                      child: const Text('Next Turn'),
                    ),
                    ElevatedButton(
                      onPressed: _isSimulatingBatch ? null : _fastForwardTen,
                      child: const Text('Fast-forward 10'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMapTab(),
                    _buildGameOverviewTab(),
                    _buildOrdersTab(),
                    ...game.players.map(_buildPlayerTab),
                  ],
                ),
              ),
            ],
          ),
          if (victory != null && _dismissedVictoryTurnNumber != victory.turnNumber)
            _buildVictoryOverlay(context, victory),
        ],
      ),
    );
  }

  Widget _buildVictoryOverlay(BuildContext context, VictoryState victory) {
    final winner = _controller.game.players
        .where((p) => p.id == victory.winnerPlayerId)
        .firstOrNull;
    final winnerName = winner?.displayName ?? victory.winnerPlayerId;
    return Material(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Victory!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text('Winner: $winnerName'),
                Text('Type: ${victory.type.name}'),
                Text('Turn: ${victory.turnNumber}'),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                      child: const Text('Return to main menu'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _dismissedVictoryTurnNumber = victory.turnNumber;
                        });
                      },
                      child: const Text('View final state'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapTab() {
    final ow = _viewData.oldWorld;
    final nw = _viewData.newWorld;
    final viewCellSize = ow.cellSize.toDouble() * kDebugMapScale;
    final gap = viewCellSize * 2;
    final totalWidth =
        ow.width * viewCellSize + gap + nw.width * viewCellSize;
    final totalHeight = math.max(
      ow.height * viewCellSize,
      nw.height * viewCellSize,
    );
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            children: [
              _SwitchRow('Geographic', _geographicMode, (v) => setState(() => _geographicMode = v)),
              _CheckRow('Ownership', _showOwnership, _geographicMode ? null : (v) => setState(() => _showOwnership = v ?? true)),
              _CheckRow('Capitals', _showCapitals, (v) => setState(() => _showCapitals = v ?? true)),
              _CheckRow('Ports', _showPorts, (v) => setState(() => _showPorts = v ?? true)),
              _CheckRow('Improvements', _showImprovements, (v) => setState(() => _showImprovements = v ?? true)),
              _CheckRow('Units', _showUnits, (v) => setState(() => _showUnits = v ?? true)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: totalWidth,
            height: totalHeight,
            child: InteractiveViewer(
              minScale: 0.25,
              maxScale: 4.0,
              child: CustomPaint(
                size: Size(totalWidth, totalHeight),
                painter: CombinedMapPainter(
                  viewData: _viewData,
                  showOwnership: _showOwnership,
                  showCapitals: _showCapitals,
                  showPorts: _showPorts,
                  geographicMode: _geographicMode,
                  showImprovements: _showImprovements,
                  showUnits: _showUnits,
                  fleets: _controller.game.worldState.fleets,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverviewTab() {
    final game = _controller.game;
    final turn = game.worldState.turnState.turnNumber;
    final year = turnToYear(turn, game.turnTimeMapping);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Turn $turn ($year)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          const Text('Turn seed (monitored)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...game.players.map((p) {
            final seed = turnSeedForPlayer(
              game,
              p.id,
              turn,
              fallbackAiSeed: _controller.baseSeed,
            );
            return Text('${p.displayName} (${p.id}): $seed');
          }),
          const SizedBox(height: 16),
          const Text('Provinces', style: TextStyle(fontWeight: FontWeight.bold)),
          ...game.players.map((p) {
            final ow = game.worldState.oldWorld.provinces.where((pr) => pr.ownerId == p.id);
            final nw = game.worldState.newWorld.provinces.where((pr) => pr.ownerId == p.id);
            final names = [
              ...ow.map((pr) => pr.displayName ?? pr.id),
              ...nw.map((pr) => pr.displayName ?? pr.id),
            ];
            return Text('${p.displayName}: ${names.join(', ')}');
          }),
          const SizedBox(height: 16),
          const Text('Military strength', style: TextStyle(fontWeight: FontWeight.bold)),
          ...game.players.map((p) {
            final str = aggregateMilitaryStrengthForPlayer(game, p.id);
            return Text('${p.displayName}: ${str.toStringAsFixed(1)}');
          }),
          const SizedBox(height: 16),
          const Text('Diplomacy', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (game.diplomacyRelations.isEmpty)
            const Text('—')
          else
            ...() {
              final rels = List<DiplomacyRelation>.from(game.diplomacyRelations)
                ..sort((a, b) {
                  final c = a.factionId1.compareTo(b.factionId1);
                  return c != 0 ? c : a.factionId2.compareTo(b.factionId2);
                });
              return rels
                  .map(
                    (rel) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${_ctdevFactionLabel(game, rel.factionId1)} ↔ '
                        '${_ctdevFactionLabel(game, rel.factionId2)}: '
                        '${rel.state.name}, ${rel.level.name}, score=${rel.score}',
                      ),
                    ),
                  )
                  .toList();
            }(),
          const SizedBox(height: 16),
          const Text('Last turn combat', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (_controller.lastTurnCombatSummaries.isEmpty)
            const Text('—')
          else
            ..._controller.lastTurnCombatSummaries.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(s),
              ),
            ),
          const SizedBox(height: 16),
          const Text('Sim Log', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(getLastUiLogLines().join('\n')),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    final history = _controller.orderHistory;
    final game = _controller.game;
    if (history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No orders recorded yet. Run at least one turn to see AI orders.'),
        ),
      );
    }

    final byTurn = <int, List<SimOrderHistoryEntry>>{};
    for (final entry in history) {
      byTurn.putIfAbsent(entry.turnNumber, () => <SimOrderHistoryEntry>[]).add(entry);
    }
    final sortedTurns = byTurn.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final turn in sortedTurns) ...[
            Builder(
              builder: (context) {
                final year = turnToYear(turn, game.turnTimeMapping);
                return Text(
                  'Turn $turn ($year)',
                  style: Theme.of(context).textTheme.titleMedium,
                );
              },
            ),
            const SizedBox(height: 4),
            Builder(
              builder: (context) {
                final entriesForTurn = List<SimOrderHistoryEntry>.from(
                  byTurn[turn] ?? const <SimOrderHistoryEntry>[],
                )..sort((a, b) {
                    final playerCompare = a.playerId.compareTo(b.playerId);
                    if (playerCompare != 0) return playerCompare;
                    return a.orderType.compareTo(b.orderType);
                  });
                final byPlayer = <String, List<SimOrderHistoryEntry>>{};
                for (final e in entriesForTurn) {
                  byPlayer.putIfAbsent(e.playerId, () => <SimOrderHistoryEntry>[]).add(e);
                }
                final playerIds = byPlayer.keys.toList()..sort();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final pid in playerIds) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${byPlayer[pid]!.first.playerName} ($pid)',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      for (final entry in byPlayer[pid]!) Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 2),
                        child: Builder(
                          builder: (context) {
                            final isAccepted =
                                entry.status == OrderValidationStatus.accepted;
                            final statusLabel =
                                isAccepted ? 'ACCEPTED' : 'REJECTED';
                            final statusColor = isAccepted
                                ? Colors.green
                                : Colors.red;
                            final reasonText = entry.reason == null
                                ? ''
                                : ' — ${entry.reason}';
                            return RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodyMedium,
                                children: [
                                  TextSpan(
                                    text: '[$statusLabel] ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '${entry.orderType}: ${entry.summary}$reasonText',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerTab(Player player) {
    final orders = _controller.pendingOrdersByPlayerId[player.id];
    final game = _controller.game;
    final topology = _controller.topology;
    final units = [
      ...game.worldState.oldWorld.units.where((u) => u.ownerId == player.id),
      ...game.worldState.newWorld.units.where((u) => u.ownerId == player.id),
    ];

    final currentOrders = orders ?? const Orders();
    final view = buildPlayerView(game, topology, player.id);
    const suggestionApi = DefaultOrderSuggestionAPI();
    final suggestedMoves = suggestionApi.suggestMoveOrders(view, game, topology, currentOrders);
    final suggestedBuilds = suggestionApi.suggestBuildOrders(view, game, topology, currentOrders);
    final suggestedWorks = suggestionApi.suggestWorkOrders(
      view,
      game,
      topology,
      currentOrders,
      tileMapByRegion: _controller.tileMapByRegion,
    );
    final suggestedResearch = suggestionApi.suggestResearchOrders(view, game, topology, currentOrders);

    // Key by regionId|id so OW and NW can share province ids (e.g. p1).
    final provinceNamesByRegionAndId = <String, String>{};
    for (final p in game.worldState.oldWorld.provinces) {
      provinceNamesByRegionAndId['${p.regionId}|${p.id}'] = p.displayName ?? p.id;
    }
    for (final p in game.worldState.newWorld.provinces) {
      provinceNamesByRegionAndId['${p.regionId}|${p.id}'] = p.displayName ?? p.id;
    }
    String provinceLabelInRegion(String regionId, String id) =>
        provinceNamesByRegionAndId['$regionId|$id'] ?? id;

    final unitsById = <String, Unit>{};
    for (final u in game.worldState.oldWorld.units) {
      unitsById[u.id] = u;
    }
    for (final u in game.worldState.newWorld.units) {
      unitsById[u.id] = u;
    }

    final ow = _viewData.oldWorld;
    final nw = _viewData.newWorld;
    final viewCellSize = ow.cellSize.toDouble() * kDebugMapScale;
    final gap = viewCellSize * 2;
    final totalMapWidth = ow.width * viewCellSize + gap + nw.width * viewCellSize;
    final totalMapHeight = math.max(
      ow.height * viewCellSize,
      nw.height * viewCellSize,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${player.displayName} (${player.id})', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Per-player map', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          SizedBox(
            width: totalMapWidth,
            height: totalMapHeight,
            child: CustomPaint(
              painter: PlayerViewMapPainter(
                viewData: _viewData,
                playerView: view,
                showOwnership: _showOwnership,
                showCapitals: _showCapitals,
                showPorts: _showPorts,
                geographicMode: _geographicMode,
                showImprovements: _showImprovements,
                showUnits: _showUnits,
                fleets: game.worldState.fleets,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Projected end of turn (pending orders)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (!_controller.hasPendingOrdersForProjection)
            const Text('— (no pending orders for this turn)')
          else
            _buildProjectedEffectsForPlayer(player),
          const SizedBox(height: 16),
          const Text('Stockpile', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(player.stockpile.quantities.isEmpty
              ? '—'
              : player.stockpile.quantities.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join(', ')),
          const SizedBox(height: 12),
          const Text('Workers', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${player.workerPool.totalWorkers}'),
          const SizedBox(height: 12),
          const Text('Treasury', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${player.treasury}'),
          const SizedBox(height: 12),
          const Text('Tech unlocked', style: TextStyle(fontWeight: FontWeight.bold)),
          Text((player.techUnlocked?.entries.where((e) => e.value).map((e) => e.key).join(', ')) ?? '—'),
          const SizedBox(height: 12),
          const Text('Pending orders', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(orders != null ? '${orders.moveOrdersByPlayerId[player.id]?.length ?? 0} move, ${orders.buildUnitOrdersByPlayerId[player.id]?.length ?? 0} build' : '—'),
          const SizedBox(height: 12),
          const Text('Available orders (suggestion API)', style: TextStyle(fontWeight: FontWeight.bold)),
          _buildAvailableOrdersSection(
            suggestedMoves: suggestedMoves,
            suggestedBuilds: suggestedBuilds,
            suggestedWorks: suggestedWorks,
            suggestedResearch: suggestedResearch,
            unitsById: unitsById,
            provinceLabelInRegion: provinceLabelInRegion,
          ),
          const SizedBox(height: 12),
          const Text('Units', style: TextStyle(fontWeight: FontWeight.bold)),
          if (units.isEmpty)
            const Text('—')
          else
            ...units.map((unit) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.type,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Province: ${provinceLabelInRegion(Unit.regionIdFromTileKey(unit.tileKey) ?? "oldWorld", unit.locationProvinceId)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _civilianUnitCapabilities[unit.type] ?? unit.type,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildAvailableOrdersSection({
    required List<MoveOrder> suggestedMoves,
    required List<BuildUnitOrder> suggestedBuilds,
    required List<WorkOrder> suggestedWorks,
    required List<ResearchOrder> suggestedResearch,
    required Map<String, Unit> unitsById,
    required String Function(String regionId, String id) provinceLabelInRegion,
  }) {
    final hasAny = suggestedMoves.isNotEmpty ||
        suggestedBuilds.isNotEmpty ||
        suggestedWorks.isNotEmpty ||
        suggestedResearch.isNotEmpty;
    if (!hasAny) {
      return const Text('—');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (suggestedMoves.isNotEmpty) ...[
          const Text('Move', style: TextStyle(fontWeight: FontWeight.w600)),
          ...suggestedMoves.map((o) {
            final unit = unitsById[o.unitId];
            final unitLabel = unit != null ? '${unit.id} (${unit.type})' : o.unitId;
            final regionId = unit != null
                ? (Unit.regionIdFromTileKey(unit.tileKey) ?? 'oldWorld')
                : 'oldWorld';
            final origin = unit != null
                ? provinceLabelInRegion(regionId, unit.locationProvinceId)
                : '?';
            final destTile = o.destinationTileKey;
            final destRegion =
                Unit.regionIdFromTileKey(destTile) ?? regionId;
            final destProv = Unit.provinceIdFromTileKey(destTile);
            final dest = destProv != null
                ? provinceLabelInRegion(destRegion, destProv)
                : destTile;
            return Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text('$unitLabel: $origin → $dest', style: Theme.of(context).textTheme.bodySmall),
            );
          }),
          const SizedBox(height: 6),
        ],
        if (suggestedBuilds.isNotEmpty) ...[
          const Text('Build', style: TextStyle(fontWeight: FontWeight.w600)),
          ...suggestedBuilds.map((o) {
            final location = provinceLabelInRegion('oldWorld', o.spawnProvinceId);
            final kind = o.isMilitary ? 'military' : 'civilian';
            return Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text('${o.unitType} ($kind) at $location', style: Theme.of(context).textTheme.bodySmall),
            );
          }),
          const SizedBox(height: 6),
        ],
        if (suggestedWorks.isNotEmpty) ...[
          const Text('Work', style: TextStyle(fontWeight: FontWeight.w600)),
          ...suggestedWorks.map((o) {
            final unit = unitsById[o.unitId];
            final unitLabel = unit != null ? '${unit.id} (${unit.type})' : o.unitId;
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
            return Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(
                '$unitLabel at $currentTile ($currentProvince) → ${o.target} at $targetTile ($targetProvince)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }),
          const SizedBox(height: 6),
        ],
        if (suggestedResearch.isNotEmpty) ...[
          const Text('Research', style: TextStyle(fontWeight: FontWeight.w600)),
          ...suggestedResearch.map((o) {
            return Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text('slot ${o.slotIndex} → ${o.techId} (${o.funding})', style: Theme.of(context).textTheme.bodySmall),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildProjectedEffectsForPlayer(Player player) {
    final fx = _controller.projectedEffectsForPlayer(player.id);
    if (fx == null) {
      return const Text('—');
    }
    final lines = <String>[];
    if (fx.workerCount != null) {
      lines.add('Workers after resolve: ${fx.workerCount}');
    }
    if (fx.treasuryDelta != null && fx.treasuryDelta != 0) {
      lines.add('Treasury Δ: ${fx.treasuryDelta}');
    }
    if (fx.stockpileDeltas != null && fx.stockpileDeltas!.isNotEmpty) {
      lines.add(
        'Stockpile Δ: '
        '${fx.stockpileDeltas!.entries.map((e) => '${e.key}:${e.value}').join(', ')}',
      );
    }
    if (fx.unitLocations != null && fx.unitLocations!.isNotEmpty) {
      final entries = fx.unitLocations!.entries.toList();
      const maxU = 12;
      final shown = entries.take(maxU).map((e) => '${e.key}→${e.value}').join('; ');
      final more = entries.length > maxU ? ' …' : '';
      lines.add('Unit provinces: $shown$more');
    }
    if (fx.productionByRecipe != null && fx.productionByRecipe!.isNotEmpty) {
      lines.add(
        'Production: '
        '${fx.productionByRecipe!.entries.map((e) => '${e.key}×${e.value}').join(', ')}',
      );
    }
    if (lines.isEmpty) {
      return Text(
        '(projection run; no worker/treasury/stockpile/unit/production deltas)',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final line in lines) Text(line)],
    );
  }

  static const _civilianUnitCapabilities = {
    kUnitTypeExplorer: 'Prospect, explore',
    kUnitTypeBuilder: 'Develop tile',
    kUnitTypeEngineer: 'Build road, port, fort',
  };
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow(this.label, this.value, this.onChanged);
  final String label;
  final bool value;
  final void Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: value, onChanged: onChanged),
          Text(label),
        ],
      );
}

class _CheckRow extends StatelessWidget {
  const _CheckRow(this.label, this.value, this.onChanged);
  final String label;
  final bool value;
  final void Function(bool?)? onChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(value: value, onChanged: onChanged),
          Text(label),
        ],
      );
}

String _ctdevFactionLabel(Game game, String factionId) {
  for (final p in game.players) {
    if (p.id == factionId) return '${p.displayName} ($factionId)';
  }
  for (final m in game.minorNations) {
    if (m.id == factionId) return '${m.displayName} ($factionId)';
  }
  for (final t in game.tribes) {
    if (t.id == factionId) return '${t.displayName} ($factionId)';
  }
  return factionId;
}
