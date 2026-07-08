// Table-driven game lookup helper scenarios (Refs #3939 phase 3).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import 'scenario_runner.dart';

/// One row in [buildProvinceIndexScenarios].
class BuildProvinceIndexScenario implements RefsScenario {
  const BuildProvinceIndexScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runBuildProvinceIndexScenario(BuildProvinceIndexScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for [buildProvinceIndex].
List<BuildProvinceIndexScenario> buildProvinceIndexScenarios() => [
      BuildProvinceIndexScenario(
        label: 'indexes provinces across both regions by prefixed id',
        run: () {
          final game = TestFixtures.minimalGame(
            oldWorld: const RegionData(
              provinces: [
                Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
                Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
              ],
            ),
            newWorld: const RegionData(
              provinces: [Province(id: 'newWorld|n1', regionId: 'newWorld')],
            ),
          );

          final index = buildProvinceIndex(game);

          expect(index.keys.toSet(), {'oldWorld|p1', 'oldWorld|p2', 'newWorld|n1'});
          expect(index['oldWorld|p1']!.regionId, 'oldWorld');
          expect(index['newWorld|n1']!.regionId, 'newWorld');
        },
        refs: '#3939',
      ),
      BuildProvinceIndexScenario(
        label: 'empty world produces an empty index',
        run: () {
          final game = TestFixtures.minimalGame();

          expect(buildProvinceIndex(game), isEmpty);
        },
        refs: '#3939',
      ),
    ];

/// One row in [collectPortTileKeysScenarios].
class CollectPortTileKeysScenario implements RefsScenario {
  const CollectPortTileKeysScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runCollectPortTileKeysScenario(CollectPortTileKeysScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for [collectPortTileKeys].
List<CollectPortTileKeysScenario> collectPortTileKeysScenarios() => [
      CollectPortTileKeysScenario(
        label: 'collects the seaboard port tile keys as a set',
        run: () {
          final game = TestFixtures.minimalGame(
            portsByProvinceSeaboard: const {
              'oldWorld|harbor|north': 'oldWorld|harbor|0|0',
              'newWorld|harbor|south': 'newWorld|harbor|1|1',
            },
          );

          expect(collectPortTileKeys(game), {
            'oldWorld|harbor|0|0',
            'newWorld|harbor|1|1',
          });
        },
        refs: '#3939',
      ),
      CollectPortTileKeysScenario(
        label: 'deduplicates seaboards that map to the same tile key',
        run: () {
          final game = TestFixtures.minimalGame(
            portsByProvinceSeaboard: const {
              'oldWorld|harbor|north': 'oldWorld|harbor|0|0',
              'oldWorld|harbor|east': 'oldWorld|harbor|0|0',
            },
          );

          expect(collectPortTileKeys(game), {'oldWorld|harbor|0|0'});
        },
        refs: '#3939',
      ),
      CollectPortTileKeysScenario(
        label: 'no ports produces an empty set',
        run: () {
          final game = TestFixtures.minimalGame();

          expect(collectPortTileKeys(game), isEmpty);
        },
        refs: '#3939',
      ),
    ];
