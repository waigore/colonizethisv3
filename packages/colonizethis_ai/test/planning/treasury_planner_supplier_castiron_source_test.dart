/// Lock-recovery castIron improvement-input supplier source
/// (Refs #2847 H8-supply castIron source).
///
/// `castIron` has no native world-market supply on seed 42, so a locked seller
/// is stuck at the level-0 `build_improvement` gate it needs to extract recipe
/// feedstock. This slice opens a *first* `castIron` source: an affluent
/// supplier over-produces `castIron` and releases the surplus (offer side), and
/// once that supply stands in the market the locked seller bids `castIron`
/// **directly** instead of routing to feedstock it cannot mine.
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
// Unimproved wool resource tile in the seller's capital province so the
// improvement-input (castIron) gate is active by default.
const _sellerWoolTile = 'oldWorld|seller_0|1|0';

Game _game({
  required int sellerTreasury,
  required int supplierTreasury,
  int sellerLumberHeld = 1,
  int sellerCastIronHeld = 0,
  int supplierCastIronHeld = 0,
  bool sellerOwnsFeedstockTile = true,
  bool supplierStandingCastIronOffer = false,
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
  var supplierStockpile = const Stockpile().applyDelta('grain', 80);
  if (supplierCastIronHeld > 0) {
    supplierStockpile =
        supplierStockpile.applyDelta(_castIronId, supplierCastIronHeld);
  }
  final resourceByTileKey = <String, String>{
    if (sellerOwnsFeedstockTile) _sellerWoolTile: _woolId,
  };
  var marketState = WorldMarketState.withDefaultPrices(const {
    'grain': 10,
    _woolId: 20,
    _fabricId: 40,
    _lumberId: 15,
    _castIronId: 30,
    _timberId: 8,
    _ironId: 12,
  });
  if (supplierStandingCastIronOffer) {
    marketState = marketState.copyWith(
      carryForwardOffersByFactionId: {
        'gp_supplier': [
          TradeOrder(
            commodityId: _castIronId,
            type: TradeOrderType.offer,
            quantity: 4,
            priority: kTreasuryBidPriorityEssentialInput,
          ),
        ],
      },
    );
  }
  return Game(
    id: 'g-h8-castiron-source',
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
        stockpile: supplierStockpile,
        treasury: supplierTreasury,
      ),
    ],
    worldMarketState: marketState,
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

Iterable<TradeOrder> _offersFor(List<TradeOrder> orders, String commodityId) =>
    orders.where(
      (o) => o.type == TradeOrderType.offer && o.commodityId == commodityId,
    );

void main() {
  group('lock-recovery castIron improvement-input supplier source '
      '(Refs #2847 H8-supply castIron source)', () {
    final threshold = cheapestRegimentBuildTreasuryCost();

    test(
      'anyLockRecoverySellerNeedsCastIronImprovementInput is true when a locked '
      'seller still lacks the castIron improvement input',
      () {
        final game = _game(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
        );
        expect(
          anyLockRecoverySellerNeedsCastIronImprovementInput(game),
          isTrue,
        );
      },
    );

    test(
      'anyLockRecoverySellerNeedsCastIronImprovementInput is false when the '
      'seller already holds castIron (negative control)',
      () {
        final game = _game(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          sellerCastIronHeld: 1,
        );
        expect(
          anyLockRecoverySellerNeedsCastIronImprovementInput(game),
          isFalse,
        );
      },
    );

    test(
      'anyLockRecoverySellerNeedsCastIronImprovementInput is false when no GP '
      'is a below-quota zero-NW lock-recovery seller (negative control)',
      () {
        final game = _game(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          sellerOwnsFeedstockTile: false,
        );
        expect(
          anyLockRecoverySellerNeedsCastIronImprovementInput(game),
          isFalse,
        );
      },
    );

    test('the locked seller is classified as a lock-recovery seller and the '
        'affluent supplier is not', () {
      final game = _game(
        sellerTreasury: threshold,
        supplierTreasury: threshold,
      );
      expect(isBelowQuotaZeroNwLockRecoverySeller(game, 'gp_seller'), isTrue);
      expect(
        isBelowQuotaZeroNwLockRecoverySeller(game, 'gp_supplier'),
        isFalse,
      );
    });

    test(
      'affluent supplier releases surplus castIron while a locked seller needs '
      'the castIron improvement input (offer side)',
      () {
        // castIron held (6) is surplus above the consumption-only reserve
        // (4 = kShortageThreshold ~/ 2) once the supplier-release safety buffer
        // drops to 0, but withheld under the default consumption safety buffer.
        final game = _game(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          supplierCastIronHeld: 6,
        );
        expect(
          _offersFor(_run(game, 'gp_supplier'), _castIronId),
          isNotEmpty,
          reason:
              'An affluent supplier must release castIron surplus so the locked '
              "seller's castIron bid can clear.",
        );
      },
    );

    test(
      'supplier keeps its normal castIron buffer when no locked seller needs '
      'the castIron improvement input (negative control)',
      () {
        // No below-quota zero-NW lock-recovery seller exists (the would-be
        // seller is at quota), so neither H8 supplier trigger fires; the
        // supplier keeps the default consumption safety buffer and withholds
        // its 6 castIron (reserve 8 > 6).
        final game = _game(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          supplierCastIronHeld: 6,
          sellerOwProvinces: 12,
        );
        expect(
          anyLockRecoverySellerNeedsCastIronImprovementInput(game),
          isFalse,
        );
        expect(_offersFor(_run(game, 'gp_supplier'), _castIronId), isEmpty);
      },
    );

    test(
      'locked seller bids castIron directly once a supplier offer stands in the '
      'market (buyer side)',
      () {
        final game = _game(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          supplierStandingCastIronOffer: true,
        );
        final orders = _run(game, 'gp_seller');
        expect(
          _bidsFor(orders, _castIronId),
          isNotEmpty,
          reason:
              'With standing castIron supply the seller bids castIron directly '
              'instead of routing to feedstock it cannot extract.',
        );
        expect(
          _bidsFor(orders, _timberId),
          isEmpty,
          reason:
              'The direct castIron bid replaces the production-feedstock route '
              'while supply exists.',
        );
        expect(_bidsFor(orders, _ironId), isEmpty);
      },
    );

    test(
      'locked seller routes to castIron production feedstock when no supplier '
      'offer stands in the market (negative control — existing behavior)',
      () {
        final game = _game(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
        );
        final orders = _run(game, 'gp_seller');
        expect(
          _bidsFor(orders, _castIronId),
          isEmpty,
          reason:
              'Without standing castIron supply, castIron is produced '
              'domestically (feedstock bid), never bid directly.',
        );
        expect(
          orders.where(
            (o) =>
                o.type == TradeOrderType.bid &&
                (o.commodityId == _timberId || o.commodityId == _ironId),
          ),
          isNotEmpty,
        );
      },
    );

    test('castIron supplier-source path is deterministic', () {
      final game = _game(
        sellerTreasury: threshold,
        supplierTreasury: threshold,
        supplierCastIronHeld: 6,
        supplierStandingCastIronOffer: true,
      );
      expect(_run(game, 'gp_seller'), equals(_run(game, 'gp_seller')));
      expect(_run(game, 'gp_supplier'), equals(_run(game, 'gp_supplier')));
    });
  });
}
