// Table-driven non-GP extraction scenarios (Refs #3836, #3939 slice 46 / 58).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
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

  final String label;
  final Game game;
  final Map<String, TileMapResult> tileMapByRegion;
  final Map<String, ConnectivityResult> connectivityByFactionId;
  final void Function(Map<String, Map<CommodityId, int>> result) verify;
  final String? refs;
}

NonGpExtractionScenario _nonGpRow({
  required String label,
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, ConnectivityResult> connectivityByFactionId,
  required NonGpExtractionExpectation expect,
  String? refs,
}) => NonGpExtractionScenario(
  label: label,
  game: game,
  tileMapByRegion: tileMapByRegion,
  connectivityByFactionId: connectivityByFactionId,
  verify: (result) => assertNonGpExtractionExpectation(result, expect),
  refs: refs,
);

void runNonGpExtractionScenario(NonGpExtractionScenario scenario) {
  final result = computeNonGreatPowerExtraction(
    game: scenario.game,
    tileMapByRegion: scenario.tileMapByRegion,
    connectivityByFactionId: scenario.connectivityByFactionId,
  );
  scenario.verify(result);
}

/// Compact minor `m1` OW extraction row (Refs #3939 slice 47 / 57 / 58).
NonGpExtractionScenario nonGpMinorRow({
  required String label,
  required NonGpExtractionExpectation expect,
  required List<List<Resource?>> resources,
  required Set<String> connected,
  List<TileImprovementSpec> tileSpecs = const [],
  int townDev = 1,
  int width = 2,
  int height = 2,
  int capitalTileGrainBonusPerTurn = 0,
  String? refs,
}) => _nonGpRow(
  label: label,
  game: nonGpMinorM1Game(
    tileSpecs: tileSpecs,
    townDev: townDev,
    capitalTileGrainBonusPerTurn: capitalTileGrainBonusPerTurn,
  ),
  tileMapByRegion: {
    'oldWorld': nonGpProvMap('oldWorld|m1', width, height, resources),
  },
  connectivityByFactionId: connectivityByFaction({'m1': connected}),
  expect: expect,
  refs: refs,
);

/// SPEC-AC happy paths from `non_gp_extraction_test.dart`.
List<NonGpExtractionScenario> nonGpExtractionSpecAcScenarios() => [
  nonGpMinorRow(
    label: 'minor with non-mineral connected tile produces 1 unit at imp=1',
    tileSpecs: const [TileImprovementSpec('oldWorld|m1|1|0', 1, 1)],
    resources: [
      [null, Resource.grain],
      [null, null],
    ],
    connected: {'oldWorld|m1|1|0'},
    expect: const NonGpExtractionExpectation(
      factionTotals: {
        'm1': {'grain': 1},
      },
    ),
    refs: '#2991',
  ),
  nonGpMinorRow(
    label:
        'tech cap clamps higher-improvement non-mineral tile to 1 unit '
        '(SPEC AC: defaultExtractionCap = 1, applied before transport/town)',
    townDev: 4,
    tileSpecs: const [TileImprovementSpec('oldWorld|m1|1|0', 4, 4)],
    resources: [
      [null, Resource.grain],
      [null, null],
    ],
    connected: {'oldWorld|m1|1|0'},
    expect: const NonGpExtractionExpectation(
      factionTotals: {
        'm1': {'grain': 1},
      },
    ),
    refs: '#2991',
  ),
  _nonGpRow(
    label:
        'mineral resources on non-GP tiles are unconditionally excluded '
        '(SPEC AC: tribes/minors never prospect)',
    game: nonGpTribeNwGame(
      tileSpecs: const [
        TileImprovementSpec('newWorld|t1|1|0', 4, 4),
        TileImprovementSpec('newWorld|t1|1|1', 1, 1),
      ],
    ),
    tileMapByRegion: {
      'newWorld': nonGpProvMap('newWorld|t1', 2, 2, [
        [null, Resource.iron],
        [null, Resource.grain],
      ]),
    },
    connectivityByFactionId: connectivityByFaction({
      't1': {'newWorld|t1|1|0', 'newWorld|t1|1|1'},
    }),
    expect: const NonGpExtractionExpectation(
      factionTotals: {
        't1': {'grain': 1},
      },
      excludesCommodity: ('t1', 'iron'),
    ),
    refs: '#2991',
  ),
  nonGpMinorRow(
    label:
        'capital-tile grain bonus is NOT applied to non-GP totals '
        '(SPEC AC: Great-Power-only rule)',
    capitalTileGrainBonusPerTurn: 5,
    width: 1,
    height: 1,
    resources: const [
      [null],
    ],
    connected: const <String>{},
    expect: const NonGpExtractionExpectation(absentFaction: 'm1'),
    refs: '#2991',
  ),
  nonGpMinorRow(
    label:
        'non-GP output is land-only (SPEC AC: no overseas bucket, no GP-side '
        'side-effects on Player.stockpile)',
    width: 1,
    height: 1,
    tileSpecs: const [TileImprovementSpec('oldWorld|m1|0|0', 1, 1)],
    resources: const [
      [Resource.timber],
    ],
    connected: {'oldWorld|m1|0|0'},
    expect: const NonGpExtractionExpectation(
      factionTotals: {
        'm1': {'timber': 1},
      },
      factionCommodityKeyCount: ('m1', 1),
    ),
    refs: '#2991',
  ),
];

/// Boundary / multi-faction cases from `non_gp_extraction_test.dart`.
List<NonGpExtractionScenario> nonGpExtractionBoundaryScenarios() => [
  ..._nonGpExtractionBoundarySkipScenarios(),
  ..._nonGpExtractionBoundaryAggregationScenarios(),
];

List<NonGpExtractionScenario> _nonGpExtractionBoundarySkipScenarios() => [
  _nonGpRow(
    label:
        'empty minors and tribes lists yield an empty result and skip lookups',
    game: nonGpEmptyGame(),
    tileMapByRegion: const <String, TileMapResult>{},
    connectivityByFactionId: const <String, ConnectivityResult>{},
    expect: const NonGpExtractionExpectation(empty: true),
    refs: '#2991',
  ),
  _nonGpRow(
    label:
        'empty tileMapByRegion short-circuits even when minors/tribes present',
    game: nonGpMinorM1Game(),
    tileMapByRegion: const <String, TileMapResult>{},
    connectivityByFactionId: connectivityByFaction({
      'm1': {'oldWorld|m1|1|0'},
    }),
    expect: const NonGpExtractionExpectation(empty: true),
    refs: '#2991',
  ),
  _nonGpRow(
    label:
        'minor without capitalProvinceId or capitalTile is skipped silently '
        '(no throw, no entry in output)',
    game: gameForNonGpExtractionTest(
      provinces: const [],
      minorNations: const [
        MinorNation(id: 'm1'),
        MinorNation(id: 'm2', capitalProvinceId: 'oldWorld|m2'),
      ],
    ),
    tileMapByRegion: {
      'oldWorld': nonGpProvMap('oldWorld|m2', 1, 1, const [
        [Resource.grain],
      ]),
    },
    connectivityByFactionId: connectivityByFaction({
      'm1': {'oldWorld|m1|0|0'},
      'm2': {'oldWorld|m2|0|0'},
    }),
    expect: const NonGpExtractionExpectation(empty: true),
    refs: '#2991',
  ),
  _nonGpRow(
    label:
        'minor with capital but no connectivity entry in the input is skipped',
    game: nonGpMinorM1Game(
      tileSpecs: const [TileImprovementSpec('oldWorld|m1|0|0', 1, 1)],
    ),
    tileMapByRegion: {
      'oldWorld': nonGpProvMap('oldWorld|m1', 1, 1, const [
        [Resource.grain],
      ]),
    },
    connectivityByFactionId: const <String, ConnectivityResult>{},
    expect: const NonGpExtractionExpectation(empty: true),
    refs: '#2991',
  ),
  nonGpMinorRow(
    label:
        'tile with road level 0 (no transport path) yields 0 even when listed '
        'as connected and improved',
    tileSpecs: const [TileImprovementSpec('oldWorld|m1|1|0', 1)],
    resources: [
      [null, Resource.timber],
      [null, null],
    ],
    connected: {'oldWorld|m1|1|0'},
    expect: const NonGpExtractionExpectation(empty: true),
    refs: '#2991',
  ),
];

List<NonGpExtractionScenario> _nonGpExtractionBoundaryAggregationScenarios() {
  final dual = nonGpMinorTribeTimberFursFixture();
  return [
    _nonGpRow(
      label:
          'minor and tribe in the same Game both produce per-faction totals '
          'keyed by their ids',
      game: dual.game,
      tileMapByRegion: dual.tileMapByRegion,
      connectivityByFactionId: dual.connectivityByFactionId,
      expect: const NonGpExtractionExpectation(
        factionKeysUnordered: ['m1', 't1'],
        factionTotals: {
          'm1': {'timber': 1},
          't1': {'furs': 1},
        },
      ),
      refs: '#2991',
    ),
    nonGpMinorRow(
      label:
          'aggregates multiple connected non-mineral tiles of the same commodity '
          'into a single per-faction total',
      width: 3,
      height: 1,
      tileSpecs: const [
        TileImprovementSpec('oldWorld|m1|0|0', 1, 1),
        TileImprovementSpec('oldWorld|m1|1|0', 1, 1),
        TileImprovementSpec('oldWorld|m1|2|0', 1, 1),
      ],
      resources: const [
        [Resource.grain, Resource.grain, Resource.timber],
      ],
      connected: {'oldWorld|m1|0|0', 'oldWorld|m1|1|0', 'oldWorld|m1|2|0'},
      expect: const NonGpExtractionExpectation(
        factionTotals: {
          'm1': {'grain': 2, 'timber': 1},
        },
      ),
      refs: '#2991',
    ),
    nonGpMinorRow(
      label:
          'capital province at minimum town development level 1 caps yield to 1',
      width: 2,
      height: 1,
      townDev: 1,
      tileSpecs: const [TileImprovementSpec('oldWorld|m1|1|0', 1, 1)],
      resources: const [
        [null, Resource.timber],
      ],
      connected: {'oldWorld|m1|1|0'},
      expect: const NonGpExtractionExpectation(
        factionTotals: {
          'm1': {'timber': 1},
        },
      ),
      refs: '#2991 #3870',
    ),
  ];
}
