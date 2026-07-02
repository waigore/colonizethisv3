// Embassy overseas-profit kickback (#3753 R8.3) aggregation tests for
// `computeFirstRightCredits`.
//
// SPEC: `SPEC/game/world-market-first-right-of-refusal.md` § Profit formula
// (D3, AC-7) and § Treasury transfer (D4, AC-D4-7/AC-D4-8). The kickback path
// credits every embassy-holding GP that does NOT own the sourcing tile a 10%
// share of its relation portion, including on sales with no purchased-tile
// attribution (R8.6); the tile owner is excluded from the kickback (R8.5) but
// still receives its full tile-owner share.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('computeFirstRightCredits embassy kickbacks (#3753 R8.3)', () {
    for (final scenario in frrCreditsKickbackScenarios()) {
      test(scenario.label, () => runFrrCreditsScenario(scenario));
    }
  });
}
