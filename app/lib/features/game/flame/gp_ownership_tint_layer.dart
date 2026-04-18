import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

/// Fixed alpha for Great Power land ownership tint on the in-game map.
/// SPEC/ui/map-widget.md § Province ownership (GP tint).
const double kGpOwnershipTintAlpha = 0.5;

/// Semi-transparent GP ownership wash after terrain, before resource glyphs.
/// See [shouldApplyGreatPowerOwnershipTint] for per-cell eligibility.
void paintGreatPowerOwnershipTintLayer({
  required Canvas canvas,
  required RegionMapViewData region,
  required double cellSize,
  required bool honorUnrevealedTiles,
}) {
  final gpIds = region.greatPowerFactionIds;
  if (gpIds.isEmpty) return;

  for (final cell in region.cells) {
    if (!shouldApplyGreatPowerOwnershipTint(
      cell: cell,
      greatPowerFactionIds: gpIds,
      honorUnrevealedTiles: honorUnrevealedTiles,
    )) {
      continue;
    }
    final owner = cell.ownerFactionId!;
    final rgb = region.factionColors[owner];
    if (rgb == null) continue;

    final left = cell.x * cellSize;
    final top = cell.y * cellSize;
    final rect = Rect.fromLTWH(left, top, cellSize, cellSize);
    final paint = Paint()
      ..color = Color.fromRGBO(rgb.$1, rgb.$2, rgb.$3, kGpOwnershipTintAlpha);
    canvas.drawRect(rect, paint);
  }
}
