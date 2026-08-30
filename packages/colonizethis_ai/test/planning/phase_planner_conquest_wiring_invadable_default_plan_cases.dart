// Default-plan case bodies for `phase_planner_conquest_wiring_invadable_cases.dart`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_test/test.dart';
import 'phase_planner_conquest_wiring_support.dart';

void registerPhasePlannerConquestWiringInvadableDefaultPlanCases() {
  group('resolvePhaseConquestInvadable', () {
    test(
      'COLONIAL non-default colonialMilitaryPlan restricts to NW destinations',
      () {
        const outcome = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonial,
          colonialMilitaryPlan: kConquestWiringColonialNwOnly,
        );
        final resolution = resolvePhaseConquestInvadable(phasePlan: outcome);
        expect(resolution.skipConquestPass, isFalse);
        expect(resolution.useLegacyInvadable, isFalse);
        expect(
          resolution.phasePlanInvadableSorted,
          kConquestWiringColonialNwOnly.priorityDestinationProvinceIdsSorted,
        );
      },
    );

    test('DEVELOP skips the conquest pass', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      final resolution = resolvePhaseConquestInvadable(phasePlan: outcome);
      expect(resolution.skipConquestPass, isTrue);
    });

    test(
      'EXPAND default plan falls back with soft NW weight (not structurally suppressed)',
      () {
        const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
        final resolution = resolvePhaseConquestInvadable(phasePlan: outcome);
        expect(resolution.skipConquestPass, isFalse);
        expect(resolution.useLegacyInvadable, isTrue);
        expect(
          resolvePhaseConquestNwInvasionWeight(phasePlan: outcome),
          PhasePriorityWeights.earlySprintDefault.newWorldAcquisition,
        );
        expect(resolution.structuralNewWorldSuppressed, isFalse);
      },
    );

    test(
      'COLONIAL-lite default plan falls back with soft NW weight (not structurally suppressed)',
      () {
        const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonialLite);
        final resolution = resolvePhaseConquestInvadable(phasePlan: outcome);
        expect(resolution.useLegacyInvadable, isTrue);
        expect(
          resolvePhaseConquestNwInvasionWeight(phasePlan: outcome),
          PhasePriorityWeights.earlySprintDefault.newWorldAcquisition,
        );
        expect(resolution.structuralNewWorldSuppressed, isFalse);
      },
    );

    test(
      'COLONIAL default plan falls back without structural NW suppression',
      () {
        const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
        final resolution = resolvePhaseConquestInvadable(phasePlan: outcome);
        expect(resolution.useLegacyInvadable, isTrue);
        expect(resolution.structuralNewWorldSuppressed, isFalse);
      },
    );

    test('deterministic for identical inputs (Must-have #7)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandMilitaryPlan: kConquestWiringExpandOwOnly,
      );
      final a = resolvePhaseConquestInvadable(phasePlan: outcome);
      final b = resolvePhaseConquestInvadable(phasePlan: outcome);
      expect(a.skipConquestPass, b.skipConquestPass);
      expect(a.useLegacyInvadable, b.useLegacyInvadable);
      expect(a.structuralNewWorldSuppressed, b.structuralNewWorldSuppressed);
      expect(a.phasePlanInvadableSorted, b.phasePlanInvadableSorted);
    });
  });
}
