// Case bodies for `phase_priority_weights_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Unit tests for the soft-phase priority weight scaffolding in
// `packages/colonizethis_ai/lib/src/planning/phase_priority_weights.dart`
// (Refs #2847 Phase 1 — weight system core).
//
// Spec contract (issue #2847 § Soft-phase priority weights;
// SPEC/ai/phase-planner-architecture.md § Soft-phase priority weights):
//
//   "Replace the binary EXPAND vs COLONIAL transition at OW=10 with a
//    weight curve where NW priority scales from ~5% at OW=7 to ~80% at
//    OW=13. Resource-need overrides raise weight floors when the
//    snapshot indicates a GP cannot bootstrap OW conquest without an
//    income or regiment lift. `oldWorldConquest` is never weakened by
//    an override."
//
// These tests pin:
//
//   1. Curve plateau: OW = 0..7 always yields the early-sprint default
//      weights (positive — Refs #2847 § curve table; negative — OW = 8
//      moves off the plateau).
//   2. Each named curve row in the SPEC table maps to the exact weight
//      quad documented at OW = 8, 9, 10, 11, 12, 13.
//   3. OW > 13 saturates at the OW = 13+ row.
//   4. Treasury-recovery override raises `newWorldAcquisition` to 0.60
//      when (treasury == 0, NW = 0, boostTreasuryRecoveryCargo) all
//      hold; negative case (any one predicate false) leaves the curve
//      value unchanged.
//   5. Zero-regiment override raises `newWorldAcquisition` to 0.30
//      when (regimentCount == 0, invadableProvinceIdsSorted non-empty)
//      both hold; negative cases (regimentCount > 0; empty invadable
//      list) leave the curve value unchanged.
//   6. Both overrides firing together: the larger floor (0.60) wins.
//   7. `oldWorldConquest`, `oldWorldCivilian`, `newWorldCivilian` are
//      never weakened by any override predicate (only the NW
//      acquisition floor is raised).
//   8. Determinism: identical inputs produce field-equal results.
//
// The dispatcher contract that `PhasePlanOutcome.priorityWeights`
// field-equals `computePhasePriorityWeights` for the same input
// triple is pinned separately in `phase_planner_dispatch_test.dart`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show ExpandEconomyPlan;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'ai_planner_fixtures.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _owProvGp1 = 'oldWorld|gp1_a';
const String _owProvMinor = 'oldWorld|m1_a';

const ExpandEconomyPlan _defaultExpandPlan = ExpandEconomyPlan.defaultPlan;
const ExpandEconomyPlan _boostCargoPlan = ExpandEconomyPlan(
  forceCheapestRegimentBuild: false,
  boostTreasuryRecoveryCargo: true,
);

Game _gameWithRegiments(int regimentCount) {
  return Game(
    id: 'g-2847-phase-priority-weights-r$regimentCount',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 30, phase: TurnPhase.orders),
      oldWorld: const RegionData(
        provinces: [
          Province(id: _owProvGp1, regionId: kOldWorldRegionId, ownerId: _gp1),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      armies: regimentCount > 0
          ? [homeArmyWithRegiments(_gp1, regimentCount)]
          : const [],
    ),
    players: const [
      Player(id: _gp1, displayName: 'GP1', isHuman: false, treasury: 0),
      Player(id: _gp2, displayName: 'GP2', isHuman: false),
    ],
  );
}

AIWorldSnapshot _snapshot({
  required int oldWorldProvincesOwned,
  int treasury = 1000,
  int newWorldProvincesOwned = 1,
  List<String> invadable = const [_owProvMinor],
}) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: invadable,
    ),
    colonial: ColonialSummary(newWorldProvincesOwned: newWorldProvincesOwned),
    economy: EconomySummary(treasury: treasury),
    relations: const {},
  );
}


void registerPhasePriorityWeightsCurveCases() {
  group('computePhasePriorityWeights curve plateau (OW <= 7)', () {
    for (final ow in const [0, 1, 4, 7]) {
      test('OW = $ow yields early-sprint default plateau', () {
        final weights = computePhasePriorityWeights(
          snapshot: _snapshot(oldWorldProvincesOwned: ow),
          game: _gameWithRegiments(5),
          expandEconomyPlan: _defaultExpandPlan,
        );
        expect(weights, PhasePriorityWeights.earlySprintDefault);
        expect(weights.oldWorldConquest, 0.95);
        expect(weights.newWorldAcquisition, 0.05);
        expect(weights.oldWorldCivilian, 0.90);
        expect(weights.newWorldCivilian, 0.10);
      });
    }

    test('OW = kPhasePriorityCurveEarlySprintCeiling (7) sits on plateau', () {
      final weights = computePhasePriorityWeights(
        snapshot: _snapshot(
          oldWorldProvincesOwned: kPhasePriorityCurveEarlySprintCeiling,
        ),
        game: _gameWithRegiments(5),
        expandEconomyPlan: _defaultExpandPlan,
      );
      expect(weights, PhasePriorityWeights.earlySprintDefault);
    });

    test('OW = 8 moves off the plateau (negative for plateau pin)', () {
      final weights = computePhasePriorityWeights(
        snapshot: _snapshot(oldWorldProvincesOwned: 8),
        game: _gameWithRegiments(5),
        expandEconomyPlan: _defaultExpandPlan,
      );
      expect(weights, isNot(PhasePriorityWeights.earlySprintDefault));
      expect(weights.oldWorldConquest, 0.90);
      expect(weights.newWorldAcquisition, 0.10);
    });
  });

  group('computePhasePriorityWeights curve rows (OW = 8..13+)', () {
    test('OW = 8', () {
      final w = computePhasePriorityWeights(
        snapshot: _snapshot(oldWorldProvincesOwned: 8),
        game: _gameWithRegiments(5),
        expandEconomyPlan: _defaultExpandPlan,
      );
      expect(w.oldWorldConquest, 0.90);
      expect(w.newWorldAcquisition, 0.10);
      expect(w.oldWorldCivilian, 0.85);
      expect(w.newWorldCivilian, 0.15);
    });

    test('OW = 9', () {
      final w = computePhasePriorityWeights(
        snapshot: _snapshot(oldWorldProvincesOwned: 9),
        game: _gameWithRegiments(5),
        expandEconomyPlan: _defaultExpandPlan,
      );
      expect(w.oldWorldConquest, 0.80);
      expect(w.newWorldAcquisition, 0.20);
      expect(w.oldWorldCivilian, 0.75);
      expect(w.newWorldCivilian, 0.25);
    });

    test('OW = 10 (hard-phase EXPAND->COLONIAL inflection)', () {
      final w = computePhasePriorityWeights(
        snapshot: _snapshot(oldWorldProvincesOwned: 10),
        game: _gameWithRegiments(5),
        expandEconomyPlan: _defaultExpandPlan,
      );
      expect(w.oldWorldConquest, 0.60);
      expect(w.newWorldAcquisition, 0.40);
      expect(w.oldWorldCivilian, 0.55);
      expect(w.newWorldCivilian, 0.45);
    });

    test('OW = 11', () {
      final w = computePhasePriorityWeights(
        snapshot: _snapshot(oldWorldProvincesOwned: 11),
        game: _gameWithRegiments(5),
        expandEconomyPlan: _defaultExpandPlan,
      );
      expect(w.oldWorldConquest, 0.40);
      expect(w.newWorldAcquisition, 0.60);
      expect(w.oldWorldCivilian, 0.35);
      expect(w.newWorldCivilian, 0.65);
    });

    test('OW = 12', () {
      final w = computePhasePriorityWeights(
        snapshot: _snapshot(oldWorldProvincesOwned: 12),
        game: _gameWithRegiments(5),
        expandEconomyPlan: _defaultExpandPlan,
      );
      expect(w.oldWorldConquest, 0.20);
      expect(w.newWorldAcquisition, 0.80);
      expect(w.oldWorldCivilian, 0.15);
      expect(w.newWorldCivilian, 0.85);
    });

    test('OW = 13', () {
      final w = computePhasePriorityWeights(
        snapshot: _snapshot(oldWorldProvincesOwned: 13),
        game: _gameWithRegiments(5),
        expandEconomyPlan: _defaultExpandPlan,
      );
      expect(w.oldWorldConquest, 0.10);
      expect(w.newWorldAcquisition, 0.90);
      expect(w.oldWorldCivilian, 0.05);
      expect(w.newWorldCivilian, 0.95);
    });

    test('OW > 13 saturates at OW=13+ row', () {
      for (final ow in const [14, 20, 99]) {
        final w = computePhasePriorityWeights(
          snapshot: _snapshot(oldWorldProvincesOwned: ow),
          game: _gameWithRegiments(5),
          expandEconomyPlan: _defaultExpandPlan,
        );
        expect(w.oldWorldConquest, 0.10, reason: 'ow=$ow');
        expect(w.newWorldAcquisition, 0.90, reason: 'ow=$ow');
        expect(w.oldWorldCivilian, 0.05, reason: 'ow=$ow');
        expect(w.newWorldCivilian, 0.95, reason: 'ow=$ow');
      }
    });
  });

  group('treasury-recovery override (NW acquisition floor 0.60)', () {
    test(
      'fires when all three predicates hold (treasury==0, NW==0, boost)',
      () {
        final w = computePhasePriorityWeights(
          snapshot: _snapshot(
            oldWorldProvincesOwned: 7,
            treasury: 0,
            newWorldProvincesOwned: 0,
          ),
          game: _gameWithRegiments(5),
          expandEconomyPlan: _boostCargoPlan,
        );
        expect(w.newWorldAcquisition, kPhasePriorityNwTreasuryRecoveryFloor);
        expect(
          w.oldWorldConquest,
          0.95,
          reason: 'OW never weakened by override',
        );
        expect(w.oldWorldCivilian, 0.90);
        expect(w.newWorldCivilian, 0.10);
      },
    );

    test(
      'does NOT fire when boostTreasuryRecoveryCargo is false (negative)',
      () {
        final w = computePhasePriorityWeights(
          snapshot: _snapshot(
            oldWorldProvincesOwned: 7,
            treasury: 0,
            newWorldProvincesOwned: 0,
          ),
          game: _gameWithRegiments(5),
          expandEconomyPlan: _defaultExpandPlan,
        );
        expect(w.newWorldAcquisition, 0.05, reason: 'Curve plateau preserved');
      },
    );

    test('does NOT fire when treasury > 0 (negative)', () {
      final w = computePhasePriorityWeights(
        snapshot: _snapshot(
          oldWorldProvincesOwned: 7,
          treasury: 1,
          newWorldProvincesOwned: 0,
        ),
        game: _gameWithRegiments(5),
        expandEconomyPlan: _boostCargoPlan,
      );
      expect(w.newWorldAcquisition, 0.05);
    });

    test('does NOT fire when newWorldProvincesOwned > 0 (negative)', () {
      final w = computePhasePriorityWeights(
        snapshot: _snapshot(
          oldWorldProvincesOwned: 7,
          treasury: 0,
          newWorldProvincesOwned: 1,
        ),
        game: _gameWithRegiments(5),
        expandEconomyPlan: _boostCargoPlan,
      );
      expect(w.newWorldAcquisition, 0.05);
    });
  });

}
