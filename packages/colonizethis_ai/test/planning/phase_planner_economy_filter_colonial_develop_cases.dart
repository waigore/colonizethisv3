// Case bodies for `phase_planner_economy_filter_test.dart` (Refs #3997 Phase 8).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show ExpandEconomyPlan;
import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_logic/ai_api.dart' show kWorkTargetBuildImprovement;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'phase_planner_economy_filter_support.dart';
import 'phase_planner_economy_filter_colonial_develop_cases_tail_cases.dart';

void registerPhasePlannerEconomyFilterColonialDevelopCases() {
group('resolvePhaseEconomyColonialPressureActive', () {
    test('active only under COLONIAL', () {
      expect(
        resolvePhaseEconomyColonialPressureActive(
          phasePlan: const PhasePlanOutcome(phase: ObserverGoalPhase.colonial),
        ),
        isTrue,
        reason:
            'COLONIAL phase entry is already gated by '
            'hasColonialAcquisitionTargets at observerGoalPhaseFor; the '
            'economy boost (lower civilian threshold, force '
            'runFullAiCivilianWork, BuildPickInput.colonialPressure cargo '
            'bonus) is structurally on for the full NW push.',
      );
    });

    test('suppressed under EXPAND, COLONIAL-lite, and DEVELOP', () {
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonialLite,
        ObserverGoalPhase.develop,
      ]) {
        expect(
          resolvePhaseEconomyColonialPressureActive(
            phasePlan: PhasePlanOutcome(phase: phase),
          ),
          isFalse,
          reason:
              '$phase must not engage the colonial economy boost. '
              'COLONIAL-lite suppression is the SPEC-aligned correctness '
              'pin: issue #2509 § COLONIAL-lite forbids weakening the OW '
              'push by biasing economy/build toward NW cargo while still '
              'below the OW quota.',
        );
      }
    });

    test('reads only outcome.phase — populated COLONIAL slots under EXPAND / '
        'COLONIAL-lite / DEVELOP do not flip the resolver to true', () {
      // The PhasePlanOutcome dispatcher already enforces that COLONIAL
      // slots are unreachable under EXPAND / COLONIAL-lite / DEVELOP
      // (see SPEC § Suppression matrix). This guard pins the resolver
      // against a hypothetical regression that started leaking COLONIAL
      // slot content into other phases — even with every COLONIAL slot
      // populated, the resolver still routes off `outcome.phase` only.
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
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
          resolvePhaseEconomyColonialPressureActive(phasePlan: outcome),
          isFalse,
          reason:
              '$phase: COLONIAL slots populated must not flip the '
              'resolver — only outcome.phase decides.',
        );
      }
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      // The resolver is pure on `outcome.phase` so identical inputs must
      // yield identical booleans across any number of invocations.
      for (final phase in ObserverGoalPhase.values) {
        final outcome = PhasePlanOutcome(phase: phase);
        final a = resolvePhaseEconomyColonialPressureActive(phasePlan: outcome);
        final b = resolvePhaseEconomyColonialPressureActive(phasePlan: outcome);
        final c = resolvePhaseEconomyColonialPressureActive(phasePlan: outcome);
        expect(a, b, reason: '$phase: two-call determinism');
        expect(b, c, reason: '$phase: three-call determinism');
      }
    });

    test('parity with resolvePhaseConquestColonialPressureActive across all '
        'phases — economy and conquest mirror each other to keep COLONIAL '
        'the sole NW-pressure phase', () {
      // Architectural parity pin: if a future slice diverges the
      // economy and conquest resolvers (for example by enabling
      // colonial economy under COLONIAL-lite while keeping conquest
      // suppression), the orchestrator's NW-pressure semantics would
      // become inconsistent across passes. This test forces both
      // resolvers to share the same "COLONIAL-only" contract until a
      // deliberate, SPEC-authorized split lands.
      for (final phase in ObserverGoalPhase.values) {
        final outcome = PhasePlanOutcome(phase: phase);
        final economy = resolvePhaseEconomyColonialPressureActive(
          phasePlan: outcome,
        );
        final conquest = resolvePhaseConquestColonialPressureActive(
          phasePlan: outcome,
        );
        expect(
          economy,
          conquest,
          reason:
              '$phase: economy and conquest NW-pressure resolvers must '
              'agree (both gate on phase == colonial).',
        );
      }
    });
  });

group('resolvePhaseEconomyDevelopActive', () {
    test('active only under DEVELOP', () {
      expect(
        resolvePhaseEconomyDevelopActive(
          phasePlan: const PhasePlanOutcome(phase: ObserverGoalPhase.develop),
        ),
        isTrue,
        reason:
            'DEVELOP phase entry is already gated by '
            '`!hasColonialAcquisitionTargets && OW >= quota` at '
            'observerGoalPhaseFor; the orchestrator economy pass must '
            'lower the civilian threshold to '
            'kDevelopCivilianWorkThresholdCap and force '
            'runFullAiCivilianWork only under DEVELOP, matching the '
            'legacy isObserverDevelopPhase compute.',
      );
    });

    test('suppressed under EXPAND, COLONIAL-lite, and COLONIAL', () {
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonialLite,
        ObserverGoalPhase.colonial,
      ]) {
        expect(
          resolvePhaseEconomyDevelopActive(
            phasePlan: PhasePlanOutcome(phase: phase),
          ),
          isFalse,
          reason:
              '$phase must not engage the DEVELOP economy gate. '
              'The DEVELOP improvement cap and forced '
              'runFullAiCivilianWork are structurally inactive '
              'outside DEVELOP — EXPAND and COLONIAL-lite keep the '
              'OW-focused civilian threshold; COLONIAL drives '
              'civilian work via colonialCivilianWorkOrders and the '
              'COLONIAL build cap (issue #2509 § Observer goal '
              'phases).',
        );
      }
    });

    test('reads only outcome.phase — populated DEVELOP / COLONIAL / EXPAND '
        'slots under non-DEVELOP phases do not flip the resolver to true', () {
      // The PhasePlanOutcome dispatcher already enforces structural
      // phase separation: DEVELOP slots are only populated under
      // DEVELOP, COLONIAL slots only under COLONIAL, EXPAND slots only
      // under EXPAND / COLONIAL-lite. This guard pins the resolver
      // against a hypothetical regression that started leaking slot
      // content into phases other than the one that produced it —
      // even with every sibling slot populated, the resolver must
      // route off `outcome.phase` only.
      const developCivilianWorkOrders = <WorkOrder>[
        WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: 'oldWorld|portugal_a|0|0',
        ),
      ];
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonialLite,
        ObserverGoalPhase.colonial,
      ]) {
        final outcome = PhasePlanOutcome(
          phase: phase,
          colonialAcquisitionTarget: kEconomyFilterColonialAcquisitionPopulated,
          colonialPeaceTargetFactionIdsSorted: const <String>['gp2'],
          colonialMilitaryPlan: kEconomyFilterColonialMilitaryPopulated,
          colonialNavalPlan: kEconomyFilterColonialNavalPopulated,
          colonialCivilianWorkOrders: kEconomyFilterColonialCivilianPopulated,
          developPeaceTargetFactionIdsSorted: const <String>['gp3'],
          developCivilianWorkOrders: developCivilianWorkOrders,
        );
        expect(
          resolvePhaseEconomyDevelopActive(phasePlan: outcome),
          isFalse,
          reason:
              '$phase: populated DEVELOP / COLONIAL slots must not '
              'flip the resolver — only outcome.phase decides.',
        );
      }
    });
  });

  registerPhasePlannerEconomyFilterColonialDevelopCasesTail();
}
