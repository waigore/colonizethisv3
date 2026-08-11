import 'dart:async';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show
        DevelopmentAssignRowState,
        DevelopmentImproveAssignCandidate,
        developmentPanelMaterialShortageCommodityIds,
        resolveDevelopmentAssignRowState,
        resolveDevelopmentRoadFirstState;
import 'package:colonizethis_world/colonizethis_world.dart'
    show
        allProvinces,
        buildPlayerView,
        kRegionNewWorld,
        kRegionOldWorld,
        PlayerView;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../widgets/ct_panel.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/ct_tab_strip.dart';
import '../../widgets/shell/shell_player_context.dart';
import 'development_panel_keys.dart';
import 'development_panel_map_panel.dart';
import 'development_panel_overview.dart';
import 'development_panel_scope_list.dart';

/// Body for [DevelopmentScreen]: region tabs, overview, list + map.
class DevelopmentScreenBody extends ConsumerStatefulWidget {
  const DevelopmentScreenBody({
    super.key,
    required this.game,
    required this.humanPlayerId,
  });

  final Game game;
  final String humanPlayerId;

  @override
  ConsumerState<DevelopmentScreenBody> createState() =>
      _DevelopmentScreenBodyState();
}

class _DevelopmentScreenBodyState extends ConsumerState<DevelopmentScreenBody> {
  final Set<String> _visitedRegionIds = {kRegionOldWorld};
  bool _readModelReady = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _readModelReady = true);
    });
  }

  void _onRegionTabSelected(int index) {
    final regionId = index == 0 ? kRegionOldWorld : kRegionNewWorld;
    if (_visitedRegionIds.contains(regionId)) return;
    setState(() => _visitedRegionIds.add(regionId));
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final humanPlayerId = widget.humanPlayerId;
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    if (mapData == null) {
      return Center(child: Text(appL10n(context).development_mapDataUnavailable));
    }

    final l10n = appL10n(context);
    if (!_readModelReady) {
      return Padding(
        padding: const EdgeInsets.all(CtSpacing.l),
        child: CtPanel(
          padding: const EdgeInsets.all(CtSpacing.l),
          child: CtTabStrip(
            key: DevelopmentPanelKeys.tabsBodyKey,
            lazyTabBodies: true,
            onTabIndexChanged: _onRegionTabSelected,
            tabLabels: [l10n.region_oldWorld, l10n.region_newWorld],
            tabViews: const [
              SizedBox.shrink(),
              SizedBox.shrink(),
            ],
          ),
        ),
      );
    }

    final orders = ref.watch(currentOrdersProvider);
    final shell = ref.watch(shellPlayerContextProvider);
    final canEdit = shell.canMutateViaUi;
    final provinceNames = <String, String>{};
    for (final province in allProvinces(game.worldState)) {
      provinceNames[province.id] = province.displayName ?? province.id;
    }
    final playerNames = {for (final p in game.players) p.id: p.displayName};
    final playerView = buildPlayerView(
      game,
      mapData.combinedTopology,
      humanPlayerId,
    );
    final shared = buildDevelopmentPanelBuildContext(
      game: game,
      playerId: humanPlayerId,
      tileMapByRegion: mapData.tileMapByRegion,
      topology: mapData.combinedTopology,
      currentOrders: orders,
    );
    final connectedTileKeys = shared.connectedTileKeys;

    DevelopmentPanelRegionModel regionModelFor(String regionId) {
      if (!_visitedRegionIds.contains(regionId)) {
        return emptyDevelopmentPanelRegionModel(regionId);
      }
      return buildDevelopmentPanelRegionModel(
        shared: shared,
        game: game,
        playerId: humanPlayerId,
        regionId: regionId,
        tileMapByRegion: mapData.tileMapByRegion,
        currentOrders: orders,
        provinceDisplayNamesById: provinceNames,
        playerDisplayNamesById: playerNames,
        playerView: playerView,
      );
    }

    final bus = ref.read(appEventBusProvider);

    return Padding(
      padding: const EdgeInsets.all(CtSpacing.l),
      child: CtPanel(
        padding: const EdgeInsets.all(CtSpacing.l),
        child: CtTabStrip(
          key: DevelopmentPanelKeys.tabsBodyKey,
          lazyTabBodies: true,
          onTabIndexChanged: _onRegionTabSelected,
          tabLabels: [l10n.region_oldWorld, l10n.region_newWorld],
          tabViews: [
            _DevelopmentRegionTab(
              game: game,
              humanPlayerId: humanPlayerId,
              regionId: kRegionOldWorld,
              regionModel: regionModelFor(kRegionOldWorld),
              playerView: playerView,
              topology: mapData.combinedTopology,
              tileMapByRegion: mapData.tileMapByRegion,
              currentOrders: orders,
              connectedTileKeys: connectedTileKeys,
              provinceDisplayNamesById: provinceNames,
              canEdit: canEdit,
              onAssign: (candidate) => _handleDevelopmentAssign(
                context: context,
                bus: bus,
                game: game,
                humanPlayerId: humanPlayerId,
                canEdit: canEdit,
                topology: mapData.combinedTopology,
                tileMapByRegion: mapData.tileMapByRegion,
                orders: orders,
                connectedTileKeys: connectedTileKeys,
                candidate: candidate,
              ),
            ),
            _DevelopmentRegionTab(
              game: game,
              humanPlayerId: humanPlayerId,
              regionId: kRegionNewWorld,
              regionModel: regionModelFor(kRegionNewWorld),
              playerView: playerView,
              topology: mapData.combinedTopology,
              tileMapByRegion: mapData.tileMapByRegion,
              currentOrders: orders,
              connectedTileKeys: connectedTileKeys,
              provinceDisplayNamesById: provinceNames,
              canEdit: canEdit,
              onAssign: (candidate) => _handleDevelopmentAssign(
                context: context,
                bus: bus,
                game: game,
                humanPlayerId: humanPlayerId,
                canEdit: canEdit,
                topology: mapData.combinedTopology,
                tileMapByRegion: mapData.tileMapByRegion,
                orders: orders,
                connectedTileKeys: connectedTileKeys,
                candidate: candidate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _handleDevelopmentAssign({
  required BuildContext context,
  required AppEventBus bus,
  required Game game,
  required String humanPlayerId,
  required bool canEdit,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required Orders orders,
  required Set<String> connectedTileKeys,
  required DevelopmentImproveAssignCandidate candidate,
}) async {
  if (!canEdit) return;

  if (!candidate.isCapitalConnected) {
    final roadFirstState = resolveDevelopmentRoadFirstState(
      game: game,
      playerId: humanPlayerId,
      currentOrders: orders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
      improveTargetTileKey: candidate.targetTileKey,
      connectedTileKeys: connectedTileKeys,
    );
    final completer = Completer<DevelopmentDisconnectedAssignChoice>();
    bus.emit(
      DevelopmentDisconnectedAssignDialogEvent(
        roadFirstEnabled: roadFirstState.enabled,
        roadFirstDisabledReason: roadFirstState.disabledReason,
        onResult: completer.complete,
      ),
    );
    final choice = await completer.future;
    switch (choice) {
      case DevelopmentDisconnectedAssignChoice.cancel:
        return;
      case DevelopmentDisconnectedAssignChoice.improveAnyway:
        break;
      case DevelopmentDisconnectedAssignChoice.roadFirst:
        final roadCandidate = roadFirstState.candidate;
        if (roadCandidate == null) return;
        bus.emit(
          UpsertPendingCivilianWorkOrderRequestedEvent(
            playerId: humanPlayerId,
            workOrder: roadCandidate.toWorkOrder(),
          ),
        );
        return;
    }
  }

  bus.emit(
    UpsertPendingCivilianWorkOrderRequestedEvent(
      playerId: humanPlayerId,
      workOrder: candidate.toWorkOrder(),
    ),
  );
}

class _DevelopmentRegionTab extends StatefulWidget {
  const _DevelopmentRegionTab({
    required this.game,
    required this.humanPlayerId,
    required this.regionId,
    required this.regionModel,
    required this.playerView,
    required this.topology,
    required this.tileMapByRegion,
    required this.currentOrders,
    required this.connectedTileKeys,
    required this.provinceDisplayNamesById,
    required this.canEdit,
    required this.onAssign,
  });

  final Game game;
  final String humanPlayerId;
  final String regionId;
  final DevelopmentPanelRegionModel regionModel;
  final PlayerView playerView;
  final MapTopology topology;
  final Map<String, TileMapResult> tileMapByRegion;
  final Orders currentOrders;
  final Set<String> connectedTileKeys;
  final Map<String, String> provinceDisplayNamesById;
  final bool canEdit;
  final void Function(DevelopmentImproveAssignCandidate candidate) onAssign;

  @override
  State<_DevelopmentRegionTab> createState() => _DevelopmentRegionTabState();
}

class _DevelopmentRegionTabState extends State<_DevelopmentRegionTab> {
  Set<String>? _highlightTileKeys;

  Iterable<({String commodityId, Set<String> tileKeys})>
  get _improvableRows sync* {
    for (final scope in [
      ...widget.regionModel.ownedScopes,
      ...widget.regionModel.purchasedScopes,
    ]) {
      for (final row in scope.improvableCommodities) {
        yield (commodityId: row.commodityId, tileKeys: row.tileKeys.toSet());
      }
    }
  }

  DevelopmentAssignRowState _assignRowStateFor(
    String commodityId,
    Set<String> tileKeys,
  ) {
    if (!widget.canEdit) {
      return const DevelopmentAssignRowState(
        enabled: false,
        disabledReason: 'Orders are read-only',
      );
    }
    return resolveDevelopmentAssignRowState(
      game: widget.game,
      playerId: widget.humanPlayerId,
      currentOrders: widget.currentOrders,
      topology: widget.topology,
      tileMapByRegion: widget.tileMapByRegion,
      commodityTileKeys: tileKeys,
      connectedTileKeys: widget.connectedTileKeys,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= kNarrowBreakpoint;
    final materialShortages = developmentPanelMaterialShortageCommodityIds(
      game: widget.game,
      playerId: widget.humanPlayerId,
      currentOrders: widget.currentOrders,
      topology: widget.topology,
      tileMapByRegion: widget.tileMapByRegion,
      improvableRows: _improvableRows,
      connectedTileKeys: widget.connectedTileKeys,
    );
    final list = DevelopmentPanelScopeList(
      key: DevelopmentPanelKeys.scopeListKey,
      regionModel: widget.regionModel,
      onShowTiles: (keys) => setState(() {
        _highlightTileKeys = Set<String>.from(keys);
      }),
      assignRowStateFor: _assignRowStateFor,
      onAssign: widget.onAssign,
    );
    final mapPanel = DevelopmentPanelMapPanel(
      key: DevelopmentPanelKeys.panelMapKeyForRegion(widget.regionId),
      game: widget.game,
      humanPlayerId: widget.humanPlayerId,
      regionId: widget.regionId,
      playerView: widget.playerView,
      highlightTileKeys: _highlightTileKeys,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DevelopmentPanelOverview(
          key: DevelopmentPanelKeys.overviewKey,
          regionModel: widget.regionModel,
          materialShortageCommodityIds: materialShortages,
          provinceDisplayNamesById: widget.provinceDisplayNamesById,
          game: widget.game,
          humanPlayerId: widget.humanPlayerId,
          currentOrders: widget.currentOrders,
        ),
        const SizedBox(height: CtSpacing.m),
        Expanded(
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: list),
                    const SizedBox(width: CtSpacing.m),
                    Expanded(child: mapPanel),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: list),
                    const SizedBox(height: CtSpacing.m),
                    SizedBox(height: 240, child: mapPanel),
                  ],
                ),
        ),
      ],
    );
  }
}
