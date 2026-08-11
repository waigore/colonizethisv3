import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show
        allProvinces,
        buildPlayerView,
        kRegionNewWorld,
        kRegionOldWorld;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../widgets/ct_panel.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/ct_tab_strip.dart';
import '../../widgets/shell/shell_player_context.dart';
import 'development_panel_assign_handler.dart';
import 'development_panel_keys.dart';
import 'development_region_tab.dart';

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
            DevelopmentRegionTab(
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
              onAssign: (candidate) => handleDevelopmentAssign(
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
            DevelopmentRegionTab(
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
              onAssign: (candidate) => handleDevelopmentAssign(
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
