import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_assets.dart';
import '../../../../config/editorial_monocle_palette.dart';
import '../../../../providers/region_minimap_provider.dart';
import '../region_map/region_map_viewport_snapshot.dart'
    show
        RegionMapViewportSnapshot,
        kRegionMapZoomMultiplierMax,
        kRegionMapZoomMultiplierMin;
import '../../../../widgets/ct_slider.dart';
import '../../../../widgets/strict_asset_icon.dart';
import '../../screens/game/game_screen_shared.dart';
import 'region_minimap_math.dart';

part 'game_region_minimap_controls.dart';
part 'game_region_minimap_painter.dart';

/// Dismissible region minimap (Empire overview). SPEC/ui/empire-overview.md § Region minimap.
///
/// [cellSizePx] must match [RegionMapViewData.cellSize] used by the Flame-backed region map for this
/// region so world↔minimap math matches [RegionMapViewportSnapshot] (see SPEC/ui/map-widget.md).
///
/// Narrow layout (issue #2870 S3, `MediaQuery.size.width < kNarrowBreakpoint`):
/// the host constructs this widget with `narrow: true`. The minimap grid then
/// fits the active region's aspect ratio into a 90 × 70 dp box per
/// `SPEC/ui/mobile-adaptation.md` § In-game shell and the
/// `.minimap-panel @media (max-width:600px)` rule in
/// `SPEC/ui/mockups/GAME10001-game-screen.html`. Wide chrome (corner-control
/// brackets, panel padding, toggle button, zoom slider) is unchanged.
class GameRegionMinimap extends ConsumerWidget {
  const GameRegionMinimap({
    required this.region,
    required this.viewportSnapshot,
    required this.bus,
    this.cellSizePx = 24,
    this.narrow = false,
    super.key,
  });

  final RegionMapViewData region;
  final RegionMapViewportSnapshot? viewportSnapshot;
  final AppEventBus bus;
  final double cellSizePx;

  /// When true, fit the grid into the narrow 90 × 70 dp box per
  /// `SPEC/ui/mobile-adaptation.md` § In-game shell (issue #2870 S3).
  /// When false (default), preserve the wide-layout behavior of capping
  /// the longer aspect side at [defaultMaxExtent].
  final bool narrow;

  /// Long-side cap in dp for the minimap grid under the wide / desktop
  /// layout. Preserves the pre-#2870 baseline so default-layout
  /// regression tests keep their existing dimensions.
  @visibleForTesting
  static const double defaultMaxExtent = 132;

  /// Width cap in dp for the minimap grid under narrow chrome. Mirrors
  /// the canonical measurement in `SPEC/ui/mobile-adaptation.md` §
  /// In-game shell ("90 × 70 dp") and the mockup
  /// `.minimap-panel @media (max-width:600px)` rule.
  @visibleForTesting
  static const double narrowMaxWidth = 90;

  /// Height cap in dp for the minimap grid under narrow chrome. Mirrors
  /// the canonical measurement in `SPEC/ui/mobile-adaptation.md` §
  /// In-game shell ("90 × 70 dp") and the mockup
  /// `.minimap-panel @media (max-width:600px)` rule.
  @visibleForTesting
  static const double narrowMaxHeight = 70;

  /// Computes the inner [CustomPaint] grid size for a region of the given
  /// `aspect` ratio (`region.width / region.height`) under the wide or
  /// narrow chrome. Visible for testing so the SPEC's 90 × 70 dp bounding
  /// box and the wide regression baseline can be pinned without pumping
  /// the full widget tree.
  @visibleForTesting
  static Size computeMapSize({required double aspect, required bool narrow}) {
    if (narrow) {
      final boxAspect = narrowMaxWidth / narrowMaxHeight;
      if (aspect >= boxAspect) {
        return Size(narrowMaxWidth, narrowMaxWidth / aspect);
      }
      return Size(narrowMaxHeight * aspect, narrowMaxHeight);
    }
    if (aspect >= 1) {
      return Size(defaultMaxExtent, defaultMaxExtent / aspect);
    }
    return Size(defaultMaxExtent * aspect, defaultMaxExtent);
  }

  /// Internal padding between the dark editorial-monocle minimap panel border
  /// and the [CustomPaint] grid. Matches mockup `.minimap-panel { padding:2px }`
  /// (`SPEC/ui/mockups/GAME10001-game-screen.html`). Unchanged at narrow —
  /// the panel padding is part of the chrome, not the grid box.
  static const double panelPadding = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(regionMinimapVisibleProvider);
    final viewport = viewportSnapshot?.regionId == region.regionId
        ? viewportSnapshot
        : null;
    final aspect = region.width / region.height;
    final mapSize = computeMapSize(aspect: aspect, narrow: narrow);

    final zoomMultiplier = viewport == null
        ? 1.0
        : viewport.zoomMultiplier.clamp(
            kRegionMapZoomMultiplierMin,
            kRegionMapZoomMultiplierMax,
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (visible) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: EditorialMonoclePalette.bgDeep,
              border: Border.all(
                color: EditorialMonoclePalette.border,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(panelPadding),
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerMove: (event) {
                  if (!event.down || event.delta == Offset.zero) {
                    return;
                  }
                  _onPan(delta: event.delta, mapSize: mapSize);
                },
                child: GestureDetector(
                  key: kRegionMinimapGestureKey,
                  behavior: HitTestBehavior.opaque,
                  // Tap-up avoids a center event at pointer-down (which interfered with drags).
                  onTapUp: (d) =>
                      _onTap(local: d.localPosition, mapSize: mapSize),
                  child: SizedBox(
                    width: mapSize.width,
                    height: mapSize.height,
                    child: CustomPaint(
                      key: kRegionMinimapCustomPaintKey,
                      painter: _RegionMinimapPainter(
                        region: region,
                        cellSizePx: cellSizePx,
                        viewport: viewport?.regionId == region.regionId
                            ? viewport
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
        _MinimapZoomControls(
          regionId: region.regionId,
          bus: bus,
          viewportMultiplier: zoomMultiplier,
          trackWidth: mapSize.width,
          theme: Theme.of(context),
          trailing: _MinimapToggleButton(
            visible: visible,
            onTap: () =>
                ref.read(regionMinimapVisibleProvider.notifier).toggle(),
          ),
        ),
      ],
    );
  }

  void _onTap({required Offset local, required Size mapSize}) {
    final mw = region.width * cellSizePx;
    final mh = region.height * cellSizePx;
    final world = minimapLocalToWorldCenter(
      localOnMinimap: local,
      minimapSize: mapSize,
      mapWidthWorld: mw,
      mapHeightWorld: mh,
    );
    bus.emit(
      RequestRegionMapCameraCenterWorldEvent(
        regionId: region.regionId,
        worldCenterX: world.dx,
        worldCenterY: world.dy,
      ),
    );
  }

  void _onPan({required Offset delta, required Size mapSize}) {
    final mw = region.width * cellSizePx;
    final mh = region.height * cellSizePx;
    final w = minimapDeltaToWorldDelta(
      minimapDelta: delta,
      minimapSize: mapSize,
      mapWidthWorld: mw,
      mapHeightWorld: mh,
    );
    bus.emit(
      RequestRegionMapCameraPanWorldDeltaEvent(
        regionId: region.regionId,
        worldDx: w.dx,
        worldDy: w.dy,
      ),
    );
  }
}
