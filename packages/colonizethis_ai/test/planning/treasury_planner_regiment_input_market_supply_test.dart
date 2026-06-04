/// Lock-recovery regiment build-input market supply (Refs #2847 H8-supply market).
library;

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _fabricId = 'fabric';
const _woolId = 'wool';
const _timberId = 'timber';

Game _twoGpGame({
  required int sellerTreasury,
  required int supplierTreasury,
  required int sellerFabricHeld,
  required int sellerWoolHeld,
  required int supplierWoolHeld,
  int supplierTimberHeld = 0,
  int sellerOwProvinces = 3,
  int supplierOwProvinces = 12,
}) {
  const ow = 'oldWorld';
  var sellerStockpile = const Stockpile().applyDelta('grain', 80);
  if (sellerWoolHeld > 0) {
    sellerStockpile = sellerStockpile.applyDelta(_woolId, sellerWoolHeld);
  }
  if (sellerFabricHeld > 0) {
    sellerStockpile = sellerStockpile.applyDelta(_fabricId, sellerFabricHeld);
  }
  var supplierStockpile = const Stockpile().applyDelta('grain', 80);
  if (supplierWoolHeld > 0) {
    supplierStockpile = supplierStockpile.applyDelta(_woolId, supplierWoolHeld);
  }
  if (supplierTimberHeld > 0) {
    supplierStockpile =
        supplierStockpile.applyDelta(_timberId, supplierTimberHeld);
  }
  return Game(
    id: 'g-h8-supply-market',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < sellerOwProvinces; i++)
            Province(id: '$ow|seller_$i', regionId: ow, ownerId: 'gp_seller'),
          for (var i = 0; i < supplierOwProvinces; i++)
            Province(id: '$ow|supplier_$i', regionId: ow, ownerId: 'gp_supplier'),
        ],
      ),
      newWorld: const RegionData(provinces: []),
    ),
    players: [
      Player(
        id: 'gp_seller',
        displayName: 'Seller',
        isHuman: false,
        capitalProvinceId: '$ow|seller_0',
        stockpile: sellerStockpile,
        treasury: sellerTreasury,
      ),
      Player(
        id: 'gp_supplier',
        displayName: 'Supplier',
        isHuman: false,
        capitalProvinceId: '$ow|supplier_0',
        stockpile: supplierStockpile,
        treasury: supplierTreasury,
      ),
    ],
    worldMarketState: WorldMarketState.withDefaultPrices(const {
      'grain': 10,
      _woolId: 20,
      _fabricId: 40,
      _timberId: 30,
    }),
  );
}

List<TradeOrder> _run(Game game, String playerId) => runTreasuryPlanner(
      game: game,
      playerId: playerId,
      stockpile: game.players.firstWhere((p) => p.id == playerId).stockpile,
      productionAssignments: const [],
      treasury: game.players.firstWhere((p) => p.id == playerId).treasury,
    );

void main() {
  group('lock-recovery regiment build-input market supply (Refs #2847 H8-supply market)',
      () {
    final threshold = cheapestRegimentBuildTreasuryCost();

    test(
      'recovered lock-recovery seller missing wool bids wool before fabric',
      () {
        final game = _twoGpGame(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          sellerFabricHeld: 0,
          sellerWoolHeld: 0,
          supplierWoolHeld: 20,
        );
        final orders = _run(game, 'gp_seller');
        final woolBids = orders
            .where((o) => o.type == TradeOrderType.bid && o.commodityId == _woolId)
            .toList();
        final fabricBids = orders
            .where((o) =>
                o.type == TradeOrderType.bid && o.commodityId == _fabricId)
            .toList();
        expect(woolBids, isNotEmpty);
        expect(fabricBids, isEmpty);
      },
    );

    test(
      'affluent non-seller offers surplus wool while a lock-recovery seller '
      'still needs the bootstrap path',
      () {
        final game = _twoGpGame(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          sellerFabricHeld: 0,
          sellerWoolHeld: 0,
          supplierWoolHeld: 20,
        );
        final woolOffers = _run(game, 'gp_supplier')
            .where((o) => o.type == TradeOrderType.offer && o.commodityId == _woolId)
            .toList();
        expect(
          woolOffers,
          isNotEmpty,
          reason:
              'An affluent GP must release wool offers so the seller feedstock '
              'bid can clear.',
        );
      },
    );

    test(
      'affluent non-seller keeps normal wool buffer when no lock-recovery seller '
      'needs the bootstrap path',
      () {
        final game = _twoGpGame(
          sellerTreasury: threshold - 1,
          supplierTreasury: threshold,
          sellerFabricHeld: 0,
          sellerWoolHeld: 0,
          supplierWoolHeld: 4,
        );
        final woolOffers = _run(game, 'gp_supplier')
            .where((o) => o.type == TradeOrderType.offer && o.commodityId == _woolId)
            .toList();
        expect(woolOffers, isEmpty);
      },
    );

    test('seller with sufficient wool bids fabric not wool', () {
      final game = _twoGpGame(
        sellerTreasury: threshold,
        supplierTreasury: threshold,
        sellerFabricHeld: 0,
        sellerWoolHeld: 2,
        supplierWoolHeld: 20,
      );
      final orders = _run(game, 'gp_seller');
      expect(
        orders.where(
          (o) => o.type == TradeOrderType.bid && o.commodityId == _woolId,
        ),
        isEmpty,
      );
      expect(
        orders.where(
          (o) => o.type == TradeOrderType.bid && o.commodityId == _fabricId,
        ),
        isNotEmpty,
      );
    });

    test(
      'supplier build-input offer lands in the same priority tier the buyer '
      'bids at so the DealMatcher can cross them (Refs #2847 H8-supply market '
      'order matching)',
      () {
        final game = _twoGpGame(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          sellerFabricHeld: 0,
          sellerWoolHeld: 0,
          supplierWoolHeld: 20,
        );
        final supplierWoolOffer = _run(game, 'gp_supplier').firstWhere(
          (o) => o.type == TradeOrderType.offer && o.commodityId == _woolId,
        );
        final sellerWoolBid = _run(game, 'gp_seller').firstWhere(
          (o) => o.type == TradeOrderType.bid && o.commodityId == _woolId,
        );
        expect(
          supplierWoolOffer.priority,
          sellerWoolBid.priority,
          reason:
              'The build-input supply offer and the buyer build-input bid '
              'must share an integer priority tier; the DealMatcher only '
              'crosses orders within the same tier.',
        );
        expect(
          supplierWoolOffer.priority,
          kTreasuryBidPriorityRawMaterial,
          reason:
              'wool is a raw material; the supply offer is re-tagged to the '
              'raw bid tier rather than the moderate offer tier.',
        );
      },
    );

    test(
      'only build-input supply commodities are re-tagged; a non-build-input '
      'surplus offer keeps the moderate offer tier (Refs #2847 H8-supply '
      'market order matching)',
      () {
        final game = _twoGpGame(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          sellerFabricHeld: 0,
          sellerWoolHeld: 0,
          supplierWoolHeld: 20,
          supplierTimberHeld: 200,
        );
        final supplierOrders = _run(game, 'gp_supplier');
        final timberOffer = supplierOrders.firstWhere(
          (o) => o.type == TradeOrderType.offer && o.commodityId == _timberId,
        );
        expect(
          timberOffer.priority,
          kTreasuryOfferPriorityModerate,
          reason:
              'timber is not a regiment build-input supply commodity, so its '
              'surplus offer keeps the general moderate offer priority and is '
              'not re-tagged.',
        );
        final woolOffer = supplierOrders.firstWhere(
          (o) => o.type == TradeOrderType.offer && o.commodityId == _woolId,
        );
        expect(
          woolOffer.priority,
          kTreasuryBidPriorityRawMaterial,
          reason:
              'wool is a build-input supply commodity, so it is re-tagged to '
              'the buyer bid tier even while timber is not.',
        );
      },
    );

    test('H8-supply market path is deterministic', () {
      final game = _twoGpGame(
        sellerTreasury: threshold,
        supplierTreasury: threshold,
        sellerFabricHeld: 0,
        sellerWoolHeld: 0,
        supplierWoolHeld: 20,
      );
      expect(_run(game, 'gp_seller'), equals(_run(game, 'gp_seller')));
      expect(_run(game, 'gp_supplier'), equals(_run(game, 'gp_supplier')));
    });
  });
}
