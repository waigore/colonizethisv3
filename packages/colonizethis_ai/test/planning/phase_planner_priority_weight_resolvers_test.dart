// Unit tests for the Phase 2 weight-resolver scaffolding (Refs #2847)
// across `phase_planner_conquest_filter.dart`,
// `phase_planner_goal_filter.dart`,
// `phase_planner_economy_filter.dart`, and
// `phase_planner_diplomacy_filter.dart`.
//
// Spec contract (`SPEC/ai/phase-planner-architecture.md` § Soft-phase
// priority weights § Phase 2 weight resolvers):
//
//   "Each resolver reads only `phasePlan.priorityWeights` (or its
//    `PhasePriorityWeights` parameter) and never inspects sibling
//    `PhasePlanOutcome` slots. Identical `PhasePlanOutcome` (or
//    `PhasePriorityWeights`) inputs always yield identical `double`
//    results in `[0.0, 1.0]` (Refs #2509 Must-have #7)."
//
// These tests pin:
//
//   1. Field-equal contract: each weight resolver returns exactly the
//      named `PhasePriorityWeights` field for the active dispatch (no
//      clamping, no transformation, no off-by-one between the
//      `oldWorldConquest` / `newWorldAcquisition` /
//      `oldWorldCivilian` / `newWorldCivilian` fields).
//   2. Phase-independence: the resolvers are projections of
//      `priorityWeights`, not of `outcome.phase`. The same weight
//      profile returns the same `double` regardless of which
//      `ObserverGoalPhase` slot it ships on.
//   3. Sibling-slot independence: populating COLONIAL / EXPAND
//      slots on the `PhasePlanOutcome` (acquisition target, military
//      plan, peace targets, civilian work orders, ...) does not
//      affect any weight resolver result.
//   4. Determinism: identical inputs yield identical results across
//      repeated calls (Refs #2509 Must-have #7).
//   5. Field exclusivity: each resolver returns its named field
//      *only*, demonstrated by sweeping a `PhasePriorityWeights`
//      input that pins each of the four fields to a unique value and
//      asserting the per-resolver-returned `double` matches the
//      single expected field.
//
// The Phase 2 weight resolvers ship side-by-side with the legacy
// boolean structural-suppression resolvers (`resolvePhaseConquest
// SuppressNwInvasionScoring`, ...). The booleans remain the production
// source of truth in this slice — no production scoring site consumes
// the weight resolvers yet. Phase 3 orchestrator wiring (Refs #2847)
// will migrate scoring sites one at a time without further filter-module
// churn; these tests guard the resolver contract so any consumer
// migration can rely on a stable `double` projection of
// `priorityWeights`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show ExpandEconomyPlan, ExpandMilitaryPlan;
import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_diplomacy_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_goal_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_naval_filter.dart'
    show resolvePhaseNavalColonialPressureWeight;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Unique per-field values so a field-mix-up regression (e.g. a
// resolver that mistakenly returns `oldWorldCivilian` instead of
// `oldWorldConquest`) produces a hard test failure rather than
// silently matching the curve default.
const PhasePriorityWeights _unique = PhasePriorityWeights(
  oldWorldConquest: 0.11,
  newWorldAcquisition: 0.22,
  oldWorldCivilian: 0.33,
  newWorldCivilian: 0.44,
);

const PhasePriorityWeights _alt = PhasePriorityWeights(
  oldWorldConquest: 0.91,
  newWorldAcquisition: 0.82,
  oldWorldCivilian: 0.73,
  newWorldCivilian: 0.64,
);

// Non-default content for every full-COLONIAL slot used by the
// "sibling-slot independence" guards. The weight resolvers must
// read only `priorityWeights`, so populated COLONIAL slots must not
// change any returned `double`.
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

const ExpandEconomyPlan _expandEconomyPopulated = ExpandEconomyPlan(
  forceCheapestRegimentBuild: true,
  boostTreasuryRecoveryCargo: true,
);

const ExpandMilitaryPlan _expandMilitaryPopulated = ExpandMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['oldWorld|m1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['minor1'],
);

PhasePlanOutcome _outcomeWithWeights({
  required ObserverGoalPhase phase,
  required PhasePriorityWeights weights,
  bool populateSiblingSlots = false,
}) {
  if (!populateSiblingSlots) {
    return PhasePlanOutcome(phase: phase, priorityWeights: weights);
  }
  return PhasePlanOutcome(
    phase: phase,
    expandDeclareWarTargetFactionId: 'gp2',
    expandPeaceTargetFactionIdsSorted: const <String>['gp3', 'gp4'],
    expandEconomyPlan: _expandEconomyPopulated,
    expandMilitaryPlan: _expandMilitaryPopulated,
    expandGpOnlyInvadableFrontierActive: true,
    expandPrimaryInvadableGpBlockerFactionId: 'gp2',
    colonialLiteOverturesSorted: const <String>['tribe1'],
    colonialAcquisitionTarget: _colonialAcquisitionPopulated,
    colonialPeaceTargetFactionIdsSorted: const <String>['gp5'],
    colonialMilitaryPlan: _colonialMilitaryPopulated,
    colonialNavalPlan: _colonialNavalPopulated,
    colonialCivilianWorkOrders: _colonialCivilianPopulated,
    developPeaceTargetFactionIdsSorted: const <String>['gp6'],
    developCivilianWorkOrders: _colonialCivilianPopulated,
    priorityWeights: weights,
  );
}

void main() {
  group('Phase 2 weight resolvers — conquest filter', () {
    group('resolvePhaseConquestNwInvasionWeight', () {
      test('returns priorityWeights.newWorldAcquisition exactly', () {
        for (final phase in ObserverGoalPhase.values) {
          expect(
            resolvePhaseConquestNwInvasionWeight(
              phasePlan: _outcomeWithWeights(
                phase: phase,
                weights: _unique,
              ),
            ),
            equals(_unique.newWorldAcquisition),
            reason:
                'phase $phase: resolver must project '
                'newWorldAcquisition (${_unique.newWorldAcquisition})',
          );
        }
      });

      test('phase-independent — same weights, different phases', () {
        final results = <double>{
          for (final phase in ObserverGoalPhase.values)
            resolvePhaseConquestNwInvasionWeight(
              phasePlan: _outcomeWithWeights(phase: phase, weights: _alt),
            ),
        };
        expect(
          results,
          <double>{_alt.newWorldAcquisition},
          reason:
              'weight resolver must depend only on priorityWeights, '
              'not outcome.phase',
        );
      });

      test('sibling-slot independence — populated COLONIAL / EXPAND '
          'slots do not affect result', () {
        for (final phase in ObserverGoalPhase.values) {
          final populated = resolvePhaseConquestNwInvasionWeight(
            phasePlan: _outcomeWithWeights(
              phase: phase,
              weights: _unique,
              populateSiblingSlots: true,
            ),
          );
          final empty = resolvePhaseConquestNwInvasionWeight(
            phasePlan: _outcomeWithWeights(phase: phase, weights: _unique),
          );
          expect(populated, equals(empty));
          expect(populated, equals(_unique.newWorldAcquisition));
        }
      });

      test('deterministic across three calls (Must-have #7)', () {
        final outcome = _outcomeWithWeights(
          phase: ObserverGoalPhase.expand,
          weights: _alt,
        );
        final a = resolvePhaseConquestNwInvasionWeight(phasePlan: outcome);
        final b = resolvePhaseConquestNwInvasionWeight(phasePlan: outcome);
        final c = resolvePhaseConquestNwInvasionWeight(phasePlan: outcome);
        expect(a, b);
        expect(b, c);
      });
    });

    group('resolvePhaseConquestOldWorldInvasionWeight', () {
      test('returns priorityWeights.oldWorldConquest exactly', () {
        for (final phase in ObserverGoalPhase.values) {
          expect(
            resolvePhaseConquestOldWorldInvasionWeight(
              phasePlan: _outcomeWithWeights(
                phase: phase,
                weights: _unique,
              ),
            ),
            equals(_unique.oldWorldConquest),
          );
        }
      });

      test('not confused with NW acquisition field', () {
        // _unique.oldWorldConquest (0.11) != _unique.newWorldAcquisition (0.22).
        final outcome = _outcomeWithWeights(
          phase: ObserverGoalPhase.colonial,
          weights: _unique,
        );
        expect(
          resolvePhaseConquestOldWorldInvasionWeight(phasePlan: outcome),
          isNot(equals(_unique.newWorldAcquisition)),
        );
      });

      test('deterministic across three calls (Must-have #7)', () {
        final outcome = _outcomeWithWeights(
          phase: ObserverGoalPhase.colonial,
          weights: _unique,
        );
        final a = resolvePhaseConquestOldWorldInvasionWeight(
          phasePlan: outcome,
        );
        final b = resolvePhaseConquestOldWorldInvasionWeight(
          phasePlan: outcome,
        );
        final c = resolvePhaseConquestOldWorldInvasionWeight(
          phasePlan: outcome,
        );
        expect(a, b);
        expect(b, c);
      });
    });

    group('resolvePhaseConquestColonialPressureWeight', () {
      test('returns priorityWeights.newWorldAcquisition exactly', () {
        for (final phase in ObserverGoalPhase.values) {
          expect(
            resolvePhaseConquestColonialPressureWeight(
              phasePlan: _outcomeWithWeights(
                phase: phase,
                weights: _unique,
              ),
            ),
            equals(_unique.newWorldAcquisition),
          );
        }
      });

      test('matches resolvePhaseConquestNwInvasionWeight on the same '
          'PhasePlanOutcome (both project newWorldAcquisition)', () {
        for (final phase in ObserverGoalPhase.values) {
          final outcome = _outcomeWithWeights(phase: phase, weights: _alt);
          expect(
            resolvePhaseConquestColonialPressureWeight(phasePlan: outcome),
            equals(
              resolvePhaseConquestNwInvasionWeight(phasePlan: outcome),
            ),
          );
        }
      });
    });
  });

  group('Phase 3 weight resolvers — naval filter', () {
    group('resolvePhaseNavalColonialPressureWeight', () {
      test('returns priorityWeights.newWorldAcquisition exactly', () {
        for (final phase in ObserverGoalPhase.values) {
          expect(
            resolvePhaseNavalColonialPressureWeight(
              phasePlan: _outcomeWithWeights(
                phase: phase,
                weights: _unique,
              ),
            ),
            equals(_unique.newWorldAcquisition),
            reason:
                'phase $phase: resolver must project '
                'newWorldAcquisition (${_unique.newWorldAcquisition})',
          );
        }
      });

      test('phase-independent — same weights, different phases', () {
        final results = <double>{
          for (final phase in ObserverGoalPhase.values)
            resolvePhaseNavalColonialPressureWeight(
              phasePlan: _outcomeWithWeights(phase: phase, weights: _alt),
            ),
        };
        expect(
          results,
          <double>{_alt.newWorldAcquisition},
          reason:
              'naval colonial-pressure weight resolver must depend only '
              'on priorityWeights, not outcome.phase',
        );
      });

      test('sibling-slot independence — populated COLONIAL / EXPAND '
          'slots do not affect result', () {
        for (final phase in ObserverGoalPhase.values) {
          final populated = resolvePhaseNavalColonialPressureWeight(
            phasePlan: _outcomeWithWeights(
              phase: phase,
              weights: _unique,
              populateSiblingSlots: true,
            ),
          );
          final empty = resolvePhaseNavalColonialPressureWeight(
            phasePlan: _outcomeWithWeights(phase: phase, weights: _unique),
          );
          expect(populated, equals(empty));
          expect(populated, equals(_unique.newWorldAcquisition));
        }
      });

      test('matches resolvePhaseConquestNwInvasionWeight on the same '
          'PhasePlanOutcome (both project newWorldAcquisition)', () {
        for (final phase in ObserverGoalPhase.values) {
          final outcome = _outcomeWithWeights(phase: phase, weights: _alt);
          expect(
            resolvePhaseNavalColonialPressureWeight(phasePlan: outcome),
            equals(
              resolvePhaseConquestNwInvasionWeight(phasePlan: outcome),
            ),
            reason:
                'naval / conquest NW projection must agree on the same '
                'newWorldAcquisition field',
          );
        }
      });

      test('deterministic across three calls (Must-have #7)', () {
        final outcome = _outcomeWithWeights(
          phase: ObserverGoalPhase.expand,
          weights: _alt,
        );
        final a = resolvePhaseNavalColonialPressureWeight(phasePlan: outcome);
        final b = resolvePhaseNavalColonialPressureWeight(phasePlan: outcome);
        final c = resolvePhaseNavalColonialPressureWeight(phasePlan: outcome);
        expect(a, b);
        expect(b, c);
      });
    });
  });

  group('Phase 2 weight resolvers — goal filter', () {
    group('resolvePhaseGoalColonialPressureWeight', () {
      test('returns weights.newWorldAcquisition exactly', () {
        expect(
          resolvePhaseGoalColonialPressureWeight(_unique),
          equals(_unique.newWorldAcquisition),
        );
        expect(
          resolvePhaseGoalColonialPressureWeight(_alt),
          equals(_alt.newWorldAcquisition),
        );
      });

      test('uses earlySprintDefault canonical value', () {
        expect(
          resolvePhaseGoalColonialPressureWeight(
            PhasePriorityWeights.earlySprintDefault,
          ),
          equals(0.05),
        );
      });

      test('deterministic across three calls (Must-have #7)', () {
        final a = resolvePhaseGoalColonialPressureWeight(_unique);
        final b = resolvePhaseGoalColonialPressureWeight(_unique);
        final c = resolvePhaseGoalColonialPressureWeight(_unique);
        expect(a, b);
        expect(b, c);
      });
    });

    group('resolvePhaseGoalOldWorldConquestWeight', () {
      test('returns weights.oldWorldConquest exactly', () {
        expect(
          resolvePhaseGoalOldWorldConquestWeight(_unique),
          equals(_unique.oldWorldConquest),
        );
        expect(
          resolvePhaseGoalOldWorldConquestWeight(_alt),
          equals(_alt.oldWorldConquest),
        );
      });

      test('uses earlySprintDefault canonical value', () {
        expect(
          resolvePhaseGoalOldWorldConquestWeight(
            PhasePriorityWeights.earlySprintDefault,
          ),
          equals(0.95),
        );
      });

      test('not confused with the NW acquisition pair', () {
        expect(
          resolvePhaseGoalOldWorldConquestWeight(_unique),
          isNot(equals(_unique.newWorldAcquisition)),
        );
        expect(
          resolvePhaseGoalOldWorldConquestWeight(_unique),
          isNot(
            equals(resolvePhaseGoalColonialPressureWeight(_unique)),
          ),
        );
      });
    });
  });

  group('Phase 2 weight resolvers — economy filter', () {
    group('resolvePhaseEconomyColonialPressureWeight', () {
      test('returns priorityWeights.newWorldAcquisition exactly', () {
        for (final phase in ObserverGoalPhase.values) {
          expect(
            resolvePhaseEconomyColonialPressureWeight(
              phasePlan: _outcomeWithWeights(
                phase: phase,
                weights: _unique,
              ),
            ),
            equals(_unique.newWorldAcquisition),
          );
        }
      });

      test('sibling-slot independence', () {
        for (final phase in ObserverGoalPhase.values) {
          final populated = resolvePhaseEconomyColonialPressureWeight(
            phasePlan: _outcomeWithWeights(
              phase: phase,
              weights: _unique,
              populateSiblingSlots: true,
            ),
          );
          expect(populated, equals(_unique.newWorldAcquisition));
        }
      });
    });

    group('resolvePhaseEconomyOldWorldCivilianWeight', () {
      test('returns priorityWeights.oldWorldCivilian exactly', () {
        for (final phase in ObserverGoalPhase.values) {
          expect(
            resolvePhaseEconomyOldWorldCivilianWeight(
              phasePlan: _outcomeWithWeights(
                phase: phase,
                weights: _unique,
              ),
            ),
            equals(_unique.oldWorldCivilian),
          );
        }
      });

      test('not confused with oldWorldConquest', () {
        final outcome = _outcomeWithWeights(
          phase: ObserverGoalPhase.expand,
          weights: _unique,
        );
        expect(
          resolvePhaseEconomyOldWorldCivilianWeight(phasePlan: outcome),
          isNot(equals(_unique.oldWorldConquest)),
        );
      });

      test('deterministic across three calls (Must-have #7)', () {
        final outcome = _outcomeWithWeights(
          phase: ObserverGoalPhase.develop,
          weights: _alt,
        );
        final a = resolvePhaseEconomyOldWorldCivilianWeight(
          phasePlan: outcome,
        );
        final b = resolvePhaseEconomyOldWorldCivilianWeight(
          phasePlan: outcome,
        );
        final c = resolvePhaseEconomyOldWorldCivilianWeight(
          phasePlan: outcome,
        );
        expect(a, b);
        expect(b, c);
      });
    });

    group('resolvePhaseEconomyNewWorldCivilianWeight', () {
      test('returns priorityWeights.newWorldCivilian exactly', () {
        for (final phase in ObserverGoalPhase.values) {
          expect(
            resolvePhaseEconomyNewWorldCivilianWeight(
              phasePlan: _outcomeWithWeights(
                phase: phase,
                weights: _unique,
              ),
            ),
            equals(_unique.newWorldCivilian),
          );
        }
      });

      test('not confused with newWorldAcquisition', () {
        // _unique.newWorldCivilian (0.44) != _unique.newWorldAcquisition (0.22).
        final outcome = _outcomeWithWeights(
          phase: ObserverGoalPhase.colonial,
          weights: _unique,
        );
        expect(
          resolvePhaseEconomyNewWorldCivilianWeight(phasePlan: outcome),
          isNot(equals(_unique.newWorldAcquisition)),
        );
      });
    });
  });

  group('Phase 2 weight resolvers — diplomacy filter', () {
    group('resolvePhaseDiplomacyDeclareWarColonialPressureWeight', () {
      test('returns priorityWeights.newWorldAcquisition exactly', () {
        for (final phase in ObserverGoalPhase.values) {
          expect(
            resolvePhaseDiplomacyDeclareWarColonialPressureWeight(
              phasePlan: _outcomeWithWeights(
                phase: phase,
                weights: _unique,
              ),
            ),
            equals(_unique.newWorldAcquisition),
          );
        }
      });

      test('phase-independent — projects only priorityWeights', () {
        final results = <double>{
          for (final phase in ObserverGoalPhase.values)
            resolvePhaseDiplomacyDeclareWarColonialPressureWeight(
              phasePlan: _outcomeWithWeights(phase: phase, weights: _alt),
            ),
        };
        expect(results, <double>{_alt.newWorldAcquisition});
      });
    });

    group('resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight', () {
      test('returns priorityWeights.oldWorldConquest exactly', () {
        for (final phase in ObserverGoalPhase.values) {
          expect(
            resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(
              phasePlan: _outcomeWithWeights(
                phase: phase,
                weights: _unique,
              ),
            ),
            equals(_unique.oldWorldConquest),
          );
        }
      });

      test('not confused with newWorldAcquisition pair', () {
        final outcome = _outcomeWithWeights(
          phase: ObserverGoalPhase.colonial,
          weights: _unique,
        );
        expect(
          resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(
            phasePlan: outcome,
          ),
          isNot(
            equals(
              resolvePhaseDiplomacyDeclareWarColonialPressureWeight(
                phasePlan: outcome,
              ),
            ),
          ),
        );
      });

      test('deterministic across three calls (Must-have #7)', () {
        final outcome = _outcomeWithWeights(
          phase: ObserverGoalPhase.expand,
          weights: _alt,
        );
        final a = resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(
          phasePlan: outcome,
        );
        final b = resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(
          phasePlan: outcome,
        );
        final c = resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(
          phasePlan: outcome,
        );
        expect(a, b);
        expect(b, c);
      });
    });
  });

  group('cross-filter field-exclusivity sweep', () {
    test('every weight resolver projects exactly its named field', () {
      final outcome = _outcomeWithWeights(
        phase: ObserverGoalPhase.colonial,
        weights: _unique,
      );
      // oldWorldConquest projections
      for (final actual in <double>[
        resolvePhaseConquestOldWorldInvasionWeight(phasePlan: outcome),
        resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(
          phasePlan: outcome,
        ),
        resolvePhaseGoalOldWorldConquestWeight(_unique),
      ]) {
        expect(actual, equals(_unique.oldWorldConquest));
      }
      // newWorldAcquisition projections
      for (final actual in <double>[
        resolvePhaseConquestNwInvasionWeight(phasePlan: outcome),
        resolvePhaseConquestColonialPressureWeight(phasePlan: outcome),
        resolvePhaseEconomyColonialPressureWeight(phasePlan: outcome),
        resolvePhaseDiplomacyDeclareWarColonialPressureWeight(
          phasePlan: outcome,
        ),
        resolvePhaseGoalColonialPressureWeight(_unique),
        resolvePhaseNavalColonialPressureWeight(phasePlan: outcome),
      ]) {
        expect(actual, equals(_unique.newWorldAcquisition));
      }
      // oldWorldCivilian projection
      expect(
        resolvePhaseEconomyOldWorldCivilianWeight(phasePlan: outcome),
        equals(_unique.oldWorldCivilian),
      );
      // newWorldCivilian projection
      expect(
        resolvePhaseEconomyNewWorldCivilianWeight(phasePlan: outcome),
        equals(_unique.newWorldCivilian),
      );
    });

    test('the four fields are read disjointly — flipping a single field '
        'changes only the resolvers that project it', () {
      const baseline = PhasePriorityWeights(
        oldWorldConquest: 0.10,
        newWorldAcquisition: 0.20,
        oldWorldCivilian: 0.30,
        newWorldCivilian: 0.40,
      );
      const owConquestBumped = PhasePriorityWeights(
        oldWorldConquest: 0.99,
        newWorldAcquisition: 0.20,
        oldWorldCivilian: 0.30,
        newWorldCivilian: 0.40,
      );

      final base = _outcomeWithWeights(
        phase: ObserverGoalPhase.expand,
        weights: baseline,
      );
      final bumped = _outcomeWithWeights(
        phase: ObserverGoalPhase.expand,
        weights: owConquestBumped,
      );

      // OW conquest resolvers must change.
      expect(
        resolvePhaseConquestOldWorldInvasionWeight(phasePlan: bumped),
        isNot(
          equals(
            resolvePhaseConquestOldWorldInvasionWeight(phasePlan: base),
          ),
        ),
      );
      expect(
        resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(
          phasePlan: bumped,
        ),
        isNot(
          equals(
            resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(
              phasePlan: base,
            ),
          ),
        ),
      );
      // Other resolvers must NOT change.
      expect(
        resolvePhaseConquestNwInvasionWeight(phasePlan: bumped),
        equals(resolvePhaseConquestNwInvasionWeight(phasePlan: base)),
      );
      expect(
        resolvePhaseEconomyOldWorldCivilianWeight(phasePlan: bumped),
        equals(
          resolvePhaseEconomyOldWorldCivilianWeight(phasePlan: base),
        ),
      );
      expect(
        resolvePhaseEconomyNewWorldCivilianWeight(phasePlan: bumped),
        equals(
          resolvePhaseEconomyNewWorldCivilianWeight(phasePlan: base),
        ),
      );
      expect(
        resolvePhaseEconomyColonialPressureWeight(phasePlan: bumped),
        equals(
          resolvePhaseEconomyColonialPressureWeight(phasePlan: base),
        ),
      );
    });
  });
}
