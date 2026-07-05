
part of 'region_map_component.dart';

extension _CtRegionMapRenderMarkers on CtRegionMapComponent {
  void _paintValidTilesGlow(Canvas canvas) {
    final keys = validTileKeys!;
    final t = _hoverAnimationT;
    final opacity =
        _kValidWorkTargetGlowOpacityBase +
        _kValidWorkTargetGlowOpacityAmplitude *
            (_kSinNormalizedMid +
                _kSinNormalizedMid *
                    math.sin(t * _kValidWorkTargetGlowTimeScale));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kMapValidTileTargetStrokeWidth
      ..color = _kValidWorkTargetStrokeYellow.withValues(alpha: opacity);
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        final tileKey = '${region.regionId}|${cell.regionCellId}|$x|$y';
        if (!keys.contains(tileKey)) continue;
        final left = x * cellSize;
        final top = y * cellSize;
        canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), paint);
      }
    }
  }

  void _paintSelectedTile(Canvas canvas) {
    _paintTileOutlineRing(
      canvas,
      tileKey: selectedTileKey!,
      color: _kMapSelectedHighlightOrange,
      strokeWidth: kMapSelectedTileStrokeWidth,
    );
  }

  void _paintSecondaryHighlightTile(Canvas canvas) {
    _paintTileOutlineRing(
      canvas,
      tileKey: secondaryHighlightTileKey!,
      color: _kMapSecondarySelectionCyan,
      strokeWidth: kMapSecondaryHighlightStrokeWidth,
    );
  }

  void _paintTileOutlineRing(
    Canvas canvas, {
    required String tileKey,
    required Color color,
    required double strokeWidth,
  }) {
    final parsed = tryParseTileKey(tileKey);
    if (parsed == null || parsed.regionId != region.regionId) return;
    final x = parsed.x;
    final y = parsed.y;
    if (x < 0 || x >= region.width || y < 0 || y >= region.height) return;
    final left = x * cellSize;
    final top = y * cellSize;
    final rect = Rect.fromLTWH(left, top, cellSize, cellSize);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    canvas.drawRect(rect, paint);
  }

  void _paintSelector(Canvas canvas) {
    final x = _hoveredTileX!;
    final y = _hoveredTileY!;
    final bounce =
        _kHoverSelectorBounceBaseline +
        _kHoverSelectorBounceAmplitude *
            math.sin(_hoverAnimationT * _kHoveredProvinceGlowAngularFrequency);
    final cx = x * cellSize + cellSize / 2;
    final cy = y * cellSize + cellSize / 2;
    final half = (cellSize / 2 - 2.0) * bounce;
    final left = cx - half;
    final top = cy - half;
    final size = half * 2;
    final rect = Rect.fromLTWH(left, top, size, size);
    final color = (validTileKeys != null && validTileKeys!.isNotEmpty)
        ? _kMapSelectedHighlightOrange
        : _kMapHoverSelectorIdle;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kMapHoverSelectorStrokeWidth
      ..color = color;
    canvas.drawRect(rect, paint);
  }
}
