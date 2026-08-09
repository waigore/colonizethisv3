// Pre-combat index scenarios (Refs #4196 slice C).

import 'package:colonizethis_combat/src/combat/pre_combat_index.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'pre_combat_index_test_support.dart';
import 'scenario_runner.dart';

const _ow = preCombatIndexOldWorldRegionId;

List<RunnableScenario> unitsByProvinceIndexScenarios() => [
  RunnableScenario(
    scenarioId: 'pci-units-grouped-ordered',
    label: 'groups combat units by province, preserving region.units order',
    run: () {
      final region = RegionData(
        units: [
          Unit(
            id: 'u1',
            type: 'grenadiers',
            ownerId: 'p1',
            locationProvinceId: '$_ow|a',
          ),
          Unit(
            id: 'u2',
            type: 'grenadiers',
            ownerId: 'p1',
            locationProvinceId: '$_ow|b',
          ),
          Unit(
            id: 'u3',
            type: 'grenadiers',
            ownerId: 'p2',
            locationProvinceId: '$_ow|a',
          ),
        ],
      );
      final index = unitsByProvinceIndex(region);
      expect(index.keys.toSet(), {'$_ow|a', '$_ow|b'});
      expect(index['$_ow|a']!.map((u) => u.id).toList(), ['u1', 'u3']);
      expect(index['$_ow|b']!.map((u) => u.id).toList(), ['u2']);
    },
  ),
  RunnableScenario(
    scenarioId: 'pci-units-empty',
    label: 'returns an empty map for a region without units',
    run: () => expect(unitsByProvinceIndex(const RegionData()), isEmpty),
  ),
];
