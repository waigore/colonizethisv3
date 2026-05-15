/// Orthogonal and diagonal neighbor deltas for tile-map grid algorithms.
///
/// Scan order is North, East, South, West (and diagonals for 8-neighborhood).
/// SPEC/program/tile-map-gen-algorithm.md; Refs #2489.
const kTileMapDirections4 = <(int dx, int dy)>[
  (0, -1),
  (1, 0),
  (0, 1),
  (-1, 0),
];

/// Eight-neighborhood deltas (4 orthogonal + 4 diagonal). Refs #2489.
const kTileMapDirections8 = <(int dx, int dy)>[
  ...kTileMapDirections4,
  (-1, -1),
  (1, -1),
  (1, 1),
  (-1, 1),
];
