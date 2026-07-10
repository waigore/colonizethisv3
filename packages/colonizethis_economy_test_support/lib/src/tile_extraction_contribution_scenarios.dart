// dart format off
// Table-driven `computeTileExtractionContributionForPlayer` scenarios (Refs #3939).

import 'package:colonizethis_data/colonizethis_data.dart';

import 'tile_extraction_contribution_expectations.dart';

/// One row for per-tile extraction contribution scenario tables (Refs #3939 slice 64).
typedef TileExtractionContributionScenario = ({
  String label,
  void Function() run,
  String? refs,
});

void runTileExtractionContributionScenario(
  TileExtractionContributionScenario scenario,
) {
  scenario.run();
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
