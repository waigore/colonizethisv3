// Table-driven naval battle resolution and intercept scenarios (Refs #3865).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'naval_combat_test_support.dart';
import 'scenario_runner.dart';



List<RunnableScenario> resolveSeaBattleScenarios() => [
  RunnableScenario(
    scenarioId: 'rsb-strength-ratio',
    label: 'returns surviving ships with casualties by strength ratio',
    run: () {
      final battle = BattleContextSea(
        seaZoneId: 'sea1',
        side1: NavalBattleSide(
          ownerId: 'p1',
          ships: legacyShipInstancesForFleet('battle_p1', ['carrack', 'carrack']),
        ),
        side2: NavalBattleSide(
          ownerId: 'p2',
          ships: legacyShipInstancesForFleet('battle_p2', ['fluyte']),
        ),
      );
      final result = resolveSeaBattle(battle, 42);
      expect(result.survivingShipsSide1, isNotEmpty);
      expect(result.survivingShipsSide2, isNotEmpty);
      expect(
        result.survivingShipsSide1.length + result.survivingShipsSide2.length,
        lessThanOrEqualTo(3),
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'rsb-zero-strength',
    label: 'returns all ships when total strength is zero',
    run: () {
      const battle = BattleContextSea(
        seaZoneId: 'sea1',
        side1: NavalBattleSide(ownerId: 'p1', ships: []),
        side2: NavalBattleSide(ownerId: 'p2', ships: []),
      );
      final result = resolveSeaBattle(battle, 0);
      expect(result.survivingShipsSide1, isEmpty);
      expect(result.survivingShipsSide2, isEmpty);
    },
  ),
  RunnableScenario(
    scenarioId: 'rsb-feeding-morale',
    label: 'feeding coverage multiplies raw naval strength like land combat morale',
    run: () {
      final raw = navalStrength(['carrack', 'carrack']);
      expect(raw * moraleMultiplierForFeedingCoverage(1.0), raw);
      expect(raw * moraleMultiplierForFeedingCoverage(0.6), raw * 0.75);
      expect(raw * moraleMultiplierForFeedingCoverage(0.0), raw * 0.5);
    },
  ),
  RunnableScenario(
    scenarioId: 'rsb-no-retreat',
    label: 'does not retreat when retreat is disallowed by topology/relation gate',
    run: () {
      final battle = BattleContextSea(
        seaZoneId: 'sea1',
        side1: NavalBattleSide(
          ownerId: 'p1',
          ships: legacyShipInstancesForFleet('ret_p1', ['carrack', 'carrack']),
          mission: FleetMission.patrol,
        ),
        side2: NavalBattleSide(
          ownerId: 'p2',
          ships: legacyShipInstancesForFleet('ret_p2', ['fluyte', 'fluyte']),
          mission: FleetMission.blockade,
        ),
      );
      final result = resolveSeaBattle(
        battle,
        42,
        side1CanRetreat: false,
        side2CanRetreat: false,
      );
      expect(result.side1Retreated, isFalse);
      expect(result.side2Retreated, isFalse);
    },
  ),
];

List<RunnableScenario> applyNavalBattleResultsScenarios() => [
  RunnableScenario(
    scenarioId: 'anbr-replace-fleets',
    label: 'replaces fleets in zone with surviving sides',
    run: () {
      final game = navalTwoPlayerGame(
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'p1',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: ['carrack'],
          ),
          Fleet(
            id: 'f2',
            ownerId: 'p2',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: ['fluyte'],
          ),
        ],
      );
      final battle = BattleContextSea(
        seaZoneId: 'sea1',
        side1: NavalBattleSide(
          ownerId: 'p1',
          ships: legacyShipInstancesForFleet('ap1', ['carrack']),
        ),
        side2: NavalBattleSide(
          ownerId: 'p2',
          ships: legacyShipInstancesForFleet('ap2', ['fluyte']),
        ),
      );
      final result = NavalBattleResult(
        survivingShipsSide1: legacyShipInstancesForFleet('out1', ['carrack']),
        survivingShipsSide2: const [],
      );
      final updated = applyNavalBattleResults(game, battle, result, 'oldWorld');
      expect(updated.worldState.fleets.length, 1);
      expect(updated.worldState.fleets.single.ownerId, 'p1');
      expect(updated.worldState.fleets.single.shipTypeIds, ['carrack']);
      expect(updated.worldState.fleets.single.mission, FleetMission.none);
    },
  ),
  RunnableScenario(
    scenarioId: 'anbr-preserve-mission',
    label: 'preserves mission on recreated surviving fleets',
    run: () {
      final game = navalTwoPlayerGame(
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'p1',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: ['carrack'],
            mission: FleetMission.patrol,
          ),
          Fleet(
            id: 'f2',
            ownerId: 'p2',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: ['fluyte'],
            mission: FleetMission.blockade,
          ),
        ],
      );
      final battle = BattleContextSea(
        seaZoneId: 'sea1',
        side1: NavalBattleSide(
          ownerId: 'p1',
          ships: legacyShipInstancesForFleet('m1', ['carrack']),
          mission: FleetMission.patrol,
        ),
        side2: NavalBattleSide(
          ownerId: 'p2',
          ships: legacyShipInstancesForFleet('m2', ['fluyte']),
          mission: FleetMission.blockade,
        ),
      );
      final result = NavalBattleResult(
        survivingShipsSide1: legacyShipInstancesForFleet('om1', ['carrack']),
        survivingShipsSide2: legacyShipInstancesForFleet('om2', ['fluyte']),
      );
      final updated = applyNavalBattleResults(game, battle, result, 'oldWorld');
      final p1 = updated.worldState.fleets.firstWhere((f) => f.ownerId == 'p1');
      final p2 = updated.worldState.fleets.firstWhere((f) => f.ownerId == 'p2');
      expect(p1.mission, FleetMission.patrol);
      expect(p2.mission, FleetMission.blockade);
    },
  ),
];

List<RunnableScenario> navalInterceptProbabilityScenarios() => [
  RunnableScenario(
    scenarioId: 'nip-patrol',
    label: 'Patrol uses mission-factor * ratio',
    run: () {
      expect(
        navalInterceptProbability(
          interceptorScore: 5,
          targetFleeScore: 5,
          isBlockade: false,
        ),
        0.25,
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'nip-blockade',
    label: 'Blockade uses mission-factor * ratio',
    run: () {
      expect(
        navalInterceptProbability(
          interceptorScore: 8,
          targetFleeScore: 2,
          isBlockade: true,
        ),
        closeTo(0.72, 1e-9),
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'nip-clamped',
    label: 'result is clamped 0.05-0.85',
    run: () {
      expect(
        navalInterceptProbability(
          interceptorScore: 0,
          targetFleeScore: 100,
          isBlockade: false,
        ),
        greaterThanOrEqualTo(0.05),
      );
      expect(
        navalInterceptProbability(
          interceptorScore: 100,
          targetFleeScore: 0,
          isBlockade: true,
        ),
        lessThanOrEqualTo(0.85),
      );
    },
  ),
];
