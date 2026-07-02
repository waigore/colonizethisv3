import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// #3753 R6 boycott colony trade embargo (matcher slice).
///
/// SPEC: `SPEC/program/world-market-resolution.md` § Deal matching engine
/// (boycott exclusion); `SPEC/game/diplomacy.md` § GP–Tribe Rules (Boycott).
void main() {
  group('DealMatcher.matchDeals — #3753 R6 boycott exclusion', () {
    for (final scenario in dealMatcherBoycottScenarios()) {
      test(scenario.label, () => runDealMatcherScenario(scenario));
    }
  });
}
