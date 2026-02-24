import 'dart:io';

import 'package:colonizethis_test/test.dart';

import 'package:sim_scenarios/scenario.dart';
import 'package:sim_scenarios/scenario_runner.dart';

void main() {
  group('sim_scenarios', () {
    group('parseScenarioFromJson', () {
      test('parses fresh init scenario', () {
        final json = {
          'name': 'test_scenario',
          'description': 'Test scenario',
          'init': {
            'type': 'fresh',
            'config': {
              'seed': 12345,
              'greatPowers': ['england', 'france'],
            },
          },
          'turns': [
            {
              'turn': 1,
              'orders': [
                {'player': 'england', 'type': 'move', 'unit': 'u1', 'to': 'province1'},
              ],
            },
          ],
          'assertions': [
            {'turn': 1, 'province': 'yorkshire', 'owner': 'england'},
          ],
        };

        final scenario = parseScenarioFromJson(json);

        expect(scenario.name, 'test_scenario');
        expect(scenario.description, 'Test scenario');
        expect(scenario.init.type, 'fresh');
        expect(scenario.init.config?['seed'], 12345);
        expect(scenario.init.config?['greatPowers'], ['england', 'france']);
        expect(scenario.turns.length, 1);
        expect(scenario.turns[0].turn, 1);
        expect(scenario.turns[0].orders.length, 1);
        expect(scenario.turns[0].orders[0].player, 'england');
        expect(scenario.turns[0].orders[0].type, 'move');
        expect(scenario.assertions.length, 1);
        expect(scenario.assertions[0].province, 'yorkshire');
        expect(scenario.assertions[0].owner, 'england');
      });

      test('parses saved init scenario', () {
        final json = {
          'name': 'saved_scenario',
          'init': {
            'type': 'saved',
            'gameId': 'save_12345',
          },
          'turns': [],
          'assertions': [],
        };

        final scenario = parseScenarioFromJson(json);

        expect(scenario.init.type, 'saved');
        expect(scenario.init.gameId, 'save_12345');
      });

      test('parses scenario with setup', () {
        final json = {
          'name': 'setup_scenario',
          'init': {'type': 'fresh', 'config': {'seed': 42}},
          'setup': {
            'units': [
              {'player': 'france', 'type': 'infantry', 'province': 'normandy', 'count': 3},
            ],
          },
          'turns': [],
          'assertions': [],
        };

        final scenario = parseScenarioFromJson(json);

        expect(scenario.setup, isNotNull);
        expect(scenario.setup!.units, isNotNull);
        expect(scenario.setup!.units!.length, 1);
        expect(scenario.setup!.units![0].playerId, 'france');
        expect(scenario.setup!.units![0].provinceId, 'normandy');
        expect(scenario.setup!.units![0].count, 3);
      });

      test('parses scenario with stockpileAdditions', () {
        final json = {
          'name': 'stockpile_setup',
          'init': {'type': 'fromTopology', 'config': {'greatPowers': ['england']}},
          'setup': {
            'stockpileAdditions': {
              'gp1': {'paper': 2},
            },
          },
          'turns': [],
          'assertions': [],
        };

        final scenario = parseScenarioFromJson(json);

        expect(scenario.setup, isNotNull);
        expect(scenario.setup!.stockpileAdditions, isNotNull);
        expect(scenario.setup!.stockpileAdditions!['gp1'], {'paper': 2});
      });

      test('parses all order types', () {
        final json = {
          'name': 'order_types',
          'init': {'type': 'fresh', 'config': {'seed': 42}},
          'turns': [
            {
              'turn': 1,
              'orders': [
                {'player': 'england', 'type': 'move', 'unit': 'u1', 'to': 'p1'},
                {'player': 'france', 'type': 'build', 'unitType': 'infantry', 'in': 'p2'},
                {'player': 'spain', 'type': 'work', 'unit': 'u2', 'workType': 'explore'},
                {'player': 'portugal', 'type': 'diplomatic', 'targetFactionId': 'england', 'action': 'declare_war'},
                {'player': 'netherlands', 'type': 'research', 'techId': 'tech1'},
                {'player': 'prussia', 'type': 'naval_move', 'fleetId': 'f1', 'destinationSeaZoneId': 'sz1'},
                {'player': 'england', 'type': 'naval_mission', 'fleetId': 'f2', 'mission': 'patrol'},
              ],
            },
          ],
          'assertions': [],
        };

        final scenario = parseScenarioFromJson(json);
        final orders = scenario.turns[0].orders;

        expect(orders[0].type, 'move');
        expect(orders[1].type, 'build');
        expect(orders[2].type, 'work');
        expect(orders[3].type, 'diplomatic');
        expect(orders[4].type, 'research');
        expect(orders[5].type, 'naval_move');
        expect(orders[6].type, 'naval_mission');
      });

      test('parses assertions with all match types', () {
        final json = {
          'name': 'match_types',
          'init': {'type': 'fresh', 'config': {'seed': 42}},
          'turns': [],
          'assertions': [
            {'turn': 1, 'province': 'p1', 'unitCount': 5},
            {'province': 'p2', 'unitCount': 3, 'matchType': 'atLeast'},
            {'province': 'p3', 'unitCount': 10, 'matchType': 'atMost'},
            {'province': 'p4', 'unitCount': 0, 'matchType': 'range', 'matchMin': 0, 'matchMax': 5},
          ],
        };

        final scenario = parseScenarioFromJson(json);

        expect(scenario.assertions[0].matchType, MatchType.exact);
        expect(scenario.assertions[1].matchType, MatchType.atLeast);
        expect(scenario.assertions[2].matchType, MatchType.atMost);
        expect(scenario.assertions[3].matchType, MatchType.range);
        expect(scenario.assertions[3].matchMin, 0);
        expect(scenario.assertions[3].matchMax, 5);
      });

      test('parses assertion with capitalProvince', () {
        final json = {
          'name': 'capital_assertion',
          'init': {'type': 'fresh', 'config': {'seed': 42}},
          'turns': [],
          'assertions': [
            {'turn': 1, 'player': 'gp1', 'capitalProvince': 'oldWorld|p1'},
          ],
        };

        final scenario = parseScenarioFromJson(json);

        expect(scenario.assertions.length, 1);
        expect(scenario.assertions[0].player, 'gp1');
        expect(scenario.assertions[0].capitalProvince, 'oldWorld|p1');
      });
    });

    group('parseScenarioFile', () {
      test('parses single scenario from file', () {
        final file = File('scenarios/basic_turn_1.json');
        if (!file.existsSync()) {
          // Skip if file doesn't exist (will be created during build)
          return;
        }

        final scenarios = parseScenarioFile(file);

        expect(scenarios.length, 1);
        expect(scenarios[0].name, 'basic_turn_1');
      });
    });

    group('discoverScenarios', () {
      test('finds all JSON files in directory', () {
        final dir = Directory('scenarios');
        if (!dir.existsSync()) {
          // Skip if directory doesn't exist
          return;
        }

        final scenarios = discoverScenarios(dir);

        expect(scenarios.length, greaterThan(0));
      });
    });

    group('civilian_units_build_explorer', () {
      test('scenario passes (GDD civilian-units training cost AC)', () async {
        final file = File('scenarios/civilian_units_build_explorer.json');
        if (!file.existsSync()) {
          return;
        }
        final scenario = parseScenarioFile(file).single;
        final runner = ScenarioRunner();
        final result = await runner.run(scenario);
        if (!result.passed) {
          for (final f in result.failures) {
            print('Failure: $f');
          }
        }
        expect(result.passed, isTrue, reason: result.failures.join('; '));
      });
    });
  });
}
