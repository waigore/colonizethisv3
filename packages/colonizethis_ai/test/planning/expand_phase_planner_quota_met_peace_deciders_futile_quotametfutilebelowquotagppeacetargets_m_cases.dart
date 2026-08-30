// quotaMetFutileBelowQuotaGpPeaceTargets — multi-target orderi (Refs #4602 Slice B).

// Case bodies for quotaMetFutileBelowQuotaGpPeaceTargets pins in
// `expand_phase_planner_quota_met_peace_deciders_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'expand_phase_planner_quota_met_peace_deciders_support.dart';

void
registerQuotaMetPeaceDecidersFutileQuotametfutilebelowquotagppeacetargetsMCases() {
  group('quotaMetFutileBelowQuotaGpPeaceTargets — multi-target ordering', () {
    test('returns multiple below-quota non-blocker off-frontier enemies '
        'sorted by factionId', () {
      // Two below-quota off-frontier enemies (gp_third, gp_fourth) +
      // one frontier owner (gp_partner) intentionally passed in
      // reverse-sort order. A regression that dropped `..sort()` on
      // the local list would surface as the reverse order.
      final game = buildQuotaMetPeaceDecidersGame(
        provincesByOwner: {
          quotaMetPeaceGpOwn: kObserverConquestMinOwProvincesPerGp + 2,
          quotaMetPeaceGpPartner: 4,
          quotaMetPeaceGpThird: 5,
          quotaMetPeaceGpFourth: 5,
        },
        players: const [
          Player(id: quotaMetPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: quotaMetPeaceGpPartner, displayName: 'F', isHuman: false),
          Player(id: quotaMetPeaceGpThird, displayName: 'T', isHuman: false),
          Player(id: quotaMetPeaceGpFourth, displayName: 'U', isHuman: false),
        ],
      );
      final snapshot = quotaMetPeaceDecidersFocusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [
          quotaMetPeaceGpFourth,
          quotaMetPeaceGpThird,
          quotaMetPeaceGpPartner,
        ],
        invadableProvinceIdsSorted: const [
          'oldWorld|${quotaMetPeaceGpPartner}_0',
        ],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        [quotaMetPeaceGpFourth, quotaMetPeaceGpThird],
        reason:
            'Multi-target results must be sorted ascending so '
            'downstream offer-peace scoring sees a stable order. The '
            'frontier-owning gp_partner is filtered; the two '
            'off-frontier below-quota enemies surface in ascending '
            'factionId order regardless of input order.',
      );
    });

    test('is deterministic across repeated calls (Must-have #7)', () {
      final game = buildQuotaMetPeaceDecidersGame(
        provincesByOwner: {
          quotaMetPeaceGpOwn: kObserverConquestMinOwProvincesPerGp + 2,
          quotaMetPeaceGpThird: 5,
          quotaMetPeaceGpFourth: 5,
        },
        players: const [
          Player(id: quotaMetPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: quotaMetPeaceGpThird, displayName: 'T', isHuman: false),
          Player(id: quotaMetPeaceGpFourth, displayName: 'U', isHuman: false),
        ],
        extraInvadableMinorOwnerId: quotaMetPeaceMinor1,
        minorNations: const [
          MinorNation(id: quotaMetPeaceMinor1, displayName: 'M'),
        ],
      );
      final snapshot = quotaMetPeaceDecidersFocusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [quotaMetPeaceGpFourth, quotaMetPeaceGpThird],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
      );
      final first = quotaMetFutileBelowQuotaGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = quotaMetFutileBelowQuotaGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final third = quotaMetFutileBelowQuotaGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(first, [quotaMetPeaceGpFourth, quotaMetPeaceGpThird]);
      expect(second, first);
      expect(third, first);
    });
  });
}
