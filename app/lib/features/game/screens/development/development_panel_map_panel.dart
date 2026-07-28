import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/region_map/region_map_widget_bindings.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../widgets/ct_region_map.dart';

/// Pannable region map for the Development panel with multi-tile highlight.
class DevelopmentPanelMapPanel extends ConsumerWidget {
  const DevelopmentPanelMapPanel({
    super.key,
    required this.game,
    required this.regionId,
    this.highlightTileKeys,
  });

  final Game game;
  final String regionId;
  final Set<String>? highlightTileKeys;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    if (mapData == null) {
      return const SizedBox.shrink();
    }

    final viewData = buildInitGameMapViewData(
      game: game,
      tileMapByRegion: mapData.tileMapByRegion,
      topologyByRegion: mapData.topologyByRegion,
      cellSize: 12,
    );
    final region = regionId == kRegionNewWorld
        ? viewData.newWorld
        : viewData.oldWorld;

    return CtRegionMap(
      region: region,
      showPoliticalOverlay: true,
      showProvinceOverlay: false,
      showProvinceNamesLayer: false,
      cellSizePx: 12,
      visibilityMode: CtMapVisibilityMode.full,
      secondaryHighlightTileKeys: highlightTileKeys,
    );
  }
}
