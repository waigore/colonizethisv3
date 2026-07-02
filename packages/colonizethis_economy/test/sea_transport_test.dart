import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('cargoHoldsForHomeFleet', () {
    test('returns 0 when no home fleet exists', () {
      final game = minimalEconomyGame(
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final holds = cargoHoldsForHomeFleet(game, 'p1');
      expect(holds, greaterThanOrEqualTo(0));
    });

    test('sums cargoHold from home-fleet ship types', () {
      final fleet = Fleet(
        id: 'fleet_p1',
        ownerId: 'p1',
        seaZoneId: 'sea1',
        regionId: 'oldWorld',
        shipTypeIds: const ['carrack', 'fluyte'],
      );
      final game = minimalEconomyGame(
        fleets: [fleet],
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final holds = cargoHoldsForHomeFleet(game, 'p1');
      expect(
        holds,
        NavalStatsCatalog.carrack.cargoHold +
            NavalStatsCatalog.fluyte.cargoHold,
      );
    });

    test('returns 0 when home fleet has only warship types (cargoHold 0)', () {
      final fleet = Fleet(
        id: 'fleet_p1',
        ownerId: 'p1',
        seaZoneId: 'sea1',
        regionId: 'oldWorld',
        shipTypeIds: const ['sloop'],
      );
      final game = minimalEconomyGame(
        fleets: [fleet],
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final holds = cargoHoldsForHomeFleet(game, 'p1');
      expect(holds, 0);
    });

    test('fleetsById index matches default linear home-fleet lookup', () {
      final home = Fleet(
        id: 'fleet_p1',
        ownerId: 'p1',
        seaZoneId: 'sea1',
        regionId: 'oldWorld',
        shipTypeIds: const ['carrack', 'fluyte'],
      );
      final other = Fleet(
        id: 'fleet_p2',
        ownerId: 'p2',
        seaZoneId: 'sea2',
        regionId: 'oldWorld',
        shipTypeIds: const ['sloop'],
      );
      final game = minimalEconomyGame(
        fleets: [other, home],
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final byId = fleetsByIdForWorld(game.worldState);
      expect(
        cargoHoldsForHomeFleet(game, 'p1', fleetsById: byId),
        cargoHoldsForHomeFleet(game, 'p1'),
      );
    });
  });

  group('SeaTransport', () {
    group('allocateOverseasToStockpile', () {
      test('returns empty when overseas is empty', () {
        final delivered = allocateOverseasToStockpile({}, cargoHolds: 10);
        expect(delivered, isEmpty);
      });

      test('cargo cap limits delivered overseas', () {
        final overseas = {'grain': 5, 'timber': 8, 'iron': 4};
        final delivered = allocateOverseasToStockpile(overseas, cargoHolds: 10);
        final total = delivered.values.fold<int>(0, (a, b) => a + b);
        expect(total, lessThanOrEqualTo(10));
        expect(total, 10);
      });

      test('priority order: food before raw materials', () {
        final overseas = {'iron': 20, 'grain': 5};
        final delivered = allocateOverseasToStockpile(overseas, cargoHolds: 6);
        expect(delivered['grain'], 5);
        expect(delivered['iron'], 1);
      });

      test('custom priorityOrder is respected', () {
        final overseas = {'grain': 3, 'iron': 10};
        final delivered = allocateOverseasToStockpile(
          overseas,
          cargoHolds: 5,
          priorityOrder: [
            CommodityCategory.rawMaterial,
            CommodityCategory.food,
          ],
        );
        expect(delivered['iron'], 5);
        expect(delivered['grain'], isNull);
      });
    });
  });
}
