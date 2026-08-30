// Naval battle resolution scenarios (Refs #4196 slice C).

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
          ships: legacyShipInstancesForFleet('battle_p1', [
            'carrack',
            'carrack',
          ]),
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
    label:
        'feeding coverage multiplies raw naval strength like land combat morale',
    run: () {
      final raw = navalStrength(['carrack', 'carrack']);
      expect(raw * moraleMultiplierForFeedingCoverage(1.0), raw);
      expect(raw * moraleMultiplierForFeedingCoverage(0.6), raw * 0.75);
      expect(raw * moraleMultiplierForFeedingCoverage(0.0), raw * 0.5);
    },
  ),
  RunnableScenario(
    scenarioId: 'rsb-no-retreat',
    label:
        'does not retreat when retreat is disallowed by topology/relation gate',
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
