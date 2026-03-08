// Test that every military unit in the game can be built in a normal game.
// SPEC/game/military-units.md: regiment buildable iff unlocking tech in techUnlocked.
// For each regiment we run a scenario with the same shape as military_units_buildability.json:
// grant unlocking tech (if any), workers and stockpile, one build order, assert unit count >= 6.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:sim_scenarios/scenario.dart';
import 'package:sim_scenarios/scenario_runner.dart';

void main() {
  group('military units buildability', () {
    test('every military unit can be built when tech and resources are available',
        () async {
      const capitalProvinceId = 'oldWorld|p1';
      const playerId = 'gp1';

      // Same assertion as military_units_buildability.json: 5 starting military + 1 built => >= 6.
      const minUnitCountAfterBuild = 6;

      final unlockMap = unlockingTechByRegimentId;
      final runner = ScenarioRunner();
      final failures = <String>[];

      for (final econ in RegimentEconomyCatalog.all) {
        final regimentId = econ.id;
        final initialTech = unlockMap[regimentId] != null
            ? [unlockMap[regimentId]!]
            : <String>[];

        final stockpile = <String, int>{
          for (final e in econ.buildInputs.entries) e.key.toString(): e.value,
          'grain': 5,
        };

        // Build scenario as JSON (same shape as military_units_buildability.json) then parse.
        final setup = <String, dynamic>{
          'initialWorkers': {
            playerId: {
              'peasants': 1,
              'apprentices': 0,
              'journeymen': 0,
              'masters': 0,
            },
          },
          'initialStockpile': {playerId: stockpile},
        };
        if (initialTech.isNotEmpty) {
          setup['initialTech'] = {playerId: initialTech};
        }

        final json = <String, dynamic>{
          'name': 'military_build_$regimentId',
          'description':
              'Build one $regimentId (tech: ${initialTech.isEmpty ? "none" : initialTech.join(",")}).',
          'init': {
            'type': 'fromTopology',
            'config': {
              'greatPowers': ['england'],
              'seed': 42,
              'minorNationCount': 0,
            },
            'oldWorld': {
              'grid': [
                ['p1', 'sea1']
              ],
              'nodes': [
                {'id': 'p1', 'regionId': 'oldWorld', 'type': 'province'},
                {'id': 'sea1', 'regionId': 'oldWorld', 'type': 'seaZone'},
              ],
              'edges': [
                {'id1': 'p1', 'id2': 'sea1'},
              ],
            },
          },
          'setup': setup,
          'turns': [
            {
              'turn': 1,
              'orders': [
                {
                  'player': playerId,
                  'type': 'build',
                  'unitType': regimentId,
                  'in': capitalProvinceId,
                },
              ],
            },
          ],
          'assertions': [
            {'turn': 1, 'province': capitalProvinceId, 'owner': playerId},
            {
              'turn': 1,
              'province': capitalProvinceId,
              'unitCount': minUnitCountAfterBuild,
              'matchType': 'atLeast',
            },
          ],
        };

        final scenario = parseScenarioFromJson(json);
        final result = await runner.run(scenario);
        if (!result.passed) {
          failures.add('$regimentId: ${result.failures.join("; ")}');
        }
      }

      expect(
        failures,
        isEmpty,
        reason: 'Regiments that failed to build: ${failures.join("\n")}',
      );
    });
  });
}
