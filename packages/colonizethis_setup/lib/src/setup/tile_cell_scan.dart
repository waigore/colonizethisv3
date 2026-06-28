// SPEC/program/game-setup-pipeline.md;
// SPEC/program/fog-and-exploration-resolution.md.
//
// Package-internal source of truth for the full-grid `for y { for x { ... } }`
// tile-cell scans setup performs over a generated [TileMapResult]. Several
// sites previously re-inlined the identical row-major walk that resolves each
// cell's local region id and canonical [CapitalTile.tileKey]:
//   - initial_visibility.dart: province-bucket indexing, old-world per-player
//     visibility, and new-world unknown-visibility fill (three near-identical
//     scans).
// Centralising the walk here keeps the deterministic row-major (y outer, x
// inner) visit order and the `(x, y, localId, tileKey)` derivation byte-identical
// across consumers (Refs #3740).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Visits a single grid cell at ([x], [y]) whose generated region id is
/// [localId] and whose canonical tile key is [tileKey]
/// ([CapitalTile.tileKey]).
typedef TileCellVisitor =
    void Function(int x, int y, String localId, String tileKey);

/// Walks every cell of [map] in deterministic row-major order (y outer, x
/// inner), invoking [visit] with the cell coordinates, its generated region
/// (province or sea zone) id, and the canonical [CapitalTile.tileKey] for
/// ([regionId], localId, x, y).
///
/// Single source of truth for the standalone `for y { for x { map.cell ... } }`
/// scans the setup pipeline previously inlined; the visit order matches those
/// inlined loops exactly, so adopting it preserves output byte-for-byte.
void forEachTileCell(
  TileMapResult map,
  String regionId,
  TileCellVisitor visit,
) {
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      final localId = map.cell(x, y);
      final tileKey = CapitalTile.tileKey(regionId, localId, x, y);
      visit(x, y, localId, tileKey);
    }
  }
}
