// Case bodies for quotaMetFutileBelowQuotaGpPeaceTargets pins in
// `expand_phase_planner_quota_met_peace_deciders_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'expand_phase_planner_quota_met_peace_deciders_support.dart';

void registerExpandPhasePlannerQuotaMetPeaceDecidersFutileCases() {
  group('quotaMetFutileBelowQuotaGpPeaceTargets — outer guards', () {
    test('returns const [] when own OW is one below the observer quota '
        '(below-quota outer guard)', () {
      // Even with a fully eligible below-quota enemy on the invadable
      // frontier, the below-quota outer guard must short-circuit before
      // the per-enemy filter loop runs.
      final game = buildQuotaMetPeaceDecidersGame(
        provincesByOwner: {
          quotaMetPeaceGpOwn: kObserverConquestMinOwProvincesPerGp - 1,
          quotaMetPeaceGpPartner: 5,
        },
        players: const [
          Player(id: quotaMetPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: quotaMetPeaceGpPartner, displayName: 'P', isHuman: false),
        ],
        extraInvadableMinorOwnerId: quotaMetPeaceMinor1,
        minorNations: const [
          MinorNation(id: quotaMetPeaceMinor1, displayName: 'M'),
        ],
      );
      final snapshot = quotaMetPeaceDecidersFocusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp - 1,
        atWarWith: const [quotaMetPeaceGpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Below the observer quota the canonical helper must '
            'short-circuit before evaluating the invadable frontier. '
            'A regression that flipped `<` to `<=` would silently '
            'peace allies the same turn the GP crossed the quota '
            'boundary.',
      );
    });

    test('returns const [] when no invadable OW provinces remain '
        '(invadable-empty outer guard)', () {
      // With no invadable OW the frontier-ownership filter is
      // meaningless; the canonical helper defers to the broader
      // `quotaMetBelowQuotaAtWarPeaceTargets` / consolidate deciders.
      final game = buildQuotaMetPeaceDecidersGame(
        provincesByOwner: {
          quotaMetPeaceGpOwn: kObserverConquestMinOwProvincesPerGp + 2,
          quotaMetPeaceGpPartner: 5,
        },
        players: const [
          Player(id: quotaMetPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: quotaMetPeaceGpPartner, displayName: 'P', isHuman: false),
        ],
      );
      final snapshot = quotaMetPeaceDecidersFocusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [quotaMetPeaceGpPartner],
        invadableProvinceIdsSorted: const [],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'With no remaining invadable OW provinces the canonical '
            'narrower decider must defer to the broader quota-met '
            'family rather than emit peace toward every below-quota '
            'GP. A regression that dropped the invadable-empty guard '
            'would collapse the narrower decider onto the broader one.',
      );
    });

    test(
      'enters the main pass at own OW == observer quota (strict `<` boundary)',
      () {
        // own == quota → `isBelowObserverConquestQuota` is false; a
        // below-quota non-blocker non-invadable-owner enemy surfaces.
        final game = buildQuotaMetPeaceDecidersGame(
          provincesByOwner: {
            quotaMetPeaceGpOwn: kObserverConquestMinOwProvincesPerGp,
            quotaMetPeaceGpPartner: 5,
          },
          players: const [
            Player(id: quotaMetPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
            Player(id: quotaMetPeaceGpPartner, displayName: 'P', isHuman: false),
          ],
          extraInvadableMinorOwnerId: quotaMetPeaceMinor1,
          minorNations: const [
            MinorNation(id: quotaMetPeaceMinor1, displayName: 'M'),
          ],
        );
        final snapshot = quotaMetPeaceDecidersFocusSnapshot(
          focusOw: kObserverConquestMinOwProvincesPerGp,
          atWarWith: const [quotaMetPeaceGpPartner],
          invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
        );
        expect(
          quotaMetFutileBelowQuotaGpPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          [quotaMetPeaceGpPartner],
          reason:
              'Exactly at kObserverConquestMinOwProvincesPerGp the canonical '
              'helper must enter the main pass. A below-quota non-blocker '
              'non-invadable-owner GP must surface so the futile-bullying '
              'exit fires at the SPEC-authorized quota boundary.',
        );
      },
    );
  });

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
