// Case bodies: phase-suppression resolvers (Refs #4239 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_diplomacy_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_diplomacy_filter_fixtures.dart';

void registerPhasePlannerDiplomacyFilterPhaseSuppressionCases() {
  group('resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive', () {
    test('active only under DEVELOP', () {
      expect(
        resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive(
          phasePlan: const PhasePlanOutcome(phase: ObserverGoalPhase.develop),
        ),
        isTrue,
        reason:
            'DEVELOP suppresses every declare-war candidate via '
            '_declareWarSuppressedDevelopPhaseScore (issue #2509 § DEVELOP '
            'suppressions "No `declareWar` on anyone").',
      );
    });

    test('suppressed under EXPAND, COLONIAL-lite, and COLONIAL', () {
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonialLite,
        ObserverGoalPhase.colonial,
      ]) {
        expect(
          resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive(
            phasePlan: PhasePlanOutcome(phase: phase),
          ),
          isFalse,
          reason:
              '$phase must not engage DEVELOP-wide declare-war suppression. '
              'EXPAND / COLONIAL-lite NW collapse via the sibling '
              'expandColonial / colonialLite resolvers; COLONIAL allows '
              'declare-war candidates to score normally so the '
              '`colonialPressure && ownsInvadableNw` exception in '
              '_declareWarSuppressedWarConcentrationScore can preserve '
              'tribe-target scoring.',
        );
      }
    });

    test('reads only outcome.phase — populated DEVELOP slots under EXPAND / '
        'COLONIAL-lite / COLONIAL do not flip the resolver to true', () {
      const developPeacePopulated = <String>['gp2', 'gp3'];
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonialLite,
        ObserverGoalPhase.colonial,
      ]) {
        final outcome = PhasePlanOutcome(
          phase: phase,
          developPeaceTargetFactionIdsSorted: developPeacePopulated,
          developCivilianWorkOrders: phasePlannerDiplomacyFilterDevelopCivilianPopulated,
        );
        expect(
          resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive(
            phasePlan: outcome,
          ),
          isFalse,
          reason:
              '$phase: DEVELOP slots populated must not flip the '
              'resolver — only outcome.phase decides.',
        );
      }
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      for (final phase in ObserverGoalPhase.values) {
        final outcome = PhasePlanOutcome(phase: phase);
        final a = resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive(
          phasePlan: outcome,
        );
        final b = resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive(
          phasePlan: outcome,
        );
        final c = resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive(
          phasePlan: outcome,
        );
        expect(a, b, reason: '$phase: two-call determinism');
        expect(b, c, reason: '$phase: three-call determinism');
      }
    });
  });

  group('resolvePhaseDiplomacyDeclareWarColonialLiteSuppressionActive', () {
    test('active only under COLONIAL-lite', () {
      expect(
        resolvePhaseDiplomacyDeclareWarColonialLiteSuppressionActive(
          phasePlan: const PhasePlanOutcome(
            phase: ObserverGoalPhase.colonialLite,
          ),
        ),
        isTrue,
        reason:
            'COLONIAL-lite collapses NW declare-war candidates (tribe / '
            'NW invadable / colonial-adjacent owners) via '
            '_declareWarSuppressedColonialLiteScore — issue #2509 § '
            'COLONIAL-lite scope summary "Suppressed: NW declareWar".',
      );
    });

    test('suppressed under EXPAND, COLONIAL, and DEVELOP', () {
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonial,
        ObserverGoalPhase.develop,
      ]) {
        expect(
          resolvePhaseDiplomacyDeclareWarColonialLiteSuppressionActive(
            phasePlan: PhasePlanOutcome(phase: phase),
          ),
          isFalse,
          reason:
              '$phase must not engage COLONIAL-lite NW-collapse '
              'suppression. EXPAND collapses NW via the sibling EXPAND '
              'resolver; COLONIAL allows NW declare-war as the '
              'SPEC-authorized acquisition route; DEVELOP collapses every '
              'declare-war candidate via the sibling DEVELOP resolver '
              'before this branch runs.',
        );
      }
    });

    test('reads only outcome.phase — populated COLONIAL-lite slots under '
        'EXPAND / COLONIAL / DEVELOP do not flip the resolver to true', () {
      const colonialLiteOverturesPopulated = <String>['tribe1', 'tribe2'];
      const colonialLiteNavalPopulated = ColonialLiteNavalPlan(
        priorityNwProvinceIdsSorted: <String>['newWorld|tribe1_a'],
        priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
      );
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonial,
        ObserverGoalPhase.develop,
      ]) {
        final outcome = PhasePlanOutcome(
          phase: phase,
          colonialLiteOverturesSorted: colonialLiteOverturesPopulated,
          colonialLiteNavalPlan: colonialLiteNavalPopulated,
        );
        expect(
          resolvePhaseDiplomacyDeclareWarColonialLiteSuppressionActive(
            phasePlan: outcome,
          ),
          isFalse,
          reason:
              '$phase: COLONIAL-lite slots populated must not flip the '
              'resolver — only outcome.phase decides.',
        );
      }
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      for (final phase in ObserverGoalPhase.values) {
        final outcome = PhasePlanOutcome(phase: phase);
        final a = resolvePhaseDiplomacyDeclareWarColonialLiteSuppressionActive(
          phasePlan: outcome,
        );
        final b = resolvePhaseDiplomacyDeclareWarColonialLiteSuppressionActive(
          phasePlan: outcome,
        );
        final c = resolvePhaseDiplomacyDeclareWarColonialLiteSuppressionActive(
          phasePlan: outcome,
        );
        expect(a, b, reason: '$phase: two-call determinism');
        expect(b, c, reason: '$phase: three-call determinism');
      }
    });
  });

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
