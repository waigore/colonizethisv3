import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/map_view_provider.dart';
import '../../../../widgets/ct_region_map.dart';
import '../widgets/civilian_units_panel.dart';
import '../widgets/diplomacy_panel.dart';
import '../widgets/military_units_panel.dart';
import '../widgets/province_sea_zone_detail_overlay.dart';
import '../widgets/technology_panel.dart';
import '../widgets/technology_screen.dart';
import 'game_canvas.dart';

/// Hosts the Flame game canvas or map. When map data exists, shows map + province/sea zone overlay.
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(currentGameProvider);
    final mapViewData = ref.watch(mapViewDataProvider);
    final victory = game?.victory;
    return Scaffold(
      body: Stack(
        children: [
          if (mapViewData != null && game != null)
            _GameMapArea(
              game: game,
              mapViewData: mapViewData,
            )
          else
            GameWidget(game: ColonizeThisGame()),
          if (game != null && victory == null) ...[
            Positioned(
              right: 16,
              top: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final service = ref.read(gameServiceProvider);
                      final orders = ref.read(currentOrdersProvider);
                      final newGame = service.nextTurn(game, orders: orders);
                      ref.read(currentGameProvider.notifier).state = newGame;
                      ref.read(currentOrdersProvider.notifier).state = const ct_models.Orders();
                    },
                    child: Text(
                      'Next turn (${game.worldState.turnState.turnNumber} / ${turnToYear(game.worldState.turnState.turnNumber, game.turnTimeMapping)})',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      final player = game.players.isNotEmpty
                          ? game.players.first
                          : null;
                      if (player != null) {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (ctx) => TechnologyScreen(
                              game: game,
                              player: player,
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.science, size: 20),
                    label: const Text('Technology'),
                  ),
                ],
              ),
            ),
          ],
          if (game != null && victory != null)
            _VictoryOverlay(
              game: game,
              victory: victory,
            ),
        ],
      ),
    );
  }
}

/// Map area with region tabs and province/sea zone detail overlay. SPEC/ui/province-sea-zone-detail-overlay.md.
class _GameMapArea extends ConsumerStatefulWidget {
  const _GameMapArea({
    required this.game,
    required this.mapViewData,
  });

  final ct_models.Game game;
  final InitGameMapViewData mapViewData;

  @override
  ConsumerState<_GameMapArea> createState() => _GameMapAreaState();
}

class _GameMapAreaState extends ConsumerState<_GameMapArea> {
  int _regionIndex = 0;
  String? _selectedDetailId;
  String? _hoveredDetailId;
  String? _hoveredTileKey;
  String? _highlightedTileKey;
  String? _centerOnTileKey;
  ({ct_models.Unit unit, String workTarget})? _workTargetSelection;

  String get _humanPlayerId =>
      widget.game.players.where((p) => p.isHuman).map((p) => p.id).firstOrNull ??
      widget.game.players.first.id;

  RegionMapViewData get _currentRegion =>
      _regionIndex == 0 ? widget.mapViewData.oldWorld : widget.mapViewData.newWorld;

  String get _currentRegionId => _regionIndex == 0 ? 'oldWorld' : 'newWorld';

  Set<String>? get _validTileKeysForSelection {
    if (_workTargetSelection == null) return null;
    final game = ref.read(currentGameProvider);
    if (game == null) return null;
    final orders = ref.read(currentOrdersProvider);
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    final topology = mapData?.combinedTopology ?? const MapTopology();
    final valid = getValidWorkOrderTileKeys(
      game,
      topology,
      _humanPlayerId,
      _workTargetSelection!.unit.id,
      _workTargetSelection!.workTarget,
      orders,
    );
    return valid.where((k) => k.startsWith('$_currentRegionId|')).toSet();
  }

  /// Province/sea zone to show in overlay (hover when overlay open, else selection). Prefixed id.
  String get _displayId {
    if (_hoveredTileKey != null) {
      final parts = _hoveredTileKey!.split('|');
      if (parts.length >= 2) {
        return '${parts[0]}|${parts[1]}';
      }
    }
    return _hoveredDetailId ?? _selectedDetailId ?? '';
  }

  void _onProvinceSelected(String provinceId) {
    setState(() {
      _selectedDetailId = _selectedDetailId == provinceId ? null : provinceId;
    });
  }

  void _onLocateCivilianUnit(ct_models.Unit unit) {
    final tileKey = unit.tileKey;
    if (tileKey == null) return;
    final regionId = ct_models.Unit.regionIdFromTileKey(tileKey);
    setState(() {
      _highlightedTileKey = tileKey;
      _centerOnTileKey = tileKey;
      if (regionId == 'newWorld') {
        _regionIndex = 1;
      } else if (regionId == 'oldWorld') {
        _regionIndex = 0;
      }
    });
    Navigator.of(context).maybePop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _centerOnTileKey = null);
    });
  }

  void _onLocateMilitaryTile(String tileKey, String regionId) {
    setState(() {
      _highlightedTileKey = tileKey;
      _centerOnTileKey = tileKey;
      if (regionId == 'newWorld') {
        _regionIndex = 1;
      } else if (regionId == 'oldWorld') {
        _regionIndex = 0;
      }
    });
    Navigator.of(context).maybePop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _centerOnTileKey = null);
    });
  }

  void _onTileSelectedForWork(String tileKey) {
    final sel = _workTargetSelection;
    if (sel == null) return;
    final target = sel.workTarget;
    String targetTileKey = tileKey;
    if (target == 'explore' || target == 'steal_tech' || target == 'counter_spy') {
      final parts = tileKey.split('|');
      if (parts.length >= 2) {
        targetTileKey = '${parts[0]}|${parts[1]}|0|0';
      }
    }
    final workOrder = ct_models.WorkOrder(
      unitId: sel.unit.id,
      target: target,
      targetTileKey: targetTileKey,
    );
    final orders = ref.read(currentOrdersProvider);
    final list = <ct_models.WorkOrder>[
      ...(orders.workOrdersByPlayerId[_humanPlayerId] ?? const []),
      workOrder,
    ];
    ref.read(currentOrdersProvider.notifier).state = orders.copyWith(
      workOrdersByPlayerId: {...orders.workOrdersByPlayerId, _humanPlayerId: list},
    );
    setState(() => _workTargetSelection = null);
  }

  void _cancelUnitWork(String unitId) {
    final game = ref.read(currentGameProvider);
    if (game == null) return;
    final newGame = clearUnitCurrentWork(game, unitId);
    ref.read(currentGameProvider.notifier).state = newGame;
    ref.read(gameServiceProvider).saveGame(newGame);
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChoiceChip(
                label: const Text('Old World'),
                selected: _regionIndex == 0,
                onSelected: (_) => setState(() => _regionIndex = 0),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('New World'),
                selected: _regionIndex == 1,
                onSelected: (_) => setState(() => _regionIndex = 1),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () {
                  final orders = ref.read(currentOrdersProvider);
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (ctx) => CivilianUnitsPanel(
                      game: ref.read(currentGameProvider) ?? widget.game,
                      humanPlayerId: _humanPlayerId,
                      currentOrders: orders,
                      onLocateUnit: _onLocateCivilianUnit,
                      onRemoveWorkOrder: (playerId, index) {
                        final o = ref.read(currentOrdersProvider);
                        final list = List<ct_models.WorkOrder>.from(
                          o.workOrdersByPlayerId[playerId] ?? [],
                        )..removeAt(index);
                        ref.read(currentOrdersProvider.notifier).state =
                            o.copyWith(
                          workOrdersByPlayerId: {...o.workOrdersByPlayerId, playerId: list},
                        );
                      },
                      onCancelUnitWork: _cancelUnitWork,
                      onStartWorkTargetSelection: (unit, workTarget) {
                        Navigator.of(ctx).pop();
                        setState(() => _workTargetSelection = (unit: unit, workTarget: workTarget));
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.people_outline, size: 20),
                label: const Text('Civilian Units'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (ctx) => MilitaryUnitsPanel(
                      game: widget.game,
                      humanPlayerId: _humanPlayerId,
                      onLocateTile: _onLocateMilitaryTile,
                    ),
                  );
                },
                icon: const Icon(Icons.military_tech_outlined, size: 20),
                label: const Text('Military Units'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  final orders = ref.read(currentOrdersProvider);
                  final mapData = ref.read(gameServiceProvider).getMapData(widget.game.id);
                  final topology = mapData?.combinedTopology ?? const MapTopology();
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (ctx) => Scaffold(
                        appBar: AppBar(
                          title: const Text('Diplomacy'),
                          leading: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ),
                        body: DiplomacyPanel(
                          game: widget.game,
                          humanPlayerId: _humanPlayerId,
                          topology: topology,
                          currentOrders: orders,
                          onOrdersChanged: (newOrders) {
                            ref.read(currentOrdersProvider.notifier).state = newOrders;
                          },
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.handshake_outlined, size: 20),
                label: const Text('Diplomacy'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: CtRegionMap(
                  region: _currentRegion,
                  cellSizePx: 24,
                  onProvinceSelected: _onProvinceSelected,
                  onProvinceHovered: (id) => setState(() => _hoveredDetailId = id),
                  onTileHovered: (key) => setState(() => _hoveredTileKey = key),
                  highlightedTileKey: _highlightedTileKey,
                  centerOnTileKey: _centerOnTileKey,
                  validTileKeys: _validTileKeysForSelection,
                  onTileSelected: _workTargetSelection != null ? _onTileSelectedForWork : null,
                  onWorkTargetSelectionCancelled: _workTargetSelection != null
                      ? () => setState(() => _workTargetSelection = null)
                      : null,
                ),
              ),
              if (!isNarrow && _selectedDetailId != null)
                SizedBox(
                  width: 320,
                  child: ProvinceSeaZoneDetailOverlay(
                    game: widget.game,
                    region: _currentRegion,
                    selectedId: _selectedDetailId!,
                    displayId: _displayId,
                    humanPlayerId: _humanPlayerId,
                    hoveredTileKey: _hoveredTileKey,
                    onHighlightTile: (k) => setState(() => _highlightedTileKey = k),
                    onClose: () => setState(() => _selectedDetailId = null),
                  ),
                ),
            ],
          ),
        ),
        if (isNarrow && _selectedDetailId != null)
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.33,
            child: ProvinceSeaZoneDetailOverlay(
              game: widget.game,
              region: _currentRegion,
              selectedId: _selectedDetailId!,
              displayId: _displayId,
              humanPlayerId: _humanPlayerId,
              hoveredTileKey: _hoveredTileKey,
              onHighlightTile: (k) => setState(() => _highlightedTileKey = k),
              onClose: () => setState(() => _selectedDetailId = null),
            ),
          ),
      ],
    );
  }
}

/// Stateful overlay so "View final state" can hide the panel without a route (SPEC/game/victory.md).
class _VictoryOverlay extends StatefulWidget {
  const _VictoryOverlay({
    required this.game,
    required this.victory,
  });

  final ct_models.Game game;
  final ct_models.VictoryState victory;

  @override
  State<_VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<_VictoryOverlay> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: _VictoryPanel(
            game: widget.game,
            victory: widget.victory,
            onViewFinalState: () => setState(() => _dismissed = true),
          ),
        ),
      ),
    );
  }
}

class _VictoryPanel extends StatelessWidget {
  const _VictoryPanel({
    required this.game,
    required this.victory,
    this.onViewFinalState,
  });

  final ct_models.Game game;
  final ct_models.VictoryState victory;
  final VoidCallback? onViewFinalState;

  @override
  Widget build(BuildContext context) {
    final winner = game.players.firstWhere(
      (p) => p.id == victory.winnerPlayerId,
      orElse: () => game.players.first,
    );
    final victoryLabel = switch (victory.type) {
      ct_models.VictoryType.military => 'Military victory',
    };

    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              victoryLabel,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              '${winner.displayName} wins on turn ${victory.turnNumber}.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Return to main menu'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    onViewFinalState?.call();
                  },
                  child: const Text('View final state'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
