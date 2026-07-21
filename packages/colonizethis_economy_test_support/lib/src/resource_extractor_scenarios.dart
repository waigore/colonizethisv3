// dart format off
// Table-driven GP resource-extraction scenarios (Refs #3836, #4108 slice B).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'extraction_fixture_support.dart';
import 'resource_extractor_expectations.dart';
import 'resource_extractor_scenario_runner.dart';
export 'resource_extractor_scenario_runner.dart';
const _p1Grid2x2 = [
  ['p1', 'p1'],
  ['p1', 'p1'],
];
List<ResourceExtractorScenario> resourceExtractorConnectivityCapScenarios({required TileMapResult grainTileMap}) => [
  extractionScenario(
    label: 'stub connectivity: land totals and tech cap applied',
    grid: _p1Grid2x2,
    resourceGrid: const [
      [Resource.grain, Resource.timber],
      [Resource.iron, null],
    ],
    improvements: [owP1Imp(3, 2), const TileImprovementSpec('oldWorld|p1|1|0', 2, 1), const TileImprovementSpec('oldWorld|p1|0|1', 4)],
    connected: {kOwP1Tile00, 'oldWorld|p1|1|0', 'oldWorld|p1|0|1'},
    expectLand: const {'grain': 2, 'timber': 1},
    landAbsent: const ['iron'],
    expectOverseasEmpty: true,
  ),
  extractionScenario(label: 'effective extraction capped by transport level', tileMap: grainTileMap, improvements: [owP1Imp(4, 1)], connected: {kOwP1Tile00}, expectLand: const {'grain': 1}),
  extractionScenario(label: 'tech cap from extractionCapForUnlocked matches turn_resolver wiring', tileMap: grainTileMap, improvements: [owP1Imp(4, 4)], connected: {kOwP1Tile00}, techUnlocked: const {kTechIdSawMill: true, kTechIdSeedDrill: true}, techCapForPlayer: (_) => extractionCapForUnlocked(const {kTechIdSawMill: true, kTechIdSeedDrill: true}), expectLand: const {'grain': 3}, techCapPinUnlocked: const {kTechIdSawMill: true, kTechIdSeedDrill: true}, techCapPinExpected: 3, refs: '#3661'),
];
const _p1FourTiles = {kOwP1Tile00, 'oldWorld|p1|1|0', 'oldWorld|p1|0|1', 'oldWorld|p1|1|1'};
List<ResourceExtractorScenario> resourceExtractorMineralTownDevScenarios({required TileMapResult ironTileMap, required TileMapResult grainTileMap}) => [
  extractionScenario(
    label: 'extracts wool and copper when present on tile map',
    grid: _p1Grid2x2,
    resourceGrid: const [
      [Resource.wool, Resource.copper],
      [Resource.timber, Resource.iron],
    ],
    improvements: tileImps(_p1FourTiles),
    connected: _p1FourTiles,
    playerProspectedTiles: {'pl1': _p1FourTiles},
    expectLand: const {'wool': 1, 'copper': 1, 'timber': 1, 'iron': 1},
  ),
  extractionScenario(label: 'mineral tiles without prospected are excluded from extraction', tileMap: ironTileMap, improvements: [owP1Imp(2, 2)], connected: {kOwP1Tile00}, landAbsent: const ['iron'], expectLandEmpty: true),
  extractionScenario(
    label: 'mineral from prospected tile counts in land',
    tileMap: ironTileMap,
    improvements: [owP1Imp(2, 2)],
    connected: {kOwP1Tile00},
    playerProspectedTiles: {
      'pl1': {kOwP1Tile00},
    },
    expectLand: const {'iron': 2},
  ),
  extractionScenario(label: 'effective extraction capped by province townDevelopmentLevel', tileMap: grainTileMap, improvements: [owP1Imp(4, 4)], connected: {kOwP1Tile00}, townDevelopmentLevel: 1, expectLand: const {'grain': 1}),
];
List<ResourceExtractorScenario> resourceExtractorEmptyConnectivityScenarios() => [extractionScenario(label: 'returns empty ExtractionTotals when player has no connected tiles', tileMapByRegion: const {}, expectLandEmpty: true, expectOverseasEmpty: true)];
List<ResourceExtractorScenario> resourceExtractorSpecialCaseScenarios({required TileMapResult grainTileMap}) {
  final blockade = blockadedOverseasExtractionFixture();
  return [
    extractionScenario(
      label: 'overseas totals when connected tile in different region',
      useOverseasGame: true,
      tileMapByRegion: {
        'oldWorld': singleTileMap(null),
        'newWorld': singleTileMap(Resource.sugarCane, province: 'n1'),
      },
      improvements: const [TileImprovementSpec('newWorld|n1|0|0', 1, 1)],
      connected: {'newWorld|n1|0|0'},
      expect: const ResourceExtractorExpectation(overseas: {'sugarCane': 1}, landEmpty: true),
    ),
    extractionScenario(label: 'effective yield capped by min transport level along path to capital', tileMap: grainTileMap, improvements: [owP1Imp(3, 3)], connected: {kOwP1Tile00}, pathTransportCap: const {kOwP1Tile00: 1}, expectLand: const {'grain': 1}),
    _townRuleScenario(
      label: 'town-rule-only + port: townDevelopmentLevel DOES cap yield',
      grid: const [
        ['p1', 'p1'],
        ['p1', 'p2'],
      ],
      resourceGrid: const [
        [null, null],
        [null, Resource.grain],
      ],
      p2TownTileKey: 'oldWorld|p2|0|1',
      portsByProvinceSeaboard: {'oldWorld|p2|sea1': 'oldWorld|p2|0|1'},
      expectLand: const {'grain': 2},
    ),
    _townRuleScenario(
      label: 'town-rule-only + non-port: townDevelopmentLevel does NOT cap yield',
      grid: const [
        ['p1', 'p1', 'p1'],
        ['p1', 'p2', 'p2'],
        ['p1', 'p2', 'p2'],
      ],
      resourceGrid: const [
        [null, null, null],
        [null, Resource.grain, null],
        [null, null, null],
      ],
      p2TownTileKey: 'oldWorld|p2|1|0',
      expectLand: const {'grain': 4},
    ),
    extractionScenario(
      label: 'effective extraction capped by player tech cap when improvement and transport are high',
      tileMap: grainTileMap,
      improvements: [owP1Imp(4, 4)],
      connected: {kOwP1Tile00},
      techCapComparisonPin: const TechCapComparisonPin(capsAndExpectedGrain: [(2, 2), (3, 3)]),
    ),
    extractionScenario(
      label: 'capital tile grain bonus is unconditional on connectivity',
      tileMapByRegion: const {},
      connected: const {},
      gameOverride: resourceExtractorGame(tileState: TileMapState(), capitalTileGrainBonusPerTurn: 5),
      connectivityByPlayer: connectivityFor(const {}),
      expect: const ResourceExtractorExpectation(land: {'grain': 5}, overseasEmpty: true),
    ),
    extractionScenario(
      label: 'blockaded overseas port: connectivity excludes tile so overseas extraction zero',
      gameOverride: blockade.game,
      tileMapByRegion: blockade.tileMapByRegion,
      blockadedOverseasPin: BlockadedOverseasPin(
        topology: blockade.topology,
        blockadedPortProvincesByPlayerId: {
          'pl1': {'newWorld|n1'},
        },
      ),
      refs: '#3939',
    ),
    extractionScenario(
      label: 'skips connected tile and logs when province missing from region (world-model)',
      tileMap: grainTileMap,
      improvements: [owP1Imp(2, 2)],
      connected: {kOwP1Tile00},
      gameForTileState: (tileState) => provinceMissingExtractorGame(tileState: tileState),
      expectLogMessageContains: 'extraction province missing',
      expect: const ResourceExtractorExpectation(landAbsent: ['grain'], landEmpty: true, overseasEmpty: true),
      refs: '#3939',
    ),
  ];
}
final _townRuleTileSpecs = [owP1Imp(0, 1), const TileImprovementSpec('oldWorld|p2|1|1', 4)];
ResourceExtractorScenario _townRuleScenario({required String label, required List<List<String>> grid, required List<List<Resource?>> resourceGrid, required String p2TownTileKey, required Map<String, int> expectLand, Map<String, String>? portsByProvinceSeaboard}) {
  const tileKey = 'oldWorld|p2|1|1';
  return extractionScenario(
    label: label,
    grid: grid,
    resourceGrid: resourceGrid,
    improvements: _townRuleTileSpecs,
    connected: {tileKey},
    pathTransportCap: const {tileKey: 4},
    gameForTileState: (tileState) => townRuleTwoProvinceExtractorGame(tileState: tileState, p1TownTileKey: kOwP1Tile00, p2TownTileKey: p2TownTileKey, portsByProvinceSeaboard: portsByProvinceSeaboard),
    expect: ResourceExtractorExpectation(land: expectLand),
    refs: 'SPEC/game/extraction-and-improvements.md § Extraction formula',
  );
}
// dart format on
