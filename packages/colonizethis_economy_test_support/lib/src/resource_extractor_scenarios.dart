// Table-driven GP resource-extraction scenarios (Refs #3836).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:logger/logger.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

import 'extraction_fixture_support.dart';
import 'resource_extractor_expectations.dart';

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
    this.gameOverride,
    this.connectivityByPlayer,
    this.techCapComparisonPin,
    this.blockadedOverseasPin,
    this.expectLogMessageContains,
    this.refs,
  });

  ResourceExtractorScenario.expect({
    required String label,
    required ResourceExtractorExpectation expect,
    TileMapResult? tileMap,
    Map<String, TileMapResult>? tileMapByRegion,
    List<List<String>>? grid,
    List<List<Resource?>>? resourceGrid,
    String regionId = 'oldWorld',
    List<TileImprovementSpec> tileSpecs = const [],
    Set<String> connected = const {},
    Map<String, int> pathTransportCap = const {},
    int townDevelopmentLevel = 4,
    Map<String, bool>? techUnlocked,
    Map<String, Set<String>>? playerProspectedTiles,
    int techCap = 4,
    int Function(String playerId)? techCapForPlayer,
    bool useOverseasGame = false,
    Game? gameOverride,
    Map<String, ConnectivityResult>? connectivityByPlayer,
    TechCapComparisonPin? techCapComparisonPin,
    BlockadedOverseasPin? blockadedOverseasPin,
    String? expectLogMessageContains,
    String? refs,
  }) : this(
          label: label,
          tileMap: tileMap,
          tileMapByRegion: tileMapByRegion,
          grid: grid,
          resourceGrid: resourceGrid,
          regionId: regionId,
          tileSpecs: tileSpecs,
          connected: connected,
          pathTransportCap: pathTransportCap,
          townDevelopmentLevel: townDevelopmentLevel,
          techUnlocked: techUnlocked,
          playerProspectedTiles: playerProspectedTiles,
          techCap: techCap,
          techCapForPlayer: techCapForPlayer,
          useOverseasGame: useOverseasGame,
          gameOverride: gameOverride,
          connectivityByPlayer: connectivityByPlayer,
          techCapComparisonPin: techCapComparisonPin,
          blockadedOverseasPin: blockadedOverseasPin,
          expectLogMessageContains: expectLogMessageContains,
          refs: refs,
          verify: (result) =>
              assertResourceExtractorExpectation(result, expect),
        );

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
  final Game? gameOverride;
  final Map<String, ConnectivityResult>? connectivityByPlayer;
  final TechCapComparisonPin? techCapComparisonPin;
  final BlockadedOverseasPin? blockadedOverseasPin;
  final String? expectLogMessageContains;
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
  return ResourceExtractorScenario.expect(
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
    expect: ResourceExtractorExpectation(
      land: expectLand ?? const {},
      overseas: expectOverseas ?? const {},
      landEmpty: expectLandEmpty,
      overseasEmpty: expectOverseasEmpty,
    ),
  );
}

void runResourceExtractorScenario(ResourceExtractorScenario scenario) {
  if (scenario.blockadedOverseasPin != null) {
    final tileState = tileStateFromSpecs(scenario.tileSpecs);
    final game = scenario.gameOverride ??
        resourceExtractorGame(
          tileState: tileState,
          townDevelopmentLevel: scenario.townDevelopmentLevel,
          techUnlocked: scenario.techUnlocked,
          playerProspectedTiles: scenario.playerProspectedTiles,
        );
    final Map<String, TileMapResult> tileMapByRegion;
    if (scenario.tileMapByRegion != null) {
      tileMapByRegion = scenario.tileMapByRegion!;
    } else {
      final resolvedTileMap = scenario.tileMap ??
          tileMapFromGrids(
            grid: scenario.grid!,
            resourceGrid: scenario.resourceGrid!,
          );
      tileMapByRegion = {scenario.regionId: resolvedTileMap};
    }
    assertBlockadedOverseasPin(
      game: game,
      tileMapByRegion: tileMapByRegion,
      pin: scenario.blockadedOverseasPin!,
    );
    return;
  }
  final captured = scenario.expectLogMessageContains != null
      ? <LogEvent>[]
      : null;
  void Function(LogEvent)? listener;
  if (captured != null) {
    listener = captured.add;
    Logger.addLogListener(listener);
    Logger.level = Level.error;
  }
  try {
    final tileState = tileStateFromSpecs(scenario.tileSpecs);
    final game = scenario.gameOverride ??
        (scenario.useOverseasGame
            ? overseasResourceExtractorGame(tileState: tileState)
            : resourceExtractorGame(
                tileState: tileState,
                townDevelopmentLevel: scenario.townDevelopmentLevel,
                techUnlocked: scenario.techUnlocked,
                playerProspectedTiles: scenario.playerProspectedTiles,
              ));
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
    final connectivity = scenario.connectivityByPlayer ??
        connectivityFor(
          scenario.connected,
          pathTransportCap: scenario.pathTransportCap,
        );
    if (scenario.techCapComparisonPin != null) {
      assertTechCapComparisonPin(
        game: game,
        tileMapByRegion: tileMapByRegion,
        connectivityResult: connectivity,
        pin: scenario.techCapComparisonPin!,
      );
      return;
    }
    final result = computeExtraction(
      game: game,
      tileMapByRegion: tileMapByRegion,
      connectivityResult: connectivity,
      techCapForPlayer:
          scenario.techCapForPlayer ?? ((_) => scenario.techCap),
    );
    scenario.verify(result);
    if (captured != null) {
      expect(
        captured.any(
          (e) => e.message.contains(scenario.expectLogMessageContains!),
        ),
        isTrue,
      );
    }
  } finally {
    if (listener != null) {
      Logger.removeLogListener(listener);
      Logger.level = Level.off;
    }
  }
}

/// Scenarios from `resource_extractor_part1_segment1_test.dart`.
List<ResourceExtractorScenario> resourceExtractorConnectivityCapScenarios({
  required TileMapResult grainTileMap,
}) => [
  ResourceExtractorScenario.expect(
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
    expect: const ResourceExtractorExpectation(
      land: {'grain': 2, 'timber': 1},
      landAbsent: ['iron'],
      overseasEmpty: true,
    ),
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
  ResourceExtractorScenario.expect(
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
    expect: ResourceExtractorExpectation(
      land: const {'grain': 3},
      techCapPinUnlocked: const {
        kTechIdSawMill: true,
        kTechIdSeedDrill: true,
      },
      techCapPinExpected: 3,
    ),
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
  ResourceExtractorScenario.expect(
    label: 'mineral tiles without prospected are excluded from extraction',
    tileMap: ironTileMap,
    tileSpecs: const [
      TileImprovementSpec('oldWorld|p1|0|0', improvement: 2, roadLevel: 2),
    ],
    connected: {'oldWorld|p1|0|0'},
    expect: const ResourceExtractorExpectation(
      landAbsent: ['iron'],
      landEmpty: true,
    ),
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
  ResourceExtractorScenario.expect(
    label: 'returns empty ExtractionTotals when player has no connected tiles',
    tileMapByRegion: const {},
    tileSpecs: const [],
    connected: const {},
    expect: const ResourceExtractorExpectation(
      landEmpty: true,
      overseasEmpty: true,
    ),
  ),
];

/// Overseas extraction from `resource_extractor_part2_part1_test.dart`.
ResourceExtractorScenario overseasExtractionScenario() =>
    ResourceExtractorScenario.expect(
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
      expect: const ResourceExtractorExpectation(
        overseas: {'sugarCane': 1},
        landEmpty: true,
      ),
    );

/// Path-transport cap from `resource_extractor_part2_part1_test.dart`.
ResourceExtractorScenario pathTransportCapScenario({
  required TileMapResult grainTileMap,
}) =>
    ResourceExtractorScenario.expect(
      label: 'effective yield capped by min transport level along path to capital',
      tileMap: grainTileMap,
      tileSpecs: const [
        TileImprovementSpec('oldWorld|p1|0|0', improvement: 3, roadLevel: 3),
      ],
      connected: {'oldWorld|p1|0|0'},
      pathTransportCap: const {'oldWorld|p1|0|0': 1},
      expect: const ResourceExtractorExpectation(
        land: {'grain': 1},
      ),
    );

/// Town-rule + port cap from `resource_extractor_part2_part1_test.dart`.
ResourceExtractorScenario townRulePortCapScenario() {
  const tileKey = 'oldWorld|p2|1|1';
  return ResourceExtractorScenario.expect(
    label: 'town-rule-only + port: townDevelopmentLevel DOES cap yield',
    grid: const [
      ['p1', 'p1'],
      ['p1', 'p2'],
    ],
    resourceGrid: const [
      [null, null],
      [null, Resource.grain],
    ],
    tileSpecs: const [
      TileImprovementSpec('oldWorld|p1|0|0', roadLevel: 1),
      TileImprovementSpec('oldWorld|p2|1|1', improvement: 4),
    ],
    connected: {tileKey},
    pathTransportCap: const {tileKey: 4},
    gameOverride: townRuleTwoProvinceExtractorGame(
      tileState: tileStateFromSpecs(const [
        TileImprovementSpec('oldWorld|p1|0|0', roadLevel: 1),
        TileImprovementSpec('oldWorld|p2|1|1', improvement: 4),
      ]),
      p1TownTileKey: 'oldWorld|p1|0|0',
      p2TownTileKey: 'oldWorld|p2|0|1',
      portsByProvinceSeaboard: {'oldWorld|p2|sea1': 'oldWorld|p2|0|1'},
    ),
    expect: const ResourceExtractorExpectation(
      land: {'grain': 2},
    ),
    refs: 'SPEC/game/extraction-and-improvements.md § Extraction formula',
  );
}

/// Town-rule + non-port from `resource_extractor_part1_segment2_test.dart`.
ResourceExtractorScenario townRuleNonPortNoCapScenario() {
  const tileKey = 'oldWorld|p2|1|1';
  return ResourceExtractorScenario.expect(
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
    tileSpecs: const [
      TileImprovementSpec('oldWorld|p1|0|0', roadLevel: 1),
      TileImprovementSpec('oldWorld|p2|1|1', improvement: 4),
    ],
    connected: {tileKey},
    pathTransportCap: const {tileKey: 4},
    gameOverride: townRuleTwoProvinceExtractorGame(
      tileState: tileStateFromSpecs(const [
        TileImprovementSpec('oldWorld|p1|0|0', roadLevel: 1),
        TileImprovementSpec('oldWorld|p2|1|1', improvement: 4),
      ]),
      p1TownTileKey: 'oldWorld|p1|0|0',
      p2TownTileKey: 'oldWorld|p2|1|0',
    ),
    expect: const ResourceExtractorExpectation(
      land: {'grain': 4},
    ),
    refs: 'SPEC/game/extraction-and-improvements.md § Extraction formula',
  );
}

/// Dual tech-cap comparison from `resource_extractor_part1_segment1_test.dart`.
ResourceExtractorScenario resourceExtractorPlayerTechCapScenario({
  required TileMapResult grainTileMap,
}) =>
    ResourceExtractorScenario(
      label: 'effective extraction capped by player tech cap when improvement and '
          'transport are high',
      tileMap: grainTileMap,
      tileSpecs: const [
        TileImprovementSpec('oldWorld|p1|0|0', improvement: 4, roadLevel: 4),
      ],
      connected: {'oldWorld|p1|0|0'},
      techCapComparisonPin: const TechCapComparisonPin(
        capsAndExpectedGrain: [(2, 2), (3, 3)],
      ),
      verify: (_) {},
    );

/// Capital grain bonus from `resource_extractor_part2_part2_test.dart`.
ResourceExtractorScenario capitalGrainBonusScenario() {
  const playerId = 'pl1';
  final player = Player(
    id: playerId,
    displayName: 'Spain',
    isHuman: true,
    capitalProvinceId: 'oldWorld|p1',
    capitalTile: const CapitalTile(
      regionId: 'oldWorld',
      provinceId: 'oldWorld|p1',
      x: 0,
      y: 0,
    ),
  );
  return ResourceExtractorScenario.expect(
    label: 'capital tile grain bonus is unconditional on connectivity',
    tileMapByRegion: const {},
    tileSpecs: const [],
    connected: const {},
    gameOverride: TestFixtures.minimalGame(
      id: 'g1',
      oldWorld: RegionData(
        provinces: [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            ownerId: playerId,
            townDevelopmentLevel: 4,
          ),
        ],
      ),
      players: [player],
    ),
    connectivityByPlayer: connectivityFor(const {}),
    expect: const ResourceExtractorExpectation(
      land: {'grain': 5},
      overseasEmpty: true,
    ),
  );
}

/// Blockaded overseas port from `resource_extractor_part2_part1_test.dart`.
ResourceExtractorScenario blockadedOverseasPortScenario() {
  final fixture = blockadedOverseasExtractionFixture();
  return ResourceExtractorScenario(
    label:
        'blockaded overseas port: connectivity excludes tile so overseas extraction zero',
    gameOverride: fixture.game,
    tileMapByRegion: fixture.tileMapByRegion,
    blockadedOverseasPin: BlockadedOverseasPin(
      topology: fixture.topology,
      blockadedPortProvincesByPlayerId: {
        'pl1': {'newWorld|n1'},
      },
    ),
    verify: (_) {},
    refs: '#3939',
  );
}

/// Missing-province defensive path from `resource_extractor_part2_part2_test.dart`.
ResourceExtractorScenario provinceMissingFromRegionScenario({
  required TileMapResult grainTileMap,
}) {
  final tileState = tileStateFromSpecs(const [
    TileImprovementSpec('oldWorld|p1|0|0', improvement: 2, roadLevel: 2),
  ]);
  return ResourceExtractorScenario.expect(
    label:
        'skips connected tile and logs when province missing from region (world-model)',
    tileMap: grainTileMap,
    tileSpecs: const [
      TileImprovementSpec('oldWorld|p1|0|0', improvement: 2, roadLevel: 2),
    ],
    connected: {'oldWorld|p1|0|0'},
    gameOverride: provinceMissingExtractorGame(tileState: tileState),
    expectLogMessageContains: 'extraction province missing',
    expect: const ResourceExtractorExpectation(
      landAbsent: ['grain'],
      landEmpty: true,
      overseasEmpty: true,
    ),
    refs: '#3939',
  );
}
