/// Deep-copies a 2D tile grid (row-major list of lists).
List<List<T>> copyTileMapGrid<T>(List<List<T>> grid) =>
    grid.map((row) => row.toList()).toList();
