// quotaMetFutileBelowQuotaGpPeaceTargets — per-enemy filters (Refs #4602 Slice B).

// Case bodies for quotaMetFutileBelowQuotaGpPeaceTargets pins in
// `expand_phase_planner_quota_met_peace_deciders_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'expand_phase_planner_quota_met_peace_deciders_support.dart';

void
registerQuotaMetPeaceDecidersFutileQuotametfutilebelowquotagppeacetargetsPCases() {
  group('quotaMetFutileBelowQuotaGpPeaceTargets — per-enemy filters', () {
    test('filters out non-GP factions in atWarWith (minors / tribes)', () {
      // A minor in `atWarWith` (here `minor1` owning the invadable
      // frontier itself) must not surface; the helper is GP-vs-GP only.
      final game = buildQuotaMetPeaceDecidersGame(
        provincesByOwner: {
          quotaMetPeaceGpOwn: kObserverConquestMinOwProvincesPerGp + 2,
        },
        players: const [
          Player(id: quotaMetPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
        ],
        extraInvadableMinorOwnerId: quotaMetPeaceMinor1,
        minorNations: const [
          MinorNation(id: quotaMetPeaceMinor1, displayName: 'M'),
        ],
      );
      final snapshot = quotaMetPeaceDecidersFocusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [quotaMetPeaceMinor1],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Minors and tribes belong to the defaultStartFutileMinorPeaceTargets '
            'family. A regression that dropped the playerById guard '
            'would surface "minor1" as a futile-bullying GP target.',
      );
    });

    test('skips at-war Great Powers at or above the observer quota', () {
      // Two GP enemies: one at-quota (filtered), one below-quota (kept).
      final game = buildQuotaMetPeaceDecidersGame(
        provincesByOwner: {
          quotaMetPeaceGpOwn: kObserverConquestMinOwProvincesPerGp + 2,
          quotaMetPeaceGpPartner: kObserverConquestMinOwProvincesPerGp,
          quotaMetPeaceGpThird: kObserverConquestMinOwProvincesPerGp - 1,
        },
        players: const [
          Player(id: quotaMetPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: quotaMetPeaceGpPartner, displayName: 'Q', isHuman: false),
          Player(id: quotaMetPeaceGpThird, displayName: 'L', isHuman: false),
        ],
        extraInvadableMinorOwnerId: quotaMetPeaceMinor1,
        minorNations: const [
          MinorNation(id: quotaMetPeaceMinor1, displayName: 'M'),
        ],
      );
      final snapshot = quotaMetPeaceDecidersFocusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [quotaMetPeaceGpPartner, quotaMetPeaceGpThird],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        [quotaMetPeaceGpThird],
        reason:
            'Quota-met enemies belong to consolidateGainsSoleGpPeaceTarget '
            'and the broader quota-met family, not this narrower '
            'futile-bullying decider. A regression that dropped the '
            'per-enemy quota check would silently leak quota-met '
            'enemies into the futile result set.',
      );
    });

    test('skips at-war Great Powers that own one of the invadable OW '
        'provinces (frontier-owner skip)', () {
      // gp_partner owns the sole invadable OW province → frontier-
      // owner skip fires; gp_third (off-frontier below-quota enemy)
      // is the only survivor.
      final game = buildQuotaMetPeaceDecidersGame(
        provincesByOwner: {
          quotaMetPeaceGpOwn: kObserverConquestMinOwProvincesPerGp + 2,
          quotaMetPeaceGpPartner: 4,
          quotaMetPeaceGpThird: 5,
        },
        players: const [
          Player(id: quotaMetPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: quotaMetPeaceGpPartner, displayName: 'F', isHuman: false),
          Player(id: quotaMetPeaceGpThird, displayName: 'O', isHuman: false),
        ],
      );
      final snapshot = quotaMetPeaceDecidersFocusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [quotaMetPeaceGpPartner, quotaMetPeaceGpThird],
        invadableProvinceIdsSorted: const [
          'oldWorld|${quotaMetPeaceGpPartner}_0',
        ],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        [quotaMetPeaceGpThird],
        reason:
            'Peace toward a GP that still owns one of the active '
            'player\'s invadable OW provinces would forfeit the '
            'remaining OW acquisition path. The frontier-owner skip '
            'must keep that war open while the off-frontier '
            'below-quota enemy surfaces for peace.',
      );
    });

    test('skips the primary invadable OW blocker even when it owns no '
        'invadable here (defensive backstop)', () {
      // gp_partner is the sole invadable-OW owner → also the blocker
      // by construction; gp_third is the off-frontier below-quota
      // survivor. The blocker-equality skip backstops the
      // frontier-owner skip; pinning a fixture where the blocker
      // also owns the invadable keeps the result identical with or
      // without the defensive backstop, documenting the contract.
      final game = buildQuotaMetPeaceDecidersGame(
        provincesByOwner: {
          quotaMetPeaceGpOwn: kObserverConquestMinOwProvincesPerGp + 2,
          quotaMetPeaceGpPartner: 4,
          quotaMetPeaceGpThird: 5,
        },
        players: const [
          Player(id: quotaMetPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: quotaMetPeaceGpPartner, displayName: 'B', isHuman: false),
          Player(id: quotaMetPeaceGpThird, displayName: 'O', isHuman: false),
        ],
      );
      final snapshot = quotaMetPeaceDecidersFocusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [quotaMetPeaceGpPartner, quotaMetPeaceGpThird],
        invadableProvinceIdsSorted: const [
          'oldWorld|${quotaMetPeaceGpPartner}_0',
        ],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        [quotaMetPeaceGpThird],
        reason:
            'The primary invadable OW blocker must never appear in '
            'the futile-bullying peace list. A future refactor that '
            'decoupled the blocker identity from per-province '
            'invadable ownership must still respect the equality '
            'skip pinned here.',
      );
    });
  });
}
