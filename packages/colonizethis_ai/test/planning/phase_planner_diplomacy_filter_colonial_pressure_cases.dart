// Case bodies: colonial-pressure resolver (Refs #4239 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_diplomacy_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_diplomacy_filter_fixtures.dart';

void registerPhasePlannerDiplomacyFilterColonialPressureCases() {
  group('resolvePhaseDiplomacyDeclareWarColonialPressureActive', () {
    test('active only under COLONIAL', () {
      expect(
        resolvePhaseDiplomacyDeclareWarColonialPressureActive(
          phasePlan: const PhasePlanOutcome(phase: ObserverGoalPhase.colonial),
        ),
        isTrue,
        reason:
            'COLONIAL phase entry is already gated by '
            'hasColonialAcquisitionTargets at observerGoalPhaseFor; the '
            'declare-war scoring colonialPressure slot is structurally on '
            'so the `colonialPressure && ownsInvadableNw` exception in '
            '_declareWarSuppressedWarConcentrationScore can keep tribe '
            'targets scorable under stalled-OW + behind-victory-pace '
            'preconditions (issue #2509 § COLONIAL planColonialAcquisition '
            'step 3 "declareWar + invade").',
      );
    });

    test('suppressed under EXPAND, COLONIAL-lite, and DEVELOP', () {
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonialLite,
        ObserverGoalPhase.develop,
      ]) {
        expect(
          resolvePhaseDiplomacyDeclareWarColonialPressureActive(
            phasePlan: PhasePlanOutcome(phase: phase),
          ),
          isFalse,
          reason:
              '$phase must not engage the declare-war colonial pressure '
              'slot. COLONIAL-lite suppression is the SPEC-aligned '
              'correctness pin: issue #2509 § COLONIAL-lite scope summary '
              'forbids NW `declareWar` outright. EXPAND collapses NW '
              'colonial targets via _declareWarSuppressedExpandColonialScore, '
              'and DEVELOP collapses every declare-war candidate via '
              '_declareWarSuppressedDevelopPhaseScore — phase-derived '
              '`false` keeps the structural contract explicit.',
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
          colonialAcquisitionTarget: phasePlannerDiplomacyFilterColonialAcquisitionPopulated,
          colonialPeaceTargetFactionIdsSorted: const <String>['gp2'],
          colonialMilitaryPlan: phasePlannerDiplomacyFilterColonialMilitaryPopulated,
          colonialNavalPlan: phasePlannerDiplomacyFilterColonialNavalPopulated,
          colonialCivilianWorkOrders: phasePlannerDiplomacyFilterColonialCivilianPopulated,
        );
        expect(
          resolvePhaseDiplomacyDeclareWarColonialPressureActive(
            phasePlan: outcome,
          ),
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
        final a = resolvePhaseDiplomacyDeclareWarColonialPressureActive(
          phasePlan: outcome,
        );
        final b = resolvePhaseDiplomacyDeclareWarColonialPressureActive(
          phasePlan: outcome,
        );
        final c = resolvePhaseDiplomacyDeclareWarColonialPressureActive(
          phasePlan: outcome,
        );
        expect(a, b, reason: '$phase: two-call determinism');
        expect(b, c, reason: '$phase: three-call determinism');
      }
    });

    test('parity with resolvePhaseEconomyColonialPressureActive and '
        'resolvePhaseConquestColonialPressureActive across all phases — '
        'declare-war, economy, and conquest mirror each other to keep '
        'COLONIAL the sole NW-pressure phase across every domain', () {
      // Architectural parity pin: if a future slice diverges any of the
      // three NW-pressure resolvers (for example by enabling colonial
      // declare-war pressure under COLONIAL-lite while keeping economy
      // and conquest suppression), the orchestrator's NW-pressure
      // semantics would become inconsistent across passes. This test
      // forces all three resolvers to share the same "COLONIAL-only"
      // contract until a deliberate, SPEC-authorized split lands.
      for (final phase in ObserverGoalPhase.values) {
        final outcome = PhasePlanOutcome(phase: phase);
        final declareWar =
            resolvePhaseDiplomacyDeclareWarColonialPressureActive(
              phasePlan: outcome,
            );
        final economy = resolvePhaseEconomyColonialPressureActive(
          phasePlan: outcome,
        );
        final conquest = resolvePhaseConquestColonialPressureActive(
          phasePlan: outcome,
        );
        expect(
          declareWar,
          economy,
          reason:
              '$phase: declare-war and economy NW-pressure resolvers must '
              'agree (both gate on phase == colonial).',
        );
        expect(
          declareWar,
          conquest,
          reason:
              '$phase: declare-war and conquest NW-pressure resolvers must '
              'agree (both gate on phase == colonial).',
        );
      }
    });
  });
}
