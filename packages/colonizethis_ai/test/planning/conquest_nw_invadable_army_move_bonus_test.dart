// Unit tests for `conquestNwInvadableArmyMoveBonus` — the Phase 2 conquest
// NW-invasion sign migration helper (Refs #2847).
//
// Contract under test (SPEC/ai/phase-planner-architecture.md § Phase 3
// consumer wiring — conquest NW invasion, "NW-pursuit sign under resource-need
// overrides"):
//
//   - A below-quota GP whose dispatched `newWorldAcquisition` weight is on the
//     ordinary curve plateau (no override; <= 0.20 at OW <= 9) pays a
//     **negative** NW-invadable bonus so the early-game OW sprint dominates —
//     preserving the gp1/gp2 +6 OW baseline.
//   - A below-quota GP whose weight reaches the resource-need override
//     threshold (`kPhasePriorityNwInvadablePursuitWeightThreshold` = the 0.30
//     zero-regiment floor; the 0.60 treasury-recovery floor also trips it)
//     pays a **positive** bonus so the army is biased toward the NW income
//     foothold the override exists to unlock (requirement clarification #3).
//   - At or above the OW conquest quota the bonus is always positive (the
//     early-sprint penalty applies only below quota).

import 'package:colonizethis_ai/src/planning/conquest_planner.dart';
import 'package:colonizethis_ai/src/planning/phase_priority_weights.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('conquestNwInvadableArmyMoveBonus', () {
    test(
      'below quota with treasury-recovery override floor (0.60) is positive',
      () {
        final bonus = conquestNwInvadableArmyMoveBonus(
          belowQuota: true,
          nwInvasionWeight: kPhasePriorityNwTreasuryRecoveryFloor,
        );
        expect(
          bonus,
          kConquestArmyMoveNwInvadableBonus *
              kPhasePriorityNwTreasuryRecoveryFloor,
        );
        expect(
          bonus,
          greaterThan(0),
          reason:
              'The resource-need override must bias a treasury-locked '
              'below-quota GP toward NW invasion (requirement #3), not repel '
              'it — the prior negation inverted the override.',
        );
      },
    );

    test(
      'below quota with zero-regiment override floor (0.30) is positive',
      () {
        final bonus = conquestNwInvadableArmyMoveBonus(
          belowQuota: true,
          nwInvasionWeight: kPhasePriorityNwZeroRegimentFloor,
        );
        expect(
          bonus,
          kConquestArmyMoveNwInvadableBonus * kPhasePriorityNwZeroRegimentFloor,
        );
        expect(bonus, greaterThan(0));
      },
    );

    test(
      'below quota at the pursuit threshold boundary is positive (>=)',
      () {
        final bonus = conquestNwInvadableArmyMoveBonus(
          belowQuota: true,
          nwInvasionWeight: kPhasePriorityNwInvadablePursuitWeightThreshold,
        );
        expect(bonus, greaterThan(0));
      },
    );

    test(
      'below quota on the OW=9 curve plateau (0.20) is negative',
      () {
        final bonus = conquestNwInvadableArmyMoveBonus(
          belowQuota: true,
          nwInvasionWeight: 0.20,
        );
        expect(bonus, -kConquestArmyMoveNwInvadableBonus * 0.20);
        expect(
          bonus,
          lessThan(0),
          reason:
              'A healthy below-quota GP (no override; weight <= 0.20) must '
              'keep the early-sprint OW push so the gp1/gp2 +6 OW baseline is '
              'preserved.',
        );
      },
    );

    test(
      'below quota on the early-sprint curve floor (0.05) is negative',
      () {
        final bonus = conquestNwInvadableArmyMoveBonus(
          belowQuota: true,
          nwInvasionWeight: 0.05,
        );
        expect(bonus, -kConquestArmyMoveNwInvadableBonus * 0.05);
        expect(bonus, lessThan(0));
      },
    );

    test(
      'just below the pursuit threshold is still negative below quota',
      () {
        final bonus = conquestNwInvadableArmyMoveBonus(
          belowQuota: true,
          nwInvasionWeight:
              kPhasePriorityNwInvadablePursuitWeightThreshold - 0.01,
        );
        expect(bonus, lessThan(0));
      },
    );

    test(
      'at or above quota is positive even at the early-sprint curve floor',
      () {
        final bonus = conquestNwInvadableArmyMoveBonus(
          belowQuota: false,
          nwInvasionWeight: 0.40,
        );
        expect(bonus, kConquestArmyMoveNwInvadableBonus * 0.40);
        expect(bonus, greaterThan(0));
      },
    );

    test('is deterministic for identical inputs (Refs #2509 Must-have #7)', () {
      final first = conquestNwInvadableArmyMoveBonus(
        belowQuota: true,
        nwInvasionWeight: kPhasePriorityNwTreasuryRecoveryFloor,
      );
      final second = conquestNwInvadableArmyMoveBonus(
        belowQuota: true,
        nwInvasionWeight: kPhasePriorityNwTreasuryRecoveryFloor,
      );
      expect(second, first);
    });
  });
}
