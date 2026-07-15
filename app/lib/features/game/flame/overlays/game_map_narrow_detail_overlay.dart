import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart';

import '../../../../providers/games_provider.dart';
import '../../../../providers/map_province_panel_provider.dart';
import '../caches/per_player_work_target_selection_cache.dart';
import 'province_detail_overlay_host_support.dart';
import 'province_detail_panel_slide_transition.dart';

/// Narrow-layout bottom sheet host; reads [mapProvincePanelProvider] only.
///
/// When the panel is open and a non-empty `displayId` resolves, the slot
/// mounts [ProvinceSeaZoneDetailOverlay] inside a single `SizedBox` whose
/// height is fixed at `0.33 * MediaQuery.sizeOf(context).height` and whose
/// width is [double.infinity] so the host
/// `Align(alignment: Alignment.bottomCenter)` + `Column(mainAxisSize: MainAxisSize.min)`
/// in `GameMapArea` (narrow) lets the overlay span the full viewport — the
/// **Province / sea detail** row of `SPEC/ui/mobile-adaptation.md` § 4 calls
/// for a *full-width bottom sheet, height ~33 vh, accent-dim top border*.
/// The accent-dim top border is provided by the nested overlay's outer
/// `CtPanel` chrome (`SPEC/ui/pixel-art-ui-catalog.md` § CtPanel) so the slot
/// does not paint its own border.
class GameMapNarrowDetailOverlaySlot extends ConsumerWidget {
  const GameMapNarrowDetailOverlaySlot({
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
      return ProvinceDetailPanelSlideTransition(
        visible: false,
        axis: ProvinceDetailPanelSlideAxis.bottom,
        child: const SizedBox.shrink(),
      );
    }
    final hostArgs = resolveProvinceDetailHostOverlayArgs(
      ref: ref,
      gameId: game.id,
    );
    final overlay = SizedBox(
      width: double.infinity,
      height: MediaQuery.sizeOf(context).height * 0.33,
      child: buildProvinceSeaZoneDetailOverlayForPanel(
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
      ),
    );
    return ProvinceDetailPanelSlideTransition(
      visible: true,
      axis: ProvinceDetailPanelSlideAxis.bottom,
      child: overlay,
    );
  }
}
