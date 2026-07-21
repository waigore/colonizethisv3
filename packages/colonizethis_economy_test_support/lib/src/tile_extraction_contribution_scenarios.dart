// dart format off
// Table-driven `computeTileExtractionContributionForPlayer` scenarios (Refs #3939, #3979).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'extraction_fixture_support.dart';

/// Pins for connected-tile extraction contribution rows.
typedef TileContributionConnectedPin = ({String commodityId, int units, bool verifyProvinceIndexParity});

/// Pins for disconnected-tile extraction contribution rows.
typedef TileContributionDisconnectedPin = ();

enum TileExtractionContributionPin { connectedGrainExcludesCapitalBonus, disconnectedNull }

TileExtractionContributionScenario tileExtractionContributionScenario({required String label, required TileExtractionContributionPin pin, TileContributionConnectedPin? connectedPins, TileMapResult? grainTileMap}) => (label: label, pin: pin, connectedPins: connectedPins, grainTileMap: grainTileMap, refs: null);

/// One row for per-tile extraction contribution scenario tables (Refs #3979).
typedef TileExtractionContributionScenario = ({
  String label,
  TileExtractionContributionPin pin,
  TileContributionConnectedPin? connectedPins,
  TileMapResult? grainTileMap,
  String? refs,
});

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
