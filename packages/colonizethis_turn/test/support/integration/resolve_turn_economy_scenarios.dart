import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import '../turn_resolver_test_harness.dart';

void registerEconomyCoreTests() {
  group('economy phases', () {
    group('economy phases', () {
      test('runs extraction, consumption, production, and movement phases', () {
        final topology = twoAdjacentOldWorldProvinceTopology();
        const ow = turnTestOldWorldRegionId;
        final game = adjacentOwP1P2Game(
          province1OwnerId: 'p1',
          province2OwnerId: 'p1',
          units: [
            Unit(
              id: 'u1',
              type: 'Regiment',
              ownerId: 'p1',
              locationProvinceId: '$ow|P1',
            ),
          ],
          players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
        );

        final orders = Orders(
          moveOrdersByPlayerId: {
            'p1': [MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P2|0|0')],
          },
        );

        final next = resolveTurnComplete(
          game: game,
          topology: topology,
          orders: orders,
          extractedByPlayerId: const {'p1': {'grain': 3}},
        );

        expect(next.worldState.turnState.turnNumber, 1);
        expect(
          next.worldState.oldWorld.units.single.locationProvinceId,
          '$ow|P2',
        );
        expect(next.players.single.stockpile.quantityOf('grain'), 3);
      });

      test(
        'army move within own provinces across regions is instantaneous',
        () {
          final topology = turnTestOwNwCrossRegionTopology();
          const ow = kRegionOldWorld;
          const nw = kRegionNewWorld;
          final game = ensureMilitaryArmiesForGame(
            turnTestOwNwCrossRegionGame(
              owUnits: [
                Unit(
                  id: 'u1',
                  type: 'musketeers',
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P1',
                ),
              ],
              playerVisibilityByTile: const {
                'p1': {
                  'oldWorld|P1|0|0': 'fullyVisible',
                  'newWorld|P2|0|0': 'fullyVisible',
                },
              },
            ),
          );

          final next = resolveTurnComplete(
            game: game,
            topology: topology,
            orders: Orders(
              armyMoveOrdersByPlayerId: {
                'p1': [
                  ArmyMoveOrder(
                    armyId: fieldArmyIdFor('p1', '$ow|P1'),
                    destinationProvinceId: '$nw|P2',
                  ),
                ],
              },
            ),
          );

          expect(next.worldState.turnState.turnNumber, 1);
          expect(next.worldState.oldWorld.units, isEmpty);
          expect(next.worldState.newWorld.units.single.id, 'u1');
          expect(
            next.worldState.newWorld.units.single.locationProvinceId,
            '$nw|P2',
          );
        },
      );

      test(
        'civilian move within own provinces across regions is instantaneous and sets tileKey',
        () {
          final topology = turnTestOwNwCrossRegionTopology();
          const ow = kRegionOldWorld;
          const nw = kRegionNewWorld;
          const nwProv = '$nw|P2';
          const nwTile = '$nwProv|0|0';
          final game = turnTestOwNwCrossRegionGame(
            owUnits: [
              Unit(
                id: 'c1',
                type: kUnitTypeMerchant,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: '$ow|P1|0|0',
              ),
            ],
            tileKeysByRegionAndProvince: {
              nw: {nwProv: [nwTile]},
            },
            playerVisibilityByTile: const {
              'p1': {
                'oldWorld|P1|0|0': 'fullyVisible',
                'newWorld|P2|0|0': 'fullyVisible',
              },
            },
          );

          final next = resolveTurnComplete(
            game: game,
            topology: topology,
            orders: Orders(
              moveOrdersByPlayerId: {
                'p1': [
                  MoveOrder(unitId: 'c1', destinationTileKey: nwTile),
                ],
              },
            ),
          );

          expect(next.worldState.turnState.turnNumber, 1);
          expect(next.worldState.oldWorld.units, isEmpty);
          final moved = next.worldState.newWorld.units.single;
          expect(moved.id, 'c1');
          expect(moved.locationProvinceId, nwProv);
          expect(moved.tileKey, nwTile);
        },
      );

      test('riches to treasury phase converts riches in stockpile', () {
        final topology = turnTestOwSingleProvinceTopology();
        final game = turnTestOwSingleProvinceGame(
          stockpile: Stockpile(quantities: {'gold': 2, 'grain': 1}),
        );
        final next = resolveTurnComplete(
          game: game,
          topology: topology,
          orders: const Orders(),
        );
        expect(next.worldState.turnState.turnNumber, 1);
        expect(next.players.single.treasury, greaterThan(0));
        expect(next.players.single.stockpile.quantityOf('gold'), lessThan(2));
      });

      test(
        'consumption and combat run with feeding coverage when player has no food',
        () {
          final topology = twoAdjacentOldWorldProvinceTopology();
          const ow = turnTestOldWorldRegionId;
          final game = adjacentOwP1P2Game(
            ensureMilitaryArmies: true,
            province1OwnerId: 'p2',
            province2OwnerId: 'p2',
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: 'p1',
                locationProvinceId: '$ow|P2',
              ),
              Unit(
                id: 'u2',
                type: 'pikemen',
                ownerId: 'p2',
                locationProvinceId: '$ow|P1',
              ),
            ],
            players: [
              Player(
                id: 'p1',
                displayName: 'P1',
                isHuman: true,
                stockpile: Stockpile.empty,
              ),
              Player(
                id: 'p2',
                displayName: 'P2',
                isHuman: true,
                stockpile: Stockpile(quantities: {'grain': 10, 'meat': 10}),
              ),
            ],
          );
          final next = resolveTurnComplete(
            game: game,
            topology: topology,
            orders: Orders(
              armyMoveOrdersByPlayerId: {
                'p1': [
                  ArmyMoveOrder(
                    armyId: fieldArmyIdFor('p1', '$ow|P2'),
                    destinationProvinceId: '$ow|P1',
                  ),
                ],
              },
            ),
          );
          expect(next.worldState.turnState.turnNumber, 1);
          expect(next.worldState.oldWorld.units.length, lessThanOrEqualTo(2));
        },
      );
    });
  });
}
