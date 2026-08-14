import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

/// Muted hatch alpha for land not bound to the capital (Refs #4370).
/// Distinct from GP ownership tint alpha 0.5 so both layers can coexist.
const double kCapitalLinkDisconnectedHatchAlpha = 0.35;

/// Neutral hatch colour (editorial-monocle muted ink) — not a faction tint.
const Color kCapitalLinkDisconnectedHatchColor = Color(0xFF8A7F72);

/// Whether [cell] should receive the capital-link disconnected hatch.
/// SPEC/ui/map-widget.md § Capital-link disconnected land highlight.
bool shouldApplyCapitalLinkDisconnectedHighlight({
  required CellViewData cell,
  required bool honorUnrevealedTiles,
}) {
  if (cell.isSea) return false;
  if (!cell.capitalLinkDisconnected) return false;
  if (honorUnrevealedTiles && cell.visibility == TileVisibility.unrevealed) {
    return false;
  }
  return true;
}

/// Diagonal hatch over viewing-player owned land not bound to the capital.
/// Painted after GP ownership tint and before resource glyphs / discs.
/// Each cell is clipRect'd so hatch lines do not bleed into neighbours.
void paintCapitalLinkDisconnectedHighlightLayer({
  required Canvas canvas,
  required RegionMapViewData region,
  required double cellSize,
  required bool honorUnrevealedTiles,
}) {
  final paint = Paint()
    ..color = kCapitalLinkDisconnectedHatchColor.withValues(
      alpha: kCapitalLinkDisconnectedHatchAlpha,
    )
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  for (final cell in region.cells) {
    if (!shouldApplyCapitalLinkDisconnectedHighlight(
      cell: cell,
      honorUnrevealedTiles: honorUnrevealedTiles,
    )) {
      continue;
    }
    final left = cell.x * cellSize;
    final top = cell.y * cellSize;
    final rect = Rect.fromLTWH(left, top, cellSize, cellSize);
    canvas.save();
    canvas.clipRect(rect);
    final step = (cellSize / 4).clamp(4.0, 16.0);
    for (var offset = -cellSize; offset < cellSize * 2; offset += step) {
      canvas.drawLine(
        Offset(left + offset, top),
        Offset(left + offset + cellSize, top + cellSize),
        paint,
      );
    }
    canvas.restore();
  }
}
