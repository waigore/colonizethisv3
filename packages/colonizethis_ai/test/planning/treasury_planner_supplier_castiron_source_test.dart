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
import 'treasury_planner_satellite_support.dart';



List<TradeOrder> _run(Game game, String playerId) => runTreasuryPlanner(TreasuryPlannerInput(
      game: game,
      playerId: playerId,
      stockpile: game.players.firstWhere((p) => p.id == playerId).stockpile,
      productionAssignments: const [],
      treasury: game.players.firstWhere((p) => p.id == playerId).treasury,
    ));

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
        final game = treasuryPlannerSupplierCastIronSourceGame(
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
        final game = treasuryPlannerSupplierCastIronSourceGame(
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
        final game = treasuryPlannerSupplierCastIronSourceGame(
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
      final game = treasuryPlannerSupplierCastIronSourceGame(
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
        final game = treasuryPlannerSupplierCastIronSourceGame(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          supplierCastIronHeld: 6,
        );
        expect(
          _offersFor(_run(game, 'gp_supplier'), kTreasurySupplierCastIronId),
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
        final game = treasuryPlannerSupplierCastIronSourceGame(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          supplierCastIronHeld: 6,
          sellerOwProvinces: 12,
        );
        expect(
          anyLockRecoverySellerNeedsCastIronImprovementInput(game),
          isFalse,
        );
        expect(_offersFor(_run(game, 'gp_supplier'), kTreasurySupplierCastIronId), isEmpty);
      },
    );

    test(
      'locked seller bids castIron directly once a supplier offer stands in the '
      'market (buyer side)',
      () {
        final game = treasuryPlannerSupplierCastIronSourceGame(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
          supplierStandingCastIronOffer: true,
        );
        final orders = _run(game, 'gp_seller');
        expect(
          _bidsFor(orders, kTreasurySupplierCastIronId),
          isNotEmpty,
          reason:
              'With standing castIron supply the seller bids castIron directly '
              'instead of routing to feedstock it cannot extract.',
        );
        expect(
          _bidsFor(orders, kTreasurySupplierTimberId),
          isEmpty,
          reason:
              'The direct castIron bid replaces the production-feedstock route '
              'while supply exists.',
        );
        expect(_bidsFor(orders, kTreasurySupplierIronId), isEmpty);
      },
    );

    test(
      'locked seller routes to castIron production feedstock when no supplier '
      'offer stands in the market (negative control — existing behavior)',
      () {
        final game = treasuryPlannerSupplierCastIronSourceGame(
          sellerTreasury: threshold,
          supplierTreasury: threshold,
        );
        final orders = _run(game, 'gp_seller');
        expect(
          _bidsFor(orders, kTreasurySupplierCastIronId),
          isEmpty,
          reason:
              'Without standing castIron supply, castIron is produced '
              'domestically (feedstock bid), never bid directly.',
        );
        expect(
          orders.where(
            (o) =>
                o.type == TradeOrderType.bid &&
                (o.commodityId == kTreasurySupplierTimberId || o.commodityId == kTreasurySupplierIronId),
          ),
          isNotEmpty,
        );
      },
    );

    test('castIron supplier-source path is deterministic', () {
      final game = treasuryPlannerSupplierCastIronSourceGame(
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
