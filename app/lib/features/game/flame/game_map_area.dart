import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart'
    show InitGameMapViewData, RegionMapViewData;
import 'package:colonizethis_app/l10n/l10n.dart';

import '../../../../widgets/ct_region_map.dart' show BaseLayerDisplayMode;

import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/map_province_panel_provider.dart';
import '../../../../providers/map_view_provider.dart';
import '../../../../providers/home_fleet_cargo_provider.dart';

import 'game_screen_shared.dart';
import 'game_side_menu.dart';
import 'game_map_controls.dart';
import 'game_map_corner_controls.dart';
import 'game_map_canvas_stack.dart';
import 'game_map_narrow_detail_overlay.dart';
import 'game_map_area_state_logic.dart';
import 'next_turn_confirmation_dialog.dart';

/// Map area with region tabs and province/sea zone detail overlay. SPEC/ui/province-sea-zone-detail-overlay.md.
class GameMapArea extends ConsumerStatefulWidget {
  const GameMapArea({required this.game, required this.mapViewData, super.key});

  final ct_models.Game game;
  final InitGameMapViewData mapViewData;

  @override
  ConsumerState<GameMapArea> createState() => _GameMapAreaState();
}

class _GameMapAreaState extends ConsumerState<GameMapArea> {
  int _regionIndex = 0;
  String? _centerOnTileKey;
  ({ct_models.Unit unit, String workTarget})? _workTargetSelection;
  Set<String>? _cachedValidTileKeys;
  bool _sideMenuOpen = false;
  StreamSubscription<ct_models.AppEvent>? _busSubscription;

  /// Base layer display mode for map letters. SPEC/ui/empire-overview.md § Base layer display cycle.
  BaseLayerDisplayMode _baseLayerDisplayMode =
      BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads;

  @override
  void initState() {
    super.initState();
    final bus = ref.read(appEventBusProvider);
    _busSubscription = bus.stream.listen((event) {
      if (event is ct_models.OpenProvinceDetailPanelEvent) {
        setState(() {
          // Town icon tap will be handled by the province panel provider
        });
      } else if (event is ct_models.LocateMapTileEvent) {
        _locateTile(event.tileKey, event.regionId, closePanel: event.closeCurrentPanel);
      } else if (event is ct_models.StartCivilianWorkTargetSelectionEvent) {
        _startWorkTargetSelection(
          event.unitId,
          event.workTarget,
          closePanel: event.closeCurrentPanel,
        );
      } else if (event is ct_models.UnitsPanelClosedEvent) {
        ref.read(mapProvincePanelProvider.notifier).setSecondaryHighlight(null);
      }
    });
  }

  @override
  void dispose() {
    _busSubscription?.cancel();
    super.dispose();
  }

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

  Set<String>? get _validTileKeysForSelection => _cachedValidTileKeys;

  void _computeValidTileKeysForSelection() {
    if (_workTargetSelection == null) {
      _cachedValidTileKeys = null;
      return;
    }
    final game = ref.read(currentGameProvider);
    if (game == null) {
      _cachedValidTileKeys = null;
      return;
    }
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
      tileMapByRegion: mapData?.tileMapByRegion,
    );
    _cachedValidTileKeys = valid
        .where((k) => k.startsWith('$_currentRegionId|'))
        .toSet();
  }

  void _cycleBaseLayerDisplayMode() {
    setState(() {
      _baseLayerDisplayMode = switch (_baseLayerDisplayMode) {
        BaseLayerDisplayMode.terrainOnly =>
          BaseLayerDisplayMode.terrainAndResources,
        BaseLayerDisplayMode.terrainAndResources =>
          BaseLayerDisplayMode.terrainAndResourcesImprovementLabels,
        BaseLayerDisplayMode.terrainAndResourcesImprovementLabels =>
          BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
        BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads =>
          BaseLayerDisplayMode.terrainOnly,
      };
    });
  }

  void _centerOnHumanCapital() {
    final player =
        widget.game.players.where((p) => p.isHuman).firstOrNull ??
        widget.game.players.first;
    final capital = player.capitalTile;
    if (capital == null) {
      return;
    }
    final tileKey = capital.toTileKey();
    final regionId = capital.regionId;
    ref.read(mapProvincePanelProvider.notifier).setSecondaryHighlight(tileKey);
    setState(() {
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

  void _locateTile(String tileKey, String regionId, {required bool closePanel}) {
    ref.read(mapProvincePanelProvider.notifier).setSecondaryHighlight(tileKey);
    setState(() {
      _centerOnTileKey = tileKey;
      if (regionId == 'newWorld') {
        _regionIndex = 1;
      } else if (regionId == 'oldWorld') {
        _regionIndex = 0;
      }
    });
    if (closePanel) {
      Navigator.of(context).maybePop();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _centerOnTileKey = null);
    });
  }

  ct_models.Unit? _findUnitById(String unitId) {
    for (final unit in widget.game.worldState.oldWorld.units) {
      if (unit.id == unitId) return unit;
    }
    for (final unit in widget.game.worldState.newWorld.units) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }

  void _startWorkTargetSelection(
    String unitId,
    String workTarget, {
    required bool closePanel,
  }) {
    final unit = _findUnitById(unitId);
    if (unit == null) return;
    setState(() {
      _workTargetSelection = (unit: unit, workTarget: workTarget);
      _computeValidTileKeysForSelection();
    });
    if (closePanel) {
      Navigator.of(context).maybePop();
    }
  }

  void _onTileSelectedForWork(String tileKey) {
    final sel = _workTargetSelection;
    if (sel == null) return;
    final target = sel.workTarget;
    final targetTileKey = GameMapAreaStateLogic.translateWorkTargetTileKey(
      tileKey: tileKey,
      workTarget: target,
    );
    final workOrder = ct_models.WorkOrder(
      unitId: sel.unit.id,
      target: target,
      targetTileKey: targetTileKey,
    );
    final orders = ref.read(currentOrdersProvider);
    ref
        .read(currentOrdersProvider.notifier)
        .replaceAll(
          GameMapAreaStateLogic.addHumanWorkOrder(
            orders: orders,
            humanPlayerId: _humanPlayerId,
            workOrder: workOrder,
          ),
        );
    setState(() {
      _workTargetSelection = null;
      _cachedValidTileKeys = null;
    });
  }

  Future<void> _onNextTurn() async {
    final game = ref.read(currentGameProvider);
    if (game == null) return;

    final currentTurn = game.worldState.turnState.turnNumber;
    final ok = await showNextTurnConfirmationDialog(
      context,
      currentTurn: currentTurn,
    );
    if (ok != true) return;

    final service = ref.read(gameServiceProvider);
    final orders = ref.read(currentOrdersProvider);
    final newGame = service.nextTurn(game, orders: orders);
    ref.read(currentGameProvider.notifier).setGame(newGame);
    ref.read(currentOrdersProvider.notifier).clear();
  }

  @override
  void didUpdateWidget(covariant GameMapArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {
      ref.read(mapProvincePanelProvider.notifier).reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showProvinceOverlay = ref.watch(mapProvinceOverlayVisibleProvider);
    final showProvinceOwnershipTint = ref.watch(
      mapProvinceOwnershipTintVisibleProvider,
    );
    final showProvinceNames = ref.watch(mapProvinceNamesVisibleProvider);
    final isNarrow = MediaQuery.sizeOf(context).width < kInGameNarrowBreakpoint;
    final mapTopology = widget.mapViewData.combinedTopology;
    final humanPlayerView = buildPlayerView(
      widget.game,
      mapTopology,
      _humanPlayerId,
    );
    final l10n = appL10n(context);
    final nextTurnText = l10n.game_nextTurnButton(
      widget.game.worldState.turnState.turnNumber,
      turnToYear(
        widget.game.worldState.turnState.turnNumber,
        widget.game.turnTimeMapping,
      ),
    );
    final cargoSummary = ref.watch(homeFleetCargoSummaryProvider);
    return Column(
      children: [
        GameMapControls(
          sideMenuOpen: _sideMenuOpen,
          onToggleSideMenu: () =>
              setState(() => _sideMenuOpen = !_sideMenuOpen),
          onNextTurn: _onNextTurn,
          regionIndex: _regionIndex,
          onRegionIndexChanged: (i) =>
              setState(() => _regionIndex = i == 0 ? 0 : 1),
          nextTurnText: nextTurnText,
          cargoUsed: cargoSummary.used,
          cargoCapacity: cargoSummary.capacity,
        ),
        Expanded(
          child: Focus(
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
                GameMapCanvasStack(
                  isNarrow: isNarrow,
                  game: widget.game,
                  region: _currentRegion,
                  baseLayerDisplayMode: _baseLayerDisplayMode,
                  showProvinceOverlay: showProvinceOverlay,
                  showProvinceOwnershipTint: showProvinceOwnershipTint,
                  showProvinceNamesLayer: showProvinceNames,
                  humanPlayerId: _humanPlayerId,
                  playerView: humanPlayerView,
                  centerOnTileKey: _centerOnTileKey,
                  validTileKeysForSelection: _validTileKeysForSelection,
                  onTileSelectedForWork: _workTargetSelection != null
                      ? _onTileSelectedForWork
                      : null,
                  onWorkTargetSelectionCancelled: _workTargetSelection != null
                      ? () => setState(() {
                          _workTargetSelection = null;
                          _cachedValidTileKeys = null;
                        })
                      : null,
                  bus: ref.read(appEventBusProvider),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: GameMapCornerControls(
                    onCycleBaseLayerDisplayMode: _cycleBaseLayerDisplayMode,
                    onCenterOnHomeCapital: _centerOnHumanCapital,
                    onOpenMapDisplayOptions: () {
                      showDialog<void>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(l10n.map_displayOptions_title),
                            content: Consumer(
                              builder: (context, ref, _) {
                                final provinceOverlayVisible = ref.watch(
                                  mapProvinceOverlayVisibleProvider,
                                );
                                final ownershipTintVisible = ref.watch(
                                  mapProvinceOwnershipTintVisibleProvider,
                                );
                                final namesVisible = ref.watch(
                                  mapProvinceNamesVisibleProvider,
                                );
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SwitchListTile(
                                      title: Text(
                                        l10n.map_displayOptions_showProvinceOverlay,
                                      ),
                                      value: provinceOverlayVisible,
                                      onChanged: (value) {
                                        ref
                                            .read(
                                              mapProvinceOverlayVisibleProvider
                                                  .notifier,
                                            )
                                            .set(value);
                                      },
                                    ),
                                    SwitchListTile(
                                      title: Text(
                                        l10n.map_displayOptions_showProvinceOwnership,
                                      ),
                                      value: ownershipTintVisible,
                                      onChanged: (value) {
                                        ref
                                            .read(
                                              mapProvinceOwnershipTintVisibleProvider
                                                  .notifier,
                                            )
                                            .set(value);
                                      },
                                    ),
                                    SwitchListTile(
                                      title: Text(
                                        l10n.map_displayOptions_showProvinceNames,
                                      ),
                                      value: namesVisible,
                                      onChanged: (value) {
                                        ref
                                            .read(
                                              mapProvinceNamesVisibleProvider
                                                  .notifier,
                                            )
                                            .set(value);
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                child: Text(l10n.common_close),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                if (!_sideMenuOpen)
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
                  GameSideMenu(
                    game: widget.game,
                    humanPlayerId: _humanPlayerId,
                    sideMenuOpen: _sideMenuOpen,
                    onClose: () => setState(() => _sideMenuOpen = false),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (isNarrow)
          GameMapNarrowDetailOverlaySlot(
            game: widget.game,
            region: _currentRegion,
            humanPlayerId: _humanPlayerId,
            playerView: humanPlayerView,
          ),
      ],
    );
  }
}
