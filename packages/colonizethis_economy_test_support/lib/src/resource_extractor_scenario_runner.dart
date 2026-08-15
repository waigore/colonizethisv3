// dart format off
// GP resource-extraction scenario runner + pins (Refs #3836, #4108 slice B, #4410).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'extraction_fixture_support.dart';
/// Dual tech-cap comparison for one fixture (Refs #3939 phase 3 slice 31).
class TechCapComparisonPin {
  const TechCapComparisonPin({required this.capsAndExpectedGrain, this.playerId = 'pl1'});
  final String playerId;
  final List<(int techCap, int expectedGrain)> capsAndExpectedGrain;
}
void assertTechCapComparisonPin({required Game game, required Map<String, TileMapResult> tileMapByRegion, required Map<String, ConnectivityResult> connectivityResult, required TechCapComparisonPin pin}) {
  for (final (techCap, expectedGrain) in pin.capsAndExpectedGrain) {
    final result = computeExtraction(game: game, tileMapByRegion: tileMapByRegion, connectivityResult: connectivityResult, techCapForPlayer: (_) => techCap);
    expect(result[pin.playerId]!.land['grain'], expectedGrain);
  }
}
/// Blockaded vs open overseas port connectivity pin (Refs #3939 phase 3 slice 31).
class BlockadedOverseasPin {
  const BlockadedOverseasPin({required this.topology, required this.blockadedPortProvincesByPlayerId, this.openOverseasCommodity = 'sugarCane', this.playerId = 'pl1'});
  final MapTopology topology;
  final Map<String, Set<String>> blockadedPortProvincesByPlayerId;
  final String openOverseasCommodity;
  final String playerId;
}
void assertBlockadedOverseasPin({required Game game, required Map<String, TileMapResult> tileMapByRegion, required BlockadedOverseasPin pin}) {
  final connectivityBlockaded = resolveConnectivity(game: game, tileMapByRegion: tileMapByRegion, topology: pin.topology, blockadedPortProvincesByPlayerId: pin.blockadedPortProvincesByPlayerId);
  final resultBlockaded = computeExtraction(game: game, tileMapByRegion: tileMapByRegion, connectivityResult: connectivityBlockaded, techCapForPlayer: (_) => 4);
  expect(resultBlockaded[pin.playerId]!.overseas, isEmpty);
  expect(resultBlockaded[pin.playerId]!.land, isEmpty);
  final connectivityOpen = resolveConnectivity(game: game, tileMapByRegion: tileMapByRegion, topology: pin.topology);
  final resultOpen = computeExtraction(game: game, tileMapByRegion: tileMapByRegion, connectivityResult: connectivityOpen, techCapForPlayer: (_) => 4);
  expect(resultOpen[pin.playerId]!.overseas[pin.openOverseasCommodity] ?? 0, greaterThan(0));
}
/// Data-driven expectations for [ResourceExtractorScenario] rows.
class ResourceExtractorExpectation {
  const ResourceExtractorExpectation({this.playerId = 'pl1', this.land = const {}, this.overseas = const {}, this.landAbsent = const [], this.landEmpty = false, this.overseasEmpty = false, this.requirePlayer = true, this.techCapPinUnlocked, this.techCapPinExpected, this.custom});
  final String playerId;
  final Map<String, int> land;
  final Map<String, int> overseas;
  final List<String> landAbsent;
  final bool landEmpty;
  final bool overseasEmpty;
  final bool requirePlayer;
  final Map<String, bool>? techCapPinUnlocked;
  final int? techCapPinExpected;
  final void Function(Map<String, ExtractionTotals> result)? custom;
}
void assertResourceExtractorExpectation(Map<String, ExtractionTotals> result, ResourceExtractorExpectation expectation) {
  if (expectation.requirePlayer) {
    expect(result[expectation.playerId], isNotNull);
  }
  final totals = result[expectation.playerId];
  if (totals == null) {
    return;
  }
  if (expectation.landEmpty) {
    expect(totals.land, isEmpty);
  }
  if (expectation.overseasEmpty) {
    expect(totals.overseas, isEmpty);
  }
  for (final commodity in expectation.landAbsent) {
    expect(totals.land[commodity], isNull);
  }
  for (final entry in expectation.land.entries) {
    expect(totals.land[entry.key], entry.value);
  }
  for (final entry in expectation.overseas.entries) {
    expect(totals.overseas[entry.key], entry.value);
  }
  if (expectation.techCapPinUnlocked != null && expectation.techCapPinExpected != null) {
    expect(extractionCapForUnlocked(expectation.techCapPinUnlocked!), expectation.techCapPinExpected);
  }
  expectation.custom?.call(result);
}
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
// dart format on
