// Pins the canonical homes in `observer_goal_phase.dart` for the remaining
// composite peace-target functions migrated from
// `diplomacy_planner_peace_targets.dart` (Refs #2509 S1).
//
// The last real-body functions in `diplomacy_planner_peace_targets.dart`
// were the private composers (`_survivalGreatPowerPeaceTargets`,
// `_expandRatchetGreatPowerPeaceTargets`) and their two public consumers
// (`collectStalledGreatPowerPeaceTargets`,
// `supplementMutualStalledGreatPowerPeaceOrders`) plus the leaf helper
// (`_appendOfferPeaceIfMissing`). This file pins the canonical
// implementations in `observer_goal_phase.dart` alongside the
// phase-specific peace-target helpers (`expandPhaseGpPeaceTargets`,
// `colonialPhaseGpPeaceTargets`, `developPhaseGpPeaceTargets`) already
// defined there.
//
// `diplomacy_planner_peace_targets.dart` previously retained thin delegating stubs
// for `collectStalledGreatPowerPeaceTargets` and
// `supplementMutualStalledGreatPowerPeaceOrders`; this file verifies
// delegation parity so every legacy call site resolves to the same
// result through the stub as through the canonical.
//
// Behavioral invariants pinned:
//
// `survivalGreatPowerPeaceTargets`:
//   1. Yields entries when all five sub-deciders fire (zero-regime
//      survival paths active).
//   2. Yields nothing for a pristine game state with no conflicts.
//   3. Must-have #7 determinism.
//
// `expandRatchetGreatPowerPeaceTargets`:
//   1. Yields entries when at least one sub-decider fires.
//   2. Yields nothing for a pristine game state.
//   3. Must-have #7 determinism.
//
// `collectStalledGreatPowerPeaceTargets`:
//   1. Phase-gated: DEVELOP returns only DEVELOP targets.
//   2. Phase-gated: EXPAND includes survival + ratchet + phase-specific.
//   3. Delegation parity with the stub in `diplomacy_planner_peace_targets.dart`.
//   4. Must-have #7 determinism.
//
// `supplementMutualStalledGreatPowerPeaceOrders`:
//   1. No-op when no mutual peace offers exist.
//   2. Delegation parity with the stub.
//   3. Must-have #7 determinism.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/observer_goal_phase_composite_peace_test_support.dart';
import 'observer_goal_phase_composite_peace_tail_cases.dart';

void main() {
  group('survivalGreatPowerPeaceTargets', () {
    test('yields zero-regiment survival paths when active', () {
      final game = observerGoalPhaseCompositePeaceZeroRegimentAtWarGame();
      final snapshot = observerGoalPhaseCompositePeaceSnapshotFor(
        playerId: kObserverGoalPhaseCompositePeaceGpOwn,
        oldWorldProvincesOwned: 6,
        atWarWith: [kObserverGoalPhaseCompositePeaceGpOther, kObserverGoalPhaseCompositePeaceMinorZeta],
      );
      final result = survivalGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      ).toList();
      expect(result, isNotEmpty);
      expect(result, contains(kObserverGoalPhaseCompositePeaceGpOther));
    });

    test('yields nothing for pristine game state', () {
      final game = observerGoalPhaseCompositePeacePristineOwProvinces(8);
      final snapshot = observerGoalPhaseCompositePeaceSnapshotFor(
        playerId: kObserverGoalPhaseCompositePeaceGpOwn,
        oldWorldProvincesOwned: 8,
        atWarWith: [],
      );
      final result = survivalGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      ).toList();
      expect(result, isEmpty);
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      final game = observerGoalPhaseCompositePeaceZeroRegimentAtWarGame();
      final snapshot = observerGoalPhaseCompositePeaceSnapshotFor(
        playerId: kObserverGoalPhaseCompositePeaceGpOwn,
        oldWorldProvincesOwned: 6,
        atWarWith: [kObserverGoalPhaseCompositePeaceGpOther, kObserverGoalPhaseCompositePeaceMinorZeta],
      );
      final first = survivalGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      ).toList();
      for (var i = 0; i < 5; i++) {
        final next = survivalGreatPowerPeaceTargets(
          game: game,
          snapshot: snapshot,
        ).toList();
        expect(next, first);
      }
    });
  });

  group('expandRatchetGreatPowerPeaceTargets', () {
    test('yields entries when stalled-expansion deciders fire', () {
      final game = observerGoalPhaseCompositePeaceZeroRegimentAtWarGame();
      final snapshot = observerGoalPhaseCompositePeaceSnapshotFor(
        playerId: kObserverGoalPhaseCompositePeaceGpOwn,
        oldWorldProvincesOwned: 6,
        atWarWith: [kObserverGoalPhaseCompositePeaceGpOther, kObserverGoalPhaseCompositePeaceMinorZeta],
      );
      final result = expandRatchetGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      ).toList();
      expect(result, isNotEmpty);
      expect(result, contains(kObserverGoalPhaseCompositePeaceGpOther));
    });

    test('yields nothing for pristine game state', () {
      final game = observerGoalPhaseCompositePeacePristineOwProvinces(8);
      final snapshot = observerGoalPhaseCompositePeaceSnapshotFor(
        playerId: kObserverGoalPhaseCompositePeaceGpOwn,
        oldWorldProvincesOwned: 8,
        atWarWith: [],
      );
      final result = expandRatchetGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      ).toList();
      expect(result, isEmpty);
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      final game = observerGoalPhaseCompositePeaceZeroRegimentAtWarGame();
      final snapshot = observerGoalPhaseCompositePeaceSnapshotFor(
        playerId: kObserverGoalPhaseCompositePeaceGpOwn,
        oldWorldProvincesOwned: 6,
        atWarWith: [kObserverGoalPhaseCompositePeaceGpOther, kObserverGoalPhaseCompositePeaceMinorZeta],
      );
      final first = expandRatchetGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      ).toList();
      for (var i = 0; i < 5; i++) {
        final next = expandRatchetGreatPowerPeaceTargets(
          game: game,
          snapshot: snapshot,
        ).toList();
        expect(next, first);
      }
    });
  });

  group('collectStalledGreatPowerPeaceTargets', () {
    test('canonical: returns expected results for typical EXPAND state', () {
      final game = observerGoalPhaseCompositePeaceZeroRegimentAtWarGame();
      final snapshot = observerGoalPhaseCompositePeaceSnapshotFor(
        playerId: kObserverGoalPhaseCompositePeaceGpOwn,
        oldWorldProvincesOwned: 6,
        atWarWith: [kObserverGoalPhaseCompositePeaceGpOther, kObserverGoalPhaseCompositePeaceMinorZeta],
      );
      final result = collectStalledGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(result, isNotEmpty);
    });

    test('canonical: returns expected results for DEVELOP state', () {
      final game = Game(
        id: 'g-2509-collect-develop',
        worldState: WorldState(
          turnState:
              const TurnState(phase: TurnPhase.orders, turnNumber: 140),
          oldWorld: RegionData(provinces: [
            for (var i = 1; i <= 10; i++)
              Province(
                id: 'oldWorld|${kObserverGoalPhaseCompositePeaceGpOwn}_$i',
                regionId: 'oldWorld',
                ownerId: kObserverGoalPhaseCompositePeaceGpOwn,
              ),
          ]),
          newWorld: const RegionData(),
        ),
        players: [
          Player(id: kObserverGoalPhaseCompositePeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: kObserverGoalPhaseCompositePeaceGpOther, displayName: 'GP_OTHER', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: kObserverGoalPhaseCompositePeaceGpOwn,
            factionId2: kObserverGoalPhaseCompositePeaceGpOther,
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      final snapshot = observerGoalPhaseCompositePeaceSnapshotFor(
        playerId: kObserverGoalPhaseCompositePeaceGpOwn,
        oldWorldProvincesOwned: 10,
        atWarWith: [kObserverGoalPhaseCompositePeaceGpOther],
      );
      final result = collectStalledGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(result, isNotEmpty);
    });
  });

  registerObserverGoalPhaseCompositePeaceTailCases();
}
