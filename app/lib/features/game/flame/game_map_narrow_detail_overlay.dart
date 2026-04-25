import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart';

import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/map_province_panel_provider.dart';
import 'game_map_area_state_logic.dart';
import '../widgets/province_sea_zone_detail_overlay.dart';

/// Narrow-layout bottom sheet host; reads [mapProvincePanelProvider] only.
class GameMapNarrowDetailOverlaySlot extends ConsumerWidget {
  const GameMapNarrowDetailOverlaySlot({
    required this.game,
    required this.region,
    required this.humanPlayerId,
    required this.playerView,
    required this.exploreEligibleTileKeyCache,
    super.key,
  });

  final ct_models.Game game;
  final RegionMapViewData region;
  final String humanPlayerId;
  final PlayerView playerView;
  final Set<String> exploreEligibleTileKeyCache;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panel = ref.watch(mapProvincePanelProvider);
    final draftOrders = ref.watch(currentOrdersProvider);
    if (!panel.overlayOpen) {
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
      return const SizedBox.shrink();
    }
    dynamic mapData;
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
            cachedExploreEligibleTileKeys: exploreEligibleTileKeyCache,
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
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.33,
      child: ProvinceSeaZoneDetailOverlay(
        game: game,
        region: region,
        displayId: displayId,
        selectedTileKey: panel.selectedTileKey,
        humanPlayerId: humanPlayerId,
        playerView: playerView,
        draftOrders: draftOrders,
        onHighlightTile: (k) => ref
            .read(mapProvincePanelProvider.notifier)
            .setSecondaryHighlight(k),
        onClose: () =>
            ref.read(mapProvincePanelProvider.notifier).closeOverlay(),
        showProspectActionIcon: prospectState.showIcon,
        prospectActionEnabled: prospectState.enabled,
        showExploreActionIcon: exploreState.showIcon,
        exploreActionEnabled: exploreState.enabled,
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
                      cachedExploreEligibleTileKeys:
                          exploreEligibleTileKeyCache,
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
      ),
    );
  }
}
