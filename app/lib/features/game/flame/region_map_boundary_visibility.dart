import 'package:colonizethis_map/colonizethis_map.dart';

/// Whether to draw a province/sea-zone topology stroke or political stroke on the
/// edge between two adjacent cells. SPEC/ui/map-widget.md § Province overlay,
/// player-constrained visibility.
///
/// When [gateByUnrevealedTiles] is false ([CtMapVisibilityMode.full]), always true.
/// When true, the edge is drawn iff at least one cell is not [TileVisibility.unrevealed].
bool regionMapDrawBoundaryBetweenAdjacentCells({
  required bool gateByUnrevealedTiles,
  required TileVisibility visibilityA,
  required TileVisibility visibilityB,
}) {
  if (!gateByUnrevealedTiles) return true;
  return visibilityA != TileVisibility.unrevealed ||
      visibilityB != TileVisibility.unrevealed;
}
