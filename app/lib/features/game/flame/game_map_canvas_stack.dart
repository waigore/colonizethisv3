import 'package:flutter/material.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart' show RegionMapViewData;

import '../../../../widgets/ct_region_map.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode, CtRegionMap;

import '../widgets/province_sea_zone_detail_overlay.dart';

/// Renders the Flame-backed map and the wide right-side detail overlay.
class GameMapCanvasStack extends StatelessWidget {
  const GameMapCanvasStack({
    required this.isNarrow,
    required this.game,
    required this.region,
    required this.baseLayerDisplayMode,
    required this.showBordersLayer,
    required this.showProvinceNamesLayer,
    required this.humanPlayerId,
    required this.playerView,
    required this.selectedDetailId,
    required this.displayId,
    required this.hoveredTileKey,
    required this.highlightedTileKey,
    required this.centerOnTileKey,
    required this.validTileKeysForSelection,
    required this.onProvinceSelected,
    required this.onProvinceHovered,
    required this.onTileHovered,
    required this.onTileSelectedForWork,
    required this.onWorkTargetSelectionCancelled,
    required this.onHighlightTile,
    required this.onCloseDetailOverlay,
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
  final String? selectedDetailId;
  final String displayId;
  final String? hoveredTileKey;
  final String? highlightedTileKey;
  final String? centerOnTileKey;
  final Set<String>? validTileKeysForSelection;

  final void Function(String provinceId) onProvinceSelected;
  final void Function(String? provinceId) onProvinceHovered;
  final void Function(String? tileKey) onTileHovered;

  final void Function(String tileKey)? onTileSelectedForWork;
  final VoidCallback? onWorkTargetSelectionCancelled;

  final void Function(String?) onHighlightTile;
  final VoidCallback onCloseDetailOverlay;

  @override
  Widget build(BuildContext context) {
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
                  baseLayerDisplayMode: baseLayerDisplayMode,
                  onProvinceSelected: onProvinceSelected,
                  onProvinceHovered: onProvinceHovered,
                  onTileHovered: onTileHovered,
                  highlightedTileKey: highlightedTileKey,
                  centerOnTileKey: centerOnTileKey,
                  validTileKeys: validTileKeysForSelection,
                  onTileSelected: onTileSelectedForWork,
                  onWorkTargetSelectionCancelled:
                      onWorkTargetSelectionCancelled,
                ),
              ),
              if (!isNarrow && selectedDetailId != null)
                SizedBox(
                  width: 320,
                  child: ProvinceSeaZoneDetailOverlay(
                    game: game,
                    region: region,
                    selectedId: selectedDetailId!,
                    displayId: displayId,
                    humanPlayerId: humanPlayerId,
                    playerView: playerView,
                    hoveredTileKey: hoveredTileKey,
                    onHighlightTile: (k) => onHighlightTile(k),
                    onClose: onCloseDetailOverlay,
                  ),
                ),
            ],
          ),
          // Cancel button overlay for work target selection mode.
          // SPEC/ui/map-widget.md § Work target selection mode.
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
