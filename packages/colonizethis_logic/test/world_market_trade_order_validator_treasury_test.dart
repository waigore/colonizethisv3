import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'world_market_trade_order_validator_test_support.dart';

/// Tests for `TradeOrderValidator` rule 5 — cross-commodity treasury bid cap.
/// Refs #3093.
void main() {
  group('TradeOrderValidator.validate — rule 5: bid treasury cap', () {
    test(
      'rejects bid when cumulative spend exceeds treasuryBudgetForBids',
      () {
        final results = TradeOrderValidator.validate(
          context: validatorCtx(
            treasuryBudgetForBids: 60,
            worldMarketState: WorldMarketState(
              prices: {
                CommodityCatalog.timber.id: 30,
                CommodityCatalog.iron.id: 30,
              },
            ),
          ),
          proposedOrders: [
            validatorBid(CommodityCatalog.timber.id, 1),
            validatorBid(CommodityCatalog.iron.id, 2),
          ],
        );
        expect(results[0].isAccepted, isTrue);
        expect(
          results[1].reason,
          TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
        );
      },
    );

    test(
      'accepts bids whose cumulative spend equals treasuryBudgetForBids',
      () {
        final results = TradeOrderValidator.validate(
          context: validatorCtx(
            treasuryBudgetForBids: 60,
            worldMarketState: WorldMarketState(
              prices: {CommodityCatalog.timber.id: 30},
            ),
          ),
          proposedOrders: [validatorBid(CommodityCatalog.timber.id, 2)],
        );
        expect(results.single.isAccepted, isTrue);
      },
    );

    test(
      'treasury cap takes precedence over bidExceedsCargoCapacity (rule 5 '
      'before rule 6)',
      () {
        final results = TradeOrderValidator.validate(
          context: validatorCtx(
            tradeCargoCapacity: 100,
            treasuryBudgetForBids: 10,
            worldMarketState: WorldMarketState(
              prices: {CommodityCatalog.timber.id: 30},
            ),
          ),
          proposedOrders: [validatorBid(CommodityCatalog.timber.id, 5)],
        );
        expect(
          results.single.reason,
          TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
        );
      },
    );

    test(
      'bids with no effective market price contribute zero treasury spend '
      '(defensive guard against unknown / future commodity ids)',
      () {
        // Refs #3093 manufactured-default-prices slice — manufactured
        // commodities now have catalog defaults, so the "no effective
        // price" branch is exercised against an unknown commodity id
        // (the validator falls back to `0` spend when neither
        // `worldMarketState.prices` nor the catalog publishes a value).
        const String unknownCommodityId = 'not_a_real_commodity';
        final results = TradeOrderValidator.validate(
          context: validatorCtx(
            treasuryBudgetForBids: 0,
            worldMarketState: const WorldMarketState(),
          ),
          proposedOrders: [validatorBid(unknownCommodityId, 10)],
        );
        expect(results.single.isAccepted, isTrue);
      },
    );

    test(
      'manufactured commodity bids now consume the catalog base price '
      '(Refs #3093 manufactured-default-prices slice)',
      () {
        // Lumber base price per SPEC/game/commodity-catalog.md § Manufactured
        // base prices is 60. A bid of quantity 10 implies a spend of 600
        // treasury — exceeding a budget of 100 must trip rule 5.
        final results = TradeOrderValidator.validate(
          context: validatorCtx(
            treasuryBudgetForBids: 100,
            worldMarketState: const WorldMarketState(),
          ),
          proposedOrders: [validatorBid(CommodityCatalog.lumber.id, 10)],
        );
        expect(
          results.single.reason,
          TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
        );
      },
    );
  });
}
