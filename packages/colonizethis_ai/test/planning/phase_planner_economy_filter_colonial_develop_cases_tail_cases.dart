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

void registerPhasePlannerEconomyFilterColonialDevelopCasesTail() {
group('resolvePhaseEconomyColonialPressureActive', () {
    test('deterministic across repeated calls (Must-have #7)', () {
      // The resolver is pure on `outcome.phase` so identical inputs
      // must yield identical booleans across any number of
      // invocations.
      for (final phase in ObserverGoalPhase.values) {
        final outcome = PhasePlanOutcome(phase: phase);
        final a = resolvePhaseEconomyDevelopActive(phasePlan: outcome);
        final b = resolvePhaseEconomyDevelopActive(phasePlan: outcome);
        final c = resolvePhaseEconomyDevelopActive(phasePlan: outcome);
        expect(a, b, reason: '$phase: two-call determinism');
        expect(b, c, reason: '$phase: three-call determinism');
      }
    });

    test(
      'disjoint from resolvePhaseEconomyColonialPressureActive — at most '
      'one of the two economy resolvers returns true for any given phase',
      () {
        // The two economy resolvers gate disjoint orchestrator
        // decisions (DEVELOP improvement cap vs COLONIAL acquisition
        // pressure boost). A future regression that fired both
        // simultaneously would mean the same player turn is treated as
        // both DEVELOP and COLONIAL, contradicting the phase-planner
        // single-goal architecture (issue #2509 § Single-goal
        // replacement "Each phase planner is a pure function … no
        // cross-phase score merging").
        for (final phase in ObserverGoalPhase.values) {
          final outcome = PhasePlanOutcome(phase: phase);
          final develop = resolvePhaseEconomyDevelopActive(phasePlan: outcome);
          final colonial = resolvePhaseEconomyColonialPressureActive(
            phasePlan: outcome,
          );
          expect(
            develop && colonial,
            isFalse,
            reason:
                '$phase: develop and colonial-pressure economy '
                'resolvers must never both return true (phases are '
                'mutually exclusive per outcome.phase).',
          );
        }
      },
    );
  });

group('resolvePhaseEconomyExpandQuotaPressureActive', () {
    test('active only under EXPAND and COLONIAL-lite', () {
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonialLite,
      ]) {
        expect(
          resolvePhaseEconomyExpandQuotaPressureActive(
            phasePlan: PhasePlanOutcome(phase: phase),
          ),
          isTrue,
          reason:
              '$phase: below-quota OW build-pass arms (stalled threshold, '
              'GP-blocker focus, quota peace rebuild) are structurally on.',
        );
      }
    });

    test('suppressed under COLONIAL and DEVELOP', () {
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.colonial,
        ObserverGoalPhase.develop,
      ]) {
        expect(
          resolvePhaseEconomyExpandQuotaPressureActive(
            phasePlan: PhasePlanOutcome(phase: phase),
          ),
          isFalse,
          reason:
              '$phase: OW quota pressure build arms must not leak from '
              'EXPAND / COLONIAL-lite once the GP is at or above quota '
              'or in DEVELOP improvement push.',
        );
      }
    });

    test('field-equal to resolvePhaseConquestExtraPassesActive across all '
        'phases', () {
      for (final phase in ObserverGoalPhase.values) {
        final outcome = PhasePlanOutcome(phase: phase);
        expect(
          resolvePhaseEconomyExpandQuotaPressureActive(phasePlan: outcome),
          resolvePhaseConquestExtraPassesActive(phasePlan: outcome),
          reason:
              '$phase: economy and conquest below-quota resolvers must '
              'agree (both gate on phase ∈ {EXPAND, COLONIAL-lite}).',
        );
      }
    });

    test('reads only outcome.phase — populated EXPAND slots under COLONIAL / '
        'DEVELOP do not flip the resolver to true', () {
      const expandEconomyPopulated = ExpandEconomyPlan(
        forceCheapestRegimentBuild: true,
        boostTreasuryRecoveryCargo: true,
      );
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.colonial,
        ObserverGoalPhase.develop,
      ]) {
        final outcome = PhasePlanOutcome(
          phase: phase,
          expandEconomyPlan: expandEconomyPopulated,
          expandDeclareWarTargetFactionId: 'minor1',
        );
        expect(
          resolvePhaseEconomyExpandQuotaPressureActive(phasePlan: outcome),
          isFalse,
          reason:
              '$phase: non-default expandEconomyPlan must not enable '
              'below-quota OW build routing outside EXPAND / COLONIAL-lite.',
        );
      }
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      for (final phase in ObserverGoalPhase.values) {
        final outcome = PhasePlanOutcome(phase: phase);
        final a = resolvePhaseEconomyExpandQuotaPressureActive(
          phasePlan: outcome,
        );
        final b = resolvePhaseEconomyExpandQuotaPressureActive(
          phasePlan: outcome,
        );
        expect(a, b, reason: '$phase: two-call determinism');
      }
    });
  });
}
