// Pins the canonical `cheapestRegimentBuildTreasuryCost` helper in
// `expand_phase_planner.dart` (Refs #2509 S1).
//
// This helper governs the EXPAND-trap treasury affordability gate that is
// shared by `planExpandDeclareWar` (priority-arm skip when treasury is
// below the cheapest regiment cost), `planExpandEconomy`
// (`ExpandEconomyPlan.boostTreasuryRecoveryCargo` when below-quota cash +
// pending riches cannot fund a build), and the COLONIAL declare-war arm
// in `colonial_phase_planner.dart`. The same value also backs the
// `isBelowQuotaPeaceTreasuryRecovery` cargo trigger in
// `colonial_pressure.dart` (now a thin delegating stub).
//
// The S1 plan in #2509 deletes `colonial_pressure.dart` outright, so the
// public helper now lives in `expand_phase_planner.dart`. This test pins
// the canonical entrypoint directly so the delegation stubs in
// `colonial_pressure.dart` and the private wrapper in
// `colonial_phase_planner.dart` can be removed in a future slice without
// regressing the cross-phase callers.
//
// Behavioral invariants pinned here (all deterministic against the
// embedded [RegimentEconomyCatalog]):
//
//   1. Returns the strict minimum of every catalog entry's
//      `buildTreasuryCost`, not the first entry, not the sum, not a
//      cached constant from `ai_victory_config.dart`. The catalog scan
//      is exhaustive so adding a cheaper regiment shifts the result;
//      adding an expensive regiment does not.
//   2. The result is strictly positive (regiment builds always require
//      treasury) so the `treasury < cheapest` branches in EXPAND /
//      COLONIAL stay reachable when treasury == 0.
//   3. The result is deterministic across repeated calls — required by
//      issue #2509 Must-have #7 "Determinism: same save + seeds → same
//      orders; phase planners are pure functions with deterministic
//      inputs." Two consecutive calls inside the same isolate must
//      yield the same value (no hidden global mutation, no rng).
//   4. The delegating stub in `colonial_pressure.dart` returns the same
//      value as the canonical helper — required so the legacy
//      `isBelowQuotaPeaceTreasuryRecovery` callers and the EXPAND /
//      COLONIAL phase planners agree on the affordability boundary.
//      A drift here would silently let one code path declare war while
//      the other still gates on cargo recovery for the same GP.

import 'package:colonizethis_ai/src/planning/colonial_pressure.dart'
    as colonial_pressure;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('cheapestRegimentBuildTreasuryCost', () {
    test('matches the strict minimum across the regiment economy catalog', () {
      // Recompute the expected minimum without sharing the helper's loop
      // shape so a regression that swapped the comparison (`>` instead
      // of `<`) or returned the first entry would not also pass this
      // test. The catalog snapshot is deterministic at process start.
      final entries = RegimentEconomyCatalog.byId.values.toList();
      expect(
        entries,
        isNotEmpty,
        reason:
            'RegimentEconomyCatalog must ship at least one regiment so the '
            'EXPAND affordability gate has a meaningful floor.',
      );
      final expected = entries
          .map((econ) => econ.buildTreasuryCost)
          .reduce((a, b) => a < b ? a : b);
      expect(
        cheapestRegimentBuildTreasuryCost(),
        expected,
        reason:
            'Helper must return the strict catalog minimum so the EXPAND-trap '
            '`treasury < cheapest` gate stays consistent with `planExpand*` '
            'callers and the COLONIAL declare-war arm.',
      );
    });

    test('returns a strictly positive treasury cost', () {
      // A non-positive result would make the `treasury < cheapest` gate
      // in `planExpandDeclareWar` unreachable at treasury == 0 (negative
      // costs invert the comparison; zero leaves a GP at zero treasury
      // free to declare war). Either regression would break the EXPAND
      // suppression / recovery contract documented in issue #2509.
      expect(
        cheapestRegimentBuildTreasuryCost(),
        greaterThan(0),
        reason:
            'Regiment builds always cost treasury; a zero / negative floor '
            'would silently bypass the EXPAND-trap affordability gate.',
      );
    });

    test('is deterministic across repeated calls (Must-have #7)', () {
      // The helper is pure with no inputs; calling twice in the same
      // isolate must yield the same value. A regression that introduced
      // rng (e.g. randomized catalog iteration) or mutable cache state
      // would surface here as a divergence between the two calls.
      final first = cheapestRegimentBuildTreasuryCost();
      final second = cheapestRegimentBuildTreasuryCost();
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
      // Pins the S1 delegation contract: removing the legacy public
      // `cheapestRegimentBuildTreasuryCost` symbol from
      // `colonial_pressure.dart` must keep returning the same value as
      // the canonical helper for as long as the stub survives.
      expect(
        colonial_pressure.cheapestRegimentBuildTreasuryCost(),
        cheapestRegimentBuildTreasuryCost(),
        reason:
            '`colonial_pressure.cheapestRegimentBuildTreasuryCost` is a thin '
            'delegating stub for legacy callers; it must mirror the '
            'canonical helper exactly so the EXPAND and COLONIAL phase '
            'planners agree on the affordability boundary.',
      );
    });
  });
}
