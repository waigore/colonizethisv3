// Refs #3393 Phase 6b — behaviour-preserving migration of the
// `war_desire_calculator` full-world owner scans onto `ProvinceOwnerCache`
// (SPEC/program/worldstate-projection.md § Phase 6b). These tests assert the
// projection returns exactly the owned-province set the prior `allProvinces`
// owner scan produced (across both regions), and that the migrated war-desire
// scoring still observes target resources and owned regions in both worlds.

import 'package:colonizethis_logic/ai_api.dart'
    show ProvinceOwnerCache, allProvinces;
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('war_desire_calculator ProvinceOwnerCache migration', () {
    Game gameWithResources(Map<String, String> resources) {
      const oldTile = 'oldWorld|p2|0|0';
      const newTile = 'newWorld|n2|0|0';
      return Game(
        id: 'g-poc',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
              Province(
                id: 'oldWorld|p2',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|p1',
              ),
              Unit(
                id: 'u2',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|p1',
              ),
            ],
          ),
          newWorld: const RegionData(
            provinces: [
              Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'gp1'),
              Province(
                id: 'newWorld|n2',
                regionId: 'newWorld',
                ownerId: 'minor1',
              ),
            ],
          ),
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              'oldWorld|p2': [oldTile],
            },
            'newWorld': {
              'newWorld|n2': [newTile],
            },
          },
          resourceByTileKey: resources,
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            stockpile: Stockpile(quantities: {'grain': 10}),
          ),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M')],
      );
    }

    test(
      'provincesOwnedBy equals the allProvinces owner scan across both regions',
      () {
        final world = gameWithResources(const {}).worldState;
        final cache = ProvinceOwnerCache.of(world);

        Set<String> manualOwned(String factionId) => {
          for (final p in allProvinces(world))
            if (p.ownerId == factionId) p.id,
        };

        expect(
          cache.provincesOwnedBy('gp1').map((p) => p.id).toSet(),
          equals(manualOwned('gp1')),
        );
        expect(
          cache.provincesOwnedBy('minor1').map((p) => p.id).toSet(),
          equals(manualOwned('minor1')),
        );
        expect(
          cache.provincesOwnedBy('minor1').map((p) => p.id).toSet(),
          equals({'oldWorld|p2', 'newWorld|n2'}),
        );
      },
    );

    test('owned-province region-id sets span old and new world', () {
      final world = gameWithResources(const {}).worldState;
      final cache = ProvinceOwnerCache.of(world);

      expect(
        cache.provincesOwnedBy('gp1').map((p) => p.regionId).toSet(),
        equals({'oldWorld', 'newWorld'}),
      );
      expect(
        cache.provincesOwnedBy('minor1').map((p) => p.regionId).toSet(),
        equals({'oldWorld', 'newWorld'}),
      );
    });

    test('resource-need bonus counts target resources from both regions', () {
      // Target owns one resource in the old world and a distinct resource in
      // the new world. Both must be counted (whole-world projection), so the
      // resource-need bonus delta is (2 missing * 5) = 10 over the no-resource
      // baseline.
      final withoutRes = gameWithResources(const {});
      final withRes = gameWithResources(const {
        'oldWorld|p2|0|0': 'tobacco',
        'newWorld|n2|0|0': 'sugar',
      });
      const relation = 40;

      final base = computeWarDesireScore(
        game: withoutRes,
        nationId: 'gp1',
        targetFactionId: 'minor1',
        relationScore: relation,
      );
      final boosted = computeWarDesireScore(
        game: withRes,
        nationId: 'gp1',
        targetFactionId: 'minor1',
        relationScore: relation,
      );

      expect(boosted - base, 10);
    });
  });
}
