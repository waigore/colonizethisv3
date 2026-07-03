// Shared RGB constants for tile-map PNG export.
// SPEC/program/map-visualization.md § Tile map PNG export.

/// Deep blue for sea zones.
const (int, int, int) seaColorRgb = (20, 60, 140);

/// Light blue for sea zone borders (sea–sea).
const (int, int, int) seaZoneBorderRgb = (173, 216, 230);

/// Red for on-map region id labels (e.g. p1, s1).
const (int, int, int) regionIdLabelRgb = (220, 0, 0);
