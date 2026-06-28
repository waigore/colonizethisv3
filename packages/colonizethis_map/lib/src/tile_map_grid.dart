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

  /// Returns a new row-major grid of [height] rows × [width] columns, each cell
  /// initialized to [fill].
  static List<List<T>> filled<T>(int height, int width, T fill) =>
      List.generate(height, (_) => List.filled(width, fill));

  /// Returns a new row-major grid of [height] rows × [width] columns, with cell
  /// `(y, x)` set by [cellAt].
  static List<List<T>> generate<T>(
    int height,
    int width,
    T Function(int y, int x) cellAt,
  ) =>
      List.generate(height, (y) => List.generate(width, (x) => cellAt(y, x)));

  /// Visits every `(y, x)` index of a [height] rows × [width] columns grid in
  /// the canonical **row-major** order (`y` outer, `x` inner).
  ///
  /// This is the single source of truth for tile-grid cell traversal across the
  /// generation passes, view builders, and visualizers, replacing hand-rolled
  /// nested `for (var y …) { for (var x …) }` walks so iteration order — which
  /// seeded generation depends on for bit-for-bit determinism — has one
  /// definition (Refs #3574). Use this overload when a pass reads from or writes
  /// to one or more parallel grids by index; use [forEachCell] when iterating a
  /// single grid's values. A guard inside [visit] (early `return`) is the
  /// equivalent of a `continue` in the original loop body.
  /// SPEC/program/tile-map-gen-algorithm.md.
  static void forEachIndex(
    int height,
    int width,
    void Function(int y, int x) visit,
  ) {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        visit(y, x);
      }
    }
  }

  /// Visits every cell of [grid] in the canonical **row-major** order (`y`
  /// outer, `x` inner), passing the cell coordinates and value to [visit].
  ///
  /// Dimensions are derived from [grid] itself (outer length is the row count,
  /// each row's length is its column count), so ragged grids are visited
  /// per-row. Use [forEachIndex] instead when the body must index sibling grids
  /// by coordinate rather than read this grid's value. Shares the determinism
  /// contract documented on [forEachIndex] (Refs #3574).
  /// SPEC/program/tile-map-gen-algorithm.md.
  static void forEachCell<T>(
    List<List<T>> grid,
    void Function(int y, int x, T value) visit,
  ) {
    for (var y = 0; y < grid.length; y++) {
      final row = grid[y];
      for (var x = 0; x < row.length; x++) {
        visit(y, x, row[x]);
      }
    }
  }
}
