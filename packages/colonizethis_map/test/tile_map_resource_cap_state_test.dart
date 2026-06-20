import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/src/tile_map_resource_cap_state.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('MultiRegionCapState', () {
    test(
      'shouldRestrictToRegionOnly returns true at cap when both and region-only exist',
      () {
        final rules = ResourceRules.defaultRules;
        final state = MultiRegionCapState(0.5, rules, 'oldWorld')
          ..bothCount = 1
          ..totalCount = 2;

        final shouldRestrict = state.shouldRestrictToRegionOnly([
          Resource.timber, // both
          Resource.grain, // old-world only
        ]);

        expect(shouldRestrict, isTrue);
      },
    );

    test('filterToRegionOnly removes both-region resources', () {
      final rules = ResourceRules.defaultRules;
      final state = MultiRegionCapState(0.3, rules, 'oldWorld');

      final filtered = state.filterToRegionOnly([
        Resource.timber, // both
        Resource.grain, // old-world only
      ]);

      expect(filtered, [Resource.grain]);
    });

    test('fromExisting and record keep both/total counters in sync', () {
      final rules = ResourceRules.defaultRules;
      final resourceGrid = <List<Resource?>>[
        [Resource.timber, null], // both
        [Resource.grain, Resource.iron], // region-only + both
      ];
      final state = MultiRegionCapState.fromExisting(
        0.3,
        rules,
        'oldWorld',
        resourceGrid,
      );

      expect(state.totalCount, 3);
      expect(state.bothCount, 2);

      state.record(Resource.grain);
      expect(state.totalCount, 4);
      expect(state.bothCount, 2);
    });

    test(
      'fromExisting excludes forest-terrain cells from cap accounting (R3 #3573)',
      () {
        final rules = ResourceRules.defaultRules;
        final resourceGrid = <List<Resource?>>[
          [Resource.timber, Resource.grain],
          [Resource.timber, Resource.iron],
        ];
        // (0,0) and (0,1) are forest timber (guaranteed); they must be excluded.
        final terrainGrid = <List<TerrainType?>>[
          [TerrainType.hardwoodForest, TerrainType.plains],
          [TerrainType.scrubForest, TerrainType.hills],
        ];
        final state = MultiRegionCapState.fromExisting(
          0.3,
          rules,
          'newWorld',
          resourceGrid,
          terrainGrid: terrainGrid,
        );
        // Only the non-forest grain (region-only) and iron (both) are counted.
        expect(state.totalCount, 2);
        expect(state.bothCount, 1);
      },
    );

    test('fromExisting without terrainGrid counts every resource (regression)', () {
      final rules = ResourceRules.defaultRules;
      final resourceGrid = <List<Resource?>>[
        [Resource.timber, Resource.grain],
      ];
      final state = MultiRegionCapState.fromExisting(
        0.3,
        rules,
        'oldWorld',
        resourceGrid,
      );
      expect(state.totalCount, 2);
      expect(state.bothCount, 1);
    });
  });
}
