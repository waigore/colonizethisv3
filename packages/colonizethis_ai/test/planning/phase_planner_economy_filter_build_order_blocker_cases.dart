// Case bodies for `phase_planner_economy_filter_test.dart` (Refs #3997 Phase 8).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show kColonialBuildOrderThresholdWhenOwnedNwUnderPressure;
import 'package:colonizethis_test/test.dart';
import 'phase_planner_economy_filter_support.dart';
import 'phase_planner_economy_filter_build_order_blocker_cases_tail_cases.dart';

void registerPhasePlannerEconomyFilterBuildOrderBlockerCases() {
group('resolvePhaseEconomyColonialBuildOrderThresholdCap', () {
    // Refs #2847 Phase 3 economy build-order threshold cap wiring: the
    // cap magnitude scales with `priorityWeights.newWorldAcquisition`
    // once `newWorldProvincesOwned > 0`; the legacy COLONIAL-only
    // boolean gate is retired from this resolver.
    test('returns kColonialBuildOrderThresholdWhenOwnedNwUnderPressure under '
        'COLONIAL with newWorldProvincesOwned > 0 and NW weight 1.0', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        priorityWeights: PhasePriorityWeights(
          oldWorldConquest: 0.1,
          newWorldAcquisition: 1.0,
          oldWorldCivilian: 0.1,
          newWorldCivilian: 0.9,
        ),
      );
      const colonial = ColonialSummary(newWorldProvincesOwned: 1);
      expect(
        resolvePhaseEconomyColonialBuildOrderThresholdCap(
          phasePlan: outcome,
          colonial: colonial,
        ),
        kColonialBuildOrderThresholdWhenOwnedNwUnderPressure,
      );
    });

    test('returns null under COLONIAL with newWorldProvincesOwned == 0', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      const colonial = ColonialSummary();
      expect(
        resolvePhaseEconomyColonialBuildOrderThresholdCap(
          phasePlan: outcome,
          colonial: colonial,
        ),
        isNull,
        reason:
            'Legacy colonialBuildOrderThresholdCap returns null when '
            'newWorldProvincesOwned == 0; the phase-derived resolver '
            'must preserve that.',
      );
    });

    test('returns null when NW weight is zero even with NW provinces owned',
        () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        priorityWeights: PhasePriorityWeights(
          oldWorldConquest: 0.95,
          newWorldAcquisition: 0.0,
          oldWorldCivilian: 0.90,
          newWorldCivilian: 0.10,
        ),
      );
      expect(
        resolvePhaseEconomyColonialBuildOrderThresholdCap(
          phasePlan: outcome,
          colonial: const ColonialSummary(newWorldProvincesOwned: 3),
        ),
        isNull,
      );
    });

    test('returns scaled cap under EXPAND when NW owned and weight > 0', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        resolvePhaseEconomyColonialBuildOrderThresholdCap(
          phasePlan: outcome,
          colonial: const ColonialSummary(newWorldProvincesOwned: 2),
        ),
        1,
        reason:
            'earlySprintDefault newWorldAcquisition (0.05) -> round(15*0.05)',
      );
    });

    test('returns null under COLONIAL-lite and DEVELOP regardless of NW '
        'ownership (structural safeguard)', () {
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.colonialLite,
        ObserverGoalPhase.develop,
      ]) {
        for (final nwOwned in <int>[0, 1, 5]) {
          final outcome = PhasePlanOutcome(phase: phase);
          expect(
            resolvePhaseEconomyColonialBuildOrderThresholdCap(
              phasePlan: outcome,
              colonial: ColonialSummary(newWorldProvincesOwned: nwOwned),
            ),
            isNull,
            reason:
                '$phase with newWorldProvincesOwned=$nwOwned: colonial '
                'build cap stays structurally suppressed.',
          );
        }
      }
    });

    test('reads phase + priorityWeights + colonial.newWorldProvincesOwned — '
        'sibling slots on PhasePlanOutcome do not flip the resolver', () {
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.colonialLite,
        ObserverGoalPhase.develop,
      ]) {
        final outcome = PhasePlanOutcome(
          phase: phase,
          colonialAcquisitionTarget: kEconomyFilterColonialAcquisitionPopulated,
          colonialPeaceTargetFactionIdsSorted: const <String>['gp2'],
          colonialMilitaryPlan: kEconomyFilterColonialMilitaryPopulated,
          colonialNavalPlan: kEconomyFilterColonialNavalPopulated,
          colonialCivilianWorkOrders: kEconomyFilterColonialCivilianPopulated,
        );
        expect(
          resolvePhaseEconomyColonialBuildOrderThresholdCap(
            phasePlan: outcome,
            colonial: const ColonialSummary(newWorldProvincesOwned: 3),
          ),
          isNull,
          reason:
              '$phase: populated COLONIAL slots must not bypass the '
              'structural COLONIAL-lite / DEVELOP suppression.',
        );
      }
      final expandOutcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        colonialAcquisitionTarget: kEconomyFilterColonialAcquisitionPopulated,
      );
      expect(
        resolvePhaseEconomyColonialBuildOrderThresholdCap(
          phasePlan: expandOutcome,
          colonial: const ColonialSummary(newWorldProvincesOwned: 3),
        ),
        1,
        reason:
            'EXPAND routes off priorityWeights.newWorldAcquisition, not '
            'populated COLONIAL slots.',
      );
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      // The resolver is pure on `(outcome.phase,
      // colonial.newWorldProvincesOwned)` so identical inputs must
      // yield identical `int?` resolutions across any number of
      // invocations. Iterates every phase x {0, 1, 5} NW-ownership
      // combination so a future regression that introduced
      // non-determinism (random tiebreak, mutable shared state, ...)
      // would be caught.
      for (final phase in ObserverGoalPhase.values) {
        for (final nwOwned in <int>[0, 1, 5]) {
          final outcome = PhasePlanOutcome(phase: phase);
          final colonial = ColonialSummary(
            newWorldProvincesOwned: nwOwned,
          );
          final a = resolvePhaseEconomyColonialBuildOrderThresholdCap(
            phasePlan: outcome,
            colonial: colonial,
          );
          final b = resolvePhaseEconomyColonialBuildOrderThresholdCap(
            phasePlan: outcome,
            colonial: colonial,
          );
          final c = resolvePhaseEconomyColonialBuildOrderThresholdCap(
            phasePlan: outcome,
            colonial: colonial,
          );
          expect(
            a,
            b,
            reason: '$phase nwOwned=$nwOwned: two-call determinism',
          );
          expect(
            b,
            c,
            reason: '$phase nwOwned=$nwOwned: three-call determinism',
          );
        }
      }
    });

    test('returns the under-pressure constant, never the retired '
        'no-acquisition fallback value (18)', () {
      // Pins the structural invariant that the legacy no-acquisition
      // fallback arm is unreachable through the phase-derived path.
      // The retired fallback constant (since removed from
      // `colonizethis_data`; Refs #2509) carried the value 18 — the
      // under-pressure cap (`kColonialBuildOrderThresholdWhenOwnedNwUnderPressure`)
      // is 15, so a future regression that wired a mistakenly higher
      // numeric cap would flip this pin to red even if the
      // COLONIAL-only suppression matrix stayed intact. Exhaustive
      // over the reachable NW-ownership range to also pin the
      // constant against any phase-keyed tier blend.
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        priorityWeights: PhasePriorityWeights(
          oldWorldConquest: 0.1,
          newWorldAcquisition: 1.0,
          oldWorldCivilian: 0.1,
          newWorldCivilian: 0.9,
        ),
      );
      for (final nwOwned in <int>[1, 2, 5, 20]) {
        final colonial = ColonialSummary(newWorldProvincesOwned: nwOwned);
        final cap = resolvePhaseEconomyColonialBuildOrderThresholdCap(
          phasePlan: outcome,
          colonial: colonial,
        );
        expect(
          cap,
          kColonialBuildOrderThresholdWhenOwnedNwUnderPressure,
          reason:
              'nwOwned=$nwOwned: COLONIAL at full NW weight must return '
              'the under-pressure cap.',
        );
        expect(
          cap,
          isNot(18),
          reason:
              'nwOwned=$nwOwned: the retired no-acquisition fallback '
              'value (18) is unreachable through the phase-derived '
              'path because COLONIAL phase entry requires '
              'hasColonialAcquisitionTargets.',
        );
      }
    });
  });

group('resolvePhaseEconomyExpandGpBlockerFocusActive', () {
    test('active under EXPAND when expand frontier slots are set', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandGpOnlyInvadableFrontierActive: true,
      );
      expect(
        resolvePhaseEconomyExpandGpBlockerFocusActive(phasePlan: outcome),
        isTrue,
      );
    });
  });

  registerPhasePlannerEconomyFilterBuildOrderBlockerCasesTail();
}
