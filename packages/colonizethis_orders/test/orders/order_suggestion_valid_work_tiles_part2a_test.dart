import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

void main() {
  group('getValidWorkOrderTileKeys', () {
    test(
      'getValidWorkOrderTileKeysWithVisibility explore only scans partially revealed provinces',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const partialProvince = '$ow|p_partial';
        const fullProvince = '$ow|p_full';
        const unknownProvince = '$ow|p_unknown';
        const partialKnownTile = 'oldWorld|p_partial|0|0';
        const partialUnknownTile = 'oldWorld|p_partial|1|0';
        const fullTile = 'oldWorld|p_full|0|0';
        const unknownTile = 'oldWorld|p_unknown|0|0';

        final explorer = Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: partialProvince,
          tileKey: partialKnownTile,
        );
        final game = TestFixtures.minimalGame(
          id: 'g1',
          players: const [
            Player(id: playerId, displayName: 'GP', isHuman: false),
          ],
          tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe')],
          // Refs #3753 R4: explore/prospect in a Tribe province require a
          // Consulate (or higher); the suggestion path shares the work-order
          // validator, so a consulate is needed for these tiles to be valid.
          overtureStates: const [
            OvertureState(
              gpId: playerId,
              targetId: 'tribe1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
          oldWorld: RegionData(
            provinces: [
              Province(id: partialProvince, regionId: ow, ownerId: 'tribe1'),
              Province(id: fullProvince, regionId: ow, ownerId: 'tribe1'),
              Province(id: unknownProvince, regionId: ow, ownerId: 'tribe1'),
            ],
            units: [explorer],
          ),
          tileKeysByRegionAndProvince: {
            ow: {
              partialProvince: [partialKnownTile, partialUnknownTile],
              fullProvince: [fullTile],
              unknownProvince: [unknownTile],
            },
          },
          playerVisibilityByTile: const {
            playerId: {
              partialKnownTile: 'fogged',
              fullTile: 'fullyVisible',
              unknownTile: 'unknown',
            },
          },
        );
        final topology = const MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, playerId);

        final valid = getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: topology,
          view: view,
          unitId: 'u1',
          workTarget: kWorkTargetExplore,
          currentOrders: const Orders(),
        );

        expect(valid, contains(partialKnownTile));
        expect(valid, isNot(contains(fullTile)));
        expect(valid, isNot(contains(unknownTile)));
      },
    );

    test(
      'getValidWorkOrderTileKeysWithVisibility explore remains under one second on large map fixture',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const provinceCount = 120;
        const tilesPerProvince = 12;
        final byProvince = <String, List<String>>{};
        final visibility = <String, String>{};
        final provinces = <Province>[];

        for (var p = 0; p < provinceCount; p++) {
          final provinceId = '$ow|p$p';
          provinces.add(
            Province(id: provinceId, regionId: ow, ownerId: 'tribe1'),
          );
          final tiles = <String>[];
          for (var t = 0; t < tilesPerProvince; t++) {
            final tileKey = '$ow|p$p|$t|0';
            tiles.add(tileKey);
            if (p.isEven && t == 0) {
              visibility[tileKey] = 'fogged';
            } else if (p.isEven && t == 1) {
              visibility[tileKey] = 'unknown';
            } else {
              visibility[tileKey] = 'unknown';
            }
          }
          byProvince[provinceId] = tiles;
        }

        final startTile = '$ow|p0|0|0';
        final explorer = Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: '$ow|p0',
          tileKey: startTile,
        );
        final game = Game(
          id: 'g-latency',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(provinces: provinces, units: [explorer]),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {ow: byProvince},
            playerVisibilityByTile: {playerId: visibility},
          ),
          players: const [
            Player(id: playerId, displayName: 'GP', isHuman: false),
          ],
          tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe')],
          // Refs #3753 R4: a Consulate is required to explore Tribe provinces.
          overtureStates: const [
            OvertureState(
              gpId: playerId,
              targetId: 'tribe1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
        );
        final topology = const MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, playerId);

        final sw = Stopwatch()..start();
        final valid = getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: topology,
          view: view,
          unitId: 'u1',
          workTarget: kWorkTargetExplore,
          currentOrders: const Orders(),
        );
        sw.stop();

        expect(valid, isNotEmpty);
        expect(sw.elapsedMilliseconds, lessThan(1000));
      },
    );
  });
}
