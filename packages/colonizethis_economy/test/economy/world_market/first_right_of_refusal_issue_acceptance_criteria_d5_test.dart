// Issue-AC-mapped unit tests for World Market First Right of Refusal (#2992 D5).
//
// SPEC: `SPEC/game/world-market-first-right-of-refusal.md` (D2 priority
// override, D3 profit formula, D4 treasury transfer). This file
// consolidates the five numbered ACs at the bottom of issue
// [#2992](https://github.com/waigore/colonizethisv3/issues/2992) into a
// single D5 contract file. Each `group(...)` maps 1:1 to one issue AC
// so reviewers / `verify-github-issue` can audit AC↔test coverage
// without cross-referencing slice files.
//
// Issue AC → group mapping (#3753 R8 supersedes the #2992 40%-cap amounts):
//  AC #1 — Owning GP's bid wins purchased-tile offer above every
//          priority tier AND above FTP (DealMatcher).
//  AC #2 — Other-GP buy at relation 75 credits owning GP exactly
//          `10 * 20 * 0.75 = 150` treasury (full share, credits helper).
//  AC #3 — Other-GP buy at relation 100 credits exactly 100% of sale
//          value (upper-bound full share, no 40% cap).
//  AC #4 — Other-GP buy at relation 0 credits 0 treasury (lower bound;
//          also: D2 FRR-match path excluded from D4 aggregation).
//  AC #5 — Multi-GP attribution: each owning GP credited only for own
//          tile(s); same GP across two minors aggregates per source
//          relation independently.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('AC #1 — owning-GP bid wins above priority tiers AND FTP', () {
    for (final scenario in frrIssueAcD5MatcherScenarios()) {
      test(scenario.label, () => runDealMatcherScenario(scenario));
    }
  });

  group('AC #2 — relation 75 credits 10*20*0.75 = 150 treasury (full)', () {
    for (final scenario in frrIssueAcD5CreditsAc2Scenarios()) {
      test(scenario.label, () => runFrrCreditsScenario(scenario));
    }
  });

  group('AC #3 — relation 100 credits exactly 100% of sale value', () {
    for (final scenario in frrIssueAcD5CreditsAc3Scenarios()) {
      test(scenario.label, () => runFrrCreditsScenario(scenario));
    }
  });

  group('AC #4 — relation 0 credits 0 treasury (no overseas profit)', () {
    for (final scenario in frrIssueAcD5CreditsAc4Scenarios()) {
      test(scenario.label, () => runFrrCreditsScenario(scenario));
    }
  });

  group('AC #5 — multi-GP attribution, no cross-credit', () {
    for (final scenario in frrIssueAcD5CreditsAc5Scenarios()) {
      test(scenario.label, () => runFrrCreditsScenario(scenario));
    }
  });
}
