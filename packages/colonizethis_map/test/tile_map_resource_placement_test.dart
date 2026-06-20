import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/src/tile_map_resource_placement.dart';
import 'package:colonizethis_map/src/tile_map_resource_cap_state.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('tryPlaceWeightedResourceAtCell', () {
    late ResourceRules rules;
    late List<List<Resource?>> resourceGrid;

    setUp(() {
      rules = ResourceRules.defaultRules;
      resourceGrid = [
        [null],
      ];
    });

    test('returns false when no resources allowed on terrain', () {
      final placed = tryPlaceWeightedResourceAtCell(
        resourceGrid: resourceGrid,
        x: 0,
        y: 0,
        terrain: TerrainType.mountain,
        mapRegionId: 'unknownRegion',
        rules: rules,
        rnd: Random(1),
      );
      expect(placed, isFalse);
      expect(resourceGrid[0][0], isNull);
    });

    test('places resource when roll accepts placement', () {
      final rnd = Random(0);
      var placedCount = 0;
      for (var i = 0; i < 50; i++) {
        resourceGrid[0][0] = null;
        if (tryPlaceWeightedResourceAtCell(
          resourceGrid: resourceGrid,
          x: 0,
          y: 0,
          terrain: TerrainType.plains,
          mapRegionId: 'oldWorld',
          rules: rules,
          rnd: rnd,
        )) {
          placedCount++;
        }
      }
      expect(placedCount, greaterThan(0));
    });

    test('respects cap state region-only filter at cap', () {
      final capState = MultiRegionCapState(0.0, rules, 'oldWorld')
        ..bothCount = 1
        ..totalCount = 1;
      final placed = tryPlaceWeightedResourceAtCell(
        resourceGrid: resourceGrid,
        x: 0,
        y: 0,
        terrain: TerrainType.plains,
        mapRegionId: 'oldWorld',
        rules: rules,
        rnd: Random(2),
        capState: capState,
      );
      if (placed) {
        final resource = resourceGrid[0][0]!;
        expect(
          rules.regionRule[resource],
          isNot(ResourceRegionRule.both),
        );
      }
    });
  });
}
