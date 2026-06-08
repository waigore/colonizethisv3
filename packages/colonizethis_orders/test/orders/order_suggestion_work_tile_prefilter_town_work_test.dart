import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_work_tile_prefilter.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('rawCandidateTilesForWorkTarget (town work)', () {
    test(
      'upgrade_town includes town tiles only in owned provinces with a town',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const ownedTownTile = 'oldWorld|p1|0|0';
        const otherTownTile = 'oldWorld|p2|0|0';
        final game = Game(
          id: 'g-town-prefilter',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: '$ow|p1',
                  regionId: ow,
                  ownerId: playerId,
                  townTileKey: ownedTownTile,
                ),
                Province(
                  id: '$ow|p2',
                  regionId: ow,
                  ownerId: 'gp2',
                  townTileKey: otherTownTile,
                ),
              ],
              units: const [],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: playerId, displayName: 'GP', isHuman: true),
            Player(id: 'gp2', displayName: 'GP2', isHuman: false),
          ],
        );

        final tiles = rawCandidateTilesForWorkTarget(
          game: game,
          playerId: playerId,
          workTarget: kWorkTargetUpgradeTown,
          playerOwnedProvinceIds: {'$ow|p1'},
        );

        expect(tiles, equals({ownedTownTile}));
        expect(tiles, isNot(contains(otherTownTile)));
      },
    );

    test(
      'build_fort matches upgrade_town town-tile prefilter for shared owned set',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const townTile = 'oldWorld|p1|0|0';
        final game = Game(
          id: 'g-fort-prefilter',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: '$ow|p1',
                  regionId: ow,
                  ownerId: playerId,
                  townTileKey: townTile,
                ),
              ],
              units: const [],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: playerId, displayName: 'GP', isHuman: true),
          ],
        );
        const owned = {'$ow|p1'};

        final upgradeTiles = rawCandidateTilesForWorkTarget(
          game: game,
          playerId: playerId,
          workTarget: kWorkTargetUpgradeTown,
          playerOwnedProvinceIds: owned,
        );
        final fortTiles = rawCandidateTilesForWorkTarget(
          game: game,
          playerId: playerId,
          workTarget: kWorkTargetBuildFort,
          playerOwnedProvinceIds: owned,
        );

        expect(fortTiles, upgradeTiles);
        expect(fortTiles, equals({townTile}));
      },
    );
  });
}
