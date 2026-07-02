import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// Tests for `TradeOrderValidator` rule 5 — cross-commodity treasury bid cap.
/// Refs #3093.
void main() {
  group('TradeOrderValidator.validate — rule 5: bid treasury cap', () {
    for (final scenario in tradeOrderValidatorTreasuryScenarios()) {
      test(scenario.label, () => runTradeOrderValidatorScenario(scenario));
    }
  });

  group('effectiveMarketPriceForCommodityId — catalog default coverage '
      '(Refs #3123)', () {
    // Refs #3661 step 6: the exhaustive non-riches catalog sweep now lives
    // in packages/colonizethis_data/test/resource_rules_test.dart (group
    // 'defaultMarketPriceForCommodityId (Refs #3093)'), where the commodity
    // catalog and ResourceRules defaults are owned. Economy keeps one raw
    // and one manufactured regression pin so the economy-side
    // effectiveMarketPriceForCommodityId wiring (worldMarketState.prices ??
    // catalog default) stays covered without iterating the whole catalog
    // every package run.
    test('a representative raw and manufactured commodity resolve to a '
        'non-null, non-negative effective price from the catalog default '
        'when no live market price exists', () {
      final rules = ResourceRules.defaultRules;
      for (final commodityId in <String>[
        CommodityCatalog.timber.id,
        CommodityCatalog.lumber.id,
      ]) {
        final effective = effectiveMarketPriceForCommodityId(
          commodityId: commodityId,
          worldMarket: const WorldMarketState(),
          resourceRules: rules,
        );
        expect(
          effective,
          isNotNull,
          reason:
              'commodity $commodityId must resolve to a non-null catalog '
              'default so rule 5 can price it',
        );
        expect(
          effective! >= 0,
          isTrue,
          reason: 'catalog default for $commodityId must be non-negative',
        );
      }
    });
  });
}
