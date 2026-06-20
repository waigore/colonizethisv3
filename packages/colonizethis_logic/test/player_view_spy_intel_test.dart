import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('PlayerView', () {
    test(
      'province panel intel shows for foreign province with active spy timer',
      () {
        const ow = 'oldWorld';
        const provinceId = '$ow|p2';
        const tileKey = '$provinceId|0|0';
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'gp2'),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                provinceId: [tileKey],
              },
            },
            playerVisibilityByTile: const {
              'gp1': {tileKey: 'fogged'},
            },
            spyRevealTurnsByPlayer: const {
              'gp1': {provinceId: 2},
            },
          ),
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: true),
            Player(id: 'gp2', displayName: 'GP2', isHuman: false),
          ],
        );
        final topology = MapTopology(nodes: const [], edges: const []);
        final view = buildPlayerView(game, topology, 'gp1');
        expect(
          provincePanelShowsFullTileDerivedIntel(
            game: game,
            view: view,
            humanPlayerId: 'gp1',
            provinceId: provinceId,
          ),
          isTrue,
        );
      },
    );
  });
}
