import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_assets.dart';
import '../../../providers/region_minimap_provider.dart';
import 'region_map_viewport_snapshot.dart'
    show
        RegionMapViewportSnapshot,
        kRegionMapZoomMultiplierMax,
        kRegionMapZoomMultiplierMin;
import '../../../widgets/strict_asset_icon.dart';
import 'game_screen_shared.dart';
import 'region_minimap_math.dart';

/// Terrain base colors for the region minimap (flat fills). SPEC/ui/empire-overview.md § Region minimap.
const Map<TerrainType, Color> kRegionMinimapTerrainColors = {
  TerrainType.plains: Color(0xFFA5D6A7),
  TerrainType.forest: Color(0xFF2E7D32),
  TerrainType.hills: Color(0xFFB0BEC5),
  TerrainType.mountain: Color(0xFF546E7A),
  TerrainType.swamp: Color(0xFF6D4C41),
  TerrainType.desert: Color(0xFFD7CCC8),
};

/// Deep sea fill when [CellViewData.isSea] is true.
const Color kRegionMinimapSeaColor = Color(0xFF0D47A1);

/// Opacity for fogged tiles (terrain still visible underneath per SPEC).
const double kRegionMinimapFoggedAlpha = 0.55;

/// Dismissible region minimap (Empire overview). SPEC/ui/empire-overview.md § Region minimap.
///
/// [cellSizePx] must match [RegionMapViewData.cellSize] used by the Flame-backed region map for this
/// region so world↔minimap math matches [RegionMapViewportSnapshot] (see SPEC/ui/map-widget.md).
class GameRegionMinimap extends ConsumerWidget {
  const GameRegionMinimap({
    required this.region,
    required this.viewportSnapshot,
    required this.bus,
    this.cellSizePx = 24,
    super.key,
  });

  final RegionMapViewData region;
  final RegionMapViewportSnapshot? viewportSnapshot;
  final AppEventBus bus;
  final double cellSizePx;

  static const double _maxExtent = 132;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(regionMinimapVisibleProvider);
    final viewport =
        viewportSnapshot?.regionId == region.regionId ? viewportSnapshot : null;
    final aspect = region.width / region.height;
    late final Size mapSize;
    if (aspect >= 1) {
      mapSize = Size(_maxExtent, _maxExtent / aspect);
    } else {
      mapSize = Size(_maxExtent * aspect, _maxExtent);
    }

    final zoomMultiplier = viewport == null
        ? 1.0
        : viewport.zoomMultiplier.clamp(
            kRegionMapZoomMultiplierMin,
            kRegionMapZoomMultiplierMax,
          );
    final zoomPercentLabel = (zoomMultiplier * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (visible) ...[
          Material(
            color: Colors.black.withValues(alpha: 0.45),
            elevation: 2,
            child: GestureDetector(
              key: kRegionMinimapGestureKey,
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _onTap(
                local: d.localPosition,
                mapSize: mapSize,
              ),
              onPanUpdate: (details) => _onPan(
                delta: details.delta,
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
          const SizedBox(height: 4),
        ],
        SizedBox(
          width: mapSize.width,
          child: Text(
            '$zoomPercentLabel%',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: mapSize.width,
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(
                  label: 'Map zoom',
                  value: '$zoomPercentLabel percent',
                  slider: true,
                  child: Tooltip(
                    message: 'Map zoom',
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 11,
                        ),
                      ),
                      child: Slider(
                        key: kRegionMinimapZoomSliderKey,
                        value: zoomMultiplier,
                        min: kRegionMapZoomMultiplierMin,
                        max: kRegionMapZoomMultiplierMax,
                        onChanged: (v) {
                          bus.emit(
                            RequestRegionMapSetZoomMultiplierEvent(
                              regionId: region.regionId,
                              zoomMultiplier: v,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Material(
                key: kRegionMinimapToggleKey,
                color: Colors.white.withValues(alpha: 0.9),
                child: Tooltip(
                  message: visible
                      ? 'Hide region minimap'
                      : 'Show region minimap',
                  child: InkWell(
                    onTap: () => ref
                        .read(regionMinimapVisibleProvider.notifier)
                        .toggle(),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: StrictAssetIcon(
                        assetPath:
                            '${kAppIconAssetPrefix}ui_icon_region_minimap.png',
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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

class _RegionMinimapPainter extends CustomPainter {
  _RegionMinimapPainter({
    required this.region,
    required this.cellSizePx,
    required this.viewport,
  });

  final RegionMapViewData region;
  final double cellSizePx;
  final RegionMapViewportSnapshot? viewport;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / region.width;
    final cellH = size.height / region.height;
    final paint = Paint();

    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        final rect = Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH);
        if (cell.visibility == TileVisibility.unrevealed) {
          paint.color = Colors.black;
          canvas.drawRect(rect, paint);
          continue;
        }
        final base = cell.isSea
            ? kRegionMinimapSeaColor
            : kRegionMinimapTerrainColors[cell.terrainType ?? TerrainType.plains]!;
        if (cell.visibility == TileVisibility.fogged) {
          paint.color = base.withValues(alpha: kRegionMinimapFoggedAlpha);
        } else {
          paint.color = base;
        }
        canvas.drawRect(rect, paint);
      }
    }

    final v = viewport;
    if (v == null) return;
    final mw = region.width * cellSizePx;
    final mh = region.height * cellSizePx;
    final indicator = minimapViewportIndicatorRect(
      viewport: v,
      minimapSize: size,
      mapWidthWorld: mw,
      mapHeightWorld: mh,
    );
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(indicator, border);
  }

  @override
  bool shouldRepaint(covariant _RegionMinimapPainter oldDelegate) {
    return oldDelegate.region != region ||
        oldDelegate.cellSizePx != cellSizePx ||
        oldDelegate.viewport != viewport;
  }
}
