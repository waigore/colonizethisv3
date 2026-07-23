import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../region_map/region_map_viewport_snapshot.dart'
    show RegionMapViewportSnapshot;
import '../../screens/game/game_screen_shared.dart';
import 'game_region_minimap.dart';
import 'game_region_minimap_painter.dart';
import 'region_minimap_math.dart';

class GameRegionMinimapVisiblePanel extends StatelessWidget {
  const GameRegionMinimapVisiblePanel({
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
        padding: const EdgeInsets.all(GameRegionMinimap.panelPadding),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerMove: (event) {
            if (!event.down || event.delta == Offset.zero) {
              return;
            }
            _emitPan(event.delta);
          },
          child: GestureDetector(
            key: kRegionMinimapGestureKey,
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _emitTap(d.localPosition),
            child: SizedBox(
              width: mapSize.width,
              height: mapSize.height,
              child: CustomPaint(
                key: kRegionMinimapCustomPaintKey,
                painter: GameRegionMinimapPainter(
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

  void _emitTap(Offset local) {
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

  void _emitPan(Offset delta) {
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
