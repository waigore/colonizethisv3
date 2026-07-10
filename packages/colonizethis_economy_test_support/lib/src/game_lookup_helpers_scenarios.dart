// dart format off
// Table-driven game lookup helper scenarios (Refs #3939 phase 3).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import 'game_lookup_helpers_expectations.dart';

/// One row in [buildProvinceIndexScenarios] (Refs #3939 slice 64).
typedef BuildProvinceIndexScenario = ({String label, Game Function() gameBuilder, BuildProvinceIndexExpectation expect, String? refs});

void runBuildProvinceIndexScenario(BuildProvinceIndexScenario scenario) {
  assertBuildProvinceIndexExpectation(buildProvinceIndex(scenario.gameBuilder()), scenario.expect);
}

/// Canonical scenarios for [buildProvinceIndex].
List<BuildProvinceIndexScenario> buildProvinceIndexScenarios() => [
  (
    label: 'indexes provinces across both regions by prefixed id',
    gameBuilder: () => TestFixtures.minimalGame(
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
          Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
        ],
      ),
      newWorld: const RegionData(
        provinces: [Province(id: 'newWorld|n1', regionId: 'newWorld')],
      ),
    ),
    expect: const BuildProvinceIndexExpectation(expectedKeys: {'oldWorld|p1', 'oldWorld|p2', 'newWorld|n1'}, regionByProvinceId: {'oldWorld|p1': 'oldWorld', 'newWorld|n1': 'newWorld'}),
    refs: '#3939',
  ),
  (label: 'empty world produces an empty index', gameBuilder: TestFixtures.minimalGame, expect: const BuildProvinceIndexExpectation(isEmpty: true), refs: '#3939'),
];

/// One row in [collectPortTileKeysScenarios] (Refs #3939 slice 64).
typedef CollectPortTileKeysScenario = ({String label, Game Function() gameBuilder, CollectPortTileKeysExpectation expect, String? refs});

void runCollectPortTileKeysScenario(CollectPortTileKeysScenario scenario) {
  assertCollectPortTileKeysExpectation(collectPortTileKeys(scenario.gameBuilder()), scenario.expect);
}

/// Canonical scenarios for [collectPortTileKeys].
List<CollectPortTileKeysScenario> collectPortTileKeysScenarios() => [
  (label: 'collects the seaboard port tile keys as a set', gameBuilder: () => TestFixtures.minimalGame(portsByProvinceSeaboard: const {'oldWorld|harbor|north': 'oldWorld|harbor|0|0', 'newWorld|harbor|south': 'newWorld|harbor|1|1'}), expect: const CollectPortTileKeysExpectation(expected: {'oldWorld|harbor|0|0', 'newWorld|harbor|1|1'}), refs: '#3939'),
  (label: 'deduplicates seaboards that map to the same tile key', gameBuilder: () => TestFixtures.minimalGame(portsByProvinceSeaboard: const {'oldWorld|harbor|north': 'oldWorld|harbor|0|0', 'oldWorld|harbor|east': 'oldWorld|harbor|0|0'}), expect: const CollectPortTileKeysExpectation(expected: {'oldWorld|harbor|0|0'}), refs: '#3939'),
  (label: 'no ports produces an empty set', gameBuilder: TestFixtures.minimalGame, expect: const CollectPortTileKeysExpectation(isEmpty: true), refs: '#3939'),
];

/// One row in [capitalFactionLookupScenarios] (Refs #3939 slice 64).
typedef CapitalFactionLookupScenario = ({String label, Game Function() gameBuilder, CapitalFactionLookupExpectation expect, String? refs});

void runCapitalFactionLookupScenario(CapitalFactionLookupScenario scenario) {
  assertCapitalFactionLookupExpectation(scenario.gameBuilder(), scenario.expect);
}

/// Canonical scenarios for [capitalProvinceIdForFaction] /
/// [capitalRegionIdForFaction].
List<CapitalFactionLookupScenario> capitalFactionLookupScenarios() => [
  (
    label: 'resolves Great Power capital province and region ids',
    gameBuilder: () => TestFixtures.minimalGame(
      players: const [
        Player(
          id: 'gp1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: 'oldWorld|p1',
          capitalTile: CapitalTile(regionId: 'oldWorld', provinceId: 'oldWorld|p1', x: 0, y: 0),
        ),
      ],
    ),
    expect: const CapitalFactionLookupExpectation(pins: [(factionId: 'gp1', provinceId: 'oldWorld|p1', regionId: 'oldWorld')]),
    refs: '#3939',
  ),
  (
    label: 'resolves minor and tribe capital ids',
    gameBuilder: () => TestFixtures.minimalGame(
      minorNations: const [
        MinorNation(
          id: 'm1',
          displayName: 'Minor',
          capitalProvinceId: 'oldWorld|m1',
          capitalTile: CapitalTile(regionId: 'oldWorld', provinceId: 'oldWorld|m1', x: 1, y: 0),
        ),
      ],
      tribes: const [
        Tribe(
          id: 't1',
          displayName: 'Tribe',
          capitalProvinceId: 'newWorld|t1',
          capitalTile: CapitalTile(regionId: 'newWorld', provinceId: 'newWorld|t1', x: 0, y: 1),
        ),
      ],
    ),
    expect: const CapitalFactionLookupExpectation(pins: [(factionId: 'm1', provinceId: 'oldWorld|m1', regionId: 'oldWorld'), (factionId: 't1', provinceId: 'newWorld|t1', regionId: 'newWorld')]),
    refs: '#3939',
  ),
  (label: 'unknown faction id returns null capital ids', gameBuilder: TestFixtures.minimalGame, expect: const CapitalFactionLookupExpectation(pins: [(factionId: 'missing', provinceId: null, regionId: null)]), refs: '#3939'),
];
// dart format on
