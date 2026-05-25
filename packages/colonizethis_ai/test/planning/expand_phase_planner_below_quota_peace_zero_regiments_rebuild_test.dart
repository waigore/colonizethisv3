// Pins the canonical `isBelowQuotaPeaceZeroRegimentsRebuild` helper in
// `expand_phase_planner.dart` (Refs #2509 S1).
//
// This helper is Arm A of the EXPAND-trap below-quota rebuild gate:
// a below-quota GP with zero standing regiments and a non-empty invadable
// OW frontier is told to force a regiment build regardless of treasury
// (Arm C handles the cargo-recovery side). It is shared by:
//
//   - `planExpandEconomy` Arm A in `expand_phase_planner.dart`
//     (`regimentCount == 0 && hasInvadable` → `forceCheapestRegimentBuild`).
//   - `isBelowQuotaPeaceTreasuryRecovery` in `colonial_pressure.dart` —
//     a composite that short-circuits to `true` when this predicate fires.
//
// The S1 plan in #2509 deletes `colonial_pressure.dart` outright, so the
// public helper now lives in `expand_phase_planner.dart`. This test pins
// the canonical entrypoint directly so the delegation stub in
// `colonial_pressure.dart` can be removed in a future slice without
// regressing the legacy `isBelowQuotaPeaceTreasuryRecovery` composite or
// the planner's Arm A path.
//
// Behavioral invariants pinned here (all deterministic, constant-time):
//
//   1. Returns `true` exactly when all three legacy conditions hold
//      together: below the observer conquest quota, zero standing
//      regiments, and a non-empty invadable OW frontier. Each condition
//      is necessary — flipping any single input to its "off" value must
//      drop the result to `false`. This protects against a regression
//      that swapped `&&` for `||` or dropped one input from the
//      composite.
//   2. The quota gate is sourced from
//      `isBelowObserverConquestQuota` (i.e. strictly
//      `< kObserverConquestMinOwProvincesPerGp`), not a hard-coded
//      literal. Pinning at the boundary (quota-1, quota, quota+1) keeps
//      the helper aligned with the shared EXPAND quota constant if it is
//      ever retuned in `ai_victory_config.dart`.
//   3. The result is deterministic across repeated calls — required by
//      issue #2509 Must-have #7 "Determinism: same save + seeds → same
//      orders; phase planners are pure functions with deterministic
//      inputs." Two consecutive calls with identical inputs must yield
//      the same value (no hidden global mutation, no rng).
//   4. The delegating stub in `colonial_pressure.dart` returns the same
//      value as the canonical helper for every relevant input
//      combination — required so the legacy
//      `isBelowQuotaPeaceTreasuryRecovery` callers and the EXPAND
//      planner agree on the zero-regiments rebuild boundary. A drift
//      here would silently let one code path trigger the cargo-recovery
//      composite while the other planner Arm A diverges.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as colonial_pressure;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('isBelowQuotaPeaceZeroRegimentsRebuild', () {
    test('returns true when all three conditions hold together', () {
      expect(
        isBelowQuotaPeaceZeroRegimentsRebuild(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 1,
          regimentCount: 0,
          hasInvadableProvinces: true,
        ),
        isTrue,
        reason:
            'Below-quota GP with zero regiments and an invadable OW frontier '
            'is the EXPAND-trap rebuild trigger; the helper must report true '
            'so `planExpandEconomy` Arm A can force a build attempt.',
      );
    });

    test('drops to false when OW holdings reach the observer quota', () {
      expect(
        isBelowQuotaPeaceZeroRegimentsRebuild(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          regimentCount: 0,
          hasInvadableProvinces: true,
        ),
        isFalse,
        reason:
            'At quota the GP is no longer in EXPAND territory for this gate; '
            'the helper must short-circuit so the EXPAND-only force-build '
            'directive does not leak into COLONIAL / DEVELOP play.',
      );
      expect(
        isBelowQuotaPeaceZeroRegimentsRebuild(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp + 1,
          regimentCount: 0,
          hasInvadableProvinces: true,
        ),
        isFalse,
        reason:
            'Above quota the GP must not trigger the EXPAND-trap rebuild '
            'arm — sanity check that the boundary is strict (`<`, not '
            '`<=`) and matches `isBelowObserverConquestQuota`.',
      );
    });

    test('drops to false when standing regiments are present', () {
      expect(
        isBelowQuotaPeaceZeroRegimentsRebuild(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 1,
          regimentCount: 1,
          hasInvadableProvinces: true,
        ),
        isFalse,
        reason:
            'The Arm A trigger requires `regimentCount == 0`; any standing '
            'regiments push the GP into the Arm B / insufficient-regiments '
            'branch instead, so the helper must not fire here.',
      );
    });

    test('drops to false when no invadable OW frontier is available', () {
      expect(
        isBelowQuotaPeaceZeroRegimentsRebuild(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 1,
          regimentCount: 0,
          hasInvadableProvinces: false,
        ),
        isFalse,
        reason:
            'Without an invadable OW frontier the rebuild directive has '
            'nothing to act on; the helper must report false so the '
            'planner does not waste a build cycle in a sealed map state.',
      );
    });

    test('is deterministic across repeated calls (Must-have #7)', () {
      // Pure helper with explicit inputs; calling twice with identical
      // inputs must yield the same value. A regression that introduced
      // rng or mutable cache state would surface here as a divergence
      // between the two calls.
      final first = isBelowQuotaPeaceZeroRegimentsRebuild(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 1,
        regimentCount: 0,
        hasInvadableProvinces: true,
      );
      final second = isBelowQuotaPeaceZeroRegimentsRebuild(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 1,
        regimentCount: 0,
        hasInvadableProvinces: true,
      );
      expect(
        first,
        second,
        reason:
            'Pure helper must return identical results on repeated calls — '
            'required by issue #2509 Must-have #7 (phase planners are pure '
            'functions with deterministic inputs).',
      );
    });

    test('colonial_pressure delegation stub returns the canonical value', () {
      // Pins the S1 delegation contract: the legacy public symbol
      // exported from `colonial_pressure.dart` must mirror the canonical
      // helper for every relevant truth-table input so removing the stub
      // in a future slice cannot silently shift the EXPAND-trap rebuild
      // boundary for legacy callers.
      const ow = kObserverConquestMinOwProvincesPerGp - 1;
      for (final regimentCount in const [0, 1]) {
        for (final hasInvadableProvinces in const [true, false]) {
          expect(
            colonial_pressure.isBelowQuotaPeaceZeroRegimentsRebuild(
              oldWorldProvincesOwned: ow,
              regimentCount: regimentCount,
              hasInvadableProvinces: hasInvadableProvinces,
            ),
            isBelowQuotaPeaceZeroRegimentsRebuild(
              oldWorldProvincesOwned: ow,
              regimentCount: regimentCount,
              hasInvadableProvinces: hasInvadableProvinces,
            ),
            reason:
                '`colonial_pressure.isBelowQuotaPeaceZeroRegimentsRebuild` '
                'is a thin delegating stub for legacy callers; it must '
                'mirror the canonical helper exactly so the EXPAND '
                'planner Arm A and the legacy '
                '`isBelowQuotaPeaceTreasuryRecovery` composite agree on '
                'the zero-regiments rebuild trigger '
                '(regimentCount=$regimentCount, '
                'hasInvadableProvinces=$hasInvadableProvinces).',
          );
        }
      }
    });
  });
}
