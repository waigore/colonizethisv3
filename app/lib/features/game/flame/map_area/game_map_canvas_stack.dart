import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart' show RegionMapViewData;

import '../../../../providers/games_provider.dart';
import '../../../../providers/map_province_panel_provider.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import '../region_map/region_map_component.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode;
import '../../../../widgets/ct_region_map.dart' show CtRegionMap;

import '../overlays/game_map_province_detail_side_panel.dart';
import 'game_map_canvas_stack_selection_prompt.dart';
import '../caches/per_player_work_target_selection_cache.dart';
import '../region_map/region_map_viewport_snapshot.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

/// Compact minimum tap-target height applied to the selection-prompt
/// banner's `cancel` [CtNinePatchButton]. Pinned to keep the inline
/// affordance vertically proportional to the surrounding banner row
/// (banner padding is 8 logical px vertical) without inflating the prompt
/// to the catalog default 48 dp button. SPEC: `SPEC/ui/map-widget.md`
/// § Dark-theme selection prompt overlay tokens.
const double kMapSelectionPromptCancelMinHeight = 34;

/// Canonical alpha applied to [EditorialMonoclePalette.bgDeep] for the
/// work-target selection prompt overlay banner background. Pinned at
/// `0.85` per `SPEC/ui/map-widget.md` § Dark-theme selection prompt overlay
/// tokens so the banner reads as a framed dark surface against the lit
/// map while still allowing terrain to glimmer through.
const double kMapSelectionPromptBackgroundAlpha = 0.85;

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
    required this.workTargetSelectionCache,
    required this.centerOnTileKey,
    required this.validTileKeysForSelection,
    required this.onTileSelectedForWork,
    required this.onWorkTargetSelectionCancelled,
    required this.selectedCivilianTileKey,
    this.selectionPromptUsesRelocateCopy = false,
    this.workTargetForSelection,
    this.hoveredWorkTargetTileKey,
    this.lastValidHoveredWorkTargetTileKey,
    this.onWorkTargetTileHovered,
    required this.onCivilianTileStateChanged,
    required this.onCivilianTileSelectionCleared,
    required this.onRegionViewportSnapshot,
    required this.zoomMultiplier,
    this.visibilityMode = CtMapVisibilityMode.playerConstrained,
    this.omniscientDetail = false,
    this.canMutateViaUi = true,
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
  final PerPlayerWorkTargetSelectionCache workTargetSelectionCache;
  final String? centerOnTileKey;
  final Set<String>? validTileKeysForSelection;

  final void Function(String tileKey)? onTileSelectedForWork;
  final VoidCallback? onWorkTargetSelectionCancelled;
  final bool selectionPromptUsesRelocateCopy;
  final String? workTargetForSelection;
  final String? hoveredWorkTargetTileKey;
  final String? lastValidHoveredWorkTargetTileKey;
  final void Function(String? tileKey)? onWorkTargetTileHovered;
  final String? selectedCivilianTileKey;
  final void Function(String tileKey)? onCivilianTileStateChanged;
  final VoidCallback? onCivilianTileSelectionCleared;
  final void Function(RegionMapViewportSnapshot snapshot)
  onRegionViewportSnapshot;
  final double zoomMultiplier;
  final CtMapVisibilityMode visibilityMode;
  final bool omniscientDetail;
  final bool canMutateViaUi;
  final ct_models.AppEventBus? bus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Narrow to map highlight fields so overlayOpen-only Chrome updates do not
    // rebuild the Flame host (Refs #4018).
    final highlights = ref.watch(
      mapProvincePanelProvider.select(mapCanvasHighlightSlice),
    );
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
                  visibilityMode: visibilityMode,
                  playerViewForResources:
                      visibilityMode == CtMapVisibilityMode.playerConstrained
                      ? playerView
                      : null,
                  baseLayerDisplayMode: baseLayerDisplayMode,
                  onProvinceSelected: null,
                  onMapTileTappedForDetail: inWorkTargetSelectionMode
                      ? null
                      : (tk) => ref
                            .read(mapProvincePanelProvider.notifier)
                            .reportMapTileTapped(tk),
                  onProvinceHovered: (_) {},
                  onTileHovered: inWorkTargetSelectionMode
                      ? onWorkTargetTileHovered
                      : (_) {},
                  onCivilianTileStateChanged: inWorkTargetSelectionMode
                      ? null
                      : onCivilianTileStateChanged,
                  onCivilianTileSelectionCleared: inWorkTargetSelectionMode
                      ? null
                      : onCivilianTileSelectionCleared,
                  selectedTileKey: highlights.selectedTileKey,
                  selectedCivilianTileKey: selectedCivilianTileKey,
                  secondaryHighlightTileKey:
                      highlights.secondaryHighlightTileKey,
                  secondaryHighlightTileKeys:
                      highlights.secondaryHighlightTileKeys,
                  centerOnTileKey: centerOnTileKey,
                  validTileKeys: validTileKeysForSelection,
                  onTileSelected: onTileSelectedForWork,
                  onWorkTargetSelectionCancelled:
                      onWorkTargetSelectionCancelled,
                  bus: inWorkTargetSelectionMode ? null : bus,
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
                  omniscientDetail: omniscientDetail,
                  canMutateViaUi: canMutateViaUi,
                  workTargetSelectionCache: workTargetSelectionCache,
                ),
            ],
          ),
          if (inWorkTargetSelectionMode)
            Consumer(
              builder: (context, ref, _) {
                final overlayOpen = ref.watch(
                  mapProvincePanelProvider.select((s) => s.overlayOpen),
                );
                final orders = ref.watch(currentOrdersProvider);
                final previewTileKey =
                    hoveredWorkTargetTileKey ??
                    lastValidHoveredWorkTargetTileKey;
                final workTarget = workTargetForSelection;
                final affordPreview =
                    workTarget != null &&
                        previewTileKey != null &&
                        !selectionPromptUsesRelocateCopy
                    ? previewWorkOrderAffordAtTile(
                        game: game,
                        playerId: humanPlayerId,
                        currentOrders: orders,
                        workTarget: workTarget,
                        targetTileKey: previewTileKey,
                      )
                    : null;
                return GameMapCanvasStackSelectionPrompt(
                  isNarrow: isNarrow,
                  overlayOpen: overlayOpen,
                  onCancel: onWorkTargetSelectionCancelled,
                  usesRelocateCopy: selectionPromptUsesRelocateCopy,
                  affordPreview: affordPreview,
                );
              },
            ),
        ],
      ),
    );
  }
}
