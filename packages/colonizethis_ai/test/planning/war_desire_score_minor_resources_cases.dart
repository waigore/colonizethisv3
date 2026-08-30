// Topic-split pins from `war_desire_score_test.dart` (Refs #4669 Slice D).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void registerWarDesireScoreMinorResourcesCases() {
  group('computeWarDesireScore', () {
    test(
      'minor target resources increase war desire when GP stockpile lacks them',
      () {
        const tileKey = 'oldWorld|p2|0|0';
        WorldState state({
          required Map<String, String> resources,
        }) => WorldState(
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
              Unit(
                id: 'u3',
                type: 'grenadiers',
                ownerId: 'minor1',
                locationProvinceId: 'oldWorld|p2',
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|p2': [tileKey],
            },
          },
          resourceByTileKey: resources,
        );
        final withoutRes = Game(
          id: 'g-res-0',
          worldState: state(resources: const {}),
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
        final withRes = withoutRes.copyWith(
          id: 'g-res-1',
          worldState: state(resources: {tileKey: 'tobacco'}),
        );
        const relation = 40;
        final a = computeWarDesireScore(
          game: withoutRes,
          nationId: 'gp1',
          targetFactionId: 'minor1',
          relationScore: relation,
        );
        final b = computeWarDesireScore(
          game: withRes,
          nationId: 'gp1',
          targetFactionId: 'minor1',
          relationScore: relation,
        );
        expect(b - a, 5);
      },
    );
  });
}
