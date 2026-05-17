import 'dart:io';
import 'package:colonizethis_test/test.dart';


import 'package:sim_scenarios/scenario.dart';

import 'package:colonizethis_data/colonizethis_data.dart'
    show
        kTechIdOrganisedRegiments,
        kTechIdRoadConstruction,
        kTechIdWeaponCraftsmanship;
import 'package:colonizethis_logic/colonizethis_logic.dart' show kWorkTargetExplore;
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
                {'player': 'spain', 'type': 'work', 'unit': 'u2', 'workType': kWorkTargetExplore},
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

      test('parses capital assertions', () {
        final json = {
          'name': 'capital_assertions',
          'init': {'type': 'fresh', 'config': {'seed': 42}},
          'turns': [],
          'assertions': [
            {'turn': 1, 'player': 'gp1', 'capitalProvinceId': 'oldWorld|p1', 'capitalTileKey': 'oldWorld|p1|0|0'},
            {'turn': 1, 'player': 'tribe1', 'capitalProvinceId': 'newWorld|p2'},
          ],
        };

        final scenario = parseScenarioFromJson(json);

        expect(scenario.assertions[0].player, 'gp1');
        expect(scenario.assertions[0].capitalProvinceId, 'oldWorld|p1');
        expect(scenario.assertions[0].capitalTileKey, 'oldWorld|p1|0|0');
        expect(scenario.assertions[1].player, 'tribe1');
        expect(scenario.assertions[1].capitalProvinceId, 'newWorld|p2');
        expect(scenario.assertions[1].capitalTileKey, isNull);
      });

      test('parses setup initialWorkers and initialStockpile', () {
        final json = {
          'name': 'workers_setup',
          'init': {'type': 'fromTopology', 'config': {'greatPowers': ['england']}},
          'setup': {
            'initialWorkers': {
              'gp1': {'peasants': 2, 'apprentices': 0, 'journeymen': 0, 'masters': 0},
            },
            'initialStockpile': {
              'gp1': {'grain': 1, 'meat': 0},
            },
          },
          'turns': [],
          'assertions': [
            {'turn': 1, 'player': 'gp1', 'workerPeasants': 1},
            {'turn': 1, 'player': 'gp1', 'commodity': 'grain', 'stockpileCommodity': 0},
          ],
        };

        final scenario = parseScenarioFromJson(json);

        expect(scenario.setup!.initialWorkers!['gp1']!['peasants'], 2);
        expect(scenario.setup!.initialStockpile!['gp1']!['grain'], 1);
        expect(scenario.assertions[0].workerPeasants, 1);
        expect(scenario.assertions[1].commodity, 'grain');
        expect(scenario.assertions[1].stockpileCommodity, 0);
      });

      test('parses setup initialFleets', () {
        final json = {
          'name': 'fleet_setup',
          'init': {'type': 'fromTopology', 'config': {'greatPowers': ['england']}},
          'setup': {
            'initialFleets': [
              {
                'id': 'f1',
                'ownerId': 'gp1',
                'regionId': 'oldWorld',
                'seaZoneId': 'sea1',
                'shipTypeIds': ['carrack', 'fluyte'],
                'mission': 'patrol',
              },
            ],
          },
          'turns': [],
          'assertions': [],
        };

        final scenario = parseScenarioFromJson(json);
        expect(scenario.setup, isNotNull);
        expect(scenario.setup!.initialFleets, isNotNull);
        expect(scenario.setup!.initialFleets!.length, 1);
        expect(scenario.setup!.initialFleets!.first.id, 'f1');
        expect(scenario.setup!.initialFleets!.first.ownerId, 'gp1');
        expect(scenario.setup!.initialFleets!.first.shipTypeIds, ['carrack', 'fluyte']);
        expect(scenario.setup!.initialFleets!.first.mission, 'patrol');
      });

      test('parses setup productionAssignments', () {
        final json = {
          'name': 'production_setup',
          'init': {'type': 'fromTopology', 'config': {'greatPowers': ['england']}},
          'setup': {
            'productionAssignments': [
              {'recipeId': 'lumber_from_timber', 'assignedLabour': 4},
              {'recipeId': 'castIron_from_timber_iron_coal', 'assignedLabour': 5},
            ],
          },
          'turns': [],
          'assertions': [],
        };

        final scenario = parseScenarioFromJson(json);

        expect(scenario.setup!.productionAssignments!.length, 2);
        expect(scenario.setup!.productionAssignments![0].recipeId, 'lumber_from_timber');
        expect(scenario.setup!.productionAssignments![0].assignedLabour, 4);
        expect(scenario.setup!.productionAssignments![1].recipeId, 'castIron_from_timber_iron_coal');
        expect(scenario.setup!.productionAssignments![1].assignedLabour, 5);
      });

      test('parses turn with overtureDecisions (blocking human GP target)', () {
        final json = {
          'name': 'overture_decisions',
          'init': {'type': 'fresh', 'config': {'seed': 42, 'greatPowers': ['england', 'france']}},
          'turns': [
            {
              'turn': 1,
              'orders': [
                {'player': 'gp2', 'type': 'diplomatic', 'diplomaticType': 'establishOverture', 'targetFactionId': 'gp1', 'overtureStage': 'tradeConsulate'},
              ],
              'overtureDecisions': [
                {'offererGpId': 'gp2', 'targetFactionId': 'gp1', 'stage': 'tradeConsulate', 'accepted': true},
              ],
            },
          ],
          'assertions': [],
        };

        final scenario = parseScenarioFromJson(json);

        expect(scenario.turns.length, 1);
        expect(scenario.turns[0].overtureDecisions, isNotNull);
        expect(scenario.turns[0].overtureDecisions!.length, 1);
        expect(scenario.turns[0].overtureDecisions![0].offererGpId, 'gp2');
        expect(scenario.turns[0].overtureDecisions![0].targetFactionId, 'gp1');
        expect(scenario.turns[0].overtureDecisions![0].stage, 'tradeConsulate');
        expect(scenario.turns[0].overtureDecisions![0].accepted, isTrue);
      });

      test('parses turn with callToArmsDecisions', () {
        final json = {
          'name': 'cta_decisions',
          'init': {
            'type': 'fresh',
            'config': {'seed': 42, 'greatPowers': ['england', 'france']},
          },
          'turns': [
            {
              'turn': 1,
              'orders': [],
              'callToArmsDecisions': [
                {
                  'allyGpId': 'gp1',
                  'defenderGpId': 'gp2',
                  'aggressorGpId': 'gp3',
                  'accepted': false,
                },
              ],
            },
          ],
          'assertions': [],
        };

        final scenario = parseScenarioFromJson(json);

        expect(scenario.turns[0].callToArmsDecisions, isNotNull);
        expect(scenario.turns[0].callToArmsDecisions!.length, 1);
        final d = scenario.turns[0].callToArmsDecisions![0];
        expect(d.allyGpId, 'gp1');
        expect(d.defenderGpId, 'gp2');
        expect(d.aggressorGpId, 'gp3');
        expect(d.accepted, isFalse);
      });

      test('parses setup leaderKeys and assertion leaderKey', () {
        final json = {
          'name': 'leader_setup',
          'init': {'type': 'fromTopology', 'config': {'greatPowers': ['england', 'france']}},
          'setup': {
            'leaderKeys': {'gp1': 'napoleon', 'gp2': 'frederick'},
          },
          'turns': [],
          'assertions': [
            {'turn': 1, 'player': 'gp1', 'leaderKey': 'napoleon'},
            {'turn': 1, 'player': 'gp2', 'leaderKey': 'frederick'},
          ],
        };

        final scenario = parseScenarioFromJson(json);

        expect(scenario.setup!.leaderKeys!['gp1'], 'napoleon');
        expect(scenario.setup!.leaderKeys!['gp2'], 'frederick');
        expect(scenario.assertions[0].player, 'gp1');
        expect(scenario.assertions[0].leaderKey, 'napoleon');
        expect(scenario.assertions[1].player, 'gp2');
        expect(scenario.assertions[1].leaderKey, 'frederick');
      });

      test('parses setup initialTech', () {
        final json = {
          'name': 'tech_setup',
          'init': {'type': 'fromTopology', 'config': {'greatPowers': ['england']}},
          'setup': {
            'initialTech': {'gp1': [kTechIdOrganisedRegiments, kTechIdWeaponCraftsmanship]},
          },
          'turns': [],
          'assertions': [],
        };

        final scenario = parseScenarioFromJson(json);

        expect(scenario.setup!.initialTech, isNotNull);
        expect(scenario.setup!.initialTech!['gp1'], [kTechIdOrganisedRegiments, kTechIdWeaponCraftsmanship]);
      });

      test('parses assertion techUnlocked', () {
        final json = {
          'name': 'research_state',
          'init': {'type': 'fromTopology', 'config': {'greatPowers': ['england']}},
          'turns': [],
          'assertions': [
            {'turn': 1, 'player': 'gp1', 'techUnlocked': ['gathering_1', kTechIdRoadConstruction]},
          ],
        };

        final scenario = parseScenarioFromJson(json);

        expect(scenario.assertions.length, 1);
        expect(scenario.assertions[0].player, 'gp1');
        expect(scenario.assertions[0].techUnlocked, ['gathering_1', kTechIdRoadConstruction]);
      });

      test('parses assertion provinceDisplayName', () {
        final json = {
          'name': 'naming_parse',
          'init': {'type': 'fresh'},
          'assertions': [
            {'turn': 1, 'province': 'oldWorld|p1', 'provinceDisplayName': 'London'},
          ],
        };

        final scenario = parseScenarioFromJson(json);

        expect(scenario.assertions.length, 1);
        expect(scenario.assertions[0].province, 'oldWorld|p1');
        expect(scenario.assertions[0].provinceDisplayName, 'London');
      });

      test('parses setup defaultCombatMode', () {
        final json = {
          'name': 'combat_mode_setup',
          'init': {'type': 'fromTopology', 'config': {'greatPowers': ['england', 'france']}},
          'setup': {'defaultCombatMode': 'quickBattle'},
          'turns': [],
          'assertions': [],
        };

        final scenario = parseScenarioFromJson(json);

        expect(scenario.setup!.defaultCombatMode, 'quickBattle');
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
  });
}
