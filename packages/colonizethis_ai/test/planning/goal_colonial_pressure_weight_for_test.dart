// Unit tests for `goalColonialPressureWeightFor` — the production goal-score
// colonial-pressure weight derivation used by the pre-prep `strategic_ai.dart`
// goal-eval site (Refs #2847 Phase 3 goal-score wiring).
//
// Spec contract (SPEC/ai/phase-planner-architecture.md § Phase 3 consumer
// wiring — goal-score colonial-pressure floors):
//
//   "The production `strategic_ai.dart` goal-eval site derives
//    `computePhasePriorityWeights`' `expandEconomyPlan` input from
//    `planExpandEconomy(game, snapshot)` ... Sourcing the real EXPAND
//    economy plan — rather than `ExpandEconomyPlan.defaultPlan` — lets the
//    § Resource-need overrides treasury-recovery floor
//    (`newWorldAcquisition = 0.60` ...) lift the goal-score colonial-pressure
//    weight for a below-quota peer-war-locked GP at the goal-scoring layer.
//    ... healthy GPs (treasury never `0`) are unaffected and the gp1/gp2 +6
//    OW baseline holds by construction."
//
// These tests pin:
//
//   1. Below-quota GP with treasury == 0, NW == 0, invadable OW frontier
//      (so `planExpandEconomy` returns `boostTreasuryRecoveryCargo == true`)
//      => weight lifts to the treasury-recovery floor (0.60). This is the
//      NEW behaviour the goal-eval EXPAND-plan sourcing enables; under the
//      old `ExpandEconomyPlan.defaultPlan` path the weight stayed at the
//      0.05 early-sprint curve value.
//   2. Healthy below-quota GP (treasury well above the cheapest regiment
//      cost) => the override does not fire and the curve value (0.05 at
//      OW <= 7) stands (regression guard for the +6 OW baseline).
//   3. At-quota GP (OW >= 10) with treasury == 0 => `planExpandEconomy`
//      short-circuits to `ExpandEconomyPlan.defaultPlan`, so the
//      treasury-recovery override cannot fire and the curve value (0.40 at
//      OW = 10) stands.
//   4. Determinism: identical `(snapshot, game)` inputs yield the same
//      `double` (Refs #2509 Must-have #7).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _owProvGp1 = 'oldWorld|gp1_a';
const String _owProvMinor = 'oldWorld|m1_a';

Army _homeArmyWithRegiments(String ownerId, int regimentCount) {
  return Army(
    id: 'home_army:$ownerId',
    ownerId: ownerId,
    regionId: kOldWorldRegionId,
    stationedProvinceId: _owProvGp1,
    isHomeArmy: true,
    regimentUnitIds: <String>[
      for (var i = 0; i < regimentCount; i++) 'reg_${ownerId}_$i',
    ],
  );
}

Game _game({required int regimentCount, required int treasury}) {
  return Game(
    id: 'g-2847-goal-weight-r${regimentCount}_t$treasury',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 30, phase: TurnPhase.orders),
      oldWorld: const RegionData(
        provinces: [
          Province(id: _owProvGp1, regionId: kOldWorldRegionId, ownerId: _gp1),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      armies: regimentCount > 0
          ? [_homeArmyWithRegiments(_gp1, regimentCount)]
          : const [],
    ),
    players: [
      Player(id: _gp1, displayName: 'GP1', isHuman: false, treasury: treasury),
      const Player(id: _gp2, displayName: 'GP2', isHuman: false),
    ],
  );
}

AIWorldSnapshot _snapshot({
  required int oldWorldProvincesOwned,
  required int treasury,
  required int newWorldProvincesOwned,
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

void main() {
  group('goalColonialPressureWeightFor', () {
    test(
      'below-quota GP at treasury==0, NW==0 lifts to treasury-recovery floor '
      '(0.60) via the real EXPAND plan',
      () {
        // OW = 7 (below quota); curve value here is 0.05. The real
        // `planExpandEconomy` yields `boostTreasuryRecoveryCargo == true`
        // because effective treasury (0) is below the cheapest regiment
        // cost, so the treasury-recovery override fires.
        final weight = goalColonialPressureWeightFor(
          snapshot: _snapshot(
            oldWorldProvincesOwned: 7,
            treasury: 0,
            newWorldProvincesOwned: 0,
          ),
          game: _game(regimentCount: 2, treasury: 0),
        );
        expect(weight, kPhasePriorityNwTreasuryRecoveryFloor);
        expect(
          weight,
          isNot(0.05),
          reason:
              'Old ExpandEconomyPlan.defaultPlan path would have left the '
              'weight at the 0.05 early-sprint curve value.',
        );
      },
    );

    test(
      'healthy below-quota GP (treasury above cheapest regiment cost) keeps '
      'the curve value 0.05 (no override; +6 baseline regression guard)',
      () {
        // Well above the cheapest regiment build cost (catalog min = 2000),
        // so `planExpandEconomy` leaves `boostTreasuryRecoveryCargo == false`
        // and the treasury-recovery override cannot fire.
        const treasury = 100000;
        final weight = goalColonialPressureWeightFor(
          snapshot: _snapshot(
            oldWorldProvincesOwned: 7,
            treasury: treasury,
            newWorldProvincesOwned: 0,
          ),
          game: _game(regimentCount: 2, treasury: treasury),
        );
        expect(weight, 0.05);
      },
    );

    test(
      'at-quota GP (OW >= 10) with treasury==0 short-circuits to defaultPlan, '
      'so the override cannot fire and the curve value (0.40) stands',
      () {
        final weight = goalColonialPressureWeightFor(
          snapshot: _snapshot(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
            treasury: 0,
            newWorldProvincesOwned: 0,
          ),
          game: _game(regimentCount: 2, treasury: 0),
        );
        expect(weight, 0.40);
      },
    );

    test('identical inputs yield the same weight (Refs #2509 Must-have #7)', () {
      final snapshot = _snapshot(
        oldWorldProvincesOwned: 7,
        treasury: 0,
        newWorldProvincesOwned: 0,
      );
      final game = _game(regimentCount: 2, treasury: 0);
      final first = goalColonialPressureWeightFor(
        snapshot: snapshot,
        game: game,
      );
      final second = goalColonialPressureWeightFor(
        snapshot: snapshot,
        game: game,
      );
      expect(first, second);
    });
  });
}
