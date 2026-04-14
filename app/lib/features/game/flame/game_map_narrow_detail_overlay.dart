import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart';

import '../../../../providers/games_provider.dart';
import '../../../../providers/map_province_panel_provider.dart';
import '../widgets/province_sea_zone_detail_overlay.dart';

/// Narrow-layout bottom sheet host; reads [mapProvincePanelProvider] only.
class GameMapNarrowDetailOverlaySlot extends ConsumerWidget {
  const GameMapNarrowDetailOverlaySlot({
    required this.game,
    required this.region,
    required this.humanPlayerId,
    required this.playerView,
    super.key,
  });

  final ct_models.Game game;
  final RegionMapViewData region;
  final String humanPlayerId;
  final PlayerView playerView;

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
      ),
    );
  }
}
