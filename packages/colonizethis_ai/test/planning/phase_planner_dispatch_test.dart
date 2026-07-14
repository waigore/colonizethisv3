// Unit tests for the phase planner dispatcher in
// `packages/colonizethis_ai/lib/src/planning/phase_planner_dispatch.dart`
// (Refs #2509 S5 foundation / S6 phase-planner-architecture sub-spec).
//
// Spec contract (issue #2509 § Design § Single-goal replacement;
// SPEC/ai/phase-planner-architecture.md § Orchestrator dispatch):
//
//   "Each phase dispatches to a self-contained planner module that makes
//    one primary decision per domain. No scores are aggregated across
//    phases."
//
// The dispatcher is the missing wiring between `observerGoalPhaseFor`
// and the four per-phase planner modules. It does not emit orders --
// the orchestrator translates `PhasePlanOutcome` into the legacy
// `runDiplomacyPlanner` / `runConquestArmyMovePlanner` / economy call
// chain in a later S5 slice. These tests pin:
//
//   1. Phase routing: `runPhasePlanners` returns each
//      `ObserverGoalPhase` value when the snapshot matches the
//      condition table (EXPAND below quota; COLONIAL-lite at quota=9
//      and turn>=120 with non-GP NW ownership; COLONIAL at quota with
//      colonial targets; DEVELOP at quota with no colonial targets).
//   2. EXPAND outcome composition: EXPAND-phase fields populate while
//      COLONIAL-lite / COLONIAL / DEVELOP fields stay at default. The
//      declare-war target picked by `planExpandDeclareWar` flows into
//      `planExpandMilitary` so the two plans target the same faction.
//   3. COLONIAL-lite outcome composition: both EXPAND fields and
//      COLONIAL-lite fields populate (OW push continues during the
//      safeguard); full-COLONIAL and DEVELOP slots stay default.
//   4. COLONIAL outcome composition: COLONIAL slots populate; EXPAND
//      / COLONIAL-lite / DEVELOP slots stay default. When acquisition
//      resolves to `declareWar`, the target factionId flows into both
//      `planColonialMilitary` and `planColonialNaval`. When
//      acquisition is `null` (no method reachable), the military /
//      naval pair fall back to their at-war arms with no declared
//      target.
//   5. DEVELOP outcome composition: only DEVELOP fields populate.
//   6. Determinism: identical inputs produce field-equal outcomes
//      (Must-have #7).
//
// Fixture style mirrors the existing per-planner tests
// (`expand_phase_planner_test.dart`, `colonial_phase_planner_test.dart`,
// `develop_phase_planner_test.dart`): minimal `Game` scaffolds tuned
// per scenario, no live AI invocation, no orchestrator wiring. The
// dispatcher is a thin composition layer so the assertions focus on
// the routing matrix rather than re-pinning each planner's internal
// branches.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart'
    show phasePlanFullColonialOutputsActive;
import 'package:colonizethis_ai/src/planning/develop_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';
import 'ai_planner_fixtures.dart';

const String _tribe1 = kColonialPhaseTribe1;
const String _minor1 = kColonialPhaseMinor1;

void main() {
  // Sanity-pin the regiment-cost helper so a regression in
  // `RegimentEconomyCatalog.byId` that bumped every cost above the
  // EXPAND fixture's default treasury (9999) would surface here rather
  // than silently failing later assertions about `planExpandDeclareWar`
  // not returning `null` from the treasury gate.
  setUpAll(() {
    final cheapest = cheapestRegimentBuildCost();
    expect(cheapest, lessThanOrEqualTo(9999), reason: 'Treasury gate fixture');
  });

  group('runPhasePlanners phase routing', () {
    test('EXPAND when OW below quota', () {
      final outcome = runPhasePlanners(
        game: buildPhasePlannerDispatchExpandGame(),
        snapshot: buildPhasePlannerDispatchExpandSnapshot(),
      );
      expect(outcome.phase, ObserverGoalPhase.expand);
    });

    test('COLONIAL-lite when turn>=120, OW=9, NW non-GP-owned visible', () {
      final outcome = runPhasePlanners(
        game: buildPhasePlannerDispatchColonialLiteGame(),
        snapshot: buildPhasePlannerDispatchColonialLiteSnapshot(),
      );
      expect(outcome.phase, ObserverGoalPhase.colonialLite);
    });

    test('COLONIAL when OW at quota with colonial acquisition targets', () {
      final outcome = runPhasePlanners(
        game: buildPhasePlannerDispatchColonialGame(),
        snapshot: buildPhasePlannerDispatchColonialSnapshot(),
      );
      expect(outcome.phase, ObserverGoalPhase.colonial);
    });

    test('DEVELOP when OW at quota and no colonial acquisition targets', () {
      final outcome = runPhasePlanners(
        game: buildPhasePlannerDispatchDevelopGame(),
        snapshot: buildPhasePlannerDispatchDevelopSnapshot(),
      );
      expect(outcome.phase, ObserverGoalPhase.develop);
    });
  });

  group('EXPAND outcome composition', () {
    test('EXPAND populates EXPAND slots and colonial bundle when NW weight > 0 '
        '(Refs #2847)', () {
      final game = buildPhasePlannerDispatchExpandGame();
      final snapshot = buildPhasePlannerDispatchExpandSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);

      // EXPAND fields paired with the per-planner outputs the
      // dispatcher composes. The declare-war target flows into
      // `planExpandMilitary`, so the two plans target the same
      // faction.
      expect(outcome.expandDeclareWarTargetFactionId, _minor1);
      expect(
        outcome.expandPeaceTargetFactionIdsSorted,
        planExpandPeace(game: game, snapshot: snapshot),
      );
      // Distraction-peace slot sources the below-quota tribe distraction
      // decider only (Refs #2847 § H5 — the minor decider stays confined
      // to the no-phasePlan fallback to protect multi-minor conquest).
      expect(
        outcome.expandDistractionPeaceTargetFactionIdsSorted,
        belowQuotaRegimentThinTribeDistractionPeaceTargets(
          game: game,
          snapshot: snapshot,
        ),
      );
      expect(
        outcome.expandEconomyPlan,
        planExpandEconomy(game: game, snapshot: snapshot),
      );
      expect(
        outcome.expandMilitaryPlan,
        planExpandMilitary(
          game: game,
          snapshot: snapshot,
          declaredWarTargetFactionId: _minor1,
        ),
      );
      expect(outcome.priorityWeights.newWorldAcquisition, greaterThan(0.0));
      expect(phasePlanFullColonialOutputsActive(outcome), isTrue);

      final colonial = planColonialAcquisition(game: game, snapshot: snapshot);
      expect(outcome.colonialAcquisitionTarget, colonial);
      expect(
        outcome.colonialPeaceTargetFactionIdsSorted,
        planColonialPeace(game: game, snapshot: snapshot),
      );
      final declaredColonialTarget =
          (colonial != null && colonial.method == AcquisitionMethod.declareWar)
          ? colonial.targetFactionId
          : null;
      expect(
        outcome.colonialMilitaryPlan,
        planColonialMilitary(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: declaredColonialTarget,
        ),
      );
      expect(
        outcome.colonialNavalPlan,
        planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: declaredColonialTarget,
        ),
      );
      expect(
        outcome.colonialCivilianWorkOrders,
        planColonialCivilian(game: game, snapshot: snapshot),
      );

      // COLONIAL-lite and DEVELOP slots stay default under EXPAND.
      expect(outcome.colonialLiteOverturesSorted, isEmpty);
      expect(outcome.colonialLiteNavalPlan, ColonialLiteNavalPlan.defaultPlan);
      expect(outcome.developPeaceTargetFactionIdsSorted, isEmpty);
      expect(outcome.developCivilianWorkOrders, isEmpty);
    });
  });

  group('COLONIAL-lite outcome composition', () {
    test('COLONIAL-lite populates EXPAND + COLONIAL-lite slots', () {
      final game = buildPhasePlannerDispatchColonialLiteGame();
      final snapshot = buildPhasePlannerDispatchColonialLiteSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);

      // EXPAND continues to run during the safeguard ("Begin NW
      // overture/naval penetration without weakening OW push").
      expect(
        outcome.expandDeclareWarTargetFactionId,
        planExpandDeclareWar(game: game, snapshot: snapshot),
      );
      expect(
        outcome.expandMilitaryPlan,
        planExpandMilitary(
          game: game,
          snapshot: snapshot,
          declaredWarTargetFactionId: outcome.expandDeclareWarTargetFactionId,
        ),
      );

      // COLONIAL-lite directives surface.
      expect(
        outcome.colonialLiteOverturesSorted,
        planColonialLiteOvertures(game: game, snapshot: snapshot),
      );
      expect(
        outcome.colonialLiteNavalPlan,
        planColonialLiteNaval(game: game, snapshot: snapshot),
      );

      // Full-COLONIAL and DEVELOP slots stay default — COLONIAL-lite
      // is structurally an EXPAND safeguard, NOT a full-COLONIAL
      // run.
      expect(outcome.colonialAcquisitionTarget, isNull);
      expect(outcome.colonialPeaceTargetFactionIdsSorted, isEmpty);
      expect(outcome.colonialMilitaryPlan, ColonialMilitaryPlan.defaultPlan);
      expect(outcome.colonialNavalPlan, ColonialNavalPlan.defaultPlan);
      expect(outcome.colonialCivilianWorkOrders, isEmpty);
      expect(outcome.developPeaceTargetFactionIdsSorted, isEmpty);
      expect(outcome.developCivilianWorkOrders, isEmpty);
    });
  });

  group('COLONIAL outcome composition', () {
    test(
      'declareWar acquisition pairs target factionId into military / naval',
      () {
        // The fixture has an at-war tribe owning the NW invadable
        // province. `planColonialAcquisition` resolves to
        // `(tribe1, declareWar)` and the dispatcher forwards that
        // factionId into both `planColonialMilitary` and
        // `planColonialNaval` -- the at-war fallback arm fires for both
        // sibling plans with `_tribe1` listed as the priority owner.
        final game = buildPhasePlannerDispatchColonialGame();
        final snapshot = buildPhasePlannerDispatchColonialSnapshot();
        final outcome = runPhasePlanners(game: game, snapshot: snapshot);

        expect(outcome.phase, ObserverGoalPhase.colonial);

        // Acquisition arm: declareWar over the tribe (Join Empire and
        // purchase_land arms have no overture / merchant).
        expect(
          outcome.colonialAcquisitionTarget,
          const ColonialAcquisitionTarget(
            targetFactionId: _tribe1,
            method: AcquisitionMethod.declareWar,
          ),
        );

        // Military / naval invasion-transport restricted to the
        // declared target.
        expect(
          outcome.colonialMilitaryPlan,
          planColonialMilitary(
            game: game,
            snapshot: snapshot,
            colonialDeclaredWarTargetFactionId: _tribe1,
          ),
        );
        expect(
          outcome.colonialNavalPlan,
          planColonialNaval(
            game: game,
            snapshot: snapshot,
            colonialDeclaredWarTargetFactionId: _tribe1,
          ),
        );

        // Peace + civilian still flow.
        expect(
          outcome.colonialPeaceTargetFactionIdsSorted,
          planColonialPeace(game: game, snapshot: snapshot),
        );
        expect(
          outcome.colonialCivilianWorkOrders,
          planColonialCivilian(game: game, snapshot: snapshot),
        );

        // EXPAND / COLONIAL-lite / DEVELOP slots stay default.
        expect(outcome.expandDeclareWarTargetFactionId, isNull);
        expect(outcome.expandPeaceTargetFactionIdsSorted, isEmpty);
        expect(outcome.expandEconomyPlan, ExpandEconomyPlan.defaultPlan);
        expect(outcome.expandMilitaryPlan, ExpandMilitaryPlan.defaultPlan);
        expect(outcome.colonialLiteOverturesSorted, isEmpty);
        expect(
          outcome.colonialLiteNavalPlan,
          ColonialLiteNavalPlan.defaultPlan,
        );
        expect(outcome.developPeaceTargetFactionIdsSorted, isEmpty);
        expect(outcome.developCivilianWorkOrders, isEmpty);
      },
    );

    test('null acquisition leaves military / naval to at-war fallback arm', () {
      // Zero regiments + no Join Empire / purchase_land path means
      // `planColonialAcquisition` returns null; the dispatcher must
      // therefore pass `null` as `colonialDeclaredWarTargetFactionId`
      // and the at-war fallback arms fire identically to a direct
      // call.
      final game = buildPhasePlannerDispatchColonialGame(regimentCount: 0);
      // Still at-war with the tribe so the at-war fallback arm
      // populates the priority owner roster (tribe1) for both
      // military and naval.
      final snapshot = buildPhasePlannerDispatchColonialSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);

      expect(outcome.phase, ObserverGoalPhase.colonial);
      expect(
        outcome.colonialAcquisitionTarget,
        isNull,
        reason:
            'Zero regiments + no overture / merchant => null '
            'acquisition target.',
      );
      expect(
        outcome.colonialMilitaryPlan,
        planColonialMilitary(game: game, snapshot: snapshot),
        reason:
            'Dispatcher forwards null colonialDeclaredWarTargetFactionId '
            'so the planner picks via the at-war fallback arm.',
      );
      expect(
        outcome.colonialNavalPlan,
        planColonialNaval(game: game, snapshot: snapshot),
        reason:
            'Naval pairs with military on the same '
            'colonialDeclaredWarTargetFactionId argument.',
      );
    });
  });

  group('DEVELOP outcome composition', () {
    test('DEVELOP populates DEVELOP slots only', () {
      final game = buildPhasePlannerDispatchDevelopGame();
      final snapshot = buildPhasePlannerDispatchDevelopSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);

      expect(outcome.phase, ObserverGoalPhase.develop);
      expect(
        outcome.developPeaceTargetFactionIdsSorted,
        planDevelopPeace(game: game, snapshot: snapshot),
      );
      expect(
        outcome.developCivilianWorkOrders,
        planDevelopCivilian(game: game, snapshot: snapshot),
      );

      // EXPAND / COLONIAL slots stay default.
      expect(outcome.expandDeclareWarTargetFactionId, isNull);
      expect(outcome.expandPeaceTargetFactionIdsSorted, isEmpty);
      expect(outcome.expandEconomyPlan, ExpandEconomyPlan.defaultPlan);
      expect(outcome.expandMilitaryPlan, ExpandMilitaryPlan.defaultPlan);
      expect(outcome.colonialLiteOverturesSorted, isEmpty);
      expect(outcome.colonialLiteNavalPlan, ColonialLiteNavalPlan.defaultPlan);
      expect(outcome.colonialAcquisitionTarget, isNull);
      expect(outcome.colonialPeaceTargetFactionIdsSorted, isEmpty);
      expect(outcome.colonialMilitaryPlan, ColonialMilitaryPlan.defaultPlan);
      expect(outcome.colonialNavalPlan, ColonialNavalPlan.defaultPlan);
      expect(outcome.colonialCivilianWorkOrders, isEmpty);
    });
  });

  group('determinism (Must-have #7)', () {
    test('EXPAND outcome equal across repeated calls', () {
      final game = buildPhasePlannerDispatchExpandGame();
      final snapshot = buildPhasePlannerDispatchExpandSnapshot();
      final a = runPhasePlanners(game: game, snapshot: snapshot);
      final b = runPhasePlanners(game: game, snapshot: snapshot);
      expect(b.phase, a.phase);
      expect(
        b.expandDeclareWarTargetFactionId,
        a.expandDeclareWarTargetFactionId,
      );
      expect(
        b.expandPeaceTargetFactionIdsSorted,
        a.expandPeaceTargetFactionIdsSorted,
      );
      expect(b.expandEconomyPlan, a.expandEconomyPlan);
      expect(b.expandMilitaryPlan, a.expandMilitaryPlan);
    });

    test('COLONIAL outcome equal across repeated calls', () {
      final game = buildPhasePlannerDispatchColonialGame();
      final snapshot = buildPhasePlannerDispatchColonialSnapshot();
      final a = runPhasePlanners(game: game, snapshot: snapshot);
      final b = runPhasePlanners(game: game, snapshot: snapshot);
      expect(b.phase, a.phase);
      expect(b.colonialAcquisitionTarget, a.colonialAcquisitionTarget);
      expect(
        b.colonialPeaceTargetFactionIdsSorted,
        a.colonialPeaceTargetFactionIdsSorted,
      );
      expect(b.colonialMilitaryPlan, a.colonialMilitaryPlan);
      expect(b.colonialNavalPlan, a.colonialNavalPlan);
      expect(b.colonialCivilianWorkOrders, a.colonialCivilianWorkOrders);
    });
  });

  group('priorityWeights field (Refs #2847 Phase 1 scaffolding)', () {
    test(
      'EXPAND outcome carries weights field-equal to computePhasePriorityWeights',
      () {
        final game = buildPhasePlannerDispatchExpandGame();
        final snapshot = buildPhasePlannerDispatchExpandSnapshot();
        final outcome = runPhasePlanners(game: game, snapshot: snapshot);
        expect(
          outcome.priorityWeights,
          computePhasePriorityWeights(
            snapshot: snapshot,
            game: game,
            expandEconomyPlan: outcome.expandEconomyPlan,
          ),
        );
      },
    );

    test('COLONIAL-lite outcome carries weights field-equal to '
        'computePhasePriorityWeights', () {
      final game = buildPhasePlannerDispatchColonialLiteGame();
      final snapshot = buildPhasePlannerDispatchColonialLiteSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);
      expect(
        outcome.priorityWeights,
        computePhasePriorityWeights(
          snapshot: snapshot,
          game: game,
          expandEconomyPlan: outcome.expandEconomyPlan,
        ),
      );
    });

    test('COLONIAL outcome carries weights from default ExpandEconomyPlan (no '
        'EXPAND planner ran)', () {
      final game = buildPhasePlannerDispatchColonialGame();
      final snapshot = buildPhasePlannerDispatchColonialSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);
      // Sanity: COLONIAL outcome leaves EXPAND plan at default.
      expect(outcome.expandEconomyPlan, ExpandEconomyPlan.defaultPlan);
      expect(
        outcome.priorityWeights,
        computePhasePriorityWeights(
          snapshot: snapshot,
          game: game,
          expandEconomyPlan: ExpandEconomyPlan.defaultPlan,
        ),
      );
    });

    test('DEVELOP outcome carries weights from default ExpandEconomyPlan (no '
        'EXPAND planner ran)', () {
      final game = buildPhasePlannerDispatchDevelopGame();
      final snapshot = buildPhasePlannerDispatchDevelopSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);
      expect(outcome.expandEconomyPlan, ExpandEconomyPlan.defaultPlan);
      expect(
        outcome.priorityWeights,
        computePhasePriorityWeights(
          snapshot: snapshot,
          game: game,
          expandEconomyPlan: ExpandEconomyPlan.defaultPlan,
        ),
      );
    });

    test(
      'weights are advisory — repeated dispatches yield identical weights',
      () {
        final game = buildPhasePlannerDispatchExpandGame();
        final snapshot = buildPhasePlannerDispatchExpandSnapshot();
        final a = runPhasePlanners(game: game, snapshot: snapshot);
        final b = runPhasePlanners(game: game, snapshot: snapshot);
        expect(b.priorityWeights, a.priorityWeights);
      },
    );
  });
}
