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

/// Whether to skip drawing a point marker (capital circle, town/port icon) on a cell.
///
/// In **player-constrained** visibility, markers that sit on a tile must not leak
/// geographic detail for [TileVisibility.unrevealed] cells (same rule as towns/ports).
/// SPEC/ui/map-widget.md § Visibility modes.
bool regionMapSkipPointMarkerOnCell({
  required bool playerConstrainedVisibility,
  required TileVisibility cellVisibility,
}) {
  if (!playerConstrainedVisibility) return false;
  return cellVisibility == TileVisibility.unrevealed;
}
