// Case bodies for pins of the canonical `criticalOwHoldPeaceTargets` and
// `stalledBelowQuotaGpLeadPeaceTargets` below-quota EXPAND peace deciders
// at their new home in `expand_phase_planner.dart` (Refs #2509 S1).
//
// Both deciders were relocated from `colonial_pressure.dart` so they
// survive the now-completed S1 deletion of that file. The canonical
// implementations live in `expand_phase_planner.dart`.
//
// Live consumers (post-relocation):
//   * `criticalOwHoldPeaceTargets` is the EXPAND "critical OW hold"
//     survival peace arm from `SPEC/ai/ai-architecture.md`
//     § Diplomacy targeting — "when OW holdings are at or below
//     `kFewOldWorldProvincesDefendThreshold` and any OW minor remains
//     (peace all GP wars)". It peaces every at-war Great Power once the
//     player has dropped at or below the defend threshold while still
//     strictly below the observer OW quota, so the GP can rebuild
//     without losing the few OW provinces it still holds.
//   * `stalledBelowQuotaGpLeadPeaceTargets` is the EXPAND "peace the
//     leaders, hold the blocker" arm from
//     `SPEC/ai/ai-architecture.md` § Diplomacy targeting. It peaces
//     at-war Great Powers that lead by the band-selected minimum
//     province deficit (`kUnwinnableSoleGpMinProvinceDeficit` on the
//     default-start row; `1` on the post-default 8–9 OW row) while
//     excluding the canonical OW invadable blocker on a GP-only
//     frontier.
//
// Sibling test coverage that this file complements (but does not duplicate):
//
//   * `diplomacy_planner_below_quota_peace_test.dart` exercises the
//     deciders through the diplomacy-planner orchestration chain (GP
//     wars at 6 OW, sole GP at 7 OW). Those flows resolve through the
//     canonical helpers pinned here.
//
// Behavioral invariants pinned at the canonical entry points:
//
//   1. `criticalOwHoldPeaceTargets` short-circuits to `const []` when
//      the at-war filter (`game.playerById(...) != null`) collapses to
//      empty.
//   2. `criticalOwHoldPeaceTargets` fires only inside the
//      `isBelowObserverConquestQuota && ownOw <=
//      kFewOldWorldProvincesDefendThreshold` AND-band; the boundary at
//      `ownOw == kFewOldWorldProvincesDefendThreshold + 1` returns
//      `const []` and the interior `ownOw == kFewOldWorldProvincesDefendThreshold`
//      returns the sorted at-war GP list.
//   3. `stalledBelowQuotaGpLeadPeaceTargets` short-circuits to
//      `const []` at the observer quota even when a GP enemy leads by
//      more than `kUnwinnableSoleGpMinProvinceDeficit` (the quota
//      hand-off to the quota-met deciders).
//   4. `stalledBelowQuotaGpLeadPeaceTargets` selects deficit band
//      `kUnwinnableSoleGpMinProvinceDeficit` on the default-start row
//      (`own <= kObserverDefaultStartOldWorldProvincesPerGp`) and band
//      `1` on the post-default row (8–9 OW). Both boundary rows are
//      pinned with positive and negative cases so the band-selector
//      cannot silently regress.
//   5. `stalledBelowQuotaGpLeadPeaceTargets` excludes the
//      `primaryInvadableOldWorldGpBlocker` on a GP-only invadable
//      frontier while keeping non-blocker GP foes that still satisfy
//      the deficit.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

const String _gpOwn = 'gp_own';
const String _gpPartner = 'gp_partner';
const String _gpThird = 'gp_third';
const String _minor1 = 'minor1';

void registerExpandPhasePlannerCriticalOwHoldAndStalledLeadPeaceCasesPartB() {
  group('criticalOwHoldPeaceTargets — canonical at-war GP filter', () {
    test(
      'default-start row requires lead `kUnwinnableSoleGpMinProvinceDeficit`',
      () {
        // own == kObserverDefaultStartOldWorldProvincesPerGp (7) so the
        // minLeadDeficit table selects kUnwinnableSoleGpMinProvinceDeficit
        // (2). lead exactly 2 peaces.
        final game = buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          partnerProvinces:
              kObserverDefaultStartOldWorldProvincesPerGp +
              kUnwinnableSoleGpMinProvinceDeficit,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const [_gpPartner],
        );
        expect(
          stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
          [_gpPartner],
          reason:
              'Default-start row (own <= '
              'kObserverDefaultStartOldWorldProvincesPerGp) requires lead '
              '== kUnwinnableSoleGpMinProvinceDeficit. A regression that '
              'collapsed both rows to `1` would peace one-province '
              'leaders at default start and trade away early-game '
              'pressure.',
        );
      },
    );

    test('default-start row skips one-province lead (below band)', () {
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gpPartner],
      );
      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Default-start row must skip lead 1 — only '
            'kUnwinnableSoleGpMinProvinceDeficit (2) qualifies. Pins the '
            'negative boundary of the band selector against a regression '
            'that broadened the row to `>= own + 1`.',
      );
    });

    test('post-default row peaces a one-province lead (8 OW + 1)', () {
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
        partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 2,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp + 1,
        atWarWith: const [_gpPartner],
      );
      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        [_gpPartner],
        reason:
            'Post-default row (own > kObserverDefaultStartOldWorldProvincesPerGp) '
            'requires lead 1 only. A regression that kept '
            'kUnwinnableSoleGpMinProvinceDeficit on the post-default row '
            'would refuse to peace near-quota leaders and starve the '
            'pivot-to-minors arm of throughput.',
      );
    });

    test('post-default row skips a tied enemy (lead == 0)', () {
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
        partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp + 1,
        atWarWith: const [_gpPartner],
      );
      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Tied enemy on the post-default row fails the `>= own + 1` '
            'gate. Pins the negative boundary against a regression that '
            'used `>= own` instead.',
      );
    });
  });

  group('stalledBelowQuotaGpLeadPeaceTargets — canonical GP-only blocker', () {
    test('skips the primary invadable OW GP blocker on a GP-only frontier', () {
      // The partner owns the only invadable OW frontier province and
      // leads by 2 (the default-start band). On a GP-only frontier the
      // primary blocker must be excluded even though it satisfies the
      // deficit gate — so the canonical helper returns const [] when
      // the sole at-war GP is the blocker.
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        partnerProvinces:
            kObserverDefaultStartOldWorldProvincesPerGp +
            kUnwinnableSoleGpMinProvinceDeficit,
        invadablePartnerProvince: true,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_partner'],
      );
      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'On a GP-only invadable frontier the primary blocker is '
            'excluded from the lead-peace list so the EXPAND planner '
            'keeps fighting the canonical OW frontier blocker. A '
            'regression that dropped the carve-out would peace the '
            'blocker and surrender the OW frontier the planner needs '
            'to push past quota.',
      );
    });

    test('keeps a non-blocker GP that satisfies the deficit when the '
        'GP-only blocker is also at war', () {
      // Partner is the GP-only frontier blocker (owns the only
      // invadable province). gp_third is a non-blocker GP at war
      // with own and leads by 2 → must still peace.
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        partnerProvinces:
            kObserverDefaultStartOldWorldProvincesPerGp +
            kUnwinnableSoleGpMinProvinceDeficit,
        invadablePartnerProvince: true,
        extraGpId: _gpThird,
        extraGpProvinces:
            kObserverDefaultStartOldWorldProvincesPerGp +
            kUnwinnableSoleGpMinProvinceDeficit,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gpPartner, _gpThird],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_partner'],
      );
      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        [_gpThird],
        reason:
            'Non-blocker GP foes that satisfy the deficit must remain '
            'in the lead-peace list even when the GP-only blocker is '
            'co-belligerent. Pins the carve-out as exclusion-only — '
            'never expand-all-GP — so the planner does not peace the '
            'frontier blocker by accident.',
      );
    });
  });
}
