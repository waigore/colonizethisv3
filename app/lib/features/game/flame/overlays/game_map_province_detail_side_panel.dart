import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/home_fleet_cargo_provider.dart';
import '../../../../providers/map_province_panel_provider.dart';
import '../../../../providers/province_overlay_read_model_cache_provider.dart';
import '../../screens/game/game_screen_shared.dart'
    show kGameMapWideProvinceSidePanelWidth;
import '../caches/per_player_army_move_picker_cache.dart';
import '../caches/per_player_work_target_selection_cache.dart';
import 'province_detail_overlay_host_support.dart';
import 'province_detail_panel_slide_transition.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

/// Wide-layout province / sea zone panel; reads [mapProvincePanelProvider] only.
class GameMapProvinceDetailSidePanel extends ConsumerWidget {
  const GameMapProvinceDetailSidePanel({
    required this.game,
    required this.region,
    required this.humanPlayerId,
    required this.playerView,
    required this.workTargetSelectionCache,
    this.armyMovePickerCache,
    this.omniscientDetail = false,
    this.canMutateViaUi = true,
    super.key,
  });

  final ct_models.Game game;
  final RegionMapViewData region;
  final String humanPlayerId;
  final PlayerView playerView;
  final PerPlayerWorkTargetSelectionCache workTargetSelectionCache;
  final PerPlayerArmyMovePickerCache? armyMovePickerCache;
  final bool omniscientDetail;
  final bool canMutateViaUi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panel = ref.watch(
      mapProvincePanelProvider.select(mapProvinceDetailHostSlice),
    );
    final draftOrders = ref.watch(currentOrdersProvider);
    final displayId = resolveProvinceDetailDisplayId(
      region: region,
      tileKey: panel.selectedTileKey,
    );
    final showPanel = panel.overlayOpen && displayId.isNotEmpty;
    if (!showPanel) {
      if (kCtE2EEnabled) {
        updateCtE2eLastPanelSnapshotIfEnabled(null);
      }
      return ProvinceDetailPanelSlideTransition(
        visible: false,
        axis: ProvinceDetailPanelSlideAxis.end,
        child: const SizedBox.shrink(),
      );
    }
    if (kCtE2EEnabled && panel.selectedTileKey != null) {
      final mapData = tryGetGameMapData(
        () => ref.read(gameServiceProvider).getMapData(game.id),
      );
      updateCtE2eLastPanelSnapshotIfEnabled(
        CtE2eLastPanelSnapshot(
          game: game,
          region: region,
          displayId: displayId,
          selectedTileKey: panel.selectedTileKey!,
          humanPlayerId: humanPlayerId,
          playerView: playerView,
          draftOrders: draftOrders,
          topology: mapData?.combinedTopology,
          tileMapByRegion: mapData?.tileMapByRegion,
        ),
      );
    }
    final hostArgs = resolveProvinceDetailHostOverlayArgs(
      loadMapData: () => ref.read(gameServiceProvider).getMapData(game.id),
      panelNotifier: ref.read(mapProvincePanelProvider.notifier),
      bus: ref.read(appEventBusProvider),
    );
    Widget overlay = buildProvinceSeaZoneDetailOverlayForPanel(
      context: context,
      game: game,
      region: region,
      humanPlayerId: humanPlayerId,
      playerView: playerView,
      workTargetSelectionCache: workTargetSelectionCache,
      armyMovePickerCache: armyMovePickerCache,
      selectedTileKey: panel.selectedTileKey,
      draftOrders: draftOrders,
      mapData: hostArgs.mapData,
      canMutateViaUi: canMutateViaUi,
      omniscientDetail: omniscientDetail,
      onHighlightTile: hostArgs.onHighlightTile,
      onHighlightTiles: hostArgs.onHighlightTiles,
      onClose: hostArgs.onClose,
      bus: hostArgs.bus,
      readModelCache: ref.read(provinceOverlayReadModelCacheProvider),
      homeFleetCargo: ref.watch(homeFleetCargoSummaryProvider),
    );
    if (kCtE2EEnabled) {
      overlay = KeyedSubtree(key: kCtE2EProvincePanelRootKey, child: overlay);
    }
    return ProvinceDetailPanelSlideTransition(
      visible: true,
      axis: ProvinceDetailPanelSlideAxis.end,
      child: SizedBox(
        width: kGameMapWideProvinceSidePanelWidth,
        child: overlay,
      ),
    );
  }
}
