// dart format off
// GP resource-extraction scenario runner (Refs #3836, #4108 slice B).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:logger/logger.dart';
import 'extraction_fixture_support.dart';
import 'resource_extractor_expectations.dart';
typedef ResourceExtractorScenario = ({String label, TileMapResult? tileMap, Map<String, TileMapResult>? tileMapByRegion, List<List<String>>? grid, List<List<Resource?>>? resourceGrid, String regionId, List<TileImprovementSpec> tileSpecs, Set<String> connected, Map<String, int> pathTransportCap, int townDevelopmentLevel, Map<String, bool>? techUnlocked, Map<String, Set<String>>? playerProspectedTiles, int techCap, int Function(String playerId)? techCapForPlayer, bool useOverseasGame, Game? gameOverride, Game Function(TileMapState tileState)? gameForTileState, Map<String, ConnectivityResult>? connectivityByPlayer, TechCapComparisonPin? techCapComparisonPin, BlockadedOverseasPin? blockadedOverseasPin, String? expectLogMessageContains, void Function(Map<String, ExtractionTotals> result) verify, String? refs});
void _noopResourceExtractorVerify(Map<String, ExtractionTotals> _) {}
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
Map<String, TileMapResult> tileMapByRegionForResourceExtractor(ResourceExtractorScenario scenario) {
  if (scenario.tileMapByRegion != null) return scenario.tileMapByRegion!;
  final resolved = scenario.tileMap ?? tileMapFromGrids(grid: scenario.grid!, resourceGrid: scenario.resourceGrid!);
  return {scenario.regionId: resolved};
}
Game gameForResourceExtractor(ResourceExtractorScenario scenario, TileMapState tileState) {
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
  final tileMapByRegion = tileMapByRegionForResourceExtractor(scenario);
  final game = gameForResourceExtractor(scenario, tileState);
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
// dart format on
