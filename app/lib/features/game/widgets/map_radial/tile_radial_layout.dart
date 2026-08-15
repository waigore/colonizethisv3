/// Layout size / clamp helpers for MAP30001.
///
/// SPEC: `SPEC/ui/components/tile-radial-catalog.md`, `SPEC/ui/tile-context-radial.md`.
library;

import 'dart:ui' show Offset, Size;

/// Minimum wedge tap target (`SPEC/ui/mobile-adaptation.md`).
const double kTileRadialWedgeMinSize = 44;

/// Distance from hub center to wedge center.
const double kTileRadialSpokeRadius = 72;

/// Hub box for the Place line.
const double kTileRadialHubSize = 88;

/// Canonical action-wedge count used when deciding radial-vs-More fallback.
const int kTileRadialFitReferenceWedgeCount = 3;

/// Bounding box for [actionWedgeCount] catalog wedges plus More.
Size tileRadialNeededSize({required int actionWedgeCount}) {
  final diameter = 2 * (kTileRadialSpokeRadius + kTileRadialWedgeMinSize / 2);
  return Size(diameter, diameter);
}

/// Whether three wedges plus More can sit inside [viewport] after clamping
/// a [needed] box toward [anchor].
bool tileRadialFitsAfterClamp({
  required Size viewport,
  required Offset anchor,
  int actionWedgeCount = kTileRadialFitReferenceWedgeCount,
}) {
  final needed = tileRadialNeededSize(actionWedgeCount: actionWedgeCount);
  if (needed.width > viewport.width || needed.height > viewport.height) {
    return false;
  }
  final topLeft = clampTileRadialTopLeft(
    viewport: viewport,
    anchor: anchor,
    size: needed,
  );
  return topLeft.dx >= 0 &&
      topLeft.dy >= 0 &&
      topLeft.dx + needed.width <= viewport.width &&
      topLeft.dy + needed.height <= viewport.height;
}

/// Top-left of a [size] box whose center prefers [anchor], clamped on-screen.
Offset clampTileRadialTopLeft({
  required Size viewport,
  required Offset anchor,
  required Size size,
}) {
  var left = anchor.dx - size.width / 2;
  var top = anchor.dy - size.height / 2;
  if (left < 0) left = 0;
  if (top < 0) top = 0;
  if (left + size.width > viewport.width) {
    left = viewport.width - size.width;
  }
  if (top + size.height > viewport.height) {
    top = viewport.height - size.height;
  }
  return Offset(left, top);
}
