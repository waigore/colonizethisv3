// Table-driven non-GP extraction scenarios (Refs #3836).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'extraction_fixture_support.dart';
import 'non_gp_extraction_expectations.dart';

/// One row for `computeNonGreatPowerExtraction` scenario tables.
class NonGpExtractionScenario {
  const NonGpExtractionScenario({
    required this.label,
    required this.game,
    required this.tileMapByRegion,
    required this.connectivityByFactionId,
    required this.verify,
    this.refs,
  });

  NonGpExtractionScenario.expect({
    required String label,
    required Game game,
    required Map<String, TileMapResult> tileMapByRegion,
    required Map<String, ConnectivityResult> connectivityByFactionId,
    required NonGpExtractionExpectation expect,
    String? refs,
  }) : this(
          label: label,
          game: game,
          tileMapByRegion: tileMapByRegion,
          connectivityByFactionId: connectivityByFactionId,
          verify: (result) => assertNonGpExtractionExpectation(result, expect),
          refs: refs,
        );

  final String label;
  final Game game;
  final Map<String, TileMapResult> tileMapByRegion;
  final Map<String, ConnectivityResult> connectivityByFactionId;
  final void Function(Map<String, Map<CommodityId, int>> result) verify;
  final String? refs;
}

void runNonGpExtractionScenario(NonGpExtractionScenario scenario) {
  final result = computeNonGreatPowerExtraction(
    game: scenario.game,
    tileMapByRegion: scenario.tileMapByRegion,
    connectivityByFactionId: scenario.connectivityByFactionId,
  );
  scenario.verify(result);
}

/// SPEC-AC happy paths from `non_gp_extraction_part1_test.dart`.
List<NonGpExtractionScenario> nonGpExtractionSpecAcScenarios() => [
  NonGpExtractionScenario.expect(
    label: 'minor with non-mineral connected tile produces 1 unit at imp=1',
    game: gameForNonGpExtractionTest(
      provinces: [
        capitalProvinceForNonGpExtractionTest(provinceId: 'oldWorld|m1'),
      ],
      tileState: tileStateFromSpecs(const [
        TileImprovementSpec('oldWorld|m1|1|0', improvement: 1, roadLevel: 1),
      ]),
      minorNations: [testMinor()],
    ),
    tileMapByRegion: {
      'oldWorld': tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: 'oldWorld|m1',
        width: 2,
        height: 2,
        resources: [
          [null, Resource.grain],
          [null, null],
        ],
      ),
    },
    connectivityByFactionId: {
      'm1': ConnectivityResult(connected: {'oldWorld|m1|1|0'}),
    },
    expect: const NonGpExtractionExpectation(
      factionTotals: {'m1': {'grain': 1}},
    ),
    refs: '#2991',
  ),
  NonGpExtractionScenario.expect(
    label: 'tech cap clamps higher-improvement non-mineral tile to 1 unit '
        '(SPEC AC: defaultExtractionCap = 1, applied before transport/town)',
    game: gameForNonGpExtractionTest(
      provinces: [
        capitalProvinceForNonGpExtractionTest(
          provinceId: 'oldWorld|m1',
          townDev: 4,
        ),
      ],
      tileState: tileStateFromSpecs(const [
        TileImprovementSpec('oldWorld|m1|1|0', improvement: 4, roadLevel: 4),
      ]),
      minorNations: [testMinor()],
    ),
    tileMapByRegion: {
      'oldWorld': tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: 'oldWorld|m1',
        width: 2,
        height: 2,
        resources: [
          [null, Resource.grain],
          [null, null],
        ],
      ),
    },
    connectivityByFactionId: {
      'm1': ConnectivityResult(connected: {'oldWorld|m1|1|0'}),
    },
    expect: const NonGpExtractionExpectation(
      factionTotals: {'m1': {'grain': 1}},
    ),
    refs: '#2991',
  ),
  NonGpExtractionScenario.expect(
    label: 'mineral resources on non-GP tiles are unconditionally excluded '
        '(SPEC AC: tribes/minors never prospect)',
    game: gameForNonGpExtractionTest(
      provinces: const [],
      newWorldProvinces: [
        Province(
          id: 'newWorld|t1',
          regionId: 'newWorld',
          ownerId: 't1',
          townDevelopmentLevel: 1,
        ),
      ],
      tileState: tileStateFromSpecs(const [
        TileImprovementSpec('newWorld|t1|1|0', improvement: 4, roadLevel: 4),
        TileImprovementSpec('newWorld|t1|1|1', improvement: 1, roadLevel: 1),
      ]),
      tribes: [testTribe()],
    ),
    tileMapByRegion: {
      'newWorld': tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: 'newWorld|t1',
        width: 2,
        height: 2,
        resources: [
          [null, Resource.iron],
          [null, Resource.grain],
        ],
      ),
    },
    connectivityByFactionId: {
      't1': ConnectivityResult(
        connected: {'newWorld|t1|1|0', 'newWorld|t1|1|1'},
      ),
    },
    expect: const NonGpExtractionExpectation(
      factionTotals: {'t1': {'grain': 1}},
      excludesCommodity: ('t1', 'iron'),
    ),
    refs: '#2991',
  ),
  NonGpExtractionScenario.expect(
    label: 'capital-tile grain bonus is NOT applied to non-GP totals '
        '(SPEC AC: Great-Power-only rule)',
    game: gameForNonGpExtractionTest(
      provinces: [
        capitalProvinceForNonGpExtractionTest(provinceId: 'oldWorld|m1'),
      ],
      capitalTileGrainBonusPerTurn: 5,
      minorNations: [testMinor()],
    ),
    tileMapByRegion: {
      'oldWorld': tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: 'oldWorld|m1',
        width: 1,
        height: 1,
        resources: const [
          [null],
        ],
      ),
    },
    connectivityByFactionId: {
      'm1': ConnectivityResult(connected: const <String>{}),
    },
    expect: const NonGpExtractionExpectation(absentFaction: 'm1'),
    refs: '#2991',
  ),
  NonGpExtractionScenario.expect(
    label: 'non-GP output is land-only (SPEC AC: no overseas bucket, no GP-side '
        'side-effects on Player.stockpile)',
    game: gameForNonGpExtractionTest(
      provinces: [
        capitalProvinceForNonGpExtractionTest(provinceId: 'oldWorld|m1'),
      ],
      tileState: tileStateFromSpecs(const [
        TileImprovementSpec('oldWorld|m1|0|0', improvement: 1, roadLevel: 1),
      ]),
      minorNations: [testMinor()],
    ),
    tileMapByRegion: {
      'oldWorld': tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: 'oldWorld|m1',
        width: 1,
        height: 1,
        resources: const [
          [Resource.timber],
        ],
      ),
    },
    connectivityByFactionId: {
      'm1': ConnectivityResult(connected: {'oldWorld|m1|0|0'}),
    },
    expect: const NonGpExtractionExpectation(
      factionTotals: {'m1': {'timber': 1}},
      factionCommodityKeyCount: ('m1', 1),
    ),
    refs: '#2991',
  ),
];

/// Boundary / multi-faction cases from `non_gp_extraction_part2_test.dart`.
List<NonGpExtractionScenario> nonGpExtractionBoundaryScenarios() => [
  ..._nonGpExtractionBoundarySkipScenarios(),
  ..._nonGpExtractionBoundaryAggregationScenarios(),
];

List<NonGpExtractionScenario> _nonGpExtractionBoundarySkipScenarios() => [
  NonGpExtractionScenario.expect(
    label: 'empty minors and tribes lists yield an empty result and skip lookups',
    game: gameForNonGpExtractionTest(provinces: const []),
    tileMapByRegion: const <String, TileMapResult>{},
    connectivityByFactionId: const <String, ConnectivityResult>{},
    expect: const NonGpExtractionExpectation(empty: true),
    refs: '#2991',
  ),
  NonGpExtractionScenario.expect(
    label: 'empty tileMapByRegion short-circuits even when minors/tribes present',
    game: gameForNonGpExtractionTest(
      provinces: [
        capitalProvinceForNonGpExtractionTest(provinceId: 'oldWorld|m1'),
      ],
      minorNations: [testMinor()],
    ),
    tileMapByRegion: const <String, TileMapResult>{},
    connectivityByFactionId: {
      'm1': ConnectivityResult(connected: {'oldWorld|m1|1|0'}),
    },
    expect: const NonGpExtractionExpectation(empty: true),
    refs: '#2991',
  ),
  NonGpExtractionScenario.expect(
    label: 'minor without capitalProvinceId or capitalTile is skipped silently '
        '(no throw, no entry in output)',
    game: gameForNonGpExtractionTest(
      provinces: const [],
      minorNations: const [
        MinorNation(id: 'm1'),
        MinorNation(id: 'm2', capitalProvinceId: 'oldWorld|m2'),
      ],
    ),
    tileMapByRegion: {
      'oldWorld': tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: 'oldWorld|m2',
        width: 1,
        height: 1,
        resources: const [
          [Resource.grain],
        ],
      ),
    },
    connectivityByFactionId: {
      'm1': ConnectivityResult(connected: {'oldWorld|m1|0|0'}),
      'm2': ConnectivityResult(connected: {'oldWorld|m2|0|0'}),
    },
    expect: const NonGpExtractionExpectation(empty: true),
    refs: '#2991',
  ),
  NonGpExtractionScenario.expect(
    label: 'minor with capital but no connectivity entry in the input is skipped',
    game: gameForNonGpExtractionTest(
      provinces: [
        capitalProvinceForNonGpExtractionTest(provinceId: 'oldWorld|m1'),
      ],
      tileState: tileStateFromSpecs(const [
        TileImprovementSpec('oldWorld|m1|0|0', improvement: 1, roadLevel: 1),
      ]),
      minorNations: [testMinor()],
    ),
    tileMapByRegion: {
      'oldWorld': tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: 'oldWorld|m1',
        width: 1,
        height: 1,
        resources: const [
          [Resource.grain],
        ],
      ),
    },
    connectivityByFactionId: const <String, ConnectivityResult>{},
    expect: const NonGpExtractionExpectation(empty: true),
    refs: '#2991',
  ),
  NonGpExtractionScenario.expect(
    label: 'tile with road level 0 (no transport path) yields 0 even when listed '
        'as connected and improved',
    game: gameForNonGpExtractionTest(
      provinces: [
        capitalProvinceForNonGpExtractionTest(provinceId: 'oldWorld|m1'),
      ],
      tileState: tileStateFromSpecs(const [
        TileImprovementSpec('oldWorld|m1|1|0', improvement: 1),
      ]),
      minorNations: [testMinor()],
    ),
    tileMapByRegion: {
      'oldWorld': tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: 'oldWorld|m1',
        width: 2,
        height: 2,
        resources: [
          [null, Resource.timber],
          [null, null],
        ],
      ),
    },
    connectivityByFactionId: {
      'm1': ConnectivityResult(connected: {'oldWorld|m1|1|0'}),
    },
    expect: const NonGpExtractionExpectation(empty: true),
    refs: '#2991',
  ),
];

List<NonGpExtractionScenario> _nonGpExtractionBoundaryAggregationScenarios() => [
  NonGpExtractionScenario.expect(
    label: 'minor and tribe in the same Game both produce per-faction totals '
        'keyed by their ids',
    game: gameForNonGpExtractionTest(
      provinces: [
        capitalProvinceForNonGpExtractionTest(provinceId: 'oldWorld|m1'),
      ],
      newWorldProvinces: [
        Province(
          id: 'newWorld|t1',
          regionId: 'newWorld',
          ownerId: 't1',
          townDevelopmentLevel: 1,
        ),
      ],
      tileState: tileStateFromSpecs(const [
        TileImprovementSpec('oldWorld|m1|0|0', improvement: 1, roadLevel: 1),
        TileImprovementSpec('newWorld|t1|0|0', improvement: 1, roadLevel: 1),
      ]),
      minorNations: [testMinor()],
      tribes: [testTribe()],
    ),
    tileMapByRegion: {
      'oldWorld': tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: 'oldWorld|m1',
        width: 1,
        height: 1,
        resources: const [
          [Resource.timber],
        ],
      ),
      'newWorld': tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: 'newWorld|t1',
        width: 1,
        height: 1,
        resources: const [
          [Resource.furs],
        ],
      ),
    },
    connectivityByFactionId: {
      'm1': ConnectivityResult(connected: {'oldWorld|m1|0|0'}),
      't1': ConnectivityResult(connected: {'newWorld|t1|0|0'}),
    },
    expect: const NonGpExtractionExpectation(
      factionKeysUnordered: ['m1', 't1'],
      factionTotals: {
        'm1': {'timber': 1},
        't1': {'furs': 1},
      },
    ),
    refs: '#2991',
  ),
  NonGpExtractionScenario.expect(
    label: 'aggregates multiple connected non-mineral tiles of the same commodity '
        'into a single per-faction total',
    game: gameForNonGpExtractionTest(
      provinces: [
        capitalProvinceForNonGpExtractionTest(provinceId: 'oldWorld|m1'),
      ],
      tileState: tileStateFromSpecs(const [
        TileImprovementSpec('oldWorld|m1|0|0', improvement: 1, roadLevel: 1),
        TileImprovementSpec('oldWorld|m1|1|0', improvement: 1, roadLevel: 1),
        TileImprovementSpec('oldWorld|m1|2|0', improvement: 1, roadLevel: 1),
      ]),
      minorNations: [testMinor()],
    ),
    tileMapByRegion: {
      'oldWorld': tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: 'oldWorld|m1',
        width: 3,
        height: 1,
        resources: const [
          [Resource.grain, Resource.grain, Resource.timber],
        ],
      ),
    },
    connectivityByFactionId: {
      'm1': ConnectivityResult(
        connected: {
          'oldWorld|m1|0|0',
          'oldWorld|m1|1|0',
          'oldWorld|m1|2|0',
        },
      ),
    },
    expect: const NonGpExtractionExpectation(
      factionTotals: {
        'm1': {'grain': 2, 'timber': 1},
      },
    ),
    refs: '#2991',
  ),
  NonGpExtractionScenario.expect(
    label: 'capital province at minimum town development level 1 caps yield to 1',
    game: gameForNonGpExtractionTest(
      provinces: [
        capitalProvinceForNonGpExtractionTest(
          provinceId: 'oldWorld|m1',
          townDev: 1,
        ),
      ],
      tileState: tileStateFromSpecs(const [
        TileImprovementSpec('oldWorld|m1|1|0', improvement: 1, roadLevel: 1),
      ]),
      minorNations: [testMinor()],
    ),
    tileMapByRegion: {
      'oldWorld': tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: 'oldWorld|m1',
        width: 2,
        height: 1,
        resources: const [
          [null, Resource.timber],
        ],
      ),
    },
    connectivityByFactionId: {
      'm1': ConnectivityResult(connected: {'oldWorld|m1|1|0'}),
    },
    expect: const NonGpExtractionExpectation(
      factionTotals: {'m1': {'timber': 1}},
    ),
    refs: '#2991 #3870',
  ),
];
