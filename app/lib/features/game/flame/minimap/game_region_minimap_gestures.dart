// Region minimap tap/pan bus emitters. SPEC/ui/empire-overview.md § Region minimap.
//
// De-parted wave-9 cluster (Refs #4117).

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'region_minimap_math.dart';

void gameRegionMinimapEmitTap({
  required RegionMapViewData region,
  required double cellSizePx,
  required AppEventBus bus,
  required Offset local,
  required Size mapSize,
}) {
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

void gameRegionMinimapEmitPan({
  required RegionMapViewData region,
  required double cellSizePx,
  required AppEventBus bus,
  required Offset delta,
  required Size mapSize,
}) {
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
