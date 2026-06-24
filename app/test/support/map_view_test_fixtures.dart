// Lightweight, hand-built [InitGameMapViewData] for app map-chrome widget tests.
//
// Map-chrome suites (players-bar gating, the selection-prompt banner, the
// event-feed inset, etc.) mount a full `GameMapArea` / `GameScreen` so the map
// canvas exists, but assert only on chrome — overlay banners, narrow/victory
// gating, dark-theme tokens — never on generated map cells, markers, or
// topology. They previously paid the ~7-11s `getDebugInitGameResult()` map
// generation once per test isolate (Refs #3656) purely to obtain a
// `mapViewData` the assertions never inspect.
//
// [buildLightweightMapViewData] returns a minimal two-region
// [InitGameMapViewData] (a single land cell per region, no markers, empty colour
// maps, empty [MapTopology]) so the canvas mounts cheaply. Route any suite that
// genuinely reads generated cells/markers/topology to the documented
// `getDebugInitGameResult()` allowlist or a serialized fixture instead.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_map/colonizethis_map.dart';

/// A minimal single-cell [RegionMapViewData] for [regionId] (one land tile, no
/// markers, empty colour maps).
RegionMapViewData buildLightweightRegionMapViewData({required String regionId}) {
  return RegionMapViewData(
    regionId: regionId,
    width: 1,
    height: 1,
    cellSize: 24,
    cells: const [CellViewData(x: 0, y: 0, regionCellId: 'p0', isSea: false)],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {},
    terrainColors: const {},
  );
}

/// A minimal two-region [InitGameMapViewData] with no markers and an empty
/// [MapTopology], for map-chrome suites that mount the canvas but assert only on
/// chrome (Refs #3656).
InitGameMapViewData buildLightweightMapViewData() {
  return InitGameMapViewData(
    oldWorld: buildLightweightRegionMapViewData(regionId: 'oldWorld'),
    newWorld: buildLightweightRegionMapViewData(regionId: 'newWorld'),
    combinedTopology: const MapTopology(),
  );
}
