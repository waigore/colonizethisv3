// Case bodies for `expand_phase_planner_default_start_and_near_quota_peace_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Pins the canonical `defaultStartGpPeaceTargets` and
// `nearQuotaHoldPeaceTargets` EXPAND multi-GP peace deciders in
// `expand_phase_planner.dart` (Refs #2509 S1).
//
// Both deciders were relocated from `colonial_pressure.dart` so they
// survive the now-completed S1 deletion of that file. The canonical
// implementations live in `expand_phase_planner.dart`.
//
// Live consumers (post-relocation):
//   * `defaultStartGpPeaceTargets` is the EXPAND default-start band
//     pivot: when a GP is at the observer default-start size, peace
//     every at-war Great Power except the GP-only-frontier blocker so
//     the planner can open a minor frontier (seed-42 gp4 zero-gain
//     stall). Composes [hasUninvadedOldWorldMinor],
//     [isOldWorldGpOnlyInvadableFrontier], and
//     [primaryInvadableOldWorldGpBlocker] with the ceiling rules from
//     `SPEC/ai/ai-architecture.md` § Diplomacy targeting.
//   * `nearQuotaHoldPeaceTargets` is the EXPAND 8–9 OW hold-gains
//     pivot: peace distracting GP wars except the
//     `primaryInvadableOldWorldGpBlocker`, with the sole-GP
//     mutual-plateau carve-out peacing the lone blocker when no minor
//     pivot remains (seed-42 gp3). Composes [primaryInvadableOldWorldGpBlocker],
//     [isOldWorldGpOnlyInvadableFrontier], [isMutualBelowQuotaPlateauPeer],
//     and [hasUninvadedOldWorldMinor] with the near-quota band rules.
//
// Behavioral invariants pinned here (all deterministic — Must-have #7):
//
//   1. `defaultStartGpPeaceTargets` returns `const []` for each outer
//      guard in order:
//      a. `oldWorldProvincesOwned >= kObserverConquestMinOwProvincesPerGp`
//         (above-quota; quota-met collectors own the decision).
//      b. `oldWorldProvincesOwned > maxOwForGpPeace` where
//         `maxOwForGpPeace` is `kStalledOldWorldProvinceThreshold` when
//         an uninvaded OW minor remains and
//         `kObserverDefaultStartOldWorldProvincesPerGp + 1` otherwise.
//   2. On the GP-only invadable frontier arm the
//      `primaryInvadableOldWorldGpBlocker` is excluded from the peace
//      list; on every other shape the blocker filter is `null` and all
//      at-war GPs are peaced. Non-GP factions in `threats.atWarWith`
//      (tribes, minors) are filtered out via `game.playerById`.
//   3. `nearQuotaHoldPeaceTargets` returns `const []` for each outer
//      guard in order:
//      a. `!isBelowObserverConquestQuota(ownOw)` (quota-met collectors
//         own the decision).
//      b. `!isStalledOldWorldExpansion(ownOw)` (default-start collector
//         owns the decision).
//      c. Empty GP-war set after the `playerById` filter (no GP wars
//         to peace at all).
//   4. On the sole-GP arm the function peaces the lone GP only when
//      the war is a mutual-plateau sole-GP stalemate on a GP-only
//      invadable frontier with no uninvaded OW minors remaining;
//      otherwise, when the lone GP is the
//      `primaryInvadableOldWorldGpBlocker` and a minor pivot remains
//      the war is held open (`const []`). On the multi-GP arm it
//      peaces every at-war GP except the blocker, sorted ascending.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

import 'expand_phase_planner_default_start_near_quota_peace_support.dart';
import 'expand_phase_planner_default_start_peace_filter_sort_cases.dart';

void registerExpandDefaultStartPeaceCases() {
  group('defaultStartGpPeaceTargets — outer guards', () {
    test('returns const [] when at the observer OW quota', () {
      // OW == kObserverConquestMinOwProvincesPerGp → not below quota →
      // helper short-circuits before ceiling/blocker logic. The
      // EXPAND→COLONIAL handoff lets the quota-met collectors govern
      // post-quota wars.
      final game = buildDefaultStartNearQuotaExpandPeaceGame(
        owOwners: const {defaultStartPeaceGpOwn: 10, defaultStartPeaceGpA: 1},
        atWarPartners: const [defaultStartPeaceGpA],
      );
      final snapshot = defaultStartPeaceSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const [defaultStartPeaceGpA],
        invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
      );
      expect(
        defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'At quota the EXPAND default-start pivot is no longer in scope; '
            'the canonical helper must return empty so the COLONIAL/'
            'COLONIAL-lite peace rules govern post-quota wars.',
      );
    });

    test('returns const [] above ceiling without an uninvaded minor', () {
      // OW = 9, no minors on the map → maxOwForGpPeace = 8 →
      // ownOw > 8 → empty. Locks the no-minor ceiling shape.
      final game = buildDefaultStartNearQuotaExpandPeaceGame(
        owOwners: const {defaultStartPeaceGpOwn: 9, defaultStartPeaceGpA: 5},
        atWarPartners: const [defaultStartPeaceGpA],
      );
      final snapshot = defaultStartPeaceSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
        atWarWith: const [defaultStartPeaceGpA],
        invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
      );
      expect(
        defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Without an uninvaded minor on the map the ceiling is '
            'kObserverDefaultStartOldWorldProvincesPerGp + 1, so OW=9 '
            'must NOT engage the canonical pivot — there is no minor '
            'frontier to pivot to.',
      );
    });

    test(
      'returns the lone non-blocker GP at ceiling WITH an uninvaded minor',
      () {
        // OW = 9, an uninvaded minor (m1) holds an OW province →
        // hasUninvadedOldWorldMinor true → ceiling = 9 → eligible.
        // The only invadable OW belongs to the minor, so the
        // frontier is not GP-only → invadableBlocker = null →
        // every at-war GP is peaced (gp_a alone here).
        final game = buildDefaultStartNearQuotaExpandPeaceGame(
          owOwners: const {
            defaultStartPeaceGpOwn: 9,
            defaultStartPeaceMinorM1: 1,
          },
          atWarPartners: const [defaultStartPeaceGpA],
          atWarWithExtraGp: false,
        );
        final snapshot = defaultStartPeaceSnapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
          atWarWith: const [defaultStartPeaceGpA],
          invadableProvinceIdsSorted: const ['oldWorld|minor_m1_1'],
        );
        expect(
          defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
          const [defaultStartPeaceGpA],
          reason:
              'With an uninvaded minor on the map the ceiling extends to '
              'kStalledOldWorldProvinceThreshold and the lone non-blocker '
              'GP must be returned. A regression that kept the ceiling at '
              'the no-minor value here would block the minor-frontier '
              'pivot the rule was added for.',
        );
      },
    );
  });

  group('defaultStartGpPeaceTargets — blocker / frontier branches', () {
    test('mixed minor + GP frontier returns every at-war GP', () {
      // gp_a owns one invadable OW; minor_m1 owns another. The minor
      // owner makes the frontier non-GP-only → invadableBlocker null
      // → every at-war GP is peaced ascending.
      final game = buildDefaultStartNearQuotaExpandPeaceGame(
        owOwners: const {
          defaultStartPeaceGpOwn: 8,
          defaultStartPeaceGpA: 1,
          defaultStartPeaceGpB: 0,
          defaultStartPeaceMinorM1: 1,
        },
        atWarPartners: const [defaultStartPeaceGpA, defaultStartPeaceGpB],
      );
      final snapshot = defaultStartPeaceSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp + 1,
        atWarWith: const [defaultStartPeaceGpA, defaultStartPeaceGpB],
        invadableProvinceIdsSorted: const [
          'oldWorld|gp_a_1',
          'oldWorld|minor_m1_1',
        ],
      );
      expect(
        defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
        const [defaultStartPeaceGpA, defaultStartPeaceGpB],
        reason:
            'When the frontier mixes GP and minor owners no GP qualifies '
            'as the blocker (the minor pivot remains), so every at-war '
            'GP is peaced in ascending factionId order.',
      );
    });

    test(
      'GP-only frontier with multiple GPs at war excludes only the blocker',
      () {
        // Pure GP frontier: gp_a owns the sole invadable OW; gp_b
        // also at war but owns nothing on the frontier. The canonical
        // helper must drop gp_a (blocker) and return [gp_b] sorted.
        final game = buildDefaultStartNearQuotaExpandPeaceGame(
          owOwners: const {
            defaultStartPeaceGpOwn: 8,
            defaultStartPeaceGpA: 1,
            defaultStartPeaceGpB: 0,
          },
          atWarPartners: const [defaultStartPeaceGpA, defaultStartPeaceGpB],
        );
        final snapshot = defaultStartPeaceSnapshot(
          oldWorldProvincesOwned:
              kObserverDefaultStartOldWorldProvincesPerGp + 1,
          atWarWith: const [defaultStartPeaceGpA, defaultStartPeaceGpB],
          invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
        );
        expect(
          defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
          const [defaultStartPeaceGpB],
          reason:
              'On a GP-only frontier the blocker (gp_a) holds the only '
              'winnable OW front and must be preserved; remaining GP '
              'wars (gp_b) are peaced ascending.',
        );
      },
    );
  });

  registerExpandDefaultStartPeaceFilterSortCases();
}
