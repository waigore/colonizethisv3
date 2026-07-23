part of 'game_region_minimap.dart';

class _GameRegionMinimapVisiblePanel extends StatelessWidget {
  const _GameRegionMinimapVisiblePanel({
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
            _gameRegionMinimapEmitPan(
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
            onTapUp: (d) => _gameRegionMinimapEmitTap(
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
    );
  }
}
