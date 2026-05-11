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
  });
}
