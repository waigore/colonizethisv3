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

import '../../../config/ct_e2e.dart';
import '../../../../widgets/ct_region_map.dart' show BaseLayerDisplayMode;

import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/map_province_panel_provider.dart';
import '../../../../providers/region_minimap_provider.dart';
import '../../../../providers/treasury_summary_provider.dart';
import 'region_map_viewport_snapshot.dart';
import '../../../../providers/home_fleet_cargo_provider.dart';

import '../../../config/constants.dart';
import 'game_screen_shared.dart';
import 'game_side_menu.dart';
import 'game_map_controls.dart';
import 'game_map_corner_controls.dart';
import 'game_map_empire_left_rail.dart';
import 'game_map_canvas_stack.dart';
import 'game_region_minimap.dart';
import 'game_map_narrow_detail_overlay.dart';
import 'game_map_area_state_logic.dart';
import 'next_turn_confirmation_dialog.dart';
import '../utils/map_location_resolver.dart';
import '../widgets/player_turn_event_feed.dart';

/// Map area with region tabs and province/sea zone detail overlay. SPEC/ui/province-sea-zone-detail-overlay.md.
class GameMapArea extends ConsumerStatefulWidget {
  const GameMapArea({required this.game, required this.mapViewData, super.key});

  final ct_models.Game game;
  final InitGameMapViewData mapViewData;

  @override
  ConsumerState<GameMapArea> createState() => _GameMapAreaState();
}

class _GameMapAreaState extends ConsumerState<GameMapArea> {
  static const ValueKey<String> _playerTurnFeedToggleButtonKey = ValueKey(
    'player-turn-feed-toggle-button',
  );
  int _regionIndex = 0;
  RegionMapViewportSnapshot? _regionViewportSnapshot;
  RegionMapViewportSnapshot? _pendingRegionViewport;
  bool _regionViewportFrameScheduled = false;
  String? _centerOnTileKey;
  String? _selectedCivilianTileKey;
  ({ct_models.Unit unit, String workTarget})? _workTargetSelection;
  Set<String>? _cachedValidTileKeys;
  bool _sideMenuOpen = false;
  final List<StreamSubscription<dynamic>> _busSubscriptions = [];
  ct_models.MapViewState _mapViewState = ct_models.MapViewState.defaults;
  final List<ct_models.GameToUIEvent> _pendingPlayerTurnEvents = [];
  List<ct_models.GameToUIEvent> _resolvedPlayerTurnEvents = const [];

  /// Base layer display mode for map letters. SPEC/ui/empire-overview.md § Base layer display cycle.
  BaseLayerDisplayMode _baseLayerDisplayMode =
      BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads;

  @override
  void initState() {
    super.initState();
    _mapViewState = widget.game.mapViewState;
    final bus = ref.read(appEventBusProvider);
    _busSubscriptions.addAll([
      bus.on<ct_models.OpenProvinceDetailPanelEvent>().listen((_) {
        if (!mounted) return;
        setState(() {
          // Town icon tap will be handled by the province panel provider
        });
      }),
      bus.on<ct_models.LocateMapTileEvent>().listen(
        (e) => _locateTile(e.tileKey, e.regionId),
      ),
      bus.on<ct_models.StartCivilianWorkTargetSelectionEvent>().listen(
        (e) => _startWorkTargetSelection(e.unitId, e.workTarget),
      ),
      bus.on<ct_models.UnitsPanelClosedEvent>().listen((_) {
        ref.read(mapProvincePanelProvider.notifier).setSecondaryHighlight(null);
      }),
      bus.on<ct_models.OpenMapTileDetailEvent>().listen(
        (e) => _openMapTileDetail(e.tileKey),
      ),
      bus.on<ct_models.AppCombatResultEvent>().listen(_onAppCombatResultEvent),
      bus.on<ct_models.AppNavalCombatResultEvent>().listen(
        _onAppNavalCombatResultEvent,
      ),
      bus.on<ct_models.AppProvinceCapturedEvent>().listen(
        _onAppProvinceCapturedEvent,
      ),
      bus.on<ct_models.AppDiplomacyChangeEvent>().listen(
        _onAppDiplomacyChangeEvent,
      ),
      bus.on<ct_models.AppResearchCompleteEvent>().listen(
        _onAppResearchCompleteEvent,
      ),
      bus.on<ct_models.AppOrderRejectedEvent>().listen(
        _onAppOrderRejectedEvent,
      ),
      bus.on<ct_models.AppWorkOrderCompletedEvent>().listen(
        _onAppWorkOrderCompletedEvent,
      ),
      bus.on<ct_models.AppPlayerProvinceDiscoveredEvent>().listen(
        _onAppPlayerProvinceDiscoveredEvent,
      ),
      bus.on<ct_models.AppPlayerSeaZoneDiscoveredEvent>().listen(
        _onAppPlayerSeaZoneDiscoveredEvent,
      ),
      bus.on<ct_models.AppOvertureAdvancedEvent>().listen(
        _onAppOvertureAdvancedEvent,
      ),
      bus.on<ct_models.TurnResolutionCompleteEvent>().listen(
        _onTurnResolutionCompleteEvent,
      ),
    ]);
  }

  void _onTurnResolutionCompleteEvent(
    ct_models.TurnResolutionCompleteEvent event,
  ) {
    if (event.gameId != widget.game.id || !mounted) {
      return;
    }
    setState(() {
      _resolvedPlayerTurnEvents = List<ct_models.GameToUIEvent>.from(
        _pendingPlayerTurnEvents,
      );
      _pendingPlayerTurnEvents.clear();
    });
  }

  void _onAppCombatResultEvent(ct_models.AppCombatResultEvent event) {
    if (event.attackerId != _humanPlayerId &&
        event.defenderId != _humanPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppNavalCombatResultEvent(ct_models.AppNavalCombatResultEvent event) {
    if (event.side1OwnerId != _humanPlayerId &&
        event.side2OwnerId != _humanPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppProvinceCapturedEvent(ct_models.AppProvinceCapturedEvent event) {
    if (event.previousOwnerId != _humanPlayerId &&
        event.newOwnerId != _humanPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppDiplomacyChangeEvent(ct_models.AppDiplomacyChangeEvent event) {
    if (event.actorId != _humanPlayerId && event.targetId != _humanPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppResearchCompleteEvent(ct_models.AppResearchCompleteEvent event) {
    if (event.playerId != _humanPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppOrderRejectedEvent(ct_models.AppOrderRejectedEvent event) {
    if (event.playerId != _humanPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppWorkOrderCompletedEvent(
    ct_models.AppWorkOrderCompletedEvent event,
  ) {
    if (event.playerId != _humanPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppPlayerProvinceDiscoveredEvent(
    ct_models.AppPlayerProvinceDiscoveredEvent event,
  ) {
    if (event.playerId != _humanPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppPlayerSeaZoneDiscoveredEvent(
    ct_models.AppPlayerSeaZoneDiscoveredEvent event,
  ) {
    if (event.playerId != _humanPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppOvertureAdvancedEvent(ct_models.AppOvertureAdvancedEvent event) {
    if (event.offererGpId != _humanPlayerId &&
        event.targetFactionId != _humanPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  @override
  void dispose() {
    for (final s in _busSubscriptions) {
      s.cancel();
    }
    _busSubscriptions.clear();
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

  void _setMapViewState(ct_models.MapViewState next) {
    if (_mapViewState == next) {
      return;
    }
    setState(() {
      _mapViewState = next;
    });
    final current = ref.read(currentGameProvider);
    if (current != null && current.id == widget.game.id) {
      ref
          .read(currentGameProvider.notifier)
          .setGame(current.copyWith(mapViewState: next));
    }
  }

  void _togglePlayerTurnEventsFeedVisibility() {
    _setMapViewState(
      _mapViewState.copyWith(
        showPlayerTurnEventsFeed: !_mapViewState.showPlayerTurnEventsFeed,
      ),
    );
  }

  Widget _buildPlayerTurnEventsToggleButton({
    required int eventCount,
    required String tooltipLabel,
  }) {
    final badgeLabel = eventCount > 99 ? '99+' : '$eventCount';
    return Tooltip(
      message: tooltipLabel,
      child: IconButton(
        key: _playerTurnFeedToggleButtonKey,
        onPressed: _togglePlayerTurnEventsFeedVisibility,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.62),
          foregroundColor: Colors.white,
        ),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              _mapViewState.showPlayerTurnEventsFeed
                  ? Icons.newspaper
                  : Icons.newspaper_outlined,
            ),
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                constraints: const BoxConstraints(minHeight: 16, minWidth: 16),
                child: Text(
                  badgeLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  void _locateTile(String tileKey, String regionId) {
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
      if (mounted) setState(() => _centerOnTileKey = null);
    });
  }

  void _openMapTileDetail(String tileKey) {
    final regionId = ct_models.Unit.regionIdFromTileKey(tileKey);
    if (regionId == null) return;
    ref.read(mapProvincePanelProvider.notifier).reportMapTileTapped(tileKey);
    setState(() {
      if (regionId == 'newWorld') {
        _regionIndex = 1;
      } else if (regionId == 'oldWorld') {
        _regionIndex = 0;
      }
    });
  }

  /// Integration tests only ([kCtE2EEnabled]). Same effect as tapping the capital map cell.
  void _e2eOpenHumanCapitalTileDetail() {
    final player =
        widget.game.players.where((p) => p.isHuman).firstOrNull ??
        widget.game.players.first;
    final capital = player.capitalTile;
    if (capital == null) {
      return;
    }
    _openMapTileDetail(capital.toTileKey());
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

  void _startWorkTargetSelection(String unitId, String workTarget) {
    final unit = _findUnitById(unitId);
    if (unit == null) return;
    setState(() {
      _workTargetSelection = (unit: unit, workTarget: workTarget);
      _computeValidTileKeysForSelection();
    });
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
      _selectedCivilianTileKey =
          GameMapAreaStateLogic.selectionAfterWorkAssignment(
            currentSelectedCivilianTileKey: _selectedCivilianTileKey,
            assignedTileKey: targetTileKey,
          );
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

  void _e2eSelectFirstValidWorkTargetTile() {
    final keys = _cachedValidTileKeys;
    if (keys == null || keys.isEmpty) return;
    final sorted = keys.toList()..sort();
    _onTileSelectedForWork(sorted.first);
  }

  void _e2eOpenFirstCivilianMarkerPanel() {
    if (!mounted) return;
    final currentOrders = ref.read(currentOrdersProvider);
    var projected = GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
      region: _currentRegion,
      game: widget.game,
      orders: currentOrders,
      humanPlayerId: _humanPlayerId,
    );
    final mapData = ref.read(gameServiceProvider).getMapData(widget.game.id);
    final tm = mapData?.tileMapByRegion;
    final tr = mapData?.topologyByRegion;
    final ct = mapData?.combinedTopology;
    if (tm != null && tr != null && ct != null) {
      projected = GameMapAreaStateLogic.projectFleetMarkersForHumanDraft(
        region: projected,
        game: widget.game,
        orders: currentOrders,
        humanPlayerId: _humanPlayerId,
        tileMapByRegion: tm,
        topologyByRegion: tr,
        combinedTopology: ct,
      );
    }
    final markers = [...projected.civilianTileMarkers]
      ..sort((a, b) => a.tileKey.compareTo(b.tileKey));
    if (markers.isEmpty) return;
    final m = markers.first;
    final initialUnitId = m.unitIds.isNotEmpty ? m.unitIds.first : null;
    setState(() => _selectedCivilianTileKey = m.tileKey);
    ref
        .read(appEventBusProvider)
        .emit(
          ct_models.OpenCivilianUnitsPanelEvent(
            tileScopeTileKey: m.tileKey,
            initialSelectedUnitId: initialUnitId,
          ),
        );
  }

  void _e2eOpenFirstFleetMarkerPanel() {
    if (!mounted) return;
    final currentOrders = ref.read(currentOrdersProvider);
    var projected = GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
      region: _currentRegion,
      game: widget.game,
      orders: currentOrders,
      humanPlayerId: _humanPlayerId,
    );
    final mapData = ref.read(gameServiceProvider).getMapData(widget.game.id);
    final tm = mapData?.tileMapByRegion;
    final tr = mapData?.topologyByRegion;
    final ct = mapData?.combinedTopology;
    if (tm != null && tr != null && ct != null) {
      projected = GameMapAreaStateLogic.projectFleetMarkersForHumanDraft(
        region: projected,
        game: widget.game,
        orders: currentOrders,
        humanPlayerId: _humanPlayerId,
        tileMapByRegion: tm,
        topologyByRegion: tr,
        combinedTopology: ct,
      );
    }
    final markers = [...projected.fleetTileMarkers]
      ..sort((a, b) => a.tileKey.compareTo(b.tileKey));
    if (markers.isEmpty) return;
    final m = markers.first;
    final initialFleetId = m.fleetIds.isNotEmpty ? m.fleetIds.first : null;
    ref
        .read(appEventBusProvider)
        .emit(
          ct_models.OpenNavalUnitsPanelEvent(
            locationScopeKey: m.locationScopeKey,
            initialSelectedFleetId: initialFleetId,
            tileScopeTileKey: m.tileKey,
          ),
        );
  }

  String _factionLabel(String id) {
    for (final p in widget.game.players) {
      if (p.id == id) return p.displayName;
    }
    for (final m in widget.game.minorNations) {
      if (m.id == id) return m.displayName ?? m.id;
    }
    for (final t in widget.game.tribes) {
      if (t.id == id) return t.displayName ?? t.id;
    }
    return id;
  }

  String _provinceLabel(String fullProvinceId) {
    for (final region in [
      widget.game.worldState.oldWorld,
      widget.game.worldState.newWorld,
    ]) {
      for (final province in region.provinces) {
        final prefixed = province.id.contains('|')
            ? province.id
            : '${province.regionId}|${province.id}';
        if (prefixed == fullProvinceId) {
          return province.displayName ?? prefixed;
        }
      }
    }
    return fullProvinceId;
  }

  String _seaZoneLabel(String seaZoneId) {
    return widget.game.worldState.seaZoneDisplayNameById[seaZoneId] ??
        seaZoneId;
  }

  String _diplomacyOutcomeLine({
    required String actorId,
    required String targetId,
    required String changeType,
  }) {
    final actor = _factionLabel(actorId);
    final target = _factionLabel(targetId);
    final normalized = changeType.toLowerCase();
    return switch (normalized) {
      'declare_war' => '$actor declared war on $target!',
      'peace' => '$actor and $target signed peace!',
      'alliance' => '$actor and $target formed an alliance!',
      'break_alliance' => '$actor and $target broke their alliance!',
      _ => '$actor and $target diplomacy changed! ${changeType.toUpperCase()}!',
    };
  }

  Set<String> _seaZoneRegionCandidates(String seaZoneId) {
    if (seaZoneId.contains('|')) {
      final parts = seaZoneId.split('|');
      if (parts.length >= 2 && parts.first.isNotEmpty) {
        return {parts.first};
      }
    }
    final localSeaZoneId = seaZoneId.contains('|')
        ? seaZoneId.split('|').last
        : seaZoneId;
    final fromPorts = <String>{};
    for (final key in widget.game.worldState.portsByProvinceSeaboard.keys) {
      final parts = key.split('|');
      if (parts.length < 2) {
        continue;
      }
      if (parts.last == localSeaZoneId && parts.first.isNotEmpty) {
        fromPorts.add(parts.first);
      }
    }
    final mapData = ref.read(gameServiceProvider).getMapData(widget.game.id);
    final fromTopology = <String>{};
    if (mapData == null) {
      return fromPorts;
    }
    for (final entry in mapData.topologyByRegion.entries) {
      if (entry.value.nodes.any(
        (node) =>
            node.type == TopologyNodeType.seaZone && node.id == localSeaZoneId,
      )) {
        fromTopology.add(entry.key);
      }
    }
    return {...fromPorts, ...fromTopology};
  }

  String? _tileKeyForSeaZoneEvent(String seaZoneId) {
    final candidates = _seaZoneRegionCandidates(seaZoneId);
    if (candidates.length != 1) {
      return null;
    }
    final regionId = candidates.first;
    final mapData = ref.read(gameServiceProvider).getMapData(widget.game.id);
    return tileKeyForNavalFleetAtSea(
      game: widget.game,
      regionId: regionId,
      seaZoneId: seaZoneId,
      tileMap: mapData?.tileMapByRegion[regionId],
      regionTopology: mapData?.topologyByRegion[regionId],
    );
  }

  ct_models.Province? _provinceByPrefixedId(String prefixedProvinceId) {
    for (final region in [
      widget.game.worldState.oldWorld,
      widget.game.worldState.newWorld,
    ]) {
      for (final province in region.provinces) {
        final prefixed = province.id.contains('|')
            ? province.id
            : '${province.regionId}|${province.id}';
        if (prefixed == prefixedProvinceId) {
          return province;
        }
      }
    }
    return null;
  }

  List<PlayerTurnEventFeedEntry> _feedEntries() {
    return _resolvedPlayerTurnEvents
        .map((event) {
          return switch (event) {
            ct_models.AppCombatResultEvent(
              :final provinceId,
              :final winnerId,
              :final attackerId,
              :final defenderId,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    '${_provinceLabel(provinceId)} battle resolved! ${_factionLabel(winnerId)} defeated ${_factionLabel(winnerId == attackerId ? defenderId : attackerId)}!',
                onTap: () {
                  final province = _provinceByPrefixedId(provinceId);
                  if (province == null) return;
                  final tileKey = tileKeyForProvinceLocation(
                    widget.game,
                    province,
                  );
                  if (tileKey == null) return;
                  ref
                      .read(appEventBusProvider)
                      .emit(
                        ct_models.LocateMapTileEvent(
                          tileKey: tileKey,
                          regionId: province.regionId,
                        ),
                      );
                },
              ),
            ct_models.AppProvinceCapturedEvent(
              :final provinceId,
              :final newOwnerId,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    '${_provinceLabel(provinceId)} captured! ${_factionLabel(newOwnerId)} now controls it!',
                onTap: () {
                  final province = _provinceByPrefixedId(provinceId);
                  if (province == null) return;
                  final tileKey = tileKeyForProvinceLocation(
                    widget.game,
                    province,
                  );
                  if (tileKey == null) return;
                  ref
                      .read(appEventBusProvider)
                      .emit(
                        ct_models.LocateMapTileEvent(
                          tileKey: tileKey,
                          regionId: province.regionId,
                        ),
                      );
                },
              ),
            ct_models.AppNavalCombatResultEvent(
              :final seaZoneId,
              :final outcomeName,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    '${_seaZoneLabel(seaZoneId)} naval battle resolved! Outcome: $outcomeName!',
                onTap: () {
                  final tileKey = _tileKeyForSeaZoneEvent(seaZoneId);
                  if (tileKey == null) {
                    return;
                  }
                  final regionId = ct_models.Unit.regionIdFromTileKey(tileKey);
                  if (regionId == null) {
                    return;
                  }
                  ref
                      .read(appEventBusProvider)
                      .emit(
                        ct_models.LocateMapTileEvent(
                          tileKey: tileKey,
                          regionId: regionId,
                        ),
                      );
                },
              ),
            ct_models.AppDiplomacyChangeEvent(
              :final actorId,
              :final targetId,
              :final changeType,
            ) =>
              PlayerTurnEventFeedEntry(
                text: _diplomacyOutcomeLine(
                  actorId: actorId,
                  targetId: targetId,
                  changeType: changeType,
                ),
              ),
            ct_models.AppResearchCompleteEvent(:final techId) =>
              PlayerTurnEventFeedEntry(
                text: 'Research complete! $techId unlocked!',
              ),
            ct_models.AppOrderRejectedEvent(:final reasonCode) =>
              PlayerTurnEventFeedEntry(
                text: 'Order rejected! Reason: $reasonCode!',
              ),
            ct_models.AppWorkOrderCompletedEvent(
              :final workTarget,
              :final targetTileKey,
              :final provinceId,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    '${_provinceLabel(provinceId)} work completed! ${workTarget.toUpperCase()} finished!',
                onTap: () {
                  final regionId = ct_models.Unit.regionIdFromTileKey(
                    targetTileKey,
                  );
                  if (regionId == null) {
                    return;
                  }
                  ref
                      .read(appEventBusProvider)
                      .emit(
                        ct_models.LocateMapTileEvent(
                          tileKey: targetTileKey,
                          regionId: regionId,
                        ),
                      );
                },
              ),
            ct_models.AppPlayerProvinceDiscoveredEvent(:final provinceId) =>
              PlayerTurnEventFeedEntry(
                text: '${_provinceLabel(provinceId)} discovered!',
                onTap: () {
                  final province = _provinceByPrefixedId(provinceId);
                  if (province == null) return;
                  final tileKey = tileKeyForProvinceLocation(
                    widget.game,
                    province,
                  );
                  if (tileKey == null) return;
                  ref
                      .read(appEventBusProvider)
                      .emit(
                        ct_models.LocateMapTileEvent(
                          tileKey: tileKey,
                          regionId: province.regionId,
                        ),
                      );
                },
              ),
            ct_models.AppPlayerSeaZoneDiscoveredEvent(:final seaZoneId) =>
              PlayerTurnEventFeedEntry(
                text: '${_seaZoneLabel(seaZoneId)} discovered!',
                onTap: () {
                  final tileKey = _tileKeyForSeaZoneEvent(seaZoneId);
                  if (tileKey == null) {
                    return;
                  }
                  final regionId = ct_models.Unit.regionIdFromTileKey(tileKey);
                  if (regionId == null) {
                    return;
                  }
                  ref
                      .read(appEventBusProvider)
                      .emit(
                        ct_models.LocateMapTileEvent(
                          tileKey: tileKey,
                          regionId: regionId,
                        ),
                      );
                },
              ),
            ct_models.AppOvertureAdvancedEvent(
              :final offererGpId,
              :final targetFactionId,
              :final newStage,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    'Overture advanced! ${_factionLabel(offererGpId)} with ${_factionLabel(targetFactionId)}: ${newStage.toUpperCase()}!',
              ),
            _ => const PlayerTurnEventFeedEntry(text: 'Event resolved!'),
          };
        })
        .toList(growable: false);
  }

  @override
  void didUpdateWidget(covariant GameMapArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {
      ref.read(mapProvincePanelProvider.notifier).reset();
      ref.read(regionMinimapVisibleProvider.notifier).resetToDefault();
      setState(() {
        _mapViewState = widget.game.mapViewState;
        _regionViewportSnapshot = null;
        _pendingRegionViewport = null;
        _regionViewportFrameScheduled = false;
      });
    } else if (oldWidget.game.mapViewState != widget.game.mapViewState) {
      _mapViewState = widget.game.mapViewState;
    }
  }

  void _onRegionViewportSnapshot(RegionMapViewportSnapshot snapshot) {
    final clampedMultiplier = snapshot.zoomMultiplier.clamp(0.5, 8.0);
    if ((clampedMultiplier - _mapViewState.zoomMultiplier).abs() > 0.001) {
      _setMapViewState(
        _mapViewState.copyWith(zoomMultiplier: clampedMultiplier),
      );
    }
    _pendingRegionViewport = snapshot;
    if (_regionViewportFrameScheduled) return;
    _regionViewportFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _regionViewportFrameScheduled = false;
      if (!mounted) return;
      final next = _pendingRegionViewport;
      _pendingRegionViewport = null;
      if (next == null) return;
      final cur = _regionViewportSnapshot;
      if (cur != null && cur.matches(next)) return;
      setState(() => _regionViewportSnapshot = next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentOrders = ref.watch(currentOrdersProvider);
    final isNarrow = MediaQuery.sizeOf(context).width < kNarrowBreakpoint;
    final mapTopology = widget.mapViewData.combinedTopology;
    final humanPlayerView = buildPlayerView(
      widget.game,
      mapTopology,
      _humanPlayerId,
    );
    final l10n = appL10n(context);
    final mapData = ref.watch(gameServiceProvider).getMapData(widget.game.id);
    var projectedRegion =
        GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
          region: _currentRegion,
          game: widget.game,
          orders: currentOrders,
          humanPlayerId: _humanPlayerId,
        );
    final tm = mapData?.tileMapByRegion;
    final tr = mapData?.topologyByRegion;
    final ct = mapData?.combinedTopology;
    if (tm != null && tr != null && ct != null) {
      projectedRegion = GameMapAreaStateLogic.projectFleetMarkersForHumanDraft(
        region: projectedRegion,
        game: widget.game,
        orders: currentOrders,
        humanPlayerId: _humanPlayerId,
        tileMapByRegion: tm,
        topologyByRegion: tr,
        combinedTopology: ct,
      );
    }
    final nextTurnText = l10n.game_nextTurnButton(
      widget.game.worldState.turnState.turnNumber,
      turnToYear(
        widget.game.worldState.turnState.turnNumber,
        widget.game.turnTimeMapping,
      ),
    );
    final cargoSummary = ref.watch(homeFleetCargoSummaryProvider);
    final treasurySummary = ref.watch(treasurySummaryProvider);
    final feedEntries = _feedEntries();
    final feedButtonTopInset = kMapOverlayEdgeInset;
    final feedButtonRightInset = kCtE2EEnabled
        ? kMapOverlayEdgeInset + 48
        : kMapOverlayEdgeInset;
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
          isCargoUsedReliable: cargoSummary.isCargoUsedReliable,
          treasury: treasurySummary.treasury,
          treasuryDelta: treasurySummary.projectedDelta,
        ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
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
                        region: projectedRegion,
                        baseLayerDisplayMode: _baseLayerDisplayMode,
                        showProvinceOverlay: _mapViewState.showProvinceOverlay,
                        showProvinceOwnershipTint:
                            _mapViewState.showProvinceOwnershipTint,
                        showProvinceNamesLayer:
                            _mapViewState.showProvinceNamesLayer,
                        humanPlayerId: _humanPlayerId,
                        playerView: humanPlayerView,
                        centerOnTileKey: _centerOnTileKey,
                        validTileKeysForSelection: _validTileKeysForSelection,
                        selectedCivilianTileKey: _selectedCivilianTileKey,
                        onTileSelectedForWork: _workTargetSelection != null
                            ? _onTileSelectedForWork
                            : null,
                        onWorkTargetSelectionCancelled:
                            _workTargetSelection != null
                            ? () => setState(() {
                                _workTargetSelection = null;
                                _cachedValidTileKeys = null;
                              })
                            : null,
                        onCivilianTileTapped: (tileKey) {
                          String? initialSelectedUnitId;
                          for (final marker
                              in projectedRegion.civilianTileMarkers) {
                            if (marker.tileKey == tileKey &&
                                marker.unitIds.isNotEmpty) {
                              initialSelectedUnitId = marker.unitIds.first;
                              break;
                            }
                          }
                          setState(() {
                            _selectedCivilianTileKey = tileKey;
                          });
                          ref
                              .read(appEventBusProvider)
                              .emit(
                                ct_models.OpenCivilianUnitsPanelEvent(
                                  tileScopeTileKey: tileKey,
                                  initialSelectedUnitId: initialSelectedUnitId,
                                ),
                              );
                        },
                        onCivilianTileSelectionCleared: () {
                          if (_selectedCivilianTileKey == null) return;
                          setState(() {
                            _selectedCivilianTileKey = null;
                          });
                        },
                        onFleetMarkerTapped:
                            (locationScopeKey, initialFleetId, markerTileKey) {
                              ref
                                  .read(appEventBusProvider)
                                  .emit(
                                    ct_models.OpenNavalUnitsPanelEvent(
                                      locationScopeKey: locationScopeKey,
                                      initialSelectedFleetId: initialFleetId,
                                      tileScopeTileKey: markerTileKey,
                                    ),
                                  );
                            },
                        bus: ref.read(appEventBusProvider),
                        onRegionViewportSnapshot: _onRegionViewportSnapshot,
                        zoomMultiplier: _mapViewState.zoomMultiplier,
                      ),
                      if (!_sideMenuOpen)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: kEdgeSwipeStripWidth,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onHorizontalDragUpdate: (details) {
                              if (details.delta.dx > 20) {
                                setState(() => _sideMenuOpen = true);
                              }
                            },
                          ),
                        ),
                      Positioned(
                        left: kEdgeSwipeStripWidth,
                        top: 0,
                        child: GameMapEmpireLeftRail(
                          game: widget.game,
                          humanPlayerId: _humanPlayerId,
                        ),
                      ),
                      Positioned(
                        left: kMapOverlayEdgeInset,
                        bottom: kMapOverlayEdgeInset,
                        child: GameMapCornerControls(
                          onCycleBaseLayerDisplayMode:
                              _cycleBaseLayerDisplayMode,
                          onCenterOnHomeCapital: _centerOnHumanCapital,
                          onOpenMapDisplayOptions: () {
                            showDialog<void>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text(l10n.map_displayOptions_title),
                                  content: Consumer(
                                    builder: (context, ref, child) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SwitchListTile(
                                            title: Text(
                                              l10n.map_displayOptions_showProvinceOverlay,
                                            ),
                                            value: _mapViewState
                                                .showProvinceOverlay,
                                            onChanged: (value) {
                                              _setMapViewState(
                                                _mapViewState.copyWith(
                                                  showProvinceOverlay: value,
                                                ),
                                              );
                                            },
                                          ),
                                          SwitchListTile(
                                            title: Text(
                                              l10n.map_displayOptions_showProvinceOwnership,
                                            ),
                                            value: _mapViewState
                                                .showProvinceOwnershipTint,
                                            onChanged: (value) {
                                              _setMapViewState(
                                                _mapViewState.copyWith(
                                                  showProvinceOwnershipTint:
                                                      value,
                                                ),
                                              );
                                            },
                                          ),
                                          SwitchListTile(
                                            title: Text(
                                              l10n.map_displayOptions_showProvinceNames,
                                            ),
                                            value: _mapViewState
                                                .showProvinceNamesLayer,
                                            onChanged: (value) {
                                              _setMapViewState(
                                                _mapViewState.copyWith(
                                                  showProvinceNamesLayer: value,
                                                ),
                                              );
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
                      Positioned(
                        right: feedButtonRightInset,
                        top: feedButtonTopInset,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildPlayerTurnEventsToggleButton(
                              eventCount: feedEntries.length,
                              tooltipLabel: 'Events',
                            ),
                          ],
                        ),
                      ),
                      if (kCtE2EEnabled) ...[
                        Positioned(
                          right: kMapOverlayEdgeInset,
                          top: kMapOverlayEdgeInset,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: kCtE2EOpenCapitalProvinceDetailKey,
                                onTap: _e2eOpenHumanCapitalTileDetail,
                              ),
                            ),
                          ),
                        ),
                        if (_workTargetSelection != null &&
                            _cachedValidTileKeys != null &&
                            _cachedValidTileKeys!.isNotEmpty)
                          Positioned(
                            right: kMapOverlayEdgeInset,
                            top: kMapOverlayEdgeInset + 48,
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  key: kCtE2ESelectFirstValidWorkTileKey,
                                  onTap: _e2eSelectFirstValidWorkTargetTile,
                                ),
                              ),
                            ),
                          ),
                        if (projectedRegion.civilianTileMarkers.isNotEmpty)
                          Positioned(
                            right: kMapOverlayEdgeInset,
                            top: kMapOverlayEdgeInset + 96,
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  key: kCtE2EOpenFirstCivilianMarkerPanelKey,
                                  onTap: _e2eOpenFirstCivilianMarkerPanel,
                                ),
                              ),
                            ),
                          ),
                        if (projectedRegion.fleetTileMarkers.isNotEmpty)
                          Positioned(
                            right: kMapOverlayEdgeInset,
                            top: kMapOverlayEdgeInset + 144,
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  key: kCtE2EOpenFirstFleetMarkerPanelKey,
                                  onTap: _e2eOpenFirstFleetMarkerPanel,
                                ),
                              ),
                            ),
                          ),
                      ],
                      if (_sideMenuOpen) ...[
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _sideMenuOpen = false),
                            child: Container(color: Colors.black54),
                          ),
                        ),
                        GameSideMenu(
                          sideMenuOpen: _sideMenuOpen,
                          onClose: () => setState(() => _sideMenuOpen = false),
                        ),
                      ],
                      Consumer(
                        builder: (context, ref, _) {
                          final panelOpen = ref
                              .watch(mapProvincePanelProvider)
                              .overlayOpen;
                          final rightInset = (!isNarrow && panelOpen)
                              ? 8.0 + 320.0
                              : 8.0;
                          return Positioned(
                            right: rightInset,
                            bottom: 8,
                            child: GameRegionMinimap(
                              region: projectedRegion,
                              viewportSnapshot: _regionViewportSnapshot,
                              bus: ref.read(appEventBusProvider),
                              cellSizePx: _currentRegion.cellSize.toDouble(),
                            ),
                          );
                        },
                      ),
                      if (!isNarrow)
                        Consumer(
                          builder: (context, ref, _) {
                            final panelOpen = ref
                                .watch(mapProvincePanelProvider)
                                .overlayOpen;
                            final rightInset = panelOpen ? 8.0 + 320.0 : 8.0;
                            if (!_mapViewState.showPlayerTurnEventsFeed) {
                              return const SizedBox.shrink();
                            }
                            return Positioned(
                              right: rightInset,
                              top: 56,
                              child: PlayerTurnEventFeedCard(
                                entries: feedEntries,
                                emptyLabel: 'No player events last turn.',
                              ),
                            );
                          },
                        ),
                      if (isNarrow && _mapViewState.showPlayerTurnEventsFeed)
                        Positioned(
                          right: kMapOverlayEdgeInset,
                          top: 56,
                          child: PlayerTurnEventFeedCard(
                            entries: feedEntries,
                            emptyLabel: 'No player events last turn.',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (isNarrow)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GameMapNarrowDetailOverlaySlot(
                        game: widget.game,
                        region: projectedRegion,
                        humanPlayerId: _humanPlayerId,
                        playerView: humanPlayerView,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
