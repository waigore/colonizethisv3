// Pins the canonical `isBelowQuotaPeaceTreasuryRecovery` composite in
// `expand_phase_planner.dart` (Refs #2509 S1).
//
// This composite is the three-arm EXPAND-trap below-quota peace
// treasury-recovery decision used by the cargo-preference boost in
// `economy_planner.dart` (legacy path) and the orchestrator's
// `_appendEconomyBuildOrders` build-rebuild-trap slice via the phase-derived
// equivalents
// `resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive` and
// `resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive`
// (`phase_planner_economy_filter.dart`, Refs #2509 S5).
//
// Arm A short-circuits to `true` when
// `isBelowQuotaPeaceZeroRegimentsRebuild` fires (canonical Arm A,
// `expand_phase_planner.dart`). Arm B requires
// `isBelowQuotaPeaceInsufficientRegiments` (canonical Arm B,
// `expand_phase_planner.dart`) AND an effective treasury
// `treasury + pendingRichesTreasuryDelta(stockpile)` strictly below
// `cheapestRegimentBuildTreasuryCost()` (canonical affordability gate,
// `expand_phase_planner.dart`). All three sub-helpers are canonical in
// `expand_phase_planner.dart`; this composite sits on top so the
// EXPAND-trap rebuild/recovery story is fully co-located.
//
// `colonial_pressure.dart` was deleted in S1 of #2509; the canonical
// helper lives in `expand_phase_planner.dart` and this test pins it
// directly. Cross-arm composition (Arm A short-circuit + Arm B +
// affordability gate) is the focus here; legacy-callsite branch coverage
// belongs to the planner-specific tests under
// `packages/colonizethis_ai/test/planning/`.
//
// Behavioral invariants pinned here (all deterministic):
//
//   1. Arm A short-circuit: when
//      `isBelowQuotaPeaceZeroRegimentsRebuild` returns `true` the composite
//      returns `true` regardless of `treasury` / `stockpile`. A regression
//      that re-ordered the arms or duplicated the affordability check ahead
//      of Arm A would surface here.
//   2. Arm B + affordability: when Arm A fails but Arm B holds the composite
//      returns `true` iff effective treasury is strictly below
//      `cheapestRegimentBuildTreasuryCost()`. Boundary at
//      `effectiveTreasury == cheapest` is `false` (afford one build, exit
//      recovery); one-below is `true` (stay in recovery). This pins the
//      `<` vs `<=` comparison the legacy composite carried.
//   3. Arm B precondition fall-through: when Arm B fails (any of the five
//      `isBelowQuotaPeaceInsufficientRegiments` disqualifiers) the composite
//      returns `false` regardless of treasury / stockpile inputs. Guards
//      against a regression that re-ordered the affordability check before
//      the precondition.
//   4. Effective-treasury composition: cash + riches both contribute via
//      `pendingRichesTreasuryDelta`. A regression that dropped either
//      addend would still pass the legacy zero-treasury cases but would
//      mishandle mixed cash + riches GP states.
//   5. Determinism (Must-have #7): two identical calls inside the same
//      isolate return the same `bool` (no rng, no hidden mutation).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Stockpile _goldStockpile(int qty) => qty <= 0
    ? const Stockpile()
    : Stockpile().applyDelta(CommodityCatalog.gold.id, qty);

void main() {
  group('isBelowQuotaPeaceTreasuryRecovery (canonical)', () {
    test('Arm A short-circuits to true when zero-regiments rebuild holds, '
        'regardless of treasury / stockpile', () {
      // Zero regiments + invadable frontier below quota → Arm A. Even an
      // overflowing treasury must not flip the result; the cargo-recovery
      // directive still surfaces so the orchestrator forces a build pass.
      expect(
        isBelowQuotaPeaceTreasuryRecovery(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 1,
          regimentCount: 0,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
          treasury: cheapestRegimentBuildTreasuryCost() * 10,
          stockpile: _goldStockpile(10),
        ),
        isTrue,
        reason:
            'Arm A (`isBelowQuotaPeaceZeroRegimentsRebuild`) must '
            'short-circuit the composite to true regardless of '
            'treasury / stockpile so the cargo-recovery directive '
            'surfaces in lockstep with the planner force-build arm.',
      );
    });

    test(
      'Arm B + affordability returns true at effectiveTreasury == cheapest - 1',
      () {
        // Strict-`<` boundary, cash-only side. One credit below cheapest
        // still keeps the GP in recovery so the cargo boost can deliver
        // riches.
        final cheapest = cheapestRegimentBuildTreasuryCost();
        expect(
          isBelowQuotaPeaceTreasuryRecovery(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
            regimentCount: 3,
            atWarWithAnyGreatPower: false,
            hasInvadableProvinces: true,
            treasury: cheapest - 1,
            stockpile: const Stockpile(),
          ),
          isTrue,
          reason:
              'Just below the cheapest regiment cost the GP cannot afford '
              'the build; the composite must stay in recovery so the cargo '
              'preference can deliver the missing credit before the next '
              'build pass.',
        );
      },
    );

    test(
      'Arm B + affordability returns false at effectiveTreasury == cheapest',
      () {
        // Strict-`<` boundary (false side). Exactly enough treasury exits
        // recovery so the planner attempts a build this turn.
        final cheapest = cheapestRegimentBuildTreasuryCost();
        expect(
          isBelowQuotaPeaceTreasuryRecovery(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
            regimentCount: 3,
            atWarWithAnyGreatPower: false,
            hasInvadableProvinces: true,
            treasury: cheapest,
            stockpile: const Stockpile(),
          ),
          isFalse,
          reason:
              'At cheapest the GP can already afford a regiment build; the '
              'composite must exit recovery so cargo preference does not '
              'block the EXPAND declare-war / build path.',
        );
      },
    );

    test('effective-treasury composition sums cash and riches', () {
      // Mixed contribution: half from cash, half from gold riches —
      // exactly enough to reach `cheapest`, so the composite returns
      // `false`. Drops one cash credit and the result flips to `true`.
      final cheapest = cheapestRegimentBuildTreasuryCost();
      // Stash 1 gold piece for a deterministic riches delta; cash makes
      // up the rest.
      final stockpile = _goldStockpile(1);
      final richesDelta = pendingRichesTreasuryDelta(stockpile: stockpile);
      // Sanity: gold riches delta must be > 0 so the composition really
      // exercises both addends.
      expect(
        richesDelta,
        greaterThan(0),
        reason:
            'Gold riches stockpile must contribute a positive '
            '`pendingRichesTreasuryDelta` so this test really exercises '
            'the cash + riches addend composition.',
      );
      final cashAtBoundary = cheapest - richesDelta;
      expect(
        isBelowQuotaPeaceTreasuryRecovery(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          regimentCount: 3,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
          treasury: cashAtBoundary,
          stockpile: stockpile,
        ),
        isFalse,
        reason:
            'Cash + riches must sum into effective treasury; a regression '
            'that dropped either addend would still pass the cash-only '
            'or riches-only boundary tests but mishandle this mixed '
            'shape.',
      );
      expect(
        isBelowQuotaPeaceTreasuryRecovery(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          regimentCount: 3,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
          treasury: cashAtBoundary - 1,
          stockpile: stockpile,
        ),
        isTrue,
        reason:
            'One credit below the mixed-composition boundary must keep '
            'the GP in recovery so cargo preference delivers the '
            'remaining riches.',
      );
    });

    test(
      'Arm B precondition fall-through: at-war drops composite to false',
      () {
        // Arm B precondition fails because GP is at war; the composite must
        // short-circuit to `false` regardless of treasury / stockpile so the
        // affordability check is not even evaluated.
        expect(
          isBelowQuotaPeaceTreasuryRecovery(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
            regimentCount: 3,
            atWarWithAnyGreatPower: true,
            hasInvadableProvinces: true,
            treasury: 0,
            stockpile: const Stockpile(),
          ),
          isFalse,
          reason:
              'An at-war GP exits the EXPAND-trap recovery composite via the '
              'Arm B precondition; treasury short-circuiting must not fire '
              'in this branch.',
        );
      },
    );

    test(
      'Arm B precondition fall-through: regimentCount at floor drops to false',
      () {
        // At the at-peace declare-war floor the GP has enough regiments;
        // Arm B precondition fails, composite must return false even at
        // zero treasury / empty stockpile.
        expect(
          isBelowQuotaPeaceTreasuryRecovery(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 1,
            regimentCount: kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
            atWarWithAnyGreatPower: false,
            hasInvadableProvinces: true,
            treasury: 0,
            stockpile: const Stockpile(),
          ),
          isFalse,
          reason:
              'At the at-peace declare-war floor the GP exits the trap; '
              'composite must report false so the planner resumes '
              'declare-war planning instead of cargo-recovery cargo.',
        );
      },
    );

    test('is deterministic across repeated calls (Must-have #7)', () {
      final first = isBelowQuotaPeaceTreasuryRecovery(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
        regimentCount: 3,
        atWarWithAnyGreatPower: false,
        hasInvadableProvinces: true,
        treasury: 0,
        stockpile: const Stockpile(),
      );
      final second = isBelowQuotaPeaceTreasuryRecovery(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
        regimentCount: 3,
        atWarWithAnyGreatPower: false,
        hasInvadableProvinces: true,
        treasury: 0,
        stockpile: const Stockpile(),
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
  });
}
