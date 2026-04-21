import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart' show RegionMapViewData;

import '../../../../providers/map_province_panel_provider.dart';
import '../../../../widgets/ct_region_map.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode, CtRegionMap;

import 'game_map_province_detail_side_panel.dart';
import 'region_map_viewport_snapshot.dart';

/// Renders the Flame-backed map and the wide right-side detail panel.
/// Map and panel communicate only via [mapProvincePanelProvider].
class GameMapCanvasStack extends ConsumerWidget {
  const GameMapCanvasStack({
    required this.isNarrow,
    required this.game,
    required this.region,
    required this.baseLayerDisplayMode,
    required this.showProvinceOverlay,
    required this.showProvinceOwnershipTint,
    required this.showProvinceNamesLayer,
    required this.humanPlayerId,
    required this.playerView,
    required this.centerOnTileKey,
    required this.validTileKeysForSelection,
    required this.onTileSelectedForWork,
    required this.onWorkTargetSelectionCancelled,
    required this.selectedCivilianTileKey,
    required this.onCivilianTileTapped,
    this.onFleetMarkerTapped,
    required this.onCivilianTileSelectionCleared,
    required this.onRegionViewportSnapshot,
    required this.zoomMultiplier,
    this.bus,
    super.key,
  });

  final bool isNarrow;
  final ct_models.Game game;
  final RegionMapViewData region;
  final BaseLayerDisplayMode baseLayerDisplayMode;
  final bool showProvinceOverlay;
  final bool showProvinceOwnershipTint;
  final bool showProvinceNamesLayer;
  final String humanPlayerId;
  final PlayerView playerView;
  final String? centerOnTileKey;
  final Set<String>? validTileKeysForSelection;

  final void Function(String tileKey)? onTileSelectedForWork;
  final VoidCallback? onWorkTargetSelectionCancelled;
  final String? selectedCivilianTileKey;
  final void Function(String tileKey)? onCivilianTileTapped;
  final void Function(
    String locationScopeKey,
    String? initialFleetId,
    String markerTileKey,
  )?
  onFleetMarkerTapped;
  final VoidCallback? onCivilianTileSelectionCleared;
  final void Function(RegionMapViewportSnapshot snapshot)
  onRegionViewportSnapshot;
  final double zoomMultiplier;
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
                  cellSizePx: region.cellSize.toDouble(),
                  showProvinceOverlay: showProvinceOverlay,
                  showProvinceOwnershipTint: showProvinceOwnershipTint,
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
                  onCivilianTileTapped: inWorkTargetSelectionMode
                      ? null
                      : onCivilianTileTapped,
                  onFleetMarkerTapped: inWorkTargetSelectionMode
                      ? null
                      : onFleetMarkerTapped,
                  onCivilianTileSelectionCleared: inWorkTargetSelectionMode
                      ? null
                      : onCivilianTileSelectionCleared,
                  selectedTileKey: panel.selectedTileKey,
                  selectedCivilianTileKey: selectedCivilianTileKey,
                  secondaryHighlightTileKey: panel.secondaryHighlightTileKey,
                  centerOnTileKey: centerOnTileKey,
                  validTileKeys: validTileKeysForSelection,
                  onTileSelected: onTileSelectedForWork,
                  onWorkTargetSelectionCancelled:
                      onWorkTargetSelectionCancelled,
                  bus: bus,
                  onViewportSnapshotChanged: onRegionViewportSnapshot,
                  zoomMultiplier: zoomMultiplier,
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
              left: 0,
              right: !isNarrow && panel.overlayOpen ? 320 : 0,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Select a tile, or click cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: onWorkTargetSelectionCancelled,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'cancel',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
