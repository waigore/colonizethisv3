import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/ct_e2e.dart';
import '../../../../config/ct_e2e_last_panel_snapshot.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/map_province_panel_provider.dart';
import '../../../core/services/game_service.dart' show GameMapData;
import 'game_screen_shared.dart' show kGameMapWideProvinceSidePanelWidth;
import 'per_player_work_target_selection_cache.dart';
import 'province_action_state_calculator.dart';
import 'province_detail_overlay_host_support.dart';
import 'province_detail_panel_slide_transition.dart';
import '../widgets/province_sea_zone_detail_overlay.dart';

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
    final panel = ref.watch(mapProvincePanelProvider);
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
    GameMapData? mapData;
    try {
      mapData = ref.watch(gameServiceProvider).getMapData(game.id);
    } catch (_) {
      // Some widget tests render this panel without initializing persistence-backed providers.
      mapData = null;
    }
    final actionStates = ProvinceActionStateCalculator.compute(
      game: game,
      humanPlayerId: humanPlayerId,
      selectedTileKey: panel.selectedTileKey,
      region: region,
      playerView: playerView,
      currentOrders: draftOrders,
      workTargetSelectionCache: workTargetSelectionCache,
      mapData: mapData,
    );
    final exploreState = actionStates.explore;
    final prospectState = actionStates.prospect;
    final buildImprovementState = actionStates.buildImprovement;
    final shortcuts = buildProvinceDetailShortcutCallbacks(
      game: game,
      humanPlayerId: humanPlayerId,
      region: region,
      playerView: playerView,
      workTargetSelectionCache: workTargetSelectionCache,
      draftOrders: draftOrders,
      mapData: mapData,
      selectedTileKey: panel.selectedTileKey,
      exploreEnabled: exploreState.enabled,
      prospectEnabled: prospectState.enabled,
      buildImprovementEnabled: buildImprovementState.enabled,
      bus: ref.read(appEventBusProvider),
    );
    Widget overlay = ProvinceSeaZoneDetailOverlay(
      game: game,
      region: region,
      displayId: displayId,
      selectedTileKey: panel.selectedTileKey,
      humanPlayerId: humanPlayerId,
      playerView: playerView,
      draftOrders: draftOrders,
      onHighlightTile: (k) =>
          ref.read(mapProvincePanelProvider.notifier).setSecondaryHighlight(k),
      onClose: () => ref.read(mapProvincePanelProvider.notifier).closeOverlay(),
      showProspectActionIcon: canMutateViaUi && prospectState.showIcon,
      prospectActionEnabled: canMutateViaUi && prospectState.enabled,
      showExploreActionIcon: canMutateViaUi && exploreState.showIcon,
      exploreActionEnabled: canMutateViaUi && exploreState.enabled,
      showBuildImprovementActionIcon:
          canMutateViaUi && buildImprovementState.showIcon,
      buildImprovementActionEnabled:
          canMutateViaUi && buildImprovementState.enabled,
      omniscientDetail: omniscientDetail,
      onExploreWithExplorerTap: shortcuts.onExploreWithExplorerTap,
      onProspectWithExplorerTap: shortcuts.onProspectWithExplorerTap,
      onBuildImprovementTap: shortcuts.onBuildImprovementTap,
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
