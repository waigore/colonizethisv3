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
import 'game_map_area_state_logic.dart';
import 'game_screen_shared.dart' show kGameMapWideProvinceSidePanelWidth;
import 'per_player_work_target_selection_cache.dart';
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
    if (!panel.overlayOpen) {
      if (kCtE2EEnabled) {
        updateCtE2eLastPanelSnapshotIfEnabled(null);
      }
      return const SizedBox.shrink();
    }
    final tileKey = panel.selectedTileKey;
    final displayId = tileKey == null || tileKey.isEmpty
        ? ''
        : (provinceDetailDisplayIdForPortHarborMapTile(
                    region: region,
                    tileKey: tileKey,
                  ) ??
                  displayProvinceOrSeaIdFromTileKey(tileKey)) ??
              '';
    if (displayId.isEmpty) {
      if (kCtE2EEnabled) {
        updateCtE2eLastPanelSnapshotIfEnabled(null);
      }
      return const SizedBox.shrink();
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
    final topology = mapData?.combinedTopology;
    final hiddenState = GameMapAreaStateLogic.kHiddenExplorerInlineActionState;
    final exploreState = panel.selectedTileKey == null
        ? hiddenState
        : GameMapAreaStateLogic.provinceExploreActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: panel.selectedTileKey!,
            selectedRegion: region,
            workTargetSelectionCache: workTargetSelectionCache,
          );
    final prospectState = panel.selectedTileKey == null
        ? hiddenState
        : GameMapAreaStateLogic.provinceProspectActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: panel.selectedTileKey!,
            playerView: playerView,
            topology: topology,
            currentOrders: draftOrders,
            tileMapByRegion: mapData?.tileMapByRegion,
          );
    final hiddenBuilderState =
        GameMapAreaStateLogic.kHiddenBuilderInlineActionState;
    final buildImprovementState = panel.selectedTileKey == null
        ? hiddenBuilderState
        : GameMapAreaStateLogic.provinceBuildImprovementActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: panel.selectedTileKey!,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
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
      onExploreWithExplorerTap:
          exploreState.enabled && panel.selectedTileKey != null
          ? () {
              final selectedTileKey = panel.selectedTileKey!;
              final revalidatedState =
                  GameMapAreaStateLogic.provinceExploreActionState(
                    game: game,
                    humanPlayerId: humanPlayerId,
                    selectedTileKey: selectedTileKey,
                    selectedRegion: region,
                    workTargetSelectionCache: workTargetSelectionCache,
                  );
              if (!revalidatedState.enabled) {
                return;
              }
              ref
                  .read(appEventBusProvider)
                  .emit(
                    ct_models.OpenCivilianUnitsPanelEvent(
                      explorerOnly: true,
                      exploreShortcutTargetTileKey: selectedTileKey,
                    ),
                  );
            }
          : null,
      onProspectWithExplorerTap:
          prospectState.enabled && panel.selectedTileKey != null
          ? () {
              final selectedTileKey = panel.selectedTileKey!;
              final revalidatedState =
                  GameMapAreaStateLogic.provinceProspectActionState(
                    game: game,
                    humanPlayerId: humanPlayerId,
                    selectedTileKey: selectedTileKey,
                    playerView: playerView,
                    topology: topology,
                    currentOrders: draftOrders,
                    tileMapByRegion: mapData?.tileMapByRegion,
                  );
              if (!revalidatedState.enabled) {
                return;
              }
              ref
                  .read(appEventBusProvider)
                  .emit(
                    ct_models.OpenCivilianUnitsPanelEvent(
                      explorerOnly: true,
                      prospectShortcutTargetTileKey: selectedTileKey,
                    ),
                  );
            }
          : null,
      onBuildImprovementTap:
          buildImprovementState.enabled && panel.selectedTileKey != null
          ? () {
              final selectedTileKey = panel.selectedTileKey!;
              final revalidatedState =
                  GameMapAreaStateLogic.provinceBuildImprovementActionState(
                    game: game,
                    humanPlayerId: humanPlayerId,
                    selectedTileKey: selectedTileKey,
                    playerView: playerView,
                    workTargetSelectionCache: workTargetSelectionCache,
                  );
              if (!revalidatedState.enabled) {
                return;
              }
              ref
                  .read(appEventBusProvider)
                  .emit(
                    ct_models.OpenCivilianUnitsPanelEvent(
                      builderOnly: true,
                      buildImprovementShortcutTargetTileKey: selectedTileKey,
                    ),
                  );
            }
          : null,
    );
    if (kCtE2EEnabled) {
      overlay = KeyedSubtree(key: kCtE2EProvincePanelRootKey, child: overlay);
    }
    return SizedBox(width: kGameMapWideProvinceSidePanelWidth, child: overlay);
  }
}
