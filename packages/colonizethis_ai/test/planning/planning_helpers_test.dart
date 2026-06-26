// Unit tests for `planning_helpers.dart` (Refs #3278).
//
// Pins the shared dedup helpers:
//   - `gpFactionIdsAtWarWith` — GP-only filter, sort/determinism, non-GP exclusion
//   - `scaleWeightedBonus` — `<= 0.0` guard, `> 1.0` clamp, rounding
//   - `resolvePhaseColonialPressureActive` — COLONIAL-only gate
//   - `resolvePhaseExpandOrColonialLiteActive` — EXPAND / COLONIAL-lite gate

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart'
    show PhasePlanOutcome;
import 'package:colonizethis_ai/src/planning/phase_priority_weights.dart'
    show PhasePriorityWeights;
import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Distinct per-field values so a slot mix-up (e.g. a projection that
// returns `oldWorldCivilian` instead of `oldWorldConquest`) fails hard
// rather than silently matching a shared default.
const PhasePriorityWeights _weights = PhasePriorityWeights(
  oldWorldConquest: 0.11,
  newWorldAcquisition: 0.22,
  oldWorldCivilian: 0.33,
  newWorldCivilian: 0.44,
);

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _tribe1 = 'tribe1';
const String _minor1 = 'minor1';

Game _gameWithGps() {
  return Game(
    id: 'g-3278-planning-helpers',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(provinces: []),
      newWorld: const RegionData(provinces: []),
    ),
    players: const [
      Player(id: _gp1, displayName: 'GP1', isHuman: false),
      Player(id: _gp2, displayName: 'GP2', isHuman: false),
      Player(id: _gp3, displayName: 'GP3', isHuman: false),
    ],
    minorNations: const [MinorNation(id: _minor1, displayName: 'Minor1')],
    tribes: const [Tribe(id: _tribe1, displayName: 'Tribe1')],
  );
}

AIWorldSnapshot _snapshotWithAtWar(List<String> atWarWith) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('gpFactionIdsAtWarWith', () {
    test('filters to Great Powers only and sorts ascending', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([
        _gp3,
        _tribe1,
        _gp1,
        _minor1,
        _gp2,
      ]);
      expect(gpFactionIdsAtWarWith(game, snapshot), [_gp1, _gp2, _gp3]);
    });

    test('returns empty when no GP wars are active', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([_tribe1, _minor1]);
      expect(gpFactionIdsAtWarWith(game, snapshot), isEmpty);
    });

    test('sorts regardless of atWarWith iteration order', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([_gp3, _gp2, _gp1]);
      final a = gpFactionIdsAtWarWith(game, snapshot);
      final b = gpFactionIdsAtWarWith(game, snapshot);
      expect(a, [_gp1, _gp2, _gp3]);
      expect(b, a);
    });
  });

  group('scaleWeightedBonus', () {
    test('returns 0 when weight <= 0.0', () {
      expect(scaleWeightedBonus(0.0, 45), 0);
      expect(scaleWeightedBonus(-0.5, 45), 0);
    });

    test('returns baseConstant exactly when weight == 1.0', () {
      expect(scaleWeightedBonus(1.0, 45), 45);
      expect(scaleWeightedBonus(1.0, 360), 360);
    });

    test('clamps weight > 1.0 to 1.0', () {
      expect(scaleWeightedBonus(1.5, 45), 45);
      expect(scaleWeightedBonus(2.0, 100), 100);
    });

    test('rounds intermediate weights', () {
      expect(scaleWeightedBonus(0.05, 45), 2);
      expect(scaleWeightedBonus(0.6, 50), 30);
    });
  });

  group('resolvePhaseColonialPressureActive', () {
    test('true only under COLONIAL', () {
      expect(
        resolvePhaseColonialPressureActive(ObserverGoalPhase.colonial),
        isTrue,
      );
      expect(
        resolvePhaseColonialPressureActive(ObserverGoalPhase.expand),
        isFalse,
      );
      expect(
        resolvePhaseColonialPressureActive(ObserverGoalPhase.colonialLite),
        isFalse,
      );
      expect(
        resolvePhaseColonialPressureActive(ObserverGoalPhase.develop),
        isFalse,
      );
    });
  });

  group('resolvePhaseExpandOrColonialLiteActive', () {
    test('true under EXPAND and COLONIAL-lite only', () {
      expect(
        resolvePhaseExpandOrColonialLiteActive(ObserverGoalPhase.expand),
        isTrue,
      );
      expect(
        resolvePhaseExpandOrColonialLiteActive(ObserverGoalPhase.colonialLite),
        isTrue,
      );
      expect(
        resolvePhaseExpandOrColonialLiteActive(ObserverGoalPhase.colonial),
        isFalse,
      );
      expect(
        resolvePhaseExpandOrColonialLiteActive(ObserverGoalPhase.develop),
        isFalse,
      );
    });
  });

  group('phase-plan weight projections (Refs #3717)', () {
    PhasePlanOutcome outcome({
      ObserverGoalPhase phase = ObserverGoalPhase.expand,
      PhasePriorityWeights weights = _weights,
    }) => PhasePlanOutcome(phase: phase, priorityWeights: weights);

    test('each projection returns exactly its named priorityWeights slot', () {
      final o = outcome();
      expect(
        resolvePhaseNewWorldAcquisitionWeight(o),
        equals(_weights.newWorldAcquisition),
      );
      expect(
        resolvePhaseOldWorldConquestWeight(o),
        equals(_weights.oldWorldConquest),
      );
      expect(
        resolvePhaseOldWorldCivilianWeight(o),
        equals(_weights.oldWorldCivilian),
      );
      expect(
        resolvePhaseNewWorldCivilianWeight(o),
        equals(_weights.newWorldCivilian),
      );
    });

    test('projections do not read sibling slots (no field confusion)', () {
      final o = outcome();
      // Each of the four distinct slot values is returned by exactly one
      // projection; a swapped accessor would match the wrong value here.
      expect(
        resolvePhaseNewWorldAcquisitionWeight(o),
        isNot(equals(_weights.oldWorldConquest)),
      );
      expect(
        resolvePhaseOldWorldConquestWeight(o),
        isNot(equals(_weights.newWorldAcquisition)),
      );
      expect(
        resolvePhaseOldWorldCivilianWeight(o),
        isNot(equals(_weights.newWorldCivilian)),
      );
      expect(
        resolvePhaseNewWorldCivilianWeight(o),
        isNot(equals(_weights.oldWorldCivilian)),
      );
    });

    test('projections are phase-independent and deterministic', () {
      final results = <double>{
        for (final phase in ObserverGoalPhase.values)
          resolvePhaseNewWorldAcquisitionWeight(outcome(phase: phase)),
      };
      expect(results, <double>{_weights.newWorldAcquisition});

      final o = outcome();
      expect(
        resolvePhaseOldWorldConquestWeight(o),
        equals(resolvePhaseOldWorldConquestWeight(o)),
      );
    });

    test('flipping a single slot changes only that slot projection', () {
      const bumped = PhasePriorityWeights(
        oldWorldConquest: 0.99,
        newWorldAcquisition: 0.22,
        oldWorldCivilian: 0.33,
        newWorldCivilian: 0.44,
      );
      final base = outcome();
      final next = outcome(weights: bumped);
      expect(
        resolvePhaseOldWorldConquestWeight(next),
        isNot(equals(resolvePhaseOldWorldConquestWeight(base))),
      );
      expect(
        resolvePhaseNewWorldAcquisitionWeight(next),
        equals(resolvePhaseNewWorldAcquisitionWeight(base)),
      );
      expect(
        resolvePhaseOldWorldCivilianWeight(next),
        equals(resolvePhaseOldWorldCivilianWeight(base)),
      );
      expect(
        resolvePhaseNewWorldCivilianWeight(next),
        equals(resolvePhaseNewWorldCivilianWeight(base)),
      );
    });
  });
}
