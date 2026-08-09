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

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';



import 'expand_phase_planner_default_start_near_quota_peace_support.dart';

void registerExpandNearQuotaPeaceCases() {

  group('nearQuotaHoldPeaceTargets — outer guards', () {
    test('returns const [] when at the observer OW quota', () {
      // OW == kObserverConquestMinOwProvincesPerGp → not below quota →
      // canonical helper short-circuits.
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
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'At quota the EXPAND near-quota hold-gains pivot is out of '
            'scope; the canonical helper must return empty so quota-met '
            'collectors govern post-quota wars.',
      );
    });

    test('returns const [] when below the stalled-band threshold', () {
      // OW = kObserverDefaultStartOldWorldProvincesPerGp (default
      // start) → !isStalledOldWorldExpansion → empty so the
      // default-start collector owns the decision.
      final game = buildDefaultStartNearQuotaExpandPeaceGame(
        owOwners: const {defaultStartPeaceGpOwn: 7, defaultStartPeaceGpA: 1},
        atWarPartners: const [defaultStartPeaceGpA],
      );
      final snapshot = defaultStartPeaceSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [defaultStartPeaceGpA],
        invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Below the stalled-band threshold the default-start '
            'collector (defaultStartGpPeaceTargets) owns the EXPAND '
            'pivot; the canonical near-quota helper must short-circuit.',
      );
    });

    test('returns const [] when no Great Powers are at war', () {
      // gp_own at 8 OW → in stalled band, below quota → both outer
      // guards pass. atWarWith carries only a tribe → playerById
      // filter empties the gp-war set → const [].
      final game = buildDefaultStartNearQuotaExpandPeaceGame(
        owOwners: const {defaultStartPeaceGpOwn: 8, defaultStartPeaceTribeT1: 0},
        atWarPartners: const [],
      );
      final snapshot = defaultStartPeaceSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
        atWarWith: const [defaultStartPeaceTribeT1],
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'A tribe-only atWarWith leaves an empty GP-war set after '
            'playerById filtering; the canonical helper must short-circuit '
            'before any blocker / frontier scan.',
      );
    });
  });

  group('nearQuotaHoldPeaceTargets — sole-GP arm', () {
    test(
      'sole GP mutual-plateau on GP-only frontier with no minor pivot peaces lone GP',
      () {
        // gp_own=8, gp_a=8 → mutual-plateau peer (|partner-own| <= 1,
        // both stalled below quota). Only invadable OW is gp_a's →
        // GP-only frontier. No OW minors → !hasUninvadedOldWorldMinor.
        // Canonical helper returns the unsorted single-GP list.
        final game = buildDefaultStartNearQuotaExpandPeaceGame(
          owOwners: const {defaultStartPeaceGpOwn: 8, defaultStartPeaceGpA: 8},
          atWarPartners: const [defaultStartPeaceGpA],
        );
        final snapshot = defaultStartPeaceSnapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
          atWarWith: const [defaultStartPeaceGpA],
          invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
        );
        expect(
          nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
          const [defaultStartPeaceGpA],
          reason:
              'The mutual-plateau sole-GP carve-out peaces the lone GP '
              'when the war is a stalemate on a GP-only invadable '
              'frontier with no remaining OW minor pivot.',
        );
      },
    );

    test('sole GP blocker with no minor pivot holds the war open', () {
      // gp_own=8, gp_a=10 (not mutual-plateau peer because |10-8|>1),
      // no minor on the map → hasUninvadedOldWorldMinor=false. gp_a
      // owns the only invadable OW (GP-only frontier). Sole GP at war
      // is the blocker; minor pivot is absent so the
      // sole-GP-blocker hold-open guard fires and the canonical helper
      // returns const [] — keep fighting the blocker.
      final game = buildDefaultStartNearQuotaExpandPeaceGame(
        owOwners: const {defaultStartPeaceGpOwn: 8, defaultStartPeaceGpA: 10},
        atWarPartners: const [defaultStartPeaceGpA],
      );
      final snapshot = defaultStartPeaceSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
        atWarWith: const [defaultStartPeaceGpA],
        invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'When the lone GP is the primary invadable OW blocker and '
            'no minor pivot remains, the canonical helper must hold '
            'the war open (return const []) so the planner keeps '
            'fighting the blocker. A regression that dropped the '
            '!hasUninvadedOldWorldMinor gate would silently surrender '
            'the war here.',
      );
    });

    test(
      'sole GP fall-through (non-blocker, non-plateau) returns the single-GP list',
      () {
        // gp_own=8, gp_a=8 (stalled-plateau peers). gp_a holds nothing
        // on the invadable list; the sole invadable OW is owned by
        // minor_m1 → frontier is NOT GP-only. Plateau check fires but
        // gpOnlyFrontier=false → mutual-plateau carve-out skipped. The
        // blocker is null because gp_a owns no invadable, so the
        // sole-GP-blocker hold guard does not trigger. Multi-GP arm
        // requires length >= 2; with length 1 the function falls
        // through to `return gpWars` (single-GP fall-through path).
        final game = buildDefaultStartNearQuotaExpandPeaceGame(
          owOwners: const {defaultStartPeaceGpOwn: 8, defaultStartPeaceGpA: 8, defaultStartPeaceMinorM1: 1},
          atWarPartners: const [defaultStartPeaceGpA],
        );
        final snapshot = defaultStartPeaceSnapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
          atWarWith: const [defaultStartPeaceGpA],
          invadableProvinceIdsSorted: const ['oldWorld|minor_m1_1'],
        );
        expect(
          nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
          const [defaultStartPeaceGpA],
          reason:
              'The sole-GP fall-through path returns the single-GP list '
              'unchanged when neither the mutual-plateau carve-out nor '
              'the blocker hold-open guard fires.',
        );
      },
    );
  });

  group('nearQuotaHoldPeaceTargets — multi-GP arm', () {
    test('multi-GP at war excludes the blocker and returns ascending', () {
      // gp_own=8 (stalled-plateau, below quota). Three GPs at war
      // supplied out of order; gp_a owns the sole invadable OW
      // (blocker). Canonical helper returns [gp_b, gp_c] ascending.
      final game = buildDefaultStartNearQuotaExpandPeaceGame(
        owOwners: const {defaultStartPeaceGpOwn: 8, defaultStartPeaceGpA: 1, defaultStartPeaceGpB: 0, defaultStartPeaceGpC: 0},
        atWarPartners: const [defaultStartPeaceGpC, defaultStartPeaceGpA, defaultStartPeaceGpB],
      );
      final snapshot = defaultStartPeaceSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
        atWarWith: const [defaultStartPeaceGpC, defaultStartPeaceGpA, defaultStartPeaceGpB],
        invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        const [defaultStartPeaceGpB, defaultStartPeaceGpC],
        reason:
            'The multi-GP arm excludes only the primary invadable OW '
            'blocker (gp_a) and returns the remaining GPs ascending '
            'across an out-of-order input list.',
      );
    });

    test(
      'multi-GP with null blocker (no invadable OW) returns every at-war GP sorted',
      () {
        // gp_own=8 (stalled-plateau). Two GPs at war but
        // invadableProvinceIdsSorted is empty → blocker == null →
        // every at-war GP is returned ascending.
        final game = buildDefaultStartNearQuotaExpandPeaceGame(
          owOwners: const {defaultStartPeaceGpOwn: 8, defaultStartPeaceGpA: 0, defaultStartPeaceGpB: 0},
          atWarPartners: const [defaultStartPeaceGpA, defaultStartPeaceGpB],
        );
        final snapshot = defaultStartPeaceSnapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
          atWarWith: const [defaultStartPeaceGpB, defaultStartPeaceGpA],
        );
        expect(
          nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
          const [defaultStartPeaceGpA, defaultStartPeaceGpB],
          reason:
              'When no invadable OW exists the blocker is null and the '
              'multi-GP arm peaces every at-war GP ascending.',
        );
      },
    );
  });

  group('nearQuotaHoldPeaceTargets — determinism / delegation', () {
    test('identical inputs return identical lists across two calls', () {
      final game = buildDefaultStartNearQuotaExpandPeaceGame(
        owOwners: const {defaultStartPeaceGpOwn: 8, defaultStartPeaceGpA: 1, defaultStartPeaceGpB: 0},
        atWarPartners: const [defaultStartPeaceGpA, defaultStartPeaceGpB],
      );
      final snapshot = defaultStartPeaceSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
        atWarWith: const [defaultStartPeaceGpA, defaultStartPeaceGpB],
        invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
      );
      final first = nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot);
      final second = nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot);
      expect(
        second,
        first,
        reason:
            'Two consecutive canonical-helper invocations on identical '
            'inputs must return identical lists (Must-have #7).',
      );
    });
  });
}
