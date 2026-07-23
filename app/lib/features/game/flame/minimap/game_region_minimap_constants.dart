// Region minimap layout constants. SPEC/ui/empire-overview.md § Region minimap.
//
// De-parted wave-9 cluster (Refs #4117).

/// Internal padding between the dark editorial-monocle minimap panel border
/// and the [CustomPaint] grid. Matches mockup `.minimap-panel { padding:2px }`
/// (`SPEC/ui/mockups/GAME10001-game-screen.html`). Unchanged at narrow —
/// the panel padding is part of the chrome, not the grid box.
const double kGameRegionMinimapPanelPadding = 2;
