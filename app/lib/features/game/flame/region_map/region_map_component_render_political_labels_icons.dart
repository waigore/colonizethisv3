import 'package:flutter/material.dart';

import '../caches/province_label_icon_cache.dart';
import 'region_map_component.dart';
import 'region_map_component_shared_palette.dart';

void regionMapComponentPaintProvinceLabelIconsRow(
  CtRegionMapComponent component, {
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
      x += RegionMapPalette.provinceLabelIconRenderedPx +
          RegionMapPalette.provinceLabelIconGapPx;
      continue;
    }
    final dstRect = Rect.fromLTWH(
      x,
      top,
      RegionMapPalette.provinceLabelIconRenderedPx,
      RegionMapPalette.provinceLabelIconRenderedPx,
    );
    canvas.drawImageRect(icon, srcRect, dstRect, Paint());
    x += RegionMapPalette.provinceLabelIconRenderedPx +
        RegionMapPalette.provinceLabelIconGapPx;
  }
}
