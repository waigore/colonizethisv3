// Test that every naval unit (ship) in the game can be built in a normal game.
// SPEC/game/ships-and-naval.md, SPEC/game/tech-tree-naval.md: ship buildable with treasury and stockpile;
// when unlocking tech is required, player must have it in techUnlocked.
// For each ship type we run a scenario: capital sea-bound, treasury and stockpile, one build order, assert fleet ship count increases.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:sim_scenarios/scenario.dart';
import 'package:sim_scenarios/scenario_runner.dart';

void main() {
  group('naval units buildability', () {
    test('every naval unit can be built when resources are available', () async {
      const capitalProvinceId = 'oldWorld|p1';
      const playerId = 'gp1';

      // Default fromTopology gives initialNavalShips: 1. One build order => >= 2.
      const minFleetShipCountAfterBuild = 2;

      final runner = ScenarioRunner();
      final failures = <String>[];

      final unlockMap = unlockingTechByShipId;

      for (final entry in ShipEconomyCatalog.all) {
        final shipTypeId = entry.shipTypeId;
        final initialTech = unlockMap[shipTypeId] != null
            ? [unlockMap[shipTypeId]!]
            : <String>[];

        final stockpile = <String, int>{
          for (final e in entry.buildInputs.entries) e.key.toString(): e.value,
        };

        // Build scenario as JSON. Naval build uses capital's sea zone; grant unlocking tech when required.
        final setup = <String, dynamic>{
          'initialStockpile': {playerId: stockpile},
          'initialTreasury': {playerId: 500},
        };
        if (initialTech.isNotEmpty) {
          setup['initialTech'] = {playerId: initialTech};
        }

        final json = <String, dynamic>{
          'name': 'naval_build_$shipTypeId',
          'description':
              'Build one $shipTypeId (tech: ${initialTech.isEmpty ? "none" : initialTech.join(",")}).',
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
                  'unitType': shipTypeId,
                  'in': capitalProvinceId,
                },
              ],
            },
          ],
          'assertions': [
            {'turn': 1, 'province': capitalProvinceId, 'owner': playerId},
            {
              'turn': 1,
              'player': playerId,
              'fleetShipCount': minFleetShipCountAfterBuild,
              'matchType': 'atLeast',
            },
          ],
        };

        final scenario = parseScenarioFromJson(json);
        final result = await runner.run(scenario);
        if (!result.passed) {
          failures.add('$shipTypeId: ${result.failures.join("; ")}');
        }
      }

      expect(
        failures,
        isEmpty,
        reason: 'Ship types that failed to build: ${failures.join("\n")}',
      );
    });
  });
}
