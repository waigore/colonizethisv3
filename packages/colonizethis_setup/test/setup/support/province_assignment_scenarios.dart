// Scenario table densify (Refs #4349 Slice C).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'scenario_runner.dart';

import 'province_assignment_more_scenarios.dart';

List<RunnableScenario> provinceAssignmentScenarios() => [
  rs('divides evenly', () {
    final result = computeFairTargets(['a', 'b', 'c'], 9);
    expect(result, {'a': 3, 'b': 3, 'c': 3});
  }),
  rs('distributes remainders to earlier factions', () {
    final result = computeFairTargets(['a', 'b', 'c'], 10);
    expect(result, {'a': 4, 'b': 3, 'c': 3});
  }),
  rs('distributes two remainders', () {
    final result = computeFairTargets(['a', 'b', 'c'], 11);
    expect(result, {'a': 4, 'b': 4, 'c': 3});
  }),
  rs('single faction gets all', () {
    final result = computeFairTargets(['x'], 7);
    expect(result, {'x': 7});
  }),
  rs('empty factions returns empty map', () {
    final result = computeFairTargets([], 10);
    expect(result, isEmpty);
  }),
  rs('zero total gives all zeros', () {
    final result = computeFairTargets(['a', 'b'], 0);
    expect(result, {'a': 0, 'b': 0});
  }),
  rs('one faction one candidate in available assigns seed', () {
    final available = {'p1'};
    final seeds = pickSimpleSeeds(
      factionIds: ['f1'],
      candidateIds: ['p1'],
      available: available,
    );
    expect(seeds, {'p1': 'f1'});
  }),
  rs('last faction wins when candidates are not consumed', () {
    // pickSimpleSeeds does not remove assigned candidates from available,
    // so repeated iterations overwrite the same seed. The downstream
    // BFS algorithm compensates for seedless factions.
    final available = {'p1', 'p2', 'p3', 'p4'};
    final seeds = pickSimpleSeeds(
      factionIds: ['f1', 'f2'],
      candidateIds: ['p1', 'p2', 'p3'],
      available: available,
    );
    expect(seeds.length, 1);
    expect(seeds['p1'], 'f2');
  }),
  rs('single faction gets one seed', () {
    final available = {'p2', 'p3'};
    final seeds = pickSimpleSeeds(
      factionIds: ['f1'],
      candidateIds: ['p1', 'p2', 'p3'],
      available: available,
    );
    expect(seeds, {'p2': 'f1'});
  }),
  ...provinceAssignmentScenariosMore(),
];
