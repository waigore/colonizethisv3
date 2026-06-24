// Focused tests for the lightweight map-view fixtures (Refs #3656). These guard
// the minimal shape the map-chrome suites rely on so the helper cannot silently
// drift into generating heavyweight data.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'map_view_test_fixtures.dart';

void main() {
  group('buildLightweightRegionMapViewData', () {
    test('builds a single-cell land region for the given regionId', () {
      final region = buildLightweightRegionMapViewData(regionId: 'oldWorld');

      expect(region.regionId, 'oldWorld');
      expect(region.width, 1);
      expect(region.height, 1);
      expect(region.cells, hasLength(1));
      expect(region.cells.single.isSea, isFalse);
      expect(region.cells.single.x, 0);
      expect(region.cells.single.y, 0);
    });

    test('carries no markers or colour maps (cheap to mount)', () {
      final region = buildLightweightRegionMapViewData(regionId: 'newWorld');

      expect(region.capitalMarkers, isEmpty);
      expect(region.portMarkers, isEmpty);
      expect(region.unitMarkers, isEmpty);
      expect(region.factionColors, isEmpty);
      expect(region.greatPowerFactionIds, isEmpty);
      expect(region.terrainColors, isEmpty);
    });
  });

  group('buildLightweightMapViewData', () {
    test('builds both regions with an empty topology', () {
      final InitGameMapViewData data = buildLightweightMapViewData();

      expect(data.oldWorld.regionId, 'oldWorld');
      expect(data.newWorld.regionId, 'newWorld');
      expect(data.combinedTopology, isA<MapTopology>());
      expect(data.combinedTopology.nodes, isEmpty);
      expect(data.combinedTopology.edges, isEmpty);
    });
  });
}
