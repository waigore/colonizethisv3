/// Lock-recovery seller improvement-input domestic production
/// (Refs #2847 H8-extraction castIron residual).
///
/// `castIron` has no world-market supply on seed 42 (it is consumed by Old World
/// military builds), so the locked seller bids `castIron`'s production feedstock
/// (`timber` + `iron`) and the economy planner produces it domestically rather
/// than bidding `castIron` directly. `lumber` keeps its direct market bid.
library;

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _woolId = 'wool';
const _fabricId = 'fabric';
const _lumberId = 'lumber';
const _castIronId = 'castIron';
const _timberId = 'timber';
const _ironId = 'iron';
// Wool resource tile in the seller's capital province, unimproved by default so
// the build_improvement (and therefore the improvement-input gate) is needed.
const _sellerWoolTile = 'oldWorld|seller_0|1|0';

Game _game({
  required int sellerTreasury,
  int sellerLumberHeld = 0,
  int sellerCastIronHeld = 0,
  int sellerTimberHeld = 0,
  int sellerIronHeld = 0,
  bool sellerOwnsFeedstockTile = true,
  int sellerOwProvinces = 3,
  int supplierOwProvinces = 12,
}) {
  const ow = 'oldWorld';
  var sellerStockpile = const Stockpile().applyDelta('grain', 80);
  if (sellerLumberHeld > 0) {
    sellerStockpile = sellerStockpile.applyDelta(_lumberId, sellerLumberHeld);
  }
  if (sellerCastIronHeld > 0) {
    sellerStockpile =
        sellerStockpile.applyDelta(_castIronId, sellerCastIronHeld);
  }
  if (sellerTimberHeld > 0) {
    sellerStockpile = sellerStockpile.applyDelta(_timberId, sellerTimberHeld);
  }
  if (sellerIronHeld > 0) {
    sellerStockpile = sellerStockpile.applyDelta(_ironId, sellerIronHeld);
  }
  final resourceByTileKey = <String, String>{
    if (sellerOwnsFeedstockTile) _sellerWoolTile: _woolId,
  };
  return Game(
    id: 'g-h8-castiron',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < sellerOwProvinces; i++)
            Province(id: '$ow|seller_$i', regionId: ow, ownerId: 'gp_seller'),
          for (var i = 0; i < supplierOwProvinces; i++)
            Province(
              id: '$ow|supplier_$i',
              regionId: ow,
              ownerId: 'gp_supplier',
            ),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      resourceByTileKey: resourceByTileKey,
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
        stockpile: const Stockpile().applyDelta('grain', 80),
        treasury: sellerTreasury,
      ),
    ],
    worldMarketState: WorldMarketState.withDefaultPrices(const {
      'grain': 10,
      _woolId: 20,
      _fabricId: 40,
      _lumberId: 15,
      _castIronId: 30,
      _timberId: 8,
      _ironId: 12,
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

Iterable<TradeOrder> _bidsFor(List<TradeOrder> orders, String commodityId) =>
    orders.where(
      (o) => o.type == TradeOrderType.bid && o.commodityId == commodityId,
    );

void main() {
  group('lock-recovery seller improvement-input domestic production '
      '(Refs #2847 H8-extraction castIron residual)', () {
    final threshold = cheapestRegimentBuildTreasuryCost();

    test(
      'seller short of castIron (and missing its production feedstock) bids a '
      'castIron production feedstock commodity, not castIron itself',
      () {
        // lumber already on hand so the single bid slot targets the castIron
        // production feedstock (timber / iron), isolating the castIron path.
        final orders = _run(
          _game(sellerTreasury: threshold, sellerLumberHeld: 1),
          'gp_seller',
        );
        final feedstockBids = orders.where(
          (o) =>
              o.type == TradeOrderType.bid &&
              (o.commodityId == _timberId || o.commodityId == _ironId),
        );
        expect(
          feedstockBids,
          isNotEmpty,
          reason:
              'The locked seller must bid castIron production feedstock '
              '(timber / iron) because castIron has no world-market supply.',
        );
        expect(
          _bidsFor(orders, _castIronId),
          isEmpty,
          reason: 'castIron is never bid directly (the market cannot supply it).',
        );
      },
    );

    test(
      'seller already holding the castIron production feedstock emits no '
      'castIron or feedstock bid, but still bids a missing direct input (lumber)',
      () {
        // Enough timber + iron for one castIron_from_timber_iron_coal run, but
        // zero lumber: castIron is produced domestically (no bid), lumber is
        // still acquired directly from the market.
        final orders = _run(
          _game(
            sellerTreasury: threshold,
            sellerTimberHeld: 2,
            sellerIronHeld: 2,
          ),
          'gp_seller',
        );
        expect(_bidsFor(orders, _castIronId), isEmpty);
        expect(_bidsFor(orders, _timberId), isEmpty);
        expect(_bidsFor(orders, _ironId), isEmpty);
        expect(
          _bidsFor(orders, _lumberId),
          isNotEmpty,
          reason:
              'lumber keeps its direct market bid; only castIron is produced '
              'domestically.',
        );
      },
    );

    test('seller already holding castIron emits no castIron feedstock bid', () {
      final orders = _run(
        _game(
          sellerTreasury: threshold,
          sellerLumberHeld: 1,
          sellerCastIronHeld: 1,
        ),
        'gp_seller',
      );
      expect(_bidsFor(orders, _castIronId), isEmpty);
      expect(_bidsFor(orders, _timberId), isEmpty);
      expect(_bidsFor(orders, _ironId), isEmpty);
    });

    test('castIron production feedstock path is deterministic', () {
      final game = _game(sellerTreasury: threshold, sellerLumberHeld: 1);
      expect(_run(game, 'gp_seller'), equals(_run(game, 'gp_seller')));
    });
  });
}
