import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'end_of_turn_distant_sea_fog_integration_test_cases.dart';

void main() {
  group('applyDistantSeaZoneFogRevert end-of-turn integration', () {
    test(
      'coastal pass after distant restores shore-adjacent sea from fogged',
      () {
        const ow = 'oldWorld';
        const tileS1 = 'oldWorld|s1|0|0';
        final topology = provinceSeaZoneTopology(
          regionId: ow,
          provinceLocalId: 'p1',
          seaZoneId: 's1',
        );
        final game = distantSeaVisibilityGame(
          oldWorldProvinces: const [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
          ],
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|s1': [tileS1],
            },
          },
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );
        final afterDistant = applyDistantSeaZoneFogRevert(game, {
          'gp1': {tileS1: VisibilityLevel.fogged.name},
        }, topology);
        expect(afterDistant['gp1']![tileS1], VisibilityLevel.fogged.name);
        final afterCoastal = applyCoastalSeaZoneFullVisibility(
          game,
          afterDistant,
          topology,
        );
        expect(afterCoastal['gp1']![tileS1], VisibilityLevel.fullyVisible.name);
      },
    );

    test(
      'runEndOfTurnPhase fogs distant sea then coastal restores owned shore',
      () {
        const ow = 'oldWorld';
        const tileS1 = 'oldWorld|s1|0|0';
        const tileS2 = 'oldWorld|s2|0|0';
        final topology = provinceSeaChainTopology(ow);
        final game = distantSeaVisibilityGame(
          turnNumber: 5,
          oldWorldProvinces: const [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
          ],
          playerVisibilityByTile: {
            'gp1': {
              tileS1: VisibilityLevel.fullyVisible.name,
              tileS2: VisibilityLevel.fullyVisible.name,
            },
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|s1': [tileS1],
              '$ow|s2': [tileS2],
            },
          },
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );

        final next = runEndOfTurnPhase(game, topology: topology);

        expect(next.worldState.turnState.turnNumber, 6);
        expect(next.worldState.turnState.phase, TurnPhase.orders);
        expect(
          next.worldState.playerVisibilityByTile['gp1']![tileS2],
          VisibilityLevel.fogged.name,
        );
        expect(
          next.worldState.playerVisibilityByTile['gp1']![tileS1],
          VisibilityLevel.fullyVisible.name,
        );
      },
    );

    test('GitHub #2023: runEndOfTurnPhase completes when OW fleet at sea and '
        'topologyByRegion splits regions (distant fog revert path)', () {
      const ow = kRegionOldWorld;
      const nw = kRegionNewWorld;
      const tileNwSea = 'newWorld|nwSea|0|0';
      final topologies = owSeaChainWithIsolatedNwSea();
      final game = distantSeaVisibilityGame(
        id: 'g_eot_2023',
        turnNumber: 5,
        oldWorldProvinces: const [
          Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
        ],
        playerVisibilityByTile: {
          'gp1': {
            'oldWorld|p1|0|0': VisibilityLevel.fullyVisible.name,
            'oldWorld|s1|0|0': VisibilityLevel.fullyVisible.name,
            'oldWorld|s2|0|0': VisibilityLevel.fullyVisible.name,
            tileNwSea: VisibilityLevel.fullyVisible.name,
          },
        },
        tileKeysByRegionAndProvince: {
          ow: {
            '$ow|p1': const ['oldWorld|p1|0|0'],
            '$ow|s1': const ['oldWorld|s1|0|0'],
            '$ow|s2': const ['oldWorld|s2|0|0'],
          },
          nw: {
            '$nw|nwSea': [tileNwSea],
          },
        },
        fleets: [
          Fleet(
            id: 'f_ow',
            ownerId: 'gp1',
            seaZoneId: 's2',
            regionId: ow,
            shipTypeIds: const ['carrack'],
          ),
        ],
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
      );

      final next = runEndOfTurnPhase(
        game,
        topology: topologies.combined,
        topologyByRegion: {ow: topologies.ow, nw: topologies.nw},
      );

      expect(next.worldState.turnState.turnNumber, 6);
      expect(next.worldState.turnState.phase, TurnPhase.orders);
      expect(
        next.worldState.playerVisibilityByTile['gp1']![tileNwSea],
        VisibilityLevel.fogged.name,
      );
    });

    test(
      'runEndOfTurnPhase leaves unknown New World land unknown (turn 0→1)',
      () {
        const ow = 'oldWorld';
        const nw = 'newWorld';
        const nwTile = 'newWorld|P2|0|0';
        final topology = dualRegionLandOnlyTopology();
        final game = distantSeaVisibilityGame(
          oldWorldProvinces: const [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
          ],
          newWorldProvinces: const [
            Province(id: '$nw|P2', regionId: nw, ownerId: 'p2'),
          ],
          playerVisibilityByTile: {
            'gp1': {
              'oldWorld|p1|0|0': VisibilityLevel.fullyVisible.name,
              nwTile: VisibilityLevel.unknown.name,
            },
          },
          tileKeysByRegionAndProvince: {
            ow: {
              'p1': ['oldWorld|p1|0|0'],
            },
            nw: {
              'P2': [nwTile],
            },
          },
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: false),
          ],
        );

        final next = runEndOfTurnPhase(game, topology: topology);

        expect(next.worldState.turnState.turnNumber, 1);
        expect(
          next.worldState.playerVisibilityByTile['gp1']![nwTile],
          VisibilityLevel.unknown.name,
        );
      },
    );
  });
}
