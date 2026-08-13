import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/full_ai_civilian_work_ow_feedstock_reservation_fixtures.dart';

// Refs #2847 § H8-extraction supplier Old World feedstock unit reservation.
void main() {
  group('selectFullAiCivilianWorkOrders Old World feedstock unit reservation '
      '(Refs #2847 H8-extraction)', () {
    test(
      'reserved Builder routes to Old World feedstock tile, not New World',
      () {
        final game = ironFeedstockReservationGame();
        final r = selectSupplierReservationWork(
          game: game,
          units: [idleSupplierBuilder('b1')],
          suggestions: [
            supplierBuildOrder('b1', supplierReservationNewWorldTile),
            supplierBuildOrder('b1', supplierReservationIronTile),
          ],
        );
        expect(r.workOrders, hasLength(1));
        expect(r.workOrders.single.targetTileKey, supplierReservationIronTile);
      },
    );

    test('lex-first idle Builder is held out of New World; the next Builder '
        'still takes New World work', () {
      final game = ironFeedstockReservationGame();
      final r = selectSupplierReservationWork(
        game: game,
        units: [idleSupplierBuilder('b1'), idleSupplierBuilder('b2')],
        suggestions: [
          supplierBuildOrder('b1', supplierReservationNewWorldTile),
          supplierBuildOrder('b2', supplierReservationNewWorldTile),
        ],
      );
      expect(r.workOrders, hasLength(1));
      expect(r.workOrders.single.unitId, 'b2');
      expect(
        r.workOrders.single.targetTileKey,
        supplierReservationNewWorldTile,
      );
      expect(r.idleEvents.map((e) => e.unitId), contains('b1'));
    });

    test('reserved Explorer prospects Old World mineral feedstock tile, not '
        'New World explore', () {
      final game = ironFeedstockReservationGame();
      final r = selectSupplierReservationWork(
        game: game,
        units: [idleSupplierExplorer('e1')],
        suggestions: [
          supplierExploreOrder('e1', supplierReservationNewWorldTile),
          supplierProspectOrder('e1', supplierReservationIronTile),
        ],
      );
      expect(r.workOrders, hasLength(1));
      expect(r.workOrders.single.target, kWorkTargetProspect);
      expect(r.workOrders.single.targetTileKey, supplierReservationIronTile);
    });

    test('lex-first idle Explorer is held out of New World; the next Explorer '
        'still explores New World', () {
      final game = ironFeedstockReservationGame();
      final r = selectSupplierReservationWork(
        game: game,
        units: [idleSupplierExplorer('e1'), idleSupplierExplorer('e2')],
        suggestions: [
          supplierExploreOrder('e1', supplierReservationNewWorldTile),
          supplierExploreOrder('e2', supplierReservationNewWorldTile),
        ],
      );
      expect(r.workOrders, hasLength(1));
      expect(r.workOrders.single.unitId, 'e2');
      expect(
        r.workOrders.single.targetTileKey,
        supplierReservationNewWorldTile,
      );
      expect(r.idleEvents.map((e) => e.unitId), contains('e1'));
    });

    test('off-gate (no peer demand): no reservation, Builder takes New World '
        'work', () {
      final game = ironFeedstockReservationGame(
        sellerOw: kObserverConquestMinOwProvincesPerGp,
      );
      final r = selectSupplierReservationWork(
        game: game,
        units: [idleSupplierBuilder('b1')],
        suggestions: [
          supplierBuildOrder('b1', supplierReservationNewWorldTile),
        ],
      );
      expect(r.workOrders, hasLength(1));
      expect(r.workOrders.single.unitId, 'b1');
      expect(
        r.workOrders.single.targetTileKey,
        supplierReservationNewWorldTile,
      );
    });

    test('no reservation when the supplier Old World feedstock tiles are all '
        'improved (gate self-clears)', () {
      final game = ironFeedstockReservationGame(
        tileState: TileMapState().setImprovement(
          supplierReservationIronTile,
          1,
        ),
      );
      final r = selectSupplierReservationWork(
        game: game,
        units: [idleSupplierBuilder('b1')],
        suggestions: [
          supplierBuildOrder('b1', supplierReservationNewWorldTile),
        ],
      );
      expect(r.workOrders, hasLength(1));
      expect(r.workOrders.single.unitId, 'b1');
      expect(
        r.workOrders.single.targetTileKey,
        supplierReservationNewWorldTile,
      );
    });

    test('reservation selection is deterministic', () {
      final game = ironFeedstockReservationGame();
      final units = [
        idleSupplierBuilder('b1'),
        idleSupplierBuilder('b2'),
        idleSupplierExplorer('e1'),
        idleSupplierExplorer('e2'),
      ];
      final suggestions = [
        supplierBuildOrder('b1', supplierReservationIronTile),
        supplierBuildOrder('b2', supplierReservationNewWorldTile),
        supplierProspectOrder('e1', supplierReservationIronTile),
        supplierExploreOrder('e2', supplierReservationNewWorldTile),
      ];
      final a = selectSupplierReservationWork(
        game: game,
        units: units,
        suggestions: suggestions,
      );
      final b = selectSupplierReservationWork(
        game: game,
        units: units,
        suggestions: suggestions,
      );
      expect(a.workOrders, equals(b.workOrders));
    });
  });
}
