
part of 'region_map_component.dart';

extension _CtRegionMapRenderPoliticalLabelsProvince on CtRegionMapComponent {
  void _ensureProvinceLabelCache() {
    if (identical(_provinceLabelsRegionRef, region) &&
        _provinceLabelsCellSize == cellSize &&
        _provinceLabelsVisibilityMode == visibilityMode &&
        _provinceLabelsCached != null) {
      return;
    }
    _provinceLabelsRegionRef = region;
    _provinceLabelsCellSize = cellSize;
    _provinceLabelsVisibilityMode = visibilityMode;
    _provinceLabelsCached = _computeProvinceLabels();
  }

  Color _provinceNamePlateColor({
    required String prefixedProvinceId,
    required List<CellViewData> qualifyingLandCells,
  }) {
    final rgb = resolveProvinceLabelPlateTintRgb(
      prefixedProvinceId: prefixedProvinceId,
      qualifyingLandCells: qualifyingLandCells,
      region: region,
      honorUnrevealedTiles:
          visibilityMode == CtMapVisibilityMode.playerConstrained,
    );
    if (rgb == null) {
      return _provinceLabelPlateColor;
    }
    return Color.fromRGBO(rgb.$1, rgb.$2, rgb.$3, kProvinceLabelPlateTintAlpha);
  }

  List<
    ({
      double cx,
      double cy,
      String text,
      String provinceId,
      Color plateColor,
      bool isCapital,
      int? avoidTileX,
      int? avoidTileY,
    })
  >
  _computeProvinceLabels() {
    final byLocalId = <String, List<CellViewData>>{};
    for (final cell in region.cells) {
      if (cell.isSea) continue;
      if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
          _visibilityForTerrain(cell) == TileVisibility.unrevealed) {
        continue;
      }
      byLocalId.putIfAbsent(cell.regionCellId, () => []).add(cell);
    }
    final out =
        <
          ({
            double cx,
            double cy,
            String text,
            String provinceId,
            Color plateColor,
            bool isCapital,
            int? avoidTileX,
            int? avoidTileY,
          })
        >[];
    final townMarkerByProvinceId = <String, TownMarkerView>{};
    for (final marker in region.townMarkers) {
      townMarkerByProvinceId.putIfAbsent(marker.provinceId, () => marker);
    }
    final capitalProvinceIds = <String>{};
    for (final cap in region.capitalMarkers) {
      if (cap.x < 0 ||
          cap.x >= region.width ||
          cap.y < 0 ||
          cap.y >= region.height) {
        continue;
      }
      final capCell = region.cellAt(cap.x, cap.y);
      if (capCell.isSea) {
        continue;
      }
      capitalProvinceIds.add('${region.regionId}|${capCell.regionCellId}');
    }
    for (final e in byLocalId.entries) {
      final cells = e.value;
      if (cells.isEmpty) continue;
      var sx = 0.0;
      var sy = 0.0;
      for (final c in cells) {
        sx += (c.x + 0.5) * cellSize;
        sy += (c.y + 0.5) * cellSize;
      }
      final n = cells.length;
      final cx = sx / n;
      final cy = sy / n;
      var tileSx = 0;
      var tileSy = 0;
      for (final c in cells) {
        tileSx += c.x;
        tileSy += c.y;
      }
      final centroidTileX = (tileSx / n).round();
      final centroidTileY = (tileSy / n).round();
      String? name;
      for (final c in cells) {
        final dn = c.provinceDisplayName;
        if (dn != null && dn.isNotEmpty) {
          name = dn;
          break;
        }
      }
      final text = name ?? e.key;
      final prefixedId = '${region.regionId}|${e.key}';
      final townMarker = townMarkerByProvinceId[e.key];
      final shouldAvoidTownTile =
          townMarker != null &&
          townMarker.x == centroidTileX &&
          townMarker.y == centroidTileY;
      final avoidTown = shouldAvoidTownTile ? townMarker : null;
      out.add((
        cx: cx,
        cy: cy,
        text: text,
        provinceId: prefixedId,
        plateColor: _provinceNamePlateColor(
          prefixedProvinceId: prefixedId,
          qualifyingLandCells: cells,
        ),
        isCapital: capitalProvinceIds.contains(prefixedId),
        avoidTileX: avoidTown?.x,
        avoidTileY: avoidTown?.y,
      ));
    }
    return out;
  }

  void _paintProvinceNames(Canvas canvas) {
    _ensureProvinceLabelCache();
    final labels = _provinceLabelsCached;
    if (labels == null || labels.isEmpty) {
      return;
    }

    final invZ = 1.0 / cameraZoom.clamp(0.25, 4.0);
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: _provinceLabelFontSizePx,
      fontWeight: FontWeight.w600,
      shadows: <Shadow>[
        Shadow(
          blurRadius: 2,
          color: _kProvinceLabelShadowColor,
          offset: Offset(0.5, 0.5),
        ),
      ],
    );
    for (final item in labels) {
      final platePaint = Paint()..color = item.plateColor;
      final presence = region.provinceUnitPresenceByProvinceId[item.provinceId];
      final hasCapitalIcon = item.isCapital;
      const capitalIconIds = <String>[_provinceLabelCapitalIconId];
      final presenceIconIds = resolveProvinceLabelPresenceIconIds(presence);
      final presenceIconCount = presenceIconIds.length;
      final presenceIconsWidth = presenceIconCount > 0
          ? (presenceIconCount * _provinceLabelIconRenderedPx) +
                ((presenceIconCount - 1) * _provinceLabelIconGapPx)
          : 0.0;
      final capitalInlineWidth = hasCapitalIcon
          ? _provinceLabelIconRenderedPx + _provinceLabelTextIconGapPx
          : 0.0;
      final shouldEllipsize = shouldEllipsizeProvinceLabelText(
        isCapital: item.isCapital,
      );
      final tp =
          TextPainter(
            text: TextSpan(text: item.text, style: textStyle),
            textDirection: TextDirection.ltr,
            maxLines: shouldEllipsize ? 3 : null,
            ellipsis: shouldEllipsize ? '…' : null,
          )..layout(
            maxWidth: shouldEllipsize
                ? _provinceLabelMaxWidthPx
                : double.infinity,
          );

      final tw = tp.width;
      final th = tp.height;
      final singleLinePresenceWidth = presenceIconCount > 0
          ? _provinceLabelTextIconGapPx + presenceIconsWidth
          : 0.0;
      final singleLineContentWidth =
          capitalInlineWidth + tw + singleLinePresenceWidth;
      final wrapIconsToSecondLine = shouldWrapProvinceLabelPresenceIcons(
        textWidthPx: tw,
        iconCount: presenceIconCount,
      );
      final lineOneWidth = capitalInlineWidth + tw;
      final lineOneHeight = hasCapitalIcon
          ? math.max(th, _provinceLabelIconRenderedPx)
          : th;
      final contentWidth = wrapIconsToSecondLine
          ? math.max(lineOneWidth, presenceIconsWidth)
          : singleLineContentWidth;
      final contentHeight = wrapIconsToSecondLine
          ? lineOneHeight +
                _provinceLabelTextIconGapPx +
                _provinceLabelIconRenderedPx
          : math.max(
              lineOneHeight,
              presenceIconCount > 0 ? _provinceLabelIconRenderedPx : 0,
            );
      const pad = _provinceLabelPlatePaddingPx;
      final bw = contentWidth + pad * 2;
      final bh = contentHeight + pad * 2;
      final center = item.avoidTileX != null && item.avoidTileY != null
          ? resolveSeaZoneNamePlateCenterWorld(
              centroidTileX: item.avoidTileX!,
              centroidTileY: item.avoidTileY!,
              avoidedTileX: item.avoidTileX!,
              avoidedTileY: item.avoidTileY!,
              cellSize: cellSize,
              gridWidth: region.width,
              gridHeight: region.height,
              plateWidthLogicalPx: bw,
              plateHeightLogicalPx: bh,
              cameraZoom: cameraZoom,
            )
          : Offset(item.cx, item.cy);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(invZ);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: bw, height: bh),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, platePaint);

      if (wrapIconsToSecondLine) {
        final lineOneLeft = -lineOneWidth / 2;
        final lineOneTop = -contentHeight / 2;
        if (hasCapitalIcon) {
          _paintProvinceLabelIconsRow(
            canvas: canvas,
            iconIds: capitalIconIds,
            left: lineOneLeft,
            top:
                lineOneTop + (lineOneHeight - _provinceLabelIconRenderedPx) / 2,
            rowWidth: _provinceLabelIconRenderedPx,
          );
        }
        tp.paint(
          canvas,
          Offset(
            lineOneLeft + capitalInlineWidth,
            lineOneTop + (lineOneHeight - th) / 2,
          ),
        );
        final iconTop =
            lineOneTop + lineOneHeight + _provinceLabelTextIconGapPx;
        _paintProvinceLabelIconsRow(
          canvas: canvas,
          iconIds: presenceIconIds,
          top: iconTop,
          rowWidth: presenceIconsWidth,
        );
      } else {
        final rowLeft = -singleLineContentWidth / 2;
        final rowTop = -contentHeight / 2;
        if (hasCapitalIcon) {
          _paintProvinceLabelIconsRow(
            canvas: canvas,
            iconIds: capitalIconIds,
            left: rowLeft,
            top: rowTop + (contentHeight - _provinceLabelIconRenderedPx) / 2,
            rowWidth: _provinceLabelIconRenderedPx,
          );
        }
        final textLeft = rowLeft + capitalInlineWidth;
        final textTop = rowTop + (contentHeight - th) / 2;
        tp.paint(canvas, Offset(textLeft, textTop));
        if (presenceIconCount > 0) {
          final iconLeft = textLeft + tw + _provinceLabelTextIconGapPx;
          _paintProvinceLabelIconsRow(
            canvas: canvas,
            iconIds: presenceIconIds,
            left: iconLeft,
            top: rowTop + (contentHeight - _provinceLabelIconRenderedPx) / 2,
            rowWidth: presenceIconsWidth,
          );
        }
      }
      canvas.restore();
    }
  }
}
