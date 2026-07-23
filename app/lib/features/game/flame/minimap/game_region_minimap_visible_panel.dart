// Region minimap grid panel + pointer chrome.
// SPEC/ui/empire-overview.md § Region minimap.
//
// De-parted wave-9 cluster (Refs #4117).

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../screens/game/game_screen_shared.dart'
    show kRegionMinimapCustomPaintKey, kRegionMinimapGestureKey;
import '../region_map/region_map_viewport_snapshot.dart'
    show RegionMapViewportSnapshot;
import 'game_region_minimap_constants.dart';
import 'game_region_minimap_gestures.dart';
import 'game_region_minimap_painter.dart';

class GameRegionMinimapVisiblePanel extends StatelessWidget {
  const GameRegionMinimapVisiblePanel({
    super.key,
    required this.region,
    required this.cellSizePx,
    required this.bus,
    required this.mapSize,
    required this.viewport,
  });

  final RegionMapViewData region;
  final double cellSizePx;
  final AppEventBus bus;
  final Size mapSize;
  final RegionMapViewportSnapshot? viewport;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.bgDeep,
        border: Border.all(
          color: EditorialMonoclePalette.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kGameRegionMinimapPanelPadding),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerMove: (event) {
            if (!event.down || event.delta == Offset.zero) {
              return;
            }
            gameRegionMinimapEmitPan(
              region: region,
              cellSizePx: cellSizePx,
              bus: bus,
              delta: event.delta,
              mapSize: mapSize,
            );
          },
          child: GestureDetector(
            key: kRegionMinimapGestureKey,
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => gameRegionMinimapEmitTap(
              region: region,
              cellSizePx: cellSizePx,
              bus: bus,
              local: d.localPosition,
              mapSize: mapSize,
            ),
            child: SizedBox(
              width: mapSize.width,
              height: mapSize.height,
              child: CustomPaint(
                key: kRegionMinimapCustomPaintKey,
                painter: RegionMinimapPainter(
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
    );
  }
}
