import 'package:colonizethis_orders/src/orders/bundled_civilian_work_order.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';

import 'movement_phase_bundled_work_cases.dart';

void main() {
  group('bundled civilian work move leg', () {
    test('skips implicit move leg for purchased foreign tile', () {
      const fromTile = 'oldWorld|p1|0|0';
      const purchasedTile = 'oldWorld|p2|0|0';
      final game = bundledWorkPurchasedForeignTileGame(
        unitId: 'u1',
        fromTile: fromTile,
        purchasedTile: purchasedTile,
        p1Owner: 'gp1',
        p2Owner: 'gp2',
      );
      final unit = game.worldState.oldWorld.units.single;
      final order = bundledWorkOrders(
        unitId: 'u1',
        targetTileKey: purchasedTile,
      ).workOrdersByPlayerId['gp1']!.single;

      expect(
        civilianBundledWorkNeedsProvinceMoveLeg(game, unit, order),
        isFalse,
      );
    });
  });

  group('applyImplicitBundledCivilianWorkOrderMoves', () {
    test('moves civilian to bundled entry tile before work phase', () {
      const fromTile = 'oldWorld|p1|0|0';
      const destTile = 'oldWorld|p2|0|0';
      final game = bundledWorkImplicitMoveGame(
        unitId: 'builder1',
        fromTile: fromTile,
        destTile: destTile,
        playerVisibilityByTile: {
          'gp1': {
            fromTile: 'fullyVisible',
            destTile: 'fullyVisible',
          },
        },
        resourceByTileKey: {destTile: 'grain'},
      );
      final orders = bundledWorkOrders(
        unitId: 'builder1',
        targetTileKey: destTile,
      );
      final topology = bundledWorkTwoProvinceTopology();

      final moved = applyImplicitBundledCivilianWorkOrderMoves(
        game,
        topology,
        orders,
      );

      final unit = moved.worldState.oldWorld.units.single;
      expect(unit.locationProvinceId, bundledWorkProvince('p2'));
      expect(unit.tileKey, destTile);
    });

    test(
      'implicit bundled move uses first MoveValidator-legal tile when earlier sorted tiles are unknown',
      () {
        const fromTile = 'oldWorld|p1|0|0';
        const destTileUnknown = 'oldWorld|p2|0|0';
        const destTileVisible = 'oldWorld|p2|1|0';
        final game = bundledWorkImplicitMoveGame(
          unitId: 'builder1',
          fromTile: fromTile,
          destTile: destTileVisible,
          p2TileKeys: [destTileUnknown, destTileVisible],
          playerVisibilityByTile: {
            'gp1': {
              fromTile: 'fullyVisible',
              destTileUnknown: 'unknown',
              destTileVisible: 'fullyVisible',
            },
          },
          resourceByTileKey: {destTileVisible: 'grain'},
        );
        final orders = bundledWorkOrders(
          unitId: 'builder1',
          targetTileKey: destTileVisible,
        );
        final topology = bundledWorkTwoProvinceTopology();

        final moved = applyImplicitBundledCivilianWorkOrderMoves(
          game,
          topology,
          orders,
        );

        final unit = moved.worldState.oldWorld.units.single;
        expect(unit.locationProvinceId, bundledWorkProvince('p2'));
        expect(unit.tileKey, destTileVisible);
      },
    );

    test('implicit bundled move prefers targetTileKey when it is legal', () {
      const fromTile = 'oldWorld|p1|0|0';
      const firstSortedLegal = 'oldWorld|p2|0|0';
      const preferredTargetTile = 'oldWorld|p2|1|0';
      final game = bundledWorkImplicitMoveGame(
        unitId: 'builder1',
        fromTile: fromTile,
        destTile: preferredTargetTile,
        p2TileKeys: [firstSortedLegal, preferredTargetTile],
        playerVisibilityByTile: {
          'gp1': {
            fromTile: 'fullyVisible',
            firstSortedLegal: 'fullyVisible',
            preferredTargetTile: 'fullyVisible',
          },
        },
        resourceByTileKey: {preferredTargetTile: 'grain'},
      );
      final orders = bundledWorkOrders(
        unitId: 'builder1',
        targetTileKey: preferredTargetTile,
      );
      final topology = bundledWorkTwoProvinceTopology();

      final moved = applyImplicitBundledCivilianWorkOrderMoves(
        game,
        topology,
        orders,
      );

      final unit = moved.worldState.oldWorld.units.single;
      expect(unit.locationProvinceId, bundledWorkProvince('p2'));
      expect(unit.tileKey, preferredTargetTile);
    });
  });
}
