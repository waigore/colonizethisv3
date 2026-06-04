/// Lock-recovery seller feedstock-improvement input bootstrap
/// (Refs #2847 H8-extraction).
library;

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _woolId = 'wool';
const _fabricId = 'fabric';
const _lumberId = 'lumber';
const _castIronId = 'castIron';
// Wool resource tile in the seller's capital province (`oldWorld|seller_0`),
// unimproved by default so the build_improvement is needed.
const _sellerWoolTile = 'oldWorld|seller_0|1|0';

Game _game({
  required int sellerTreasury,
  required int supplierTreasury,
  bool sellerHoldsImprovementInputs = false,
  bool sellerOwnsFeedstockTile = true,
  bool sellerWoolTileImproved = false,
  List<Unit> sellerUnits = const [],
  int supplierLumberHeld = 20,
  int sellerOwProvinces = 3,
  int supplierOwProvinces = 12,
}) {
  const ow = 'oldWorld';
  var sellerStockpile = const Stockpile().applyDelta('grain', 80);
  if (sellerHoldsImprovementInputs) {
    sellerStockpile = sellerStockpile
        .applyDelta(_lumberId, 1)
        .applyDelta(_castIronId, 1);
  }
  var supplierStockpile = const Stockpile().applyDelta('grain', 80);
  if (supplierLumberHeld > 0) {
    supplierStockpile = supplierStockpile.applyDelta(
      _lumberId,
      supplierLumberHeld,
    );
  }
  final resourceByTileKey = <String, String>{
    if (sellerOwnsFeedstockTile) _sellerWoolTile: _woolId,
  };
  final tileState = sellerWoolTileImproved
      ? TileMapState().setImprovement(_sellerWoolTile, 1)
      : TileMapState();
  return Game(
    id: 'g-h8-improvement',
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
        units: sellerUnits,
      ),
      newWorld: const RegionData(provinces: []),
      resourceByTileKey: resourceByTileKey,
      tileState: tileState,
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
      _lumberId: 15,
      _castIronId: 30,
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
  group('lock-recovery seller feedstock-improvement input bootstrap '
      '(Refs #2847 H8-extraction)', () {
    final threshold = cheapestRegimentBuildTreasuryCost();

    test(
      'recovered seller with owned unimproved feedstock tile but no lumber / '
      'cast iron bids an improvement input before fabric or feedstock',
      () {
        final orders = _run(
          _game(sellerTreasury: threshold, supplierTreasury: threshold),
          'gp_seller',
        );
        final improvementBids = orders.where(
          (o) =>
              o.type == TradeOrderType.bid &&
              (o.commodityId == _lumberId || o.commodityId == _castIronId),
        );
        expect(
          improvementBids,
          isNotEmpty,
          reason:
              'The locked seller must bid for the level-0 build_improvement '
              'inputs (lumber / cast iron) it cannot afford.',
        );
        expect(_bidsFor(orders, _fabricId), isEmpty);
        expect(_bidsFor(orders, _woolId), isEmpty);
      },
    );

    test('seller already holding lumber + cast iron emits no improvement-input '
        'bid and resumes the feedstock / fabric bootstrap', () {
      final orders = _run(
        _game(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          sellerHoldsImprovementInputs: true,
        ),
        'gp_seller',
      );
      expect(_bidsFor(orders, _lumberId), isEmpty);
      expect(_bidsFor(orders, _castIronId), isEmpty);
      expect(
        orders.where((o) => o.type == TradeOrderType.bid),
        isNotEmpty,
        reason:
            'With the improvement inputs on hand the seller resumes the '
            'feedstock / fabric bootstrap bid.',
      );
    });

    test('seller owning no feedstock tile emits no improvement-input bid', () {
      final orders = _run(
        _game(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          sellerOwnsFeedstockTile: false,
        ),
        'gp_seller',
      );
      expect(_bidsFor(orders, _lumberId), isEmpty);
      expect(_bidsFor(orders, _castIronId), isEmpty);
    });

    test('seller whose feedstock tile is already improved emits no '
        'improvement-input bid', () {
      final orders = _run(
        _game(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          sellerWoolTileImproved: true,
        ),
        'gp_seller',
      );
      expect(_bidsFor(orders, _lumberId), isEmpty);
      expect(_bidsFor(orders, _castIronId), isEmpty);
    });

    test(
      'seller that already owns a regiment emits no improvement-input bid',
      () {
        final orders = _run(
          _game(
            sellerTreasury: threshold,
            supplierTreasury: threshold,
            sellerUnits: [
              Unit(
                id: 'r1',
                type: 'peasant_levies',
                ownerId: 'gp_seller',
                locationProvinceId: 'oldWorld|seller_0',
              ),
            ],
          ),
          'gp_seller',
        );
        expect(_bidsFor(orders, _lumberId), isEmpty);
        expect(_bidsFor(orders, _castIronId), isEmpty);
      },
    );

    test(
      'seller below the regiment threshold emits no improvement-input bid',
      () {
        final orders = _run(
          _game(sellerTreasury: threshold - 1, supplierTreasury: threshold),
          'gp_seller',
        );
        expect(_bidsFor(orders, _lumberId), isEmpty);
        expect(_bidsFor(orders, _castIronId), isEmpty);
      },
    );

    test('affluent non-seller releases surplus lumber while a lock-recovery '
        'seller needs the improvement-input bootstrap', () {
      final lumberOffers =
          _run(
            _game(sellerTreasury: threshold, supplierTreasury: threshold),
            'gp_supplier',
          ).where(
            (o) => o.type == TradeOrderType.offer && o.commodityId == _lumberId,
          );
      expect(
        lumberOffers,
        isNotEmpty,
        reason:
            'An affluent GP must release lumber so the locked seller\'s '
            'improvement-input bid can clear.',
      );
    });

    test('improvement-input bootstrap path is deterministic', () {
      final game = _game(
        sellerTreasury: threshold,
        supplierTreasury: threshold,
      );
      expect(_run(game, 'gp_seller'), equals(_run(game, 'gp_seller')));
      expect(_run(game, 'gp_supplier'), equals(_run(game, 'gp_supplier')));
    });
  });
}
