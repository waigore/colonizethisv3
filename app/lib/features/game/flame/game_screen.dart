import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/map_view_provider.dart';
import '../../../../providers/production_allocation_provider.dart';
import '../../../../widgets/ct_region_map.dart'
    show BaseLayerDisplayMode, CtRegionMap, CtMapVisibilityMode;
import '../widgets/civilian_units_panel.dart';
import '../widgets/diplomacy_screen.dart';
import '../widgets/military_units_panel.dart';
import '../widgets/production_screen.dart';
import '../widgets/province_sea_zone_detail_overlay.dart';
import '../widgets/technology_screen.dart';
import '../../../widgets/ct_choice_chip.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_panel.dart';
import '../../../widgets/ct_screen_shell.dart';
import 'game_canvas.dart';

/// Breakpoint for in-game narrow layout (side menu, reduced top bar). SPEC/ui/in-game-shell-narrow.md.
const double kInGameNarrowBreakpoint = 600;

/// Key for the base layer cycle button (for tests). SPEC/ui/empire-overview.md § Base layer display cycle.
const Key kBaseLayerCycleButtonKey = Key('base_layer_cycle_button');

/// Key for the home-to-capital button (for tests). SPEC/ui/empire-overview.md § Home-to-capital button.
const Key kHomeToCapitalButtonKey = Key('home_to_capital_button');

/// Shows the in-game pause menu (Debug log, Resume). SPEC/program/debug-log-viewer.md.
void _showPauseMenu(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Debug log'),
            onTap: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed(Routes.debugLog);
            },
          ),
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Resume'),
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    ),
  );
}

/// Hosts the Flame game canvas or map. When map data exists, shows map + province/sea zone overlay.
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(currentGameProvider);
    final mapViewData = ref.watch(mapViewDataProvider);
    final victory = game?.victory;
    final isNarrow = MediaQuery.sizeOf(context).width < kInGameNarrowBreakpoint;
    final showOverlayButtons =
        game != null && victory == null && (!isNarrow || mapViewData == null);
    return CtScreenShell(
      title: 'Game',
      child: Stack(
        children: [
          if (mapViewData != null && game != null)
            _GameMapArea(game: game, mapViewData: mapViewData)
          else
            GameWidget(game: ColonizeThisGame()),
          if (showOverlayButtons) ...[
            Positioned(
              left: 16,
              top: 16,
              child: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _showPauseMenu(context),
                tooltip: 'Pause menu',
              ),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: CtNinePatchButton(
                onPressed: () {
                  final service = ref.read(gameServiceProvider);
                  final orders = ref.read(currentOrdersProvider);
                  final newGame = service.nextTurn(game, orders: orders);
                  ref.read(currentGameProvider.notifier).state = newGame;
                  ref.read(currentOrdersProvider.notifier).state =
                      const ct_models.Orders();
                },
                child: Text(
                  'Next turn (${game!.worldState.turnState.turnNumber} / ${turnToYear(game.worldState.turnState.turnNumber, game.turnTimeMapping)})',
                ),
              ),
            ),
          ],
          if (game != null && victory != null)
            _VictoryOverlay(game: game, victory: victory),
        ],
      ),
    );
  }
}

/// Map area with region tabs and province/sea zone detail overlay. SPEC/ui/province-sea-zone-detail-overlay.md.
class _GameMapArea extends ConsumerStatefulWidget {
  const _GameMapArea({required this.game, required this.mapViewData});

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
  bool _sideMenuOpen = false;

  /// Base layer display mode for map letters. SPEC/ui/empire-overview.md § Base layer display cycle.
  BaseLayerDisplayMode _baseLayerDisplayMode =
      BaseLayerDisplayMode.terrainResourcesImprovements;

  String get _humanPlayerId =>
      widget.game.players
          .where((p) => p.isHuman)
          .map((p) => p.id)
          .firstOrNull ??
      widget.game.players.first.id;

  RegionMapViewData get _currentRegion => _regionIndex == 0
      ? widget.mapViewData.oldWorld
      : widget.mapViewData.newWorld;

  String get _currentRegionId => _regionIndex == 0 ? 'oldWorld' : 'newWorld';

  Set<String>? get _validTileKeysForSelection {
    if (_workTargetSelection == null) return null;
    final game = ref.read(currentGameProvider);
    if (game == null) return null;
    final orders = ref.read(currentOrdersProvider);
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    final topology = mapData?.combinedTopology ?? const MapTopology();
    final view = buildPlayerView(game, topology, _humanPlayerId);
    final valid = getValidWorkOrderTileKeysWithVisibility(
      game: game,
      topology: topology,
      view: view,
      unitId: _workTargetSelection!.unit.id,
      workTarget: _workTargetSelection!.workTarget,
      currentOrders: orders,
    );
    return valid.where((k) => k.startsWith('$_currentRegionId|')).toSet();
  }

  void _cycleBaseLayerDisplayMode() {
    setState(() {
      _baseLayerDisplayMode = switch (_baseLayerDisplayMode) {
        BaseLayerDisplayMode.terrainOnly =>
          BaseLayerDisplayMode.terrainAndResources,
        BaseLayerDisplayMode.terrainAndResources =>
          BaseLayerDisplayMode.terrainResourcesImprovements,
        BaseLayerDisplayMode.terrainResourcesImprovements =>
          BaseLayerDisplayMode.terrainOnly,
      };
    });
  }

  /// Base layer cycle button (letter r). SPEC/ui/empire-overview.md § Base layer display cycle.
  Widget _buildBaseLayerCycleButton() {
    return Material(
      key: kBaseLayerCycleButtonKey,
      color: Colors.white.withValues(alpha: 0.9),
      child: Tooltip(
        message: 'Base layer: terrain / +resources / +improvements',
        child: InkWell(
          onTap: _cycleBaseLayerDisplayMode,
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'r',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  /// Home-to-capital button (letter h). SPEC/ui/empire-overview.md § Home-to-capital button.
  Widget _buildHomeToCapitalButton() {
    return Material(
      key: kHomeToCapitalButtonKey,
      color: Colors.white.withValues(alpha: 0.9),
      child: Tooltip(
        message: 'Center on capital',
        child: InkWell(
          onTap: _centerOnHumanCapital,
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'h',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  void _centerOnHumanCapital() {
    final player = widget.game.players.where((p) => p.isHuman).firstOrNull ??
        widget.game.players.first;
    final capital = player.capitalTile;
    if (capital == null) {
      return;
    }
    final tileKey = capital.toTileKey();
    final regionId = capital.regionId;
    setState(() {
      _highlightedTileKey = tileKey;
      _centerOnTileKey = tileKey;
      if (regionId == 'newWorld') {
        _regionIndex = 1;
      } else if (regionId == 'oldWorld') {
        _regionIndex = 0;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _centerOnTileKey = null;
      });
    });
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
    // Province tap always selects/shows the overlay; it stays visible until
    // explicitly dismissed via the overlay close button. SPEC/ui/province-sea-zone-detail-overlay.md.
    setState(() {
      _selectedDetailId = provinceId;
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
    if (target == 'explore' ||
        target == 'steal_tech' ||
        target == 'counter_spy') {
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
      workOrdersByPlayerId: {
        ...orders.workOrdersByPlayerId,
        _humanPlayerId: list,
      },
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

  void _onNextTurn() {
    final game = ref.read(currentGameProvider);
    if (game == null) return;
    final service = ref.read(gameServiceProvider);
    final orders = ref.read(currentOrdersProvider);
    final newGame = service.nextTurn(game, orders: orders);
    ref.read(currentGameProvider.notifier).state = newGame;
    ref.read(currentOrdersProvider.notifier).state = const ct_models.Orders();
  }

  static const double _kSideMenuWidth = 280;

  Widget _buildSideMenu(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      key: ValueKey(_sideMenuOpen),
      tween: Tween<Offset>(
        begin: Offset(_sideMenuOpen ? -1 : 0, 0),
        end: Offset(_sideMenuOpen ? 0 : -1, 0),
      ),
      duration: const Duration(milliseconds: 200),
      builder: (context, Offset offset, child) {
        return Positioned(
          left: offset.dx * _kSideMenuWidth,
          top: 0,
          bottom: 0,
          width: _kSideMenuWidth,
          child: child!,
        );
      },
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx < -5) {
            setState(() => _sideMenuOpen = false);
          }
        },
        child: CtPanel(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CtNinePatchButton(
                    onPressed: () => setState(() => _sideMenuOpen = false),
                    child: const Text('×'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._buildEmpireMenuButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEmpireMenuButtons(BuildContext context) {
    final player =
        widget.game.players.where((p) => p.isHuman).firstOrNull ??
        widget.game.players.first;
    final orders = ref.read(currentOrdersProvider);
    final mapData = ref.read(gameServiceProvider).getMapData(widget.game.id);
    final topology = mapData?.combinedTopology ?? const MapTopology();
    final desired = ref.read(productionDesiredOutputProvider);
    return [
      _empireButton(
        context,
        'assets/images/ui_icon_production.png',
        'Production',
        () {
          setState(() => _sideMenuOpen = false);
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (ctx) => ProductionScreen(
                game: widget.game,
                player: player,
                desiredOutputByRecipe: desired,
                onDesiredOutputChanged: (newMap) {
                  ref.read(productionDesiredOutputProvider.notifier).state =
                      newMap;
                },
              ),
            ),
          );
        },
      ),
      _empireButton(
        context,
        'assets/images/ui_icon_civilian_units.png',
        'Civilian Units',
        () {
          setState(() => _sideMenuOpen = false);
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (ctx) {
              final isNarrowCtx =
                  MediaQuery.sizeOf(ctx).width < kInGameNarrowBreakpoint;
              final maxHeight =
                  MediaQuery.sizeOf(ctx).height * (isNarrowCtx ? 0.33 : 0.5);
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: CivilianUnitsPanel(
                  game: ref.read(currentGameProvider) ?? widget.game,
                  humanPlayerId: _humanPlayerId,
                  currentOrders: orders,
                  availableWorkTargets: ref.watch(availableWorkTargetsProvider),
                  onLocateUnit: _onLocateCivilianUnit,
                  onRemoveWorkOrder: (playerId, index) {
                    final o = ref.read(currentOrdersProvider);
                    final list = List<ct_models.WorkOrder>.from(
                      o.workOrdersByPlayerId[playerId] ?? [],
                    )..removeAt(index);
                    ref.read(currentOrdersProvider.notifier).state = o.copyWith(
                      workOrdersByPlayerId: {
                        ...o.workOrdersByPlayerId,
                        playerId: list,
                      },
                    );
                  },
                  onCancelUnitWork: _cancelUnitWork,
                  onStartWorkTargetSelection: (unit, workTarget) {
                    Navigator.of(ctx).pop();
                    setState(
                      () => _workTargetSelection = (
                        unit: unit,
                        workTarget: workTarget,
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      _empireButton(
        context,
        'assets/images/ui_icon_military_units.png',
        'Military Units',
        () {
          setState(() => _sideMenuOpen = false);
          showModalBottomSheet<void>(
            context: context,
            builder: (ctx) => MilitaryUnitsPanel(
              game: widget.game,
              humanPlayerId: _humanPlayerId,
              onLocateTile: _onLocateMilitaryTile,
            ),
          );
        },
      ),
      _empireButton(
        context,
        'assets/images/ui_icon_diplomacy.png',
        'Diplomacy',
        () {
          setState(() => _sideMenuOpen = false);
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => DiplomacyScreen(
                game: widget.game,
                humanPlayerId: _humanPlayerId,
                topology: topology,
                currentOrders: orders,
                onOrdersChanged: (newOrders) {
                  ref.read(currentOrdersProvider.notifier).state = newOrders;
                },
              ),
            ),
          );
        },
      ),
      _empireButton(
        context,
        'assets/images/ui_icon_technology.png',
        'Technology',
        () {
          setState(() => _sideMenuOpen = false);
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (ctx) => TechnologyScreen(
                game: widget.game,
                player: player,
                currentOrders: orders,
                onOrdersChanged: (newOrders) {
                  ref.read(currentOrdersProvider.notifier).state = newOrders;
                },
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _empireButton(
    BuildContext context,
    String iconAsset,
    String label,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CtNinePatchButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(iconAsset, width: 20, height: 20),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < kInGameNarrowBreakpoint;
    return Column(
      children: [
        if (isNarrow)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () =>
                      setState(() => _sideMenuOpen = !_sideMenuOpen),
                  tooltip: 'Menu',
                ),
                Expanded(
                  child: CtNinePatchButton(
                    onPressed: _onNextTurn,
                    child: Text(
                      'Next turn (${widget.game.worldState.turnState.turnNumber} / ${turnToYear(widget.game.worldState.turnState.turnNumber, widget.game.turnTimeMapping)})',
                    ),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CtChoiceChip(
                label: const Text('Old World'),
                selected: _regionIndex == 0,
                onSelected: (_) => setState(() => _regionIndex = 0),
              ),
              const SizedBox(width: 8),
              CtChoiceChip(
                label: const Text('New World'),
                selected: _regionIndex == 1,
                onSelected: (_) => setState(() => _regionIndex = 1),
              ),
              if (!isNarrow) ...[
                const SizedBox(width: 16),
                CtNinePatchButton(
                  onPressed: () {
                    final player =
                        widget.game.players
                            .where((p) => p.isHuman)
                            .firstOrNull ??
                        widget.game.players.first;
                    final desired = ref.read(productionDesiredOutputProvider);
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (ctx) => ProductionScreen(
                          game: widget.game,
                          player: player,
                          desiredOutputByRecipe: desired,
                          onDesiredOutputChanged: (newMap) {
                            ref
                                    .read(
                                      productionDesiredOutputProvider.notifier,
                                    )
                                    .state =
                                newMap;
                          },
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/ui_icon_production.png',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Production'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CtNinePatchButton(
                  onPressed: () {
                    final orders = ref.read(currentOrdersProvider);
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) {
                        final isNarrow = MediaQuery.sizeOf(ctx).width < 600;
                        final maxHeight =
                            MediaQuery.sizeOf(ctx).height *
                            (isNarrow ? 0.33 : 0.5);
                        return ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: maxHeight),
                          child: CivilianUnitsPanel(
                            game: ref.read(currentGameProvider) ?? widget.game,
                            humanPlayerId: _humanPlayerId,
                            currentOrders: orders,
                            availableWorkTargets: ref.watch(
                              availableWorkTargetsProvider,
                            ),
                            onLocateUnit: _onLocateCivilianUnit,
                            onRemoveWorkOrder: (playerId, index) {
                              final o = ref.read(currentOrdersProvider);
                              final list = List<ct_models.WorkOrder>.from(
                                o.workOrdersByPlayerId[playerId] ?? [],
                              )..removeAt(index);
                              ref.read(currentOrdersProvider.notifier).state = o
                                  .copyWith(
                                    workOrdersByPlayerId: {
                                      ...o.workOrdersByPlayerId,
                                      playerId: list,
                                    },
                                  );
                            },
                            onCancelUnitWork: _cancelUnitWork,
                            onStartWorkTargetSelection: (unit, workTarget) {
                              Navigator.of(ctx).pop();
                              setState(
                                () => _workTargetSelection = (
                                  unit: unit,
                                  workTarget: workTarget,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/ui_icon_civilian_units.png',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Civilian Units'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CtNinePatchButton(
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/ui_icon_military_units.png',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Military Units'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CtNinePatchButton(
                  onPressed: () {
                    final orders = ref.read(currentOrdersProvider);
                    final mapData = ref
                        .read(gameServiceProvider)
                        .getMapData(widget.game.id);
                    final topology =
                        mapData?.combinedTopology ?? const MapTopology();
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => DiplomacyScreen(
                          game: widget.game,
                          humanPlayerId: _humanPlayerId,
                          topology: topology,
                          currentOrders: orders,
                          onOrdersChanged: (newOrders) {
                            ref.read(currentOrdersProvider.notifier).state =
                                newOrders;
                          },
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/ui_icon_diplomacy.png',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Diplomacy'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CtNinePatchButton(
                  onPressed: () {
                    final orders = ref.read(currentOrdersProvider);
                    final player =
                        widget.game.players
                            .where((p) => p.isHuman)
                            .firstOrNull ??
                        widget.game.players.first;
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (ctx) => TechnologyScreen(
                          game: widget.game,
                          player: player,
                          currentOrders: orders,
                          onOrdersChanged: (newOrders) {
                            ref.read(currentOrdersProvider.notifier).state =
                                newOrders;
                          },
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/ui_icon_technology.png',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Technology'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: isNarrow
              ? Focus(
                  autofocus: true,
                  onKeyEvent: (node, event) {
                    if (_sideMenuOpen &&
                        event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.escape) {
                      setState(() => _sideMenuOpen = false);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CtRegionMap(
                          region: _currentRegion,
                          cellSizePx: 24,
                          visibilityMode: CtMapVisibilityMode.playerConstrained,
                          baseLayerDisplayMode: _baseLayerDisplayMode,
                          onProvinceSelected: _onProvinceSelected,
                          onProvinceHovered: (id) =>
                              setState(() => _hoveredDetailId = id),
                          onTileHovered: (key) =>
                              setState(() => _hoveredTileKey = key),
                          highlightedTileKey: _highlightedTileKey,
                          centerOnTileKey: _centerOnTileKey,
                          validTileKeys: _validTileKeysForSelection,
                          onTileSelected: _workTargetSelection != null
                              ? _onTileSelectedForWork
                              : null,
                          onWorkTargetSelectionCancelled:
                              _workTargetSelection != null
                              ? () =>
                                    setState(() => _workTargetSelection = null)
                              : null,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBaseLayerCycleButton(),
                            const SizedBox(height: 4),
                            _buildHomeToCapitalButton(),
                          ],
                        ),
                      ),
                      if (isNarrow && !_sideMenuOpen)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 20,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onHorizontalDragUpdate: (details) {
                              if (details.delta.dx > 20) {
                                setState(() => _sideMenuOpen = true);
                              }
                            },
                          ),
                        ),
                      if (_sideMenuOpen) ...[
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _sideMenuOpen = false),
                            child: Container(color: Colors.black54),
                          ),
                        ),
                        _buildSideMenu(context),
                      ],
                    ],
                  ),
                )
              : Stack(
                  children: [
                    Positioned.fill(
                      child: Row(
                        children: [
                          Expanded(
                            child: CtRegionMap(
                              region: _currentRegion,
                              cellSizePx: 24,
                              visibilityMode:
                                  CtMapVisibilityMode.playerConstrained,
                              baseLayerDisplayMode: _baseLayerDisplayMode,
                              onProvinceSelected: _onProvinceSelected,
                              onProvinceHovered: (id) =>
                                  setState(() => _hoveredDetailId = id),
                              onTileHovered: (key) =>
                                  setState(() => _hoveredTileKey = key),
                              highlightedTileKey: _highlightedTileKey,
                              centerOnTileKey: _centerOnTileKey,
                              validTileKeys: _validTileKeysForSelection,
                              onTileSelected: _workTargetSelection != null
                                  ? _onTileSelectedForWork
                                  : null,
                              onWorkTargetSelectionCancelled:
                                  _workTargetSelection != null
                                  ? () => setState(
                                      () => _workTargetSelection = null,
                                    )
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
                                onHighlightTile: (k) =>
                                    setState(() => _highlightedTileKey = k),
                                onClose: () =>
                                    setState(() => _selectedDetailId = null),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBaseLayerCycleButton(),
                          const SizedBox(height: 4),
                          _buildHomeToCapitalButton(),
                        ],
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
  const _VictoryOverlay({required this.game, required this.victory});

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

    return Padding(
      padding: const EdgeInsets.all(24),
      child: CtPanel(
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
                CtNinePatchButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Return to main menu'),
                ),
                const SizedBox(width: 12),
                CtNinePatchButton(
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
