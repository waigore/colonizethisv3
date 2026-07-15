import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/map_province_panel_provider.dart';
import '../../screens/game/game_screen_shared.dart' show kGameMapWideProvinceSidePanelWidth;
import '../caches/per_player_work_target_selection_cache.dart';
import 'province_detail_overlay_host_support.dart';
import 'province_detail_panel_slide_transition.dart';

/// Wide-layout province / sea zone panel; reads [mapProvincePanelProvider] only.
class GameMapProvinceDetailSidePanel extends ConsumerWidget {
  const GameMapProvinceDetailSidePanel({
    required this.game,
    required this.region,
    required this.humanPlayerId,
    required this.playerView,
    required this.workTargetSelectionCache,
    this.omniscientDetail = false,
    this.canMutateViaUi = true,
    super.key,
  });

  final ct_models.Game game;
  final RegionMapViewData region;
  final String humanPlayerId;
  final PlayerView playerView;
  final PerPlayerWorkTargetSelectionCache workTargetSelectionCache;
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
      updateCtE2eLastPanelSnapshotIfEnabled(
        CtE2eLastPanelSnapshot(
          game: game,
          region: region,
          displayId: displayId,
          selectedTileKey: panel.selectedTileKey!,
          humanPlayerId: humanPlayerId,
          playerView: playerView,
          draftOrders: draftOrders,
        ),
      );
    }
    final hostArgs = resolveProvinceDetailHostOverlayArgs(
      ref: ref,
      gameId: game.id,
    );
    Widget overlay = buildProvinceSeaZoneDetailOverlayForPanel(
      game: game,
      region: region,
      humanPlayerId: humanPlayerId,
      playerView: playerView,
      workTargetSelectionCache: workTargetSelectionCache,
      selectedTileKey: panel.selectedTileKey,
      draftOrders: draftOrders,
      mapData: hostArgs.mapData,
      canMutateViaUi: canMutateViaUi,
      omniscientDetail: omniscientDetail,
      onHighlightTile: hostArgs.onHighlightTile,
      onHighlightTiles: hostArgs.onHighlightTiles,
      onClose: hostArgs.onClose,
      bus: hostArgs.bus,
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
