// Case bodies for `phase_planner_economy_filter_test.dart` (Refs #3997 Phase 8).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show kColonialBuildOrderThresholdWhenOwnedNwUnderPressure;
import 'package:colonizethis_test/test.dart';
import 'phase_planner_economy_filter_support.dart';

void registerPhasePlannerEconomyFilterBuildOrderBlockerCasesTail() {
group('resolvePhaseEconomyColonialBuildOrderThresholdCap', () {
    // Refs #2847 Phase 3 economy build-order threshold cap wiring: the
    // cap magnitude scales with `priorityWeights.newWorldAcquisition`
    // once `newWorldProvincesOwned > 0`; the legacy COLONIAL-only
    // boolean gate is retired from this resolver.
    test('active under COLONIAL-lite when expand frontier slots are set', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandGpOnlyInvadableFrontierActive: true,
      );
      expect(
        resolvePhaseEconomyExpandGpBlockerFocusActive(phasePlan: outcome),
        isTrue,
      );
    });

    test('inactive under EXPAND when gp-only frontier is false', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandGpOnlyInvadableFrontierActive: false,
      );
      expect(
        resolvePhaseEconomyExpandGpBlockerFocusActive(phasePlan: outcome),
        isFalse,
      );
    });

    test('inactive under COLONIAL and DEVELOP even when frontier slots set',
        () {
      const populated = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        expandGpOnlyInvadableFrontierActive: true,
        expandPrimaryInvadableGpBlockerFactionId: 'gp2',
      );
      expect(
        resolvePhaseEconomyExpandGpBlockerFocusActive(phasePlan: populated),
        isFalse,
      );
      expect(
        resolvePhaseEconomyExpandGpBlockerFocusActive(
          phasePlan: const PhasePlanOutcome(
            phase: ObserverGoalPhase.develop,
            expandGpOnlyInvadableFrontierActive: true,
            expandPrimaryInvadableGpBlockerFactionId: 'gp2',
          ),
        ),
        isFalse,
      );
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandGpOnlyInvadableFrontierActive: true,
      );
      expect(
        resolvePhaseEconomyExpandGpBlockerFocusActive(phasePlan: outcome),
        resolvePhaseEconomyExpandGpBlockerFocusActive(phasePlan: outcome),
      );
    });
  });

group('expandPrimaryInvadableGpBlockerFromPhasePlan', () {
    test('returns blocker id when focus active', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandGpOnlyInvadableFrontierActive: true,
        expandPrimaryInvadableGpBlockerFactionId: 'gp2',
      );
      expect(
        expandPrimaryInvadableGpBlockerFromPhasePlan(phasePlan: outcome),
        'gp2',
      );
    });

    test('returns null when focus inactive', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandGpOnlyInvadableFrontierActive: false,
        expandPrimaryInvadableGpBlockerFactionId: 'gp2',
      );
      expect(
        expandPrimaryInvadableGpBlockerFromPhasePlan(phasePlan: outcome),
        isNull,
      );
    });

    test('returns null under COLONIAL even when slots populated', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        expandGpOnlyInvadableFrontierActive: true,
        expandPrimaryInvadableGpBlockerFactionId: 'gp2',
      );
      expect(
        expandPrimaryInvadableGpBlockerFromPhasePlan(phasePlan: outcome),
        isNull,
      );
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandGpOnlyInvadableFrontierActive: true,
        expandPrimaryInvadableGpBlockerFactionId: 'gp3',
      );
      expect(
        expandPrimaryInvadableGpBlockerFromPhasePlan(phasePlan: outcome),
        expandPrimaryInvadableGpBlockerFromPhasePlan(phasePlan: outcome),
      );
    });
  });
}
