import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import '../turn_resolver_test_harness.dart';

void registerCombatMovementOrdersTests() {
  group('combat movement', () {
    group('combat movement orders', () {
      test('naval move order targeting home fleet does not move it', () {
        final next = resolveTurnComplete(
          game: turnTestFleetsOnlyGame(fleets: [turnTestCarrackFleet(id: 'fleet_p1')]),
          topology: turnTestOwTwoLinkedSeaZonesTopology(),
          orders: Orders(
            navalMoveOrdersByPlayerId: {
              'p1': [
                const NavalMoveOrder(
                  fleetId: 'fleet_p1',
                  destinationSeaZoneId: 'sea2',
                ),
              ],
            },
          ),
        );
        expect(next.worldState.fleets.single.seaZoneId, 'sea1');
        expect(next.worldState.turnState.turnNumber, 1);
      });

      test(
        'dock at capital merges sea-going fleet into home fleet and reveals port tiles',
        () {
          const ow = kRegionOldWorld;
          const tileKey = '$ow|P1|0|0';
          final game = turnTestOwGame(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
            ],
            fleets: [
              turnTestCarrackFleet(
                id: 'fleet_p1',
                seaZoneId: null,
                inPortAtProvinceId: '$ow|P1',
              ),
              turnTestCarrackFleet(id: 'f2', shipTypeIds: const ['frigate']),
            ],
            players: const [
              Player(
                id: 'p1',
                displayName: 'A',
                isHuman: true,
                capitalProvinceId: '$ow|P1',
              ),
            ],
          );
          final next = resolveTurnComplete(
            game: game.copyWith(
              worldState: game.worldState.copyWith(
                tileKeysByRegionAndProvince: {
                  ow: {'$ow|P1': [tileKey]},
                },
                playerVisibilityByTile: {
                  'p1': {tileKey: 'fogged'},
                },
              ),
            ),
            topology: turnTestOwSeaProvinceTopology(),
            orders: Orders(
              navalMoveOrdersByPlayerId: {
                'p1': [
                  NavalMoveOrder(
                    fleetId: 'f2',
                    destinationPortProvinceId: '$ow|P1',
                  ),
                ],
              },
            ),
          );
          expect(next.worldState.fleets.length, 1);
          final home = next.worldState.fleets.single;
          expect(home.id, 'fleet_p1');
          expect(home.shipTypeIds.length, 2);
          expect(home.isInPort, isTrue);
          expect(
            next.worldState.playerVisibilityByTile['p1']?[tileKey],
            'fullyVisible',
          );
        },
      );

      test('naval move clears mission on fleet', () {
        final next = resolveTurnComplete(
          game: turnTestFleetsOnlyGame(
            fleets: [turnTestCarrackFleet(mission: FleetMission.patrol)],
          ),
          topology: turnTestOwTwoLinkedSeaZonesTopology(),
          orders: Orders(
            navalMoveOrdersByPlayerId: {
              'p1': [
                const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
              ],
            },
          ),
        );
        expect(next.worldState.fleets.single.mission, FleetMission.none);
      });

      test(
        'naval mission order skipped when naval move targets same fleet',
        () {
          final next = resolveTurnComplete(
            game: turnTestFleetsOnlyGame(fleets: [turnTestCarrackFleet()]),
            topology: turnTestOwTwoLinkedSeaZonesTopology(),
            orders: Orders(
              navalMoveOrdersByPlayerId: {
                'p1': [
                  const NavalMoveOrder(
                    fleetId: 'f1',
                    destinationSeaZoneId: 'sea2',
                  ),
                ],
              },
              navalMissionOrdersByPlayerId: {
                'p1': [NavalMissionOrder(fleetId: 'f1', mission: 'patrol')],
              },
            ),
          );
          expect(next.worldState.fleets.single.seaZoneId, 'sea2');
          expect(next.worldState.fleets.single.mission, FleetMission.none);
        },
      );
    });
  });
}
