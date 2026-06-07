/// Region and grid constants shared by world-layer resolvers (Refs #3290 Phase 1).
library;

const String kRegionOldWorld = 'oldWorld';
const String kRegionNewWorld = 'newWorld';

/// Cardinal (4-neighbor) grid deltas on row-major tile maps (north/up-first).
const List<(int, int)> kGridNeighborsCardinal4 = [
  (0, -1),
  (1, 0),
  (0, 1),
  (-1, 0),
];
