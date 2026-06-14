/// Canonical row-major tile-grid operations for colonizethis_map.
///
/// All defensive deep copies of a 2D tile grid (row-major list of row lists)
/// must route through [TileMapGrid.copy] so grid-copy logic has a single
/// source of truth across the land-seed, lakes-province, and join-sea
/// generation passes (Refs #3459). The repo-lint rule
/// `repo.map_grid_ops_central` forbids re-introducing scattered inline
/// `.map((row) => row.toList()).toList()` deep copies in the package lib.
/// SPEC/program/tile-map-gen-algorithm.md.
class TileMapGrid {
  /// Returns an independent deep copy of [grid] (a new outer list whose rows
  /// are each a fresh copy of the corresponding input row). The element values
  /// are copied by reference, matching the previous `copyTileMapGrid` helper so
  /// seeded generation output stays bit-for-bit deterministic.
  static List<List<T>> copy<T>(List<List<T>> grid) =>
      grid.map((row) => row.toList()).toList();
}
