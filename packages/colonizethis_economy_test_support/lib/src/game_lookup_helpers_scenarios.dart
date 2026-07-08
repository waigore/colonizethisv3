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

/// One row in [capitalFactionLookupScenarios].
class CapitalFactionLookupScenario implements RefsScenario {
  const CapitalFactionLookupScenario({
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

void runCapitalFactionLookupScenario(CapitalFactionLookupScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for [capitalProvinceIdForFaction] /
/// [capitalRegionIdForFaction].
List<CapitalFactionLookupScenario> capitalFactionLookupScenarios() => [
      CapitalFactionLookupScenario(
        label: 'resolves Great Power capital province and region ids',
        run: () {
          final game = TestFixtures.minimalGame(
            players: const [
              Player(
                id: 'gp1',
                displayName: 'Spain',
                isHuman: true,
                capitalProvinceId: 'oldWorld|p1',
                capitalTile: CapitalTile(
                  regionId: 'oldWorld',
                  provinceId: 'oldWorld|p1',
                  x: 0,
                  y: 0,
                ),
              ),
            ],
          );
          expect(capitalProvinceIdForFaction(game, 'gp1'), 'oldWorld|p1');
          expect(capitalRegionIdForFaction(game, 'gp1'), 'oldWorld');
        },
        refs: '#3939',
      ),
      CapitalFactionLookupScenario(
        label: 'resolves minor and tribe capital ids',
        run: () {
          final game = TestFixtures.minimalGame(
            minorNations: const [
              MinorNation(
                id: 'm1',
                displayName: 'Minor',
                capitalProvinceId: 'oldWorld|m1',
                capitalTile: CapitalTile(
                  regionId: 'oldWorld',
                  provinceId: 'oldWorld|m1',
                  x: 1,
                  y: 0,
                ),
              ),
            ],
            tribes: const [
              Tribe(
                id: 't1',
                displayName: 'Tribe',
                capitalProvinceId: 'newWorld|t1',
                capitalTile: CapitalTile(
                  regionId: 'newWorld',
                  provinceId: 'newWorld|t1',
                  x: 0,
                  y: 1,
                ),
              ),
            ],
          );
          expect(capitalProvinceIdForFaction(game, 'm1'), 'oldWorld|m1');
          expect(capitalRegionIdForFaction(game, 'm1'), 'oldWorld');
          expect(capitalProvinceIdForFaction(game, 't1'), 'newWorld|t1');
          expect(capitalRegionIdForFaction(game, 't1'), 'newWorld');
        },
        refs: '#3939',
      ),
      CapitalFactionLookupScenario(
        label: 'unknown faction id returns null capital ids',
        run: () {
          final game = TestFixtures.minimalGame();
          expect(capitalProvinceIdForFaction(game, 'missing'), isNull);
          expect(capitalRegionIdForFaction(game, 'missing'), isNull);
        },
        refs: '#3939',
      ),
    ];
