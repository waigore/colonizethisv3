import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Eligibility pins for [evaluateCapitalReassignmentEligibility] (Refs #4515).
typedef CapitalEligibilityCase = ({
  String description,
  Game game,
  String playerId,
  String regionId,
  String? excludedProvinceId,
  void Function(CapitalReassignmentEligibility result, Game game) verify,
});

final List<CapitalEligibilityCase> capitalEligibilityCases = [
  (
    description:
        'returns deterministic candidate when owner has provinces in region',
    game: TestFixtures.minimalGame(
      id: 'g-cap-eligible',
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'p1'),
          Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
        ],
      ),
      players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
    ),
    playerId: 'p1',
    regionId: 'oldWorld',
    excludedProvinceId: null,
    verify: (eligibility, _) {
      expect(eligibility.eligible, isTrue);
      expect(eligibility.reasonCode, 'eligible');
      expect(eligibility.candidateProvinceId, 'oldWorld|P1');
    },
  ),
  (
    description: 'reports ineligible when owner has no provinces in region',
    game: TestFixtures.minimalGame(
      id: 'g-cap-ineligible',
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p2'),
        ],
      ),
      players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
    ),
    playerId: 'p1',
    regionId: 'oldWorld',
    excludedProvinceId: null,
    verify: (eligibility, _) {
      expect(eligibility.eligible, isFalse);
      expect(eligibility.reasonCode, 'no_owned_provinces_in_region');
      expect(eligibility.candidateProvinceId, isNull);
    },
  ),
  (
    description:
        'ownedProvinceIdsInRegion matches projection in region list order',
    game: TestFixtures.minimalGame(
      id: 'g-cap-projection-parity',
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'p1'),
          Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
          Province(id: 'oldWorld|P3', regionId: 'oldWorld', ownerId: 'p2'),
        ],
      ),
      players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
    ),
    playerId: 'p1',
    regionId: kRegionOldWorld,
    excludedProvinceId: null,
    verify: (eligibility, game) {
      final projectionIds = ProvinceOwnerCache.of(game.worldState)
          .provincesOwnedByInRegion('p1', kRegionOldWorld)
          .map((p) => p.id)
          .toList();
      final legacyScanIds = game.worldState.oldWorld.provinces
          .where((p) => p.ownerId == 'p1')
          .map((p) => p.id)
          .toList();
      expect(eligibility.ownedProvinceIdsInRegion, [
        'oldWorld|P2',
        'oldWorld|P1',
      ]);
      expect(eligibility.ownedProvinceIdsInRegion, projectionIds);
      expect(eligibility.ownedProvinceIdsInRegion, legacyScanIds);
    },
  ),
  (
    description:
        'excludedProvinceId is filtered out after the projection lookup',
    game: TestFixtures.minimalGame(
      id: 'g-cap-excluded',
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'p1'),
          Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
        ],
      ),
      players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
    ),
    playerId: 'p1',
    regionId: kRegionOldWorld,
    excludedProvinceId: 'oldWorld|P2',
    verify: (eligibility, _) {
      expect(eligibility.eligible, isTrue);
      expect(eligibility.ownedProvinceIdsInRegion, ['oldWorld|P1']);
      expect(eligibility.candidateProvinceId, 'oldWorld|P1');
    },
  ),
];
