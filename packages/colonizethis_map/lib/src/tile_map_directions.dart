/// Orthogonal and diagonal neighbor deltas for tile-map grid algorithms.
///
/// Two legacy 4-neighbor scan orders exist in the generator; unifying them into
/// one list changes deterministic BFS/flood-fill outcomes (Refs #2489).
/// SPEC/program/tile-map-gen-algorithm.md.
///
/// [kTileMapDirections4] — North, East, South, West (clockwise from north).
/// Used by terrain assignment, join-sea jitter, and port-icon placement.
const kTileMapDirections4 = <(int dx, int dy)>[
  (0, -1),
  (1, 0),
  (0, 1),
  (-1, 0),
];

/// [kTileMapDirections4NorthSouthWestEast] — North, South, West, East.
/// Legacy order for grid-graph BFS, lakes, join-sea bridges, and coast growth.
const kTileMapDirections4NorthSouthWestEast = <(int dx, int dy)>[
  (0, -1),
  (0, 1),
  (-1, 0),
  (1, 0),
];

/// West, East, North, South deltas (orthogonal).
///
/// Matches legacy `(x±1,y)` / `(x,y±1)` tuple order where iteration order affects
/// deterministic outcomes (for example `_tryBorderNoiseSwapAtCell`). Refs #2489.
const kTileMapDirections4WestEastNorthSouth = <(int dx, int dy)>[
  (-1, 0),
  (1, 0),
  (0, -1),
  (0, 1),
];

/// Eight-neighborhood deltas (4 orthogonal + 4 diagonal). Refs #2489.
const kTileMapDirections8 = <(int dx, int dy)>[
  ...kTileMapDirections4,
  (-1, -1),
  (1, -1),
  (1, 1),
  (-1, 1),
];
