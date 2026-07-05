
part of 'region_map_component.dart';

extension _CtRegionMapRenderPoliticalLabelsSea on CtRegionMapComponent {
  void _ensureSeaZoneLabelCache() {
    if (identical(_seaZoneLabelsRegionRef, region) &&
        _seaZoneLabelsCellSize == cellSize &&
        _seaZoneLabelsCached != null) {
      return;
    }
    _seaZoneLabelsRegionRef = region;
    _seaZoneLabelsCellSize = cellSize;
    _seaZoneLabelsCached = _computeSeaZoneLabels();
  }

  List<({int cx, int cy, String text, bool isWarpZone})>
  _computeSeaZoneLabels() {
    final byLocalId = <String, List<CellViewData>>{};
    for (final cell in region.cells) {
      if (!cell.isSea) {
        continue;
      }
      byLocalId.putIfAbsent(cell.regionCellId, () => []).add(cell);
    }
    final out = <({int cx, int cy, String text, bool isWarpZone})>[];
    final warpSeaZoneIds = region.warpMarkers.map((m) => m.seaZoneId).toSet();
    for (final e in byLocalId.entries) {
      final cells = e.value;
      if (cells.isEmpty) {
        continue;
      }
      var sx = 0;
      var sy = 0;
      for (final c in cells) {
        sx += c.x;
        sy += c.y;
      }
      final n = cells.length;
      final cx = (sx / n).round();
      final cy = (sy / n).round();
      if (cx < 0 || cy < 0 || cx >= region.width || cy >= region.height) {
        continue;
      }
      final prefixed = '${region.regionId}|${e.key}';
      final text = region.seaZoneDisplayNameByPrefixedId[prefixed] ?? e.key;
      out.add((
        cx: cx,
        cy: cy,
        text: text,
        isWarpZone: warpSeaZoneIds.contains(e.key),
      ));
    }
    return out;
  }

  void _paintSeaZoneNames(Canvas canvas) {
    _ensureSeaZoneLabelCache();
    final items = _seaZoneLabelsCached;
    if (items == null || items.isEmpty) {
      return;
    }

    final invZ = 1.0 / cameraZoom.clamp(0.25, 4.0);
    const textStyle = TextStyle(
      color: _seaZoneLabelTextColor,
      fontSize: _provinceLabelFontSizePx,
      fontWeight: FontWeight.w600,
    );
    const pad = _provinceLabelPlatePaddingPx;
    final platePaint = Paint()..color = _seaZoneLabelPlateColor;

    for (final item in items) {
      final centroidCell = region.cellAt(item.cx, item.cy);
      if (_visibilityForTerrain(centroidCell) == TileVisibility.unrevealed) {
        continue;
      }
      final tp = TextPainter(
        text: TextSpan(text: item.text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: double.infinity);
      final prefixIconIds = resolveSeaZoneLabelPrefixIconIds(
        isWarpZone: item.isWarpZone,
      );
      final hasPrefixIcon = prefixIconIds.isNotEmpty;
      final prefixIconWidth = hasPrefixIcon
          ? _provinceLabelIconRenderedPx + _provinceLabelTextIconGapPx
          : 0.0;
      final contentWidth = prefixIconWidth + tp.width;
      final contentHeight = math.max(
        tp.height,
        hasPrefixIcon ? _provinceLabelIconRenderedPx : 0.0,
      );
      final bw = contentWidth + pad * 2;
      final bh = contentHeight + pad * 2;
      final center = resolveSeaZoneNamePlateCenterWorld(
        centroidTileX: item.cx,
        centroidTileY: item.cy,
        cellSize: cellSize,
        gridWidth: region.width,
        gridHeight: region.height,
        plateWidthLogicalPx: bw,
        plateHeightLogicalPx: bh,
        cameraZoom: cameraZoom,
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(invZ);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: bw, height: bh),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, platePaint);
      final rowLeft = -contentWidth / 2;
      final rowTop = -contentHeight / 2;
      if (hasPrefixIcon) {
        _paintProvinceLabelIconsRow(
          canvas: canvas,
          iconIds: prefixIconIds,
          left: rowLeft,
          top: rowTop + (contentHeight - _provinceLabelIconRenderedPx) / 2,
          rowWidth: _provinceLabelIconRenderedPx,
        );
      }
      tp.paint(
        canvas,
        Offset(
          rowLeft + prefixIconWidth,
          rowTop + (contentHeight - tp.height) / 2,
        ),
      );
      canvas.restore();
    }
  }

  void _paintProvinceLabelIconsRow({
    required Canvas canvas,
    required List<String> iconIds,
    required double top,
    required double rowWidth,
    double? left,
  }) {
    if (iconIds.isEmpty) return;
    final srcRect = Rect.fromLTWH(
      0,
      0,
      ProvinceLabelIconCache.iconSize,
      ProvinceLabelIconCache.iconSize,
    );
    var x = left ?? (-rowWidth / 2);
    for (final iconId in iconIds) {
      final icon = provinceLabelIconCache.getIcon(iconId);
      if (icon == null) {
        x += _provinceLabelIconRenderedPx + _provinceLabelIconGapPx;
        continue;
      }
      final dstRect = Rect.fromLTWH(
        x,
        top,
        _provinceLabelIconRenderedPx,
        _provinceLabelIconRenderedPx,
      );
      canvas.drawImageRect(icon, srcRect, dstRect, Paint());
      x += _provinceLabelIconRenderedPx + _provinceLabelIconGapPx;
    }
  }
}
