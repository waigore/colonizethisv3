import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

void main() {
  group('evaluateCapitalReassignmentEligibility', () {
    test(
      'returns deterministic candidate when owner has provinces in region',
      () {
        final game = TestFixtures.minimalGame(
          id: 'g-cap-eligible',
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );

        final eligibility = evaluateCapitalReassignmentEligibility(
          state: game,
          playerId: 'p1',
          regionId: 'oldWorld',
          regionTopology: const MapTopology(),
        );

        expect(eligibility.eligible, isTrue);
        expect(eligibility.reasonCode, 'eligible');
        expect(eligibility.candidateProvinceId, 'oldWorld|P1');
      },
    );

    test('reports ineligible when owner has no provinces in region', () {
      final game = TestFixtures.minimalGame(
        id: 'g-cap-ineligible',
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p2'),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final eligibility = evaluateCapitalReassignmentEligibility(
        state: game,
        playerId: 'p1',
        regionId: 'oldWorld',
        regionTopology: const MapTopology(),
      );

      expect(eligibility.eligible, isFalse);
      expect(eligibility.reasonCode, 'no_owned_provinces_in_region');
      expect(eligibility.candidateProvinceId, isNull);
    });

    // Phase 6b slice 15 (SPEC/program/worldstate-projection.md; Refs #3393):
    // the owned-province lookup now reads ProvinceOwnerCache; these assert the
    // migration is behaviour-preserving against the projection and the prior
    // `region.provinces.where((p) => p.ownerId == ...)` scan order.
    test(
      'ownedProvinceIdsInRegion matches projection in region list order',
      () {
        final game = TestFixtures.minimalGame(
          id: 'g-cap-projection-parity',
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'oldWorld|P3', regionId: 'oldWorld', ownerId: 'p2'),
            ],
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );

        final eligibility = evaluateCapitalReassignmentEligibility(
          state: game,
          playerId: 'p1',
          regionId: kRegionOldWorld,
          regionTopology: const MapTopology(),
        );

        final projectionIds = ProvinceOwnerCache.of(game.worldState)
            .provincesOwnedByInRegion('p1', kRegionOldWorld)
            .map((p) => p.id)
            .toList();
        final legacyScanIds = game.worldState.oldWorld.provinces
            .where((p) => p.ownerId == 'p1')
            .map((p) => p.id)
            .toList();

        expect(eligibility.ownedProvinceIdsInRegion, ['oldWorld|P2', 'oldWorld|P1']);
        expect(eligibility.ownedProvinceIdsInRegion, projectionIds);
        expect(eligibility.ownedProvinceIdsInRegion, legacyScanIds);
      },
    );

    test('excludedProvinceId is filtered out after the projection lookup', () {
      final game = TestFixtures.minimalGame(
        id: 'g-cap-excluded',
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'p1'),
            Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final eligibility = evaluateCapitalReassignmentEligibility(
        state: game,
        playerId: 'p1',
        regionId: kRegionOldWorld,
        regionTopology: const MapTopology(),
        excludedProvinceId: 'oldWorld|P2',
      );

      expect(eligibility.eligible, isTrue);
      expect(eligibility.ownedProvinceIdsInRegion, ['oldWorld|P1']);
      expect(eligibility.candidateProvinceId, 'oldWorld|P1');
    });
  });
}
