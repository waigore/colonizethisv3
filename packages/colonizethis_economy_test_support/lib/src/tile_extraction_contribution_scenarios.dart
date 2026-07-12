// dart format off
// Table-driven `computeTileExtractionContributionForPlayer` scenarios (Refs #3939, #3979).

import 'package:colonizethis_data/colonizethis_data.dart';

import 'extraction_fixture_support.dart';
import 'tile_extraction_contribution_expectations.dart';

/// One row for per-tile extraction contribution scenario tables (Refs #3979).
typedef TileExtractionContributionScenario = ({
  String label,
  TileExtractionContributionPin pin,
  TileContributionConnectedPin? connectedPins,
  TileMapResult? grainTileMap,
  String? refs,
});

void runTileExtractionContributionScenario(
  TileExtractionContributionScenario scenario,
) {
  final tileMap = scenario.grainTileMap ?? singleTileMap(Resource.grain);
  switch (scenario.pin) {
    case TileExtractionContributionPin.connectedGrainExcludesCapitalBonus:
      runTileContributionConnectedPin(
        grainTileMap: tileMap,
        pins: scenario.connectedPins!,
      );
    case TileExtractionContributionPin.disconnectedNull:
      runTileContributionDisconnectedPin(grainTileMap: tileMap);
  }
}

List<TileExtractionContributionScenario> tileExtractionContributionScenarios({
  required TileMapResult grainTileMap,
}) => [
  tileExtractionContributionScenario(
    label:
        'tile extraction contribution excludes aggregate capital grain bonus',
    pin: TileExtractionContributionPin.connectedGrainExcludesCapitalBonus,
    grainTileMap: grainTileMap,
    connectedPins: (
      commodityId: 'grain',
      units: 1,
      verifyProvinceIndexParity: true,
    ),
  ),
  tileExtractionContributionScenario(
    label: 'tile extraction contribution is null for disconnected tile',
    pin: TileExtractionContributionPin.disconnectedNull,
    grainTileMap: grainTileMap,
  ),
];
// dart format on
