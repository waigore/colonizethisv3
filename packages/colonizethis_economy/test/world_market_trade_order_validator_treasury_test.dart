import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// Tests for `TradeOrderValidator` rule 5 — cross-commodity treasury bid cap.
/// Refs #3093.
void main() {
  group('TradeOrderValidator.validate — rule 5: bid treasury cap', () {
    test('rejects bid when cumulative spend exceeds treasuryBudgetForBids', () {
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
    });

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

    test('treasury cap takes precedence over bidExceedsCargoCapacity (rule 5 '
        'before rule 6)', () {
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
    });

    test('bids with no effective market price contribute zero treasury spend '
        '(defensive guard against unknown / future commodity ids)', () {
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
    });

    test('manufactured commodity bids now consume the catalog base price '
        '(Refs #3093 manufactured-default-prices slice)', () {
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
    });

    test('accepts cumulative spend equal to treasuryBudgetForBids across '
        'distinct commodities in submission order (Refs #3123)', () {
      // SPEC/program/world-market-resolution.md § Validation (issue #2989)
      // — Refs #3123: cumulative cap is inclusive; bids whose running
      // notional reaches the budget exactly are admitted.
      final results = TradeOrderValidator.validate(
        context: validatorCtx(
          treasuryBudgetForBids: 100,
          worldMarketState: WorldMarketState(
            prices: {
              CommodityCatalog.timber.id: 30,
              CommodityCatalog.iron.id: 10,
            },
          ),
        ),
        proposedOrders: [
          validatorBid(CommodityCatalog.timber.id, 2),
          validatorBid(CommodityCatalog.iron.id, 4),
        ],
      );
      expect(results, hasLength(2));
      expect(results[0].isAccepted, isTrue);
      expect(
        results[1].isAccepted,
        isTrue,
        reason: 'cumulative 100 == budget must be admitted',
      );
    });

    test('rejected bid does not consume the running spend budget — greedy '
        'continuation admits a later smaller bid that fits (Refs #3123)', () {
      // SPEC/program/world-market-resolution.md § Validation (issue #2989)
      // — Refs #3123: greedy continuation. timber x 4 @ 30 (notional 120)
      // overshoots the 100 budget and is rejected; the running spend stays
      // at 0 so the following iron x 1 @ 10 (notional 10) fits and is
      // admitted.
      final results = TradeOrderValidator.validate(
        context: validatorCtx(
          treasuryBudgetForBids: 100,
          tradeCargoCapacity: 100,
          worldMarketState: WorldMarketState(
            prices: {
              CommodityCatalog.timber.id: 30,
              CommodityCatalog.iron.id: 10,
            },
          ),
        ),
        proposedOrders: [
          validatorBid(CommodityCatalog.timber.id, 4),
          validatorBid(CommodityCatalog.iron.id, 1),
        ],
      );
      expect(results, hasLength(2));
      expect(
        results[0].reason,
        TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
      );
      expect(
        results[1].isAccepted,
        isTrue,
        reason:
            'greedy continuation: rejected bid must not consume '
            'the running spend budget so a later bid that fits the '
            'remaining budget is admitted',
      );
    });

    test(
      'treasuryBudgetForBids == 0 rejects every priced bid (Refs #3123)',
      () {
        final results = TradeOrderValidator.validate(
          context: validatorCtx(
            treasuryBudgetForBids: 0,
            worldMarketState: WorldMarketState(
              prices: {CommodityCatalog.timber.id: 30},
            ),
          ),
          proposedOrders: [
            validatorBid(CommodityCatalog.timber.id, 1),
            validatorBid(CommodityCatalog.timber.id, 5),
          ],
        );
        expect(results, hasLength(2));
        expect(
          results[0].reason,
          TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
        );
        expect(
          results[1].reason,
          TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
        );
      },
    );

    test('admits a bid priced solely from the catalog default when budget '
        'allows (Refs #3123 AC: rule 5 must not reject for unknown price '
        'when an initial/default price exists)', () {
      // SPEC/game/world-market.md § Treasury budget for bids: the
      // validator falls back to ResourceRules.defaultMarketPriceForCommodityId
      // when worldMarketState.prices omits the commodity. With a budget
      // that covers the catalog default, the bid must be accepted —
      // i.e. rule 5 must never reject solely for "missing live price"
      // when an initial price exists.
      final int? catalogTimber = ResourceRules.defaultRules
          .defaultMarketPriceForCommodityId(CommodityCatalog.timber.id);
      expect(
        catalogTimber,
        isNotNull,
        reason: 'timber must have a catalog default for this AC pin',
      );
      final int budget = catalogTimber! * 2; // covers a quantity-2 bid
      final results = TradeOrderValidator.validate(
        context: validatorCtx(
          treasuryBudgetForBids: budget,
          worldMarketState: const WorldMarketState(),
        ),
        proposedOrders: [validatorBid(CommodityCatalog.timber.id, 2)],
      );
      expect(
        results.single.isAccepted,
        isTrue,
        reason:
            'rule 5 must use the catalog default and admit when '
            'cumulative spend fits the budget',
      );
    });

    test('admits a manufactured-commodity bid priced from the catalog '
        'default when budget allows (Refs #3123 AC, manufactured branch)', () {
      // Refs #3093 manufactured-default-prices: manufactured commodities
      // (e.g. lumber) now resolve to a non-null catalog default. Pin
      // the positive acceptance branch alongside the existing rejection
      // branch so the AC is symmetric.
      final int? catalogLumber = ResourceRules.defaultRules
          .defaultMarketPriceForCommodityId(CommodityCatalog.lumber.id);
      expect(
        catalogLumber,
        isNotNull,
        reason: 'lumber must have a manufactured catalog default',
      );
      final int budget = catalogLumber!; // covers a quantity-1 bid exactly
      final results = TradeOrderValidator.validate(
        context: validatorCtx(
          treasuryBudgetForBids: budget,
          worldMarketState: const WorldMarketState(),
        ),
        proposedOrders: [validatorBid(CommodityCatalog.lumber.id, 1)],
      );
      expect(results.single.isAccepted, isTrue);
    });

    test('identical inputs produce identical result lists across two '
        'validate() calls (Refs #3123 AC: validator determinism)', () {
      // SPEC/program/world-market-resolution.md § Validation —
      // determinism: pure validator with no I/O / time / random
      // dependencies must return byte-identical results for byte-identical
      // inputs. Pin both an accepted and a rejected order so the
      // determinism contract covers both result branches.
      final context = validatorCtx(
        treasuryBudgetForBids: 100,
        tradeCargoCapacity: 100,
        worldMarketState: WorldMarketState(
          prices: {
            CommodityCatalog.timber.id: 30,
            CommodityCatalog.iron.id: 10,
          },
        ),
      );
      final orders = [
        validatorBid(CommodityCatalog.timber.id, 4), // 120 — rejected
        validatorBid(CommodityCatalog.iron.id, 1), // 10 — admitted (greedy)
      ];
      final first = TradeOrderValidator.validate(
        context: context,
        proposedOrders: orders,
      );
      final second = TradeOrderValidator.validate(
        context: context,
        proposedOrders: orders,
      );
      expect(second, hasLength(first.length));
      for (var i = 0; i < first.length; i++) {
        expect(second[i].isAccepted, first[i].isAccepted);
        expect(second[i].reason, first[i].reason);
      }
    });
  });

  group('effectiveMarketPriceForCommodityId — catalog default coverage '
      '(Refs #3123)', () {
    test('every non-riches commodity in the catalog resolves to a non-null '
        'effective price via the default ResourceRules (no hidden gaps that '
        "would force a rule-5 'unknown price' rejection in normal play)", () {
      // SPEC/game/world-market.md § Treasury budget for bids: rule 5
      // must use worldMarketState.prices ?? catalog default for every
      // tradeable commodity. This pin guards against silently shipping
      // a tradeable commodity without a catalog default (which would
      // otherwise let rule 5 admit unbounded bids on that commodity
      // because effectiveMarketPriceForCommodityId returns null →
      // 0 spend contribution).
      final rules = ResourceRules.defaultRules;
      for (final commodity in CommodityCatalog.all) {
        if (richesCommodityIds.contains(commodity.id)) continue;
        final effective = effectiveMarketPriceForCommodityId(
          commodityId: commodity.id,
          worldMarket: const WorldMarketState(),
          resourceRules: rules,
        );
        expect(
          effective,
          isNotNull,
          reason:
              'commodity ${commodity.id} (non-riches) must resolve to a '
              'non-null catalog default so rule 5 can price it',
        );
        expect(
          effective! >= 0,
          isTrue,
          reason:
              'catalog default for ${commodity.id} must be '
              'non-negative',
        );
      }
    });
  });
}
