import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import '../turn_resolver_test_harness.dart';

void registerCombatResolutionContinuedTests() {
  group('combat resolution', () {
    group('combat resolution continued', () {
      test(
        'validateOrdersAndResolveTurn filters invalid order and applies only valid move',
        () {
          const ow = turnTestOldWorldRegionId;
          final topology = twoAdjacentOldWorldProvinceTopology();
          final game = adjacentOwP1P2Game(
            province1OwnerId: 'p1',
            province2OwnerId: 'p1',
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeBuilder,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
              ),
            ],
            playerVisibilityByTile: {
              'p1': {
                turnTestOwTileKey('P1'): 'fullyVisible',
                turnTestOwTileKey('P2'): 'fullyVisible',
              },
            },
            players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
          );
          final orders = Orders(
            moveOrdersByPlayerId: {
              'p1': [
                MoveOrder(
                  unitId: 'u1',
                  destinationTileKey: turnTestOwTileKey('P2'),
                ),
                MoveOrder(
                  unitId: 'u999',
                  destinationTileKey: turnTestOwTileKey('P2'),
                ),
              ],
            },
          );
          final next = requireTurnResolutionComplete(
            validateOrdersAndResolveTurn(
              game: game,
              topology: topology,
              orders: orders,
              extractedByPlayerId: const {},
              defaultAssignments: const [],
            ),
          );
          expect(next.worldState.turnState.turnNumber, 1);
          expect(next.worldState.oldWorld.units.length, 1);
          expect(
            next.worldState.oldWorld.units.single.locationProvinceId,
            '$ow|P2',
          );
        },
      );

      test('movement phase applies naval mission order', () {
        final next = resolveTurnComplete(
          game: turnTestFleetsOnlyGame(
            fleets: [turnTestCarrackFleet(mission: FleetMission.none)],
          ),
          topology: turnTestOwSeaZoneTopology(),
          orders: Orders(
            navalMissionOrdersByPlayerId: {
              'p1': [
                NavalMissionOrder(
                  fleetId: 'f1',
                  mission: FleetMission.patrol.name,
                ),
              ],
            },
          ),
        );
        expect(next.worldState.fleets.single.mission, FleetMission.patrol);
        expect(next.worldState.turnState.turnNumber, 1);
      });

      test('movement phase applies naval move order to adjacent sea zone', () {
        final next = resolveTurnComplete(
          game: turnTestFleetsOnlyGame(fleets: [turnTestCarrackFleet()]),
          topology: turnTestOwTwoLinkedSeaZonesTopology(),
          orders: Orders(
            navalMoveOrdersByPlayerId: {
              'p1': [
                NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
              ],
            },
          ),
        );
        expect(next.worldState.fleets.single.seaZoneId, 'sea2');
        expect(next.worldState.turnState.turnNumber, 1);
      });

      test('dock order moves fleet from sea to port at owned province', () {
        const ow = kRegionOldWorld;
        final next = resolveTurnComplete(
          game: turnTestOwGame(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
            ],
            fleets: [turnTestCarrackFleet()],
          ),
          topology: turnTestOwSeaProvinceTopology(),
          orders: Orders(
            navalMoveOrdersByPlayerId: {
              'p1': [
                NavalMoveOrder(
                  fleetId: 'f1',
                  destinationPortProvinceId: '$ow|P1',
                ),
              ],
            },
          ),
        );
        final fleet = next.worldState.fleets.single;
        expect(fleet.isInPort, isTrue);
        expect(fleet.inPortAtProvinceId, '$ow|P1');
        expect(fleet.seaZoneId, isNull);
      });

      test('naval move order undocks fleet from port to adjacent sea zone', () {
        const ow = kRegionOldWorld;
        final next = resolveTurnComplete(
          game: turnTestOwGame(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
            ],
            fleets: [
              turnTestCarrackFleet(
                seaZoneId: null,
                inPortAtProvinceId: '$ow|P1',
              ),
            ],
          ),
          topology: turnTestOwSeaProvinceTopology(),
          orders: Orders(
            navalMoveOrdersByPlayerId: {
              'p1': [
                const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea1'),
              ],
            },
          ),
        );
        final fleet = next.worldState.fleets.single;
        expect(fleet.isAtSea, isTrue);
        expect(fleet.seaZoneId, 'sea1');
        expect(fleet.inPortAtProvinceId, isNull);
      });
    });
  });
}
