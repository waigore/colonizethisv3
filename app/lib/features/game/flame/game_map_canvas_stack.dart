import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart' show RegionMapViewData;

import '../../../../providers/map_province_panel_provider.dart';
import '../../../../widgets/ct_region_map.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode, CtRegionMap;

import 'game_map_province_detail_side_panel.dart';

/// Renders the Flame-backed map and the wide right-side detail panel.
/// Map and panel communicate only via [mapProvincePanelProvider].
class GameMapCanvasStack extends ConsumerWidget {
  const GameMapCanvasStack({
    required this.isNarrow,
    required this.game,
    required this.region,
    required this.baseLayerDisplayMode,
    required this.showBordersLayer,
    required this.showProvinceNamesLayer,
    required this.humanPlayerId,
    required this.playerView,
    required this.centerOnTileKey,
    required this.validTileKeysForSelection,
    required this.onTileSelectedForWork,
    required this.onWorkTargetSelectionCancelled,
    this.bus,
    super.key,
  });

  final bool isNarrow;
  final ct_models.Game game;
  final RegionMapViewData region;
  final BaseLayerDisplayMode baseLayerDisplayMode;
  final bool showBordersLayer;
  final bool showProvinceNamesLayer;
  final String humanPlayerId;
  final PlayerView playerView;
  final String? centerOnTileKey;
  final Set<String>? validTileKeysForSelection;

  final void Function(String tileKey)? onTileSelectedForWork;
  final VoidCallback? onWorkTargetSelectionCancelled;
  final ct_models.AppEventBus? bus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panel = ref.watch(mapProvincePanelProvider);
    final inWorkTargetSelectionMode = validTileKeysForSelection != null;
    return Positioned.fill(
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: CtRegionMap(
                  region: region,
                  cellSizePx: 24,
                  showBordersLayer: showBordersLayer,
                  showProvinceNamesLayer: showProvinceNamesLayer,
                  visibilityMode: CtMapVisibilityMode.playerConstrained,
                  playerViewForResources: playerView,
                  baseLayerDisplayMode: baseLayerDisplayMode,
                  onProvinceSelected: null,
                  onMapTileTappedForDetail: inWorkTargetSelectionMode
                      ? null
                      : (tk) => ref
                            .read(mapProvincePanelProvider.notifier)
                            .reportMapTileTapped(tk),
                  onProvinceHovered: (_) {},
                  onTileHovered: (_) {},
                  selectedTileKey: panel.selectedTileKey,
                  secondaryHighlightTileKey: panel.secondaryHighlightTileKey,
                  centerOnTileKey: centerOnTileKey,
                  validTileKeys: validTileKeysForSelection,
                  onTileSelected: onTileSelectedForWork,
                  onWorkTargetSelectionCancelled:
                      onWorkTargetSelectionCancelled,
                  bus: bus,
                ),
              ),
              if (!isNarrow)
                GameMapProvinceDetailSidePanel(
                  game: game,
                  region: region,
                  humanPlayerId: humanPlayerId,
                  playerView: playerView,
                ),
            ],
          ),
          if (inWorkTargetSelectionMode)
            Positioned(
              top: 8,
              right: isNarrow ? 8 : 328,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onWorkTargetSelectionCancelled,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
