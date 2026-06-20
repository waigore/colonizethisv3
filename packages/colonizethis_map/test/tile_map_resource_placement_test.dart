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

  group('guaranteed forest resource spawn (R3 #3573)', () {
    late ResourceRules rules;

    setUp(() => rules = ResourceRules.defaultRules);

    bool place(TerrainType terrain, String region, Random rnd) {
      final grid = <List<Resource?>>[
        [null],
      ];
      final placed = tryPlaceWeightedResourceAtCell(
        resourceGrid: grid,
        x: 0,
        y: 0,
        terrain: terrain,
        mapRegionId: region,
        rules: rules,
        rnd: rnd,
      );
      return placed;
    }

    test('scrub forest always receives timber (OW and NW)', () {
      for (final region in ['oldWorld', 'newWorld']) {
        final rnd = Random(7);
        for (var i = 0; i < 200; i++) {
          final grid = <List<Resource?>>[
            [null],
          ];
          final placed = tryPlaceWeightedResourceAtCell(
            resourceGrid: grid,
            x: 0,
            y: 0,
            terrain: TerrainType.scrubForest,
            mapRegionId: region,
            rules: rules,
            rnd: rnd,
          );
          expect(placed, isTrue);
          expect(grid[0][0], Resource.timber, reason: 'region=$region');
        }
      }
    });

    test('hardwood forest Old World always receives timber', () {
      final rnd = Random(11);
      for (var i = 0; i < 200; i++) {
        final grid = <List<Resource?>>[
          [null],
        ];
        tryPlaceWeightedResourceAtCell(
          resourceGrid: grid,
          x: 0,
          y: 0,
          terrain: TerrainType.hardwoodForest,
          mapRegionId: 'oldWorld',
          rules: rules,
          rnd: rnd,
        );
        expect(grid[0][0], Resource.timber);
      }
    });

    test('hardwood forest New World yields only furs or timber, ~70/30', () {
      final rnd = Random(13);
      var furs = 0;
      var timber = 0;
      const samples = 4000;
      for (var i = 0; i < samples; i++) {
        final grid = <List<Resource?>>[
          [null],
        ];
        final placed = tryPlaceWeightedResourceAtCell(
          resourceGrid: grid,
          x: 0,
          y: 0,
          terrain: TerrainType.hardwoodForest,
          mapRegionId: 'newWorld',
          rules: rules,
          rnd: rnd,
        );
        expect(placed, isTrue);
        final r = grid[0][0];
        expect(r == Resource.furs || r == Resource.timber, isTrue);
        if (r == Resource.furs) furs++;
        if (r == Resource.timber) timber++;
      }
      expect(furs + timber, samples);
      final fursFraction = furs / samples;
      expect(fursFraction, closeTo(0.7, 0.05));
    });

    test('forest cells bypass the 40% gate even when cap would restrict', () {
      // A cap state at the cap with a region-only restriction would suppress a
      // "both" resource on a non-forest cell, but forest cells must always place.
      final capState = MultiRegionCapState(0.0, rules, 'newWorld')
        ..bothCount = 10
        ..totalCount = 10;
      final grid = <List<Resource?>>[
        [null],
      ];
      final placed = tryPlaceWeightedResourceAtCell(
        resourceGrid: grid,
        x: 0,
        y: 0,
        terrain: TerrainType.scrubForest,
        mapRegionId: 'newWorld',
        rules: rules,
        rnd: Random(1),
        capState: capState,
      );
      expect(placed, isTrue);
      expect(grid[0][0], Resource.timber);
    });

    test('forest placements are excluded from cap accounting', () {
      final capState = MultiRegionCapState(0.3, rules, 'newWorld');
      final grid = <List<Resource?>>[
        [null],
      ];
      tryPlaceWeightedResourceAtCell(
        resourceGrid: grid,
        x: 0,
        y: 0,
        terrain: TerrainType.hardwoodForest,
        mapRegionId: 'newWorld',
        rules: rules,
        rnd: Random(2),
        capState: capState,
      );
      // The guaranteed forest placement must not be recorded.
      expect(capState.totalCount, 0);
      expect(capState.bothCount, 0);
    });

    test('non-forest placement is unaffected (regression)', () {
      // Plains still honors the probability gate (may or may not place).
      var anyPlaced = false;
      final rnd = Random(3);
      for (var i = 0; i < 50; i++) {
        if (place(TerrainType.plains, 'oldWorld', rnd)) anyPlaced = true;
      }
      expect(anyPlaced, isTrue);
    });
  });
}
