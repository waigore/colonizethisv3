// dart format off
// Table-driven GP resource-extraction scenarios (Refs #3836).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:logger/logger.dart';

import 'extraction_fixture_support.dart';
import 'resource_extractor_expectations.dart';

/// One row for `computeExtraction` scenario tables on the standard single-player
/// `resourceExtractorGame` setup.
typedef ResourceExtractorScenario = ({String label, TileMapResult? tileMap, Map<String, TileMapResult>? tileMapByRegion, List<List<String>>? grid, List<List<Resource?>>? resourceGrid, String regionId, List<TileImprovementSpec> tileSpecs, Set<String> connected, Map<String, int> pathTransportCap, int townDevelopmentLevel, Map<String, bool>? techUnlocked, Map<String, Set<String>>? playerProspectedTiles, int techCap, int Function(String playerId)? techCapForPlayer, bool useOverseasGame, Game? gameOverride, Game Function(TileMapState tileState)? gameForTileState, Map<String, ConnectivityResult>? connectivityByPlayer, TechCapComparisonPin? techCapComparisonPin, BlockadedOverseasPin? blockadedOverseasPin, String? expectLogMessageContains, void Function(Map<String, ExtractionTotals> result) verify, String? refs});

void _noopResourceExtractorVerify(Map<String, ExtractionTotals> _) {}

const _p1Grid2x2 = [
  ['p1', 'p1'],
  ['p1', 'p1'],
];

/// Issue #3836 DSL entry point — builds a [ResourceExtractorScenario] from
/// grid/improvement inputs and a land-bucket expectation map
/// (Refs #3939 slice 60 — absorbs former `_extractorRow`).
ResourceExtractorScenario extractionScenario({
  required String label,
  List<List<String>>? grid,
  List<List<Resource?>>? resourceGrid,
  TileMapResult? tileMap,
  Map<String, TileMapResult>? tileMapByRegion,
  List<TileImprovementSpec> improvements = const [],
  Set<String> connected = const {},
  int techCap = 4,
  Map<String, int>? expectLand,
  Map<String, int>? expectOverseas,
  bool expectOverseasEmpty = false,
  bool expectLandEmpty = false,
  List<String> landAbsent = const [],
  int townDevelopmentLevel = 4,
  Map<String, bool>? techUnlocked,
  Map<String, Set<String>>? playerProspectedTiles,
  Map<String, int> pathTransportCap = const {},
  Map<String, bool>? techCapPinUnlocked,
  int? techCapPinExpected,
  int Function(String playerId)? techCapForPlayer,
  bool useOverseasGame = false,
  Game? gameOverride,
  Game Function(TileMapState tileState)? gameForTileState,
  Map<String, ConnectivityResult>? connectivityByPlayer,
  String? expectLogMessageContains,
  TechCapComparisonPin? techCapComparisonPin,
  BlockadedOverseasPin? blockadedOverseasPin,
  ResourceExtractorExpectation? expect,
  String? refs,
}) {
  final resolvedExpect = expect ?? ResourceExtractorExpectation(land: expectLand ?? const {}, overseas: expectOverseas ?? const {}, landEmpty: expectLandEmpty, overseasEmpty: expectOverseasEmpty, landAbsent: landAbsent, techCapPinUnlocked: techCapPinUnlocked, techCapPinExpected: techCapPinExpected);
  final pinOnly = techCapComparisonPin != null || blockadedOverseasPin != null;
  return (label: label, tileMap: tileMap, tileMapByRegion: tileMapByRegion, grid: grid, resourceGrid: resourceGrid, regionId: 'oldWorld', tileSpecs: improvements, connected: connected, pathTransportCap: pathTransportCap, townDevelopmentLevel: townDevelopmentLevel, techUnlocked: techUnlocked, playerProspectedTiles: playerProspectedTiles, techCap: techCap, techCapForPlayer: techCapForPlayer, useOverseasGame: useOverseasGame, gameOverride: gameOverride, gameForTileState: gameForTileState, connectivityByPlayer: connectivityByPlayer, techCapComparisonPin: techCapComparisonPin, blockadedOverseasPin: blockadedOverseasPin, expectLogMessageContains: expectLogMessageContains, refs: refs, verify: pinOnly ? _noopResourceExtractorVerify : (result) => assertResourceExtractorExpectation(result, resolvedExpect));
}

Map<String, TileMapResult> _tileMapByRegionFor(ResourceExtractorScenario scenario) {
  if (scenario.tileMapByRegion != null) return scenario.tileMapByRegion!;
  final resolved = scenario.tileMap ?? tileMapFromGrids(grid: scenario.grid!, resourceGrid: scenario.resourceGrid!);
  return {scenario.regionId: resolved};
}

Game _gameFor(ResourceExtractorScenario scenario, TileMapState tileState) {
  if (scenario.gameOverride != null) return scenario.gameOverride!;
  final lazy = scenario.gameForTileState;
  if (lazy != null) return lazy(tileState);
  if (scenario.useOverseasGame) {
    return overseasResourceExtractorGame(tileState: tileState);
  }
  return resourceExtractorGame(tileState: tileState, townDevelopmentLevel: scenario.townDevelopmentLevel, techUnlocked: scenario.techUnlocked, playerProspectedTiles: scenario.playerProspectedTiles);
}

void runResourceExtractorScenario(ResourceExtractorScenario scenario) {
  final tileState = tileStateFromSpecs(scenario.tileSpecs);
  final tileMapByRegion = _tileMapByRegionFor(scenario);
  final game = _gameFor(scenario, tileState);
  if (scenario.blockadedOverseasPin != null) {
    assertBlockadedOverseasPin(game: game, tileMapByRegion: tileMapByRegion, pin: scenario.blockadedOverseasPin!);
    return;
  }
  final captured = scenario.expectLogMessageContains != null ? <LogEvent>[] : null;
  void Function(LogEvent)? listener;
  if (captured != null) {
    listener = captured.add;
    Logger.addLogListener(listener);
    Logger.level = Level.error;
  }
  try {
    final connectivity = scenario.connectivityByPlayer ?? connectivityFor(scenario.connected, pathTransportCap: scenario.pathTransportCap);
    if (scenario.techCapComparisonPin != null) {
      assertTechCapComparisonPin(game: game, tileMapByRegion: tileMapByRegion, connectivityResult: connectivity, pin: scenario.techCapComparisonPin!);
      return;
    }
    final result = computeExtraction(game: game, tileMapByRegion: tileMapByRegion, connectivityResult: connectivity, techCapForPlayer: scenario.techCapForPlayer ?? ((_) => scenario.techCap));
    scenario.verify(result);
    if (captured != null) {
      expect(captured.any((e) => e.message.contains(scenario.expectLogMessageContains!)), isTrue);
    }
  } finally {
    if (listener != null) {
      Logger.removeLogListener(listener);
      Logger.level = Level.off;
    }
  }
}

/// Scenarios from `resource_extractor_part1_segment1_test.dart`.
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

/// Scenarios from `resource_extractor_part1_segment2_test.dart`.
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

/// Scenarios from `resource_extractor_part2_part2_test.dart` (empty connectivity).
List<ResourceExtractorScenario> resourceExtractorEmptyConnectivityScenarios() => [extractionScenario(label: 'returns empty ExtractionTotals when player has no connected tiles', tileMapByRegion: const {}, expectLandEmpty: true, expectOverseasEmpty: true)];

/// Overseas / town-rule / capital / blockade / missing-province special cases
/// (Refs #3939 slice 57 / 60 — formerly one-shot factories + `_extractorRow`).
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
