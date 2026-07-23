import 'dart:math' as math;

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import 'region_map_component.dart';
import 'region_map_component_render_political_labels_icons.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_shared_visibility.dart';
import 'region_map_component_support.dart';

void regionMapComponentEnsureSeaZoneLabelCache(
  CtRegionMapComponent component,
) {
  if (identical(component.session.seaZoneLabelsRegionRef, component.region) &&
      component.session.seaZoneLabelsCellSize == component.cellSize &&
      component.session.seaZoneLabelsCached != null) {
    return;
  }
  component.session.seaZoneLabelsRegionRef = component.region;
  component.session.seaZoneLabelsCellSize = component.cellSize;
  component.session.seaZoneLabelsCached = regionMapComponentComputeSeaZoneLabels(
    component,
  );
}

List<({int cx, int cy, String text, bool isWarpZone})>
regionMapComponentComputeSeaZoneLabels(CtRegionMapComponent component) {
  final byLocalId = <String, List<CellViewData>>{};
  for (final cell in component.region.cells) {
    if (!cell.isSea) {
      continue;
    }
    byLocalId.putIfAbsent(cell.regionCellId, () => []).add(cell);
  }
  final out = <({int cx, int cy, String text, bool isWarpZone})>[];
  final warpSeaZoneIds = component.region.warpMarkers.map((m) => m.seaZoneId).toSet();
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
    if (cx < 0 || cy < 0 || cx >= component.region.width || cy >= component.region.height) {
      continue;
    }
    final prefixed = '${component.region.regionId}|${e.key}';
    final text = component.region.seaZoneDisplayNameByPrefixedId[prefixed] ?? e.key;
    out.add((
      cx: cx,
      cy: cy,
      text: text,
      isWarpZone: warpSeaZoneIds.contains(e.key),
    ));
  }
  return out;
}

void regionMapComponentPaintSeaZoneNames(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  regionMapComponentEnsureSeaZoneLabelCache(component);
  final items = component.session.seaZoneLabelsCached;
  if (items == null || items.isEmpty) {
    return;
  }

  final invZ = 1.0 / component.cameraZoom.clamp(0.25, 4.0);
  const textStyle = TextStyle(
    color: RegionMapPalette.seaZoneLabelTextColor,
    fontSize: RegionMapPalette.provinceLabelFontSizePx,
    fontWeight: FontWeight.w600,
  );
  const pad = RegionMapPalette.provinceLabelPlatePaddingPx;
  final platePaint = Paint()..color = RegionMapPalette.seaZoneLabelPlateColor;

  for (final item in items) {
    final centroidCell = component.region.cellAt(item.cx, item.cy);
    if (regionMapComponentVisibilityForTerrain(component, centroidCell) ==
        TileVisibility.unrevealed) {
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
        ? RegionMapPalette.provinceLabelIconRenderedPx +
              RegionMapPalette.provinceLabelTextIconGapPx
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
      cellSize: component.cellSize,
      gridWidth: component.region.width,
      gridHeight: component.region.height,
      plateWidthLogicalPx: bw,
      plateHeightLogicalPx: bh,
      cameraZoom: component.cameraZoom,
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
      regionMapComponentPaintProvinceLabelIconsRow(
        component,
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
