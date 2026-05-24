// Unit tests for `phase_planner_diplomacy_filter.dart`
// (Refs #2509 S5 — companion to `phase_planner_economy_filter_test.dart`,
// `phase_planner_conquest_wiring_test.dart` for the conquest-side
// `resolvePhaseConquestColonialPressureActive` pin).
//
// Pins the structural contract of
// `resolvePhaseDiplomacyDeclareWarColonialPressureActive`:
//
//   - Returns `true` *only* under `ObserverGoalPhase.colonial`.
//   - Returns `false` under `ObserverGoalPhase.expand`,
//     `ObserverGoalPhase.colonialLite`, and `ObserverGoalPhase.develop`.
//   - Reads only `outcome.phase` — sibling slots (`colonialAcquisitionTarget`,
//     `colonialMilitaryPlan`, `colonialNavalPlan`, `colonialCivilianWorkOrders`,
//     `colonialPeaceTargetFactionIdsSorted`, ...) have no effect.
//   - Pure and deterministic across repeated calls (Refs #2509 Must-have #7).
//   - Field-equal with the economy and conquest sister resolvers across every
//     `ObserverGoalPhase` value — the three resolvers form a uniform
//     COLONIAL-only structural matrix until a deliberate SPEC-authorized
//     split forces them apart.
//
// COLONIAL-lite suppression is the *correctness* pin: a tuning regression that
// fans out the legacy `hasColonialAcquisitionTargets && !stalledFocus &&
// !shouldSuppressNW` semantic into the new resolver (returning `true` under
// COLONIAL-lite when not stalled) would re-enable NW `declareWar` candidate
// scoring exceptions in `_declareWarSuppressedWarConcentrationScore` even when
// the safeguard explicitly forbids NW `declareWar`, contradicting issue #2509
// § COLONIAL-lite scope summary "Suppressed: NW declareWar, NW invasion army
// moves, purchase_land in NW". A negative-control test pins COLONIAL-lite at
// `isFalse` even when every COLONIAL slot in `PhasePlanOutcome` is populated.
//
// This file also pins the three sibling phase-suppression resolvers added by
// the declare-war scoring phase-suppression slice:
//
//   - `resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive` — DEVELOP-only.
//   - `resolvePhaseDiplomacyDeclareWarColonialLiteSuppressionActive` —
//     COLONIAL-lite-only.
//   - `resolvePhaseDiplomacyDeclareWarExpandColonialSuppressionActive` —
//     EXPAND-only.
//
// The three resolvers form a *partition* matrix: exactly one returns `true`
// for any given `outcome.phase`, and all three return `false` under COLONIAL
// (declare-war candidates score normally under COLONIAL — the
// `colonialPressure && ownsInvadableNw` exception in
// `_declareWarSuppressedWarConcentrationScore` handles tribe-target
// preservation there). The partition pin guards against a regression that
// allows two resolvers to return `true` simultaneously, which would fold
// suppression branches into each other and either over- or under-collapse
// candidates.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_diplomacy_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Non-default content for every full-COLONIAL slot used by the
// "structural exclusion ignores sibling slots" guard. The resolver must
// read only `outcome.phase`, so populated COLONIAL slots under EXPAND /
// COLONIAL-lite / DEVELOP must still resolve to `false`.
const ColonialAcquisitionTarget _colonialAcquisitionPopulated =
    ColonialAcquisitionTarget(
      targetFactionId: 'tribe1',
      method: AcquisitionMethod.declareWar,
    );

const ColonialMilitaryPlan _colonialMilitaryPopulated = ColonialMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
);

const ColonialNavalPlan _colonialNavalPopulated = ColonialNavalPlan(
  priorityInvasionTransportProvinceIdsSorted: <String>['newWorld|tribe1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
);

const List<WorkOrder> _colonialCivilianPopulated = <WorkOrder>[
  WorkOrder(
    unitId: 'm1',
    target: 'purchase_land',
    targetTileKey: 'newWorld|tribe1_a|0|0',
  ),
];

// Mirrors the COLONIAL "structural exclusion" guard above for the
// DEVELOP-side population pin used by
// `resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive` tests. Hoisted
// to a top-level const so the WorkOrder string literal lives in a field
// declaration rather than an executable literal context (Refs
// `tool/check_work_target_constants.dart` `_isExecutableLiteral`).
const List<WorkOrder> _developCivilianPopulated = <WorkOrder>[
  WorkOrder(
    unitId: 'b1',
    target: 'build_improvement',
    targetTileKey: 'oldWorld|gp1_a|0|0',
  ),
];

void main() {
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
          colonialAcquisitionTarget: _colonialAcquisitionPopulated,
          colonialPeaceTargetFactionIdsSorted: const <String>['gp2'],
          colonialMilitaryPlan: _colonialMilitaryPopulated,
          colonialNavalPlan: _colonialNavalPopulated,
          colonialCivilianWorkOrders: _colonialCivilianPopulated,
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
          developCivilianWorkOrders: _developCivilianPopulated,
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

  group('phase-suppression resolver partition', () {
    test('exactly one of the three phase-suppression resolvers returns true '
        'for EXPAND, COLONIAL-lite, and DEVELOP', () {
      // Partition pin: the three sibling resolvers
      // (`...DevelopSuppressionActive`,
      // `...ColonialLiteSuppressionActive`,
      // `...ExpandColonialSuppressionActive`) divide the four
      // ObserverGoalPhase values into a strict partition. EXPAND,
      // COLONIAL-lite, and DEVELOP each activate exactly one resolver;
      // COLONIAL activates none of the three (declare-war candidates
      // score normally under COLONIAL — the colonialPressure exception
      // in _declareWarSuppressedWarConcentrationScore handles
      // tribe-target preservation there). A regression where two
      // resolvers fire simultaneously would fold suppression branches
      // into each other and over-collapse candidates; a regression
      // where none fires under EXPAND/COLONIAL-lite/DEVELOP would
      // re-enable scoring branches the SPEC explicitly suppresses.
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonialLite,
        ObserverGoalPhase.develop,
      ]) {
        final outcome = PhasePlanOutcome(phase: phase);
        final develop = resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive(
          phasePlan: outcome,
        );
        final colonialLite =
            resolvePhaseDiplomacyDeclareWarColonialLiteSuppressionActive(
              phasePlan: outcome,
            );
        final expand =
            resolvePhaseDiplomacyDeclareWarExpandColonialSuppressionActive(
              phasePlan: outcome,
            );
        final activeCount = [
          develop,
          colonialLite,
          expand,
        ].where((b) => b).length;
        expect(
          activeCount,
          1,
          reason:
              '$phase: partition contract requires exactly one of the '
              'three phase-suppression resolvers to return true '
              '(develop=$develop, colonialLite=$colonialLite, '
              'expandColonial=$expand).',
        );
      }
    });

    test(
      'all three phase-suppression resolvers return false under COLONIAL',
      () {
        // COLONIAL declare-war candidates score normally — the
        // `colonialPressure && ownsInvadableNw` exception in
        // _declareWarSuppressedWarConcentrationScore handles tribe-target
        // preservation. A regression where any of the three suppression
        // resolvers fires under COLONIAL would prematurely collapse
        // declare-war candidates and break the
        // `planColonialAcquisition` step 3 "declareWar + invade" path.
        const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
        expect(
          resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive(
            phasePlan: outcome,
          ),
          isFalse,
          reason:
              'COLONIAL must not activate the DEVELOP suppression resolver.',
        );
        expect(
          resolvePhaseDiplomacyDeclareWarColonialLiteSuppressionActive(
            phasePlan: outcome,
          ),
          isFalse,
          reason:
              'COLONIAL must not activate the COLONIAL-lite suppression '
              'resolver.',
        );
        expect(
          resolvePhaseDiplomacyDeclareWarExpandColonialSuppressionActive(
            phasePlan: outcome,
          ),
          isFalse,
          reason: 'COLONIAL must not activate the EXPAND suppression resolver.',
        );
      },
    );
  });
}
