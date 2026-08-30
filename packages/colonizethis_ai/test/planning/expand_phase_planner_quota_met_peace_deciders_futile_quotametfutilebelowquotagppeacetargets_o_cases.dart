// quotaMetFutileBelowQuotaGpPeaceTargets — outer guards (Refs #4602 Slice B).

// Case bodies for quotaMetFutileBelowQuotaGpPeaceTargets pins in
// `expand_phase_planner_quota_met_peace_deciders_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'expand_phase_planner_quota_met_peace_deciders_support.dart';

void
registerQuotaMetPeaceDecidersFutileQuotametfutilebelowquotagppeacetargetsOCases() {
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
            Player(
              id: quotaMetPeaceGpOwn,
              displayName: 'GP_OWN',
              isHuman: false,
            ),
            Player(
              id: quotaMetPeaceGpPartner,
              displayName: 'P',
              isHuman: false,
            ),
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
}
