// Pre-combat index scenarios (Refs #4196 slice C).

import 'package:colonizethis_combat/src/combat/pre_combat_index.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'pre_combat_index_test_support.dart';
import 'scenario_runner.dart';

const _ow = preCombatIndexOldWorldRegionId;

List<RunnableScenario> provincesByIdIndexScenarios() => [
  RunnableScenario(
    scenarioId: 'pci-provinces-by-id',
    label: 'maps each province id to its province',
    run: () {
      const region = RegionData(
        provinces: [
          Province(id: '$_ow|p1', regionId: _ow, ownerId: 'p1'),
          Province(id: '$_ow|p2', regionId: _ow, ownerId: 'p2'),
        ],
      );
      final index = provincesByIdIndex(region);
      expect(index.keys.toSet(), {'$_ow|p1', '$_ow|p2'});
      expect(index['$_ow|p1']!.ownerId, 'p1');
    },
  ),
];
