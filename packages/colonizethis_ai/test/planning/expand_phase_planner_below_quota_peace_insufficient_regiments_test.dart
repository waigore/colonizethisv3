// Pins the canonical `isBelowQuotaPeaceInsufficientRegiments` helper in
// `expand_phase_planner.dart` (Refs #2509 S1).
//
// This helper is Arm B of the EXPAND-trap below-quota rebuild gate: a
// below-quota GP at peace with all Great Powers carrying a positive but
// small standing regiment count (in the half-open range
// `[1, kBelowQuotaPeaceMinRegimentsBeforeDeclareWar)`) and a non-empty
// invadable OW frontier is told to delay declare-war on the GP-only
// frontier until enough regiments are rebuilt to mount a credible attack
// (Refs #2509 § Observer goal phases (Full AI) "EXPAND regiment-rebuild
// trap"). It is shared by:
//
//   - `isBelowQuotaPeaceTreasuryRecovery` in `expand_phase_planner.dart`
//     — the three-arm EXPAND-trap composite that short-circuits to `true`
//     when this predicate fires AND effective treasury falls short of the
//     cheapest regiment cost.
//   - Phase-derived equivalent
//     `resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive`
//     in `phase_planner_economy_filter.dart` consumed by the orchestrator's
//     `_appendEconomyBuildOrders` build-rebuild-trap slice (Refs #2509 S5).
//
// The S1 plan in #2509 deletes `colonial_pressure.dart` outright, so the
// public helper now lives in `expand_phase_planner.dart`. This test pins
// the canonical entrypoint directly so the delegation stub in
// `colonial_pressure.dart` can be removed in a future slice without
// regressing the legacy `isBelowQuotaPeaceTreasuryRecovery` composite or
// the orchestrator's phase-derived rebuild-trap path.
//
// Behavioral invariants pinned here (all deterministic, constant-time):
//
//   1. Returns `true` exactly when all four legacy conditions hold
//      together: below the observer conquest quota, not at war with any
//      Great Power, regiment count strictly inside
//      `[1, kBelowQuotaPeaceMinRegimentsBeforeDeclareWar)`, and a
//      non-empty invadable OW frontier. Each condition is necessary —
//      flipping any single input to its "off" value must drop the
//      result to `false`. This protects against a regression that swapped
//      `&&` for `||` or dropped one input from the composite.
//   2. The quota gate is sourced from `isBelowObserverConquestQuota`
//      (strictly `< kObserverConquestMinOwProvincesPerGp`), not a
//      hard-coded literal. Pinning at the boundary (quota-1, quota,
//      quota+1) keeps the helper aligned with the shared EXPAND quota
//      constant if it is ever retuned in `ai_victory_config.dart`.
//   3. The regiment-count band is the half-open range
//      `[1, kBelowQuotaPeaceMinRegimentsBeforeDeclareWar)` — zero
//      regiments belong to Arm A (`isBelowQuotaPeaceZeroRegimentsRebuild`)
//      and a regiment count at or above the floor exits the trap.
//   4. The result is deterministic across repeated calls — required by
//      issue #2509 Must-have #7 "Determinism: same save + seeds → same
//      orders; phase planners are pure functions with deterministic
//      inputs."
//   5. The delegating stub in `colonial_pressure.dart` returns the same
//      value as the canonical helper for every relevant input
//      combination — required so the legacy
//      `isBelowQuotaPeaceTreasuryRecovery` callers and the EXPAND
//      planner agree on the insufficient-regiments boundary.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as colonial_pressure;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('isBelowQuotaPeaceInsufficientRegiments', () {
    test('returns true for the seed-42 trap shape', () {
      expect(
        isBelowQuotaPeaceInsufficientRegiments(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          regimentCount: 3,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
        ),
        isTrue,
        reason:
            'Below-quota GP at peace with a small positive standing regiment '
            'count and an invadable OW frontier is the EXPAND-trap '
            'insufficient-regiments trigger; the helper must report true so '
            '`isBelowQuotaPeaceTreasuryRecovery` Arm B and the orchestrator '
            'phase-derived rebuild-trap path agree on the gate.',
      );
    });

    test('drops to false when OW holdings reach the observer quota', () {
      expect(
        isBelowQuotaPeaceInsufficientRegiments(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          regimentCount: 3,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
        ),
        isFalse,
        reason:
            'At quota the GP is no longer in EXPAND territory for this gate; '
            'the helper must short-circuit so the EXPAND-only rebuild-trap '
            'arm does not leak into COLONIAL / DEVELOP play.',
      );
      expect(
        isBelowQuotaPeaceInsufficientRegiments(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp + 1,
          regimentCount: 3,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
        ),
        isFalse,
        reason:
            'Above quota the GP must not trigger the EXPAND-trap '
            'insufficient-regiments arm — sanity check that the boundary is '
            'strict (`<`, not `<=`) and matches `isBelowObserverConquestQuota`.',
      );
    });

    test('drops to false when at war with any Great Power', () {
      expect(
        isBelowQuotaPeaceInsufficientRegiments(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          regimentCount: 3,
          atWarWithAnyGreatPower: true,
          hasInvadableProvinces: true,
        ),
        isFalse,
        reason:
            'The trap predicate only fires at peace; an existing GP war '
            'means the regiment budget is already committed and the '
            'rebuild-trap directive does not apply.',
      );
    });

    test('drops to false when regimentCount is zero', () {
      expect(
        isBelowQuotaPeaceInsufficientRegiments(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          regimentCount: 0,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
        ),
        isFalse,
        reason:
            'Zero regiments belongs to Arm A '
            '(`isBelowQuotaPeaceZeroRegimentsRebuild`); the helper must not '
            'fire so the two arms partition cleanly inside the '
            '`isBelowQuotaPeaceTreasuryRecovery` composite.',
      );
    });

    test(
      'drops to false at the at-peace declare-war floor (upper boundary)',
      () {
        expect(
          isBelowQuotaPeaceInsufficientRegiments(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 1,
            regimentCount: kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
            atWarWithAnyGreatPower: false,
            hasInvadableProvinces: true,
          ),
          isFalse,
          reason:
              'At the at-peace declare-war floor the GP has enough regiments '
              'to mount a credible attack; the helper must report false so '
              'the planner exits the rebuild-trap arm and resumes '
              'declare-war planning.',
        );
      },
    );

    test('returns true just below the at-peace declare-war floor', () {
      expect(
        isBelowQuotaPeaceInsufficientRegiments(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 1,
          regimentCount: kBelowQuotaPeaceMinRegimentsBeforeDeclareWar - 1,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
        ),
        isTrue,
        reason:
            'Just below the at-peace declare-war floor the GP still needs to '
            'rebuild; the helper must fire so the cargo-recovery composite '
            'and the orchestrator phase-derived rebuild-trap path agree.',
      );
    });

    test('drops to false when no invadable OW frontier remains', () {
      expect(
        isBelowQuotaPeaceInsufficientRegiments(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          regimentCount: 3,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: false,
        ),
        isFalse,
        reason:
            'Without an invadable OW frontier the rebuild-trap directive has '
            'nothing to act on; the helper must report false so the planner '
            'does not waste a build cycle in a sealed map state.',
      );
    });

    test('is deterministic across repeated calls (Must-have #7)', () {
      final first = isBelowQuotaPeaceInsufficientRegiments(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
        regimentCount: 3,
        atWarWithAnyGreatPower: false,
        hasInvadableProvinces: true,
      );
      final second = isBelowQuotaPeaceInsufficientRegiments(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
        regimentCount: 3,
        atWarWithAnyGreatPower: false,
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
      // Pins the S1 delegation contract: the legacy public symbol exported
      // from `colonial_pressure.dart` must mirror the canonical helper for
      // every relevant truth-table input so removing the stub in a future
      // slice cannot silently shift the EXPAND-trap insufficient-regiments
      // boundary for legacy callers.
      for (final ow in const [
        kObserverConquestMinOwProvincesPerGp - 2,
        kObserverConquestMinOwProvincesPerGp,
      ]) {
        for (final regimentCount in const [0, 1, 3]) {
          for (final atWar in const [true, false]) {
            for (final hasInvadable in const [true, false]) {
              expect(
                colonial_pressure.isBelowQuotaPeaceInsufficientRegiments(
                  oldWorldProvincesOwned: ow,
                  regimentCount: regimentCount,
                  atWarWithAnyGreatPower: atWar,
                  hasInvadableProvinces: hasInvadable,
                ),
                isBelowQuotaPeaceInsufficientRegiments(
                  oldWorldProvincesOwned: ow,
                  regimentCount: regimentCount,
                  atWarWithAnyGreatPower: atWar,
                  hasInvadableProvinces: hasInvadable,
                ),
                reason:
                    '`colonial_pressure.isBelowQuotaPeaceInsufficientRegiments` '
                    'is a thin delegating stub for legacy callers; it must '
                    'mirror the canonical helper exactly so the EXPAND-trap '
                    'rebuild composite and orchestrator phase-derived path '
                    'agree on the insufficient-regiments trigger '
                    '(ow=$ow, regimentCount=$regimentCount, '
                    'atWarWithAnyGreatPower=$atWar, '
                    'hasInvadableProvinces=$hasInvadable).',
              );
            }
          }
        }
      }
    });
  });
}
