part of 'game_region_minimap.dart';

/// Terrain base colors for the region minimap (flat fills). SPEC/ui/empire-overview.md § Region minimap.
const Map<TerrainType, Color> kRegionMinimapTerrainColors = {
  TerrainType.plains: Color(0xFFA5D6A7),
  TerrainType.hardwoodForest: Color(0xFF2E7D32),
  TerrainType.scrubForest: Color(0xFF7CB342),
  TerrainType.hills: Color(0xFFB0BEC5),
  TerrainType.mountain: Color(0xFF546E7A),
  TerrainType.swamp: Color(0xFF6D4C41),
  TerrainType.desert: Color(0xFFD7CCC8),
};

/// Deep sea fill when [CellViewData.isSea] is true.
const Color kRegionMinimapSeaColor = Color(0xFF0D47A1);

/// Opacity for fogged tiles (terrain still visible underneath per SPEC).
const double kRegionMinimapFoggedAlpha = 0.55;

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
          paint.color = EditorialMonoclePalette.bgDeep;
          canvas.drawRect(rect, paint);
          continue;
        }
        final base = cell.isSea
            ? kRegionMinimapSeaColor
            : kRegionMinimapTerrainColors[cell.terrainType ??
                  TerrainType.plains]!;
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
      ..color = EditorialMonoclePalette.fg
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
