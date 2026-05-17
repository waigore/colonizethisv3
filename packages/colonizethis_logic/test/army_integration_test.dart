import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  suppressLogsForTests();

  group('applyArmyMoveOrderForPlayer', () {
    test('last order per armyId wins', () {
      const pid = 'gp1';
      const armyId = 'army_field';
      var orders = const Orders();
      orders = applyArmyMoveOrderForPlayer(
        orders,
        pid,
        const ArmyMoveOrder(
          armyId: armyId,
          destinationProvinceId: 'oldWorld|p1',
        ),
      );
      orders = applyArmyMoveOrderForPlayer(
        orders,
        pid,
        const ArmyMoveOrder(
          armyId: armyId,
          destinationProvinceId: 'oldWorld|p2',
        ),
      );
      final list = orders.armyMoveOrdersByPlayerId[pid]!;
      expect(list.length, 1);
      expect(list.single.destinationProvinceId, 'oldWorld|p2');
    });
  });

  group('applyArmyMoveOrdersToRegion', () {
    test('moves all regiments to adjacent province', () {
      const p1 = 'oldWorld|a';
      const p2 = 'oldWorld|b';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'oldWorld|a',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|b',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'oldWorld|a', id2: 'oldWorld|b')],
      );
      const playerId = 'gp1';
      final u1 = Unit(
        id: 'r1',
        type: 'musketeers',
        ownerId: playerId,
        locationProvinceId: p1,
      );
      final u2 = Unit(
        id: 'r2',
        type: 'pikemen',
        ownerId: playerId,
        locationProvinceId: p1,
      );
      var ws = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            Province(id: p1, regionId: 'oldWorld', ownerId: playerId),
            Province(id: p2, regionId: 'oldWorld', ownerId: playerId),
          ],
          units: [u1, u2],
        ),
        newWorld: const RegionData(),
        armies: [
          Army(
            id: 'afield',
            ownerId: playerId,
            regionId: 'oldWorld',
            stationedProvinceId: p1,
            regimentUnitIds: const ['r1', 'r2'],
            isHomeArmy: false,
          ),
        ],
      );

      ws = applyArmyMoveOrdersToRegion(ws, topology, {
        playerId: [
          const ArmyMoveOrder(armyId: 'afield', destinationProvinceId: p2),
        ],
      }, regionId: 'oldWorld');

      final moved = ws.oldWorld.units
          .where((u) => u.id == 'r1' || u.id == 'r2')
          .toList();
      expect(moved.every((u) => u.locationProvinceId == p2), isTrue);
      final army = ws.armies.where((a) => a.id == 'afield').single;
      expect(army.stationedProvinceId, p2);
    });

    test('ignores home army move order', () {
      const cap = 'oldWorld|cap';
      const p2 = 'oldWorld|b';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'oldWorld|cap',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|b',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'oldWorld|cap', id2: 'oldWorld|b')],
      );
      const playerId = 'gp1';
      final hid = homeArmyIdFor(playerId);
      final u1 = Unit(
        id: 'r1',
        type: 'musketeers',
        ownerId: playerId,
        locationProvinceId: cap,
      );
      var ws = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            Province(id: cap, regionId: 'oldWorld', ownerId: playerId),
            Province(id: p2, regionId: 'oldWorld', ownerId: playerId),
          ],
          units: [u1],
        ),
        newWorld: const RegionData(),
        armies: [
          Army(
            id: hid,
            ownerId: playerId,
            regionId: 'oldWorld',
            stationedProvinceId: cap,
            regimentUnitIds: const ['r1'],
            isHomeArmy: true,
          ),
        ],
      );

      ws = applyArmyMoveOrdersToRegion(ws, topology, {
        playerId: [ArmyMoveOrder(armyId: hid, destinationProvinceId: p2)],
      }, regionId: 'oldWorld');

      expect(ws.oldWorld.units.single.locationProvinceId, cap);
      expect(ws.armies.single.stationedProvinceId, cap);
    });

    test(
      'cross-region army moves reuse updated army location between orders',
      () {
        const playerId = 'gp1';
        const oldProvince = 'oldWorld|p1';
        const newProvince = 'newWorld|n1';
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: oldProvince,
                  regionId: 'oldWorld',
                  ownerId: playerId,
                ),
              ],
              units: [
                Unit(
                  id: 'r1',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: oldProvince,
                ),
              ],
            ),
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: newProvince,
                  regionId: 'newWorld',
                  ownerId: playerId,
                ),
              ],
            ),
            armies: const [
              Army(
                id: 'field',
                ownerId: playerId,
                regionId: 'oldWorld',
                stationedProvinceId: oldProvince,
                regimentUnitIds: ['r1'],
              ),
            ],
          ),
          players: const [
            Player(id: playerId, displayName: 'P', isHuman: true),
          ],
        );

        final result = applyCrossRegionArmyMovesWithinOwnedProvinces(
          game: game,
          worldState: game.worldState,
          armyMoveOrdersByPlayerId: const {
            playerId: [
              ArmyMoveOrder(
                armyId: 'field',
                destinationProvinceId: newProvince,
              ),
              ArmyMoveOrder(
                armyId: 'field',
                destinationProvinceId: oldProvince,
              ),
            ],
          },
        );

        expect(result.remainingArmyMoveOrdersByPlayerId, isEmpty);
        expect(
          result.worldState.armies.single.stationedProvinceId,
          oldProvince,
        );
        expect(
          result.worldState.oldWorld.units.single.locationProvinceId,
          oldProvince,
        );
      },
    );
  });
}
