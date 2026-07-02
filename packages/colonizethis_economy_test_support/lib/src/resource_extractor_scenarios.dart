// Table-driven GP resource-extraction scenarios (Refs #3836).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'resource_extractor_test_support.dart';
import 'tile_map_test_support.dart';

/// One row for `computeExtraction` scenario tables on the standard single-player
/// `resourceExtractorGame` setup.
class ResourceExtractorScenario {
  const ResourceExtractorScenario({
    required this.label,
    required this.verify,
    this.tileMap,
    this.tileMapByRegion,
    this.grid,
    this.resourceGrid,
    this.regionId = 'oldWorld',
    this.tileSpecs = const [],
    this.connected = const {},
    this.pathTransportCap = const {},
    this.townDevelopmentLevel = 4,
    this.techUnlocked,
    this.playerProspectedTiles,
    this.techCap = 4,
    this.techCapForPlayer,
    this.useOverseasGame = false,
    this.refs,
  });

  final String label;
  final TileMapResult? tileMap;
  final Map<String, TileMapResult>? tileMapByRegion;
  final List<List<String>>? grid;
  final List<List<Resource?>>? resourceGrid;
  final String regionId;
  final List<TileImprovementSpec> tileSpecs;
  final Set<String> connected;
  final Map<String, int> pathTransportCap;
  final int townDevelopmentLevel;
  final Map<String, bool>? techUnlocked;
  final Map<String, Set<String>>? playerProspectedTiles;
  final int techCap;
  final int Function(String playerId)? techCapForPlayer;
  final bool useOverseasGame;
  final void Function(Map<String, ExtractionTotals> result) verify;
  final String? refs;
}

/// Issue #3836 DSL entry point — builds a [ResourceExtractorScenario] from
/// grid/improvement inputs and a land-bucket expectation map.
ResourceExtractorScenario extractionScenario({
  required String label,
  List<List<String>>? grid,
  List<List<Resource?>>? resourceGrid,
  TileMapResult? tileMap,
  required List<TileImprovementSpec> improvements,
  required Set<String> connected,
  int techCap = 4,
  Map<String, int>? expectLand,
  Map<String, int>? expectOverseas,
  bool expectOverseasEmpty = false,
  bool expectLandEmpty = false,
  int townDevelopmentLevel = 4,
  Map<String, bool>? techUnlocked,
  Map<String, Set<String>>? playerProspectedTiles,
  Map<String, int> pathTransportCap = const {},
  String? refs,
}) {
  return ResourceExtractorScenario(
    label: label,
    grid: grid,
    resourceGrid: resourceGrid,
    tileMap: tileMap,
    tileSpecs: improvements,
    connected: connected,
    pathTransportCap: pathTransportCap,
    townDevelopmentLevel: townDevelopmentLevel,
    techUnlocked: techUnlocked,
    playerProspectedTiles: playerProspectedTiles,
    techCap: techCap,
    refs: refs,
    verify: (result) {
      final totals = result['pl1']!;
      if (expectLandEmpty) {
        expect(totals.land, isEmpty);
      }
      if (expectOverseasEmpty) {
        expect(totals.overseas, isEmpty);
      }
      expectLand?.forEach((commodity, qty) {
        expect(totals.land[commodity], qty);
      });
      expectOverseas?.forEach((commodity, qty) {
        expect(totals.overseas[commodity], qty);
      });
    },
  );
}

void runResourceExtractorScenario(ResourceExtractorScenario scenario) {
  final tileState = tileStateFromSpecs(scenario.tileSpecs);
  final game = scenario.useOverseasGame
      ? overseasResourceExtractorGame(tileState: tileState)
      : resourceExtractorGame(
          tileState: tileState,
          townDevelopmentLevel: scenario.townDevelopmentLevel,
          techUnlocked: scenario.techUnlocked,
          playerProspectedTiles: scenario.playerProspectedTiles,
        );
  final Map<String, TileMapResult> tileMapByRegion;
  if (scenario.tileMapByRegion != null) {
    tileMapByRegion = scenario.tileMapByRegion!;
  } else {
    final TileMapResult resolvedTileMap = scenario.tileMap ??
        tileMapFromGrids(
          grid: scenario.grid!,
          resourceGrid: scenario.resourceGrid!,
        );
    tileMapByRegion = {scenario.regionId: resolvedTileMap};
  }
  final result = computeExtraction(
    game: game,
    tileMapByRegion: tileMapByRegion,
    connectivityResult: connectivityFor(
      scenario.connected,
      pathTransportCap: scenario.pathTransportCap,
    ),
    techCapForPlayer:
        scenario.techCapForPlayer ?? ((_) => scenario.techCap),
  );
  scenario.verify(result);
}

/// Scenarios from `resource_extractor_part1_segment1_test.dart`.
List<ResourceExtractorScenario> resourceExtractorConnectivityCapScenarios({
  required TileMapResult grainTileMap,
}) => [
  ResourceExtractorScenario(
    label: 'stub connectivity: land totals and tech cap applied',
    grid: const [
      ['p1', 'p1'],
      ['p1', 'p1'],
    ],
    resourceGrid: const [
      [Resource.grain, Resource.timber],
      [Resource.iron, null],
    ],
    tileSpecs: const [
      TileImprovementSpec('oldWorld|p1|0|0', improvement: 3, roadLevel: 2),
      TileImprovementSpec('oldWorld|p1|1|0', improvement: 2, roadLevel: 1),
      TileImprovementSpec('oldWorld|p1|0|1', improvement: 4, roadLevel: 0),
    ],
    connected: {
      'oldWorld|p1|0|0',
      'oldWorld|p1|1|0',
      'oldWorld|p1|0|1',
    },
    verify: (result) {
      expect(result['pl1'], isNotNull);
      expect(result['pl1']!.overseas, isEmpty);
      expect(result['pl1']!.land['grain'], 2);
      expect(result['pl1']!.land['timber'], 1);
      expect(result['pl1']!.land['iron'], isNull);
    },
  ),
  extractionScenario(
    label: 'effective extraction capped by transport level',
    tileMap: grainTileMap,
    improvements: const [
      TileImprovementSpec('oldWorld|p1|0|0', improvement: 4, roadLevel: 1),
    ],
    connected: {'oldWorld|p1|0|0'},
    expectLand: const {'grain': 1},
  ),
  ResourceExtractorScenario(
    label: 'tech cap from extractionCapForUnlocked matches turn_resolver wiring',
    tileMap: grainTileMap,
    tileSpecs: const [
      TileImprovementSpec('oldWorld|p1|0|0', improvement: 4, roadLevel: 4),
    ],
    connected: {'oldWorld|p1|0|0'},
    techUnlocked: const {
      kTechIdSawMill: true,
      kTechIdSeedDrill: true,
    },
    techCapForPlayer: (playerId) => extractionCapForUnlocked(const {
      kTechIdSawMill: true,
      kTechIdSeedDrill: true,
    }),
    verify: (result) {
      expect(extractionCapForUnlocked(const {
        kTechIdSawMill: true,
        kTechIdSeedDrill: true,
      }), 3);
      expect(result['pl1']!.land['grain'], 3);
    },
    refs: '#3661',
  ),
];

/// Scenarios from `resource_extractor_part1_segment2_test.dart`.
List<ResourceExtractorScenario> resourceExtractorMineralTownDevScenarios({
  required TileMapResult ironTileMap,
  required TileMapResult grainTileMap,
}) => [
  extractionScenario(
    label: 'extracts wool and copper when present on tile map',
    grid: const [
      ['p1', 'p1'],
      ['p1', 'p1'],
    ],
    resourceGrid: const [
      [Resource.wool, Resource.copper],
      [Resource.timber, Resource.iron],
    ],
    improvements: const [
      TileImprovementSpec('oldWorld|p1|0|0', improvement: 1, roadLevel: 1),
      TileImprovementSpec('oldWorld|p1|1|0', improvement: 1, roadLevel: 1),
      TileImprovementSpec('oldWorld|p1|0|1', improvement: 1, roadLevel: 1),
      TileImprovementSpec('oldWorld|p1|1|1', improvement: 1, roadLevel: 1),
    ],
    connected: {
      'oldWorld|p1|0|0',
      'oldWorld|p1|1|0',
      'oldWorld|p1|0|1',
      'oldWorld|p1|1|1',
    },
    playerProspectedTiles: {
      'pl1': {
        'oldWorld|p1|0|0',
        'oldWorld|p1|1|0',
        'oldWorld|p1|0|1',
        'oldWorld|p1|1|1',
      },
    },
    expectLand: const {
      'wool': 1,
      'copper': 1,
      'timber': 1,
      'iron': 1,
    },
  ),
  ResourceExtractorScenario(
    label: 'mineral tiles without prospected are excluded from extraction',
    tileMap: ironTileMap,
    tileSpecs: const [
      TileImprovementSpec('oldWorld|p1|0|0', improvement: 2, roadLevel: 2),
    ],
    connected: {'oldWorld|p1|0|0'},
    verify: (result) {
      expect(result['pl1']!.land['iron'], isNull);
      expect(result['pl1']!.land, isEmpty);
    },
  ),
  extractionScenario(
    label: 'mineral from prospected tile counts in land',
    tileMap: ironTileMap,
    improvements: const [
      TileImprovementSpec('oldWorld|p1|0|0', improvement: 2, roadLevel: 2),
    ],
    connected: {'oldWorld|p1|0|0'},
    playerProspectedTiles: {
      'pl1': {'oldWorld|p1|0|0'},
    },
    expectLand: const {'iron': 2},
  ),
  extractionScenario(
    label: 'effective extraction capped by province townDevelopmentLevel',
    tileMap: grainTileMap,
    improvements: const [
      TileImprovementSpec('oldWorld|p1|0|0', improvement: 4, roadLevel: 4),
    ],
    connected: {'oldWorld|p1|0|0'},
    townDevelopmentLevel: 1,
    expectLand: const {'grain': 1},
  ),
];

/// Scenarios from `resource_extractor_part2_part2_test.dart` (empty connectivity).
List<ResourceExtractorScenario> resourceExtractorEmptyConnectivityScenarios() => [
  ResourceExtractorScenario(
    label: 'returns empty ExtractionTotals when player has no connected tiles',
    tileMapByRegion: const {},
    tileSpecs: const [],
    connected: const {},
    verify: (result) {
      expect(result['pl1']!.land, isEmpty);
      expect(result['pl1']!.overseas, isEmpty);
    },
  ),
];

/// Overseas extraction from `resource_extractor_part2_part1_test.dart`.
ResourceExtractorScenario overseasExtractionScenario() => ResourceExtractorScenario(
  label: 'overseas totals when connected tile in different region',
  useOverseasGame: true,
  tileMapByRegion: {
    'oldWorld': singleTileMap(null),
    'newWorld': singleTileMap(Resource.sugarCane, province: 'n1'),
  },
  tileSpecs: const [
    TileImprovementSpec('newWorld|n1|0|0', improvement: 1, roadLevel: 1),
  ],
  connected: {'newWorld|n1|0|0'},
  verify: (result) {
    expect(result['pl1']!.overseas['sugarCane'], 1);
    expect(result['pl1']!.land, isEmpty);
  },
);

/// Path-transport cap from `resource_extractor_part2_part1_test.dart`.
ResourceExtractorScenario pathTransportCapScenario({
  required TileMapResult grainTileMap,
}) =>
    ResourceExtractorScenario(
      label: 'effective yield capped by min transport level along path to capital',
      tileMap: grainTileMap,
      tileSpecs: const [
        TileImprovementSpec('oldWorld|p1|0|0', improvement: 3, roadLevel: 3),
      ],
      connected: {'oldWorld|p1|0|0'},
      pathTransportCap: const {'oldWorld|p1|0|0': 1},
      verify: (result) {
        expect(result['pl1']!.land['grain'], 1);
      },
    );
