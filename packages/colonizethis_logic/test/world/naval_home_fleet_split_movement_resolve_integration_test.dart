import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/turn/phases/movement_phase.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Integration path for GitHub #2010: split from Home Fleet (orders UI), then
/// movement phase applies naval moves and ship reveal using combined topology.
/// [runMovementPhase] is the resolver entry that calls [applyNavalMovesAndShipReveal].
void main() {
  group('naval home fleet split + movement phase (combined topology)', () {
    test('split ship to new fleet then OW sea move resolves without error when '
        'topology mixes Old World and New World edges', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const nw = 'newWorld';
      final homeId = homeFleetIdFor(playerId);
      const seaOrigin = '$ow|seaOrigin';
      const seaDest = '$ow|seaDest';
      const owCoastProv = '$ow|pCoast';
      const coastalTile = '$ow|pCoast|1|0';
      const inlandTile = '$ow|pCoast|0|0';
      const seaDestWater = '$ow|seaDest|2|0';

      final combinedTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: owCoastProv,
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: seaOrigin,
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: seaDest,
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: '$nw|p1',
            regionId: nw,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: '$nw|seaOther',
            regionId: nw,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [
          TopologyEdge(id1: owCoastProv, id2: seaDest),
          TopologyEdge(id1: seaOrigin, id2: seaDest),
          TopologyEdge(id1: '$nw|p1', id2: '$nw|seaOther'),
        ],
      );

      final gameBeforeSplit = Game(
        id: 'g_split_move_2010',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.movement, turnNumber: 2),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: homeId,
              ownerId: playerId,
              seaZoneId: seaOrigin,
              regionId: ow,
              ships: const [
                ShipInstance(id: 'ship_1', typeId: 'carrack'),
                ShipInstance(id: 'ship_2', typeId: 'fluyte'),
              ],
            ),
          ],
          tileKeysByRegionAndProvince: {
            ow: {
              owCoastProv: [coastalTile, inlandTile],
              seaDest: [seaDestWater],
              seaOrigin: const ['$ow|seaOrigin|0|0'],
            },
          },
          playerVisibilityByTile: {
            playerId: {
              coastalTile: VisibilityLevel.unknown.name,
              seaDestWater: VisibilityLevel.unknown.name,
            },
          },
        ),
        players: const [
          Player(id: playerId, displayName: 'GP1', isHuman: true),
        ],
      );

      final afterSplit = applyNavalSplitFleet(
        game: gameBeforeSplit,
        humanPlayerId: playerId,
        originalFleetId: homeId,
        shipInstanceIdsToNewFleet: const ['ship_2'],
      );

      final splitFleet = afterSplit.worldState.fleets.firstWhere(
        (f) => f.ownerId == playerId && f.id != homeId,
      );
      expect(splitFleet.seaZoneId, seaOrigin);
      expect(splitFleet.ships.single.id, 'ship_2');

      final orders = Orders(
        navalMoveOrdersByPlayerId: {
          playerId: [
            NavalMoveOrder(
              fleetId: splitFleet.id,
              destinationSeaZoneId: seaDest,
            ),
          ],
        },
      );

      Game? afterMovement;
      expect(() {
        afterMovement = runMovementPhase(afterSplit, combinedTopology, orders);
      }, returnsNormally);

      final resolved = afterMovement!;
      final moved = resolved.worldState.fleets.firstWhere(
        (f) => f.id == splitFleet.id,
      );
      expect(moved.seaZoneId, seaDest);

      final vis = resolved.worldState.playerVisibilityByTile[playerId]!;
      expect(vis[coastalTile], VisibilityLevel.fullyVisible.name);
      expect(vis[inlandTile], isNot(VisibilityLevel.fullyVisible.name));
      expect(vis[seaDestWater], VisibilityLevel.fullyVisible.name);
    });
  });
}
