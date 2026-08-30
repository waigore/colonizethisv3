// EXPAND-colonial phase-suppression resolver cases (Refs #4669 Slice D).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_diplomacy_filter.dart';
import 'package:colonizethis_test/test.dart';

void registerPhasePlannerDiplomacyFilterExpandColonialSuppressionCases() {
  group('resolvePhaseDiplomacyDeclareWarExpandColonialSuppressionActive', () {
    test('active only under EXPAND', () {
      expect(
        resolvePhaseDiplomacyDeclareWarExpandColonialSuppressionActive(
          phasePlan: const PhasePlanOutcome(phase: ObserverGoalPhase.expand),
        ),
        isTrue,
        reason:
            'EXPAND collapses NW declare-war candidates (tribe / NW '
            'invadable / colonial-adjacent owners) via '
            '_declareWarSuppressedExpandColonialScore — issue #2509 § '
            'EXPAND NW suppression "structural suppression — never imports '
            'or calls colonial modules".',
      );
    });

    test('suppressed under COLONIAL-lite, COLONIAL, and DEVELOP', () {
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.colonialLite,
        ObserverGoalPhase.colonial,
        ObserverGoalPhase.develop,
      ]) {
        expect(
          resolvePhaseDiplomacyDeclareWarExpandColonialSuppressionActive(
            phasePlan: PhasePlanOutcome(phase: phase),
          ),
          isFalse,
          reason:
              '$phase must not engage EXPAND NW-collapse suppression. '
              'COLONIAL-lite NW collapse runs via the sibling '
              'colonialLite resolver; COLONIAL allows NW declare-war as '
              'the SPEC-authorized acquisition route; DEVELOP collapses '
              'every declare-war candidate via the sibling DEVELOP '
              'resolver before this branch runs.',
        );
      }
    });

    test('reads only outcome.phase — populated EXPAND slots under '
        'COLONIAL-lite / COLONIAL / DEVELOP do not flip the resolver to '
        'true', () {
      const expandEconomyPopulated = ExpandEconomyPlan(
        forceCheapestRegimentBuild: true,
        boostTreasuryRecoveryCargo: true,
      );
      const expandMilitaryPopulated = ExpandMilitaryPlan(
        priorityDestinationProvinceIdsSorted: <String>['oldWorld|gp1_a'],
        priorityTargetOwnerFactionIdsSorted: <String>['minor1'],
      );
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.colonialLite,
        ObserverGoalPhase.colonial,
        ObserverGoalPhase.develop,
      ]) {
        final outcome = PhasePlanOutcome(
          phase: phase,
          expandDeclareWarTargetFactionId: 'minor1',
          expandPeaceTargetFactionIdsSorted: const <String>['gp2'],
          expandEconomyPlan: expandEconomyPopulated,
          expandMilitaryPlan: expandMilitaryPopulated,
        );
        expect(
          resolvePhaseDiplomacyDeclareWarExpandColonialSuppressionActive(
            phasePlan: outcome,
          ),
          isFalse,
          reason:
              '$phase: EXPAND slots populated must not flip the '
              'resolver — only outcome.phase decides.',
        );
      }
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      for (final phase in ObserverGoalPhase.values) {
        final outcome = PhasePlanOutcome(phase: phase);
        final a =
            resolvePhaseDiplomacyDeclareWarExpandColonialSuppressionActive(
              phasePlan: outcome,
            );
        final b =
            resolvePhaseDiplomacyDeclareWarExpandColonialSuppressionActive(
              phasePlan: outcome,
            );
        final c =
            resolvePhaseDiplomacyDeclareWarExpandColonialSuppressionActive(
              phasePlan: outcome,
            );
        expect(a, b, reason: '$phase: two-call determinism');
        expect(b, c, reason: '$phase: three-call determinism');
      }
    });
  });
}
