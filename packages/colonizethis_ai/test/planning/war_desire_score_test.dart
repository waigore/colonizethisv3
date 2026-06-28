import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('computeWarDesireScore', () {
    test(
      'higher relative power and hostile relation yields higher war desire',
      () {
        final strongVsWeak = Game(
          id: 'g-desire-1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|p2',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|p3',
                  regionId: 'oldWorld',
                  ownerId: 'gp2',
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
                  locationProvinceId: 'oldWorld|p2',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
          ],
        );
        final weakVsStrong = strongVsWeak.copyWith(
          worldState: strongVsWeak.worldState.copyWith(
            oldWorld: RegionData(
              provinces: strongVsWeak.worldState.oldWorld.provinces,
              units: [
                Unit(
                  id: 'u3',
                  type: 'grenadiers',
                  ownerId: 'gp2',
                  locationProvinceId: 'oldWorld|p3',
                ),
                Unit(
                  id: 'u4',
                  type: 'grenadiers',
                  ownerId: 'gp2',
                  locationProvinceId: 'oldWorld|p3',
                ),
              ],
            ),
          ),
        );

        final high = computeWarDesireScore(
          game: strongVsWeak,
          nationId: 'gp1',
          targetFactionId: 'gp2',
          relationScore: 20,
        );
        final low = computeWarDesireScore(
          game: weakVsStrong,
          nationId: 'gp1',
          targetFactionId: 'gp2',
          relationScore: 80,
        );

        expect(high, greaterThan(low));
      },
    );

    test(
      'minor target with intervention risk and no navy reduces war desire',
      () {
        final game = Game(
          id: 'g-desire-2',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
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
              ],
            ),
            newWorld: RegionData(
              provinces: const [
                Province(
                  id: 'newWorld|n1',
                  regionId: 'newWorld',
                  ownerId: 'minor1',
                ),
              ],
              units: [
                Unit(
                  id: 'u2',
                  type: 'grenadiers',
                  ownerId: 'minor1',
                  locationProvinceId: 'newWorld|n1',
                ),
                Unit(
                  id: 'u3',
                  type: 'grenadiers',
                  ownerId: 'minor1',
                  locationProvinceId: 'newWorld|n1',
                ),
              ],
            ),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
            Player(id: 'gp3', displayName: 'C', isHuman: false),
          ],
          minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
          overtureStates: const [
            OvertureState(
              gpId: 'gp2',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
            ),
            OvertureState(
              gpId: 'gp3',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
            ),
          ],
        );
        final score = computeWarDesireScore(
          game: game,
          nationId: 'gp1',
          targetFactionId: 'minor1',
          relationScore: 40,
        );
        expect(score, lessThan(50));
      },
    );

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
