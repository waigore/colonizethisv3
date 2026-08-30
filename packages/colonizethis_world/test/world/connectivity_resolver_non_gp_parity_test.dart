import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import '../world_test_support/world_test_support.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void main() {
  _connectivity_resolver_non_gp_parity_testTests();
}

void _connectivity_resolver_non_gp_parity_testTests() {
  group('resolveNonGreatPowerConnectivity parity / policy', () {
    test(
      'war does not block market access: enemy fleet on Blockade against minor port leaves minor connectivity unchanged',
      () {
        const ow = 'oldWorld';
        // Two-province OW: p1 inland (capital), p2 seaboard (port).
        final tileMap = tileMapFromGrid([
          ['p1', 'p2'],
          ['p1', 'p2'],
        ]);
        final topology = inlandAndSeaboardProvincesTopology(regionId: ow);
        final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
        // Road from capital tile through both provinces' tiles to the port.
        final tileState = TileMapState()
            .setRoadLevel('oldWorld|p1|0|0', 1)
            .setRoadLevel('oldWorld|p1|0|1', 1)
            .setRoadLevel('oldWorld|p2|1|0', 1)
            .setRoadLevel('oldWorld|p2|1|1', 1);
        // Port tile in p2.
        final ports = {'$ow|p2|sea1': 'oldWorld|p2|1|0'};
        // Enemy GP fleet at sea on Blockade against minor's port province p2.
        final blockadingFleet = Fleet(
          id: 'fleet_attacker',
          ownerId: 'gp_enemy',
          seaZoneId: 'sea1',
          inPortAtProvinceId: null,
          regionId: ow,
          mission: FleetMission.blockade,
          targetProvinceId: '$ow|p2',
        );

        final gameNoFleet = ordersPhaseGame(
          oldWorldProvinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
            Province(id: '$ow|p2', regionId: ow, ownerId: 'minor_lux'),
          ],
          tileState: tileState,
          portsByProvinceSeaboard: ports,
          players: const [],
          minorNations: [
            MinorNation(
              id: 'minor_lux',
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );

        final gameWithBlockade = ordersPhaseGame(
          oldWorldProvinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
            Province(id: '$ow|p2', regionId: ow, ownerId: 'minor_lux'),
          ],
          tileState: tileState,
          portsByProvinceSeaboard: ports,
          fleets: [blockadingFleet],
          players: const [],
          minorNations: [
            MinorNation(
              id: 'minor_lux',
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );

        final tileMapByRegion = {'oldWorld': tileMap};
        final noFleetResult = resolveNonGreatPowerConnectivity(
          game: gameNoFleet,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        );
        final blockadedResult = resolveNonGreatPowerConnectivity(
          game: gameWithBlockade,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        );

        // Identical connected sets: blockade does not affect non-GP connectivity.
        expect(
          blockadedResult['minor_lux']!.connected,
          equals(noFleetResult['minor_lux']!.connected),
        );
        // Sanity: the port tile is connected in both cases.
        expect(
          blockadedResult['minor_lux']!.connected.contains('oldWorld|p2|1|0'),
          isTrue,
        );
      },
    );

    test(
      'parity: GP and non-GP resolvers produce the same per-tile connected set for equivalent inputs',
      () {
        // Build a single 3x3 owned province with a road at (0,1). Run the GP
        // resolver for a player with capitalProvinceId/capitalTile set, and the
        // non-GP resolver for a minor with the same capitalProvinceId and
        // capitalTile values. Verify their `connected` sets are identical (the
        // shared Road and Town rules apply faction-agnostically).
        const ow = 'oldWorld';
        final tileMap = uniformProvinceTileMap('p1', size: 3);
        final topology = singleProvinceTopology(
          regionId: ow,
          provinceLocalId: 'p1',
        );
        final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 1, y: 1);
        final tileState = TileMapState()
            .setRoadLevel('oldWorld|p1|1|1', 1)
            .setRoadLevel('oldWorld|p1|0|1', 1)
            .setRoadLevel('oldWorld|p1|0|0', 1);

        final gpGame = ordersPhaseGame(
          oldWorldProvinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
          ],
          tileState: tileState,
          players: [
            Player(
              id: 'pl1',
              displayName: 'Spain',
              isHuman: true,
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );
        final minorGame = ordersPhaseGame(
          oldWorldProvinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
          ],
          tileState: tileState,
          players: const [],
          minorNations: [
            MinorNation(
              id: 'minor_lux',
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );

        final tileMapByRegion = {'oldWorld': tileMap};
        final gpResult = resolveConnectivity(
          game: gpGame,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        );
        final minorResult = resolveNonGreatPowerConnectivity(
          game: minorGame,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        );

        expect(
          minorResult['minor_lux']!.connected,
          equals(gpResult['pl1']!.connected),
        );
      },
    );

    test(
      'GP and non-GP resolvers run independently — non-GP call does not return GP keys',
      () {
        const ow = 'oldWorld';
        final tileMap = tileMapFromGrid([
          ['p1', 'p2'],
        ]);
        final topology = twoProvinceLandTopology(regionId: ow);
        final gpCap = CapitalTile(
          regionId: ow,
          provinceId: '$ow|p1',
          x: 0,
          y: 0,
        );
        final minorCap = CapitalTile(
          regionId: ow,
          provinceId: '$ow|p2',
          x: 1,
          y: 0,
        );
        final game = ordersPhaseGame(
          oldWorldProvinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
            Province(id: '$ow|p2', regionId: ow, ownerId: 'minor_lux'),
          ],
          players: [
            Player(
              id: 'pl1',
              displayName: 'Spain',
              isHuman: true,
              capitalProvinceId: '$ow|p1',
              capitalTile: gpCap,
            ),
          ],
          minorNations: [
            MinorNation(
              id: 'minor_lux',
              capitalProvinceId: '$ow|p2',
              capitalTile: minorCap,
            ),
          ],
        );

        final nonGpResult = resolveNonGreatPowerConnectivity(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap},
          topology: topology,
        );

        // The non-GP call only emits keys for minors and tribes. No GP player
        // id appears in the result map.
        expect(nonGpResult.containsKey('pl1'), isFalse);
        expect(nonGpResult.keys.toSet(), {'minor_lux'});
      },
    );
  });
}
