import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Consolidated DealMatcher runners (Refs #3939 phase 3).
void main() {
  late final Map<String, TileMapResult> boycottTileMaps;
  late final MapTopology boycottTopology;

  setUpAll(() {
    boycottTileMaps = tileMapsForBoycottColonyTribeTest();
    boycottTopology = topologyForBoycottColonyTribeTest();
  });

  group('DealMatcher.pairKey', () {
    test('returns canonical key regardless of argument order', () {
      expect(
        DealMatcher.pairKey('alpha', 'zeta'),
        DealMatcher.pairKey('zeta', 'alpha'),
      );
      expect(DealMatcher.pairKey('alpha', 'zeta'), 'alpha|zeta');
    });

    test('handles equal ids (degenerate self-pair) deterministically', () {
      expect(DealMatcher.pairKey('a', 'a'), 'a|a');
    });
  });

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — empty inputs',
    dealMatcherEmptyAndBasicScenarios().take(3),
    runDealMatcherScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — basic fills',
    dealMatcherEmptyAndBasicScenarios().skip(3),
    runDealMatcherScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — cargo enforcement',
    dealMatcherCargoScenarios(),
    runDealMatcherScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — priority and FTP precedence',
    dealMatcherPriorityAndFtpScenarios(),
    runDealMatcherScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — multi-commodity',
    dealMatcherMultiCommodityScenarios(),
    runDealMatcherScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — lock-recovery seller priority (Refs #2924 F12)',
    dealMatcherLockRecoveryScenarios(),
    runDealMatcherScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — activity bookkeeping',
    dealMatcherActivityScenarios(),
    runDealMatcherScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — treasury clamp (Refs #3115)',
    dealMatcherTreasuryScenarios(),
    runDealMatcherScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — #3753 R7.3 sell-priority relation',
    dealMatcherSellPriorityScenarios(),
    runDealMatcherScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — #3753 R6 boycott exclusion',
    dealMatcherBoycottScenarios(),
    runDealMatcherScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — First Right of Refusal (#2992 D2)',
    dealMatcherFirstRightScenarios(),
    runDealMatcherScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — FRR activity bookkeeping (#2992 D2)',
    dealMatcherFrrActivityScenarios(),
    runDealMatcherScenario,
    labelOf: (s) => s.label,
  );

  group(
    'AC #1 — owning-GP bid wins above priority tiers AND FTP (#2992 D5)',
    () {
      for (final scenario in frrIssueAcD5MatcherScenarios()) {
        test(scenario.label, () => runDealMatcherScenario(scenario));
      }
    },
  );

  group('PurchasedTileIndex.forTesting (#2992 D2 test helper)', () {
    test('first attribution per tileKey wins on duplicates', () {
      const first = PurchasedTileAttribution(
        tileKey: 'oldWorld|M1|0|0',
        owningGpId: 'gpA',
        sourceFactionId: 'M1',
        provinceId: 'oldWorld|M1',
      );
      const second = PurchasedTileAttribution(
        tileKey: 'oldWorld|M1|0|0',
        owningGpId: 'gpB',
        sourceFactionId: 'M1',
        provinceId: 'oldWorld|M1',
      );
      final index = PurchasedTileIndex.forTesting([first, second]);
      expect(index.length, 1);
      expect(index.attributionForTileKey('oldWorld|M1|0|0'), first);
    });

    test('empty input yields empty index', () {
      final index = PurchasedTileIndex.forTesting(const []);
      expect(index.length, 0);
      expect(index.isEmpty, isTrue);
    });
  });

  group('boycottedColonySellableCommodityIds (Refs #3758 S7/R12)', () {
    for (final scenario in boycottBlockedCommoditiesScenarios()) {
      test(scenario.label, () {
        runBoycottBlockedCommoditiesScenario(
          scenario: scenario,
          defaultTileMaps: boycottTileMaps,
          defaultTopology: boycottTopology,
        );
      });
    }
  });

  group('computeLockRecoveryMinorAutoBids', () {
    for (final scenario in lockRecoveryMinorBidsScenarios()) {
      test(scenario.label, () {
        runLockRecoveryMinorBidsScenario(
          scenario: scenario,
          worldMarketState: lockRecoveryGrainMarket(),
        );
      });
    }
  });
}
