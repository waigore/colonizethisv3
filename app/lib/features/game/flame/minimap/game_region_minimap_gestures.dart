part of 'game_region_minimap.dart';

void _gameRegionMinimapEmitTap({
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

void _gameRegionMinimapEmitPan({
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
