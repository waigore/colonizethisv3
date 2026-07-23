import 'dart:math' as math;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';
import '../caches/province_label_icon_cache.dart';
import 'region_map_component.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_shared_visibility.dart';
import 'region_map_component_support.dart';
import 'region_map_province_overlay_geometry.dart';

extension CtRegionMapRenderPoliticalLabelsProvinceCompute
    on CtRegionMapComponent {
  void _ensureProvinceLabelCache() {
    if (identical(session.provinceLabelsRegionRef, region) &&
        session.provinceLabelsCellSize == cellSize &&
        session.provinceLabelsVisibilityMode == visibilityMode &&
        session.provinceLabelsCached != null) {
      return;
    }
    session.provinceLabelsRegionRef = region;
    session.provinceLabelsCellSize = cellSize;
    session.provinceLabelsVisibilityMode = visibilityMode;
    session.provinceLabelsCached = _computeProvinceLabels();
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
      return RegionMapPalette.provinceLabelPlateColor;
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
          regionMapComponentVisibilityForTerrain(this, cell) == TileVisibility.unrevealed) {
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
}

extension CtRegionMapRenderPoliticalLabelsProvincePaint
    on CtRegionMapComponent {
  void paintProvinceNames(Canvas canvas) {
    _ensureProvinceLabelCache();
    final labels = session.provinceLabelsCached;
    if (labels == null || labels.isEmpty) {
      return;
    }

    final invZ = 1.0 / cameraZoom.clamp(0.25, 4.0);
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: RegionMapPalette.provinceLabelFontSizePx,
      fontWeight: FontWeight.w600,
      shadows: <Shadow>[
        Shadow(
          blurRadius: 2,
          color: RegionMapPalette.provinceLabelShadowColor,
          offset: Offset(0.5, 0.5),
        ),
      ],
    );
    for (final item in labels) {
      final platePaint = Paint()..color = item.plateColor;
      final presence = region.provinceUnitPresenceByProvinceId[item.provinceId];
      final hasCapitalIcon = item.isCapital;
      const capitalIconIds = <String>[RegionMapPalette.provinceLabelCapitalIconId];
      final presenceIconIds = resolveProvinceLabelPresenceIconIds(presence);
      final presenceIconCount = presenceIconIds.length;
      final presenceIconsWidth = presenceIconCount > 0
          ? (presenceIconCount * RegionMapPalette.provinceLabelIconRenderedPx) +
                ((presenceIconCount - 1) * RegionMapPalette.provinceLabelIconGapPx)
          : 0.0;
      final capitalInlineWidth = hasCapitalIcon
          ? RegionMapPalette.provinceLabelIconRenderedPx + RegionMapPalette.provinceLabelTextIconGapPx
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
                ? RegionMapPalette.provinceLabelMaxWidthPx
                : double.infinity,
          );

      final tw = tp.width;
      final th = tp.height;
      final singleLinePresenceWidth = presenceIconCount > 0
          ? RegionMapPalette.provinceLabelTextIconGapPx + presenceIconsWidth
          : 0.0;
      final singleLineContentWidth =
          capitalInlineWidth + tw + singleLinePresenceWidth;
      final wrapIconsToSecondLine = shouldWrapProvinceLabelPresenceIcons(
        textWidthPx: tw,
        iconCount: presenceIconCount,
      );
      final lineOneWidth = capitalInlineWidth + tw;
      final lineOneHeight = hasCapitalIcon
          ? math.max(th, RegionMapPalette.provinceLabelIconRenderedPx)
          : th;
      final contentWidth = wrapIconsToSecondLine
          ? math.max(lineOneWidth, presenceIconsWidth)
          : singleLineContentWidth;
      final contentHeight = wrapIconsToSecondLine
          ? lineOneHeight +
                RegionMapPalette.provinceLabelTextIconGapPx +
                RegionMapPalette.provinceLabelIconRenderedPx
          : math.max(
              lineOneHeight,
              presenceIconCount > 0 ? RegionMapPalette.provinceLabelIconRenderedPx : 0,
            );
      const pad = RegionMapPalette.provinceLabelPlatePaddingPx;
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
                lineOneTop + (lineOneHeight - RegionMapPalette.provinceLabelIconRenderedPx) / 2,
            rowWidth: RegionMapPalette.provinceLabelIconRenderedPx,
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
            lineOneTop + lineOneHeight + RegionMapPalette.provinceLabelTextIconGapPx;
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
            top: rowTop + (contentHeight - RegionMapPalette.provinceLabelIconRenderedPx) / 2,
            rowWidth: RegionMapPalette.provinceLabelIconRenderedPx,
          );
        }
        final textLeft = rowLeft + capitalInlineWidth;
        final textTop = rowTop + (contentHeight - th) / 2;
        tp.paint(canvas, Offset(textLeft, textTop));
        if (presenceIconCount > 0) {
          final iconLeft = textLeft + tw + RegionMapPalette.provinceLabelTextIconGapPx;
          _paintProvinceLabelIconsRow(
            canvas: canvas,
            iconIds: presenceIconIds,
            left: iconLeft,
            top: rowTop + (contentHeight - RegionMapPalette.provinceLabelIconRenderedPx) / 2,
            rowWidth: presenceIconsWidth,
          );
        }
      }
      canvas.restore();
    }
  }
}

extension CtRegionMapRenderPoliticalLabelsSea on CtRegionMapComponent {
  void _ensureSeaZoneLabelCache() {
    if (identical(session.seaZoneLabelsRegionRef, region) &&
        session.seaZoneLabelsCellSize == cellSize &&
        session.seaZoneLabelsCached != null) {
      return;
    }
    session.seaZoneLabelsRegionRef = region;
    session.seaZoneLabelsCellSize = cellSize;
    session.seaZoneLabelsCached = _computeSeaZoneLabels();
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

  void paintSeaZoneNames(Canvas canvas) {
    _ensureSeaZoneLabelCache();
    final items = session.seaZoneLabelsCached;
    if (items == null || items.isEmpty) {
      return;
    }

    final invZ = 1.0 / cameraZoom.clamp(0.25, 4.0);
    const textStyle = TextStyle(
      color: RegionMapPalette.seaZoneLabelTextColor,
      fontSize: RegionMapPalette.provinceLabelFontSizePx,
      fontWeight: FontWeight.w600,
    );
    const pad = RegionMapPalette.provinceLabelPlatePaddingPx;
    final platePaint = Paint()..color = RegionMapPalette.seaZoneLabelPlateColor;

    for (final item in items) {
      final centroidCell = region.cellAt(item.cx, item.cy);
      if (regionMapComponentVisibilityForTerrain(this, centroidCell) == TileVisibility.unrevealed) {
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
          ? RegionMapPalette.provinceLabelIconRenderedPx + RegionMapPalette.provinceLabelTextIconGapPx
          : 0.0;
      final contentWidth = prefixIconWidth + tp.width;
      final contentHeight = math.max(
        tp.height,
        hasPrefixIcon ? RegionMapPalette.provinceLabelIconRenderedPx : 0.0,
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
          top: rowTop + (contentHeight - RegionMapPalette.provinceLabelIconRenderedPx) / 2,
          rowWidth: RegionMapPalette.provinceLabelIconRenderedPx,
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
        x += RegionMapPalette.provinceLabelIconRenderedPx + RegionMapPalette.provinceLabelIconGapPx;
        continue;
      }
      final dstRect = Rect.fromLTWH(
        x,
        top,
        RegionMapPalette.provinceLabelIconRenderedPx,
        RegionMapPalette.provinceLabelIconRenderedPx,
      );
      canvas.drawImageRect(icon, srcRect, dstRect, Paint());
      x += RegionMapPalette.provinceLabelIconRenderedPx + RegionMapPalette.provinceLabelIconGapPx;
    }
  }
}
