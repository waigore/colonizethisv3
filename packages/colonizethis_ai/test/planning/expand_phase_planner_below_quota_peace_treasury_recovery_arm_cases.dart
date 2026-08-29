// Arm A / Arm B affordability pins for `isBelowQuotaPeaceTreasuryRecovery` (Refs #2509 S1; #4669 Slice B).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'expand_phase_planner_below_quota_peace_treasury_recovery_support.dart';

void registerExpandPhasePlannerBelowQuotaPeaceTreasuryRecoveryArmCases() {
  group('isBelowQuotaPeaceTreasuryRecovery (canonical) — arms A/B', () {
    test('Arm A short-circuits to true when zero-regiments rebuild holds, '
        'regardless of treasury / stockpile', () {
      expect(
        isBelowQuotaPeaceTreasuryRecovery(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 1,
          regimentCount: 0,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
          treasury: cheapestRegimentBuildTreasuryCost() * 10,
          stockpile: goldStockpile(10),
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
      final cheapest = cheapestRegimentBuildTreasuryCost();
      final stockpile = goldStockpile(1);
      final richesDelta = pendingRichesTreasuryDelta(stockpile: stockpile);
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
  });
}
