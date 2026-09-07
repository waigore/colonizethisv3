// P->S undock end-of-turn cases (Refs #4740 Slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/ship_reveal_test_support.dart';

void registerShipRevealEndOfTurnUndockCases() {
  test(
    'P->S undock entry remains fully visible after end-of-turn and in PlayerView',
    () {
      const ow = 'oldWorld';
      const portProv = '$ow|pPort';
      const destSeaPrefixed = '$ow|seaDest';
      const destSeaTileA = '$ow|seaDest|4|0';
      const destSeaTileB = '$ow|seaDest|4|1';
      const coastTile = '$portProv|3|0';

      final topologies = shipRevealPrefixedLocalTopologyPair(
        regionId: ow,
        nodes: const [
          ('pPort', TopologyNodeType.province),
          ('seaDest', TopologyNodeType.seaZone),
        ],
        edges: const [('pPort', 'seaDest')],
      );

      final game = Game(
        id: 'gP2S',
        worldState: WorldState(
          turnState: const TurnState(
            phase: TurnPhase.movement,
            turnNumber: 7,
          ),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f2',
              ownerId: 'gp1',
              inPortAtProvinceId: portProv,
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
          tileKeysByRegionAndProvince: const {
            ow: {
              portProv: [coastTile],
              destSeaPrefixed: [destSeaTileA, destSeaTileB],
            },
          },
          playerVisibilityByTile: {
            'gp1': {
              destSeaTileA: VisibilityLevel.unknown.name,
              destSeaTileB: VisibilityLevel.unknown.name,
            },
          },
        ),
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
      );

      final result = applyShipRevealThenEndOfTurnView(
        game: game,
        moveTopology: topologies.combined,
        endOfTurnTopology: topologies.local,
        regionId: ow,
        navalMoveOrdersByPlayerId: {
          'gp1': [
            const NavalMoveOrder(
              fleetId: 'f2',
              destinationSeaZoneId: destSeaPrefixed,
            ),
          ],
        },
        turnNumber: 7,
      );

      expect(
        result.ended.worldState.playerVisibilityByTile['gp1']?[destSeaTileA],
        VisibilityLevel.fullyVisible.name,
      );
      expect(
        result.ended.worldState.playerVisibilityByTile['gp1']?[destSeaTileB],
        VisibilityLevel.fullyVisible.name,
      );
      expect(
        result.view.visibilityForTile(destSeaTileA),
        VisibilityLevel.fullyVisible,
      );
      expect(
        result.view.visibilityForTile(destSeaTileB),
        VisibilityLevel.fullyVisible,
      );
    },
  );
}
